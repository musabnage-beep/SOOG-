import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { PaginationDto } from '@/common/dto/pagination.dto';
import { UsersService } from './users.service';
import {
  ChangePasswordDto,
  CreateEmployeeDto,
  UpdateProfileDto,
  UpdateUserStatusDto,
} from './dto/user.dto';

@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get('me')
  me(@CurrentUser('id') userId: string) {
    return this.service.me(userId);
  }

  @Patch('me')
  updateProfile(@CurrentUser('id') userId: string, @Body() dto: UpdateProfileDto) {
    return this.service.updateProfile(userId, dto);
  }

  @Patch('me/password')
  changePassword(@CurrentUser('id') userId: string, @Body() dto: ChangePasswordDto) {
    return this.service.changePassword(userId, dto);
  }

  // ── Admin: customers ──────────────────────────────────────────────────────
  @Roles(RoleName.ADMIN)
  @RequirePermissions('customer.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Get('customers')
  listCustomers(@Query() query: PaginationDto) {
    return this.service.list(RoleName.CUSTOMER, query);
  }

  // ── Admin: employees ──────────────────────────────────────────────────────
  @Roles(RoleName.ADMIN)
  @RequirePermissions('employee.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Get('employees')
  listEmployees(@Query() query: PaginationDto) {
    return this.service.list(RoleName.EMPLOYEE, query);
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('employee.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Post('employees')
  createEmployee(@Body() dto: CreateEmployeeDto) {
    return this.service.createEmployee(dto);
  }

  @Roles(RoleName.ADMIN)
  @RequirePermissions('employee.manage', 'customer.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Patch(':id/status')
  setStatus(@Param('id') id: string, @Body() dto: UpdateUserStatusDto) {
    return this.service.setStatus(id, dto);
  }
}
