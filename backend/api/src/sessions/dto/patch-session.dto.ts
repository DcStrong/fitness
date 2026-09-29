import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsNumber,
  IsOptional,
  IsUUID,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class PatchSessionWorkoutLoadItemDto {
  @IsUUID('4')
  exerciseId!: string;

  @IsNumber()
  @Min(0)
  weightKg!: number;
}

export class PatchSessionWorkoutLoadsDto {
  @IsUUID('4')
  studentPlanId!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => PatchSessionWorkoutLoadItemDto)
  items!: PatchSessionWorkoutLoadItemDto[];
}

export class PatchSessionDto {
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsUUID('4')
  studentPlanId?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  @Type(() => String)
  workoutPlanIds?: string[];

  @IsOptional()
  @ValidateNested()
  @Type(() => PatchSessionWorkoutLoadsDto)
  workoutLoads?: PatchSessionWorkoutLoadsDto;
}
