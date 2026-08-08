import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { SaleUnit, StockStatus } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { unitLabelOf, unitPriceOf } from '@/common/sale-unit';

@Injectable()
export class CartService {
  constructor(private readonly prisma: PrismaService) {}

  /** Returns the user's cart with line totals and a computed subtotal. */
  async getCart(userId: string) {
    const items = await this.prisma.cartItem.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      include: {
        product: {
          include: { images: { where: { isMain: true }, take: 1 } },
        },
      },
    });

    const lines = items.map((item) => {
      // Fall back to the piece price if the unit was retired after the line was
      // added, so an old cart line still renders instead of blowing up.
      const unitPrice =
        unitPriceOf(item.product, item.unit) ?? unitPriceOf(item.product, SaleUnit.PIECE)!;
      return {
        id: item.id,
        productId: item.productId,
        nameAr: item.product.nameAr,
        nameEn: item.product.nameEn,
        image: item.product.images[0]?.url ?? null,
        unitPrice,
        quantity: item.quantity,
        unit: item.unit,
        unitLabel: unitLabelOf(item.product, item.unit),
        unitsPerCarton: item.unit === SaleUnit.CARTON ? item.product.unitsPerCarton : null,
        lineTotal: +(unitPrice * item.quantity).toFixed(2),
        stockStatus: item.product.stockStatus,
      };
    });
    const subtotal = +lines.reduce((sum, l) => sum + l.lineTotal, 0).toFixed(2);
    return { items: lines, subtotal, itemCount: lines.length };
  }

  async add(userId: string, productId: string, quantity: number, unit: SaleUnit = SaleUnit.PIECE) {
    const product = await this.prisma.product.findUnique({ where: { id: productId } });
    if (!product || !product.isActive) throw new NotFoundException('Product not found');
    if (product.stockStatus === StockStatus.OUT_OF_STOCK) {
      throw new BadRequestException('Product is out of stock');
    }
    if (unitPriceOf(product, unit) == null) {
      throw new BadRequestException(`هذا المنتج لا يُباع بوحدة «${unitLabelOf(product, unit)}»`);
    }
    await this.prisma.cartItem.upsert({
      where: { userId_productId_unit: { userId, productId, unit } },
      update: { quantity: { increment: quantity } },
      create: { userId, productId, quantity, unit },
    });
    return this.getCart(userId);
  }

  async update(userId: string, itemId: string, quantity: number) {
    const item = await this.prisma.cartItem.findFirst({ where: { id: itemId, userId } });
    if (!item) throw new NotFoundException('Cart item not found');
    if (quantity === 0) {
      await this.prisma.cartItem.delete({ where: { id: itemId } });
    } else {
      await this.prisma.cartItem.update({ where: { id: itemId }, data: { quantity } });
    }
    return this.getCart(userId);
  }

  async remove(userId: string, itemId: string) {
    await this.prisma.cartItem.deleteMany({ where: { id: itemId, userId } });
    return this.getCart(userId);
  }

  async clear(userId: string) {
    await this.prisma.cartItem.deleteMany({ where: { userId } });
    return this.getCart(userId);
  }
}
