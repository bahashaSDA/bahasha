import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bahasha/features/prayer/data/prayer_outbox.dart';

/// Mimics an Apps Script web app: POST → 302 to an echo URL, GET echo → JSON.
class _FakeScript implements HttpClientAdapter {
  _FakeScript({this.online = true, this.flakyEchoes = 0, this.reject});
  bool online;

  /// How many echo reads fail (404) before one succeeds — the live
  /// endpoint's behaviour.
  int flakyEchoes;

  /// When set, the script answers {ok:false, error: reject}.
  String? reject;
  final posted = <Map<String, dynamic>>[];
  final _ids = <String>{};
  String _answer = '{"ok":true}';

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    if (!online) throw DioException.connectionError(requestOptions: o, reason: 'offline');
    if (o.method == 'POST') {
      final bytes = await body!.fold<List<int>>([], (a, b) => a..addAll(b));
      final sent = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      posted.add(sent);
      final id = sent['requestId'] as String;
      _answer = reject != null
          ? '{"ok":false,"error":"$reject"}'
          : (_ids.add(id) ? '{"ok":true}' : '{"ok":true,"duplicate":true}');
      return ResponseBody.fromString('', 302, headers: {
        'location': ['https://script.googleusercontent.com/echo'],
      });
    }
    if (flakyEchoes > 0) {
      flakyEchoes--;
      return ResponseBody.fromString('<html>Page not found</html>', 404);
    }
    return ResponseBody.fromString(_answer, 200);
  }

  @override
  void close({bool force = false}) {}
}


void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PrayerOutbox outbox(_FakeScript script, {String endpoint = 'https://script.google.com/macros/s/x/exec'}) {
    final dio = Dio(BaseOptions(followRedirects: false, validateStatus: (s) => s != null && s < 500))
      ..httpClientAdapter = script;
    return PrayerOutbox(dio: dio, endpoint: endpoint)..retryDelay = Duration.zero;
  }

  test('an empty or whitespace prayer is never saved', () async {
    final o = outbox(_FakeScript());
    expect(await o.enqueue(text: '   '), isNull);
    expect(await o.pending(), isEmpty);
  });

  test('a prayer is delivered once and then removed from the phone', () async {
    final script = _FakeScript();
    final o = outbox(script);
    final r = await o.enqueue(text: ' Healing for my mother ');
    await o.flush();
    expect(r, isNotNull);
    expect(script.posted, hasLength(1));
    expect(script.posted.single['prayer'], 'Healing for my mother');
    expect(await o.pending(), isEmpty);
  });

  test('offline: the prayer stays queued and is sent when back online', () async {
    final script = _FakeScript(online: false);
    final o = outbox(script);
    await o.enqueue(text: 'Pray for exams');
    await o.flush();
    expect(await o.pending(), hasLength(1));

    script.online = true;
    await o.flush();
    expect(await o.pending(), isEmpty);
    expect(script.posted, hasLength(1));
  });

  test('a flaky echo page is retried; the sheet stores the prayer once', () async {
    final script = _FakeScript(flakyEchoes: 2);
    final o = outbox(script);
    await o.enqueue(text: 'Strength');
    await o.flush();
    expect(await o.pending(), isEmpty);
    expect(script.posted, hasLength(3)); // 2 unreadable + 1 read
    expect(script.posted.map((p) => p['requestId']).toSet(), hasLength(1));
  });

  test('a prayer the script rejects as malformed leaves the phone', () async {
    final o = outbox(_FakeScript(reject: 'bad_request_id'));
    await o.enqueue(text: 'x');
    await o.flush();
    expect(await o.pending(), isEmpty);
  });

  test('without a configured endpoint nothing is lost', () async {
    final o = outbox(_FakeScript(), endpoint: '');
    await o.enqueue(text: 'Guidance');
    await o.flush();
    expect(await o.pending(), hasLength(1));
  });

  test('every prayer is anonymous: only the text, a random id and the Sabbath are sent', () async {
    final script = _FakeScript();
    final o = outbox(script);
    await o.enqueue(text: 'Provision for my family');
    await o.flush();
    final sent = script.posted.single;
    expect(sent.keys.toSet(), {'requestId', 'prayer', 'cycle'});
    final raw = jsonEncode(sent);
    for (final leak in ['Brian', 'Mtana', '0705061269', 'Technical University', 'u-1', 'c0ffee00']) {
      expect(raw.contains(leak), isFalse, reason: 'leaked $leak');
    }
  });
}
