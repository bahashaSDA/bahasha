import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The hub's identity: its API key and the backend it uploads to. The API key
/// authenticates every ingest call and is stored in the platform secure
/// keystore, never in plain preferences. A deacon pairs the hub once by
/// entering the key their treasurer/admin issued; it persists across launches.
class HubSession {
  HubSession({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _keyApi = 'cvendor.hub.apiKey';
  static const _keyChurch = 'cvendor.hub.churchName';
  static const _aOptions = AndroidOptions(encryptedSharedPreferences: true);

  Future<bool> get isPaired async =>
      (await _storage.read(key: _keyApi, aOptions: _aOptions)) != null;

  Future<String?> get apiKey => _storage.read(key: _keyApi, aOptions: _aOptions);
  Future<String?> get churchName => _storage.read(key: _keyChurch, aOptions: _aOptions);

  Future<void> pair({required String apiKey, required String churchName}) async {
    await _storage.write(key: _keyApi, value: apiKey, aOptions: _aOptions);
    await _storage.write(key: _keyChurch, value: churchName, aOptions: _aOptions);
  }

  Future<void> unpair() async {
    await _storage.delete(key: _keyApi, aOptions: _aOptions);
    await _storage.delete(key: _keyChurch, aOptions: _aOptions);
  }

  /// Validate the hub key format before saving, so an obviously-wrong paste is
  /// caught immediately rather than on the first upload.
  static bool isWellFormedKey(String key) => RegExp(r'^bhk_[A-Za-z0-9_-]{43}$').hasMatch(key);
}
