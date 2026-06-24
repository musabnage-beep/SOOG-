import { Test } from '@nestjs/testing';
import { InventoryLogType, StockStatus } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { NotificationsService } from '@/modules/notifications/notifications.service';
import { InventoryService } from './inventory.service';

describe('InventoryService.adjust', () => {
  let service: InventoryService;
  let productFindUniqueOrThrow: jest.Mock;
  let productUpdate: jest.Mock;
  let inventoryLogCreate: jest.Mock;
  let userFindMany: jest.Mock;
  let notify: jest.Mock;

  const product = (over: Partial<Record<string, unknown>> = {}) => ({
    id: 'p1',
    nameAr: 'تمر',
    quantity: 10,
    lowStockThreshold: 3,
    stockStatus: StockStatus.IN_STOCK,
    ...over,
  });

  beforeEach(async () => {
    productFindUniqueOrThrow = jest.fn();
    productUpdate = jest.fn();
    inventoryLogCreate = jest.fn();
    userFindMany = jest.fn().mockResolvedValue([{ id: 'staff1' }]);
    notify = jest.fn().mockResolvedValue(undefined);

    const moduleRef = await Test.createTestingModule({
      providers: [
        InventoryService,
        {
          provide: PrismaService,
          useValue: {
            product: { findUniqueOrThrow: productFindUniqueOrThrow, update: productUpdate },
            inventoryLog: { create: inventoryLogCreate },
            user: { findMany: userFindMany },
          },
        },
        { provide: NotificationsService, useValue: { notify } },
      ],
    }).compile();
    service = moduleRef.get(InventoryService);
  });

  it('adds stock, recomputes IN_STOCK status and logs the delta', async () => {
    productFindUniqueOrThrow.mockResolvedValue(product({ quantity: 5 }));
    await service.adjust({ productId: 'p1', type: InventoryLogType.STOCK_IN, quantityDelta: 10 });

    expect(productUpdate).toHaveBeenCalledWith({
      where: { id: 'p1' },
      data: { quantity: 15, stockStatus: StockStatus.IN_STOCK },
    });
    expect(inventoryLogCreate).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ quantityBefore: 5, quantityAfter: 15 }) }),
    );
  });

  it('never lets quantity drop below zero', async () => {
    productFindUniqueOrThrow.mockResolvedValue(product({ quantity: 2 }));
    await service.adjust({ productId: 'p1', type: InventoryLogType.SOLD, quantityDelta: -5 });
    expect(productUpdate).toHaveBeenCalledWith({
      where: { id: 'p1' },
      data: { quantity: 0, stockStatus: StockStatus.OUT_OF_STOCK },
    });
  });

  it('alerts staff when crossing into LOW_STOCK', async () => {
    productFindUniqueOrThrow.mockResolvedValue(product({ quantity: 5, stockStatus: StockStatus.IN_STOCK }));
    await service.adjust({ productId: 'p1', type: InventoryLogType.SOLD, quantityDelta: -3 });
    expect(notify).toHaveBeenCalledTimes(1);
    expect(notify).toHaveBeenCalledWith(expect.objectContaining({ userId: 'staff1', title: 'Low stock' }));
  });

  it('alerts staff when crossing into OUT_OF_STOCK', async () => {
    productFindUniqueOrThrow.mockResolvedValue(product({ quantity: 1, stockStatus: StockStatus.LOW_STOCK }));
    await service.adjust({ productId: 'p1', type: InventoryLogType.SOLD, quantityDelta: -1 });
    expect(notify).toHaveBeenCalledWith(expect.objectContaining({ title: 'Out of stock' }));
  });

  it('does not alert when status is unchanged', async () => {
    productFindUniqueOrThrow.mockResolvedValue(product({ quantity: 20, stockStatus: StockStatus.IN_STOCK }));
    await service.adjust({ productId: 'p1', type: InventoryLogType.STOCK_IN, quantityDelta: 5 });
    expect(notify).not.toHaveBeenCalled();
  });

  it('suppresses alerts when running inside a transaction', async () => {
    const txProduct = { findUniqueOrThrow: jest.fn().mockResolvedValue(product({ quantity: 1 })), update: jest.fn() };
    const tx = { product: txProduct, inventoryLog: { create: jest.fn() } } as never;
    await service.adjust({ productId: 'p1', type: InventoryLogType.SOLD, quantityDelta: -1 }, tx);
    expect(notify).not.toHaveBeenCalled();
    expect(productUpdate).not.toHaveBeenCalled();
    expect(txProduct.update).toHaveBeenCalled();
  });
});
