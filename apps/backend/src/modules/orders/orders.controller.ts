import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { CurrentUser, AuthUser } from '@/common/decorators/current-user.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { OrdersService } from './orders.service';
import {
  AdvanceStatusDto,
  CheckoutDto,
  QueryOrdersDto,
  RejectOrderDto,
  RequestConfirmationDto,
} from './dto/order.dto';

@ApiTags('Orders')
@ApiBearerAuth()
@Controller('orders')
export class OrdersController {
  constructor(private readonly service: OrdersService) {}

  // ── Customer ───────────────────────────────────────────────────────────────
  @Post('checkout')
  checkout(@CurrentUser('id') userId: string, @Body() dto: CheckoutDto) {
    return this.service.checkout(userId, dto);
  }

  @Get('mine')
  myOrders(@CurrentUser('id') userId: string, @Query() query: QueryOrdersDto) {
    return this.service.listForCustomer(userId, query);
  }

  @Get('mine/:id')
  myOrder(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.service.getForCustomer(userId, id);
  }

  @Post('mine/:id/confirm-partial')
  confirmPartial(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.service.confirmPartial(userId, id);
  }

  @Post('mine/:id/cancel')
  cancel(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.service.cancel(userId, id);
  }

  // ── Staff (employee / admin) ─────────────────────────────────────────────────
  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('order.review')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Get()
  list(@Query() query: QueryOrdersDto) {
    return this.service.listForStaff(query);
  }

  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('order.review')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Get('review-queue')
  reviewQueue() {
    return this.service.reviewQueue();
  }

  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('order.review')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Get(':id')
  detail(@Param('id') id: string) {
    return this.service.getForStaff(id);
  }

  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('order.review')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Patch(':id/review')
  startReview(@Param('id') id: string, @CurrentUser() actor: AuthUser) {
    return this.service.startReview(id, actor);
  }

  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('order.approve')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Patch(':id/approve')
  approve(@Param('id') id: string, @CurrentUser() actor: AuthUser) {
    return this.service.approve(id, actor);
  }

  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('order.reject')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Patch(':id/reject')
  reject(@Param('id') id: string, @Body() dto: RejectOrderDto, @CurrentUser() actor: AuthUser) {
    return this.service.reject(id, dto, actor);
  }

  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('order.request_confirmation')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Patch(':id/request-confirmation')
  requestConfirmation(
    @Param('id') id: string,
    @Body() dto: RequestConfirmationDto,
    @CurrentUser() actor: AuthUser,
  ) {
    return this.service.requestConfirmation(id, dto, actor);
  }

  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('order.approve')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Patch(':id/status')
  advance(@Param('id') id: string, @Body() dto: AdvanceStatusDto, @CurrentUser() actor: AuthUser) {
    return this.service.advanceStatus(id, dto, actor);
  }
}
