import type { ChatMessageEntity } from '../database/entity/chat-message.entity';
import type { ChatMessageModel } from './interface';

/**
 *
 */
export function toChatMessageModel(message: ChatMessageEntity): ChatMessageModel {
  return {
    id: message.id,
    conversationId: message.conversationId,
    senderId: message.senderId,
    kind: message.kind,
    body: message.body,
    systemType: message.systemType,
    payload: message.payload,
    clientId: message.clientId,
    createdAt: message.createdAt.toISOString(),
  };
}
