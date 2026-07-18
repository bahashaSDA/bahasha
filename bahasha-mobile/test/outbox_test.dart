import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahasha/core/crypto/payload_signer.dart';
import 'package:bahasha/core/data/local_database.dart';
import 'package:bahasha/core/data/contribution_repository.dart';

/// Proves the on-device give path against an in-memory database:
/// a basket becomes a durable, signed outbox entry with a strictly-increasing
/// replay counter — the properties the backend relies on for idempotency and
/// replay defence.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase db;
  late ContributionRepository repo;
  late PayloadSigner signer;

  // Back flutter_secure_storage with an in-memory map by mocking its platform
  // channel, so the signer can persist and reload its keypair seed under test.
  final store = <String, String>{};
  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'read':
          return store[args['key'] as String];
        case 'write':
          store[args['key'] as String] = args['value'] as String;
          return null;
        case 'delete':
          store.remove(args['key'] as String);
          return null;
        case 'containsKey':
          return store.containsKey(args['key'] as String);
        case 'readAll':
          return Map<String, String>.from(store);
        default:
          return null;
      }
    });
  });

  setUp(() {
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    signer = PayloadSigner();
    repo = ContributionRepository(db: db, signer: signer);
  });

  tearDown(() async => db.close());

  LocalUser user() => LocalUser(
        clientUuid: 'client-1',
        serverUserId: 'user-1',
        fullName: 'Grace Wanjiru',
        phone: '+254712345678',
        churchId: 'church-1',
        membershipStatus: 'member',
        visibility: 'open',
        synced: true,
        registeredAt: DateTime.now(),
      );

  test('a basket becomes a signed, queued contribution', () async {
    final id = await repo.createSigned(
      allocations: {'tithe': 1000, 'conference_evangelism': 500, 'church_building': 200},
      user: user(),
    );

    final row = await (db.select(db.contributions)..where((t) => t.id.equals(id))).getSingle();
    expect(row.totalAmount, 1700);
    expect(row.status, 'queued');
    expect(row.signature, isNotNull);
    expect(row.counter, 1);

    final allocations = (jsonDecode(row.allocationsJson) as List).cast<Map<String, dynamic>>();
    expect(allocations.length, 3);
    expect(allocations.fold<int>(0, (s, a) => s + (a['amount'] as int)), 1700);
  });

  test('replay counter is strictly increasing across contributions', () async {
    final id1 = await repo.createSigned(allocations: {'tithe': 100}, user: user());
    final id2 = await repo.createSigned(allocations: {'welfare': 200}, user: user());

    final c1 = await (db.select(db.contributions)..where((t) => t.id.equals(id1))).getSingle();
    final c2 = await (db.select(db.contributions)..where((t) => t.id.equals(id2))).getSingle();

    expect(c2.counter, greaterThan(c1.counter));
  });

  test('secret giver produces an anonymous-flagged contribution', () async {
    final secretUser = user().copyWith(visibility: 'secret');
    final id = await repo.createSigned(allocations: {'thanksgiving': 300}, user: secretUser);
    final row = await (db.select(db.contributions)..where((t) => t.id.equals(id))).getSingle();
    expect(row.anonymous, isTrue);
  });

  test('an empty basket is refused', () async {
    expect(
      () => repo.createSigned(allocations: {'tithe': 0}, user: user()),
      throwsA(isA<ArgumentError>()),
    );
  });
}
