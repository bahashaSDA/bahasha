// Named constructor params map to private fields (db, client).
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'hub_database.dart';
import 'ingest_client.dart';

/// Drains the local received-payload queue to the backend.
///
/// Runs on a timer and on every connectivity regain. Each pending payload is
/// uploaded; the backend's idempotency means a payload uploaded twice (retry
/// after an ambiguous failure) never double-charges, so retries are always
/// safe. Rejected payloads (bad signature, replay) are marked terminally
/// rejected and not retried — they are an attack/bug signal, not a transient.
class UploadService {
  UploadService({required HubDatabase db, required IngestClient client})
      : _db = db,
        _client = client;

  final HubDatabase _db;
  final IngestClient _client;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _running = false;

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 20), (_) => drain());
    _connSub ??= Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) drain();
    });
    drain();
  }

  void dispose() {
    _timer?.cancel();
    _connSub?.cancel();
    _timer = null;
    _connSub = null;
  }

  /// One drain pass. Coalesces overlapping triggers.
  Future<void> drain() async {
    if (_running) return;
    _running = true;
    try {
      final pending = await _db.pending();
      if (pending.isEmpty) return;

      // Mark uploading and send as one batch.
      for (final row in pending) {
        await _db.setStatus(row.idempotencyKey, 'uploading');
        await _db.incrementAttempts(row.idempotencyKey);
      }

      try {
        final results = await _client.uploadBatch(pending.map((r) => r.payloadJson).toList());
        final byKey = {for (final r in results) r.idempotencyKey: r};
        for (final row in pending) {
          final result = byKey[row.idempotencyKey];
          if (result == null) {
            await _db.setStatus(row.idempotencyKey, 'received', error: 'no result returned');
          } else if (result.ok) {
            await _db.setStatus(row.idempotencyKey, 'uploaded');
          } else if (result.code == 'payload_verification_failed') {
            // Terminal: a bad signature/replay never becomes valid on retry.
            await _db.setStatus(row.idempotencyKey, 'rejected', error: result.message);
            await _db.log('Payload rejected: ${result.message}', level: 'warn');
          } else {
            await _db.setStatus(row.idempotencyKey, 'failed', error: result.message);
          }
        }
        final ok = results.where((r) => r.ok).length;
        if (ok > 0) await _db.log('Uploaded $ok contribution(s)');
      } on IngestAuthException catch (e) {
        // Whole batch stays pending; the key is wrong and must be re-paired.
        for (final row in pending) {
          await _db.setStatus(row.idempotencyKey, 'failed', error: e.message);
        }
        await _db.log('Upload auth failed: ${e.message}', level: 'error');
      } on Object catch (e) {
        // Transient (network/server). Return to pending for the next pass.
        for (final row in pending) {
          await _db.setStatus(row.idempotencyKey, 'received', error: '$e');
        }
      }
    } finally {
      _running = false;
    }
  }
}
