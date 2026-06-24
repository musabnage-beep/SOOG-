import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import sharp from 'sharp';
import { PrismaService } from '@/prisma/prisma.service';
import { STORAGE_PROVIDER, StorageProvider } from '@/integrations/storage/storage.interface';

const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_BYTES = 8 * 1024 * 1024; // 8MB

@Injectable()
export class ProductImagesService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(STORAGE_PROVIDER) private readonly storage: StorageProvider,
  ) {}

  /** Validates, compresses to WEBP, uploads, and persists product images. */
  async upload(productId: string, files: Express.Multer.File[]) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      include: { images: true },
    });
    if (!product) throw new NotFoundException('Product not found');
    if (!files?.length) throw new BadRequestException('No files provided');

    let order = product.images.length;
    const hasMain = product.images.some((i) => i.isMain);

    const created = [];
    for (const file of files) {
      if (!ALLOWED_MIME.includes(file.mimetype)) {
        throw new BadRequestException(`Unsupported type: ${file.mimetype}`);
      }
      if (file.size > MAX_BYTES) throw new BadRequestException('File too large (max 8MB)');

      const webp = await sharp(file.buffer)
        .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
        .webp({ quality: 82 })
        .toBuffer();

      const key = `products/${productId}/${Date.now()}-${order}.webp`;
      const stored = await this.storage.upload({ buffer: webp, contentType: 'image/webp', key });

      const image = await this.prisma.productImage.create({
        data: {
          productId,
          s3Key: stored.key,
          url: stored.url,
          isMain: !hasMain && order === product.images.length,
          sortOrder: order,
        },
      });
      created.push(image);
      order++;
    }
    return created;
  }

  async remove(productId: string, imageId: string) {
    const image = await this.prisma.productImage.findFirst({ where: { id: imageId, productId } });
    if (!image) throw new NotFoundException('Image not found');
    await this.storage.delete(image.s3Key);
    await this.prisma.productImage.delete({ where: { id: imageId } });

    // Promote another image to main if the main one was removed.
    if (image.isMain) {
      const next = await this.prisma.productImage.findFirst({
        where: { productId },
        orderBy: { sortOrder: 'asc' },
      });
      if (next) {
        await this.prisma.productImage.update({ where: { id: next.id }, data: { isMain: true } });
      }
    }
    return { ok: true };
  }

  async setMain(productId: string, imageId: string) {
    const image = await this.prisma.productImage.findFirst({ where: { id: imageId, productId } });
    if (!image) throw new NotFoundException('Image not found');
    await this.prisma.$transaction([
      this.prisma.productImage.updateMany({ where: { productId }, data: { isMain: false } }),
      this.prisma.productImage.update({ where: { id: imageId }, data: { isMain: true } }),
    ]);
    return { ok: true };
  }

  /** Reorders the gallery according to the given ordered list of image ids. */
  async reorder(productId: string, orderedIds: string[]) {
    await this.prisma.$transaction(
      orderedIds.map((id, index) =>
        this.prisma.productImage.updateMany({
          where: { id, productId },
          data: { sortOrder: index },
        }),
      ),
    );
    return this.prisma.productImage.findMany({
      where: { productId },
      orderBy: { sortOrder: 'asc' },
    });
  }
}
