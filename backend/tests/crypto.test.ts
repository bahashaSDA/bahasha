/**
 * Crypto tests -- the trust anchor of the BLE protocol.
 *
 * These generate REAL keypairs, sign the canonical payload bytes exactly as a
 * device would, and verify with the backend's verifier. If any of these fail,
 * every contribution in production would either be silently forgeable or
 * silently unverifiable -- so they run keypair generation, not fixtures.
 */

import { describe, expect, it } from 'vitest';
import { generateKeyPairSync, sign as nodeSign } from 'node:crypto';
import {
  canonicalPayloadBytes,
  hashHubKey,
  hubKeyHashEquals,
  importPublicKey,
  isWellFormedHubKey,
  verifySignature,
} from '../src/lib/crypto.js';

const samplePayload = {
  idempotencyKey: '99999999-0000-0000-0000-000000000001',
  deviceUuid: 'dddddddd-0000-0000-0000-000000000001',
  userId: 'aaaaaaaa-0000-0000-0000-000000000001',
  churchId: 'cccccccc-0000-0000-0000-000000000001',
  msisdn: '+254712345678',
  totalAmount: 1700,
  counter: 10,
  nonce: 'nonce-crypto-0001',
  deviceTimestamp: '2026-07-18T09:00:00.000Z',
  anonymous: false,
};

describe('Ed25519 payload signing', () => {
  it('verifies a genuine signature', () => {
    const { publicKey, privateKey } = generateKeyPairSync('ed25519');
    const spkiB64 = publicKey.export({ format: 'der', type: 'spki' }).toString('base64');
    const message = canonicalPayloadBytes(samplePayload);

    // Ed25519 signs with a null digest algorithm.
    const signature = nodeSign(null, message, privateKey).toString('base64');

    const imported = importPublicKey(spkiB64, 'ed25519');
    expect(verifySignature(imported, message, signature, 'ed25519')).toBe(true);
  });

  it('rejects a signature over tampered data (amount changed)', () => {
    const { publicKey, privateKey } = generateKeyPairSync('ed25519');
    const spkiB64 = publicKey.export({ format: 'der', type: 'spki' }).toString('base64');

    // Sign the honest 1700 payload...
    const signed = canonicalPayloadBytes(samplePayload);
    const signature = nodeSign(null, signed, privateKey).toString('base64');

    // ...but present a payload claiming 17000. The signature must not verify.
    const tampered = canonicalPayloadBytes({ ...samplePayload, totalAmount: 17000 });
    const imported = importPublicKey(spkiB64, 'ed25519');
    expect(verifySignature(imported, tampered, signature, 'ed25519')).toBe(false);
  });

  it("rejects a signature from a different device's key", () => {
    const attacker = generateKeyPairSync('ed25519');
    const victim = generateKeyPairSync('ed25519');
    const message = canonicalPayloadBytes(samplePayload);

    // Attacker signs; we verify against the victim's registered public key.
    const forged = nodeSign(null, message, attacker.privateKey).toString('base64');
    const victimKey = importPublicKey(
      victim.publicKey.export({ format: 'der', type: 'spki' }).toString('base64'),
      'ed25519',
    );
    expect(verifySignature(victimKey, message, forged, 'ed25519')).toBe(false);
  });

  it('rejects a malformed (wrong-length) signature without throwing', () => {
    const { publicKey } = generateKeyPairSync('ed25519');
    const imported = importPublicKey(
      publicKey.export({ format: 'der', type: 'spki' }).toString('base64'),
      'ed25519',
    );
    const message = canonicalPayloadBytes(samplePayload);
    expect(verifySignature(imported, message, Buffer.from('short').toString('base64'), 'ed25519')).toBe(
      false,
    );
  });

  it('refuses to import an EC key as ed25519', () => {
    const { publicKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const spkiB64 = publicKey.export({ format: 'der', type: 'spki' }).toString('base64');
    expect(() => importPublicKey(spkiB64, 'ed25519')).toThrow();
  });
});

describe('ECDSA P-256 payload signing', () => {
  it('verifies a genuine signature', () => {
    const { publicKey, privateKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const spkiB64 = publicKey.export({ format: 'der', type: 'spki' }).toString('base64');
    const message = canonicalPayloadBytes(samplePayload);
    const signature = nodeSign('sha256', message, privateKey).toString('base64');

    const imported = importPublicKey(spkiB64, 'ecdsa-p256');
    expect(verifySignature(imported, message, signature, 'ecdsa-p256')).toBe(true);
  });

  it('rejects a P-384 key presented as P-256', () => {
    const { publicKey } = generateKeyPairSync('ec', { namedCurve: 'secp384r1' });
    const spkiB64 = publicKey.export({ format: 'der', type: 'spki' }).toString('base64');
    expect(() => importPublicKey(spkiB64, 'ecdsa-p256')).toThrow();
  });
});

describe('canonical bytes stability', () => {
  it('is deterministic and field-order sensitive', () => {
    const a = canonicalPayloadBytes(samplePayload);
    const b = canonicalPayloadBytes({ ...samplePayload });
    expect(a.equals(b)).toBe(true);

    // Any field change changes the bytes -> changes what must be signed.
    const c = canonicalPayloadBytes({ ...samplePayload, nonce: 'different' });
    expect(a.equals(c)).toBe(false);
  });

  it('encodes the documented v1 prefix and newline layout', () => {
    const text = canonicalPayloadBytes(samplePayload).toString('utf8');
    expect(text.startsWith('bahasha.v1\n')).toBe(true);
    expect(text.split('\n')).toHaveLength(11);
  });
});

describe('hub API key hashing', () => {
  it('validates key format', () => {
    expect(isWellFormedHubKey('bhk_' + 'a'.repeat(43))).toBe(true);
    expect(isWellFormedHubKey('bhk_short')).toBe(false);
    expect(isWellFormedHubKey('nope_' + 'a'.repeat(43))).toBe(false);
  });

  it('hashes deterministically and compares in constant time', () => {
    const secret = 'test-hub-secret-must-be-32-characters-long';
    const key = 'bhk_' + 'a'.repeat(43);
    const h1 = hashHubKey(key, secret);
    const h2 = hashHubKey(key, secret);
    expect(h1).toBe(h2);
    expect(hubKeyHashEquals(h1, h2)).toBe(true);
    expect(hubKeyHashEquals(h1, hashHubKey('bhk_' + 'b'.repeat(43), secret))).toBe(false);
  });
});
