/**
 * Hub ingest endpoint.
 *
 * A CVendor hub POSTs signed contribution payloads here. Authenticated by hub
 * API key (requireHub), rate-limited per hub, and each payload is fully
 * verified and settled by the ingest pipeline. Supports both a single payload
 * and a batch, because a hub that was offline replays its whole queue at once
 * when it reconnects.
 */

import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../middleware/async-handler.js';
import { validate } from '../middleware/validate.js';
import { requireHub } from '../middleware/authenticate.js';
import { ingestLimiter } from '../middleware/rate-limit.js';
import { contributionPayloadSchema } from '../domain/payload.js';
import { ingestContribution, type IngestContext } from '../services/ingest.js';
import { AppError } from '../lib/errors.js';
import { adminDb } from '../lib/supabase.js';

export const ingestRouter = Router();

// A batch is capped so one request cannot pin a worker; a hub with a larger
// backlog paginates. Each item is independent -- one bad payload does not sink
// the batch.
const batchSchema = z.object({
  payloads: z.array(contributionPayloadSchema).min(1).max(50),
});

ingestRouter.post(
  '/ingest',
  requireHub,
  ingestLimiter,
  validate('body', batchSchema),
  asyncHandler(async (req, res) => {
    const { payloads } = req.body as z.infer<typeof batchSchema>;
    const hub = req.hub!;
    const ctx: IngestContext = {
      hubId: hub.id,
      hubChurchId: hub.churchId,
      ipAddress: req.ip ?? null,
    };

    // Process sequentially: keeps DB load predictable and preserves per-device
    // counter ordering within a batch from the same device.
    const results = await Promise.all(
      payloads.map(async (payload) => {
        try {
          const result = await ingestContribution(payload, ctx);
          return { idempotencyKey: payload.idempotencyKey, ok: true as const, ...result };
        } catch (err) {
          // A rejected payload is a per-item outcome, not a request failure --
          // the hub needs to know which ones were refused and why, and must not
          // retry the whole batch because one packet was forged.
          const code = err instanceof AppError ? err.code : 'internal_error';
          const message = err instanceof AppError && err.expose ? err.message : 'Rejected';
          return { idempotencyKey: payload.idempotencyKey, ok: false as const, code, message };
        }
      }),
    );

    void adminDb
      .from('church_hubs')
      .update({ last_upload_at: new Date().toISOString() })
      .eq('id', hub.id)
      .then(() => undefined);

    const accepted = results.filter((r) => r.ok).length;
    res.status(207).json({ accepted, total: results.length, results });
  }),
);

/**
 * Hub heartbeat. Lets a background CVendor service report liveness and pull its
 * current status without uploading anything.
 */
ingestRouter.post(
  '/hub/heartbeat',
  requireHub,
  asyncHandler(async (req, res) => {
    const hub = req.hub!;
    const { data } = await adminDb
      .from('church_hubs')
      .select('id, name, status, last_upload_at')
      .eq('id', hub.id)
      .single();
    res.json({ hub: data });
  }),
);
