// The receiver holds a private db field via a named constructor param.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'hub_database.dart';

/// The hub's BLE peripheral: it advertises the Bahasha GATT service and accepts
/// contribution payloads written by nearby Bahasha (giver) devices, reassembles
/// the chunked frames, and enqueues each complete payload for upload.
///
/// Protocol (mirrors documentation/protocol/ble-protocol.md and the Bahasha
/// send side). The UUIDs MUST match the giver app exactly.
///
/// HARDWARE NOTE: BLE peripheral mode requires a real Android device — it cannot
/// be exercised on an emulator or in unit tests. The reassembly logic is a pure
/// function ([reassemble]) so that part is tested without a radio.
class BleReceiver {
  BleReceiver({required HubDatabase db}) : _db = db;

  final HubDatabase _db;
  final PeripheralManager _manager = PeripheralManager();

  // Must equal BleProtocol in the Bahasha app.
  static final UUID _service = UUID.fromString('b1a5a000-0000-4000-8000-00000000ba5a');
  static final UUID _challenge = UUID.fromString('b1a5a001-0000-4000-8000-00000000ba5a');
  static final UUID _payload = UUID.fromString('b1a5a002-0000-4000-8000-00000000ba5a');
  static final UUID _ack = UUID.fromString('b1a5a003-0000-4000-8000-00000000ba5a');

  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>? _writeSub;
  GATTCharacteristic? _ackCharacteristic;

  /// Per-connection chunk reassembly buffers, keyed by central id.
  final Map<String, _Assembly> _assemblies = {};

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get status => _statusController.stream;

  /// Bring up the peripheral: register the service and start advertising.
  Future<void> start() async {
    if (_manager.state != BluetoothLowEnergyState.poweredOn) {
      _statusController.add('Bluetooth is off');
      return;
    }

    final ack = GATTCharacteristic.mutable(
      uuid: _ack,
      properties: [GATTCharacteristicProperty.notify],
      permissions: [],
      descriptors: [],
    );
    _ackCharacteristic = ack;

    final service = GATTService(
      uuid: _service,
      isPrimary: true,
      includedServices: [],
      characteristics: [
        GATTCharacteristic.mutable(
          uuid: _challenge,
          properties: [GATTCharacteristicProperty.read],
          permissions: [GATTCharacteristicPermission.read],
          descriptors: [],
        ),
        GATTCharacteristic.mutable(
          uuid: _payload,
          properties: [GATTCharacteristicProperty.write],
          permissions: [GATTCharacteristicPermission.write],
          descriptors: [],
        ),
        ack,
      ],
    );

    await _manager.addService(service);

    _writeSub = _manager.characteristicWriteRequested.listen(_onWrite);

    await _manager.startAdvertising(
      Advertisement(name: 'Bahasha Hub', serviceUUIDs: [_service]),
    );
    _statusController.add('Advertising — ready to receive');
  }

  Future<void> stop() async {
    await _writeSub?.cancel();
    await _manager.stopAdvertising();
    await _manager.removeAllServices();
    _statusController.add('Stopped');
  }

  Future<void> _onWrite(GATTCharacteristicWriteRequestedEventArgs args) async {
    // Always acknowledge the write request first; a write-with-response that is
    // never answered blocks the giver's next chunk.
    await _manager.respondWriteRequest(args.request);

    if (args.characteristic.uuid != _payload) return;
    final centralId = args.central.uuid.toString();
    final assembly = _assemblies.putIfAbsent(centralId, () => _Assembly());

    final complete = assembly.addChunk(args.request.value);
    if (complete == null) return; // more chunks to come

    _assemblies.remove(centralId);
    await _handleComplete(complete, args.central);
  }

  Future<void> _handleComplete(Uint8List bytes, Central central) async {
    try {
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final key = map['idempotencyKey'] as String?;
      if (key == null) {
        await _notifyAck(central, 0xFF);
        return;
      }
      await _db.enqueue(key, utf8.decode(bytes), map['deviceUuid'] as String?);
      await _db.log('Received contribution ${key.substring(0, 8)}');
      _statusController.add('Received a contribution');
      await _notifyAck(central, 0x01); // accepted-for-relay
    } catch (_) {
      await _notifyAck(central, 0xFF); // malformed
    }
  }

  Future<void> _notifyAck(Central central, int statusByte) async {
    final ack = _ackCharacteristic;
    if (ack == null) return;
    try {
      await _manager.notifyCharacteristic(
        central,
        ack,
        value: Uint8List.fromList([statusByte]),
      );
    } catch (_) {
      // Central may have disconnected; the giver's outbox will retry.
    }
  }

  /// Reassemble framed chunks [seq:2][total:2][...data] into the full payload.
  /// Pure and unit-testable. Returns null until all `total` chunks have arrived.
  static Uint8List? reassembleChunks(Iterable<List<int>> chunks) {
    final assembly = _Assembly();
    Uint8List? done;
    for (final c in chunks) {
      done = assembly.addChunk(c);
    }
    return done;
  }

  void dispose() {
    _writeSub?.cancel();
    _statusController.close();
  }
}

/// Accumulates chunks for one in-flight payload.
class _Assembly {
  final Map<int, List<int>> _bySeq = {};
  int? _total;

  /// Returns the full payload once complete, else null.
  Uint8List? addChunk(List<int> chunk) {
    if (chunk.length < 4) return null;
    final seq = (chunk[0] << 8) | chunk[1];
    _total = (chunk[2] << 8) | chunk[3];
    _bySeq[seq] = chunk.sublist(4);
    if (_bySeq.length != _total) return null;

    final out = <int>[];
    for (var i = 0; i < _total!; i++) {
      final part = _bySeq[i];
      if (part == null) return null; // gap: not actually complete
      out.addAll(part);
    }
    return Uint8List.fromList(out);
  }
}
