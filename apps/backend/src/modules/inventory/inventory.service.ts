import { Injectable } from '@nestjs/common';
import { InventoryLogType, NotificationType, Prisma, RoleName, StockStatus } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { NotificationsService } from '@/modules/notifications/notifications.service';

export interface StockAdjustment {
  productId: string;
  type: InventoryLogType;
  /** Positive to add stock, negative to remove. */
  quantityDelta: number;
  reason?: string;
  actorId?: string;
}

@Injectable()
export class InventoryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  private statusFor(quantity: number, threshold: number): StockStatus {
    if (quantity <= 0) return StockStatus.OUT_OF_STOCK;
    if (quantity <= threshold) return StockStatus.LOW_STOCK;
    return StockStatus.IN_STOCK;
  }

  /**
   * Adjusts product stock atomically, writes an inventory log, recomputes stock status
   * and fires low/out-of-stock alerts to staff. Runs inside an optional transaction client.
   */
  async adjust(adj: StockAdjustment, tx?: Prisma.TransactionClient): Promise<void> {
    const client = tx ?? this.prisma;
    const product = await client.product.findUniqueOrThrow({ where: { id: adj.productId } });
    const before = product.quantity;
    const after = Math.max(0, before + adj.quantityDelta);
    const status = this.statusFor(after, product.lowStockThreshold);

    await client.product.update({
      where: { id: adj.productId },
      data: { quantity: after, stockStatus: status },
    });
    await client.inventoryLog.create({
      data: {
        productId: adj.productId,
        type: adj.type,
        quantityDelta: adj.quantityDelta,
        quantityBefore: before,
        quantityAfter: after,
        reason: adj.reason,
        actorId: adj.actorId,
      },
    });

    // Fire alerts only on threshold crossings (avoid spamming). Skip during tx to keep it short.
    if (!tx && status !== product.stockStatus && status !== StockStatus.IN_STOCK) {
      await this.alertStaff(product.nameAr, after, status);
    }
  }

  private async alertStaff(productName: string, qty: number, status: StockStatus): Promise<void> {
    const staff = await this.prisma.user.findMany({
      where: { role: { name: { in: [RoleName.ADMIN, RoleName.EMPLOYEE] } }, isActive: true },
      select: { id: true },
    });
    const isOut = status === StockStatus.OUT_OF_STOCK;
    await Promise.all(
      staff.map((s) =>
        this.notifications.notify({
          userId: s.id,
          type: isOut ? NotificationType.OUT_OF_STOCK : NotificationType.LOW_STOCK,
          title: isOut ? 'Out of stock' : 'Low stock',
          body: `${productName} — ${qty} remaining`,
          push: false,
        }),
      ),
    );
  }

  history(productId: string) {
    return this.prisma.inventoryLog.findMany({
      where: { productId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  lowStock() {
    return this.prisma.product.findMany({
      where: { isActive: true, stockStatus: { in: [StockStatus.LOW_STOCK, StockStatus.OUT_OF_STOCK] } },
      orderBy: { quantity: 'asc' },
      include: { category: { select: { nameAr: true, nameEn: true } } },
    });
  }
}
