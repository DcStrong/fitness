import { Type } from 'class-transformer';
import { IsDateString, IsInt, IsOptional, Max, Min } from 'class-validator';

export class ExtendSessionPackageDto {
  @IsInt()
  @Min(1)
  @Max(1000)
  @Type(() => Number)
  addSessions!: number;

  @IsOptional()
  @IsDateString()
  expiresAt?: string;
}
