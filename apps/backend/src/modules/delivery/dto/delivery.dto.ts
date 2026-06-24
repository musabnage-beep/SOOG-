import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsLatitude, IsLongitude, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class DeliveryQuoteDto {
  @ApiProperty({ example: 24.7136 })
  @Type(() => Number)
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ example: 46.6753 })
  @Type(() => Number)
  @IsLongitude()
  longitude!: number;
}

export class UpsertDeliveryZoneDto {
  @ApiProperty()
  @IsString()
  name!: string;

  @ApiProperty({ description: 'Inclusive lower bound (meters)' })
  @IsInt()
  @Min(0)
  minRadiusM!: number;

  @ApiProperty({ description: 'Inclusive upper bound (meters)' })
  @IsInt()
  @Min(0)
  maxRadiusM!: number;

  @ApiProperty({ description: 'Fee (SAR)' })
  @IsNumber()
  @Min(0)
  fee!: number;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
