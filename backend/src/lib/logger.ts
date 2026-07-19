/**
 * Structured logging.
 *
 * Pino for JSON logs in production (Render ingests these as structured events)
 * and pretty output in development. A redaction list strips anything that could
 * carry a secret or PII out of the log stream -- logs are the single easiest
 * place to accidentally leak an MSISDN, a bearer token, or an MPESA receipt.
 */

import { pino } from 'pino';
import { env, isProduction } from '../config/env.js';

export const logger = pino({
  level: env.LOG_LEVEL,
  // Redact known-sensitive paths anywhere they appear in a logged object.
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'req.headers["x-hub-api-key"]',
      '*.password',
      '*.msisdn',
      '*.phone',
      '*.consumerSecret',
      '*.passkey',
      '*.privateKey',
      '*.serviceRoleKey',
      '*.signature',
      '*.ciphertext',
    ],
    censor: '[redacted]',
  },
  // Pretty output only in an interactive terminal. In serverless/hosted
  // environments (Vercel, Render, etc.) stdout is not a TTY, so we emit plain
  // JSON — pino-pretty runs a worker thread that is unreliable in serverless.
  ...(!isProduction && process.stdout.isTTY
    ? {
        transport: {
          target: 'pino-pretty',
          options: { colorize: true, translateTime: 'SYS:HH:MM:ss.l', ignore: 'pid,hostname' },
        },
      }
    : {}),
  base: { service: 'bahasha-backend' },
});

export type Logger = typeof logger;
