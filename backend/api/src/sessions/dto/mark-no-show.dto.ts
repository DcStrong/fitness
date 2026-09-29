import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class MarkNoShowDto {
  @IsBoolean()
  charge!: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
