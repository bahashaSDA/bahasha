import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_protocol.dart';

/// Outcome of a transmission attempt.
enum BleSendOutcome { accepted, duplicate, rejected, noHubFound, transportError }

/// The giver-side BLE transport: find a church hub, hand it a signed
/// contribution payload, and read back the delivery result.
///
/// This is a transport only. It carries an already-signed (and, in production,
/// encrypted-to-church-key) payload; it makes no security decisions. The
/// authenticity of what it delivers is guaranteed by the device signature the
/// backend verifies, not by anything that happens here — so a hostile hub can
/// drop or delay a packet but cannot forge or alter one.
///
/// Hardware note: BLE cannot be exercised in a unit test or emulator; this is
/// validated on physical devices. The framing and reassembly logic below is
/// factored into pure functions ([frameChunks]/[parseAck]) so that part is
/// tested without radios.
class BleTransport {
  BleTransport({FlutterReactiveBle? ble}) : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;

  /// Scan for a hub, connect, hand over [payloadJson], and await the ack.
  /// [timeout] bounds the whole exchange so a stalled radio doesn't hang the UI.
  Future<BleSendOutcome> send({
    required String payloadJson,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    StreamSubscription<ConnectionStateUpdate>? connSub;
    final completer = Completer<BleSendOutcome>();

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(BleSendOutcome.transportError);
    });

    try {
      // 1. Scan for the first hub advertising our service.
      final device = await _firstHub(timeout: timeout);
      if (device == null) return BleSendOutcome.noHubFound;

      // 2. Connect.
      connSub = _ble.connectToDevice(id: device.id, connectionTimeout: timeout).listen((update) async {
        if (update.connectionState != DeviceConnectionState.connected) return;
        try {
          final outcome = await _exchange(device.id, payloadJson);
          if (!completer.isCompleted) completer.complete(outcome);
        } catch (_) {
          if (!completer.isCompleted) completer.complete(BleSendOutcome.transportError);
        }
      }, onError: (_) {
        if (!completer.isCompleted) completer.complete(BleSendOutcome.transportError);
      });

      return await completer.future;
    } catch (_) {
      return BleSendOutcome.transportError;
    } finally {
      timer.cancel();
      await connSub?.cancel();
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

  Future<BleSendOutcome> _exchange(String deviceId, String payloadJson) async {
    QualifiedCharacteristic ch(Uuid c) => QualifiedCharacteristic(
          serviceId: BleProtocol.serviceUuid,
          characteristicId: c,
          deviceId: deviceId,
        );

    // Read the hub's transport challenge (liveness; the security nonce is
    // already inside the signed payload).
    await _ble.readCharacteristic(ch(BleProtocol.challengeCharacteristic));

    // Write the payload in framed chunks.
    final chunks = frameChunks(utf8.encode(payloadJson), BleProtocol.defaultChunkSize);
    for (final chunk in chunks) {
      await _ble.writeCharacteristicWithResponse(
        ch(BleProtocol.payloadCharacteristic),
        value: chunk,
      );
    }

    // Await the ack notification.
    final ackBytes = await _ble
        .subscribeToCharacteristic(ch(BleProtocol.ackCharacteristic))
        .firstWhere((v) => v.isNotEmpty);
    return parseAck(ackBytes);
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
