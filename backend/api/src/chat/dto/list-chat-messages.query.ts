import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsUUID, Max, Min } from 'class-validator';
import { CHAT_PAGE_MAX_LIMIT } from '../chat.rules';

export class ListChatMessagesQuery {
  @IsOptional()
  @IsUUID()
  before?: string;

  @IsOptional()
  @IsUUID()
  after?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(CHAT_PAGE_MAX_LIMIT)
  @Type(() => Number)
  limit?: number;
}
