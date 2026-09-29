import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CancelSessionDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
