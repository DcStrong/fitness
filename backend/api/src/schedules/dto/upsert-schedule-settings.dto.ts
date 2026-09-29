import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateIf,
} from 'class-validator';

export class UpsertScheduleSettingsDto {
  @IsString()
  timezone!: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  defaultDurationMinutes!: number;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  breakMinutes!: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(52)
  horizonWeeks!: number;

  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @Type(() => Number)
  @IsInt()
  @Min(1)
  onlineDurationMinutes?: number | null;

  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @Type(() => Number)
  @IsInt()
  @Min(1)
  offlineDurationMinutes?: number | null;

  @IsIn(['online', 'offline'])
  defaultMode!: 'online' | 'offline';
}
