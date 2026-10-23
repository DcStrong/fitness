import { IsString, IsUUID, MaxLength } from 'class-validator';
import { CHAT_MESSAGE_MAX_LENGTH } from '../chat.rules';

export class SendChatMessageDto {
  @IsUUID()
  clientId!: string;

  @IsString()
  @MaxLength(CHAT_MESSAGE_MAX_LENGTH + 1000)
  body!: string;
}
