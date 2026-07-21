import { Body, Controller, Delete, Ip, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Request } from 'express';
import { Public } from '@/common/decorators/public.decorator';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { AuthService } from './auth.service';
import {
  ForgotPasswordDto,
  LoginDto,
  LogoutDto,
  RefreshDto,
  RegisterDto,
  RegisterFcmTokenDto,
  ResendOtpDto,
  ResetPasswordDto,
  VerifyOtpDto,
} from './dto/auth.dto';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  private ua(req: Request) {
    return req.headers['user-agent'];
  }

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60 } })
  @Post('register')
  @ApiOperation({ summary: 'Register a customer and sign in immediately (no OTP)' })
  register(@Body() dto: RegisterDto, @Ip() ip: string, @Req() req: Request) {
    return this.auth.register(dto, { ip, userAgent: this.ua(req) });
  }

  @Public()
  @Throttle({ default: { limit: 15, ttl: 60 } })
  @Post('verify-otp')
  @ApiOperation({ summary: 'Verify OTP; returns tokens for registration/login purposes' })
  verifyOtp(@Body() dto: VerifyOtpDto, @Ip() ip: string, @Req() req: Request) {
    return this.auth.verifyOtp(dto, { ip, userAgent: this.ua(req) });
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60 } })
  @Post('resend-otp')
  resendOtp(@Body() dto: ResendOtpDto) {
    return this.auth.resendOtp(dto.target, dto.purpose);
  }

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60 } })
  @Post('login')
  login(@Body() dto: LoginDto, @Ip() ip: string, @Req() req: Request) {
    return this.auth.login(dto, { ip, userAgent: this.ua(req) });
  }

  @Public()
  @Throttle({ default: { limit: 30, ttl: 60 } })
  @Post('refresh')
  refresh(@Body() dto: RefreshDto, @Ip() ip: string, @Req() req: Request) {
    return this.auth.refresh(dto.refreshToken, { ip, userAgent: this.ua(req) });
  }

  @Public()
  @Post('logout')
  logout(@Body() dto: LogoutDto) {
    return this.auth.logout(dto.refreshToken);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60 } })
  @Post('forgot-password')
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.auth.forgotPassword(dto);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60 } })
  @Post('reset-password')
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.auth.resetPassword(dto);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('fcm-token')
  registerFcm(@CurrentUser('id') userId: string, @Body() dto: RegisterFcmTokenDto) {
    return this.auth.registerFcmToken(userId, dto.token);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Delete('fcm-token')
  removeFcm(@CurrentUser('id') userId: string, @Body() dto: RegisterFcmTokenDto) {
    return this.auth.removeFcmToken(userId, dto.token);
  }
}
