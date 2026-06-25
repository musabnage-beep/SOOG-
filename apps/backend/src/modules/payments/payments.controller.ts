import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { Public } from '@/common/decorators/public.decorator';
import { PaymentsService } from './payments.service';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly service: PaymentsService) {}

  /** Customer starts an online card payment for one of their orders. */
  @ApiBearerAuth()
  @Post('orders/:id/initiate')
  initiate(@CurrentUser('id') userId: string, @Param('id') orderId: string) {
    return this.service.initiate(userId, orderId);
  }

  /** Redirect target after the hosted payment page. Reconciles with the gateway. */
  @Public()
  @Get('callback')
  callback(@Query('order') orderId: string, @Query('id') reference?: string) {
    return this.service.confirmCallback(orderId, reference);
  }

  /** Gateway server-to-server webhook. */
  @Public()
  @Post('webhook')
  @HttpCode(200)
  webhook(@Body() body: Record<string, unknown>) {
    return this.service.handleWebhook(body);
  }
}
