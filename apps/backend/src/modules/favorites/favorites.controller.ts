import { Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '@/prisma/prisma.service';
import { CurrentUser } from '@/common/decorators/current-user.decorator';

@ApiTags('Favorites')
@ApiBearerAuth()
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async list(@CurrentUser('id') userId: string) {
    const items = await this.prisma.wishlist.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { product: { include: { images: { where: { isMain: true }, take: 1 } } } },
    });
    return items.map((w) => w.product);
  }

  @Post(':productId')
  async add(@CurrentUser('id') userId: string, @Param('productId') productId: string) {
    await this.prisma.wishlist.upsert({
      where: { userId_productId: { userId, productId } },
      update: {},
      create: { userId, productId },
    });
    return { ok: true };
  }

  @Delete(':productId')
  async remove(@CurrentUser('id') userId: string, @Param('productId') productId: string) {
    await this.prisma.wishlist.deleteMany({ where: { userId, productId } });
    return { ok: true };
  }
}
