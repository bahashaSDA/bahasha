/**
 * Server entry point. Boots the HTTP listener and wires graceful shutdown so an
 * in-flight contribution is not severed mid-settlement on a deploy.
 */

import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './lib/logger.js';

const app = createApp();

const server = app.listen(env.PORT, () => {
  logger.info(
    { port: env.PORT, env: env.NODE_ENV, daraja: env.DARAJA_ENV },
    `Bahasha backend listening on :${env.PORT}`,
  );
});

// --- Graceful shutdown -------------------------------------------------------
// Render sends SIGTERM on deploy. Stop accepting new connections, let in-flight
// requests drain, then exit. A hard cap prevents a stuck request from blocking
// the deploy forever.
function shutdown(signal: string): void {
  logger.info({ signal }, 'shutting down');
  server.close((err) => {
    if (err) {
      logger.error({ err }, 'error during shutdown');
      process.exit(1);
    }
    logger.info('shutdown complete');
    process.exit(0);
  });
  setTimeout(() => {
    logger.error('shutdown timed out; forcing exit');
    process.exit(1);
  }, 15_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// A truly unexpected error should crash loudly so the platform restarts a clean
// process, rather than limp along in an unknown state.
process.on('unhandledRejection', (reason) => {
  logger.fatal({ reason }, 'unhandled promise rejection');
  process.exit(1);
});
process.on('uncaughtException', (err) => {
  logger.fatal({ err }, 'uncaught exception');
  process.exit(1);
});
