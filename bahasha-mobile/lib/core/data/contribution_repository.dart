// Named constructor params intentionally map to private fields; see
// registration_repository.dart for why initializing formals don't apply.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../crypto/payload_signer.dart';
import 'local_database.dart';

/// Turns a giving basket into a durable, signed contribution in the local
/// outbox. This is the on-device half of the BLE protocol: it mints the
/// idempotency key, pulls the next replay counter, builds the exact canonical
/// bytes the backend verifies, and signs them — all before anything is
/// transmitted. If the app dies here, the contribution survives in SQLite and
/// the outbox resends it later. Nothing is ever charged twice, and nothing is
/// lost.
class ContributionRepository {
  ContributionRepository({required LocalDatabase db, required PayloadSigner signer})
      : _db = db,
        _signer = signer;

  final LocalDatabase _db;
  final PayloadSigner _signer;
  static const _uuid = Uuid();

  /// Create a signed contribution from a basket of category→amount entries.
  /// Returns the contribution id (also the idempotency key). Fully offline.
  Future<String> createSigned({
    required Map<String, int> allocations,
    required LocalUser user,
  }) async {
    final id = _uuid.v4();
    final total = allocations.values.fold(0, (s, a) => s + a);
    if (total <= 0) {
      throw ArgumentError('cannot create a contribution with no amount');
    }

    final counter = await _db.nextCounter();
    final nonce = _uuid.v4();
    final anonymous = user.visibility == 'secret';
    // Single source of truth for the device id — same value the backend stored
    // at registration, so signature verification resolves the right key.
    final deviceUuid = await _signer.deviceUuid();
    final timestamp = DateTime.now().toUtc().toIso8601String();

    // Build the canonical bytes IDENTICAL to the backend verifier, then sign.
    final message = PayloadSigner.canonicalBytes(
      idempotencyKey: id,
      deviceUuid: deviceUuid,
      userId: user.serverUserId ?? user.clientUuid,
      churchId: user.churchId,
      msisdn: user.phone,
      totalAmount: total,
      counter: counter,
      nonce: nonce,
      deviceTimestamp: timestamp,
      anonymous: anonymous,
    );
    final signature = await _signer.sign(message);

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
            anonymous: Value(anonymous),
            status: const Value('queued'),
            counter: Value(counter),
            nonce: Value(nonce),
            signature: Value(signature),
          ),
        );

    return id;
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

}
