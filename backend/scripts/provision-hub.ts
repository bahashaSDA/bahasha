/**
 * Provision a CVendor church hub.
 *
 *   npx tsx scripts/provision-hub.ts <church-slug> [hub name]
 *
 * Creates the one hub for a church (or reuses it) and prints a freshly-minted
 * API key ONCE. Only the key's HMAC digest is stored — a database leak never
 * yields a working credential — so this plaintext is unrecoverable afterwards;
 * hand it to the deacon and do not log it.
 *
 * This is the real deacon-onboarding path, not a test fixture.
 */

import { randomBytes } from 'node:crypto';
import 'dotenv/config';
import pg from 'pg';
import { hashHubKey, hubKeyPrefix } from '../src/lib/crypto.js';

const secret = process.env.HUB_API_KEY_SECRET;
const dbUrl = process.env.DATABASE_URL;
if (!secret || !dbUrl) {
  console.error('HUB_API_KEY_SECRET and DATABASE_URL must be set in .env');
  process.exit(1);
}

const slug = process.argv[2];
const hubName = process.argv[3] ?? 'Church Hub';
if (!slug) {
  console.error('usage: tsx scripts/provision-hub.ts <church-slug> [hub name]');
  process.exit(1);
}

/** Mint a key of the form bhk_<43 url-safe base64 chars>. */
function mintKey(): string {
  const raw = randomBytes(32).toString('base64url'); // 43 chars
  return `bhk_${raw}`;
}

async function main(): Promise<void> {
  const client = new pg.Client({ connectionString: dbUrl, ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    const church = await client.query<{ id: string; name: string }>(
      'select id, name from public.churches where slug = $1',
      [slug],
    );
    if (church.rows.length === 0) throw new Error(`no church with slug "${slug}"`);
    const churchId = church.rows[0]!.id;

    const key = mintKey();
    const keyHash = hashHubKey(key, secret!);
    const prefix = hubKeyPrefix(key);

    // One hub per church (unique index on church_id): upsert the credential.
    const res = await client.query<{ id: string }>(
      `insert into public.church_hubs (church_id, name, api_key_hash, api_key_prefix, status)
         values ($1, $2, $3, $4, 'offline')
       on conflict (church_id) do update
         set name = excluded.name,
             api_key_hash = excluded.api_key_hash,
             api_key_prefix = excluded.api_key_prefix
       returning id`,
      [churchId, hubName, keyHash, prefix],
    );

    console.log('\nHub provisioned for:', church.rows[0]!.name);
    console.log('  hub id  :', res.rows[0]!.id);
    console.log('  key id  :', prefix);
    console.log('\n  API KEY (shown once — give it to the deacon, then it is gone):\n');
    console.log('   ', key, '\n');
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error('provisioning failed:', err instanceof Error ? err.message : err);
  process.exit(1);
});
