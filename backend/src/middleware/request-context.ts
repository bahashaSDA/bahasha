/**
 * Assigns a request id and wires pino-http so every log line for a request is
 * correlated. The id is echoed back in the X-Request-Id header and embedded in
 * error responses, so a support ticket can be traced to exact log lines.
 */

import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import { pinoHttp } from 'pino-http';
import { logger } from '../lib/logger.js';

export function requestId(req: Request, res: Response, next: NextFunction): void {
  // Honour an upstream id (from a proxy/load balancer) if present and sane.
  const incoming = req.headers['x-request-id'];
  const id = typeof incoming === 'string' && incoming.length <= 128 ? incoming : randomUUID();
  (req as Request & { id: string }).id = id;
  res.setHeader('X-Request-Id', id);
  next();
}

export const httpLogger = pinoHttp({
  logger,
  genReqId: (req) => (req as Request & { id?: string }).id ?? randomUUID(),
  // Health checks are noise; drop them to debug so production logs stay signal.
  customLogLevel: (_req, res, err) => {
    if (err || res.statusCode >= 500) return 'error';
    if (res.statusCode >= 400) return 'warn';
    if (res.statusCode === 404) return 'debug';
    return 'info';
  },
  customSuccessMessage: (req, res) => `${req.method} ${req.url} -> ${res.statusCode}`,
  autoLogging: {
    ignore: (req) => req.url === '/health' || req.url === '/health/live',
  },
});
