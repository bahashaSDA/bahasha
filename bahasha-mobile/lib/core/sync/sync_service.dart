// Named constructor params map to private fields; see registration_repository.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import '../data/local_database.dart';
import '../data/registration_repository.dart';
import '../network/api_client.dart';

/// Reconciles local state with the backend whenever connectivity is available.
///
/// Offline-first means the app never blocks on the network: registration and
/// contributions are written locally, and this service drains them upward in
/// the background. It runs on app start, on every connectivity regain, and can
/// be triggered manually (e.g. pull-to-refresh). All work is idempotent, so a
/// double-trigger is harmless.
class SyncService {
  SyncService({
    required LocalDatabase db,
    required ApiClient api,
    required RegistrationRepository registration,
  })  : _db = db,
        _api = api,
        _registration = registration;

  final LocalDatabase _db;
  final ApiClient _api;
  final RegistrationRepository _registration;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _running = false;

  /// Begin watching connectivity and do an initial pass.
  void start() {
    _sub ??= Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) unawaited(syncNow());
    });
    unawaited(syncNow());
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// One reconciliation pass. Guarded so overlapping triggers coalesce.
  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    try {
      await _refreshChurches();
      await _registration.sync();
      // The contribution outbox is drained by the BLE transport (contributions
      // settle via a hub, not a direct upload); this pass only pushes identity
      // and profile state. See ble/ for the transport that flushes giving.
    } catch (_) {
      // Swallow: the next connectivity event or manual trigger retries. A sync
      // failure must never surface as an error to the giver.
    } finally {
      _running = false;
    }
  }

  /// Refresh the cached church list so the picker reflects newly-onboarded
  /// congregations without an app update.
  Future<void> _refreshChurches() async {
    final churches = await _api.churches();
    if (churches.isEmpty) return;
    for (final c in churches) {
      await _db.into(_db.cachedChurches).insertOnConflictUpdate(
            CachedChurchesCompanion(
              id: Value(c['id'] as String),
              name: Value(c['name'] as String),
              slug: Value(c['slug'] as String),
              publicKey: Value(c['public_key'] as String?),
            ),
          );
    }
  }
}
