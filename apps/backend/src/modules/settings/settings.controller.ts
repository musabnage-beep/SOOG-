import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { Public } from '@/common/decorators/public.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { SettingsService } from './settings.service';
import { UpdateSettingsDto } from './dto/settings.dto';

@ApiTags('Settings')
@Controller('settings')
export class SettingsController {
  constructor(private readonly service: SettingsService) {}

  @Public()
  @Get()
  get() {
    return this.service.get();
  }

  @ApiBearerAuth()
  @Roles(RoleName.ADMIN)
  @RequirePermissions('settings.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Put()
  update(@Body() dto: UpdateSettingsDto) {
    return this.service.update(dto);
  }
}
