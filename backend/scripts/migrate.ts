/**
 * Migration runner.
 *
 * Applies backend/supabase/migrations/*.sql in filename order against
 * DATABASE_URL, inside a transaction per file, and records each applied file in
 * a schema_migrations table so re-runs are safe and incremental.
 *
 *   npm run db:migrate           apply any pending migrations
 *   npm run db:migrate -- --reset  DROP everything first, then apply (DEV ONLY)
 *
 * This talks raw Postgres (node-postgres), not the Supabase SDK, because DDL
 * and the service-role JWT are different trust paths -- migrations need the DB
 * password in DATABASE_URL, which never leaves the server.
 */

import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { config as loadDotenv } from 'dotenv';
import pg from 'pg';

loadDotenv();

const here = dirname(fileURLToPath(import.meta.url));
const migrationsDir = join(here, '..', 'supabase', 'migrations');

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL || /your-project-ref/.test(DATABASE_URL)) {
  console.error(
    'DATABASE_URL is not set to a real value.\n' +
      'Set it from Supabase -> Project Settings -> Database -> Connection string (URI).\n' +
      'It contains the DB password and must stay in the gitignored .env.',
  );
  process.exit(1);
}

const reset = process.argv.includes('--reset');

async function main(): Promise<void> {
  const client = new pg.Client({
    connectionString: DATABASE_URL,
    // Supabase requires TLS; its cert chain is public infra, so this is fine.
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();

  try {
    if (reset) {
      if (process.env.NODE_ENV === 'production') {
        throw new Error('refusing to --reset with NODE_ENV=production');
      }
      console.warn('--reset: dropping and recreating the public schema');
      await client.query('drop schema if exists public cascade; create schema public;');
      await client.query('grant usage on schema public to anon, authenticated, service_role;');
    }

    await client.query(`
      create table if not exists public.schema_migrations (
        filename   text primary key,
        applied_at timestamptz not null default now()
      );
    `);

    const applied = new Set(
      (await client.query<{ filename: string }>('select filename from public.schema_migrations')).rows.map(
        (r) => r.filename,
      ),
    );

    const files = readdirSync(migrationsDir)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    let count = 0;
    for (const file of files) {
      if (applied.has(file)) continue;
      const sql = readFileSync(join(migrationsDir, file), 'utf8');
      process.stdout.write(`applying ${file} ... `);
      await client.query('begin');
      try {
        await client.query(sql);
        await client.query('insert into public.schema_migrations (filename) values ($1)', [file]);
        await client.query('commit');
        console.log('ok');
        count += 1;
      } catch (err) {
        await client.query('rollback');
        console.log('FAILED');
        throw err;
      }
    }

    console.log(count === 0 ? 'already up to date' : `applied ${count} migration(s)`);
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error('\nmigration failed:', err instanceof Error ? err.message : err);
  process.exit(1);
});
