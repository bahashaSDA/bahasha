import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cvendor/core/hub_database.dart';
import 'package:cvendor/core/hub_protocol.dart';
import 'package:cvendor/core/prayer_relay.dart';

/// The hub relays everything an offline Bahasha phone needs: registration,
/// offerings and anonymous prayers.
void main() {
  Uint8List msg(Map<String, dynamic> m) => Uint8List.fromList(utf8.encode(jsonEncode(m)));
  const userId = '0f8fad5b-d9cb-469f-a165-70867728950e';
  const key = 'ea87c870-3030-4806-946c-92a2eb12e90a';

  group('HubMessageHandler', () {
    late List<String> offerings;
    late List<(String, String)> prayers;
    late RegisterOutcome registerOutcome;

    HubMessageHandler handler() => HubMessageHandler(
          enqueueOffering: (k, json, d) async => offerings.add(k),
          register: (body) async =>
              (registerOutcome, registerOutcome == RegisterOutcome.registered ? userId : null),
          enqueuePrayer: (id, text) async => prayers.add((id, text)),
        );

    setUp(() {
      offerings = [];
      prayers = [];
      registerOutcome = RegisterOutcome.registered;
    });

    test('registration: relays and returns the server user id in the ack', () async {
      final ack = await handler().handle(msg({'type': 'register', 'body': {'clientUuid': 'x'}}), issuedNonce: 'n');
      expect(ack.first, HubProtocol.ackAccepted);
      expect(ack.sublist(1), HubProtocol.uuidToBytes(userId));
    });

    test('registration: offline → retry later; refused → phone is told', () async {
      registerOutcome = RegisterOutcome.offline;
      expect((await handler().handle(msg({'type': 'register', 'body': {}}), issuedNonce: 'n')).first,
          HubProtocol.ackHubOffline);
      registerOutcome = RegisterOutcome.refused;
      expect((await handler().handle(msg({'type': 'register', 'body': {}}), issuedNonce: 'n')).first,
          HubProtocol.ackRefused);
    });

    test('offering: accepted only when signed with this session\'s challenge', () async {
      final h = handler();
      final ok = await h.handle(msg({'idempotencyKey': key, 'nonce': 'abc123def456-0'}), issuedNonce: 'abc123def456');
      expect(ok.first, HubProtocol.ackAccepted);
      expect(offerings, [key]);

      final replayed = await h.handle(msg({'idempotencyKey': key, 'nonce': 'oldsession99-0'}), issuedNonce: 'abc123def456');
      expect(replayed.first, HubProtocol.ackRejected);
      final noChallenge = await h.handle(msg({'idempotencyKey': key, 'nonce': 'abc123def456-0'}), issuedNonce: null);
      expect(noChallenge.first, HubProtocol.ackRejected);
      expect(offerings, hasLength(1));
    });

    test('prayer: keeps only the random id and the text', () async {
      final ack = await handler()
          .handle(msg({'type': 'prayer', 'requestId': key, 'prayer': '  Healing  ', 'giverName': 'Brian'}), issuedNonce: 'n');
      expect(ack.first, HubProtocol.ackAccepted);
      expect(prayers, [(key, 'Healing')]);
    });

    test('malformed or unknown messages are rejected', () async {
      final h = handler();
      expect((await h.handle(Uint8List.fromList([1, 2, 3]), issuedNonce: 'n')).first, HubProtocol.ackRejected);
      expect((await h.handle(msg({'type': 'prayer', 'requestId': 'nope', 'prayer': 'x'}), issuedNonce: 'n')).first,
          HubProtocol.ackRejected);
      expect((await h.handle(msg({'type': 'surprise'}), issuedNonce: 'n')).first, HubProtocol.ackRejected);
    });

    test('challenge carries a fresh 32-hex nonce and the church', () {
      final a = HubProtocol.newNonce();
      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(HubProtocol.newNonce(), isNot(a));
      final c = jsonDecode(utf8.decode(HubProtocol.challenge(a, 'TUK SDA Church'))) as Map;
      expect(c, {'v': 1, 'nonce': a, 'church': 'TUK SDA Church'});
    });
  });

  test('a re-sent offering replaces the unuploaded copy (fresher signature), never an uploaded one', () async {
    final db = HubDatabase.forTesting(NativeDatabase.memory());
    await db.enqueueOrRefresh(key, '{"v":"old"}', 'd');
    await db.enqueueOrRefresh(key, '{"v":"new"}', 'd');
    expect((await db.pending()).single.payloadJson, '{"v":"new"}');

    await db.setStatus(key, 'uploaded');
    await db.enqueueOrRefresh(key, '{"v":"newer"}', 'd');
    expect(await db.pending(), isEmpty);
    await db.close();
  });

  group('PrayerRelay', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('delivers to the sheet, retrying a flaky echo page, then forgets the prayer', () async {
      final script = _Script(flakyEchoes: 2);
      final relay = PrayerRelay(dio: Dio(BaseOptions(followRedirects: false, validateStatus: (s) => s != null && s < 500))
        ..httpClientAdapter = script, endpoint: 'https://script.test/exec')
        ..retryDelay = Duration.zero;
      await relay.enqueue(key, 'Healing');
      await relay.flush();
      expect(await relay.pending(), isEmpty);
      expect(script.posted.map((p) => p['requestId']).toSet(), {key});
      expect(script.posted.first.keys.toSet(), {'requestId', 'prayer'});
    });

    test('offline: held on the hub until the network returns; a phone retry is not duplicated', () async {
      final script = _Script(online: false);
      final relay = PrayerRelay(dio: Dio(BaseOptions(followRedirects: false, validateStatus: (s) => s != null && s < 500))
        ..httpClientAdapter = script, endpoint: 'https://script.test/exec')
        ..retryDelay = Duration.zero;
      await relay.enqueue(key, 'Peace');
      await relay.enqueue(key, 'Peace');
      await relay.flush();
      expect(await relay.pending(), hasLength(1));
      script.online = true;
      await relay.flush();
      expect(await relay.pending(), isEmpty);
    });
  });
}

/// Mimics the Apps Script web app: POST → 302 → echo JSON (sometimes 404).
class _Script implements HttpClientAdapter {
  _Script({this.online = true, this.flakyEchoes = 0});
  bool online;
  int flakyEchoes;
  final posted = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    if (!online) throw DioException.connectionError(requestOptions: o, reason: 'offline');
    if (o.method == 'POST') {
      final bytes = await body!.fold<List<int>>([], (a, b) => a..addAll(b));
      posted.add(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
      return ResponseBody.fromString('', 302, headers: {'location': ['https://echo.test']});
    }
    if (flakyEchoes > 0) {
      flakyEchoes--;
      return ResponseBody.fromString('not found', 404);
    }
    return ResponseBody.fromString('{"ok":true}', 200);
  }

  @override
  void close({bool force = false}) {}
}
