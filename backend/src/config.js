import 'dotenv/config';

const env = process.env;
const isProd = env.NODE_ENV === 'production';

if (!env.JWT_SECRET || (isProd && env.JWT_SECRET.length < 32)) {
  throw new Error('JWT_SECRET is missing (use at least 32 characters in production).');
}
if (!env.DATABASE_URL) throw new Error('DATABASE_URL is missing.');
if (isProd && !env.SMTP_HOST) throw new Error('SMTP_HOST is missing: production needs a way to email the OTP codes.');

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
  // Email sending (free: use a Gmail "app password"). Empty SMTP_HOST = codes are printed in the terminal.
  smtp: {
    host: env.SMTP_HOST || '',
    port: Number(env.SMTP_PORT || 465),
    user: env.SMTP_USER || '',
    pass: env.SMTP_PASS || '',
    from: env.MAIL_FROM || env.SMTP_USER || 'Astra Learn <no-reply@localhost>',
  },
  otp: {
    ttlMinutes: Number(env.OTP_TTL_MINUTES || 10),
    maxAttempts: 5,
    cooldownSeconds: Number(env.OTP_COOLDOWN_SECONDS || 60),
    hourlyLimit: 5,
  },
  ai: {
    provider: env.AI_PROVIDER || 'anthropic',
    apiKey: env.AI_API_KEY || '', // empty => mock replies
    model: env.AI_MODEL || '',
    baseUrl: env.AI_BASE_URL || ((env.AI_PROVIDER || 'anthropic') === 'ollama' ? 'http://localhost:11434' : 'https://api.anthropic.com'),
  },
};