// Named constructor params intentionally map to private fields; initializing
// formals (`this._db`) are illegal for private names in named-parameter
// position, so the explicit assignment below is correct, not a smell.
// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../crypto/payload_signer.dart';
import 'local_database.dart';

/// Owns the giver's registration. Fully offline: the profile is written on
/// the phone, and the backend learns it through a CVendor hub over BLE — the
/// hub relays [registrationBody] to POST /register (idempotent on clientUuid /
/// deviceUuid) and hands back the server user id, which [markRegistered]
/// stores. Until then `synced` is false and the next hub session registers
/// (or re-registers, after an edit) before handing over any offering.
class RegistrationRepository {
  RegistrationRepository({
    required LocalDatabase db,
    required PayloadSigner signer,
  })  : _db = db,
        _signer = signer;

  final LocalDatabase _db;
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

  /// The POST /register body a hub relays for this giver: the profile plus the
  /// device public key that anchors every contribution signature.
  Future<Map<String, dynamic>?> registrationBody() async {
    final user = await _db.currentUser();
    if (user == null) return null;
    return {
      'clientUuid': user.clientUuid,
      'fullName': user.fullName,
      'phone': user.phone,
      // The churchId column now holds the giver's free-text HOME church.
      'homeChurch': user.churchId,
      'visibility': user.visibility,
      'device': {
        'deviceUuid': await _signer.deviceUuid(),
        'publicKey': await _signer.publicKeySpkiBase64(),
        'keyAlgorithm': 'ed25519',
        'platform': 'android',
      },
    };
  }

  /// The hub relayed the registration and the backend accepted it.
  Future<void> markRegistered(String serverUserId) async {
    final user = await _db.currentUser();
    if (user == null) return;
    await (_db.update(_db.localUsers)..where((t) => t.clientUuid.equals(user.clientUuid))).write(
      LocalUsersCompanion(serverUserId: Value(serverUserId), synced: const Value(true)),
    );
  }

  /// Toggle giving visibility. Applied on the phone at once; the backend is
  /// updated through the next hub session (re-registration carries it).
  Future<void> setVisibility(String visibility) async {
    final user = await _db.currentUser();
    if (user == null) return;
    await (_db.update(_db.localUsers)..where((t) => t.clientUuid.equals(user.clientUuid)))
        .write(LocalUsersCompanion(visibility: Value(visibility), synced: const Value(false)));
  }

  /// Edit the giver's name/phone (Settings → Personal info). Saved on the
  /// phone and marked unsynced: the next hub session re-registers (the same
  /// user, reconciled on clientUuid) BEFORE handing over any offering, so an
  /// offering is never signed with a phone the backend has not accepted.
  Future<void> updateProfile({required String fullName, required String phone}) async {
    final user = await _db.currentUser();
    if (user == null) return;
    await (_db.update(_db.localUsers)..where((t) => t.clientUuid.equals(user.clientUuid))).write(
      LocalUsersCompanion(fullName: Value(fullName), phone: Value(phone), synced: const Value(false)),
    );
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
