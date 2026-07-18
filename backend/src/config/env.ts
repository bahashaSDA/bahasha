/**
 * Environment configuration.
 *
 * Parsed and validated once, at import time. If anything required is missing or
 * malformed the process exits before it can serve a request -- a payments
 * service that boots with a half-configured Daraja client is worse than one
 * that refuses to boot at all, because the failure surfaces mid-transaction
 * instead of at deploy time.
 */

import { config as loadDotenv } from 'dotenv';
import { z } from 'zod';

loadDotenv();

/**
 * A required string that must be at least `min` chars AND must not still be one
 * of the .env.example placeholder values. `.min()` is applied before `.refine()`
 * because refine returns a ZodEffects, which no longer exposes string builders.
 */
const notPlaceholder = (field: string, min = 1) =>
  z
    .string()
    .min(min)
    .refine(
      (v) => !/^(changeme|placeholder|your[-_]|xxx|todo)/i.test(v),
      `${field} still holds its .env.example placeholder value`,
    );

const envSchema = z
  .object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: z.coerce.number().int().positive().max(65535).default(8080),
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),

    /** Comma-separated origins allowed to call the API (the dashboard). */
    CORS_ORIGINS: z
      .string()
      .default('')
      .transform((v) =>
        v
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
      ),

    // --- Supabase -----------------------------------------------------------
    // Accept the project URL and normalise to its origin: people frequently
    // paste the REST endpoint (…/rest/v1/) from the API page, which the SDK
    // then doubles into an invalid path. Strip any path/trailing slash so both
    // forms work.
    SUPABASE_URL: z
      .string()
      .url()
      .transform((v) => new URL(v).origin),
    /**
     * Service role key. Bypasses RLS, so it never leaves the server and is
     * never sent to a client. See docs/protocol for the trust boundary.
     */
    SUPABASE_SERVICE_ROLE_KEY: notPlaceholder('SUPABASE_SERVICE_ROLE_KEY', 20),
    /**
     * Anon (public) key. Safe to expose; it is RLS-constrained. Used for the
     * per-request client that runs dashboard reads UNDER the caller's policies.
     * Optional so the backend can boot for BLE/Daraja work before the dashboard
     * is wired, but any RLS-scoped read will fail with a clear error until set.
     */
    SUPABASE_ANON_KEY: z.string().min(20).optional(),
    /** Used only to verify JWTs minted by Supabase Auth for dashboard users. */
    SUPABASE_JWT_SECRET: notPlaceholder('SUPABASE_JWT_SECRET', 20).optional(),
    /** Direct Postgres URL, for migrations only. */
    DATABASE_URL: z.string().url().optional(),

    // --- MPESA Daraja -------------------------------------------------------
    // Optional at the schema level so the backend boots for registration/BLE
    // development before MPESA credentials exist. The superRefine below makes
    // them mandatory (and non-placeholder) in production, and isDarajaConfigured
    // gates the settlement path at runtime.
    DARAJA_ENV: z.enum(['sandbox', 'production']).default('sandbox'),
    DARAJA_CONSUMER_KEY: z.string().optional(),
    DARAJA_CONSUMER_SECRET: z.string().optional(),
    /** Lipa Na MPESA online passkey for the shortcode. */
    DARAJA_PASSKEY: z.string().optional(),
    /** Business shortcode initiating the STK Push. */
    DARAJA_SHORTCODE: z
      .string()
      .regex(/^[0-9]{5,7}$/, 'DARAJA_SHORTCODE must be 5-7 digits')
      .optional(),
    /**
     * Public HTTPS URL Safaricom posts callbacks to. Must be reachable from the
     * internet -- localhost will silently never receive a confirmation.
     */
    DARAJA_CALLBACK_URL: z.string().url().optional(),
    /**
     * Shared secret embedded in the callback path. Daraja cannot send custom
     * auth headers, so an unguessable path segment plus a source-IP allowlist
     * is the practical way to keep forged callbacks out.
     */
    DARAJA_CALLBACK_SECRET: z.string().min(32),

    // --- Protocol -----------------------------------------------------------
    /** HMAC key for hub API credentials. */
    HUB_API_KEY_SECRET: notPlaceholder('HUB_API_KEY_SECRET', 32),
    /** How stale a device-signed payload may be before it is refused. */
    PAYLOAD_MAX_AGE_SECONDS: z.coerce.number().int().positive().default(900),
  })
  .superRefine((env, ctx) => {
    if (env.NODE_ENV !== 'production') return;

    // In production, the Daraja credentials are mandatory and must be real --
    // a live deployment that cannot settle money is not a valid deployment.
    const darajaRequired: Array<[keyof typeof env, string | undefined]> = [
      ['DARAJA_CONSUMER_KEY', env.DARAJA_CONSUMER_KEY],
      ['DARAJA_CONSUMER_SECRET', env.DARAJA_CONSUMER_SECRET],
      ['DARAJA_PASSKEY', env.DARAJA_PASSKEY],
      ['DARAJA_SHORTCODE', env.DARAJA_SHORTCODE],
      ['DARAJA_CALLBACK_URL', env.DARAJA_CALLBACK_URL],
    ];
    for (const [key, value] of darajaRequired) {
      if (!value || /^(changeme|placeholder|your[-_]|xxx|todo)/i.test(value)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: [key],
          message: `${key} is required and must be a real value in production`,
        });
      }
    }

    // Production-only invariants. These are cheap to state and expensive to
    // discover in the field.
    if (env.DARAJA_ENV !== 'production') {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['DARAJA_ENV'],
        message: 'NODE_ENV=production requires DARAJA_ENV=production; refusing to run live traffic against the sandbox',
      });
    }
    if (env.DARAJA_CALLBACK_URL && !env.DARAJA_CALLBACK_URL.startsWith('https://')) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['DARAJA_CALLBACK_URL'],
        message: 'DARAJA_CALLBACK_URL must be HTTPS in production',
      });
    }
    if (env.CORS_ORIGINS.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['CORS_ORIGINS'],
        message: 'CORS_ORIGINS must list the dashboard origin explicitly in production',
      });
    }
    if (env.CORS_ORIGINS.includes('*')) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['CORS_ORIGINS'],
        message: 'CORS_ORIGINS may not be a wildcard in production',
      });
    }
  });

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // Deliberately console.error rather than the logger: the logger reads config,
  // and this runs before config exists.
  const detail = parsed.error.issues
    .map((i) => `  - ${i.path.join('.') || '(root)'}: ${i.message}`)
    .join('\n');
  console.error(`Invalid environment configuration:\n${detail}\n`);
  process.exit(1);
}

