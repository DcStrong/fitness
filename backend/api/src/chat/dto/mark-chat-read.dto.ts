import { IsUUID } from 'class-validator';

export class MarkChatReadDto {
  @IsUUID()
  upToMessageId!: string;
}
