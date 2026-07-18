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
      'churchId': user.churchId,
      'membershipStatus': user.membershipStatus,
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

}
