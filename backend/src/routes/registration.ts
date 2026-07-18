/**
 * Giver registration and device enrolment.
 *
 * Called once, when a Bahasha install first syncs. It creates (or reconciles,
 * via client_uuid) the user and registers the device public key that will
 * anchor every future contribution signature. The apps work offline first, so
 * this endpoint is idempotent on client_uuid / device_uuid: a retry after a
 * flaky connection must not create duplicates.
 *
 * Note this is unauthenticated: a giver has no prior credential to present.
 * Trust is established here by the device registering its public key; from then
 * on, authenticity is proven by signatures, not by this call.
 */

import { Router } from 'express';
import { z } from 'zod';
import { adminDb } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { validate } from '../middleware/validate.js';
import { badRequest, conflict, notFound } from '../lib/errors.js';
import { normalizeMsisdn } from '../lib/phone.js';
import { importPublicKey } from '../lib/crypto.js';
import { authLimiter } from '../middleware/rate-limit.js';

export const registrationRouter = Router();

const registerSchema = z.object({
  clientUuid: z.string().uuid(),
  fullName: z.string().trim().min(1).max(120),
  phone: z.string().min(7).max(20),
  churchId: z.string().uuid(),
  membershipStatus: z.enum(['member', 'visitor', 'other_church_member']),
  visibility: z.enum(['open', 'secret']).default('open'),
  device: z.object({
    deviceUuid: z.string().uuid(),
    publicKey: z.string().min(1), // base64 SPKI DER
    keyAlgorithm: z.enum(['ed25519', 'ecdsa-p256']).default('ed25519'),
    platform: z.string().max(40).optional(),
    model: z.string().max(80).optional(),
    appVersion: z.string().max(40).optional(),
  }),
});

registrationRouter.post(
  '/register',
  authLimiter,
  validate('body', registerSchema),
  asyncHandler(async (req, res) => {
    const body = req.body as z.infer<typeof registerSchema>;

    // Normalise the phone to E.164 up front; the DB will reject anything else.
    const msisdn = normalizeMsisdn(body.phone);
    if (!msisdn) throw badRequest('phone is not a valid Kenyan mobile number');

    // Validate the public key actually parses for the stated algorithm BEFORE
    // we store it -- a device whose key we cannot import could never have a
    // contribution verified, so reject it at enrolment rather than at giving.
    try {
      importPublicKey(body.device.publicKey, body.device.keyAlgorithm);
    } catch (err) {
      throw badRequest('device.publicKey is not a valid key for the stated algorithm', {
        reason: (err as Error).message,
      });
    }

    // Church must exist and be active.
    const { data: church } = await adminDb
      .from('churches')
      .select('id')
      .eq('id', body.churchId)
      .eq('is_active', true)
      .maybeSingle();
    if (!church) throw notFound('Church not found');

    // --- Reconcile the user on client_uuid (idempotent registration) --------
    const { data: existingUser } = await adminDb
      .from('users')
      .select('id, phone, church_id')
      .eq('client_uuid', body.clientUuid)
      .maybeSingle();

    let userId: string;
    if (existingUser) {
      userId = existingUser.id as string;
      // Allow profile corrections on re-register, but a phone already used by a
      // DIFFERENT person at this church is a conflict the DB unique index will
      // also refuse -- surface it cleanly.
      const { error: updErr } = await adminDb
        .from('users')
        .update({
          full_name: body.fullName,
          phone: msisdn,
          church_id: body.churchId,
          membership_status: body.membershipStatus,
          visibility: body.visibility,
          last_seen_at: new Date().toISOString(),
        })
        .eq('id', userId);
      if (updErr) {
        if (updErr.code === '23505') throw conflict('That phone number is already registered at this church');
        throw updErr;
      }
    } else {
      const { data: created, error: insErr } = await adminDb
        .from('users')
        .insert({
          client_uuid: body.clientUuid,
          full_name: body.fullName,
          phone: msisdn,
          church_id: body.churchId,
          membership_status: body.membershipStatus,
          visibility: body.visibility,
        })
        .select('id')
        .single();
      if (insErr) {
        if (insErr.code === '23505') throw conflict('That phone number is already registered at this church');
        throw insErr;
      }
      userId = created.id as string;
    }

    // --- Register / update the device ---------------------------------------
    // Upsert on device_uuid. A device that re-enrols keeps its identity but may
    // rotate its key; the replay counter is preserved by not overwriting it.
    const { error: devErr } = await adminDb.from('devices').upsert(
      {
        user_id: userId,
        device_uuid: body.device.deviceUuid,
        public_key: body.device.publicKey,
        key_algorithm: body.device.keyAlgorithm,
        platform: body.device.platform ?? null,
        model: body.device.model ?? null,
        app_version: body.device.appVersion ?? null,
        last_seen_at: new Date().toISOString(),
      },
      { onConflict: 'device_uuid' },
    );
    if (devErr) throw devErr;

    // Seed a default theme row if none exists (offline-first apps expect one).
    await adminDb.from('themes').upsert({ user_id: userId }, { onConflict: 'user_id' });

    res.status(201).json({ userId, churchId: body.churchId });
  }),
);

/**
 * Toggle giving visibility (Secret Giving <-> Give Openly) from Account
 * settings. Only affects FUTURE giving: past contributions keep the snapshot
 * they were made under (see visibility_snapshot in 0003), so this can never
 * retroactively de-anonymise or expose prior gifts.
 */
const visibilitySchema = z.object({
  clientUuid: z.string().uuid(),
  visibility: z.enum(['open', 'secret']),
});

registrationRouter.post(
  '/account/visibility',
  validate('body', visibilitySchema),
  asyncHandler(async (req, res) => {
    const { clientUuid, visibility } = req.body as z.infer<typeof visibilitySchema>;
    const { data, error } = await adminDb
      .from('users')
      .update({ visibility })
      .eq('client_uuid', clientUuid)
      .select('id')
      .maybeSingle();
    if (error) throw error;
    if (!data) throw notFound('User not found');
    res.json({ userId: data.id, visibility });
  }),
);
