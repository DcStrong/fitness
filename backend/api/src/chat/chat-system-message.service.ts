import { Injectable } from '@nestjs/common';
import type { EntityManager } from 'typeorm';
import { ChatConversationEntity } from '../database/entity/chat-conversation.entity';
import { ChatMessageEntity } from '../database/entity/chat-message.entity';
import { ChatEventsService } from './chat-events.service';
import { systemMessageBody } from './chat.rules';
import type { PostSystemMessageParams } from './interface';

/**
 * A stored message plus the pair it must be delivered to.
 */
export interface ChatDelivery {
  message: ChatMessageEntity;
  coachId: string;
  studentId: string;
}

/**
 * Session and booking services call `post` inside their own transaction, keep
 * the returned delivery, and call `publish` only after the transaction commits.
 */
@Injectable()
export class ChatSystemMessageService {
  constructor(private readonly events: ChatEventsService) {}

  /**
   *
   */
  async post(params: PostSystemMessageParams): Promise<ChatDelivery> {
    const conversation = await ensureConversation(
      params.manager,
      params.coachId,
      params.studentId,
    );
    const message = await params.manager.save(
      params.manager.create(ChatMessageEntity, {
        conversationId: conversation.id,
        senderId: null,
        kind: 'system',
        body: systemMessageBody(params.type, params.payload),
        systemType: params.type,
        payload: params.payload,
        clientId: null,
      }),
    );
    await touchLastMessage(params.manager, conversation.id, message.id);

    return {
      message,
      coachId: params.coachId,
      studentId: params.studentId,
    };
  }

  /**
   *
   */
  publish(deliveries: ChatDelivery[]): void {
    for (const delivery of deliveries) {
      this.events.messageCreated(delivery);
    }
  }
}

/**
 * Get-or-create the single conversation of a coach–student pair; safe under
 * concurrent callers thanks to the pair unique constraint.
 */
export async function ensureConversation(
  manager: EntityManager,
  coachId: string,
  studentId: string,
): Promise<ChatConversationEntity> {
  await manager
    .createQueryBuilder()
    .insert()
    .into(ChatConversationEntity)
    .values({ coachId, studentId })
    .orIgnore()
    .execute();

  return manager.findOneOrFail(ChatConversationEntity, {
    where: { coachId, studentId },
  });
}

/**
 * Moves `last_message_at` to the message timestamp in SQL so microseconds
 * survive (JS dates would truncate them and break cursor comparisons).
 */
export async function touchLastMessage(
  manager: EntityManager,
  conversationId: string,
  messageId: string,
): Promise<void> {
  await manager.query(
    `UPDATE "chat_conversations" c
        SET "last_message_at" = GREATEST(
          COALESCE(c."last_message_at", '-infinity'::timestamptz), m."created_at")
       FROM "chat_messages" m
      WHERE c."id" = $1 AND m."id" = $2`,
    [conversationId, messageId],
  );
}
