import {
  IsISO8601,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export class RecordExpenseDto {
  @Matches(/^[1-9]\d*$/, {
    message: 'amountMinor must be a positive integer string',
  })
  amountMinor!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  category?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @IsOptional()
  @IsISO8601({ strict: true })
  occurredAt?: string;
}
