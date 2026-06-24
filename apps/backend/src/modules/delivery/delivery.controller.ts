import { Body, Controller, Delete, Get, Param, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { DeliveryService } from './delivery.service';
import { DeliveryQuoteDto, UpsertDeliveryZoneDto } from './dto/delivery.dto';

@ApiTags('Delivery')
@ApiBearerAuth()
@Controller('delivery')
export class DeliveryController {
  constructor(
    private readonly service: DeliveryService,
    private readonly prisma: PrismaService,
  ) {}

  @Get('quote')
  quote(@Query() dto: DeliveryQuoteDto) {
    return this.service.quote(dto.latitude, dto.longitude);
  }

  // ── Delivery zones (admin) ────────────────────────────────────────────────
  @Get('zones')
  listZones() {
    return this.prisma.deliveryZone.findMany({ orderBy: { minRadiusM: 'asc' } });
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('delivery.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Post('zones')
  createZone(@Body() dto: UpsertDeliveryZoneDto) {
    return this.prisma.deliveryZone.create({ data: dto });
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('delivery.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Put('zones/:id')
  updateZone(@Param('id') id: string, @Body() dto: UpsertDeliveryZoneDto) {
    return this.prisma.deliveryZone.update({ where: { id }, data: dto });
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('delivery.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Delete('zones/:id')
  async deleteZone(@Param('id') id: string) {
    await this.prisma.deliveryZone.delete({ where: { id } });
    return { ok: true };
  }
}
