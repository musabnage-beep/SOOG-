import { ConfigModule, ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { SMS_PROVIDER } from './messaging.interface';
import { MessagingModule } from './messaging.module';
import {
  ConsoleSmsProvider,
  MsegatSmsProvider,
  TaqnyatSmsProvider,
  TwilioSmsProvider,
  UnifonicSmsProvider,
} from './sms.providers';

/**
 * Taqnyat answers 201 even when it refuses the recipient, so a naive `res.ok`
 * check would report a delivered OTP for a message nobody receives. These tests
 * pin the request shape and that rejection-inside-201 still throws.
 */
describe('TaqnyatSmsProvider', () => {
  const config = {
    get: (key: string) =>
      ({ SMS_API_KEY: 'test-token', SMS_SENDER_ID: 'ALDIAFAH' })[key] ?? '',
  } as unknown as ConfigService;

  let fetchMock: jest.Mock;

  const reply = (status: number, body: unknown) =>
    fetchMock.mockResolvedValue({
      ok: status >= 200 && status < 300,
      status,
      text: async () => JSON.stringify(body),
    });

  beforeEach(() => {
    fetchMock = jest.fn();
    global.fetch = fetchMock as unknown as typeof fetch;
  });

  it('posts a bearer-authenticated payload with a bare recipient number', async () => {
    reply(201, { accepted: [{ number: '966512345678' }], rejected: [] });

    await new TaqnyatSmsProvider(config).send('+966512345678', 'code 1234');

    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://api.taqnyat.sa/v1/messages');
    expect(init.headers.Authorization).toBe('Bearer test-token');
    expect(JSON.parse(init.body)).toEqual({
      recipients: ['966512345678'],
      body: 'code 1234',
      sender: 'ALDIAFAH',
    });
  });

  it('strips a 00 international prefix as well', async () => {
    reply(201, { accepted: [{}], rejected: [] });

    await new TaqnyatSmsProvider(config).send('00966512345678', 'hi');

    expect(JSON.parse(fetchMock.mock.calls[0][1].body).recipients).toEqual([
      '966512345678',
    ]);
  });

  it('throws when the sender name is not active', async () => {
    reply(400, { message: 'Sender Name not active' });

    await expect(
      new TaqnyatSmsProvider(config).send('+966512345678', 'hi'),
    ).rejects.toThrow('SMS provider error: 400');
  });

  it('throws when a 201 carries a rejected recipient', async () => {
    reply(201, { accepted: [], rejected: [{ number: '966512345678' }] });

    await expect(
      new TaqnyatSmsProvider(config).send('+966512345678', 'hi'),
    ).rejects.toThrow('SMS provider rejected the recipient');
  });

  it('throws when a 201 accepts nobody', async () => {
    reply(201, { accepted: [], rejected: [] });

    await expect(
      new TaqnyatSmsProvider(config).send('+966512345678', 'hi'),
    ).rejects.toThrow('SMS provider rejected the recipient');
  });
});

/**
 * An unknown SMS_PROVIDER value falls back to the console provider, so a
 * missing branch in the factory would quietly swallow every message instead of
 * failing loudly. Assert each name maps to its class.
 */
describe('MessagingModule SMS_PROVIDER factory', () => {
  const resolve = async (name: string) => {
    const moduleRef = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [() => ({ SMS_PROVIDER: name })],
        }),
        MessagingModule,
      ],
    }).compile();
    return moduleRef.get(SMS_PROVIDER);
  };

  it.each([
    ['taqnyat', TaqnyatSmsProvider],
    ['msegat', MsegatSmsProvider],
    ['twilio', TwilioSmsProvider],
    ['unifonic', UnifonicSmsProvider],
    ['console', ConsoleSmsProvider],
  ])('resolves %s', async (name, expected) => {
    expect(await resolve(name)).toBeInstanceOf(expected);
  });
});
