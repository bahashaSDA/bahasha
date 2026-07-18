/**
 * Express application assembly.
 *
 * Kept separate from server.ts so tests can import the app and drive it with
 * supertest without binding a port. Middleware order is deliberate and
 * commented -- security headers and body limits come before routing; the error
 * handler and 404 come strictly last.
 */

import express, { type Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env.js';
import { httpLogger, requestId } from './middleware/request-context.js';
import { errorHandler, notFoundHandler } from './middleware/error-handler.js';
import { apiLimiter } from './middleware/rate-limit.js';
import { healthRouter } from './routes/health.js';
import { churchesRouter } from './routes/churches.js';
import { registrationRouter } from './routes/registration.js';
import { ingestRouter } from './routes/ingest.js';
import { mpesaRouter } from './routes/mpesa.js';

export function createApp(): Express {
  const app = express();

  // Render (and most PaaS) put a proxy in front; trust exactly one hop so
  // req.ip and rate-limit keys reflect the real client, not the proxy.
  app.set('trust proxy', 1);
  app.disable('x-powered-by');

  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGINS.length > 0 ? env.CORS_ORIGINS : false,
      credentials: true,
    }),
  );

  // Bound the body size: contribution batches are small, and an unbounded JSON
  // body is a trivial memory-exhaustion vector.
  app.use(express.json({ limit: '256kb' }));

  app.use(requestId);
  app.use(httpLogger);

  // Health is unversioned and unthrottled so probes always get through.
  app.use('/', healthRouter);

  // Everything else lives under /api/v1 and is subject to the base limiter;
  // routes add tighter limiters (auth, ingest) on top.
  const v1 = express.Router();
  v1.use(apiLimiter);
  v1.use(churchesRouter);
  v1.use(registrationRouter);
  v1.use(ingestRouter);
  v1.use(mpesaRouter);
  app.use('/api/v1', v1);

  // Terminal handlers, in order: unmatched -> 404, everything else -> error.
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
