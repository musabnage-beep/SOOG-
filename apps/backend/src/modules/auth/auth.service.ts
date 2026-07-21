import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { OtpPurpose, RoleName } from '@prisma/client';
import * as argon2 from 'argon2';
import { PrismaService } from '@/prisma/prisma.service';
import { OtpService } from './otp.service';
import { TokensService } from './tokens.service';
import {
  ForgotPasswordDto,
  LoginDto,
  RegisterDto,
  ResetPasswordDto,
  VerifyOtpDto,
} from './dto/auth.dto';

interface RequestMeta {
  ip?: string;
  userAgent?: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otp: OtpService,
    private readonly tokens: TokensService,
  ) {}

  private async customerRoleId(): Promise<string> {
    const role = await this.prisma.role.findUniqueOrThrow({ where: { name: RoleName.CUSTOMER } });
    return role.id;
  }

  async register(dto: RegisterDto) {
    const emailExists = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (emailExists) throw new ConflictException('Email already registered');
    const phoneExists = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
    if (phoneExists) throw new ConflictException('Phone already registered');

    const user = await this.prisma.user.create({
      data: {
        fullName: dto.fullName,
        email: dto.email,
        phone: dto.phone,
        passwordHash: await argon2.hash(dto.password),
        roleId: await this.customerRoleId(),
      },
    });

    // Verification is by EMAIL only; the Saudi phone is stored but not OTP-verified.
    await this.otp.issue(dto.email, OtpPurpose.REGISTRATION, user.id);
    return { userId: user.id, target: dto.email, message: 'OTP sent for verification' };
  }

  async verifyOtp(dto: VerifyOtpDto, meta: RequestMeta) {
    await this.otp.verify(dto.target, dto.code, dto.purpose);

    const user = await this.findByTarget(dto.target);
    if (!user) throw new BadRequestException('User not found');

    if (dto.purpose === OtpPurpose.REGISTRATION || dto.purpose === OtpPurpose.LOGIN) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: dto.target.includes('@') ? { isEmailVerified: true } : { isPhoneVerified: true },
      });
      const tokens = await this.tokens.issue(user.id, user.role.name, meta);
      return { ...tokens, user: this.publicUser(user) };
    }
    return { verified: true };
  }

  async login(dto: LoginDto, meta: RequestMeta) {
    const user = await this.findByTarget(dto.email ?? dto.phone!);
    if (!user || !user.isActive) throw new UnauthorizedException('Invalid credentials');

    const valid = await argon2.verify(user.passwordHash, dto.password);
    if (!valid) throw new UnauthorizedException('Invalid credentials');

    // Enforce email verification for customers (OTP is emailed).
    if (user.role.name === RoleName.CUSTOMER && !user.isEmailVerified && user.email) {
      await this.otp.issue(user.email, OtpPurpose.LOGIN, user.id);
      throw new UnauthorizedException('Account not verified. OTP re-sent.');
    }

    await this.prisma.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date() } });
    const tokens = await this.tokens.issue(user.id, user.role.name, meta);
    return { ...tokens, user: this.publicUser(user) };
  }

  async resendOtp(target: string, purpose: OtpPurpose) {
    const user = await this.findByTarget(target);
    await this.otp.issue(target, purpose, user?.id);
    return { message: 'OTP sent', target };
  }

  async refresh(refreshToken: string, meta: RequestMeta) {
    try {
      return await this.tokens.rotate(refreshToken, meta);
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(refreshToken?: string) {
    if (refreshToken) await this.tokens.revoke(refreshToken);
    return { ok: true };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.findByTarget(dto.target);
    // Always respond OK to avoid user enumeration.
    if (user) await this.otp.issue(dto.target, OtpPurpose.PASSWORD_RESET, user.id);
    return { message: 'If the account exists, an OTP has been sent' };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.findByTarget(dto.target);
    if (!user) throw new BadRequestException('Invalid request');
    await this.otp.verify(dto.target, dto.code, OtpPurpose.PASSWORD_RESET);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: await argon2.hash(dto.newPassword) },
    });
    // Revoke all sessions on password reset.
    await this.prisma.session.updateMany({
      where: { userId: user.id, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { message: 'Password reset successful' };
  }

  async registerFcmToken(userId: string, token: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (!user.fcmTokens.includes(token)) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { fcmTokens: { push: token } },
      });
    }
    return { ok: true };
  }

  async removeFcmToken(userId: string, token: string) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmTokens: user.fcmTokens.filter((t) => t !== token) },
    });
    return { ok: true };
  }

  private async findByTarget(target: string) {
    return this.prisma.user.findFirst({
      where: target.includes('@') ? { email: target } : { phone: target },
      include: { role: true },
    });
  }

  private publicUser(user: { id: string; fullName: string; email: string | null; phone: string | null; role: { name: RoleName } }) {
    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role.name,
    };
  }
}
