import { ArrayNotEmpty, IsArray, IsUUID } from 'class-validator';

export class UnassignExercisesDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('4', { each: true })
  exerciseIds!: string[];

  @IsUUID('4')
  studentId!: string;
}
