import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { Pool } from 'pg';
import { runIngestion } from './pipeline.js';

/**
 * Phase 28 ingestion entry point.
 *
 * Usage: DATABASE_URL=... npm run ingest -- [manifest path] [--dry-run] [--fail-on-invalid]
 *
 * The command reports every candidate classification, including the ones it deliberately does not
 * import. It exits non-zero only when the run itself fails, or when --fail-on-invalid is given and
 * the manifest contains malformed rows.
 */

const DEFAULT_MANIFEST = 'data/ingestion/phase28-genesis-manifest.csv';

const main = async (): Promise<void> => {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error('DATABASE_URL is required for Phase 28 ingestion');

  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const failOnInvalid = args.includes('--fail-on-invalid');
  const manifestPath = args.find((argument) => !argument.startsWith('--')) ?? DEFAULT_MANIFEST;
  const resolvedPath = path.resolve(manifestPath);
  const manifestText = await fs.readFile(resolvedPath, 'utf8');

  const pool = new Pool({ connectionString: databaseUrl });
  try {
    const report = await runIngestion(pool, {
      manifestText,
      manifestSource: manifestPath,
      dryRun
    });
    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
    if (failOnInvalid && report.totals.INVALID > 0) {
      throw new Error(`manifest contains ${report.totals.INVALID} INVALID candidates`);
    }
  } finally {
    await pool.end();
  }
};

main().catch((error: unknown) => {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
  process.exitCode = 1;
});
