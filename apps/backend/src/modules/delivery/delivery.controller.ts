import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { Public } from '@/common/decorators/public.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { DeliveryService } from './delivery.service';
import {
  DeliveryQuoteDto,
  UpsertDeliveryProviderDto,
  UpsertDeliveryZoneDto,
} from './dto/delivery.dto';

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

  // ── Third-party delivery providers ────────────────────────────────────────

  /** Active shipping companies offered to customers at checkout. */
  @Public()
  @Get('providers')
  listProviders() {
    return this.service.listProviders(true);
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('delivery.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Get('providers/all')
  listAllProviders() {
    return this.service.listProviders(false);
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('delivery.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Post('providers')
  createProvider(@Body() dto: UpsertDeliveryProviderDto) {
    return this.service.createProvider(dto);
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('delivery.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Put('providers/:id')
  updateProvider(@Param('id') id: string, @Body() dto: UpsertDeliveryProviderDto) {
    return this.service.updateProvider(id, dto);
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('delivery.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Delete('providers/:id')
  deleteProvider(@Param('id') id: string) {
    return this.service.deleteProvider(id);
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('delivery.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Post('providers/:id/logo')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } },
  })
  @UseInterceptors(FileInterceptor('file'))
  uploadProviderLogo(@Param('id') id: string, @UploadedFile() file: Express.Multer.File) {
    return this.service.uploadProviderLogo(id, file);
  }
}
