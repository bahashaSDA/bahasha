import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
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

  test('a basket is saved as a queued contribution, unsigned until hand-over', () async {
    final id = await repo.createQueued(
      allocations: {'tithe': 1000, 'conference_evangelism': 500, 'church_building': 200},
      user: user(),
    );

    final row = await (db.select(db.contributions)..where((t) => t.id.equals(id))).getSingle();
    expect(row.totalAmount, 1700);
    expect(row.status, 'queued');
    expect(row.signature, isNull);

    final allocations = (jsonDecode(row.allocationsJson) as List).cast<Map<String, dynamic>>();
    expect(allocations.length, 3);
    expect(allocations.fold<int>(0, (s, a) => s + (a['amount'] as int)), 1700);
  });

  test('hand-over signs the exact /ingest payload, and the signature verifies', () async {
    final id = await repo.createQueued(allocations: {'tithe': 1000, 'mission': 700}, user: user().copyWith(phone: '0712 345 678'));
    final row = (await repo.awaitingHandover()).single;
    expect(row.id, id);

    final env = await repo.envelopeFor(row, user().copyWith(phone: '0712 345 678'), 'hubnonce123-0');
    expect(env['userId'], 'user-1'); // the SERVER user id, never the client uuid
    expect(env['msisdn'], '+254712345678'); // E.164, as the backend stores it
    expect(env['totalAmount'], 1700);
    expect(env['nonce'], 'hubnonce123-0');
    expect(env['algorithm'], 'ed25519');
    expect((env['allocations'] as List).length, 2);

    // Verify with the device public key over the canonical bytes — what
    // backend/src/services/ingest.ts does.
    final spki = base64Decode(await signer.publicKeySpkiBase64());
    final pub = SimplePublicKey(spki.sublist(12), type: KeyPairType.ed25519);
    final message = PayloadSigner.canonicalBytes(
      idempotencyKey: env['idempotencyKey'] as String,
      deviceUuid: env['deviceUuid'] as String,
      userId: env['userId'] as String,
      homeChurch: env['homeChurch'] as String,
      msisdn: env['msisdn'] as String,
      totalAmount: env['totalAmount'] as int,
      counter: env['counter'] as int,
      nonce: env['nonce'] as String,
      deviceTimestamp: env['deviceTimestamp'] as String,
      anonymous: env['anonymous'] as bool,
    );
    final ok = await Ed25519().verify(message,
        signature: Signature(base64Decode(env['signature'] as String), publicKey: pub));
    expect(ok, isTrue);

    final signed = await (db.select(db.contributions)..where((t) => t.id.equals(id))).getSingle();
    expect(signed.status, 'transmitting');
    expect(signed.signature, env['signature']);
  });

  test('every hand-over takes a strictly higher replay counter', () async {
    await repo.createQueued(allocations: {'tithe': 100}, user: user());
    await repo.createQueued(allocations: {'welfare': 200}, user: user());
    final rows = await repo.awaitingHandover();
    final a = await repo.envelopeFor(rows[0], user(), 'n-0000000');
    final b = await repo.envelopeFor(rows[1], user(), 'n-0000001');
    // Re-signing a retry takes a new counter too (same idempotency key).
    final again = await repo.envelopeFor(rows[0], user(), 'n-0000002');
    expect(b['counter'] as int, greaterThan(a['counter'] as int));
    expect(again['counter'] as int, greaterThan(b['counter'] as int));
    expect(again['idempotencyKey'], a['idempotencyKey']);
  });

  test('cannot sign before the backend has registered the giver', () async {
    await repo.createQueued(allocations: {'tithe': 100}, user: user());
    final row = (await repo.awaitingHandover()).single;
    expect(() => repo.envelopeFor(row, user().copyWith(serverUserId: const Value(null)), 'n-0000000'),
        throwsA(isA<StateError>()));
  });

  test('secret giver produces an anonymous-flagged contribution', () async {
    final secretUser = user().copyWith(visibility: 'secret');
    final id = await repo.createQueued(allocations: {'thanksgiving': 300}, user: secretUser);
    final row = await (db.select(db.contributions)..where((t) => t.id.equals(id))).getSingle();
    expect(row.anonymous, isTrue);
    expect((await repo.envelopeFor(row, secretUser, 'n-0000000'))['anonymous'], isTrue);
  });

  test('an empty basket is refused', () async {
    expect(
      () => repo.createQueued(allocations: {'tithe': 0}, user: user()),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('phone numbers normalise exactly like the backend', () {
    expect(ContributionRepository.normalizeMsisdn('0712345678'), '+254712345678');
    expect(ContributionRepository.normalizeMsisdn('+254 712-345-678'), '+254712345678');
    expect(ContributionRepository.normalizeMsisdn('254112345678'), '+254112345678');
    expect(ContributionRepository.normalizeMsisdn('712345678'), '+254712345678');
    expect(ContributionRepository.normalizeMsisdn('0812345678'), isNull);
    expect(ContributionRepository.normalizeMsisdn('12345'), isNull);
  });
}
