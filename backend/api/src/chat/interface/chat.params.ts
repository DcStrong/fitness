import type { EntityManager } from 'typeorm';
import type { ChatSystemPayload, ChatSystemType } from './chat.types';

/**
 *
 */
export interface ListChatMessagesParams {
  actorId: string;
  conversationId: string;
  before?: string;
  after?: string;
  limit?: number;
}

/**
 *
 */
export interface SendChatMessageParams {
  actorId: string;
  conversationId: string;
  clientId: string;
  body: string;
}

/**
 *
 */
export interface MarkChatReadParams {
  actorId: string;
  conversationId: string;
  upToMessageId: string;
}

/**
 *
 */
export interface PostSystemMessageParams {
  manager: EntityManager;
  coachId: string;
  studentId: string;
  type: ChatSystemType;
  payload: ChatSystemPayload;
}
