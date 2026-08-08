import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, StockStatus } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { paginate } from '@/common/dto/pagination.dto';
import { CreateProductDto, QueryProductsDto, UpdateProductDto } from './dto/product.dto';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: QueryProductsDto) {
    const where: Prisma.ProductWhereInput = { isActive: true };

    if (query.categoryId) where.categoryId = query.categoryId;
    if (query.categorySlug) where.category = { slug: query.categorySlug };
    if (query.inStock === 'true') where.stockStatus = { not: StockStatus.OUT_OF_STOCK };
    if (query.minPrice != null || query.maxPrice != null) {
      where.price = {};
      if (query.minPrice != null) where.price.gte = query.minPrice;
      if (query.maxPrice != null) where.price.lte = query.maxPrice;
    }
    if (query.search) {
      where.OR = [
        { nameAr: { contains: query.search, mode: 'insensitive' } },
        { nameEn: { contains: query.search, mode: 'insensitive' } },
        { sku: { contains: query.search, mode: 'insensitive' } },
        { tags: { has: query.search } },
      ];
    }

    const orderBy: Prisma.ProductOrderByWithRelationInput =
      query.sort === 'price_asc'
        ? { price: 'asc' }
        : query.sort === 'price_desc'
          ? { price: 'desc' }
          : query.sort === 'name'
            ? { nameAr: 'asc' }
            : { createdAt: 'desc' };

    const [items, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        orderBy,
        skip: query.skip,
        take: query.limit,
        include: {
          category: { select: { id: true, nameAr: true, nameEn: true, slug: true } },
          images: { orderBy: { sortOrder: 'asc' } },
        },
      }),
      this.prisma.product.count({ where }),
    ]);
    return paginate(items, total, query.page, query.limit);
  }

  async findOne(id: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: {
        category: true,
        images: { orderBy: { sortOrder: 'asc' } },
      },
    });
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  /** Carton fields only persist when the product is sold by carton, and require both values. */
  private normalizeCarton(sellByCarton?: boolean, unitsPerCarton?: number, cartonPrice?: number) {
    if (!sellByCarton) {
      return { sellByCarton: false, unitsPerCarton: null, cartonPrice: null };
    }
    if (!unitsPerCarton || unitsPerCarton < 1 || !cartonPrice || cartonPrice <= 0) {
      throw new BadRequestException('يجب إدخال عدد الحبات بالكرتون وسعر الكرتون');
    }
    return { sellByCarton: true, unitsPerCarton, cartonPrice };
  }

  async create(dto: CreateProductDto) {
    const {
      barcode,
      sku,
      nameEn,
      discountPrice,
      sellByCarton,
      unitsPerCarton,
      cartonPrice,
      halfKgPrice,
      kgPrice,
      pieceLabel,
      ...rest
    } = dto;
    // Stock is unlimited: products are always available.
    const product = await this.prisma.product.create({
      data: {
        ...rest,
        nameEn: nameEn?.trim() || rest.nameAr,
        sku: sku?.trim() || `SKU-${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.toUpperCase(),
        barcode: barcode?.trim() || null,
        discountPrice: discountPrice || null,
        // A zero/blank weight price means "not sold by weight".
        halfKgPrice: halfKgPrice || null,
        kgPrice: kgPrice || null,
        pieceLabel: pieceLabel?.trim() || null,
        ...this.normalizeCarton(sellByCarton, unitsPerCarton, cartonPrice),
        stockStatus: StockStatus.IN_STOCK,
      },
    });
    return this.findOne(product.id);
  }

  async update(id: string, dto: UpdateProductDto) {
    const existing = await this.findOne(id);
    const {
      barcode,
      discountPrice,
      sellByCarton,
      unitsPerCarton,
      cartonPrice,
      halfKgPrice,
      kgPrice,
      pieceLabel,
      ...rest
    } = dto;
    const cartonTouched =
      sellByCarton !== undefined || unitsPerCarton !== undefined || cartonPrice !== undefined;
    const carton = cartonTouched
      ? this.normalizeCarton(
          sellByCarton ?? existing.sellByCarton,
          unitsPerCarton ?? existing.unitsPerCarton ?? undefined,
          cartonPrice ?? (existing.cartonPrice != null ? Number(existing.cartonPrice) : undefined),
        )
      : {};
    await this.prisma.product.update({
      where: { id },
      data: {
        ...rest,
        ...(barcode !== undefined && { barcode: barcode.trim() || null }),
        ...(discountPrice !== undefined && { discountPrice: discountPrice || null }),
        ...(halfKgPrice !== undefined && { halfKgPrice: halfKgPrice || null }),
        ...(kgPrice !== undefined && { kgPrice: kgPrice || null }),
        ...(pieceLabel !== undefined && { pieceLabel: pieceLabel.trim() || null }),
        ...carton,
      },
    });
    return this.findOne(id);
  }

  async remove(id: string) {
    await this.findOne(id);
    // Soft-delete to preserve order history integrity.
    await this.prisma.product.update({ where: { id }, data: { isActive: false } });
    return { ok: true };
  }
}
