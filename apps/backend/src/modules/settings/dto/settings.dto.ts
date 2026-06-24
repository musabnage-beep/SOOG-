import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsLatitude, IsLongitude, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateSettingsDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  storeName?: string;

  @ApiPropertyOptional({ example: 24.7136 })
  @IsOptional()
  @IsLatitude()
  storeLatitude?: number;

  @ApiPropertyOptional({ example: 46.6753 })
  @IsOptional()
  @IsLongitude()
  storeLongitude?: number;

  @ApiPropertyOptional({ description: 'Free delivery radius (meters)' })
  @IsOptional()
  @IsInt()
  @Min(0)
  freeDeliveryRadiusM?: number;

  @ApiPropertyOptional({ description: 'Max delivery radius (meters)' })
  @IsOptional()
  @IsInt()
  @Min(0)
  deliveryRadiusM?: number;

  @ApiPropertyOptional({ description: 'Base delivery fee (SAR)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  baseDeliveryFee?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  currency?: string;

  @ApiPropertyOptional({ description: 'Average speed for ETA (km/h)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  avgSpeedKmh?: number;
}
