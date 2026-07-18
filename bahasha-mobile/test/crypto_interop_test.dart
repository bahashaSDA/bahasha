import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahasha/core/crypto/payload_signer.dart';

/// Cross-stack crypto contract test.
///
/// This produces a signature and public key with the SAME primitives the app
/// uses, over the SAME canonical bytes the backend expects, from a FIXED seed
/// so the output is deterministic. It writes the artefacts to a temp file that
/// a Node script (`backend/scripts/verify-interop.mjs`) then verifies with the
/// backend's own verifier. If both sides agree, the Flutter↔Node signature
/// contract holds; if they ever drift, this is where it surfaces.
void main() {
  test('Dart-signed payload matches the backend canonical bytes and verifies', () async {
    // Deterministic 32-byte seed so the run is reproducible.
    final seed = List<int>.generate(32, (i) => i + 1);
    final algo = Ed25519();
    final pair = await algo.newKeyPairFromSeed(seed);
    final pub = await pair.extractPublicKey();

    final message = PayloadSigner.canonicalBytes(
      idempotencyKey: '99999999-0000-0000-0000-000000000001',
      deviceUuid: 'dddddddd-0000-0000-0000-000000000001',
      userId: 'aaaaaaaa-0000-0000-0000-000000000001',
      churchId: 'cccccccc-0000-0000-0000-000000000001',
      msisdn: '+254712345678',
      totalAmount: 1700,
      counter: 10,
      nonce: 'nonce-interop-0001',
      deviceTimestamp: '2026-07-18T09:00:00.000Z',
      anonymous: false,
    );

    final signature = await algo.sign(message, keyPair: pair);

    // Wrap the raw public key in SPKI DER exactly as the app registers it.
    final spki = _wrapSpki(pub.bytes);

    final artefact = <String, dynamic>{
      'publicKeySpkiBase64': base64Encode(spki),
      'messageBase64': base64Encode(message),
      'signatureBase64': base64Encode(signature.bytes),
      'canonicalText': utf8.decode(message),
    };

    final out = File('${Directory.systemTemp.path}/bahasha_interop.json');
    out.writeAsStringSync(jsonEncode(artefact));

    // Sanity within Dart: it verifies against itself.
    final ok = await algo.verify(
      message,
      signature: Signature(signature.bytes, publicKey: pub),
    );
    expect(ok, isTrue);
    expect(signature.bytes.length, 64);
    // Leave a breadcrumb for the Node step.
    // ignore: avoid_print
    print('INTEROP_ARTEFACT=${out.path}');
  });
}

List<int> _wrapSpki(List<int> raw) => <int>[
      0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00,
      ...raw,
    ];
