/**
 * MPESA Daraja callback webhook.
 *
 * Safaricom POSTs the outcome of each STK Push here. Daraja cannot send custom
 * auth headers, so this endpoint is protected by an unguessable secret path
 * segment (DARAJA_CALLBACK_SECRET) -- the route is mounted at
 * /mpesa/callback/:secret and rejects any mismatch. In production this should
 * be paired with a Safaricom source-IP allowlist at the platform edge.
 *
 * The handler ALWAYS returns 200 with Daraja's expected ack body once it has
 * durably recorded the outcome, because a non-200 makes Safaricom retry with
 * backoff. Idempotency lives in apply_stk_callback (0009), so retries are safe.
 */

import { Router } from 'express';
import { timingSafeEqual } from 'node:crypto';
import { env } from '../config/env.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { adminDb } from '../lib/supabase.js';
import { parseStkCallback } from '../services/daraja.js';
import { logger } from '../lib/logger.js';

export const mpesaRouter = Router();

function secretMatches(provided: string): boolean {
  const a = Buffer.from(provided);
  const b = Buffer.from(env.DARAJA_CALLBACK_SECRET);
  return a.length === b.length && timingSafeEqual(a, b);
}

mpesaRouter.post(
  '/mpesa/callback/:secret',
  asyncHandler(async (req, res) => {
    // Guard the path secret in constant time. On mismatch, 404 (not 401) so a
    // prober cannot tell a wrong secret from a nonexistent route.
    if (!secretMatches(req.params.secret ?? '')) {
      logger.warn({ ip: req.ip }, 'mpesa callback with bad path secret');
      res.status(404).json({ error: { code: 'not_found', message: 'Not found' } });
      return;
    }

    let result;
    try {
      result = parseStkCallback(req.body);
    } catch (err) {
      // Malformed body: log the raw payload for investigation, but still 200 so
      // Safaricom does not hammer us retrying an unparseable message.
      logger.error({ err, body: req.body }, 'unparseable mpesa callback');
      res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
      return;
    }

    const { data, error } = await adminDb.rpc('apply_stk_callback', {
      p_checkout_request_id: result.checkoutRequestId,
      p_result_code: result.resultCode,
      p_result_desc: result.resultDesc,
      p_mpesa_receipt: result.mpesaReceiptNumber ?? null,
      p_amount: result.amount ?? null,
      p_transaction_date: result.transactionDate ?? null,
      p_raw: req.body,
    });

    if (error) {
      // A DB error here is ours to fix; do NOT 200, so Safaricom retries and the
      // outcome is not silently lost.
      logger.error({ err: error, checkoutRequestId: result.checkoutRequestId }, 'apply_stk_callback failed');
      res.status(500).json({ ResultCode: 1, ResultDesc: 'Internal error' });
      return;
    }

    const outcome = Array.isArray(data) ? data[0]?.outcome : undefined;
    logger.info({ checkoutRequestId: result.checkoutRequestId, outcome }, 'mpesa callback applied');

    // Daraja's expected acknowledgement.
    res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
  }),
);
