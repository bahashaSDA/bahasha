// Named constructor params intentionally map to private fields; see
// registration_repository.dart for why initializing formals don't apply.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../crypto/payload_signer.dart';
import 'local_database.dart';

/// Turns a giving basket into a durable contribution in the local outbox, and
/// — at hand-over time, over BLE — into the signed envelope the backend's
/// /ingest verifies (documentation/protocol/ble-protocol.md §4).
///
/// Why sign at hand-over, not at tap: the backend only accepts a payload whose
/// device timestamp is fresh (PAYLOAD_MAX_AGE_SECONDS, 15 min) and whose nonce
/// the hub just issued. An offering saved in the pew with no hub in range can
/// therefore wait on the phone for days, and is signed the moment a hub takes
/// it. Re-signing a retried offering is safe: the idempotency key never
/// changes, and the backend de-duplicates on it, so nothing is charged twice.
class ContributionRepository {
  ContributionRepository({required LocalDatabase db, required PayloadSigner signer})
      : _db = db,
        _signer = signer;

  final LocalDatabase _db;
  final PayloadSigner _signer;
  static const _uuid = Uuid();

  /// Save a basket as a queued contribution. Returns its id (also the
  /// idempotency key). Fully offline; nothing is signed yet.
  Future<String> createQueued({
    required Map<String, int> allocations,
    required LocalUser user,
  }) async {
    final id = _uuid.v4();
    final total = allocations.values.fold(0, (s, a) => s + a);
    if (total <= 0) {
      throw ArgumentError('cannot create a contribution with no amount');
    }
    final allocationsJson = jsonEncode(
      allocations.entries
          .where((e) => e.value > 0)
          .map((e) => {'categoryCode': e.key, 'amount': e.value})
          .toList(),
    );
    await _db.into(_db.contributions).insert(
          ContributionsCompanion(
            id: Value(id),
            churchId: Value(user.churchId),
            totalAmount: Value(total),
            allocationsJson: Value(allocationsJson),
            anonymous: Value(user.visibility == 'secret'),
            status: const Value('queued'),
            counter: const Value(0), // assigned when signed for hand-over
          ),
        );
    return id;
  }

  /// Offerings waiting to be handed to a hub, oldest first.
  Future<List<Contribution>> awaitingHandover() {
    return (_db.select(_db.contributions)
          ..where((t) => t.status.isIn(['queued', 'transmitting']))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Sign [row] for hand-over with the hub's [nonce]: a fresh replay counter
  /// and timestamp, over the exact canonical bytes the backend verifies.
  /// Returns the /ingest payload the hub uploads verbatim. Requires the giver
  /// to be registered with the backend (a server user id).
  Future<Map<String, dynamic>> envelopeFor(Contribution row, LocalUser user, String nonce) async {
    final userId = user.serverUserId;
    if (userId == null) throw StateError('giver is not registered with the backend yet');
    final msisdn = normalizeMsisdn(user.phone);
    if (msisdn == null) throw StateError('phone number is not a valid Kenyan mobile number');

    final counter = await _db.nextCounter();
    final deviceUuid = await _signer.deviceUuid();
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final anonymous = user.visibility == 'secret';
    final message = PayloadSigner.canonicalBytes(
      idempotencyKey: row.id,
      deviceUuid: deviceUuid,
      userId: userId,
      // The churchId column holds the giver's free-text HOME church.
      homeChurch: user.churchId,
      msisdn: msisdn,
      totalAmount: row.totalAmount,
      counter: counter,
      nonce: nonce,
      deviceTimestamp: timestamp,
      anonymous: anonymous,
    );
    final signature = await _signer.sign(message);

    await (_db.update(_db.contributions)..where((t) => t.id.equals(row.id))).write(
      ContributionsCompanion(
        counter: Value(counter),
        nonce: Value(nonce),
        signature: Value(signature),
        anonymous: Value(anonymous),
        status: const Value('transmitting'),
        retryCount: Value(row.retryCount + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return {
      'idempotencyKey': row.id,
      'deviceUuid': deviceUuid,
      'userId': userId,
      'homeChurch': user.churchId,
      'msisdn': msisdn,
      'totalAmount': row.totalAmount,
      'allocations': jsonDecode(row.allocationsJson),
      'counter': counter,
      'nonce': nonce,
      'deviceTimestamp': timestamp,
      'anonymous': anonymous,
      // The spec's encryption-to-church-key layer is not implemented yet; the
      // backend stores this field for forensics only (the SIGNATURE is what
      // proves authenticity), so it carries the signed canonical bytes.
      'ciphertext': base64Encode(message),
      'signature': signature,
      'algorithm': 'ed25519',
    };
  }

  /// Mark an outbox item's transmission state as it moves through BLE → backend.
  Future<void> updateStatus(String id, String status, {String? failureReason}) {
    return (_db.update(_db.contributions)..where((t) => t.id.equals(id))).write(
      ContributionsCompanion(
        status: Value(status),
        failureReason: Value(failureReason),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Kenyan MSISDN → E.164, exactly as the backend normalises it at
  /// registration (backend/src/lib/phone.ts) — /ingest compares the signed
  /// number to the stored one byte for byte.
  static String? normalizeMsisdn(String raw) {
    var s = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (s.isEmpty) return null;
    if (s.startsWith('+')) {
      // already prefixed
    } else if (s.startsWith('254')) {
      s = '+$s';
    } else if (s.startsWith('0')) {
      s = '+254${s.substring(1)}';
    } else if (RegExp(r'^[17][0-9]{8}$').hasMatch(s)) {
      s = '+254$s';
    } else {
      return null;
    }
    return RegExp(r'^\+254[17][0-9]{8}$').hasMatch(s) ? s : null;
  }
}
