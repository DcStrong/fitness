import { IsUUID } from 'class-validator';

export class OpenChatDto {
  @IsUUID()
  counterpartId!: string;
}
