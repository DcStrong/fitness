import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

export class CreateRecurringBookingDto {
  @IsUUID()
  studentId!: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  @Type(() => Number)
  weekdays!: number[];

  @IsInt()
  @Min(0)
  @Max(1439)
  @Type(() => Number)
  startMinute!: number;

  @IsIn(['online', 'offline'])
  mode!: 'online' | 'offline';

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(52)
  @Type(() => Number)
  horizonWeeksOverride?: number;
}
