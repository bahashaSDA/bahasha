/**
 * Encryption for church payment secrets (the MPESA Lipa Na M-Pesa Online
 * passkey). AES-256-GCM with a server-side key from PAYMENT_ENCRYPTION_KEY.
 *
 * The passkey lets the API sign STK Push requests against a church's paybill, so
 * it is a payment credential and must never be stored in the clear or returned
 * to any client. GCM gives us authenticated encryption: tampering with the
 * ciphertext is detected on decrypt. The stored format is
 *   base64(iv) . base64(authTag) . base64(ciphertext)
 * so everything needed to decrypt (except the key) travels with the value.
 */

import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';
import { env } from '../config/env.js';
import { AppError } from './errors.js';

const ALGO = 'aes-256-gcm';
const IV_LEN = 12; // GCM standard nonce length

function key(): Buffer {
  if (!env.PAYMENT_ENCRYPTION_KEY) {
    throw new AppError(
      'service_unavailable',
      'Payment encryption is not configured on this server (PAYMENT_ENCRYPTION_KEY missing)',
    );
  }
  return Buffer.from(env.PAYMENT_ENCRYPTION_KEY, 'hex');
}

/** Encrypt a secret; returns "iv.tag.ciphertext" (all base64). */
export function encryptSecret(plaintext: string): string {
  const iv = randomBytes(IV_LEN);
  const cipher = createCipheriv(ALGO, key(), iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv.toString('base64')}.${tag.toString('base64')}.${ciphertext.toString('base64')}`;
}

/** Decrypt a value produced by {@link encryptSecret}. Throws on tamper. */
export function decryptSecret(stored: string): string {
  const parts = stored.split('.');
  if (parts.length !== 3) throw new Error('malformed encrypted secret');
  const [iv, tag, ciphertext] = parts.map((p) => Buffer.from(p, 'base64'));
  const decipher = createDecipheriv(ALGO, key(), iv!);
  decipher.setAuthTag(tag!);
  return Buffer.concat([decipher.update(ciphertext!), decipher.final()]).toString('utf8');
}

/** Whether payment-secret encryption is available on this server. */
export const paymentEncryptionAvailable = Boolean(env.PAYMENT_ENCRYPTION_KEY);
