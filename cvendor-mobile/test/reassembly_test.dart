import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:cvendor/core/ble_receiver.dart';

/// The hub must reassemble the exact bytes the giver framed, in any order they
/// arrive, and only report completion once every chunk is present. A bug here
/// would corrupt a contribution payload before it reaches the backend, so the
/// pure reassembly logic is tested directly (BLE radio itself needs hardware).
void main() {
  /// Frame like the giver's BleTransport: [seq:2][total:2][...data].
  List<List<int>> frame(List<int> data, int chunkSize) {
    final body = chunkSize - 4;
    final total = (data.length / body).ceil().clamp(1, 0xFFFF);
    final out = <List<int>>[];
    for (var i = 0; i < total; i++) {
      final start = i * body;
      final end = (start + body).clamp(0, data.length);
      final header = Uint8List(4);
      header.buffer.asByteData()
        ..setUint16(0, i, Endian.big)
        ..setUint16(2, total, Endian.big);
      out.add(<int>[...header, ...data.sublist(start, end)]);
    }
    return out;
  }

  test('reassembles a multi-chunk payload back to the original bytes', () {
    final payload = jsonEncode({
      'idempotencyKey': '99999999-0000-0000-0000-000000000001',
      'totalAmount': 1700,
      'signature': 'x' * 88,
    });
    final bytes = utf8.encode(payload);
    final chunks = frame(bytes, 180);
    expect(chunks.length, greaterThan(1));

    final restored = BleReceiver.reassembleChunks(chunks);
    expect(restored, isNotNull);
    expect(utf8.decode(restored!), equals(payload));
  });

  test('reassembles correctly even if chunks arrive out of order', () {
    final bytes = List<int>.generate(600, (i) => i % 256);
    final chunks = frame(bytes, 100)..shuffle();
    final restored = BleReceiver.reassembleChunks(chunks);
    expect(restored, equals(bytes));
  });

  test('reports incomplete until the final chunk arrives', () {
    final bytes = List<int>.filled(400, 9);
    final chunks = frame(bytes, 100); // 4 chunks
    // Feed all but the last: must still be null.
    expect(BleReceiver.reassembleChunks(chunks.take(chunks.length - 1)), isNull);
    // All chunks: complete.
    expect(BleReceiver.reassembleChunks(chunks), equals(bytes));
  });
}
