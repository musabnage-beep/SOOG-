import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SmsProvider } from './messaging.interface';

/** Dev SMS provider: logs the message (so OTP codes are visible during development). */
@Injectable()
export class ConsoleSmsProvider implements SmsProvider {
  private readonly logger = new Logger('SMS');

  async send(to: string, message: string): Promise<void> {
    this.logger.log(`[DEV-SMS] to=${to} :: ${message}`);
  }
}

/**
 * msegat SMS provider (popular in KSA). Requires SMS_API_KEY (API key),
 * SMS_SENDER_ID (approved sender name), and SMS_USERNAME (account username).
 */
@Injectable()
export class MsegatSmsProvider implements SmsProvider {
  private readonly logger = new Logger('SMS');
  private readonly username: string;
  private readonly apiKey: string;
  private readonly senderId: string;

  constructor(config: ConfigService) {
    this.username = config.get<string>('SMS_USERNAME', '');
    this.apiKey = config.get<string>('SMS_API_KEY', '');
    this.senderId = config.get<string>('SMS_SENDER_ID', 'ALDIAFAH');
  }

  async send(to: string, message: string): Promise<void> {
    const number = to.replace('+', '');
    const res = await fetch('https://www.msegat.com/gw/sendsms.php', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userName: this.username,
        apiKey: this.apiKey,
        numbers: number,
        userSender: this.senderId,
        msg: message,
        msgEncoding: 'UTF8',
      }),
    });
    const text = await res.text();
    if (!res.ok || text.includes('error') || text === '0') {
      this.logger.error(`msegat SMS failed for ${to}: ${text}`);
      throw new Error(`SMS provider error: ${text}`);
    }
  }
}

/**
 * Twilio SMS provider. Requires TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN,
 * and TWILIO_PHONE_NUMBER (the purchased Twilio phone number, e.g. +12345678900).
 */
@Injectable()
export class TwilioSmsProvider implements SmsProvider {
  private readonly logger = new Logger('SMS');
  private readonly accountSid: string;
  private readonly authToken: string;
  private readonly fromNumber: string;

  constructor(config: ConfigService) {
    this.accountSid = config.get<string>('TWILIO_ACCOUNT_SID', '');
    this.authToken = config.get<string>('TWILIO_AUTH_TOKEN', '');
    this.fromNumber = config.get<string>('TWILIO_PHONE_NUMBER', '');
  }

  async send(to: string, message: string): Promise<void> {
    const url = `https://api.twilio.com/2010-04-01/Accounts/${this.accountSid}/Messages.json`;
    const auth = Buffer.from(`${this.accountSid}:${this.authToken}`).toString('base64');
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({ From: this.fromNumber, To: to, Body: message }).toString(),
    });
    if (!res.ok) {
      const text = await res.text();
      this.logger.error(`Twilio SMS failed (${res.status}) for ${to}: ${text}`);
      throw new Error(`SMS provider error: ${res.status}`);
    }
  }
}

/**
 * Production SMS provider (Unifonic — common in KSA). Wired to call the HTTP API.
 * Requires SMS_API_KEY. Network call uses the global fetch (Node >= 18).
 */
@Injectable()
export class UnifonicSmsProvider implements SmsProvider {
  private readonly logger = new Logger('SMS');
  private readonly apiKey: string;
  private readonly senderId: string;

  constructor(config: ConfigService) {
    this.apiKey = config.get<string>('SMS_API_KEY', '');
    this.senderId = config.get<string>('SMS_SENDER_ID', 'ALDIAFAH');
  }

  async send(to: string, message: string): Promise<void> {
    const res = await fetch('https://el.cloud.unifonic.com/rest/SMS/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        AppSid: this.apiKey,
        SenderID: this.senderId,
        Recipient: to.replace('+', ''),
        Body: message,
      }),
    });
    if (!res.ok) {
      this.logger.error(`Unifonic SMS failed (${res.status}) for ${to}`);
      throw new Error(`SMS provider error: ${res.status}`);
    }
  }
}
