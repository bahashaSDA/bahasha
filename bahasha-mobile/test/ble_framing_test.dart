import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahasha/core/ble/ble_transport.dart';
import 'package:bahasha/core/ble/ble_protocol.dart';

/// The BLE radio can't be exercised without hardware, but the framing and ack
/// logic is pure and must be exactly right — a reassembly bug would corrupt a
/// contribution payload in transit. These test that part directly.
void main() {
  List<int> reassemble(List<List<int>> chunks) {
    // Mirror the hub's reassembly: order by seq, strip headers, concat.
    final bySeq = <int, List<int>>{};
    int? total;
    for (final chunk in chunks) {
      final seq = (chunk[0] << 8) | chunk[1];
      total = (chunk[2] << 8) | chunk[3];
      bySeq[seq] = chunk.sublist(BleProtocol.chunkHeaderLength);
    }
    final out = <int>[];
    for (var i = 0; i < (total ?? 0); i++) {
      out.addAll(bySeq[i]!);
    }
    return out;
  }

  test('a payload survives a frame → reassemble round trip', () {
    final payload = jsonEncode({
      'idempotencyKey': '99999999-0000-0000-0000-000000000001',
      'totalAmount': 1700,
      'allocations': [
        {'categoryCode': 'tithe', 'amount': 1000},
        {'categoryCode': 'mission', 'amount': 700},
      ],
      'signature': 'a' * 88,
    });
    final bytes = utf8.encode(payload);

    final chunks = BleTransport.frameChunks(bytes, BleProtocol.defaultChunkSize);
    expect(chunks.length, greaterThan(1)); // this payload spans multiple chunks

    final restored = reassemble(chunks);
    expect(restored, equals(bytes));
    expect(utf8.decode(restored), equals(payload));
  });

  test('a single small payload frames into exactly one chunk', () {
    final bytes = utf8.encode('{"ok":1}');
    final chunks = BleTransport.frameChunks(bytes, BleProtocol.defaultChunkSize);
    expect(chunks.length, 1);
    expect(chunks.first[2] << 8 | chunks.first[3], 1); // total == 1
    expect(reassemble(chunks), equals(bytes));
  });

  test('chunk headers carry correct seq and total', () {
    final bytes = List<int>.filled(500, 7);
    final chunks = BleTransport.frameChunks(bytes, 100); // body 96 => 6 chunks
    expect(chunks.length, 6);
    for (var i = 0; i < chunks.length; i++) {
      expect(chunks[i][0] << 8 | chunks[i][1], i); // seq
      expect(chunks[i][2] << 8 | chunks[i][3], 6); // total
    }
  });

  test('ack bytes map to the right outcome', () {
    expect(BleTransport.parseAck([BleProtocol.ackAccepted]), BleSendOutcome.accepted);
    expect(BleTransport.parseAck([BleProtocol.ackDuplicate]), BleSendOutcome.duplicate);
    expect(BleTransport.parseAck([BleProtocol.ackRejected]), BleSendOutcome.rejected);
    expect(BleTransport.parseAck([]), BleSendOutcome.transportError);
  });
}
