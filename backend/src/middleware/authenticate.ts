/**
 * Authentication guards.
 *
 * Two independent schemes, because two different classes of caller reach this
 * API and neither should be able to assume the other's identity:
 *
 *   requireUser  -- treasurers and admins from the dashboard, carrying a
 *                   Supabase-issued JWT in `Authorization: Bearer <jwt>`. The
 *                   token is verified against SUPABASE_JWT_SECRET (HS256), and
 *                   the caller's role is resolved from the staff tables. The
 *                   raw token is stashed so downstream handlers can build an
 *                   RLS-scoped client via asUser().
 *
 *   requireHub   -- CVendor hubs uploading payloads, carrying a hub API key in
 *                   `X-Hub-Api-Key`. The key is HMAC-hashed and matched against
 *                   church_hubs.api_key_hash in constant time.
 */

import type { NextFunction, Request, Response } from 'express';
import { createRemoteJWKSet, jwtVerify, decodeProtectedHeader, type JWTPayload } from 'jose';
import { env } from '../config/env.js';
import { forbidden, unauthorized, AppError } from '../lib/errors.js';
import { adminDb } from '../lib/supabase.js';
import { hashHubKey, hubKeyHashEquals, isWellFormedHubKey } from '../lib/crypto.js';

// Supabase issues asymmetric JWTs (ES256/RS256) signed by rotating keys exposed
// at the project's JWKS endpoint. createRemoteJWKSet fetches and caches those
// public keys (and re-fetches on an unknown `kid`), so verification keeps
// working across key rotations without any redeploy. Legacy projects that still
// mint HS256 tokens are handled by the shared-secret fallback below.
const jwks = createRemoteJWKSet(new URL(`${env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`));

/**
 * Verify a Supabase access token regardless of signing scheme:
 *   - HS256  -> shared secret (SUPABASE_JWT_SECRET), the legacy scheme.
 *   - ES256/RS256/EdDSA -> the project's public JWKS.
 * Returns the decoded payload, or throws for any invalid/expired token.
 */
async function verifySupabaseToken(token: string): Promise<JWTPayload> {
  let alg: string | undefined;
  try {
    alg = decodeProtectedHeader(token).alg;
  } catch {
    throw unauthorized('Invalid or expired token');
  }

  if (alg === 'HS256' && !env.SUPABASE_JWT_SECRET) {
    throw unauthorized('Dashboard authentication is not configured on this server');
  }

  try {
    if (alg === 'HS256') {
      const { payload } = await jwtVerify(
        token,
        new TextEncoder().encode(env.SUPABASE_JWT_SECRET!),
        { algorithms: ['HS256'] },
      );
      return payload;
    }
    const { payload } = await jwtVerify(token, jwks, { algorithms: ['ES256', 'RS256', 'EdDSA'] });
    return payload;
  } catch (err) {
    if (err instanceof AppError) throw err;
    throw unauthorized('Invalid or expired token');
  }
}

// --- Types augmenting the request --------------------------------------------

export interface AuthenticatedUser {
  id: string;
  role: 'treasurer' | 'super_admin' | 'support' | 'auditor';
  churchId: string | null; // null for platform admins (all churches)
  accessToken: string;
}

export interface AuthenticatedHub {
  id: string;
  churchId: string;
  name: string;
}

declare module 'express-serve-static-core' {
  interface Request {
    user?: AuthenticatedUser;
    hub?: AuthenticatedHub;
  }
}

// --- User (dashboard) auth ---------------------------------------------------

function bearerToken(req: Request): string | null {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return null;
  const token = header.slice('Bearer '.length).trim();
  return token.length > 0 ? token : null;
}

/**
 * Verifies the Supabase JWT and resolves the caller to a treasurer or admin.
 * A valid signature is necessary but not sufficient: the `sub` must map to an
 * active staff row, otherwise a legitimately-signed token for, say, a giver
 * (who has no dashboard access) is still rejected.
 */
export async function requireUser(req: Request, _res: Response, next: NextFunction): Promise<void> {
  try {
    const token = bearerToken(req);
    if (!token) throw unauthorized('Missing bearer token');

    const payload = await verifySupabaseToken(token);

    const sub = payload.sub;
    if (typeof sub !== 'string') throw unauthorized('Token has no subject');

    // Resolve role. Admin takes precedence over treasurer if somehow both.
    const [{ data: admin }, { data: treasurer }] = await Promise.all([
      adminDb.from('admins').select('id, role, is_active').eq('id', sub).maybeSingle(),
      adminDb.from('treasurers').select('id, church_id, is_active').eq('id', sub).maybeSingle(),
    ]);

    if (admin?.is_active) {
      req.user = {
        id: sub,
        role: admin.role as AuthenticatedUser['role'],
        churchId: null,
        accessToken: token,
      };
      return next();
    }

    if (treasurer?.is_active) {
      req.user = {
        id: sub,
        role: 'treasurer',
        churchId: treasurer.church_id as string,
        accessToken: token,
      };
      return next();
    }

    throw forbidden('This account has no dashboard access');
  } catch (err) {
    next(err);
  }
}

/** Route guard: caller must be a platform super admin. */
export function requireSuperAdmin(req: Request, _res: Response, next: NextFunction): void {
  if (req.user?.role !== 'super_admin') {
    return next(forbidden('Super admin access required'));
  }
  next();
}

/** Route guard: caller must be any active admin (super_admin/support/auditor). */
export function requireAdmin(req: Request, _res: Response, next: NextFunction): void {
  const role = req.user?.role;
  if (role !== 'super_admin' && role !== 'support' && role !== 'auditor') {
    return next(forbidden('Admin access required'));
  }
  next();
}

// --- Hub auth ----------------------------------------------------------------

/**
 * Authenticates a CVendor hub by its API key. The key is never compared as
 * plaintext against anything: it is HMAC-hashed and the digest is matched, in
 * constant time, so neither a database read nor a timing measurement yields a
 * usable credential.
 */
export async function requireHub(req: Request, _res: Response, next: NextFunction): Promise<void> {
  try {
    const provided = req.headers['x-hub-api-key'];
    if (typeof provided !== 'string' || !isWellFormedHubKey(provided)) {
      throw unauthorized('Missing or malformed hub API key');
    }

    const hash = hashHubKey(provided, env.HUB_API_KEY_SECRET);

    // Look up by hash (unique index). A hit means the hash matched, but we still
    // re-compare in constant time as defence in depth against any DB-side
    // normalisation surprise.
    const { data: hub } = await adminDb
      .from('church_hubs')
      .select('id, church_id, name, api_key_hash, is_active')
      .eq('api_key_hash', hash)
      .maybeSingle();

    if (!hub || !hub.is_active || !hubKeyHashEquals(hub.api_key_hash as string, hash)) {
      throw unauthorized('Unrecognised hub API key');
    }

    req.hub = {
      id: hub.id as string,
      churchId: hub.church_id as string,
      name: hub.name as string,
    };

    // Best-effort liveness stamp; a failure here must not fail the request.
    void adminDb
      .from('church_hubs')
      .update({ last_heartbeat_at: new Date().toISOString(), status: 'online' })
      .eq('id', hub.id)
      .then(() => undefined);

    next();
  } catch (err) {
    next(err);
  }
}
