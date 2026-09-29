import { IsUUID } from 'class-validator';

export class AssignTagDto {
  @IsUUID()
  userId!: string;
}
