import { Injectable } from '@nestjs/common';
import type { Namespace } from 'socket.io';
import type { ChatMessageEntity } from '../database/entity/chat-message.entity';
import { toChatMessageModel } from './chat.mapper';
import type { ChatReadModel } from './interface';

export const CHAT_EVENT_MESSAGE_CREATED = 'message.created';
export const CHAT_EVENT_CONVERSATION_READ = 'conversation.read';

/**
 * Socket room that holds every connection of one user.
 */
export function chatUserRoom(userId: string): string {
  return `user:${userId}`;
}

/**
 * Fan-out of chat events to both participants. The gateway attaches the
 * socket.io namespace on init; before that (unit tests, cron) emits are no-ops.
 */
@Injectable()
export class ChatEventsService {
  private namespace: Namespace | null = null;

  /**
   *
   */
  attach(namespace: Namespace): void {
    this.namespace = namespace;
  }

  /**
   *
   */
  messageCreated(params: {
    message: ChatMessageEntity;
    coachId: string;
    studentId: string;
  }): void {
    this.emit(
      [params.coachId, params.studentId],
      CHAT_EVENT_MESSAGE_CREATED,
      toChatMessageModel(params.message),
    );
  }

  /**
   *
   */
  conversationRead(
    participants: [string, string],
    read: ChatReadModel,
  ): void {
    this.emit(participants, CHAT_EVENT_CONVERSATION_READ, read);
  }

  /**
   *
   */
  private emit(userIds: string[], event: string, payload: unknown): void {
    if (!this.namespace) {
      return;
    }
    this.namespace.to(userIds.map(chatUserRoom)).emit(event, payload);
  }
}
