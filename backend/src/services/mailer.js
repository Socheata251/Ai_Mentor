import nodemailer from 'nodemailer';
import { config } from '../config.js';
import { HttpError } from '../middleware/errors.js';

export const mailConfigured = () => Boolean(config.smtp.host);

/** Only while developing without email: the API may return the code so the app can fill it in. */
export const canExposeDevCode = () => !config.isProd && !mailConfigured();

let transport;

export async function sendOtpEmail({ to, code, purpose, ttlMinutes }) {
  const verify = purpose === 'verify';
  const subject = verify ? `Your Astra Learn verification code: ${code}` : `Your Astra Learn password reset code: ${code}`;
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
  const { host, port, user, pass, from } = config.smtp;
  transport ??= nodemailer.createTransport({ host, port, secure: port === 465, auth: user ? { user, pass } : undefined });
  try {
    await transport.sendMail({ from, to, subject, text, html });
  } catch (e) {
    console.error('email failed:', e.message);
    throw new HttpError(502, 'email_failed', 'We could not send the email. Please try again later.');
  }
}
