/**
 * The contribution ingest pipeline.
 *
 * A CVendor hub POSTs a signed payload; this turns it into money moving, or
 * refuses it, in a fixed sequence where every step can only reject:
 *
 *   1. Idempotency     -- seen this idempotency key already? return the prior
 *                         result, never charge twice.
 *   2. Device identity -- the device_uuid must resolve to a registered,
 *                         non-revoked device whose user owns the payload's
 *                         user_id AND the payload's phone number.
 *   3. Freshness       -- device timestamp within PAYLOAD_MAX_AGE_SECONDS, and
 *                         counter strictly greater than the device's last.
 *   4. Signature       -- verify against the registered public key over the
 *                         canonical bytes. THIS is the trust anchor; the hub's
 *                         say-so counts for nothing.
 *   5. Persist         -- record the payload, create the contribution and its
 *                         allocations, advance the device counter -- via an
 *                         atomic RPC so a crash cannot leave a half-charge.
 *   6. Settle          -- issue the STK Push and record the transaction.
 *
 * Steps 1-4 are cheap and ordered cheapest-rejection-first. A forged packet is
 * discarded before it can touch the payment path.
 */

import { env, isDarajaConfigured } from '../config/env.js';
import { AppError, payloadVerificationFailed } from '../lib/errors.js';
import { logger } from '../lib/logger.js';
import { adminDb } from '../lib/supabase.js';
import {
  canonicalPayloadBytes,
  importPublicKey,
  verifySignature,
  type KeyAlgorithm,
} from '../lib/crypto.js';
import { toDarajaMsisdn } from '../lib/phone.js';
import { initiateStkPush } from './daraja.js';
import type { ContributionPayload } from '../domain/payload.js';

export interface IngestContext {
  hubId: string;
  hubChurchId: string;
  ipAddress: string | null;
}

export interface IngestResult {
  status: 'accepted' | 'duplicate';
  contributionId: string;
  checkoutRequestId: string | null;
  /** Present when the STK Push could not be issued but the contribution stands. */
  settlementError?: string;
}

/** Record a rejected packet for forensics, then throw the client-facing error. */
async function reject(
  payload: ContributionPayload,
  ctx: IngestContext,
  reason: string,
  publicReason: string,
): Promise<never> {
  await adminDb
    .from('bluetooth_payloads')
    .insert({
      hub_id: ctx.hubId,
      church_id: ctx.hubChurchId,
      device_uuid: payload.deviceUuid,
      idempotency_key: payload.idempotencyKey,
      ciphertext: payload.ciphertext,
      signature: payload.signature,
      counter: payload.counter,
      nonce: payload.nonce,
      status: 'rejected',
      rejection_reason: reason,
      byte_size: payload.ciphertext.length,
    })
    // A duplicate (device_uuid,counter) or nonce collision on a *rejected*
    // insert is itself fine -- the point is a record exists. Swallow it.
    .then(({ error }) => {
      if (error) logger.debug({ error, reason }, 'could not persist rejected payload');
    });

  logger.warn(
    { reason, deviceUuid: payload.deviceUuid, hubId: ctx.hubId, church: ctx.hubChurchId },
    'payload rejected',
  );
  throw payloadVerificationFailed(publicReason, { reason });
}

