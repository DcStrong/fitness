import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsNumber,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

export class PlanLoadItemDto {
  @IsUUID('4')
  exerciseId!: string;

  @IsNumber()
  @Min(0)
  weightKg!: number;
}

export class PatchPlanLoadsDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => PlanLoadItemDto)
  items!: PlanLoadItemDto[];
}
