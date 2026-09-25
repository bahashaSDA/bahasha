import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bahasha/core/ble/hub_protocol.dart';
import 'package:bahasha/core/crypto/payload_signer.dart';
import 'package:bahasha/core/data/contribution_repository.dart';
import 'package:bahasha/core/data/local_database.dart';
import 'package:bahasha/core/data/registration_repository.dart';
import 'package:bahasha/features/contribution/application/giving_relay.dart';
import 'package:bahasha/features/prayer/data/prayer_outbox.dart';
import 'fake_hub.dart';

/// Bahasha is fully offline: registration, offerings and prayers all reach
/// the church through a CVendor hub over BLE. These drive the real relay,
/// repositories and signer against a fake hub.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = <String, String>{};
  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      if (call.method == 'read') return store[args['key'] as String];
      if (call.method == 'write') store[args['key'] as String] = args['value'] as String;
      if (call.method == 'containsKey') return store.containsKey(args['key'] as String);
      return null;
    });
  });

  late LocalDatabase db;
  late ContributionRepository contributions;
  late RegistrationRepository registration;
  late PrayerOutbox prayers;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    final signer = PayloadSigner();
    contributions = ContributionRepository(db: db, signer: signer);
    registration = RegistrationRepository(db: db, signer: signer);
    prayers = PrayerOutbox();
    await registration.registerLocally(
      fullName: 'Brian Mtana',
      phone: '0705061269',
      churchId: 'Technical University of Kenya SDA Church',
      membershipStatus: 'member',
      visibility: 'open',
    );
  });
  tearDown(() => db.close());

  GivingRelay relay(FakeHub hub) =>
      GivingRelay(db: db, contributions: contributions, registration: registration, prayers: prayers, connector: hub);

  Future<LocalUser> user() async => (await db.currentUser())!;

  test('first give: registers through the hub, then hands over the signed offering and the prayer', () async {
    final hub = FakeHub();
    await contributions.createQueued(allocations: {'tithe': 300}, user: await user());
    await prayers.enqueue(text: 'Healing for my mother');

    final r = await relay(hub).drain();

    expect(r.hubFound, isTrue);
    expect(r.registered, isTrue);
    expect(r.offeringsHanded, 1);
    expect(r.offeringsWaiting, 0);
    expect(r.prayersHanded, 1);
    expect(r.church, 'TUK SDA Church');

    // Order matters: register BEFORE the offering (it needs the server id).
    expect(hub.received.map((m) => m['type'] ?? 'offering').toList(), ['register', 'offering', 'prayer']);
    final reg = hub.registrations.single['body'] as Map<String, dynamic>;
    expect(reg['phone'], '0705061269');
    expect((reg['device'] as Map)['publicKey'], isNotEmpty);

    final offering = hub.offerings.single;
    expect(offering['userId'], FakeHub.serverUserId);
    expect(offering['msisdn'], '+254705061269');
    expect((offering['nonce'] as String).startsWith('hubnonce1'), isTrue);

    // Prayer: anonymous — only the random id and the text.
    expect(hub.prayers.single.keys.toSet(), {'type', 'requestId', 'prayer'});
    expect(jsonEncode(hub.prayers.single).contains('Brian'), isFalse);

    final u = await user();
    expect(u.serverUserId, FakeHub.serverUserId);
    expect(u.synced, isTrue);
    expect((await db.history()).single.status, 'sent');
    expect(await prayers.pending(), isEmpty);
  });

  test('no collector in range: everything stays safely on the phone', () async {
    final hub = FakeHub(inRange: false);
    await contributions.createQueued(allocations: {'tithe': 300}, user: await user());
    await prayers.enqueue(text: 'Guidance');
    final r = await relay(hub).drain();
    expect(r.hubFound, isFalse);
    expect(r.offeringsWaiting, 1);
    expect((await db.history()).single.status, 'queued');
    expect(await prayers.pending(), hasLength(1));
  });

  test('hub offline: registration waits and no offering is handed over; the prayer still goes', () async {
    final hub = FakeHub(online: false);
    await contributions.createQueued(allocations: {'tithe': 300}, user: await user());
    await prayers.enqueue(text: 'Peace');
    final r = await relay(hub).drain();
    expect(r.registrationPending, isTrue);
    expect(hub.offerings, isEmpty);
    expect((await db.history()).single.status, 'queued');
    expect(r.prayersHanded, 1);

    // Next time the hub is online, it goes through.
    hub.online = true;
    final r2 = await relay(hub).drain();
    expect(r2.registered, isTrue);
    expect(r2.offeringsHanded, 1);
  });

  test('backend refuses the details: nothing is handed over, the giver is told', () async {
    final hub = FakeHub(refuseRegistration: true);
    await contributions.createQueued(allocations: {'tithe': 300}, user: await user());
    final r = await relay(hub).drain();
    expect(r.registrationRefused, isTrue);
    expect(hub.offerings, isEmpty);
    expect((await db.history()).single.status, 'queued');
  });

  test('walking out of range mid-session: the offering returns to the queue and is re-signed next time', () async {
    final hub = FakeHub(dropAfter: 1); // register goes, offering drops
    await contributions.createQueued(allocations: {'tithe': 300}, user: await user());
    final r = await relay(hub).drain();
    expect(r.offeringsHanded, 0);
    expect((await db.history()).single.status, 'queued');

    hub.dropAfter = null;
    final r2 = await relay(hub).drain();
    expect(r2.registered, isFalse); // already registered last time
    expect(r2.offeringsHanded, 1);
    expect(hub.offerings.single['idempotencyKey'], (await db.history()).single.id);
  });

  test('an edit to the phone number re-registers before the next offering', () async {
    final hub = FakeHub();
    await relay(hub).drain(); // registers (nothing else waiting)
    expect(hub.registrations, hasLength(1));

    await registration.updateProfile(fullName: 'Brian Mtana', phone: '0711000111');
    await contributions.createQueued(allocations: {'offering': 50}, user: await user());
    await relay(hub).drain();

    expect(hub.registrations, hasLength(2));
    expect((hub.registrations.last['body'] as Map)['phone'], '0711000111');
    expect(hub.offerings.single['msisdn'], '+254711000111');
    expect(hub.received.indexOf(hub.registrations.last), lessThan(hub.received.indexOf(hub.offerings.single)));
  });

  test('two offerings in one session each get their own nonce', () async {
    final hub = FakeHub();
    await contributions.createQueued(allocations: {'tithe': 300}, user: await user());
    await contributions.createQueued(allocations: {'mission': 100}, user: await user());
    final r = await relay(hub).drain();
    expect(r.offeringsHanded, 2);
    expect(hub.offerings.map((o) => o['nonce']).toSet(), hasLength(2));
  });

  test('a call during a running session runs one more, so nothing queued meanwhile is left behind', () async {
    final hub = FakeHub();
    final rel = relay(hub);
    final first = rel.drain();
    await contributions.createQueued(allocations: {'tithe': 10}, user: await user());
    final second = rel.drain();
    await first;
    await second;
    expect(hub.offerings, hasLength(1));
    expect((await db.history()).single.status, 'sent');
  });

  test('ack wire format round-trips the server user id', () {
    final ack = HubAck.parse([HubProtocol.ackAccepted, ...HubAck.uuidToBytes(FakeHub.serverUserId)]);
    expect(ack.accepted, isTrue);
    expect(ack.userId, FakeHub.serverUserId);
    expect(HubAck.parse([]).status, HubProtocol.ackRejected);
    expect(HubChallenge.parse(utf8.encode('{"v":1,"nonce":"abcdef1234","church":"TUK"}'))!.church, 'TUK');
    expect(HubChallenge.parse(utf8.encode('not json')), isNull);
  });

  test('prayers: empty or whitespace never saved; handed prayers leave the phone', () async {
    expect(await prayers.enqueue(text: '   '), isNull);
    final p = await prayers.enqueue(text: '  Strength  ');
    expect(p!.text, 'Strength');
    await prayers.remove(p.id);
    expect(await prayers.pending(), isEmpty);
  });
}
