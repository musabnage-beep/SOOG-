import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';

describe('PaymentsController (callback routing)', () => {
  let app: INestApplication;
  let confirmCallback: jest.Mock;

  beforeEach(async () => {
    confirmCallback = jest.fn().mockResolvedValue({
      orderId: 'o1',
      orderNumber: 'ALD-2026-000021',
      paymentStatus: 'PAID',
    });

    const moduleRef = await Test.createTestingModule({
      controllers: [PaymentsController],
      providers: [{ provide: PaymentsService, useValue: { confirmCallback } }],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  // The gateway POSTs to the callback URL; accepting only GET returned 404 and
  // left paid orders stuck as PENDING.
  it.each(['get', 'post'] as const)('reconciles the order on %s', async (method) => {
    const res = await request(app.getHttpServer())[method]('/payments/callback?order=o1');

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('text/html');
    expect(confirmCallback).toHaveBeenCalledWith('o1');
  });
});
