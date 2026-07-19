import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/providers.dart';
import '../core/hub_database.dart';
import '../core/ingest_client.dart';
import '../core/upload_service.dart';
import '../core/ble_receiver.dart';
import '../theme.dart';

/// The hub's operational dashboard. Once paired, the deacon leaves this running
/// during the service: it advertises over BLE, receives contributions, queues
/// them locally, and uploads them to the backend. The screen shows live status,
/// today's collection count, the pending queue, and an activity log.
class HubDashboardScreen extends ConsumerStatefulWidget {
  const HubDashboardScreen({super.key});

  @override
  ConsumerState<HubDashboardScreen> createState() => _HubDashboardScreenState();
}

class _HubDashboardScreenState extends ConsumerState<HubDashboardScreen> {
  BleReceiver? _receiver;
  UploadService? _upload;
  String _bleStatus = 'Starting…';
  StreamSubscription<String>? _statusSub;

  @override
  void initState() {
    super.initState();
    _bootHub();
  }

  Future<void> _bootHub() async {
    // BLE + nearby permissions are required to advertise and receive.
    await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    final db = ref.read(hubDatabaseProvider);
    final session = ref.read(hubSessionProvider);
    final apiKey = await session.apiKey;
    if (apiKey == null) return;

    // Start the upload pump.
    _upload = UploadService(db: db, client: IngestClient(apiKey: apiKey))..start();

    // Start the BLE peripheral.
    final receiver = BleReceiver(db: db);
    _receiver = receiver;
    _statusSub = receiver.status.listen((s) {
      if (mounted) setState(() => _bleStatus = s);
    });
    await receiver.start();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _receiver?.stop();
    _receiver?.dispose();
    _upload?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(hubDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Hub', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Unpair',
            onPressed: () async {
              await ref.read(hubSessionProvider).unpair();
              ref.invalidate(isPairedProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _StatusBanner(status: _bleStatus),
          const SizedBox(height: 16),
          _TodayCard(db: db),
          const SizedBox(height: 16),
          const Text('Pending upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _PendingList(db: db),
          const SizedBox(height: 16),
          const Text('Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _ActivityLog(db: db),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final ok = status.contains('Advertising') || status.contains('ready');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok ? HubColors.green : HubColors.warning,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(ok ? Icons.bluetooth_connected : Icons.bluetooth_searching, color: HubColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(status,
                style: const TextStyle(color: HubColors.ink, fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.db});
  final HubDatabase db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReceivedPayload>>(
      stream: db.watchAll(),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const [];
        final uploaded = rows.where((r) => r.status == 'uploaded').length;
        final pending = rows.where((r) => r.status == 'received' || r.status == 'failed').length;
        return Row(
          children: <Widget>[
            _stat('Uploaded', '$uploaded', HubColors.indigo),
            const SizedBox(width: 12),
            _stat('Pending', '$pending', HubColors.cyan),
            const SizedBox(width: 12),
            _stat('Total', '${rows.length}', HubColors.violet),
          ],
        );
      },
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 13, color: HubColors.inkMuted)),
            ],
          ),
        ),
      );
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.db});
  final HubDatabase db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReceivedPayload>>(
      stream: db.watchAll(),
      builder: (context, snapshot) {
        final pending = (snapshot.data ?? const [])
            .where((r) => r.status != 'uploaded')
            .toList();
        if (pending.isEmpty) {
          return _muted('Nothing pending — all received contributions are uploaded.');
        }
        return Column(
          children: pending.take(20).map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: <Widget>[
                  Icon(_statusIcon(r.status), size: 20, color: _statusColor(r.status)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Contribution ${r.idempotencyKey.substring(0, 8)}',
                        style: const TextStyle(fontFamily: 'monospace')),
                  ),
                  Text(r.status, style: TextStyle(color: _statusColor(r.status), fontSize: 13)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _statusIcon(String s) => switch (s) {
        'uploading' => Icons.upload,
        'rejected' => Icons.block,
        'failed' => Icons.error_outline,
        _ => Icons.schedule,
      };

  Color _statusColor(String s) => switch (s) {
        'rejected' => HubColors.danger,
        'failed' => HubColors.warning,
        _ => HubColors.inkMuted,
      };
}

class _ActivityLog extends StatelessWidget {
  const _ActivityLog({required this.db});
  final HubDatabase db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UploadLogData>>(
      stream: db.watchLog(),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? const [];
        if (logs.isEmpty) return _muted('No activity yet.');
        return Column(
          children: logs.take(30).map((l) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${l.at.hour.toString().padLeft(2, '0')}:${l.at.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: HubColors.inkMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.message,
                        style: TextStyle(
                            fontSize: 13,
                            color: l.level == 'error'
                                ? HubColors.danger
                                : l.level == 'warn'
                                    ? HubColors.warning
                                    : HubColors.ink)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

Widget _muted(String text) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: HubColors.inkMuted)),
    );
