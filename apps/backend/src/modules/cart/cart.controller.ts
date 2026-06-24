import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { CartService } from './cart.service';
import { AddToCartDto, UpdateCartItemDto } from './dto/cart.dto';

@ApiTags('Cart')
@ApiBearerAuth()
@Controller('cart')
export class CartController {
  constructor(private readonly service: CartService) {}

  @Get()
  get(@CurrentUser('id') userId: string) {
    return this.service.getCart(userId);
  }

  @Post('items')
  add(@CurrentUser('id') userId: string, @Body() dto: AddToCartDto) {
    return this.service.add(userId, dto.productId, dto.quantity);
  }

  @Patch('items/:itemId')
  update(
    @CurrentUser('id') userId: string,
    @Param('itemId') itemId: string,
    @Body() dto: UpdateCartItemDto,
  ) {
    return this.service.update(userId, itemId, dto.quantity);
  }

  @Delete('items/:itemId')
  remove(@CurrentUser('id') userId: string, @Param('itemId') itemId: string) {
    return this.service.remove(userId, itemId);
  }

  @Delete()
  clear(@CurrentUser('id') userId: string) {
    return this.service.clear(userId);
  }
}
