import { IsIn, Matches } from 'class-validator';
import type { BillingCurrency } from '../interface';

export class UpdateFinanceSettingsDto {
  @Matches(/^[1-9]\d*$/, {
    message: 'defaultSessionPriceMinor must be a positive integer string',
  })
  defaultSessionPriceMinor!: string;

  @IsIn(['RUB'])
  currency!: BillingCurrency;
}
