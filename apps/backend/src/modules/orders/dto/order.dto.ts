import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FulfillmentType, OrderStatus } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { PaginationDto } from '@/common/dto/pagination.dto';

export class CheckoutDto {
  @ApiProperty({ enum: FulfillmentType })
  @IsEnum(FulfillmentType)
  fulfillmentType!: FulfillmentType;

  @ApiPropertyOptional({ description: 'Required when fulfillmentType is DELIVERY' })
  @ValidateIf((o) => o.fulfillmentType === FulfillmentType.DELIVERY)
  @IsUUID()
  addressId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  customerNote?: string;
}

export class RejectOrderDto {
  @ApiProperty()
  @IsString()
  reason!: string;
}

class PartialItemDto {
  @ApiProperty()
  @IsUUID()
  orderItemId!: string;
}

export class RequestConfirmationDto {
  @ApiProperty({ type: [PartialItemDto], description: 'Items that are unavailable' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PartialItemDto)
  unavailableItems!: PartialItemDto[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;
}

export class AdvanceStatusDto {
  @ApiProperty({
    enum: OrderStatus,
    description: 'Next status (PREPARING, READY, OUT_FOR_DELIVERY, DELIVERED, PICKED_UP)',
  })
  @IsEnum(OrderStatus)
  status!: OrderStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;
}

export class QueryOrdersDto extends PaginationDto {
  @ApiPropertyOptional({ enum: OrderStatus })
  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;
}
