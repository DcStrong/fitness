import { IsISO8601, IsIn, IsOptional } from 'class-validator';
import type { PaymentMethod } from '../interface';

export class MarkChargePaidDto {
  @IsIn(['cash', 'transfer', 'card', 'other'])
  paymentMethod!: PaymentMethod;

  @IsOptional()
  @IsISO8601({ strict: true })
  paidAt?: string;
}
