import { Body, Controller, Get, HttpCode, Logger, Param, Post, Query, Res } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { Public } from '@/common/decorators/public.decorator';
import { renderPaymentResult } from './payment-result.page';
import { PaymentsService } from './payments.service';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger('PAYMENT');

  constructor(private readonly service: PaymentsService) {}

  /** Customer starts an online card payment for one of their orders. */
  @ApiBearerAuth()
  @Post('orders/:id/initiate')
  initiate(@CurrentUser('id') userId: string, @Param('id') orderId: string) {
    return this.service.initiate(userId, orderId);
  }

  /**
   * Redirect target after the hosted payment page. Reconciles with the gateway
   * and answers with an HTML page — a real customer reads this in their browser,
   * so it must never be the JSON envelope. `@Res()` bypasses the global response
   * interceptor, which means failures have to be rendered here too rather than
   * bubbling up to the JSON exception filter.
   */
  @Public()
  @Get('callback')
  callbackFromRedirect(@Res() res: Response, @Query('order') orderId: string) {
    return this.callback(res, orderId);
  }

  /** Same reconciliation, but for the gateway's server-side POST. */
  @Public()
  @Post('callback')
  callbackFromGateway(@Res() res: Response, @Query('order') orderId: string) {
    return this.callback(res, orderId);
  }

  private async callback(res: Response, orderId: string) {
    try {
      const result = await this.service.confirmCallback(orderId);
      const outcome =
        result.paymentStatus === 'PAID'
          ? 'paid'
          : result.paymentStatus === 'FAILED'
            ? 'failed'
            : 'pending';
      this.sendPage(res, outcome, result.orderNumber);
    } catch (error) {
      this.logger.error(`Payment callback failed for order ${orderId}: ${String(error)}`);
      this.sendPage(res, 'error');
    }
  }

  private sendPage(
    res: Response,
    outcome: 'paid' | 'failed' | 'pending' | 'error',
    orderNumber?: string,
  ) {
    res
      .status(200)
      .type('html')
      .send(renderPaymentResult(outcome, orderNumber));
  }

  /** Gateway server-to-server webhook. */
  @Public()
  @Post('webhook')
  @HttpCode(200)
  webhook(@Body() body: Record<string, unknown>) {
    return this.service.handleWebhook(body);
  }
}
