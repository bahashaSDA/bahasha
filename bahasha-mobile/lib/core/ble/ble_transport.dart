import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_protocol.dart';
import 'hub_protocol.dart';

/// Outcome of a transmission attempt (legacy single-status view of an ack).
enum BleSendOutcome { accepted, duplicate, rejected, noHubFound, transportError }

/// An open BLE session with one CVendor hub: read its challenge, then send
/// messages one at a time, each answered by an ack notification. Abstract so
/// the giving relay is unit-tested without radios.
abstract class HubLink {
  /// The hub's single-use challenge for this connection.
  HubChallenge get challenge;

  /// Write [message] (framed into chunks) and wait for the hub's ack.
  Future<HubAck> send(Uint8List message, {Duration timeout});

  Future<void> close();
}

/// Finds a hub and opens a [HubLink] to it.
abstract class HubConnector {
  /// Null when no hub is in range (or Bluetooth is off / not permitted).
  Future<HubLink?> connect({Duration timeout});
}

/// The giver-side BLE transport (central role, flutter_reactive_ble).
///
/// This is a transport only. It carries already-signed payloads; it makes no
/// security decisions. Authenticity is guaranteed by the device signature the
/// backend verifies, so a hostile hub can drop or delay a packet but cannot
/// forge or alter one.
///
/// Hardware note: BLE cannot be exercised in a unit test or emulator; this is
/// validated on physical devices. The framing logic ([frameChunks]/[parseAck])
/// is pure and unit-tested.
class BleTransport implements HubConnector {
  BleTransport({FlutterReactiveBle? ble}) : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;

  @override
  Future<HubLink?> connect({Duration timeout = const Duration(seconds: 15)}) async {
    if (!await _permissions()) return null;
    final device = await _firstHub(timeout: timeout);
    if (device == null) return null;

    final connected = Completer<bool>();
    late final StreamSubscription<ConnectionStateUpdate> connSub;
    connSub = _ble.connectToDevice(id: device.id, connectionTimeout: timeout).listen((u) {
      if (u.connectionState == DeviceConnectionState.connected && !connected.isCompleted) connected.complete(true);
      if (u.connectionState == DeviceConnectionState.disconnected && !connected.isCompleted) connected.complete(false);
    }, onError: (_) {
      if (!connected.isCompleted) connected.complete(false);
    });

    final ok = await connected.future.timeout(timeout, onTimeout: () => false);
    if (!ok) {
      await connSub.cancel();
      return null;
    }
    try {
      // A bigger MTU means fewer, faster chunks; fall back to the BLE minimum.
      var mtu = 23;
      try {
        mtu = await _ble.requestMtu(deviceId: device.id, mtu: 247);
      } catch (_) {}
      await _ble.discoverAllServices(device.id);
      QualifiedCharacteristic ch(Uuid c) =>
          QualifiedCharacteristic(serviceId: BleProtocol.serviceUuid, characteristicId: c, deviceId: device.id);

      // Subscribe to acks BEFORE writing anything, or a fast ack is missed.
      final acks = StreamController<List<int>>.broadcast();
      final ackSub = _ble.subscribeToCharacteristic(ch(BleProtocol.ackCharacteristic)).listen(acks.add, onError: acks.addError);
      final challengeBytes = await _ble.readCharacteristic(ch(BleProtocol.challengeCharacteristic)).timeout(timeout);
      final challenge = HubChallenge.parse(challengeBytes);
      if (challenge == null) {
        await ackSub.cancel();
        await connSub.cancel();
        return null;
      }
      return _BleHubLink(_ble, ch(BleProtocol.payloadCharacteristic), challenge, acks, ackSub, connSub, mtu);
    } catch (_) {
      await connSub.cancel();
      return null;
    }
  }

  Future<bool> _permissions() async {
    try {
      final r = await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse].request();
      return (r[Permission.bluetoothScan]?.isGranted ?? false) || (r[Permission.locationWhenInUse]?.isGranted ?? false);
    } catch (_) {
      return false;
    }
  }

  Future<DiscoveredDevice?> _firstHub({required Duration timeout}) {
    final completer = Completer<DiscoveredDevice?>();
    late final StreamSubscription<DiscoveredDevice> sub;
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    sub = _ble.scanForDevices(withServices: [BleProtocol.serviceUuid]).listen(
      (d) {
        if (!completer.isCompleted) completer.complete(d);
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    return completer.future.whenComplete(() {
      timer.cancel();
      sub.cancel();
    });
  }

  // --- Pure, unit-testable framing ------------------------------------------

  /// Split [data] into framed chunks: [seq:2][total:2][...payload]. Big-endian
  /// counters. The receiver reassembles by seq and is complete at `total`.
  static List<List<int>> frameChunks(List<int> data, int chunkSize) {
    final body = chunkSize - BleProtocol.chunkHeaderLength;
    if (body <= 0) throw ArgumentError('chunkSize too small for header');
    final total = (data.length / body).ceil().clamp(1, 0xFFFF);
    final out = <List<int>>[];
    for (var i = 0; i < total; i++) {
      final start = i * body;
      final end = (start + body).clamp(0, data.length);
      final header = Uint8List(BleProtocol.chunkHeaderLength);
      header.buffer.asByteData()
        ..setUint16(0, i, Endian.big)
        ..setUint16(2, total, Endian.big);
      out.add(<int>[...header, ...data.sublist(start, end)]);
    }
    return out;
  }

  /// Interpret the hub's ack byte.
  static BleSendOutcome parseAck(List<int> ack) {
    if (ack.isEmpty) return BleSendOutcome.transportError;
    switch (ack.first) {
      case BleProtocol.ackAccepted:
        return BleSendOutcome.accepted;
      case BleProtocol.ackDuplicate:
        return BleSendOutcome.duplicate;
      case BleProtocol.ackRejected:
        return BleSendOutcome.rejected;
      default:
        return BleSendOutcome.transportError;
    }
  }
}

class _BleHubLink implements HubLink {
  _BleHubLink(this._ble, this._payload, this.challenge, this._acks, this._ackSub, this._connSub, int mtu)
      // ATT write payload is MTU − 3; each chunk must fit one write.
      : _chunkSize = (mtu - 3).clamp(20, 512);

  final FlutterReactiveBle _ble;
  final QualifiedCharacteristic _payload;
  @override
  final HubChallenge challenge;
  final StreamController<List<int>> _acks;
  final StreamSubscription<List<int>> _ackSub;
  final StreamSubscription<ConnectionStateUpdate> _connSub;
  final int _chunkSize;

  @override
  Future<HubAck> send(Uint8List message, {Duration timeout = const Duration(seconds: 25)}) async {
    final next = _acks.stream.firstWhere((v) => v.isNotEmpty).timeout(timeout);
    for (final chunk in BleTransport.frameChunks(message, _chunkSize)) {
      await _ble.writeCharacteristicWithResponse(_payload, value: chunk);
    }
    return HubAck.parse(await next);
  }

  @override
  Future<void> close() async {
    await _ackSub.cancel();
    await _acks.close();
    await _connSub.cancel(); // cancelling the connection stream disconnects
  }
}
