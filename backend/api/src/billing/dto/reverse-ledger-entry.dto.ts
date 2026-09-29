import {
  IsISO8601,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class ReverseLedgerEntryDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @IsOptional()
  @IsISO8601({ strict: true })
  occurredAt?: string;
}
