import { IsOptional, IsString, MaxLength } from 'class-validator';

export class ListChatsQuery {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  q?: string;
}
