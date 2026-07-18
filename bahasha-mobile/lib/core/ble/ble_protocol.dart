import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Shared BLE GATT contract between Bahasha (giver) and CVendor (hub).
///
/// These UUIDs and framing rules are the transport half of the protocol
/// documented in documentation/protocol/ble-protocol.md. Both apps MUST use the
/// identical values or they will not find or talk to each other.
class BleProtocol {
  BleProtocol._();

  /// The service a CVendor hub advertises and a Bahasha device scans for.
  static final Uuid serviceUuid = Uuid.parse('b1a5a000-0000-4000-8000-00000000ba5a');

  /// The hub writes a fresh single-use transport nonce here for the giver to
  /// read at the start of a session (challenge-response liveness).
  static final Uuid challengeCharacteristic =
      Uuid.parse('b1a5a001-0000-4000-8000-00000000ba5a');

  /// The giver writes the (encrypted, signed) contribution payload here, in
  /// ordered chunks framed per [chunkHeaderLength].
  static final Uuid payloadCharacteristic =
      Uuid.parse('b1a5a002-0000-4000-8000-00000000ba5a');

  /// The hub notifies the delivery result here: one status byte + the
  /// idempotency key, so the giver can mark the outbox item sent or retry.
  static final Uuid ackCharacteristic = Uuid.parse('b1a5a003-0000-4000-8000-00000000ba5a');

  /// BLE payloads are chunked because the MTU is small (~180–512 bytes). Each
  /// chunk is framed: [seq:2][total:2][...data]. The receiver reassembles by
  /// seq and knows it is complete when it has `total` chunks.
  static const int chunkHeaderLength = 4;

  /// Conservative default write size; negotiated MTU may allow more.
  static const int defaultChunkSize = 180;

  /// Ack status byte values written to [ackCharacteristic].
  static const int ackAccepted = 0x01;
  static const int ackDuplicate = 0x02;
  static const int ackRejected = 0xFF;
}
