/**
 * The contribution payload contract.
 *
 * This is the exact shape a Bahasha device builds, signs, and hands (encrypted)
 * to a CVendor hub over BLE; the hub forwards it here. The Zod schema is the
 * single source of truth for the wire format -- the Flutter app must produce
 * exactly this, and documentation/protocol/ble-protocol.md is generated to
 * match it.
 *
 * The hub uploads the DECRYPTED envelope fields plus the ciphertext it received;
 * the signature is verified server-side against the canonical byte encoding in
 * lib/crypto.ts. Field names here mirror the canonical field order there.
 */

import { z } from 'zod';

const uuid = z.string().uuid();

/** One category line within a contribution. */
export const allocationSchema = z.object({
  categoryCode: z
    .string()
    .regex(/^[a-z0-9]+(_[a-z0-9]+)*$/, 'categoryCode must be a snake_case category code'),
  // Whole shillings, > 0. The DB re-asserts this; validating here gives a clean
  // 400 instead of a constraint error.
  amount: z.number().int().positive().max(250_000),
});

/** The signed contribution payload as uploaded by a hub. */
export const contributionPayloadSchema = z
  .object({
    /** Idempotency key for the whole pipeline; minted on-device per contribution. */
    idempotencyKey: uuid,
    deviceUuid: uuid,
    userId: uuid,
    churchId: uuid,
    /** Payer number in E.164; the hub relays it verbatim from the device. */
    msisdn: z.string().regex(/^\+254[17][0-9]{8}$/, 'msisdn must be E.164 Kenyan mobile'),
    totalAmount: z.number().int().positive().max(250_000),
    allocations: z.array(allocationSchema).min(1).max(20),
    /** Strictly-increasing per-device replay counter. */
    counter: z.number().int().nonnegative(),
    /** Single-use handshake nonce. */
    nonce: z.string().min(8).max(128),
    /** Device clock at payload construction, ISO-8601 UTC. */
    deviceTimestamp: z.string().datetime(),
    anonymous: z.boolean(),
    /** base64 ciphertext exactly as received over BLE (retained for forensics). */
    ciphertext: z.string().min(1),
    /** base64 detached signature over the canonical bytes. */
    signature: z.string().min(1),
    /** Signing algorithm; must match the registered device key. */
    algorithm: z.enum(['ed25519', 'ecdsa-p256']).default('ed25519'),
  })
  .superRefine((p, ctx) => {
    // The allocations MUST sum to the declared total. This is the same
    // invariant the database enforces, checked early so a mismatch is a clean
    // 400 rather than a deferred constraint failure deep in a transaction.
    const sum = p.allocations.reduce((acc, a) => acc + a.amount, 0);
    if (sum !== p.totalAmount) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['totalAmount'],
        message: `allocations sum to ${sum} but totalAmount is ${p.totalAmount}`,
      });
    }
  });

export type ContributionPayload = z.infer<typeof contributionPayloadSchema>;
export type Allocation = z.infer<typeof allocationSchema>;
