import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'hub_database.g.dart';

/// The hub's local queue.
///
/// Every payload received over BLE is written here FIRST, before any upload is
/// attempted, so a payload is never lost if the hub is briefly offline or the
/// process is killed. The upload service drains this queue to the backend and
/// marks each row uploaded or failed. This is what makes the hub resilient on a
/// congested Sabbath network.
class ReceivedPayloads extends Table {
  /// The idempotency key carried in the payload — dedupes re-received packets.
  TextColumn get idempotencyKey => text()();
  /// The raw decrypted payload JSON exactly as reassembled from BLE chunks.
  TextColumn get payloadJson => text()();
  TextColumn get deviceUuid => text().nullable()();
  // received | uploading | uploaded | rejected | failed
  TextColumn get status => text().withDefault(const Constant('received'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {idempotencyKey};
}

/// Append-only log of upload activity, surfaced in the dashboard.
class UploadLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get message => text()();
  TextColumn get level => text().withDefault(const Constant('info'))(); // info|warn|error
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [ReceivedPayloads, UploadLog])
class HubDatabase extends _$HubDatabase {
  HubDatabase() : super(_open());
  HubDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<void> enqueue(String idempotencyKey, String payloadJson, String? deviceUuid) {
    return into(receivedPayloads).insert(
      ReceivedPayloadsCompanion(
        idempotencyKey: Value(idempotencyKey),
        payloadJson: Value(payloadJson),
        deviceUuid: Value(deviceUuid),
      ),
      // A re-received packet (same key) is ignored — the hub must not enqueue
      // duplicates; the backend is idempotent too, but this avoids the round trip.
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<List<ReceivedPayload>> pending() {
    return (select(receivedPayloads)
          ..where((t) => t.status.isIn(['received', 'failed']))
          ..orderBy([(t) => OrderingTerm.asc(t.receivedAt)]))
        .get();
  }

  Stream<List<ReceivedPayload>> watchAll() {
    return (select(receivedPayloads)
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .watch();
  }

  Future<void> setStatus(String key, String status, {String? error}) {
    return (update(receivedPayloads)..where((t) => t.idempotencyKey.equals(key))).write(
      ReceivedPayloadsCompanion(
        status: Value(status),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> incrementAttempts(String key) async {
    final row = await (select(receivedPayloads)..where((t) => t.idempotencyKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(receivedPayloads)..where((t) => t.idempotencyKey.equals(key)))
        .write(ReceivedPayloadsCompanion(attempts: Value(row.attempts + 1)));
  }

  Future<void> log(String message, {String level = 'info'}) {
    return into(uploadLog).insert(
      UploadLogCompanion(message: Value(message), level: Value(level)),
    );
  }

  Stream<List<UploadLogData>> watchLog() {
    return (select(uploadLog)
          ..orderBy([(t) => OrderingTerm.desc(t.at)])
          ..limit(100))
        .watch();
  }

  /// Count of payloads uploaded today, for the dashboard headline.
  Future<int> uploadedTodayCount() async {
    final start = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final rows = await (select(receivedPayloads)
          ..where((t) => t.status.equals('uploaded') & t.updatedAt.isBiggerThanValue(start)))
        .get();
    return rows.length;
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(File(p.join(dir.path, 'cvendor.sqlite')));
  });
}
