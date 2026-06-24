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
