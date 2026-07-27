import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SaleUnit } from '@prisma/client';
import { IsEnum, IsInt, IsOptional, IsUUID, Min } from 'class-validator';

export class AddToCartDto {
  @ApiProperty()
  @IsUUID()
  productId!: string;

  @ApiProperty({ default: 1 })
  @IsInt()
  @Min(1)
  quantity!: number;

  @ApiPropertyOptional({ enum: SaleUnit, default: SaleUnit.PIECE })
  @IsOptional()
  @IsEnum(SaleUnit)
  unit?: SaleUnit;
}

export class UpdateCartItemDto {
  @ApiProperty({ minimum: 0, description: '0 removes the item' })
  @IsInt()
  @Min(0)
  quantity!: number;
}
