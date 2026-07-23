/**
 * Self-service church payment onboarding.
 *
 * A church treasurer (or a Bahasha admin) configures their OWN paybill so
 * contributions settle directly into it — no central aggregation, no manual
 * integration by Bahasha. The passkey is a payment secret: it is encrypted at
 * rest and NEVER returned to any client, not even the treasurer who set it.
 *
 * All three endpoints require a signed-in dashboard user, and authorise that
 * the caller owns the church (treasurer) or is a platform admin.
 */

import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../middleware/async-handler.js';
import { validate } from '../middleware/validate.js';
import { requireUser } from '../middleware/authenticate.js';
import { authLimiter } from '../middleware/rate-limit.js';
import { adminDb } from '../lib/supabase.js';
import { encryptSecret, decryptSecret, paymentEncryptionAvailable } from '../lib/payment-crypto.js';
import { normalizeMsisdn, toDarajaMsisdn } from '../lib/phone.js';
import { initiateStkPush } from '../services/daraja.js';
import { isDarajaConfigured } from '../config/env.js';
import { badRequest, forbidden, notFound, AppError } from '../lib/errors.js';
import type { Request } from 'express';

export const paymentsRouter = Router();

/** The caller may manage this church's payments if they own it or are an admin. */
function assertCanManage(req: Request, churchId: string): void {
  const user = req.user!;
  const isAdmin = user.role === 'super_admin' || user.role === 'support';
  if (!isAdmin && user.churchId !== churchId) {
    throw forbidden('You can only manage payments for your own church');
  }
}

// --- Read current status (never the passkey) --------------------------------
paymentsRouter.get(
  '/churches/:id/payment-config',
  requireUser,
  asyncHandler(async (req, res) => {
    const churchId = req.params.id!;
    assertCanManage(req, churchId);

    const { data: church } = await adminDb
      .from('churches')
      .select('id, name, mpesa_shortcode, mpesa_passkey_encrypted, payments_configured_at')
      .eq('id', churchId)
      .maybeSingle();
    if (!church) throw notFound('Church not found');

    res.json({
      churchId: church.id,
      churchName: church.name,
      shortcode: church.mpesa_shortcode ?? null,
      // Booleans only — the encrypted passkey never leaves the server.
      hasPasskey: Boolean(church.mpesa_passkey_encrypted),
      configured: Boolean(church.mpesa_shortcode && church.mpesa_passkey_encrypted),
      configuredAt: church.payments_configured_at ?? null,
    });
  }),
);

// --- Save shortcode + passkey ----------------------------------------------
const configSchema = z.object({
  shortcode: z.string().regex(/^[0-9]{5,7}$/, 'Paybill/till must be 5–7 digits'),
  passkey: z.string().trim().min(20, 'The passkey looks too short').max(120),
});

paymentsRouter.put(
  '/churches/:id/payment-config',
  requireUser,
  authLimiter,
  validate('body', configSchema),
  asyncHandler(async (req, res) => {
    const churchId = req.params.id!;
    assertCanManage(req, churchId);
    if (!paymentEncryptionAvailable) {
      throw new AppError('service_unavailable', 'Payment setup is not enabled on this server yet');
    }

    const { shortcode, passkey } = req.body as z.infer<typeof configSchema>;

    const { data: church } = await adminDb.from('churches').select('id').eq('id', churchId).maybeSingle();
    if (!church) throw notFound('Church not found');

    const { error } = await adminDb
      .from('churches')
      .update({
        mpesa_shortcode: shortcode,
        mpesa_passkey_encrypted: encryptSecret(passkey),
        payments_configured_at: new Date().toISOString(),
      })
      .eq('id', churchId);
    if (error) throw error;

    res.json({ churchId, shortcode, configured: true });
  }),
);

// --- Fire a test STK Push to prove the config works -------------------------
const testSchema = z.object({ phone: z.string().min(7).max(20) });

paymentsRouter.post(
  '/churches/:id/payment-config/test',
  requireUser,
  authLimiter,
  validate('body', testSchema),
  asyncHandler(async (req, res) => {
    const churchId = req.params.id!;
    assertCanManage(req, churchId);
    if (!isDarajaConfigured) {
      throw new AppError('service_unavailable', 'MPESA is not configured on this server yet');
    }

    const msisdn = normalizeMsisdn((req.body as z.infer<typeof testSchema>).phone);
    if (!msisdn) throw badRequest('Enter a valid Kenyan mobile number');

    const { data: church } = await adminDb
      .from('churches')
      .select('mpesa_shortcode, mpesa_passkey_encrypted')
      .eq('id', churchId)
      .maybeSingle();
    if (!church?.mpesa_shortcode || !church?.mpesa_passkey_encrypted) {
      throw badRequest('Save your paybill and passkey first, then test');
    }

    const stk = await initiateStkPush({
      shortcode: church.mpesa_shortcode,
      passkey: decryptSecret(church.mpesa_passkey_encrypted),
      msisdn: toDarajaMsisdn(msisdn),
      amount: 1, // a 1-shilling test
      accountReference: 'BAHASHA-TEST',
      description: 'Test',
    });

    res.json({
      ok: true,
      message: 'Test prompt sent — check the phone for an MPESA PIN request for KSh 1.',
      checkoutRequestId: stk.checkoutRequestId,
    });
  }),
);
