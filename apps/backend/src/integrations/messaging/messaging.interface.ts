export const SMS_PROVIDER = Symbol('SMS_PROVIDER');
export const PUSH_PROVIDER = Symbol('PUSH_PROVIDER');
export const MAIL_PROVIDER = Symbol('MAIL_PROVIDER');

export interface SmsProvider {
  send(to: string, message: string): Promise<void>;
}

export interface PushMessage {
  tokens: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface PushProvider {
  send(message: PushMessage): Promise<void>;
}

export interface MailMessage {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export interface MailProvider {
  send(message: MailMessage): Promise<void>;
}
