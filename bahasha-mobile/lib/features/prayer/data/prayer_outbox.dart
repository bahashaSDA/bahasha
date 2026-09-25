import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/prayer_cycle.dart';

/// A silent prayer request, given alongside an offering.
///
/// ANONYMOUS BY DESIGN: it carries only the prayer text and when it is for.
/// No name, phone, user or device id, home church or offering reference
/// ever leaves the phone with it — nothing the prayer team (or anyone who can
/// read the sheet) could use to tell who wrote it.
class PrayerRequest {
  const PrayerRequest({
    required this.id,
    required this.text,
    required this.submittedAt,
    required this.cycle,
  });

  /// A random UUID minted for this prayer alone (not derived from the giver
  /// or the offering) — only so a retry never creates a second row.
  final String id;
  final String text;

  /// Kept on the phone for queue order only; never sent.
  final DateTime submittedAt; // UTC

  /// Sabbath the prayer is for (PrayerCycle.keyFor). The server recomputes it
  /// authoritatively in Africa/Nairobi time.
  final String cycle;

  /// Exactly what is sent to the sheet.
  Map<String, dynamic> toPayload() => {'requestId': id, 'prayer': text, 'cycle': cycle};

  Map<String, dynamic> toJson() => {
        ...toPayload(),
        'submittedAt': submittedAt.toUtc().toIso8601String(),
      };

  factory PrayerRequest.fromJson(Map<String, dynamic> j) => PrayerRequest(
        id: j['requestId'] as String,
        text: j['prayer'] as String,
        submittedAt: DateTime.parse(j['submittedAt'] as String),
        cycle: j['cycle'] as String,
      );

  /// Normalise what the giver typed: trimmed, and null when empty or
  /// whitespace-only (an empty prayer is never saved).
  static String? clean(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    return t.length > maxLength ? t.substring(0, maxLength) : t;
  }

  static const int maxLength = 1000;
}

/// Durable outbox for prayer requests, delivered to the prayer team's Google
/// Sheet through a Google Apps Script web app (documentation/prayer/).
///
/// Why this shape:
///  * No credentials live in the app. The endpoint is a write-only Apps Script
///    web app that runs as the sheet owner on Google's servers; it never
///    returns stored prayers, and the sheet itself is shared privately with
///    the prayer team only.
///  * Offline-first like the rest of Bahasha: the request is persisted on the
///    phone first and sent when a connection is available, then removed from
///    the phone once the sheet has it (the phone keeps no prayer archive).
///  * Only ever enqueued AFTER the offering was saved, so no orphan prayers.
class PrayerOutbox {
  PrayerOutbox({Dio? dio, String? endpoint})
      : _endpoint = endpoint ?? const String.fromEnvironment('PRAYER_ENDPOINT', defaultValue: defaultEndpoint),
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              // Apps Script answers a POST with a 302 to the script's echo
              // URL; we follow it by hand (see _deliver) to read the result.
              followRedirects: false,
              validateStatus: (s) => s != null && s < 500,
            ));

  /// The church's deployed prayer web app (documentation/prayer/). Not a
  /// secret: it only accepts prayers and never returns them. Override per
  /// build with --dart-define=PRAYER_ENDPOINT=... (e.g. another church).
  static const defaultEndpoint =
      'https://script.google.com/macros/s/AKfycbzrkzzVNu-LQfImabFxsWSqPiEVckIy-r0W6TjZqYl-E7VfuL9ss6wyYO9EufqCUExb/exec';

  final String _endpoint;
  final Dio _dio;
  static const _uuid = Uuid();
  static const _prefsKey = 'bahasha.prayers.outbox.v1';

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Future<void>? _inFlight;
  bool _again = false;

  bool get isConfigured => _endpoint.isNotEmpty;

  /// Watch connectivity and flush whenever the network returns; flush once now.
  void start() {
    _sub ??= Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) unawaited(flush());
    });
    unawaited(flush());
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// Persist an anonymous prayer. Returns null (and saves nothing) when
  /// [text] is empty or whitespace. The caller only enqueues AFTER the
  /// offering has been saved. Delivery is attempted in the background;
  /// failures stay queued and retry.
  Future<PrayerRequest?> enqueue({required String? text, DateTime? now}) async {
    final prayer = PrayerRequest.clean(text);
    if (prayer == null) return null;
    final at = (now ?? DateTime.now()).toUtc();
    final request = PrayerRequest(
      id: _uuid.v4(),
      text: prayer,
      submittedAt: at,
      cycle: PrayerCycle.keyFor(at),
    );
    final queue = await pending();
    await _save([...queue, request]);
    unawaited(flush());
    return request;
  }

  /// Prayers still waiting to reach the sheet, oldest first.
  Future<List<PrayerRequest>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(PrayerRequest.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Try to deliver every queued prayer. Guarded so overlapping triggers
  /// coalesce; each delivered prayer is removed individually, so a failure
  /// midway never re-sends (and the sheet de-duplicates on requestId anyway).
  ///
  /// A call made while a flush is running waits for it and triggers one more
  /// pass, so a prayer queued mid-flush is never left behind.
  Future<void> flush() {
    if (!isConfigured) return Future.value();
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
        final outcome = await _deliver(p);
        if (outcome == _Outcome.retryLater) return; // offline — keep the rest
        // Delivered, or permanently rejected as malformed: either way it must
        // leave the phone (a malformed request would otherwise retry forever).
        final rest = (await pending()).where((q) => q.id != p.id).toList();
        await _save(rest);
      }
    } while (_again);
  }

  /// POST the prayer and read the script's answer.
  ///
  /// Apps Script replies to a POST with a 302 to a one-off "echo" URL on
  /// script.googleusercontent.com that holds the JSON result. The script has
  /// already run by then, but that echo page is flaky: measured against the
  /// live endpoint, roughly one read in three comes back 302/404. Re-sending
  /// is safe (the sheet de-duplicates on requestId and answers
  /// {ok:true, duplicate:true}), so an unreadable answer is simply retried a
  /// few times with a short back-off.
  Future<_Outcome> _deliver(PrayerRequest p) async {
    const attempts = 4;
    for (var i = 0; i < attempts; i++) {
      if (i > 0) await Future<void>.delayed(retryDelay * i);
      final answer = await _post(p);
      if (answer == null) continue; // unreadable — ask again
      if (answer['ok'] == true) return _Outcome.delivered;
      final error = answer['error'];
      if (error == 'bad_request_id' || error == 'empty_prayer') return _Outcome.rejected;
      // server_error (e.g. the sheet was busy): try again.
    }
    return _Outcome.retryLater;
  }

  /// Pause between re-sends (× attempt number). Shortened in tests.
  Duration retryDelay = const Duration(seconds: 1);

  /// One POST + echo read. Null when there is no readable JSON answer.
  Future<Map<String, dynamic>?> _post(PrayerRequest p) async {
    try {
      final res = await _dio.post<dynamic>(
        _endpoint,
        data: jsonEncode(p.toPayload()),
        // text/plain keeps Apps Script from rejecting the body; the script
        // parses e.postData.contents as JSON.
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

  Future<void> _save(List<PrayerRequest> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(queue.map((q) => q.toJson()).toList()));
  }

  /// Remove every queued prayer from this phone (account deletion).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

enum _Outcome { delivered, rejected, retryLater }
