import 'dotenv/config';

const env = process.env;
const isProd = env.NODE_ENV === 'production';

if (!env.JWT_SECRET || (isProd && env.JWT_SECRET.length < 32)) {
  throw new Error('JWT_SECRET is missing (use at least 32 characters in production).');
}
if (!env.DATABASE_URL) throw new Error('DATABASE_URL is missing.');
// 'local'    = this server stores passwords and emails the OTP codes itself (old way).
// 'supabase' = Supabase Auth keeps the accounts and sends the OTP emails.
const authProvider = (env.AUTH_PROVIDER || 'local').trim().toLowerCase();
if (!['local', 'supabase'].includes(authProvider)) {
  throw new Error('AUTH_PROVIDER must be "local" or "supabase".');
}
if (authProvider === 'supabase' && (!env.SUPABASE_URL || !env.SUPABASE_ANON_KEY)) {
  throw new Error('AUTH_PROVIDER=supabase needs SUPABASE_URL and SUPABASE_ANON_KEY (Supabase > Project Settings > API).');
}
if (authProvider === 'local' && isProd && !env.SMTP_HOST && !env.BREVO_API_KEY && !env.RESEND_API_KEY) {
  throw new Error('Production needs a way to email the OTP codes: set BREVO_API_KEY (or RESEND_API_KEY, or SMTP_HOST).');
}

export const config = {
  isProd,
  port: Number(env.PORT || 3000),
  databaseUrl: env.DATABASE_URL,
  jwtSecret: env.JWT_SECRET,
  authProvider,
  supabase: {
    url: (env.SUPABASE_URL || '').trim().replace(/\/+$/, ''), // https://xxxx.supabase.co
    anonKey: (env.SUPABASE_ANON_KEY || '').trim(), // the public "anon" / "publishable" key
    jwtSecret: (env.SUPABASE_JWT_SECRET || '').trim(), // only for projects that still sign tokens with HS256
  },
  accessTtl: env.ACCESS_TOKEN_TTL || '15m',
  refreshDays: Number(env.REFRESH_TOKEN_DAYS || 30),
  corsOrigins: (env.CORS_ORIGINS || '*').split(',').map((s) => s.trim()),
  authRateMax: Number(env.AUTH_RATE_MAX || 20),
  trustProxy: env.TRUST_PROXY === '1',
  // Email through an HTTPS API. Needed on hosts that block SMTP (Railway Free/Hobby, Render...).
  mail: { brevoKey: env.BREVO_API_KEY || '', resendKey: env.RESEND_API_KEY || '' },
  // Email sending with SMTP (Gmail "app password"). Nothing configured = codes are printed in the terminal.
  smtp: {
    host: env.SMTP_HOST || '',
    port: Number(env.SMTP_PORT || 465),
    user: env.SMTP_USER || '',
    pass: env.SMTP_PASS || '',
    from: env.MAIL_FROM || env.SMTP_USER || 'iLearnCode <no-reply@localhost>',
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