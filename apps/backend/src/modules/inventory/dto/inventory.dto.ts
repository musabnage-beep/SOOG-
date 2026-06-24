import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { InventoryLogType } from '@prisma/client';
import { IsEnum, IsInt, IsOptional, IsString } from 'class-validator';

export class AdjustStockDto {
  @ApiProperty({ enum: InventoryLogType, example: InventoryLogType.STOCK_IN })
  @IsEnum(InventoryLogType)
  type!: InventoryLogType;

  @ApiProperty({ description: 'Positive to add, negative to remove', example: 50 })
  @IsInt()
  quantityDelta!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  reason?: string;
}
