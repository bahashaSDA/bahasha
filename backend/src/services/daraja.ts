/**
 * Safaricom Daraja (MPESA) client -- Lipa Na MPESA Online / STK Push.
 *
 * This is the real Daraja contract: OAuth token acquisition, the STK Push
 * request, and the shapes Safaricom sends back both synchronously and in the
 * async callback. It runs against the sandbox today and against production the
 * moment DARAJA_ENV flips and live credentials are in place -- there is no mock
 * layer to remove.
 *
 * Reference: https://developer.safaricom.co.ke/APIs (Lipa Na M-Pesa Online)
 */

import { darajaBaseUrl, env, isDarajaConfigured } from '../config/env.js';
import { AppError } from '../lib/errors.js';
import { logger } from '../lib/logger.js';

// --- OAuth token cache -------------------------------------------------------
// Daraja tokens live ~3600s. Re-fetching one per STK Push would roughly double
// the latency and hammer the auth endpoint, so cache with a safety margin.

interface CachedToken {
  token: string;
  expiresAt: number; // epoch ms
}
let cachedToken: CachedToken | null = null;

async function getAccessToken(): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expiresAt > now + 60_000) {
    return cachedToken.token;
  }

  const credentials = Buffer.from(
    `${env.DARAJA_CONSUMER_KEY}:${env.DARAJA_CONSUMER_SECRET}`,
  ).toString('base64');

  const res = await fetch(
    `${darajaBaseUrl}/oauth/v1/generate?grant_type=client_credentials`,
    { headers: { Authorization: `Basic ${credentials}` } },
  );

  if (!res.ok) {
    const body = await res.text().catch(() => '');
    logger.error({ status: res.status, body }, 'daraja oauth failed');
    throw new AppError('payment_provider_error', 'Could not authenticate with the payment provider');
  }

  const json = (await res.json()) as { access_token?: string; expires_in?: string };
  if (!json.access_token) {
    throw new AppError('payment_provider_error', 'Payment provider returned no access token');
  }

  const ttlSeconds = Number(json.expires_in ?? '3599');
  cachedToken = { token: json.access_token, expiresAt: now + ttlSeconds * 1000 };
  return cachedToken.token;
}

// --- STK Push ----------------------------------------------------------------

/** yyyyMMddHHmmss in East Africa Time, as Daraja's Timestamp field requires. */
function darajaTimestamp(date = new Date()): string {
  // Daraja expects EAT (UTC+3). Build the string from a UTC+3 shifted instant.
  const eat = new Date(date.getTime() + 3 * 60 * 60 * 1000);
  const p = (n: number, w = 2) => String(n).padStart(w, '0');
  return (
    `${eat.getUTCFullYear()}` +
    `${p(eat.getUTCMonth() + 1)}` +
    `${p(eat.getUTCDate())}` +
    `${p(eat.getUTCHours())}` +
    `${p(eat.getUTCMinutes())}` +
    `${p(eat.getUTCSeconds())}`
  );
}

export interface StkPushRequest {
  /** Payer number in Daraja form: 2547XXXXXXXX (no '+'). */
  msisdn: string;
  /** Whole shillings. */
  amount: number;
  /** Shown on the payer's handset and echoed in the callback. */
  accountReference: string;
  /** Free-text description, <= 13 chars is safest for Daraja. */
  description: string;
}

export interface StkPushResult {
  merchantRequestId: string;
  checkoutRequestId: string;
  /** Daraja's synchronous acceptance code; '0' means the push was queued. */
  responseCode: string;
  responseDescription: string;
  customerMessage: string;
}

/**
 * Issue an STK Push. A '0' ResponseCode means Safaricom accepted the request
 * and will prompt the handset; the actual payment outcome arrives later on the
 * callback URL. A non-zero code or a transport error is surfaced as a
 * payment_provider_error so the caller can mark the attempt failed.
 */
