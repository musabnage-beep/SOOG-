import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { OtpPurpose } from '@prisma/client';
import {
  IsEmail,
  IsEnum,
  IsOptional,
  IsPhoneNumber,
  IsString,
  Length,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'Mohammed Ali' })
  @IsString()
  @MinLength(2)
  fullName!: string;

  // Email is required and is the verification channel (OTP is emailed).
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email!: string;

  // A valid Saudi mobile number is required (but not OTP-verified).
  @ApiProperty({ example: '+966500000001' })
  @IsPhoneNumber('SA')
  phone!: string;

  @ApiProperty({ example: 'StrongPass!1', minLength: 8 })
  @IsString()
  @MinLength(8)
  password!: string;
}

export class LoginDto {
  @ApiPropertyOptional({ example: 'user@example.com' })
  @ValidateIf((o) => !o.phone)
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: '+966500000001' })
  @ValidateIf((o) => !o.email)
  @IsPhoneNumber('SA')
  phone?: string;

  @ApiProperty({ example: 'StrongPass!1' })
  @IsString()
  password!: string;
}

export class VerifyOtpDto {
  @ApiProperty({ description: 'Email or phone the OTP was sent to' })
  @IsString()
  target!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @Length(4, 8)
  code!: string;

  @ApiProperty({ enum: OtpPurpose })
  @IsEnum(OtpPurpose)
  purpose!: OtpPurpose;
}

export class ResendOtpDto {
  @ApiProperty({ description: 'Email or phone' })
  @IsString()
  target!: string;

  @ApiProperty({ enum: OtpPurpose })
  @IsEnum(OtpPurpose)
  purpose!: OtpPurpose;
}

export class RefreshDto {
  @ApiProperty()
  @IsString()
  refreshToken!: string;
}

export class ForgotPasswordDto {
  @ApiProperty({ description: 'Email or phone' })
  @IsString()
  target!: string;
}

export class ResetPasswordDto {
  @ApiProperty({ description: 'Email or phone' })
  @IsString()
  target!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  code!: string;

  @ApiProperty({ minLength: 8 })
  @IsString()
  @MinLength(8)
  newPassword!: string;
}

export class RegisterFcmTokenDto {
  @ApiProperty()
  @IsString()
  token!: string;
}

export class LogoutDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  refreshToken?: string;
}
