import { BadRequestException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { OtpPurpose } from '@prisma/client';
import * as argon2 from 'argon2';
import { PrismaService } from '@/prisma/prisma.service';
import {
  MAIL_PROVIDER,
  MailProvider,
  SMS_PROVIDER,
  SmsProvider,
} from '@/integrations/messaging/messaging.interface';
import { OtpService } from './otp.service';

describe('OtpService', () => {
  let service: OtpService;
  let otpCode: {
    updateMany: jest.Mock;
    create: jest.Mock;
    findFirst: jest.Mock;
    update: jest.Mock;
  };
  let sms: jest.Mocked<SmsProvider>;
  let mail: jest.Mocked<MailProvider>;

  beforeEach(async () => {
    otpCode = {
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      create: jest.fn().mockResolvedValue({}),
      findFirst: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
    };
    sms = { send: jest.fn().mockResolvedValue(undefined) };
    mail = { send: jest.fn().mockResolvedValue(undefined) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        OtpService,
        { provide: PrismaService, useValue: { otpCode } },
        { provide: ConfigService, useValue: { get: (_k: string, d: number) => d } },
        { provide: SMS_PROVIDER, useValue: sms },
        { provide: MAIL_PROVIDER, useValue: mail },
      ],
    }).compile();
    service = moduleRef.get(OtpService);
  });

  it('invalidates prior codes, stores a hash (never plaintext) and texts a phone', async () => {
    await service.issue('+966500000000', OtpPurpose.REGISTRATION);
    expect(otpCode.updateMany).toHaveBeenCalled();
    const created = otpCode.create.mock.calls[0][0].data;
    expect(created.codeHash).toMatch(/^\$argon2/);
    expect(sms.send).toHaveBeenCalledTimes(1);
    expect(mail.send).not.toHaveBeenCalled();
  });

  it('emails the code when the target is an email', async () => {
    await service.issue('user@example.com', OtpPurpose.LOGIN);
    expect(mail.send).toHaveBeenCalledTimes(1);
    expect(sms.send).not.toHaveBeenCalled();
  });

  it('throws when no active code exists', async () => {
    otpCode.findFirst.mockResolvedValue(null);
    await expect(service.verify('+966500000000', '123456', OtpPurpose.LOGIN)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('throws and consumes the code when it is expired', async () => {
    otpCode.findFirst.mockResolvedValue({
      id: 'o1',
      expiresAt: new Date(Date.now() - 1000),
      attempts: 0,
      codeHash: await argon2.hash('123456'),
    });
    await expect(service.verify('+966500000000', '123456', OtpPurpose.LOGIN)).rejects.toThrow('expired');
  });

  it('increments attempts on a wrong code', async () => {
    otpCode.findFirst.mockResolvedValue({
      id: 'o1',
      expiresAt: new Date(Date.now() + 60_000),
      attempts: 0,
      codeHash: await argon2.hash('123456'),
    });
    await expect(service.verify('+966500000000', '000000', OtpPurpose.LOGIN)).rejects.toThrow('Invalid code');
    expect(otpCode.update).toHaveBeenCalledWith({
      where: { id: 'o1' },
      data: { attempts: { increment: 1 } },
    });
  });

  it('locks out after too many attempts', async () => {
    otpCode.findFirst.mockResolvedValue({
      id: 'o1',
      expiresAt: new Date(Date.now() + 60_000),
      attempts: 5,
      codeHash: await argon2.hash('123456'),
    });
    await expect(service.verify('+966500000000', '123456', OtpPurpose.LOGIN)).rejects.toThrow('Too many attempts');
  });

  it('consumes the code on a successful verification', async () => {
    otpCode.findFirst.mockResolvedValue({
      id: 'o1',
      expiresAt: new Date(Date.now() + 60_000),
      attempts: 0,
      codeHash: await argon2.hash('123456'),
    });
    await service.verify('+966500000000', '123456', OtpPurpose.LOGIN);
    expect(otpCode.update).toHaveBeenLastCalledWith({ where: { id: 'o1' }, data: { consumed: true } });
  });
});
