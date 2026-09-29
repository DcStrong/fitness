import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsUUID,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class UpsertProgramDayItemDto {
  @IsUUID('4')
  templateId!: string;
}

export class UpsertProgramDayDto {
  @IsInt()
  @Min(1)
  @Max(7)
  weekday!: number;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => UpsertProgramDayItemDto)
  items!: UpsertProgramDayItemDto[];
}

export class UpsertProgressionRuleDto {
  @IsUUID('4')
  exerciseId!: string;

  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsNumber()
  @Min(0)
  startWeightKg?: number | null;

  @IsOptional()
  @IsNumber()
  deltaKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  incrementKg?: number;

  @IsOptional()
  @IsBoolean()
  holdOnMiss?: boolean;
}

export class UpsertWorkoutProgramDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(8)
  horizonWeeks?: number;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => UpsertProgramDayDto)
  days!: UpsertProgramDayDto[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpsertProgressionRuleDto)
  progressionRules?: UpsertProgressionRuleDto[];
}

export class ApplyWorkoutProgramDto {
  @IsOptional()
  @IsBoolean()
  force?: boolean;
}
