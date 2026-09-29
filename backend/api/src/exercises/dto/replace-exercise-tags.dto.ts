import { IsArray, IsUUID } from 'class-validator';

export class ReplaceExerciseTagsDto {
  @IsArray()
  @IsUUID('4', { each: true })
  tagIds!: string[];
}
