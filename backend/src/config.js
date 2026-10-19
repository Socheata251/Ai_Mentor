import 'dotenv/config';

const env = process.env;
const isProd = env.NODE_ENV === 'production';

if (!env.JWT_SECRET || (isProd && env.JWT_SECRET.length < 32)) {
  throw new Error('JWT_SECRET is missing (use at least 32 characters in production).');
}
if (!env.DATABASE_URL) throw new Error('DATABASE_URL is missing.');

export const config = {
  isProd,
  port: Number(env.PORT || 3000),
  databaseUrl: env.DATABASE_URL,
  jwtSecret: env.JWT_SECRET,
  accessTtl: env.ACCESS_TOKEN_TTL || '15m',
  refreshDays: Number(env.REFRESH_TOKEN_DAYS || 30),
  corsOrigins: (env.CORS_ORIGINS || '*').split(',').map((s) => s.trim()),
  authRateMax: Number(env.AUTH_RATE_MAX || 20),
  trustProxy: env.TRUST_PROXY === '1',
  ai: {
    provider: env.AI_PROVIDER || 'anthropic',
    apiKey: env.AI_API_KEY || '', // empty => mock replies
    model: env.AI_MODEL || '',
    baseUrl: env.AI_BASE_URL || 'https://api.anthropic.com',
  },
};
