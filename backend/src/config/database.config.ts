import { DataSourceOptions } from 'typeorm';
import { join } from 'path';

/**
 * Single source of truth for the database connection, shared by the
 * running app (app.module.ts) and the TypeORM CLI (data-source.ts).
 *
 * Production (Render/Railway): set DATABASE_URL and DB_SSL=true.
 * Local development: either DATABASE_URL or the DB_* variables.
 *
 * Schema changes are applied through migrations (src/migrations),
 * never by `synchronize`, so deploys can't silently drop columns.
 */
export function buildDataSourceOptions(
  env: NodeJS.ProcessEnv = process.env,
): DataSourceOptions {
  const ssl = env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false;

  const connection = env.DATABASE_URL
    ? { url: env.DATABASE_URL }
    : {
        host: env.DB_HOST ?? 'localhost',
        port: parseInt(env.DB_PORT ?? '5432', 10),
        username: env.DB_USER ?? 'postgres',
        password: env.DB_PASS,
        database: env.DB_NAME ?? 'kachipapa',
      };

  return {
    type: 'postgres',
    ...connection,
    ssl,
    entities: [join(__dirname, '..', '**', '*.entity.{ts,js}')],
    migrations: [join(__dirname, '..', 'migrations', '*.{ts,js}')],
    migrationsRun: env.DB_RUN_MIGRATIONS !== 'false',
    synchronize: false,
  };
}
