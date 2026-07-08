import { Injectable } from '@nestjs/common';
import { OrderStatus, RoleName } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';

const ACTIVE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.SUBMITTED,
  OrderStatus.UNDER_REVIEW,
  OrderStatus.CONFIRMATION_REQUIRED,
  OrderStatus.APPROVED,
  OrderStatus.PREPARING,
  OrderStatus.READY,
  OrderStatus.OUT_FOR_DELIVERY,
];

const COMPLETED_STATUSES: OrderStatus[] = [OrderStatus.DELIVERED, OrderStatus.PICKED_UP];

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  /** Enriched widget set for the employee dashboard. */
  async employeeWidgets() {
    const since7 = new Date();
    since7.setDate(since7.getDate() - 7);

    const [
      pending,
      underReview,
      lowStock,
      totalOrders,
      preparing,
      delivered,
      revenueAgg,
      statusGroups,
      dailyOrdersRaw,
      recent,
    ] = await Promise.all([
      this.prisma.order.count({ where: { status: OrderStatus.SUBMITTED } }),
      this.prisma.order.count({ where: { status: OrderStatus.UNDER_REVIEW } }),
      this.prisma.product.count({
        where: { isActive: true, stockStatus: { in: ['LOW_STOCK', 'OUT_OF_STOCK'] } },
      }),
      this.prisma.order.count(),
      this.prisma.order.count({
        where: { status: { in: [OrderStatus.PREPARING, OrderStatus.READY] } },
      }),
      this.prisma.order.count({ where: { status: { in: COMPLETED_STATUSES } } }),
      this.prisma.order.aggregate({
        _sum: { total: true },
        where: { status: { in: COMPLETED_STATUSES } },
      }),
      this.prisma.order.groupBy({ by: ['status'], _count: { _all: true } }),
      this.prisma.$queryRaw<{ day: Date; orders: bigint }[]>`
        SELECT date_trunc('day', "submittedAt") AS day, COUNT(*) AS orders
        FROM "Order"
        WHERE "submittedAt" >= ${since7}
        GROUP BY day
        ORDER BY day ASC
      `,
      this.prisma.order.findMany({
        where: { status: { in: ACTIVE_ORDER_STATUSES } },
        orderBy: { submittedAt: 'desc' },
        take: 10,
        include: { user: { select: { fullName: true } }, _count: { select: { items: true } } },
      }),
    ]);

    return {
      pending,
      underReview,
      lowStock,
      totalOrders,
      preparing,
      delivered,
      totalRevenue: Number(revenueAgg._sum.total ?? 0),
      ordersByStatus: Object.fromEntries(statusGroups.map((g) => [g.status, g._count._all])),
      dailyOrders: dailyOrdersRaw.map((r) => ({ day: r.day, orders: Number(r.orders) })),
      recent,
    };
  }

  /** Full analytics for the admin dashboard. */
  async adminAnalytics() {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const [
      revenueAgg,
      monthRevenueAgg,
      orderCount,
      customerCount,
      employeeCount,
      productCount,
      statusGroups,
    ] = await Promise.all([
      this.prisma.order.aggregate({
        _sum: { total: true },
        where: { status: { in: COMPLETED_STATUSES } },
      }),
      this.prisma.order.aggregate({
        _sum: { total: true },
        where: { status: { in: COMPLETED_STATUSES }, deliveredAt: { gte: startOfMonth } },
      }),
      this.prisma.order.count(),
      this.prisma.user.count({ where: { role: { name: RoleName.CUSTOMER } } }),
      this.prisma.user.count({ where: { role: { name: RoleName.EMPLOYEE } } }),
      this.prisma.product.count({ where: { isActive: true } }),
      this.prisma.order.groupBy({ by: ['status'], _count: { _all: true } }),
    ]);

    return {
      totalRevenue: Number(revenueAgg._sum.total ?? 0),
      monthRevenue: Number(monthRevenueAgg._sum.total ?? 0),
      orders: orderCount,
      customers: customerCount,
      employees: employeeCount,
      products: productCount,
      ordersByStatus: Object.fromEntries(statusGroups.map((g) => [g.status, g._count._all])),
    };
  }

  /** Daily sales for the last N days (for charts). */
  async dailySales(days = 30) {
    const since = new Date();
    since.setDate(since.getDate() - days);
    const rows = await this.prisma.$queryRaw<{ day: Date; revenue: number; orders: bigint }[]>`
      SELECT date_trunc('day', "deliveredAt") AS day,
             SUM("total")::float AS revenue,
             COUNT(*) AS orders
      FROM "Order"
      WHERE "status" IN ('DELIVERED', 'PICKED_UP') AND "deliveredAt" >= ${since}
      GROUP BY day
      ORDER BY day ASC;
    `;
    return rows.map((r) => ({
      day: r.day,
      revenue: Number(r.revenue ?? 0),
      orders: Number(r.orders),
    }));
  }

  /** Top selling products with main image URL. */
  async topProducts(limit = 10) {
    const grouped = await this.prisma.orderItem.groupBy({
      by: ['productId', 'nameAr', 'nameEn'],
      _sum: { quantity: true, lineTotal: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: limit,
    });

    const productIds = grouped.map((g) => g.productId);
    const images = await this.prisma.productImage.findMany({
      where: { productId: { in: productIds }, isMain: true },
      select: { productId: true, url: true },
    });
    const imageMap = new Map(images.map((i) => [i.productId, i.url]));

    return grouped.map((g) => ({
      productId: g.productId,
      nameAr: g.nameAr,
      nameEn: g.nameEn,
      unitsSold: g._sum.quantity ?? 0,
      revenue: Number(g._sum.lineTotal ?? 0),
      imageUrl: imageMap.get(g.productId) ?? null,
    }));
  }
}
