import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bahasha/core/ble/vendor_presence.dart';
import 'package:bahasha/core/data/local_database.dart';
import 'package:bahasha/core/providers.dart';
import 'package:bahasha/features/contribution/presentation/home_screen.dart';
import 'package:bahasha/features/contribution/presentation/thank_you_screen.dart';
import 'package:bahasha/features/contribution/application/giving_relay.dart';
import 'package:bahasha/features/prayer/data/prayer_outbox.dart';
import 'fake_hub.dart';
import 'package:bahasha/features/prayer/presentation/prayer_screen.dart';
import 'package:bahasha/features/tour/tour_controller.dart';
import 'package:bahasha/features/tour/tour_overlay.dart';

/// End-to-end giving journey on the real screens, against an in-memory
/// database and the real signer: keypad → Send → (optional) prayer → Send →
/// offering signed into the outbox → prayer queued and delivered.

class _Vendor extends VendorPresenceController {
  @override
  VendorPresence build() => const VendorPresence(VendorStatus.found, name: 'Bahasha Hub');
  @override
  Future<void> scan({Duration timeout = const Duration(seconds: 12)}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = <String, String>{};

  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'read':
          return store[args['key'] as String];
        case 'write':
          store[args['key'] as String] = args['value'] as String;
          return null;
        case 'containsKey':
          return store.containsKey(args['key'] as String);
        default:
          return null;
      }
    });
  });

  late LocalDatabase db;
  late FakeHub hub;

  Future<ProviderContainer> app(WidgetTester t, {bool tourDone = true}) async {
    t.view.physicalSize = const Size(420, 912);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({if (tourDone) 'bahasha.tour.v2.done': true});
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    await t.runAsync(() => db.into(db.localUsers).insert(LocalUsersCompanion.insert(
          clientUuid: 'c-1',
          fullName: 'Brian Mtana',
          phone: '0705061269',
          churchId: 'Technical University of Kenya SDA Church',
          membershipStatus: 'member',
          serverUserId: const Value('u-1'),
        )));
    hub = FakeHub();
    final container = ProviderContainer(overrides: [
      localDatabaseProvider.overrideWithValue(db),
      hubConnectorProvider.overrideWithValue(hub),
      vendorPresenceProvider.overrideWith(_Vendor.new),
    ]);
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        builder: (c, child) => TourHost(child: child!),
        home: const HomeScreen(),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump(const Duration(milliseconds: 100));
    return container;
  }

  Future<void> settle(WidgetTester t, [int ms = 700]) async {
    for (var i = 0; i < 4; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await t.pump(Duration(milliseconds: ms ~/ 4));
    }
  }

  /// Real async work (Ed25519 signing, SQLite) needs wall-clock time.
  Future<void> until(WidgetTester t, Finder f) async {
    for (var i = 0; i < 60 && f.evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await settle(t);
  }

  Future<void> type(WidgetTester t, String digits) async {
    for (final d in digits.split('')) {
      await t.tap(find.text(d).first);
      await t.pump();
    }
  }

  testWidgets('give with a prayer: registered, offering and anonymous prayer handed over Bluetooth', (t) async {
    await app(t);
    await type(t, '300');
    expect(find.text('300'), findsOneWidget);

    await t.tap(find.bySemanticsLabel('Review and send'));
    await settle(t);
    expect(find.text('Total'), findsWidgets);

    // First Send opens the optional prayer step.
    await t.tap(find.bySemanticsLabel('Send offering'));
    await settle(t);
    expect(find.byType(PrayerScreen), findsOneWidget);
    await t.enterText(find.byType(TextField), '  Healing for my mother  ');
    await t.tap(find.bySemanticsLabel('Add prayer and continue'));
    await settle(t);
    expect(find.byType(PrayerScreen), findsNothing);

    // Second Send gives.
    await t.tap(find.bySemanticsLabel('Send offering'));
    await until(t, find.byType(ThankYouScreen));
    expect(find.byType(ThankYouScreen), findsOneWidget);

    final rows = await t.runAsync(() => db.history());
    expect(rows, hasLength(1));
    expect(rows!.single.totalAmount, 300);
    // Handed to the collector over Bluetooth (registering on the way).
    expect(rows.single.status, 'sent');
    expect(find.textContaining('Handed to TUK SDA Church'), findsOneWidget);
    expect(hub.registrations, hasLength(1));
    expect(hub.offerings.single['totalAmount'], 300);
    expect(hub.prayers.single['prayer'], 'Healing for my mother');
    // Anonymous: nothing ties the prayer to the giver or the offering.
    expect(hub.prayers.single.keys.toSet(), {'type', 'requestId', 'prayer'});
    expect(jsonEncode(hub.prayers.single).contains(rows.single.id.substring(0, 8)), isFalse);
    await t.pump(const Duration(seconds: 5)); // let snackbars expire
  });

  testWidgets('skip the prayer: offering still handed over, no prayer saved', (t) async {
    await app(t);
    await type(t, '50');
    await t.tap(find.bySemanticsLabel('Review and send'));
    await settle(t);
    await t.tap(find.bySemanticsLabel('Send offering'));
    await settle(t);
    // Type something, then back out: it must NOT be attached.
    await t.enterText(find.byType(TextField), 'draft I changed my mind about');
    final nav = appNavigatorKey.currentState!;
    nav.pop();
    await settle(t);
    await t.tap(find.bySemanticsLabel('Send offering'));
    await until(t, find.byType(ThankYouScreen));
    expect(find.byType(ThankYouScreen), findsOneWidget);
    expect(await t.runAsync(() => db.history()), hasLength(1));
    expect(hub.offerings, hasLength(1));
    expect(hub.prayers, isEmpty);
    expect(await t.runAsync(() => PrayerOutbox().pending()), isEmpty);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('first-run tour walks every step on the real screens, then never again', (t) async {
    final c = await app(t, tourDone: false);
    await settle(t, 800);
    expect(c.read(tourProvider), 0);
    for (var i = 0; i < tourSteps.length; i++) {
      expect(find.text(tourSteps[i].body), findsOneWidget, reason: 'step $i');
      await t.tap(find.bySemanticsLabel(i == tourSteps.length - 1 ? 'Start giving' : 'Next'));
      await settle(t, 800);
    }
    expect(c.read(tourProvider), isNull);
    final prefs = await t.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getBool('bahasha.tour.v2.done'), isTrue);
    // Back on Home with nothing left pushed.
    expect(appNavigatorKey.currentState!.canPop(), isFalse);
  });
}