export const env = Object.freeze(parsed.data);
export type Env = typeof env;

export const isProduction = env.NODE_ENV === 'production';
export const isTest = env.NODE_ENV === 'test';

/**
 * Whether the MPESA settlement path is usable. When false (dev without Daraja
 * keys yet), ingest still verifies and records contributions but the STK Push
 * step is skipped with a clear, logged reason instead of crashing.
 *
 * A value must be present AND not a leftover .env.example placeholder — an
 * unset key and a "changeme-…" key are equally unusable, and treating the
 * placeholder as configured makes ingest attempt a doomed OAuth call against
 * Safaricom on every contribution.
 */
const isRealValue = (v: string | undefined): boolean =>
  Boolean(v) && !/^(changeme|placeholder|your[-_]|xxx|todo)/i.test(v!);

export const isDarajaConfigured =
  isRealValue(env.DARAJA_CONSUMER_KEY) &&
  isRealValue(env.DARAJA_CONSUMER_SECRET) &&
  isRealValue(env.DARAJA_PASSKEY) &&
  isRealValue(env.DARAJA_SHORTCODE) &&
  isRealValue(env.DARAJA_CALLBACK_URL);

/** Daraja base URL derived from DARAJA_ENV so it can never drift out of sync. */
export const darajaBaseUrl =
  env.DARAJA_ENV === 'production'
    ? 'https://api.safaricom.co.ke'
    : 'https://sandbox.safaricom.co.ke';
