import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  ValidateIf,
} from 'class-validator';

export class ResolveOccurrenceDto {
  @IsIn(['skip', 'reschedule'])
  type!: 'skip' | 'reschedule';

  @ValidateIf(dto => dto.type === 'reschedule')
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1439)
  @Type(() => Number)
  newStartMinute?: number;

  @ValidateIf(dto => dto.type === 'reschedule')
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  newLocalDate?: string;
}
