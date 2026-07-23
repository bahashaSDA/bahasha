import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

/// The on-device source of truth.
///
/// Bahasha is offline-first: registration, the contribution outbox, history,
/// and settings all live here so the app is fully usable with no connectivity,
/// and a background sync reconciles with the backend when the network returns.
/// SQLite via Drift gives typed queries and migrations without hand-written SQL.

/// The local profile. One row: this device's registered giver. `synced`
/// distinguishes a purely-local registration from one the backend has accepted.
class LocalUsers extends Table {
  TextColumn get clientUuid => text()();
  TextColumn get serverUserId => text().nullable()();
  TextColumn get fullName => text()();
  TextColumn get phone => text()();
  TextColumn get churchId => text()();
  TextColumn get membershipStatus => text()();
  TextColumn get visibility => text().withDefault(const Constant('open'))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get registeredAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

/// The contribution outbox / history. A contribution is created locally the
/// instant the member taps Send, and lives here through its whole lifecycle:
/// queued → sent over BLE → settled by the backend. Nothing is lost if the app
/// is offline or the member walks out of Bluetooth range mid-transfer.
class Contributions extends Table {
  TextColumn get id => text()(); // client-minted UUID = idempotency key
  TextColumn get churchId => text()();
  IntColumn get totalAmount => integer()(); // whole shillings
  // JSON: [{"categoryCode":"tithe","amount":1000}, ...]
  TextColumn get allocationsJson => text()();
  BoolColumn get anonymous => boolean().withDefault(const Constant(false))();
  // queued | transmitting | sent | processing | completed | failed | cancelled
  TextColumn get status => text().withDefault(const Constant('queued'))();
  IntColumn get counter => integer()(); // per-device replay counter used at signing
  TextColumn get nonce => text().nullable()();
  TextColumn get signature => text().nullable()();
  TextColumn get failureReason => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached church list, so the picker works offline on second launch.
class CachedChurches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get slug => text()();
  TextColumn get publicKey => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached categories, so the giving screen works offline.
class CachedCategories extends Table {
  TextColumn get code => text()();
  TextColumn get churchId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  RealColumn get fixedAmount => real().nullable()();
  RealColumn get percentageHint => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {code};
}

/// Per-device appearance settings (mirrors the backend `themes` table), stored
/// locally first and synced up so a reinstall restores the chosen look.
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get mode => text().withDefault(const Constant('system'))();
  TextColumn get primaryColor => text().withDefault(const Constant('#231F4F'))();
  TextColumn get accentColor => text().withDefault(const Constant('#89D385'))();
  TextColumn get backgroundColor =>
      text().withDefault(const Constant('#D1EFBD'))();
  RealColumn get fontScale => real().withDefault(const Constant(1.0))();

  /// JSON blob of the giver's custom colour choices (Customize screen):
  /// { "background": "#RRGGBB", "send": "#RRGGBB", "category": { code: hex } }.
  /// Null until the giver customises anything; screens fall back to defaults.
  TextColumn get customColorsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The next monotonic replay counter for this device's signatures. Kept as a
/// single-row table so the increment is transactional and never regresses.
class SignCounter extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get value => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalUsers,
    Contributions,
    CachedChurches,
    CachedCategories,
    AppSettings,
    SignCounter,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_open());
  LocalDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2 adds AppSettings.customColorsJson for the Customize screen.
          if (from < 2) {
            await m.addColumn(appSettings, appSettings.customColorsJson);
          }
        },
      );

  /// Atomically returns the next replay counter, persisting the increment so a
  /// crash cannot reuse a value. The backend rejects any non-increasing
  /// counter, so this must be strictly monotonic across the app's lifetime.
  Future<int> nextCounter() {
    return transaction(() async {
      final row = await (select(signCounter)..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      final next = (row?.value ?? 0) + 1;
      await into(signCounter).insertOnConflictUpdate(
        SignCounterCompanion(id: const Value(1), value: Value(next)),
      );
      return next;
    });
  }

  /// The local giver profile, if registration has happened.
  Future<LocalUser?> currentUser() =>
      select(localUsers).getSingleOrNull();

  /// Contributions not yet settled, oldest first — the sync queue.
  Future<List<Contribution>> pendingContributions() {
    return (select(contributions)
          ..where((t) => t.status.isNotIn(['completed', 'cancelled']))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Full history, newest first.
  Future<List<Contribution>> history() {
    return (select(contributions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Stream<List<Contribution>> watchHistory() {
    return (select(contributions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'bahasha.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
