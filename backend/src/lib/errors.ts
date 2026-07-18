/**
 * Error taxonomy.
 *
 * Every failure the API returns is an AppError with a stable machine-readable
 * `code`, an HTTP status, and a safe public message. The error handler
 * (middleware/error-handler.ts) turns anything that is NOT an AppError into a
 * generic 500 -- so an unexpected exception can never leak a stack trace, a SQL
 * string, or a Postgres constraint name to a client.
 *
 * `code` is part of the API contract: clients branch on it, never on the
 * human-readable message.
 */

export type ErrorCode =
  | 'validation_error'
  | 'unauthorized'
  | 'forbidden'
  | 'not_found'
  | 'conflict'
  | 'idempotent_replay'
  | 'rate_limited'
  | 'payload_verification_failed'
  | 'payment_provider_error'
  | 'church_not_settleable'
  | 'internal_error'
  | 'service_unavailable';

const STATUS_BY_CODE: Record<ErrorCode, number> = {
  validation_error: 400,
  unauthorized: 401,
  forbidden: 403,
  not_found: 404,
  conflict: 409,
  idempotent_replay: 409,
  rate_limited: 429,
  payload_verification_failed: 422,
  payment_provider_error: 502,
  church_not_settleable: 409,
  internal_error: 500,
  service_unavailable: 503,
};

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly status: number;
  /** Structured, client-safe context. Never put secrets or PII here. */
  readonly details: Record<string, unknown> | undefined;
  /** True for errors that are safe to surface verbatim to the caller. */
  readonly expose: boolean;

  constructor(
    code: ErrorCode,
    message: string,
    options: { details?: Record<string, unknown>; cause?: unknown } = {},
  ) {
    super(message, options.cause !== undefined ? { cause: options.cause } : undefined);
    this.name = 'AppError';
    this.code = code;
    this.status = STATUS_BY_CODE[code];
    this.details = options.details;
    // 5xx errors are treated as internal: the message is replaced before it
    // reaches the client so implementation detail cannot escape.
    this.expose = this.status < 500;
    Error.captureStackTrace?.(this, AppError);
  }
}

// --- Convenience constructors ------------------------------------------------
// These keep call sites terse and the codes consistent across the codebase.

export const badRequest = (message: string, details?: Record<string, unknown>) =>
  new AppError('validation_error', message, details ? { details } : {});

export const unauthorized = (message = 'Authentication required') =>
  new AppError('unauthorized', message);

export const forbidden = (message = 'You do not have access to this resource') =>
  new AppError('forbidden', message);

export const notFound = (message = 'Resource not found') => new AppError('not_found', message);

export const conflict = (message: string, details?: Record<string, unknown>) =>
  new AppError('conflict', message, details ? { details } : {});

export const idempotentReplay = (message = 'This request was already processed') =>
  new AppError('idempotent_replay', message);

export const payloadVerificationFailed = (message: string, details?: Record<string, unknown>) =>
  new AppError('payload_verification_failed', message, details ? { details } : {});
