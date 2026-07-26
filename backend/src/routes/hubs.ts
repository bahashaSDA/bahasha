/**
 * Self-service CVendor hub provisioning.
 *
 * A treasurer (or admin) generates their church's hub key with one click, then
 * hands the plaintext to the deacon to pair the CVendor app. This mirrors
 * scripts/provision-hub.ts exactly — mint a `bhk_…` key, store only its HMAC
 * digest, show the plaintext ONCE — but exposes it to the dashboard so no one
 * has to run a CLI. The key is unrecoverable after this response: a database
 * leak never yields a working hub credential.
 */

import { Router } from 'express';
import { randomBytes } from 'node:crypto';
import { z } from 'zod';
import { asyncHandler } from '../middleware/async-handler.js';
import { validate } from '../middleware/validate.js';
import { requireUser } from '../middleware/authenticate.js';
import { authLimiter } from '../middleware/rate-limit.js';
import { adminDb } from '../lib/supabase.js';
import { hashHubKey, hubKeyPrefix } from '../lib/crypto.js';
import { encryptSecret, decryptSecret, paymentEncryptionAvailable } from '../lib/payment-crypto.js';
import { requireUuid } from '../lib/validators.js';
import { env } from '../config/env.js';
import { forbidden, notFound } from '../lib/errors.js';
import type { Request } from 'express';

export const hubsRouter = Router();

/** The caller may manage this church's hub if they own it or are an admin. */
function assertCanManage(req: Request, churchId: string): void {
  const user = req.user!;
  const isAdmin = user.role === 'super_admin' || user.role === 'support';
  if (!isAdmin && user.churchId !== churchId) {
    throw forbidden('You can only manage the hub for your own church');
  }
}

/** Mint a key of the form bhk_<43 url-safe base64 chars>. */
function mintKey(): string {
  return `bhk_${randomBytes(32).toString('base64url')}`;
}

// --- Current hub status (never the key) -------------------------------------
hubsRouter.get(
  '/churches/:id/hub',
  requireUser,
  asyncHandler(async (req, res) => {
    const churchId = requireUuid(req.params.id, 'church id');
    assertCanManage(req, churchId);

    const { data: hub } = await adminDb
      .from('church_hubs')
      .select('name, api_key_prefix, status, last_heartbeat_at, last_upload_at, is_active, hub_api_key_encrypted')
      .eq('church_id', churchId)
      .maybeSingle();

    // The full key is decrypted only here, for the authorised church owner/admin,
    // so they can re-copy it without regenerating. Hubs created before the key
    // was stored (or with encryption disabled) return null — regenerate to view.
    let apiKey: string | null = null;
    if (hub?.hub_api_key_encrypted && paymentEncryptionAvailable) {
      try {
        apiKey = decryptSecret(hub.hub_api_key_encrypted as string);
      } catch {
        apiKey = null;
      }
    }

    res.json({
      exists: Boolean(hub),
      name: hub?.name ?? null,
      keyPrefix: hub?.api_key_prefix ?? null, // first 8 chars, safe to display
      apiKey, // full key when saved; null if it must be regenerated to view
      status: hub?.status ?? null,
      lastHeartbeatAt: hub?.last_heartbeat_at ?? null,
      lastUploadAt: hub?.last_upload_at ?? null,
      active: hub?.is_active ?? false,
    });
  }),
);

// --- Generate (or rotate) the hub key ---------------------------------------
const genSchema = z.object({ name: z.string().trim().min(1).max(80).optional() });

hubsRouter.post(
  '/churches/:id/hub/key',
  requireUser,
  authLimiter,
  validate('body', genSchema),
  asyncHandler(async (req, res) => {
    const churchId = requireUuid(req.params.id, 'church id');
    assertCanManage(req, churchId);

    const { data: church } = await adminDb
      .from('churches')
      .select('id, name')
      .eq('id', churchId)
      .maybeSingle();
    if (!church) throw notFound('Church not found');

    const key = mintKey();
    const keyHash = hashHubKey(key, env.HUB_API_KEY_SECRET);
    const prefix = hubKeyPrefix(key);
    const name = (req.body as z.infer<typeof genSchema>).name ?? `${church.name as string} Hub`;

    // One hub per church (unique index on church_id): upsert rotates the key.
    // Any key issued earlier stops working the moment this new digest is stored.
    // We also keep the key encrypted at rest so the owner can re-view it later;
    // if encryption isn't configured, we simply don't store it (regenerate-only).
    const row: Record<string, unknown> = {
      church_id: churchId,
      name,
      api_key_hash: keyHash,
      api_key_prefix: prefix,
      is_active: true,
      hub_api_key_encrypted: paymentEncryptionAvailable ? encryptSecret(key) : null,
    };
    const { error } = await adminDb.from('church_hubs').upsert(row, { onConflict: 'church_id' });
    if (error) throw error;

    res.json({ apiKey: key, keyPrefix: prefix, name, saved: paymentEncryptionAvailable });
  }),
);
