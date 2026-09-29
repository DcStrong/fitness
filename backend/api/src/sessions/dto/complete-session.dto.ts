import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsNumber,
  IsOptional,
  IsUUID,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

export class CompleteSessionSetDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(1000)
  reps?: number | null;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(9999.99)
  weightKg?: number | null;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(86400)
  durationSeconds?: number | null;
}

export class CompleteSessionExerciseLogDto {
  @IsUUID('4')
  exerciseId!: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CompleteSessionSetDto)
  sets!: CompleteSessionSetDto[];
}

export class CompleteSessionDto {
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CompleteSessionExerciseLogDto)
  logs?: CompleteSessionExerciseLogDto[];
}
