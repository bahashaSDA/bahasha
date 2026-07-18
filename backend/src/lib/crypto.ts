/**
 * Cryptographic primitives for the BLE contribution protocol.
 *
 * The security model, stated plainly, because it is easy to get wrong:
 *
 *   - Each Bahasha install generates an Ed25519 keypair. The private key never
 *     leaves the device keystore. The public key is registered in
 *     public.devices at signup.
 *
 *   - A contribution payload is signed on-device with that private key. The
 *     signature covers a canonical byte string (see canonicalPayloadBytes) that
 *     includes the device counter and a nonce.
 *
 *   - The CVendor hub relays the payload but is NOT trusted to vouch for it.
 *     This backend re-verifies the signature against the registered public key
 *     before it will trigger an STK Push. That is what stops a bystander in
 *     Bluetooth range from crafting a packet carrying someone else's phone
 *     number and spamming them with real payment prompts.
 *
 *   - Replay is defeated by the strictly-increasing per-device counter and the
 *     single-use nonce, both enforced by unique indexes in the database
 *     (0004_payments.sql). Crypto proves authenticity; the database proves
 *     freshness.
 *
 * Ed25519 is the default: 64-byte signatures, 32-byte keys, constant-time
 * verification in Node's built-in crypto, and no curve/parameter footguns.
 * ECDSA-P256 is supported for devices that can only do WebCrypto EC.
 */

import {
  createHmac,
  createPublicKey,
  timingSafeEqual,
  verify as nodeVerify,
  type KeyObject,
} from 'node:crypto';

export type KeyAlgorithm = 'ed25519' | 'ecdsa-p256';

/**
 * The canonical byte encoding a device signs and the backend verifies.
 *
 * Both sides MUST build these bytes identically or every signature fails, so
 * the format is deliberately rigid: fixed field order, newline-delimited, UTF-8,
 * no whitespace, amounts as integer strings. This is intentionally NOT
 * JSON.stringify of the payload -- key ordering in JSON is not guaranteed
 * across platforms, and a signature over a non-canonical encoding is a
 * signature over nothing.
 *
 * Documented in full in documentation/protocol/ble-protocol.md.
 */
export function canonicalPayloadBytes(input: {
  idempotencyKey: string;
  deviceUuid: string;
  userId: string;
  churchId: string;
  msisdn: string;
  totalAmount: number;
  counter: number;
  nonce: string;
  deviceTimestamp: string; // ISO-8601 UTC
  anonymous: boolean;
}): Buffer {
  // Field order is part of the wire contract. Do not reorder.
  const fields = [
    'bahasha.v1',
    input.idempotencyKey,
    input.deviceUuid,
    input.userId,
    input.churchId,
    input.msisdn,
    String(input.totalAmount),
    String(input.counter),
    input.nonce,
    input.deviceTimestamp,
    input.anonymous ? '1' : '0',
  ];
  return Buffer.from(fields.join('\n'), 'utf8');
}

/**
 * Parse a base64 SPKI-DER public key into a KeyObject for the given algorithm.
 * Throws on a malformed or wrong-type key; callers treat that as a verification
 * failure, never a 500.
 */
export function importPublicKey(base64Spki: string, algorithm: KeyAlgorithm): KeyObject {
  const der = Buffer.from(base64Spki, 'base64');
  const key = createPublicKey({ key: der, format: 'der', type: 'spki' });

  const asym = key.asymmetricKeyType;
  if (algorithm === 'ed25519' && asym !== 'ed25519') {
    throw new Error(`expected an ed25519 key, got ${asym ?? 'unknown'}`);
  }
  if (algorithm === 'ecdsa-p256') {
    if (asym !== 'ec') throw new Error(`expected an ec key, got ${asym ?? 'unknown'}`);
    const curve = key.asymmetricKeyDetails?.namedCurve;
    if (curve !== 'prime256v1') throw new Error(`expected P-256, got ${curve ?? 'unknown'}`);
  }
  return key;
}

/**
 * Verify a detached signature over `message` using a registered public key.
 * Returns a boolean; never throws for a bad signature (only for a malformed
 * key, which the caller imports separately). Node's verify is constant-time
 * with respect to the signature.
 */
export function verifySignature(
  publicKey: KeyObject,
  message: Buffer,
  signatureBase64: string,
  algorithm: KeyAlgorithm,
): boolean {
  const signature = Buffer.from(signatureBase64, 'base64');
  // Ed25519 signatures are exactly 64 bytes; reject anything else outright so a
  // truncated or padded signature cannot reach the verifier.
  if (algorithm === 'ed25519' && signature.length !== 64) return false;

  try {
    if (algorithm === 'ed25519') {
      // For Ed25519, the digest algorithm argument to verify() must be null.
      return nodeVerify(null, message, publicKey, signature);
    }
    // ECDSA-P256 signs the SHA-256 digest of the message.
    return nodeVerify('sha256', message, publicKey, signature);
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Hub API credentials
// ---------------------------------------------------------------------------
// A hub authenticates to the backend with a bearer credential. Only its HMAC
// digest is stored (church_hubs.api_key_hash); a database leak must not yield a
// working key. The plaintext key is shown to the deacon exactly once, at
// registration.

const HUB_KEY_PREFIX = 'bhk_';

/** Format: bhk_<43 url-safe base64 chars>. The prefix aids log grep + support. */
export function isWellFormedHubKey(key: string): boolean {
  return /^bhk_[A-Za-z0-9_-]{43}$/.test(key);
}

/** Deterministic HMAC of a hub key, for storage and lookup. */
export function hashHubKey(plaintextKey: string, secret: string): string {
  return createHmac('sha256', secret).update(plaintextKey).digest('hex');
}

/** First 8 chars, stored alongside the hash so a deacon can identify their key. */
export function hubKeyPrefix(plaintextKey: string): string {
  return plaintextKey.slice(0, 8);
}

/**
 * Constant-time comparison of two hub-key hashes. Prevents a timing side
 * channel from revealing how many leading bytes of a guessed key are correct.
 */
export function hubKeyHashEquals(a: string, b: string): boolean {
  const bufA = Buffer.from(a, 'utf8');
  const bufB = Buffer.from(b, 'utf8');
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

export { HUB_KEY_PREFIX };
