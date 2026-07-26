/**
 * Small shared validators for untrusted input that reaches the database.
 */

import { badRequest } from './errors.js';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Assert a value is a well-formed UUID, returning it narrowed to `string`.
 * Use on every route param that is interpolated into (or passed to) a query —
 * a valid UUID cannot carry PostgREST filter-injection payloads, so this closes
 * that class of attack at the boundary.
 */
export function requireUuid(value: unknown, field = 'id'): string {
  if (typeof value !== 'string' || !UUID_RE.test(value)) {
    throw badRequest(`${field} must be a valid UUID`);
  }
  return value;
}

export const isUuid = (value: unknown): value is string =>
  typeof value === 'string' && UUID_RE.test(value);
