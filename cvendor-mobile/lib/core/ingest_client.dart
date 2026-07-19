import 'dart:convert';
import 'package:dio/dio.dart';

/// Per-payload result the backend returns for a batch ingest item.
class IngestItemResult {
  IngestItemResult({required this.idempotencyKey, required this.ok, this.code, this.message});
  final String idempotencyKey;
  final bool ok;
  final String? code;
  final String? message;
}

/// Uploads received BLE payloads to the Bahasha backend `/ingest` endpoint,
/// authenticated by the hub API key. The backend re-verifies each payload's
/// device signature before settling — the hub is a relay, not a trust anchor —
/// so this client simply forwards what it received and reports the outcome.
class IngestClient {
  IngestClient({required String apiKey, String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? _defaultBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json', 'X-Hub-Api-Key': apiKey},
            validateStatus: (s) => s != null && s < 500,
          ),
        );

  final Dio _dio;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  /// Upload a batch of already-reassembled payloads. Each payload JSON is the
  /// full signed envelope a Bahasha device produced. Returns per-item results so
  /// the caller can mark each queue row uploaded/rejected independently.
  Future<List<IngestItemResult>> uploadBatch(List<String> payloadJsons) async {
    final payloads = payloadJsons.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    final res = await _dio.post('/ingest', data: {'payloads': payloads});

    if (res.statusCode == 401) {
      throw IngestAuthException('Hub API key was rejected');
    }
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw IngestException('Ingest failed (HTTP ${res.statusCode})');
    }

    final results = (res.data['results'] as List).cast<Map<String, dynamic>>();
    return results
        .map((r) => IngestItemResult(
              idempotencyKey: r['idempotencyKey'] as String,
              ok: r['ok'] as bool,
              code: r['code'] as String?,
              message: r['message'] as String?,
            ))
        .toList();
  }

  /// Lightweight liveness ping; also refreshes the hub's status server-side.
  Future<bool> heartbeat() async {
    try {
      final res = await _dio.post('/hub/heartbeat');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class IngestException implements Exception {
  IngestException(this.message);
  final String message;
  @override
  String toString() => message;
}

class IngestAuthException extends IngestException {
  IngestAuthException(super.message);
}
