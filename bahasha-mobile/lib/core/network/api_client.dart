import 'package:dio/dio.dart';

/// Thin HTTP client for the Bahasha backend.
///
/// The base URL is injected at build time via --dart-define=API_BASE_URL so the
/// same binary points at local/staging/production without a code change. Timeouts
/// are short because the app is offline-first: a slow network should fail fast
/// and let the outbox retry, not block the UI.
class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? _defaultBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
            sendTimeout: const Duration(seconds: 12),
            headers: {'Content-Type': 'application/json'},
            // We handle non-2xx ourselves so the outbox can classify failures.
            validateStatus: (s) => s != null && s < 500,
          ),
        );

  final Dio _dio;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1', // Android emulator -> host
  );

  /// Registers (or reconciles) the giver and device. Returns the server user id.
  Future<String> register(Map<String, dynamic> body) async {
    final res = await _dio.post('/register', data: body);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return res.data['userId'] as String;
    }
    throw ApiException.fromResponse(res);
  }

  /// Fetches the active church list.
  Future<List<Map<String, dynamic>>> churches() async {
    final res = await _dio.get('/churches');
    if (res.statusCode == 200) {
      return (res.data['churches'] as List).cast<Map<String, dynamic>>();
    }
    throw ApiException.fromResponse(res);
  }

  /// Fetches the categories for a church (globals + church-specific).
  Future<List<Map<String, dynamic>>> categories(String churchId) async {
    final res = await _dio.get('/churches/$churchId/categories');
    if (res.statusCode == 200) {
      return (res.data['categories'] as List).cast<Map<String, dynamic>>();
    }
    throw ApiException.fromResponse(res);
  }

  /// Updates the giver's visibility preference (Secret ↔ Open).
  Future<void> setVisibility(String clientUuid, String visibility) async {
    final res = await _dio.post(
      '/account/visibility',
      data: {'clientUuid': clientUuid, 'visibility': visibility},
    );
    if (res.statusCode != 200) throw ApiException.fromResponse(res);
  }
}

/// A backend error surfaced with the stable machine code the API returns, so
/// callers branch on `code`, never on the message.
class ApiException implements Exception {
  ApiException(this.code, this.message, [this.status]);

  final String code;
  final String message;
  final int? status;

  factory ApiException.fromResponse(Response<dynamic> res) {
    final data = res.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        (err['code'] as String?) ?? 'unknown',
        (err['message'] as String?) ?? 'Request failed',
        res.statusCode,
      );
    }
    return ApiException('unknown', 'Request failed', res.statusCode);
  }

  @override
  String toString() => 'ApiException($code, $status): $message';
}
