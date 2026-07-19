import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hub_database.dart';
import 'hub_session.dart';

/// Shared singletons. The BLE receiver, ingest client, and upload service are
/// constructed by the dashboard once the hub is paired (they need the API key),
/// so they are not provided here.

final hubDatabaseProvider = Provider<HubDatabase>((ref) {
  final db = HubDatabase();
  ref.onDispose(db.close);
  return db;
});

final hubSessionProvider = Provider<HubSession>((ref) => HubSession());

/// Whether the hub has been paired (an API key is stored). Drives the gate
/// between the pairing screen and the dashboard.
final isPairedProvider = FutureProvider<bool>((ref) {
  return ref.watch(hubSessionProvider).isPaired;
});
