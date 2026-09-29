import { Type } from 'class-transformer';
import {
  IsDateString,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

export class CreateSessionPackageDto {
  @IsUUID()
  studentId!: string;

  @IsInt()
  @Min(1)
  @Max(1000)
  @Type(() => Number)
  totalSessions!: number;

  @IsOptional()
  @IsDateString()
  expiresAt?: string;
}
