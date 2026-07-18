/**
 * Wraps an async route handler so a rejected promise is forwarded to Express's
 * error pipeline instead of hanging the request. Without this, an `await` that
 * throws inside a handler becomes an unhandled rejection and the client waits
 * until timeout.
 */

import type { NextFunction, Request, RequestHandler, Response } from 'express';

type AsyncRequestHandler = (req: Request, res: Response, next: NextFunction) => Promise<unknown>;

export function asyncHandler(handler: AsyncRequestHandler): RequestHandler {
  return (req, res, next) => {
    handler(req, res, next).catch(next);
  };
}
