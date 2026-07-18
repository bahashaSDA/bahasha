/**
 * Terminal error handler. Every error path in the app converges here.
 *
 * Contract:
 *   - AppError -> its status + a { error: { code, message, details? } } body.
 *   - ZodError -> 400 validation_error with the field issues.
 *   - anything else -> 500 internal_error with a generic message and a logged
 *     stack. Implementation detail (SQL, stack traces, Postgres constraint
 *     names) never reaches the client.
 *
 * Response shape is stable and identical across every error, so clients parse
 * one thing.
 */

import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../lib/errors.js';
import { logger } from '../lib/logger.js';

interface ErrorBody {
  error: {
    code: string;
    message: string;
    details?: unknown;
    requestId?: string;
  };
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars -- Express needs the 4-arg arity to treat this as an error handler.
export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction): void {
  const requestId = (req as Request & { id?: string }).id;

  if (err instanceof AppError) {
    // Client errors are logged at warn; server-classified AppErrors at error.
    const level = err.status >= 500 ? 'error' : 'warn';
    logger[level]({ err, code: err.code, requestId }, 'request failed');

    const body: ErrorBody = {
      error: {
        code: err.code,
        // 5xx AppErrors are not exposed verbatim.
        message: err.expose ? err.message : 'An unexpected error occurred',
        ...(err.expose && err.details ? { details: err.details } : {}),
        ...(requestId ? { requestId } : {}),
      },
    };
    res.status(err.status).json(body);
    return;
  }

  if (err instanceof ZodError) {
    logger.warn({ issues: err.issues, requestId }, 'validation failed');
    const body: ErrorBody = {
      error: {
        code: 'validation_error',
        message: 'The request did not pass validation',
        details: err.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
        ...(requestId ? { requestId } : {}),
      },
    };
    res.status(400).json(body);
    return;
  }

  // Unknown: this is a bug or an unhandled edge. Log it fully; tell the client
  // nothing that could help an attacker.
  logger.error({ err, requestId }, 'unhandled error');
  const body: ErrorBody = {
    error: {
      code: 'internal_error',
      message: 'An unexpected error occurred',
      ...(requestId ? { requestId } : {}),
    },
  };
  res.status(500).json(body);
}

/** 404 for any route that did not match. Registered after all routes. */
export function notFoundHandler(_req: Request, res: Response): void {
  res.status(404).json({
    error: { code: 'not_found', message: 'The requested resource does not exist' },
  });
}
