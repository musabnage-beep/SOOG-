import { BadRequestException, Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OtpPurpose } from '@prisma/client';
import * as argon2 from 'argon2';
import { randomInt } from 'crypto';
import { PrismaService } from '@/prisma/prisma.service';
import { SMS_PROVIDER, SmsProvider } from '@/integrations/messaging/messaging.interface';
import { MAIL_PROVIDER, MailProvider } from '@/integrations/messaging/messaging.interface';

const MAX_ATTEMPTS = 5;

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    @Inject(SMS_PROVIDER) private readonly sms: SmsProvider,
    @Inject(MAIL_PROVIDER) private readonly mail: MailProvider,
  ) {}

  private generateCode(): string {
    const len = this.config.get<number>('OTP_LENGTH', 6);
    const min = 10 ** (len - 1);
    const max = 10 ** len - 1;
    return String(randomInt(min, max + 1));
  }

  /** Generates, stores (hashed) and dispatches an OTP to a phone or email. */
  async issue(target: string, purpose: OtpPurpose, userId?: string): Promise<void> {
    const ttl = this.config.get<number>('OTP_TTL_SECONDS', 300);
    const code = this.generateCode();

    // Invalidate previous unconsumed codes for this target/purpose.
    await this.prisma.otpCode.updateMany({
      where: { target, purpose, consumed: false },
      data: { consumed: true },
    });

    await this.prisma.otpCode.create({
      data: {
        userId,
        target,
        codeHash: await argon2.hash(code),
        purpose,
        expiresAt: new Date(Date.now() + ttl * 1000),
      },
    });

    const message = `ALDIAFAH verification code: ${code}`;
    if (target.includes('@')) {
      await this.mail.send({ to: target, subject: 'ALDIAFAH OTP', html: `<p>${message}</p>`, text: message });
    } else {
      await this.sms.send(target, message);
    }
  }

  /** Verifies an OTP, marking it consumed. Throws on invalid/expired/exhausted. */
  async verify(target: string, code: string, purpose: OtpPurpose): Promise<void> {
    const otp = await this.prisma.otpCode.findFirst({
      where: { target, purpose, consumed: false },
      orderBy: { createdAt: 'desc' },
    });
    if (!otp) throw new BadRequestException('No active code. Request a new one.');
    if (otp.expiresAt < new Date()) throw new BadRequestException('Code expired');
    if (otp.attempts >= MAX_ATTEMPTS) {
      await this.prisma.otpCode.update({ where: { id: otp.id }, data: { consumed: true } });
      throw new BadRequestException('Too many attempts. Request a new code.');
    }

    const valid = await argon2.verify(otp.codeHash, code);
    if (!valid) {
      await this.prisma.otpCode.update({
        where: { id: otp.id },
        data: { attempts: { increment: 1 } },
      });
      throw new BadRequestException('Invalid code');
    }

    await this.prisma.otpCode.update({ where: { id: otp.id }, data: { consumed: true } });
  }
}
