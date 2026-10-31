import nodemailer from 'nodemailer';
import { config } from '../config.js';
import { HttpError } from '../middleware/errors.js';

/**
 * How OTP emails are sent (first one that is set wins):
 *   1) BREVO_API_KEY   -> Brevo HTTPS API   (works on Render free: no SMTP port needed)
 *   2) RESEND_API_KEY  -> Resend HTTPS API
 *   3) SMTP_HOST       -> SMTP (Gmail etc.). NOTE: Render's free plan blocks SMTP ports.
 * Nothing set -> development: the code is printed in the terminal.
 */
export const mailConfigured = () =>
  Boolean(config.mail.brevoKey || config.mail.resendKey || config.smtp.host);

/** Only while developing without email: the API may return the code so the app can fill it in. */
export const canExposeDevCode = () => !config.isProd && !mailConfigured();

let transport;

/** "iLearnCode <me@gmail.com>"  ->  { name: 'iLearnCode', email: 'me@gmail.com' } */
function parseFrom(from) {
  const m = /^\s*"?([^"<]*?)"?\s*<([^>]+)>\s*$/.exec(from || '');
  return m ? { name: m[1].trim() || 'iLearnCode', email: m[2].trim() } : { name: 'iLearnCode', email: String(from || '').trim() };
}

async function postJson(url, headers, body, label) {
  let res;
  try {
    res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', accept: 'application/json', ...headers },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15_000),
    });
  } catch (e) {
    throw new Error(`${label} could not be reached: ${e.message}`);
  }
  if (!res.ok) {
    const detail = (await res.text().catch(() => '')).slice(0, 300);
    throw new Error(`${label} answered ${res.status}: ${detail}`);
  }
}

export async function sendOtpEmail({ to, code, purpose, ttlMinutes }) {
  const verify = purpose === 'verify';
  const subject = verify ? `Your iLearnCode verification code: ${code}` : `Your iLearnCode password reset code: ${code}`;
  const what = verify ? 'verify your email address' : 'reset your password';
  const text =
    `Your code is ${code}\n\nUse it to ${what}. It works for ${ttlMinutes} minutes.\n` +
    'Never share this code with anyone. If you did not ask for it, you can ignore this email.';
  const html =
    `<div style="font-family:Arial,sans-serif;max-width:420px">` +
    `<p>Use this code to ${what}:</p>` +
    `<p style="font-size:32px;font-weight:bold;letter-spacing:8px;margin:16px 0">${code}</p>` +
    `<p style="color:#555">It works for ${ttlMinutes} minutes. Never share it with anyone.</p>` +
    `<p style="color:#888;font-size:12px">If you did not ask for this code, ignore this email.</p></div>`;

  if (!mailConfigured()) {
    console.log(`\n[mail:dev] To: ${to}\n[mail:dev] ${subject}\n`);
    return;
  }

  const { from } = config.smtp;
  try {
    if (config.mail.brevoKey) {
      const sender = parseFrom(from);
      await postJson(
        'https://api.brevo.com/v3/smtp/email',
        { 'api-key': config.mail.brevoKey },
        { sender, to: [{ email: to }], subject, htmlContent: html, textContent: text },
        'Brevo',
      );
    } else if (config.mail.resendKey) {
      await postJson(
        'https://api.resend.com/emails',
        { authorization: `Bearer ${config.mail.resendKey}` },
        { from, to: [to], subject, html, text },
        'Resend',
      );
    } else {
      const { host, port, user, pass } = config.smtp;
      transport ??= nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: user ? { user, pass } : undefined,
        connectionTimeout: 10_000,
        greetingTimeout: 10_000,
        socketTimeout: 15_000,
      });
      await transport.sendMail({ from, to, subject, text, html });
    }
  } catch (e) {
    console.error('email failed:', e.message);
    throw new HttpError(502, 'email_failed', 'We could not send the email. Please try again later.');
  }
}