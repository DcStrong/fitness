import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { PERMISSIONS } from '../access-control/constants';
import { RequirePermissions } from '../access-control/permissions.decorator';
import { PermissionsGuard } from '../access-control/permissions.guard';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthUserPayload } from '../auth/interface/auth-user-payload.interface';
import { ChatService } from './chat.service';
import { ListChatMessagesQuery } from './dto/list-chat-messages.query';
import { ListChatsQuery } from './dto/list-chats.query';
import { MarkChatReadDto } from './dto/mark-chat-read.dto';
import { OpenChatDto } from './dto/open-chat.dto';
import { SendChatMessageDto } from './dto/send-chat-message.dto';

/**
 *
 */
type RequestWithUser = Request & { user: AuthUserPayload; };

@Controller('chats')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ChatController {
  constructor(private readonly chat: ChatService) {}

  /**
   *
   */
  @Get()
  @RequirePermissions(PERMISSIONS.CHAT_READ_OWN)
  async list(@Req() req: RequestWithUser, @Query() query: ListChatsQuery) {
    return this.chat.list(req.user.id, query.q);
  }

  /**
   *
   */
  @Post()
  @HttpCode(200)
  @RequirePermissions(PERMISSIONS.CHAT_READ_OWN)
  async open(@Req() req: RequestWithUser, @Body() dto: OpenChatDto) {
    return this.chat.open(req.user.id, dto.counterpartId);
  }

  /**
   *
   */
  @Get('unread-count')
  @RequirePermissions(PERMISSIONS.CHAT_READ_OWN)
  async unreadCount(@Req() req: RequestWithUser) {
    return this.chat.unreadCount(req.user.id);
  }

  /**
   *
   */
  @Get(':id')
  @RequirePermissions(PERMISSIONS.CHAT_READ_OWN)
  async get(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.chat.getConversation(req.user.id, id);
  }

  /**
   *
   */
  @Get(':id/messages')
  @RequirePermissions(PERMISSIONS.CHAT_READ_OWN)
  async messages(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: ListChatMessagesQuery,
  ) {
    return this.chat.messages({
      actorId: req.user.id,
      conversationId: id,
      ...query.before !== undefined ? { before: query.before } : {},
      ...query.after !== undefined ? { after: query.after } : {},
      ...query.limit !== undefined ? { limit: query.limit } : {},
    });
  }

  /**
   *
   */
  @Post(':id/messages')
  @RequirePermissions(PERMISSIONS.CHAT_SEND_OWN)
  async send(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SendChatMessageDto,
  ) {
    return this.chat.send({
      actorId: req.user.id,
      conversationId: id,
      clientId: dto.clientId,
      body: dto.body,
    });
  }

  /**
   *
   */
  @Post(':id/read')
  @HttpCode(200)
  @RequirePermissions(PERMISSIONS.CHAT_READ_OWN)
  async read(
    @Req() req: RequestWithUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MarkChatReadDto,
  ) {
    return this.chat.markRead({
      actorId: req.user.id,
      conversationId: id,
      upToMessageId: dto.upToMessageId,
    });
  }
}
