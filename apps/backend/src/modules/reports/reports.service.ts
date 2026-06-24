import { Injectable } from '@nestjs/common';
import { OrderStatus, ReportType, RoleName } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';

export interface ReportDataset {
  title: string;
  columns: string[];
  rows: (string | number)[][];
}

export interface ReportRange {
  from?: Date;
  to?: Date;
}

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async build(type: ReportType, range: ReportRange): Promise<ReportDataset> {
    switch (type) {
      case ReportType.SALES:
        return this.sales(range);
      case ReportType.ORDERS:
        return this.orders(range);
      case ReportType.INVENTORY:
        return this.inventory();
      case ReportType.CUSTOMERS:
        return this.customers();
      case ReportType.EMPLOYEES:
        return this.employees();
    }
  }

  private dateFilter(range: ReportRange) {
    const gte = range.from;
    const lte = range.to;
    return gte || lte ? { gte, lte } : undefined;
  }

  private async sales(range: ReportRange): Promise<ReportDataset> {
    const orders = await this.prisma.order.findMany({
      where: {
        status: { in: [OrderStatus.DELIVERED, OrderStatus.PICKED_UP] },
        deliveredAt: this.dateFilter(range),
      },
      orderBy: { deliveredAt: 'asc' },
    });
    return {
      title: 'Sales Report',
      columns: ['Order #', 'Date', 'Subtotal', 'Delivery', 'Total'],
      rows: orders.map((o) => [
        o.orderNumber,
        o.deliveredAt?.toISOString().slice(0, 10) ?? '',
        Number(o.subtotal),
        Number(o.deliveryFee),
        Number(o.total),
      ]),
    };
  }

  private async orders(range: ReportRange): Promise<ReportDataset> {
    const orders = await this.prisma.order.findMany({
      where: { createdAt: this.dateFilter(range) },
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { fullName: true } } },
    });
    return {
      title: 'Orders Report',
      columns: ['Order #', 'Customer', 'Status', 'Total', 'Created'],
      rows: orders.map((o) => [
        o.orderNumber,
        o.user.fullName,
        o.status,
        Number(o.total),
        o.createdAt.toISOString().slice(0, 10),
      ]),
    };
  }

  private async inventory(): Promise<ReportDataset> {
    const products = await this.prisma.product.findMany({
      where: { isActive: true },
      orderBy: { quantity: 'asc' },
      include: { category: { select: { nameEn: true } } },
    });
    return {
      title: 'Inventory Report',
      columns: ['SKU', 'Name', 'Category', 'Quantity', 'Status'],
      rows: products.map((p) => [p.sku, p.nameEn, p.category.nameEn, p.quantity, p.stockStatus]),
    };
  }

  private async customers(): Promise<ReportDataset> {
    const customers = await this.prisma.user.findMany({
      where: { role: { name: RoleName.CUSTOMER } },
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { orders: true } } },
    });
    return {
      title: 'Customers Report',
      columns: ['Name', 'Email', 'Phone', 'Orders', 'Joined'],
      rows: customers.map((c) => [
        c.fullName,
        c.email ?? '',
        c.phone ?? '',
        c._count.orders,
        c.createdAt.toISOString().slice(0, 10),
      ]),
    };
  }

  private async employees(): Promise<ReportDataset> {
    const employees = await this.prisma.user.findMany({
      where: { role: { name: RoleName.EMPLOYEE } },
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { reviewedOrders: true } } },
    });
    return {
      title: 'Employees Report',
      columns: ['Name', 'Email', 'Active', 'Orders Reviewed', 'Joined'],
      rows: employees.map((e) => [
        e.fullName,
        e.email ?? '',
        e.isActive ? 'Yes' : 'No',
        e._count.reviewedOrders,
        e.createdAt.toISOString().slice(0, 10),
      ]),
    };
  }
}
