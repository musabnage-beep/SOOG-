import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import sharp from 'sharp';
import { PrismaService } from '@/prisma/prisma.service';
import { STORAGE_PROVIDER, StorageProvider } from '@/integrations/storage/storage.interface';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';

const ICON_MIME = ['image/jpeg', 'image/png', 'image/webp'];
const ICON_MAX_BYTES = 8 * 1024 * 1024;

@Injectable()
export class CategoriesService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STORAGE_PROVIDER) private readonly storage: StorageProvider,
  ) {}

  findAll(includeInactive = false) {
    return this.prisma.category.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: { _count: { select: { products: true } } },
    });
  }

  async findOne(id: string) {
    const category = await this.prisma.category.findUnique({ where: { id } });
    if (!category) throw new NotFoundException('Category not found');
    return category;
  }

  create(dto: CreateCategoryDto) {
    return this.prisma.category.create({ data: dto });
  }

  async update(id: string, dto: UpdateCategoryDto) {
    await this.findOne(id);
    return this.prisma.category.update({ where: { id }, data: dto });
  }

  async remove(id: string) {
    const category = await this.findOne(id);
    const count = await this.prisma.product.count({ where: { categoryId: id } });
    if (count > 0) {
      throw new BadRequestException('Cannot delete a category that has products');
    }
    if (category.iconKey) await this.storage.delete(category.iconKey);
    await this.prisma.category.delete({ where: { id } });
    return { ok: true };
  }

  /** Replaces the category glyph with a real photo (square WEBP thumbnail). */
  async uploadIcon(id: string, file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('No file provided');
    if (!ICON_MIME.includes(file.mimetype)) {
      throw new BadRequestException(`Unsupported type: ${file.mimetype}`);
    }
    if (file.size > ICON_MAX_BYTES) throw new BadRequestException('File too large (max 8MB)');

    const category = await this.findOne(id);
    const webp = await sharp(file.buffer)
      .resize(512, 512, { fit: 'cover' })
      .webp({ quality: 88 })
      .toBuffer();
    const stored = await this.storage.upload({
      buffer: webp,
      contentType: 'image/webp',
      key: `categories/${id}/${Date.now()}.webp`,
    });
    if (category.iconKey) await this.storage.delete(category.iconKey);

    return this.prisma.category.update({
      where: { id },
      data: { icon: stored.url, iconKey: stored.key },
    });
  }
}
