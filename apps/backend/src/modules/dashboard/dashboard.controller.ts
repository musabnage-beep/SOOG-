import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { DashboardService } from './dashboard.service';

@ApiTags('Dashboard')
@ApiBearerAuth()
@Controller('dashboard')
@UseGuards(RolesGuard)
export class DashboardController {
  constructor(private readonly service: DashboardService) {}

  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @Get('employee')
  employee() {
    return this.service.employeeWidgets();
  }

  @Roles(RoleName.ADMIN)
  @Get('admin')
  admin() {
    return this.service.adminAnalytics();
  }

  @Roles(RoleName.ADMIN)
  @Get('admin/daily-sales')
  dailySales(@Query('days') days?: string) {
    return this.service.dailySales(days ? Number(days) : 30);
  }

  @Roles(RoleName.ADMIN)
  @Get('admin/top-products')
  topProducts(@Query('limit') limit?: string) {
    return this.service.topProducts(limit ? Number(limit) : 10);
  }
}
