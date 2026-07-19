// Vercel serverless entry point for the Bahasha backend.
//
// Vercel runs `npm run build` (tsc -> dist/) first, then bundles this file as a
// serverless function. It imports the already-compiled Express app and exports
// it as the request handler. An Express app instance is itself a
// `(req, res) => void` function, which is exactly what Vercel's Node runtime
// invokes — so the entire API (health, register, ingest, MPESA callback) runs
// unchanged behind a single function, with the original request path preserved
// by the catch-all rewrite in vercel.json.
//
// This mirrors src/server.ts, minus app.listen(): serverless owns the socket.

// tsconfig rootDir is ".", so tsc mirrors the tree: src/app.ts -> dist/src/app.js.
import { createApp } from '../dist/src/app.js';

const app = createApp();

export default app;
