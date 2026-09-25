import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// The hub side of the Bahasha ↔ CVendor BLE exchange
/// (documentation/protocol/ble-protocol.md §5). Bahasha phones make NO
/// internet calls; this hub relays everything they need:
///
///   READ  challenge → `{"v":1,"nonce":…,"church":…}` (fresh per connection)
///   WRITE register  → relayed to POST /register; ack 0x01 + 16-byte user id
///   WRITE offering  → queued for POST /ingest (its nonce must start with the
///                     challenge this hub issued on this connection)
///   WRITE prayer    → anonymous; queued for the prayer team's sheet
///
/// MUST match bahasha-mobile/lib/core/ble/hub_protocol.dart byte for byte.
class HubProtocol {
  HubProtocol._();
  static const int ackAccepted = 0x01;
  static const int ackDuplicate = 0x02;
  static const int ackHubOffline = 0x04;
  static const int ackRefused = 0x05;
  static const int ackRejected = 0xFF;

  /// A fresh, unguessable challenge nonce (32 hex chars).
  static String newNonce([Random? random]) {
    final r = random ?? Random.secure();
    return List<int>.generate(16, (_) => r.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List challenge(String nonce, String? church) =>
      Uint8List.fromList(utf8.encode(jsonEncode({'v': 1, 'nonce': nonce, 'church': ?church})));

  static Uint8List uuidToBytes(String uuid) {
    final h = uuid.replaceAll('-', '');
    return Uint8List.fromList([for (var i = 0; i < 32; i += 2) int.parse(h.substring(i, i + 2), radix: 16)]);
  }
}

/// Outcome of relaying a registration to the backend.
enum RegisterOutcome { registered, offline, refused }

/// Decides the ack for each complete message a phone writes. Pure apart from
/// the injected side effects, so the whole dispatch is unit-tested without a
/// radio.
class HubMessageHandler {
  HubMessageHandler({
    required this.enqueueOffering,
    required this.register,
    required this.enqueuePrayer,
    this.log,
  });

  /// Queue an offering for upload (key, full JSON, device uuid).
  final Future<void> Function(String idempotencyKey, String json, String? deviceUuid) enqueueOffering;

  /// Relay a registration; returns the backend's user id when accepted.
  final Future<(RegisterOutcome, String?)> Function(Map<String, dynamic> body) register;

  /// Queue an anonymous prayer (random request id + text only).
  final Future<void> Function(String requestId, String prayer) enqueuePrayer;
  final Future<void> Function(String message)? log;

  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

  /// [issuedNonce] is the challenge this hub gave the writing phone on this
  /// connection (null if it never read one).
  Future<Uint8List> handle(Uint8List bytes, {required String? issuedNonce}) async {
    try {
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      switch (map['type']) {
        case 'register':
          final body = map['body'];
          if (body is! Map<String, dynamic>) return _ack(HubProtocol.ackRejected);
          final (outcome, userId) = await register(body);
          if (outcome == RegisterOutcome.registered && userId != null && _uuid.hasMatch(userId)) {
            await log?.call('Registered a giver’s phone');
            return Uint8List.fromList([HubProtocol.ackAccepted, ...HubProtocol.uuidToBytes(userId)]);
          }
          return _ack(outcome == RegisterOutcome.refused ? HubProtocol.ackRefused : HubProtocol.ackHubOffline);

        case 'prayer':
          final id = map['requestId'];
          final text = (map['prayer'] as String?)?.trim() ?? '';
          if (id is! String || !_uuid.hasMatch(id) || text.isEmpty) return _ack(HubProtocol.ackRejected);
          // Only the random id and the text are kept — nothing about the giver.
          await enqueuePrayer(id, text.length > 1000 ? text.substring(0, 1000) : text);
          await log?.call('Received a prayer request');
          return _ack(HubProtocol.ackAccepted);

        case null:
          final key = map['idempotencyKey'];
          final nonce = map['nonce'];
          if (key is! String || !_uuid.hasMatch(key)) return _ack(HubProtocol.ackRejected);
          // Liveness: the offering must be signed with THIS connection's
          // challenge, so a recorded packet cannot be played to a hub later.
          if (issuedNonce == null || nonce is! String || !nonce.startsWith(issuedNonce)) {
            await log?.call('Refused an offering signed for another session');
            return _ack(HubProtocol.ackRejected);
          }
          await enqueueOffering(key, utf8.decode(bytes), map['deviceUuid'] as String?);
          await log?.call('Received contribution ${key.substring(0, 8)}');
          return _ack(HubProtocol.ackAccepted);

        default:
          return _ack(HubProtocol.ackRejected);
      }
    } catch (_) {
      return _ack(HubProtocol.ackRejected);
    }
  }

  static Uint8List _ack(int status) => Uint8List.fromList([status]);
}
