/**
 * Validates environment variables at startup so a misconfigured
 * deployment fails immediately with a clear message instead of
 * failing later on the first request.
 */
export function validateEnv(config: Record<string, unknown>) {
  const errors: string[] = [];
  const isProd = config.NODE_ENV === 'production';

  const jwtSecret = config.JWT_SECRET as string | undefined;
  if (!jwtSecret) {
    errors.push('JWT_SECRET is required');
  } else if (isProd && jwtSecret.length < 32) {
    errors.push('JWT_SECRET must be at least 32 characters in production');
  }

  if (!config.DATABASE_URL && !config.DB_HOST) {
    errors.push(
      'Set DATABASE_URL (recommended) or DB_HOST/DB_USER/DB_PASS/DB_NAME',
    );
  }

  if (isProd && !config.ADMIN_SETUP_KEY) {
    errors.push(
      'ADMIN_SETUP_KEY is required in production (protects first-admin registration)',
    );
  }

  if (errors.length) {
    throw new Error(
      `Invalid environment configuration:\n  - ${errors.join('\n  - ')}`,
    );
  }
  return config;
}
