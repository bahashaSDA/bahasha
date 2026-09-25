import 'dart:convert';
import 'dart:typed_data';
import 'package:bahasha/core/ble/ble_transport.dart';
import 'package:bahasha/core/ble/hub_protocol.dart';

/// A stand-in CVendor hub for tests: answers the same messages, with the same
/// acks, as cvendor-mobile's BleReceiver.
class FakeHub implements HubConnector {
  FakeHub({this.inRange = true, this.online = true, this.refuseRegistration = false, this.dropAfter});

  bool inRange;

  /// Whether the hub itself has internet (needed to relay a registration).
  bool online;
  bool refuseRegistration;

  /// Simulate walking out of range after this many messages.
  int? dropAfter;

  static const serverUserId = '0f8fad5b-d9cb-469f-a165-70867728950e';
  final received = <Map<String, dynamic>>[];
  int connections = 0;

  List<Map<String, dynamic>> get registrations => received.where((m) => m['type'] == 'register').toList();
  List<Map<String, dynamic>> get offerings => received.where((m) => m['type'] == null).toList();
  List<Map<String, dynamic>> get prayers => received.where((m) => m['type'] == 'prayer').toList();

  @override
  Future<HubLink?> connect({Duration timeout = const Duration(seconds: 15)}) async {
    if (!inRange) return null;
    connections++;
    return _FakeLink(this, 'hubnonce$connections');
  }
}

class _FakeLink implements HubLink {
  _FakeLink(this.hub, String nonce) : challenge = HubChallenge(nonce: nonce, church: 'TUK SDA Church');
  final FakeHub hub;
  @override
  final HubChallenge challenge;
  int _sent = 0;

  @override
  Future<HubAck> send(Uint8List message, {Duration timeout = const Duration(seconds: 25)}) async {
    if (hub.dropAfter != null && _sent >= hub.dropAfter!) throw StateError('out of range');
    _sent++;
    final m = jsonDecode(utf8.decode(message)) as Map<String, dynamic>;
    hub.received.add(m);
    switch (m['type']) {
      case 'register':
        if (!hub.online) return const HubAck(HubProtocol.ackHubOffline);
        if (hub.refuseRegistration) return const HubAck(HubProtocol.ackRefused);
        return HubAck.parse([HubProtocol.ackAccepted, ...HubAck.uuidToBytes(FakeHub.serverUserId)]);
      case 'prayer':
        return const HubAck(HubProtocol.ackAccepted);
      default:
        final nonce = m['nonce'] as String;
        return HubAck(nonce.startsWith(challenge.nonce) ? HubProtocol.ackAccepted : HubProtocol.ackRejected);
    }
  }

  @override
  Future<void> close() async {}
}
