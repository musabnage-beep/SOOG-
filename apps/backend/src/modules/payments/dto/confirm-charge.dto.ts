import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class ConfirmChargeDto {
  /** Gateway charge id returned to the app by the in-app payment SDK. */
  @ApiProperty({ example: '502317fc-8dcd-4113-b9cf-a0e69876956d' })
  @IsString()
  @IsNotEmpty()
  paymentId!: string;
}
