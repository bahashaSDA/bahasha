/**
 * Cross-stack crypto verification (Node side).
 *
 * Reads the artefact the Flutter test wrote and verifies the Dart-produced
 * signature with the BACKEND's own verifier path (SPKI DER import + Ed25519
 * verify). A pass proves the Flutter app and this backend agree on both the
 * canonical byte encoding and the signature format. Run:
 *
 *   node backend/scripts/verify-interop.mjs [artefactPath]
 */

import { readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createPublicKey, verify as nodeVerify } from 'node:crypto';

const artefactPath = process.argv[2] ?? join(tmpdir(), 'bahasha_interop.json');
const a = JSON.parse(readFileSync(artefactPath, 'utf8'));

const der = Buffer.from(a.publicKeySpkiBase64, 'base64');
const key = createPublicKey({ key: der, format: 'der', type: 'spki' });

if (key.asymmetricKeyType !== 'ed25519') {
  console.error(`FAIL: imported key is ${key.asymmetricKeyType}, expected ed25519`);
  process.exit(1);
}

const message = Buffer.from(a.messageBase64, 'base64');
const signature = Buffer.from(a.signatureBase64, 'base64');

// Rebuild the canonical bytes on this side too, to prove the encodings match
// and not merely that the signature verifies over whatever the app sent.
const expected = [
  'bahasha.v1',
  '99999999-0000-0000-0000-000000000001',
  'dddddddd-0000-0000-0000-000000000001',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'cccccccc-0000-0000-0000-000000000001',
  '+254712345678',
  '1700',
  '10',
  'nonce-interop-0001',
  '2026-07-18T09:00:00.000Z',
  '0',
].join('\n');

if (message.toString('utf8') !== expected) {
  console.error('FAIL: canonical bytes differ between Dart and Node');
  console.error('  dart:', JSON.stringify(message.toString('utf8')));
  console.error('  node:', JSON.stringify(expected));
  process.exit(1);
}

const ok = nodeVerify(null, message, key, signature);
if (!ok) {
  console.error('FAIL: signature did not verify on the Node side');
  process.exit(1);
}

console.log('PASS: Dart-signed payload verifies in the Node backend');
console.log('      canonical bytes identical, Ed25519 signature valid, SPKI import ok');
