/**
 * Rate limiters.
 *
 * Three tiers, because the traffic classes have very different shapes:
 *
 *   apiLimiter      -- broad ceiling for general dashboard/API traffic.
 *   ingestLimiter   -- per-hub, generous: a busy Sabbath hub may relay hundreds
 *                      of legitimate payloads in a burst, so this is high but
 *                      bounded, keyed by hub so one compromised hub cannot
 *                      exhaust the budget for the rest.
 *   authLimiter     -- tight, on credential-checking endpoints, to blunt
 *                      brute-force against hub keys and logins.
 *
 * Keyed by hub id / user id where authenticated, falling back to IP. NOTE:
 * behind Render's proxy, app.set('trust proxy', 1) in app.ts is what makes the
 * client IP correct here.
 */

import rateLimit, { type Options } from 'express-rate-limit';
import type { Request } from 'express';
import { AppError } from '../lib/errors.js';

const shared: Partial<Options> = {
  standardHeaders: true,
  legacyHeaders: false,
  // Surface a rate-limit as our standard error shape, not the library default.
  handler: (_req, _res, next) => {
    next(new AppError('rate_limited', 'Too many requests; please slow down'));
  },
};

export const apiLimiter = rateLimit({
  ...shared,
  windowMs: 60_000,
  limit: 120, // 120 req/min per key
});

export const ingestLimiter = rateLimit({
  ...shared,
  windowMs: 60_000,
  limit: 600, // a busy hub relaying many givers at once
  keyGenerator: (req: Request) => req.hub?.id ?? req.ip ?? 'unknown',
});

export const authLimiter = rateLimit({
  ...shared,
  windowMs: 15 * 60_000,
  limit: 30, // 30 attempts / 15 min against credential endpoints
});
