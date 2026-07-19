/**
 * Health endpoints.
 *
 *   /health/live  -- process is up. Never touches the DB; used by the platform
 *                    to decide whether to restart the container.
 *   /health       -- readiness: can we actually reach Supabase? Used by the
 *                    load balancer to decide whether to route traffic here.
 *
 * Readiness deliberately does a cheap, bounded query rather than trusting that
 * "the process started" means "the process can serve".
 */

import { Router } from 'express';
import { adminDb } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/async-handler.js';

export const healthRouter = Router();

// Friendly landing at the root so opening the base URL in a browser shows the
// API is alive and where to go, rather than a bare 404.
healthRouter.get('/', (_req, res) => {
  res.json({
    name: 'Bahasha API',
    status: 'ok',
    version: 'v1',
    endpoints: {
      health: '/health',
      liveness: '/health/live',
      churches: '/api/v1/churches',
      categories: '/api/v1/categories',
    },
  });
});

healthRouter.get('/health/live', (_req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

healthRouter.get(
  '/health',
  asyncHandler(async (_req, res) => {
    const started = Date.now();
    const { error } = await adminDb.from('churches').select('id').limit(1);
    const dbLatencyMs = Date.now() - started;

    if (error) {
      res.status(503).json({ status: 'degraded', database: 'unreachable', error: error.message });
      return;
    }
    res.json({ status: 'ok', database: 'ok', dbLatencyMs });
  }),
);
