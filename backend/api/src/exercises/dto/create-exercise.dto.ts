import { IsArray, IsIn, IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { EXERCISE_KINDS, type ExerciseKind } from '../interface';

export class CreateExerciseDto {
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  name!: string;

  @IsIn([...EXERCISE_KINDS])
  kind!: ExerciseKind;

  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  tagIds?: string[];
}