export async function ingestContribution(
  payload: ContributionPayload,
  ctx: IngestContext,
): Promise<IngestResult> {
  // --- 0. Hub/church consistency --------------------------------------------
  // The payload names a church; it must be the hub's own church. A hub only
  // ever settles offerings for the congregation it belongs to.
  if (payload.churchId !== ctx.hubChurchId) {
    await reject(
      payload,
      ctx,
      `church mismatch: payload=${payload.churchId} hub=${ctx.hubChurchId}`,
      'This payload does not belong to your church',
    );
  }

  // --- 1. Idempotency --------------------------------------------------------
  const { data: existing } = await adminDb
    .from('contributions')
    .select('id, status')
    .eq('user_id', payload.userId)
    .eq('client_uuid', payload.idempotencyKey)
    .maybeSingle();

  if (existing) {
    const { data: txn } = await adminDb
      .from('transactions')
      .select('checkout_request_id')
      .eq('contribution_id', existing.id)
      .order('attempt', { ascending: false })
      .limit(1)
      .maybeSingle();
    logger.info({ contributionId: existing.id }, 'idempotent replay: returning prior result');
    return {
      status: 'duplicate',
      contributionId: existing.id as string,
      checkoutRequestId: (txn?.checkout_request_id as string | null) ?? null,
    };
  }

  // --- 2. Device identity ----------------------------------------------------
  const { data: device } = await adminDb
    .from('devices')
    .select('id, user_id, public_key, key_algorithm, last_counter, is_revoked')
    .eq('device_uuid', payload.deviceUuid)
    .maybeSingle();

  if (!device) {
    await reject(payload, ctx, 'unknown device', 'Device is not registered');
  }
  if (device!.is_revoked) {
    await reject(payload, ctx, 'revoked device', 'Device credential has been revoked');
  }
  if (device!.user_id !== payload.userId) {
    await reject(
      payload,
      ctx,
      `device/user mismatch: device belongs to ${device!.user_id}, payload claims ${payload.userId}`,
      'Device does not match the claimed user',
    );
  }

  // The phone number being charged must belong to the payload's user. This is
  // the check that stops a crafted packet from billing a stranger.
  const { data: user } = await adminDb
    .from('users')
    .select('id, phone, church_id, visibility')
    .eq('id', payload.userId)
    .maybeSingle();

  if (!user) {
    await reject(payload, ctx, 'unknown user', 'User is not registered');
  }
  if (user!.phone !== payload.msisdn) {
    await reject(
      payload,
      ctx,
      'msisdn does not match the user of record',
      'Phone number does not match the registered user',
    );
  }
  if (user!.church_id !== payload.churchId) {
    await reject(
      payload,
      ctx,
      `user church mismatch: user=${user!.church_id} payload=${payload.churchId}`,
      'User does not belong to this church',
    );
  }

  // --- 3. Freshness + replay -------------------------------------------------
  const ageSeconds = (Date.now() - new Date(payload.deviceTimestamp).getTime()) / 1000;
  if (ageSeconds > env.PAYLOAD_MAX_AGE_SECONDS) {
    await reject(
      payload,
      ctx,
      `stale payload: ${Math.round(ageSeconds)}s old (max ${env.PAYLOAD_MAX_AGE_SECONDS}s)`,
      'This contribution is too old to process; please try again',
    );
  }
  // A small negative age (device clock slightly ahead) is tolerated; a large
  // one is a forged future timestamp.
  if (ageSeconds < -env.PAYLOAD_MAX_AGE_SECONDS) {
    await reject(payload, ctx, `future-dated payload: ${Math.round(ageSeconds)}s`, 'Invalid timestamp');
  }
  if (payload.counter <= (device!.last_counter as number)) {
    await reject(
      payload,
      ctx,
      `replayed counter: ${payload.counter} <= last ${device!.last_counter}`,
      'This contribution has already been seen',
    );
  }

  // --- 4. Signature ----------------------------------------------------------
  const algorithm = (device!.key_algorithm as KeyAlgorithm) ?? 'ed25519';
  if (algorithm !== payload.algorithm) {
    await reject(
      payload,
      ctx,
      `algorithm mismatch: device=${algorithm} payload=${payload.algorithm}`,
      'Signature algorithm does not match the registered device',
    );
  }

  let signatureValid = false;
  try {
    const key = importPublicKey(device!.public_key as string, algorithm);
    const message = canonicalPayloadBytes({
      idempotencyKey: payload.idempotencyKey,
      deviceUuid: payload.deviceUuid,
      userId: payload.userId,
      churchId: payload.churchId,
      msisdn: payload.msisdn,
      totalAmount: payload.totalAmount,
      counter: payload.counter,
      nonce: payload.nonce,
      deviceTimestamp: payload.deviceTimestamp,
      anonymous: payload.anonymous,
    });
    signatureValid = verifySignature(key, message, payload.signature, algorithm);
  } catch (err) {
    logger.warn({ err }, 'signature verification errored');
    signatureValid = false;
  }

  if (!signatureValid) {
    await reject(payload, ctx, 'invalid signature', 'Payload signature is invalid');
  }

  // --- 5. Persist atomically -------------------------------------------------
  // One RPC does: insert bluetooth_payloads(verified), insert contribution +
  // allocations, advance devices.last_counter -- all in a single transaction,
  // with the counter advance conditional on it still being > last_counter so
  // two concurrent uploads cannot both win. See 0009_ingest_rpc.sql.
  const { data: persisted, error: persistErr } = await adminDb.rpc('ingest_contribution', {
    p_hub_id: ctx.hubId,
    p_church_id: payload.churchId,
    p_user_id: payload.userId,
    p_device_uuid: payload.deviceUuid,
    p_idempotency_key: payload.idempotencyKey,
    p_ciphertext: payload.ciphertext,
    p_signature: payload.signature,
    p_counter: payload.counter,
    p_nonce: payload.nonce,
    p_total_amount: payload.totalAmount,
    p_visibility: user!.visibility,
    p_device_timestamp: payload.deviceTimestamp,
    p_allocations: payload.allocations.map((a) => ({
      category_code: a.categoryCode,
      amount: a.amount,
    })),
  });

  if (persistErr) {
    // A unique violation here means a concurrent request won the race; treat as
    // a duplicate rather than an error.
    if (persistErr.code === '23505') {
      const { data: dup } = await adminDb
        .from('contributions')
        .select('id')
        .eq('user_id', payload.userId)
        .eq('client_uuid', payload.idempotencyKey)
        .maybeSingle();
      if (dup) {
        return { status: 'duplicate', contributionId: dup.id as string, checkoutRequestId: null };
      }
    }
    logger.error({ err: persistErr }, 'ingest persistence failed');
    throw new AppError('internal_error', 'Could not record the contribution', {
      cause: persistErr,
    });
  }

  const contributionId = persisted as string;

  // --- 6. Settle -------------------------------------------------------------
  // The contribution is durably recorded. If the STK Push fails now, the record
  // still stands and can be retried; we never lose the intent to give.

  // Before MPESA credentials are configured (early dev), record the
  // contribution and leave it pending settlement rather than crashing. This
  // lets the full BLE pipeline be exercised end-to-end before Daraja exists.
  if (!isDarajaConfigured) {
    logger.warn(
      { contributionId },
      'daraja not configured; contribution recorded but STK push skipped',
    );
    return {
      status: 'accepted',
      contributionId,
      checkoutRequestId: null,
      settlementError: 'MPESA settlement not configured; contribution is pending',
    };
  }

  try {
    const stk = await initiateStkPush({
      msisdn: toDarajaMsisdn(payload.msisdn),
      amount: payload.totalAmount,
      accountReference: contributionId.slice(0, 12),
      description: 'Offering',
    });

    await adminDb.rpc('record_stk_initiation', {
      p_contribution_id: contributionId,
      p_church_id: payload.churchId,
      p_msisdn: payload.msisdn,
      p_amount: payload.totalAmount,
      p_merchant_request_id: stk.merchantRequestId,
      p_checkout_request_id: stk.checkoutRequestId,
    });

    return { status: 'accepted', contributionId, checkoutRequestId: stk.checkoutRequestId };
  } catch (err) {
    const message = err instanceof AppError ? err.message : 'Payment initiation failed';
    logger.error({ err, contributionId }, 'stk push failed after persistence');
    await adminDb
      .from('contributions')
      .update({ status: 'failed', failure_reason: message, processed_at: new Date().toISOString() })
      .eq('id', contributionId);
    return { status: 'accepted', contributionId, checkoutRequestId: null, settlementError: message };
  }
}
