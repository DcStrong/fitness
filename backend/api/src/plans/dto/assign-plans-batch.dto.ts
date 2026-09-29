import { ArrayNotEmpty, IsArray, IsUUID } from 'class-validator';

export class AssignPlansBatchDto {
  @IsUUID('4')
  studentId!: string;

  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('4', { each: true })
  planIds!: string[];
}
