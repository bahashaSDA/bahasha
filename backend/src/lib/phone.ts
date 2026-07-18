/**
 * Kenyan MSISDN normalisation.
 *
 * The database stores phone numbers in strict E.164 (+2547XXXXXXXX /
 * +2541XXXXXXXX) and rejects anything else (see is_valid_msisdn in 0001). Users
 * type numbers a dozen ways -- 0712..., 712..., 254712..., +254 712 345 678 --
 * so normalisation happens once, here, at the API edge. Daraja's STK Push,
 * separately, wants the number WITHOUT the leading '+' (254...), so we expose
 * both forms rather than let call sites hand-roll the conversion.
 */

const E164 = /^\+254[17][0-9]{8}$/;

/**
 * Normalise a user-entered Kenyan number to E.164, or return null if it cannot
 * be a valid Kenyan mobile number. Never throws -- callers decide how to report
 * a rejection.
 */
export function normalizeMsisdn(raw: string): string | null {
  if (typeof raw !== 'string') return null;

  // Strip spaces, hyphens, and parentheses that people paste in.
  let s = raw.replace(/[\s\-()]/g, '');
  if (s === '') return null;

  if (s.startsWith('+')) {
    // already prefixed
  } else if (s.startsWith('254')) {
    s = `+${s}`;
  } else if (s.startsWith('0')) {
    // 0712345678 -> +254712345678
    s = `+254${s.slice(1)}`;
  } else if (/^[17][0-9]{8}$/.test(s)) {
    // bare 712345678 / 112345678
    s = `+254${s}`;
  } else {
    return null;
  }

  return E164.test(s) ? s : null;
}

/** True if the string is already valid E.164 Kenyan mobile. */
export function isE164Msisdn(s: string): boolean {
  return E164.test(s);
}

/**
 * Daraja form: the E.164 number without its leading '+'. STK Push's
 * PhoneNumber and PartyA fields expect 2547XXXXXXXX.
 */
export function toDarajaMsisdn(e164: string): string {
  return e164.replace(/^\+/, '');
}
