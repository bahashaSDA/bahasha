import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Forwards the anonymous prayers Bahasha phones hand this hub over BLE to the
/// prayer team's Google Sheet, via the church's Apps Script web app
/// (documentation/prayer/). The phones never go online; the hub does.
///
/// Each prayer is held here (only its random request id and text — nothing
/// about who wrote it) until the sheet confirms it, then removed. The sheet
/// de-duplicates on the request id, so resending is always safe.
class PrayerRelay {
  PrayerRelay({Dio? dio, String? endpoint})
      : _endpoint = endpoint ?? const String.fromEnvironment('PRAYER_ENDPOINT', defaultValue: defaultEndpoint),
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              // Apps Script answers a POST with a 302 to a one-off "echo" URL
              // holding the JSON result; it is followed by hand (see _post).
              followRedirects: false,
              validateStatus: (s) => s != null && s < 500,
            ));

  /// The church's deployed prayer web app. Not a secret: it only accepts
  /// prayers and never returns them.
  static const defaultEndpoint =
      'https://script.google.com/macros/s/AKfycbzrkzzVNu-LQfImabFxsWSqPiEVckIy-r0W6TjZqYl-E7VfuL9ss6wyYO9EufqCUExb/exec';

  final String _endpoint;
  final Dio _dio;
  static const _prefsKey = 'cvendor.prayers.relay.v1';

  /// Pause between re-sends (× attempt number). Shortened in tests.
  Duration retryDelay = const Duration(seconds: 1);

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Future<void>? _inFlight;
  bool _again = false;

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => unawaited(flush()));
    _connSub ??= Connectivity().onConnectivityChanged.listen((r) {
      if (r.any((x) => x != ConnectivityResult.none)) unawaited(flush());
    });
    unawaited(flush());
  }

  void dispose() {
    _timer?.cancel();
    _connSub?.cancel();
    _timer = null;
    _connSub = null;
  }

  /// Hold a prayer a phone handed over, then try to deliver it.
  Future<void> enqueue(String requestId, String prayer) async {
    final queue = await pending();
    if (queue.any((p) => p.requestId == requestId)) return; // phone retried
    await _save([...queue, (requestId: requestId, prayer: prayer)]);
    unawaited(flush());
  }

  Future<List<({String requestId, String prayer})>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return [
        for (final m in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          (requestId: m['requestId'] as String, prayer: m['prayer'] as String),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Deliver every held prayer. A call during a flush triggers one more pass.
  Future<void> flush() {
    if (_endpoint.isEmpty) return Future.value();
    if (_inFlight != null) {
      _again = true;
      return _inFlight!;
    }
    return _inFlight = _run().whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    do {
      _again = false;
      for (final p in await pending()) {
        final outcome = await _deliver(p.requestId, p.prayer);
        if (outcome == _Outcome.retryLater) return; // offline — keep the rest
        await _save((await pending()).where((q) => q.requestId != p.requestId).toList());
      }
    } while (_again);
  }

  /// The echo page is flaky (measured against the live endpoint: ~1 read in 3
  /// comes back 302/404) though the script has already run, so an unreadable
  /// answer is re-sent a few times — safe, since the sheet de-duplicates.
  Future<_Outcome> _deliver(String requestId, String prayer) async {
    for (var i = 0; i < 4; i++) {
      if (i > 0) await Future<void>.delayed(retryDelay * i);
      final answer = await _post({'requestId': requestId, 'prayer': prayer});
      if (answer == null) continue;
      if (answer['ok'] == true) return _Outcome.delivered;
      final error = answer['error'];
      if (error == 'bad_request_id' || error == 'empty_prayer') return _Outcome.rejected;
    }
    return _Outcome.retryLater;
  }

  Future<Map<String, dynamic>?> _post(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post<dynamic>(
        _endpoint,
        data: jsonEncode(payload),
        options: Options(contentType: 'text/plain;charset=utf-8', responseType: ResponseType.plain),
      );
      var status = res.statusCode ?? 0;
      var body = res.data?.toString() ?? '';
      if (status == 302 || status == 303) {
        final location = res.headers.value('location');
        if (location == null) return null;
        final echo = await _dio.get<dynamic>(
          location,
          options: Options(responseType: ResponseType.plain, followRedirects: false, persistentConnection: false),
        );
        status = echo.statusCode ?? 0;
        body = echo.data?.toString() ?? '';
      }
      if (status != 200) return null;
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(List<({String requestId, String prayer})> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, jsonEncode([for (final p in queue) {'requestId': p.requestId, 'prayer': p.prayer}]));
  }
}

enum _Outcome { delivered, rejected, retryLater }
