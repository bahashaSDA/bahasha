/**
 * Supabase clients.
 *
 * Two distinct clients, on purpose, because they sit on opposite sides of the
 * trust boundary:
 *
 *   adminDb  -- service_role key. Bypasses RLS. This is what verifies device
 *               signatures, writes contributions, and calls into the payment
 *               path. It must NEVER be constructed with any request's user
 *               token, or a client could borrow its authority.
 *
 *   asUser   -- builds a per-request client bound to the caller's JWT, so every
 *               query runs *under RLS* as that user. Used for dashboard reads
 *               where the policies in 0007_rls.sql are the access control.
 *
 * The service_role key is read once here and never exported, so no other module
 * can accidentally forward it.
 */

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '../config/env.js';

const commonOptions = {
  auth: {
    // The backend is stateless; it holds no session and refreshes no token.
    persistSession: false,
    autoRefreshToken: false,
  },
} as const;

/**
 * Elevated client. RLS does not apply. Guard its use: every write it performs
 * must have been authorised in application code first (signature check, hub
 * credential, verified JWT), because the database will not second-guess it.
 */
export const adminDb: SupabaseClient = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  commonOptions,
);

/**
 * Per-request client that runs under the caller's Row Level Security context.
 *
 * Built on the ANON key -- never the service_role key -- so PostgREST derives
 * the effective role from the user's JWT and enforces the 0007_rls.sql
 * policies. Passing service_role here would hand the caller elevated rights,
 * which is precisely the bug this split exists to prevent.
 *
 * Pass the raw bearer token from the Authorization header.
 */
export function asUser(accessToken: string): SupabaseClient {
  if (!env.SUPABASE_ANON_KEY) {
    // Fail loud rather than silently falling back to an elevated client.
    throw new Error(
      'SUPABASE_ANON_KEY is not configured; RLS-scoped user queries are unavailable. ' +
        'Set it from Supabase -> Project Settings -> API -> Project API keys -> anon public.',
    );
  }
  return createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
    ...commonOptions,
    global: {
      headers: { Authorization: `Bearer ${accessToken}` },
    },
  });
}