export async function initiateStkPush(request: StkPushRequest): Promise<StkPushResult> {
  if (!isDarajaConfigured) {
    // Guard so a misconfigured environment fails loudly here rather than
    // sending a half-formed request to Safaricom.
    throw new AppError('service_unavailable', 'MPESA settlement is not configured on this server');
  }
  const token = await getAccessToken();
  const timestamp = darajaTimestamp();
  const password = Buffer.from(
    `${env.DARAJA_SHORTCODE}${env.DARAJA_PASSKEY}${timestamp}`,
  ).toString('base64');

  const body = {
    BusinessShortCode: env.DARAJA_SHORTCODE,
    Password: password,
    Timestamp: timestamp,
    TransactionType: 'CustomerPayBillOnline',
    Amount: request.amount,
    PartyA: request.msisdn,
    PartyB: env.DARAJA_SHORTCODE,
    PhoneNumber: request.msisdn,
    CallBackURL: env.DARAJA_CALLBACK_URL,
    AccountReference: request.accountReference.slice(0, 12),
    TransactionDesc: request.description.slice(0, 13),
  };

  const res = await fetch(`${darajaBaseUrl}/mpesa/stkpush/v1/processrequest`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;

  if (!res.ok || json.ResponseCode !== '0') {
    // Daraja puts the reason in errorMessage (HTTP error) or ResponseDescription.
    const reason =
      (json.errorMessage as string) ??
      (json.ResponseDescription as string) ??
      `HTTP ${res.status}`;
    logger.error({ status: res.status, reason }, 'stk push rejected');
    throw new AppError('payment_provider_error', 'The payment request was rejected', {
      details: { reason },
    });
  }

  return {
    merchantRequestId: json.MerchantRequestID as string,
    checkoutRequestId: json.CheckoutRequestID as string,
    responseCode: json.ResponseCode as string,
    responseDescription: json.ResponseDescription as string,
    customerMessage: json.CustomerMessage as string,
  };
}

// --- Callback parsing --------------------------------------------------------

export interface StkCallbackResult {
  merchantRequestId: string;
  checkoutRequestId: string;
  resultCode: number;
  resultDesc: string;
  /** Present only on success (resultCode === 0). */
  mpesaReceiptNumber?: string;
  amount?: number;
  phoneNumber?: string;
  transactionDate?: string; // ISO-8601
}

/**
 * Parse the STK callback body Safaricom POSTs to CallBackURL. Its metadata is a
 * positional array of { Name, Value } items, so this normalises it into a flat,
 * typed result. resultCode 0 = success; anything else is a failure/cancel whose
 * reason is in resultDesc.
 */
export function parseStkCallback(payload: unknown): StkCallbackResult {
  const stk = (payload as { Body?: { stkCallback?: Record<string, unknown> } })?.Body?.stkCallback;
  if (!stk) {
    throw new AppError('validation_error', 'Callback body is not a recognised STK callback');
  }

  const resultCode = Number(stk.ResultCode);
  const base: StkCallbackResult = {
    merchantRequestId: String(stk.MerchantRequestID ?? ''),
    checkoutRequestId: String(stk.CheckoutRequestID ?? ''),
    resultCode,
    resultDesc: String(stk.ResultDesc ?? ''),
  };

  if (resultCode !== 0) return base;

  const items =
    (stk.CallbackMetadata as { Item?: Array<{ Name: string; Value?: unknown }> })?.Item ?? [];
  const byName = new Map(items.map((i) => [i.Name, i.Value]));

  // Build up only the fields that are actually present. exactOptionalPropertyTypes
  // forbids assigning `undefined` to an optional prop, so absent metadata items
  // are omitted rather than set to undefined.
  const success: StkCallbackResult = { ...base };
  const receipt = byName.get('MpesaReceiptNumber');
  if (receipt != null) success.mpesaReceiptNumber = String(receipt);
  const amount = byName.get('Amount');
  if (amount != null) success.amount = Number(amount);
  const phone = byName.get('PhoneNumber');
  if (phone != null) success.phoneNumber = String(phone);
  const rawDate = byName.get('TransactionDate');
  if (rawDate != null) {
    // Daraja sends yyyyMMddHHmmss (EAT). Convert to a real instant.
    const iso = parseDarajaDate(String(rawDate));
    if (iso) success.transactionDate = iso;
  }
  return success;
}

/** yyyyMMddHHmmss (EAT) -> ISO-8601 UTC. */
function parseDarajaDate(raw: string): string | undefined {
  const m = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/.exec(raw);
  if (!m) return undefined;
  const [, y, mo, d, h, mi, s] = m;
  // Interpret as EAT (UTC+3) and express as UTC.
  const asUtc = Date.UTC(+y!, +mo! - 1, +d!, +h!, +mi!, +s!);
  return new Date(asUtc - 3 * 60 * 60 * 1000).toISOString();
}
