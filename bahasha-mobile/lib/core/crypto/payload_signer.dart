import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Device-side signing for the BLE contribution protocol.
///
/// MUST stay byte-for-byte compatible with the backend verifier
/// (`backend/src/lib/crypto.ts`) and the protocol spec
/// (`documentation/protocol/ble-protocol.md`). If the canonical encoding here
/// and there ever diverge, every signature fails verification and no
/// contribution settles — so the field order below is a hard contract.
///
/// The Ed25519 private key is generated once and stored in the platform secure
/// keystore via flutter_secure_storage (Android Keystore-backed). It is never
/// exported, logged, or synced.
class PayloadSigner {
  PayloadSigner({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _algorithm = Ed25519();

  final FlutterSecureStorage _storage;
  final Ed25519 _algorithm;

  static const _seedKey = 'bahasha.device.ed25519.seed';
  static const _aOptions = AndroidOptions(encryptedSharedPreferences: true);

  /// Returns the device keypair, generating and persisting it on first use.
  /// Only the 32-byte private seed is stored; the public key is derived from it.
  Future<SimpleKeyPair> _keyPair() async {
    final existing = await _storage.read(key: _seedKey, aOptions: _aOptions);
    if (existing != null) {
      final seed = base64Decode(existing);
      return _algorithm.newKeyPairFromSeed(seed);
    }
    final pair = await _algorithm.newKeyPair();
    final seed = await pair.extractPrivateKeyBytes();
    await _storage.write(
      key: _seedKey,
      value: base64Encode(seed),
      aOptions: _aOptions,
    );
    return pair;
  }

  /// The device public key as base64 SPKI DER — the exact form the backend's
  /// `importPublicKey` expects at registration.
  Future<String> publicKeySpkiBase64() async {
    final pair = await _keyPair();
    final pub = await pair.extractPublicKey();
    return base64Encode(_wrapEd25519Spki(pub.bytes));
  }

  /// The stable device UUID, derived deterministically from THIS device's public
  /// key. Both registration (which registers it with the backend) and signing
  /// (which stamps it into the payload) call this single method, so the id the
  /// backend stores and the id it looks up on verification are guaranteed to
  /// match. Deriving it from the key means no extra storage and no drift.
  Future<String> deviceUuid() async {
    final pub = await publicKeySpkiBase64();
    return const Uuid().v5(Namespace.url.value, 'bahasha-device:$pub');
  }

  /// The canonical bytes to sign. Field order mirrors
  /// `canonicalPayloadBytes` in the backend, prefix included.
  static Uint8List canonicalBytes({
    required String idempotencyKey,
    required String deviceUuid,
    required String userId,
    required String churchId,
    required String msisdn,
    required int totalAmount,
    required int counter,
    required String nonce,
    required String deviceTimestamp,
    required bool anonymous,
  }) {
    final fields = <String>[
      'bahasha.v1',
      idempotencyKey,
      deviceUuid,
      userId,
      churchId,
      msisdn,
      '$totalAmount',
      '$counter',
      nonce,
      deviceTimestamp,
      anonymous ? '1' : '0',
    ];
    return Uint8List.fromList(utf8.encode(fields.join('\n')));
  }

  /// Sign the canonical bytes; returns the detached signature, base64.
  Future<String> sign(Uint8List message) async {
    final pair = await _keyPair();
    final signature = await _algorithm.sign(message, keyPair: pair);
    return base64Encode(signature.bytes);
  }

  /// Wrap a raw 32-byte Ed25519 public key in the fixed SPKI DER prefix so the
  /// backend (Node's crypto, SPKI DER) can import it. The prefix is constant for
  /// Ed25519 (RFC 8410), so this is a byte concat, not a full ASN.1 encoder.
  static Uint8List _wrapEd25519Spki(List<int> rawPublicKey) {
    // 302a300506032b6570032100 || <32-byte key>
    const prefix = <int>[
      0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00,
    ];
    return Uint8List.fromList(<int>[...prefix, ...rawPublicKey]);
  }
}
