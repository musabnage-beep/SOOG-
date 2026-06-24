import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { InventoryService } from './inventory.service';
import { AdjustStockDto } from './dto/inventory.dto';

@ApiTags('Inventory')
@ApiBearerAuth()
@Controller('inventory')
@Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
@RequirePermissions('inventory.manage')
@UseGuards(RolesGuard, PermissionsGuard)
export class InventoryController {
  constructor(private readonly service: InventoryService) {}

  @Get('low-stock')
  lowStock() {
    return this.service.lowStock();
  }

  @Get(':productId/history')
  history(@Param('productId') productId: string) {
    return this.service.history(productId);
  }

  @Post(':productId/adjust')
  async adjust(
    @Param('productId') productId: string,
    @Body() dto: AdjustStockDto,
    @CurrentUser('id') actorId: string,
  ) {
    await this.service.adjust({ productId, actorId, ...dto });
    return { ok: true };
  }
}
