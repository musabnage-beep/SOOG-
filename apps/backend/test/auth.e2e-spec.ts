/**
 * End-to-end auth lifecycle test.
 *
 * Requires a reachable PostgreSQL database (set DATABASE_URL to a disposable TEST
 * database and run migrations first):
 *
 *   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/aldiafa_test \
 *   pnpm --filter @aldiafa/backend prisma migrate deploy
 *   pnpm --filter @aldiafa/backend test:e2e
 *
 * The SMS provider is overridden with a capturing double so the real
 * register → OTP → verify → authenticated-request → refresh → logout flow can be
 * asserted without an external SMS gateway.
 */
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { OtpPurpose } from '@prisma/client';
import { AppModule } from '@/app.module';
import { AllExceptionsFilter } from '@/common/filters/http-exception.filter';
import { ResponseInterceptor } from '@/common/interceptors/response.interceptor';
import { PrismaService } from '@/prisma/prisma.service';
import { SMS_PROVIDER, SmsProvider } from '@/integrations/messaging/messaging.interface';

const captured: { code?: string } = {};
const capturingSms: SmsProvider = {
  async send(_to, message) {
    captured.code = message.match(/(\d{4,8})/)?.[1];
  },
};

describe('Auth (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const phone = '+9665' + Math.floor(10_000_000 + Math.random() * 89_999_999).toString();
  const password = 'StrongPass!1';
  let accessToken: string;
  let refreshToken: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(SMS_PROVIDER)
      .useValue(capturingSms)
      .compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new ResponseInterceptor());
    await app.init();
    prisma = app.get(PrismaService);
  });

  afterAll(async () => {
    if (prisma) {
      await prisma.user.deleteMany({ where: { phone } });
    }
    await app?.close();
  });

  it('GET /api/health is public', async () => {
    const res = await request(app.getHttpServer()).get('/api/health').expect(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBeDefined();
  });

  it('rejects a malformed register payload with 400', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ fullName: 'x', password: 'short' })
      .expect(400);
  });

  it('rejects protected routes without a token', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/fcm-token')
      .send({ token: 'abc' })
      .expect(401);
  });

  it('registers a customer and dispatches an OTP', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ fullName: 'E2E Tester', phone, password })
      .expect(201);
    expect(captured.code).toMatch(/^\d{4,8}$/);
  });

  it('verifies the OTP and returns tokens', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/auth/verify-otp')
      .send({ target: phone, code: captured.code, purpose: OtpPurpose.REGISTRATION })
      .expect(201);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();
    accessToken = res.body.data.accessToken;
    refreshToken = res.body.data.refreshToken;
  });

  it('accepts the access token on a protected route', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/fcm-token')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ token: 'device-token-123' })
      .expect(201);
  });

  it('rotates the refresh token', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken })
      .expect(201);
    expect(res.body.data.refreshToken).toBeDefined();
    expect(res.body.data.refreshToken).not.toBe(refreshToken);
    refreshToken = res.body.data.refreshToken;
  });

  it('logs in with the verified credentials', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ phone, password })
      .expect(201);
    expect(res.body.data.accessToken).toBeDefined();
  });

  it('logs out and invalidates the refresh token', async () => {
    await request(app.getHttpServer()).post('/api/auth/logout').send({ refreshToken }).expect(201);
    await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken })
      .expect(401);
  });
});
