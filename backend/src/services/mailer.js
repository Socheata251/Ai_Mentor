import nodemailer from 'nodemailer';
import { config } from '../config.js';
import { HttpError } from '../middleware/errors.js';

export const mailConfigured = () =>
  Boolean(config.mail.brevoKey || config.mail.resendKey || config.smtp.host);

// "iLearnCode <me@gmail.com>"  ->  { name, email }
function parseFrom(from) {
  const m = /^\s*"?([^"<]*?)"?\s*<([^>]+)>\s*$/.exec(from || '');
  return m ? { name: m[1].trim() || 'iLearnCode', email: m[2].trim() } : { name: 'iLearnCode', email: (from || '').trim() };
}

// Render (and most free hosts) block SMTP ports, so mail goes over HTTPS instead.
async function postJson(url, headers, body) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json', ...headers },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(15000),
  });
  if (!res.ok) throw new Error(`${res.status} ${(await res.text()).slice(0, 300)}`);
}

const sendBrevo = ({ to, subject, text, html }) => {
  const sender = parseFrom(config.smtp.from);
  return postJson('https://api.brevo.com/v3/smtp/email', { 'api-key': config.mail.brevoKey }, {
    sender, to: [{ email: to }], subject, textContent: text, htmlContent: html,
  });
};

const sendResend = ({ to, subject, text, html }) =>
  postJson('https://api.resend.com/emails', { Authorization: `Bearer ${config.mail.resendKey}` }, {
    from: config.smtp.from, to: [to], subject, text, html,
  });

/** Only while developing without email: the API may return the code so the app can fill it in. */
export const canExposeDevCode = () => !config.isProd && !mailConfigured();

let transport;

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
  if (config.mail.brevoKey || config.mail.resendKey) {
    try {
      await (config.mail.brevoKey ? sendBrevo : sendResend)({ to, subject, text, html });
      return;
    } catch (e) {
      console.error('email failed:', e.message);
      throw new HttpError(502, 'email_failed', 'We could not send the email. Please try again later.');
    }
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