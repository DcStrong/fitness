import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class ExceptionWindowDto {
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(1439)
  startMinute!: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(1440)
  endMinute!: number;

  @IsOptional()
  @IsIn(['online', 'offline'])
  mode?: 'online' | 'offline' | null;
}

export class AvailabilityExceptionDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  localDate!: string;

  @IsIn(['closed', 'custom_hours'])
  type!: 'closed' | 'custom_hours';

  @ValidateIf(o => o.type === 'custom_hours')
  @IsArray()
  @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => ExceptionWindowDto)
  windows?: ExceptionWindowDto[] | null;
}

export class ReplaceAvailabilityExceptionsDto {
  @IsArray()
  @ArrayMaxSize(366)
  @ValidateNested({ each: true })
  @Type(() => AvailabilityExceptionDto)
  exceptions!: AvailabilityExceptionDto[];
}
