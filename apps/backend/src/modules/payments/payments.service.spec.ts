import { Test } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PaymentMethod, PaymentStatus } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { NotificationsService } from '@/modules/notifications/notifications.service';
import { PAYMENT_PROVIDER } from '@/integrations/payment/payment.interface';
import { PaymentsService } from './payments.service';

describe('PaymentsService', () => {
  let service: PaymentsService;
  let orderFindFirst: jest.Mock;
  let orderFindUnique: jest.Mock;
  let orderUpdate: jest.Mock;
  let notify: jest.Mock;
  let createPayment: jest.Mock;
  let getPayment: jest.Mock;
  let getCharge: jest.Mock;
  let verifyWebhook: jest.Mock;

  const order = (over: Partial<Record<string, unknown>> = {}) => ({
    id: 'o1',
    orderNumber: 'ALD-2026-000001',
    userId: 'u1',
    status: 'SUBMITTED',
    total: '150.00',
    paymentMethod: PaymentMethod.CARD,
    paymentStatus: PaymentStatus.PENDING,
    paymentRef: null,
    ...over,
  });

  beforeEach(async () => {
    orderFindFirst = jest.fn();
    orderFindUnique = jest.fn();
    orderUpdate = jest.fn().mockResolvedValue(undefined);
    notify = jest.fn().mockResolvedValue(undefined);
    createPayment = jest.fn();
    getPayment = jest.fn();
    getCharge = jest.fn();
    verifyWebhook = jest.fn().mockReturnValue(true);

    const moduleRef = await Test.createTestingModule({
      providers: [
        PaymentsService,
        {
          provide: PrismaService,
          useValue: {
            order: { findFirst: orderFindFirst, findUnique: orderFindUnique, update: orderUpdate },
          },
        },
        { provide: NotificationsService, useValue: { notify } },
        {
          provide: ConfigService,
          useValue: { get: () => 'http://localhost:3000/api/payments/callback' },
        },
        {
          provide: PAYMENT_PROVIDER,
          useValue: {
            publishableKey: 'pk_test_1',
            createPayment,
            getPayment,
            getCharge,
            verifyWebhook,
          },
        },
      ],
    }).compile();
    service = moduleRef.get(PaymentsService);
  });

  it('initiates a card payment and stores the gateway reference', async () => {
    orderFindFirst.mockResolvedValue(order());
    createPayment.mockResolvedValue({ reference: 'inv_1', redirectUrl: 'https://pay/inv_1' });

    const res = await service.initiate('u1', 'o1');

    expect(res).toEqual({ reference: 'inv_1', redirectUrl: 'https://pay/inv_1' });
    expect(orderUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ paymentRef: 'inv_1' }) }),
    );
  });

  it('rejects initiating payment for a COD order', async () => {
    orderFindFirst.mockResolvedValue(order({ paymentMethod: PaymentMethod.COD }));
    await expect(service.initiate('u1', 'o1')).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects initiating payment for an already-paid order', async () => {
    orderFindFirst.mockResolvedValue(order({ paymentStatus: PaymentStatus.PAID }));
    await expect(service.initiate('u1', 'o1')).rejects.toBeInstanceOf(BadRequestException);
  });

  it('marks the order paid and notifies the customer when the gateway confirms', async () => {
    orderFindFirst.mockResolvedValue(order({ paymentRef: 'inv_1' }));
    getPayment.mockResolvedValue({ reference: 'inv_1', status: 'paid', amount: 150 });

    await service.handleWebhook({ secret_token: 's', data: { id: 'inv_1', status: 'paid' } });

    expect(orderUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ paymentStatus: PaymentStatus.PAID }) }),
    );
    expect(notify).toHaveBeenCalled();
  });

  it('matches a payment event by its invoice id, not the payment id', async () => {
    orderFindFirst.mockResolvedValue(order({ paymentRef: 'inv_1' }));

    await service.handleWebhook({
      secret_token: 's',
      data: { id: 'pay_9', invoice_id: 'inv_1', status: 'paid' },
    });

    expect(orderFindFirst).toHaveBeenCalledWith({
      where: { paymentRef: { in: ['inv_1', 'pay_9'] } },
    });
    expect(orderUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ paymentStatus: PaymentStatus.PAID, paymentRef: 'inv_1' }),
      }),
    );
  });

  it('hands the app the publishable key and the amount in halalas', async () => {
    orderFindFirst.mockResolvedValue(order());

    await expect(service.session('u1', 'o1')).resolves.toEqual(
      expect.objectContaining({ publishableKey: 'pk_test_1', amount: 15000, currency: 'SAR' }),
    );
  });

  it('confirms an in-app charge after re-reading it from the gateway', async () => {
    orderFindFirst
      .mockResolvedValueOnce(order())
      .mockResolvedValueOnce(order())
      .mockResolvedValueOnce(null);
    getCharge.mockResolvedValue({
      reference: 'pay_9',
      status: 'paid',
      amount: 150,
      currency: 'SAR',
    });
    orderFindUnique.mockResolvedValue(order({ paymentStatus: PaymentStatus.PAID }));

    const res = await service.confirmCharge('u1', 'o1', 'pay_9');

    expect(res.paymentStatus).toBe(PaymentStatus.PAID);
    expect(orderUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ paymentStatus: PaymentStatus.PAID, paymentRef: 'pay_9' }),
      }),
    );
  });

  // A cheap charge must never settle an expensive order.
  it('rejects an in-app charge whose amount does not match the order', async () => {
    orderFindFirst
      .mockResolvedValueOnce(order())
      .mockResolvedValueOnce(order())
      .mockResolvedValueOnce(null);
    getCharge.mockResolvedValue({ reference: 'pay_9', status: 'paid', amount: 1, currency: 'SAR' });

    await expect(service.confirmCharge('u1', 'o1', 'pay_9')).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(orderUpdate).not.toHaveBeenCalled();
  });

  it('treats an already-paid order as a successful confirmation', async () => {
    orderFindFirst.mockResolvedValue(order({ paymentStatus: PaymentStatus.PAID }));

    await expect(service.confirmCharge('u1', 'o1', 'pay_9')).resolves.toEqual(
      expect.objectContaining({ paymentStatus: PaymentStatus.PAID }),
    );
    expect(getCharge).not.toHaveBeenCalled();
  });

  // In-app charges have no invoice, so metadata is the only link back to the order.
  it('falls back to the order id in the charge metadata', async () => {
    orderFindFirst.mockResolvedValue(null);
    orderFindUnique.mockResolvedValue(order());

    await service.handleWebhook({
      secret_token: 's',
      data: { id: 'pay_9', status: 'paid', amount: 15000, metadata: { order_id: 'o1' } },
    });

    expect(orderUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ paymentStatus: PaymentStatus.PAID, paymentRef: 'pay_9' }),
      }),
    );
  });

  it('ignores a metadata match when the charged amount is wrong', async () => {
    orderFindFirst.mockResolvedValue(null);
    orderFindUnique.mockResolvedValue(order());

    await service.handleWebhook({
      secret_token: 's',
      data: { id: 'pay_9', status: 'paid', amount: 100, metadata: { order_id: 'o1' } },
    });

    expect(orderUpdate).not.toHaveBeenCalled();
  });

  it('rejects a webhook with an invalid signature', async () => {
    verifyWebhook.mockReturnValue(false);
    await expect(
      service.handleWebhook({ data: { id: 'inv_1', status: 'paid' } }),
    ).rejects.toThrow();
  });
});
