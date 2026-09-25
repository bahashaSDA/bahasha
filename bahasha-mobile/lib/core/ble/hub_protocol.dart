import 'dart:convert';
import 'dart:typed_data';

/// The messages a Bahasha phone and a CVendor hub exchange over the Bahasha
/// GATT service (documentation/protocol/ble-protocol.md §5). Bahasha makes NO
/// internet calls: everything the backend or the prayer sheet needs travels
/// through the hub, which has the connection.
///
/// One session, all over BLE:
///   1. READ the challenge characteristic → `{"v":1,"nonce":…,"church":…}`.
///      The nonce is single-use for this connection; each signed offering
///      carries `<nonce>-<n>`, so a captured packet cannot be replayed.
///   2. WRITE messages (framed chunks) to the payload characteristic; after
///      each, the hub NOTIFIES one ack on the ack characteristic:
///        • `{"type":"register","body":{…}}` — the hub relays it to the
///          backend's POST /register; ack = 0x01 + the 16-byte server user id.
///        • a contribution envelope (the exact /ingest payload, no "type").
///        • `{"type":"prayer","requestId":…,"prayer":…}` — anonymous; the
///          hub forwards it to the prayer team's sheet.
///
/// MUST match cvendor-mobile/lib/core/hub_protocol.dart byte for byte.
class HubProtocol {
  HubProtocol._();

  static const int ackAccepted = 0x01;
  static const int ackDuplicate = 0x02;

  /// Registration could not be relayed: the hub has no internet right now.
  static const int ackHubOffline = 0x04;

  /// The backend refused the registration (e.g. that phone number already
  /// belongs to another giver).
  static const int ackRefused = 0x05;

  /// Malformed, or the nonce was not the one this hub issued.
  static const int ackRejected = 0xFF;

  static Uint8List register(Map<String, dynamic> body) =>
      _json({'type': 'register', 'body': body});

  static Uint8List prayer({required String requestId, required String prayer}) =>
      _json({'type': 'prayer', 'requestId': requestId, 'prayer': prayer});

  static Uint8List contribution(Map<String, dynamic> envelope) => _json(envelope);

  static Uint8List _json(Map<String, dynamic> m) => Uint8List.fromList(utf8.encode(jsonEncode(m)));
}

/// What the hub tells the phone when it connects.
class HubChallenge {
  const HubChallenge({required this.nonce, this.church});

  final String nonce;

  /// The collecting church's name, as the hub was paired (may be absent).
  final String? church;

  static HubChallenge? parse(List<int> bytes) {
    try {
      final m = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final nonce = m['nonce'] as String?;
      if (nonce == null || nonce.length < 8 || nonce.length > 100) return null;
      final church = (m['church'] as String?)?.trim();
      return HubChallenge(nonce: nonce, church: (church == null || church.isEmpty) ? null : church);
    } catch (_) {
      return null;
    }
  }
}

/// One ack notification: a status byte, then (for an accepted registration)
/// the 16 raw bytes of the backend's user id.
class HubAck {
  const HubAck(this.status, {this.userId});

  final int status;
  final String? userId;

  bool get accepted => status == HubProtocol.ackAccepted || status == HubProtocol.ackDuplicate;

  static HubAck parse(List<int> bytes) {
    if (bytes.isEmpty) return const HubAck(HubProtocol.ackRejected);
    String? userId;
    if (bytes.length >= 17) userId = uuidFromBytes(bytes.sublist(1, 17));
    return HubAck(bytes.first, userId: userId);
  }

  static String uuidFromBytes(List<int> b) {
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  static Uint8List uuidToBytes(String uuid) {
    final h = uuid.replaceAll('-', '');
    return Uint8List.fromList([for (var i = 0; i < 32; i += 2) int.parse(h.substring(i, i + 2), radix: 16)]);
  }
}
