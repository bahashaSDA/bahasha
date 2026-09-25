// Named constructor params intentionally map to private fields; initializing
// formals (`this._db`) are illegal for private names in named-parameter
// position, so the explicit assignment below is correct, not a smell.
// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../crypto/payload_signer.dart';
import '../network/api_client.dart';
import 'local_database.dart';

/// Owns the giver's registration: writes it locally first (so the app proceeds
/// offline), then syncs to the backend, registering the device public key that
/// anchors every future contribution signature.
class RegistrationRepository {
  RegistrationRepository({
    required LocalDatabase db,
    required ApiClient api,
    required PayloadSigner signer,
  })  : _db = db,
        _api = api,
        _signer = signer;

  final LocalDatabase _db;
  final ApiClient _api;
  final PayloadSigner _signer;
  static const _uuid = Uuid();

  /// Persist a first-time registration locally. Returns the client UUID that
  /// identifies this giver across sync. Safe with no connectivity.
  Future<String> registerLocally({
    required String fullName,
    required String phone,
    required String churchId,
    required String membershipStatus,
    required String visibility,
  }) async {
    final existing = await _db.currentUser();
    final clientUuid = existing?.clientUuid ?? _uuid.v4();

    await _db.into(_db.localUsers).insertOnConflictUpdate(
          LocalUsersCompanion(
            clientUuid: Value(clientUuid),
            fullName: Value(fullName),
            phone: Value(phone),
            churchId: Value(churchId),
            membershipStatus: Value(membershipStatus),
            visibility: Value(visibility),
            synced: const Value(false),
          ),
        );
    return clientUuid;
  }

  /// Push the local registration to the backend. Registers the device keypair's
  /// public key. Idempotent: the backend reconciles on clientUuid/deviceUuid, so
  /// a retry after a flaky connection creates no duplicates.
  Future<void> sync() async {
    final user = await _db.currentUser();
    if (user == null || user.synced) return;

    final deviceUuid = await _signer.deviceUuid();
    final publicKey = await _signer.publicKeySpkiBase64();

    final serverUserId = await _api.register({
      'clientUuid': user.clientUuid,
      'fullName': user.fullName,
      'phone': user.phone,
      // The churchId column now holds the giver's free-text HOME church.
      'homeChurch': user.churchId,
      'visibility': user.visibility,
      'device': {
        'deviceUuid': deviceUuid,
        'publicKey': publicKey,
        'keyAlgorithm': 'ed25519',
        'platform': 'android',
      },
    });

    await (_db.update(_db.localUsers)
          ..where((t) => t.clientUuid.equals(user.clientUuid)))
        .write(
      LocalUsersCompanion(serverUserId: Value(serverUserId), synced: const Value(true)),
    );
  }

  /// Toggle giving visibility. Applies locally immediately; syncs best-effort so
  /// the change is not lost if offline (the outbox retries).
  Future<void> setVisibility(String visibility) async {
    final user = await _db.currentUser();
    if (user == null) return;
    await (_db.update(_db.localUsers)
          ..where((t) => t.clientUuid.equals(user.clientUuid)))
        .write(LocalUsersCompanion(visibility: Value(visibility)));
    try {
      await _api.setVisibility(user.clientUuid, visibility);
    } on ApiException {
      // Left for the next sync pass; the local value is authoritative meanwhile.
    }
  }

  /// Edit the giver's name/phone (Settings → Personal info). Applied locally
  /// at once and marked unsynced; the existing idempotent /register call then
  /// reconciles the same user on clientUuid, so the backend is updated with no
  /// new endpoint.
  ///
  /// All-or-nothing: offerings are signed with the stored phone and the
  /// backend only accepts a payload whose phone matches the user of record,
  /// so a change the backend has not accepted must not linger locally. On any
  /// failure (offline, or e.g. the phone belongs to another giver) the old
  /// details are restored and the error is rethrown for the caller to show.
  Future<void> updateProfile({required String fullName, required String phone}) async {
    final user = await _db.currentUser();
    if (user == null) return;
    Future<void> write(String name, String number, bool synced) =>
        (_db.update(_db.localUsers)..where((t) => t.clientUuid.equals(user.clientUuid))).write(
          LocalUsersCompanion(fullName: Value(name), phone: Value(number), synced: Value(synced)),
        );
    await write(fullName, phone, false);
    try {
      await sync();
    } catch (_) {
      await write(user.fullName, user.phone, user.synced);
      rethrow;
    }
  }

  /// Remove this giver's account from the phone: the profile and the local
  /// giving history. The per-device replay counter and signing key are kept on
  /// purpose — resetting them would make a future re-registration's
  /// signatures look like replays to the backend.
  Future<void> deleteLocalAccount() async {
    await _db.transaction(() async {
      await _db.delete(_db.contributions).go();
      await _db.delete(_db.localUsers).go();
    });
  }

  /// Offerings signed on this phone that have not yet settled — deleting the
  /// account would discard them, so the UI warns first.
  Future<int> unsettledCount() async => (await _db.pendingContributions()).length;

}
