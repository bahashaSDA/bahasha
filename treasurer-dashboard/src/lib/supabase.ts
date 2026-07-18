"use client";

import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Browser Supabase client for the treasurer dashboard.
 *
 * Uses the ANON key only. Everything this client can read is governed by the
 * Row Level Security policies and masking views in the backend
 * (`0007_rls.sql`): a treasurer sees their own church's giving, with secret
 * givers masked to a pseudonym. The service-role key NEVER reaches the browser.
 *
 * The session (treasurer login) is what scopes the data — an unauthenticated
 * client sees nothing but the public church list.
 */

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

let cached: SupabaseClient | null = null;

/** Returns the singleton browser client, or throws a clear config error. */
export function getSupabase(): SupabaseClient {
  if (!url || !anonKey) {
    throw new Error(
      "Supabase is not configured. Set NEXT_PUBLIC_SUPABASE_URL and " +
        "NEXT_PUBLIC_SUPABASE_ANON_KEY in .env.local (see .env.example).",
    );
  }
  cached ??= createClient(url, anonKey, {
    auth: { persistSession: true, autoRefreshToken: true },
  });
  return cached;
}

/** Whether the dashboard has its Supabase config — used to show a setup hint. */
export function isSupabaseConfigured(): boolean {
  return Boolean(url && anonKey);
}
