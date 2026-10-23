import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, QueryFailedError, type EntityManager } from 'typeorm';
import { ChatConversationEntity } from '../database/entity/chat-conversation.entity';
import { ChatMessageEntity } from '../database/entity/chat-message.entity';
import { CoachStudentLinkEntity } from '../database/entity/coach-student-link.entity';
import { ChatEventsService } from './chat-events.service';
import { toChatMessageModel } from './chat.mapper';
import {
  CHAT_PAGE_DEFAULT_LIMIT,
  CHAT_PAGE_MAX_LIMIT,
  normalizeChatBody,
} from './chat.rules';
import { ensureConversation, touchLastMessage } from './chat-system-message.service';
import type {
  ChatConversationModel,
  ChatMessageModel,
  ChatParticipantRole,
  ChatReadModel,
  ChatUnreadCountModel,
  ListChatMessagesParams,
  MarkChatReadParams,
  SendChatMessageParams,
} from './interface';

/**
 *
 */
interface ConversationRow {
  id: string;
  coachId: string;
  studentId: string;
  lastMessageAt: Date | null;
  counterpartLastReadAt: Date | null;
  counterpartId: string;
  counterpartEmail: string;
  counterpartName: string | null;
  unread: number;
}

/**
 * Unread for `$1`: messages after the caller's read marker not sent by the caller.
 */
const UNREAD_SQL = `(
  SELECT COUNT(*)::int FROM "chat_messages" m
   WHERE m."conversation_id" = c."id"
     AND m."sender_id" IS DISTINCT FROM $1
     AND m."created_at" > COALESCE(
       CASE WHEN c."coach_id" = $1 THEN c."coach_last_read_at"
            ELSE c."student_last_read_at" END,
       '-infinity'::timestamptz))`;

@Injectable()
export class ChatService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly events: ChatEventsService,
  ) {}

  /**
   * Conversations that have at least one message, newest first.
   */
  async list(actorId: string, q?: string): Promise<ChatConversationModel[]> {
    const search = q?.trim() ? `%${escapeLike(q.trim())}%` : null;
    const rows = (await this.dataSource.query(
      `${this.conversationSelect()}
        WHERE (c."coach_id" = $1 OR c."student_id" = $1)
          AND c."last_message_at" IS NOT NULL
          AND ($2::text IS NULL OR u."email" ILIKE $2 OR p."display_name" ILIKE $2)
        ORDER BY c."last_message_at" DESC`,
      [actorId, search],
    )) as ConversationRow[];

    return this.toConversationModels(actorId, rows);
  }

  /**
   * Get-or-create the conversation with a linked counterpart.
   */
  async open(
    actorId: string,
    counterpartId: string,
  ): Promise<ChatConversationModel> {
    const link = await this.findLink(this.dataSource.manager, actorId, counterpartId);
    if (!link) {
      throw new ForbiddenException('No coach–student link with this user');
    }
    const conversation = await ensureConversation(
      this.dataSource.manager,
      link.coachId,
      link.studentId,
    );

    return this.getConversation(actorId, conversation.id);
  }

  /**
   *
   */
  async getConversation(
    actorId: string,
    conversationId: string,
  ): Promise<ChatConversationModel> {
    const rows = (await this.dataSource.query(
      `${this.conversationSelect()}
        WHERE c."id" = $2 AND (c."coach_id" = $1 OR c."student_id" = $1)`,
      [actorId, conversationId],
    )) as ConversationRow[];
    const [model] = await this.toConversationModels(actorId, rows);
    if (!model) {
      throw new NotFoundException('Conversation not found');
    }

    return model;
  }

  /**
   *
   */
  async unreadCount(actorId: string): Promise<ChatUnreadCountModel> {
    const [row] = (await this.dataSource.query(
      `SELECT COALESCE(SUM(${UNREAD_SQL}), 0)::int AS "total"
         FROM "chat_conversations" c
        WHERE c."coach_id" = $1 OR c."student_id" = $1`,
      [actorId],
    )) as Array<{ total: number; }>;

    return { total: row?.total ?? 0 };
  }

  /**
   * Cursor page in ascending order. Without a cursor returns the latest page;
   * `after` is what clients use to catch up after a reconnect.
   */
  async messages(
    params: ListChatMessagesParams,
  ): Promise<{ items: ChatMessageModel[]; hasMore: boolean; }> {
    await this.requireParticipant(this.dataSource.manager, params);
    const limit = Math.min(
      params.limit ?? CHAT_PAGE_DEFAULT_LIMIT,
      CHAT_PAGE_MAX_LIMIT,
    );
    const qb = this.dataSource.manager
      .createQueryBuilder(ChatMessageEntity, 'm')
      .where('m.conversation_id = :conversationId', {
        conversationId: params.conversationId,
      })
      .take(limit + 1);
    const ascending = params.after !== undefined;
    if (params.after !== undefined) {
      qb.andWhere(
        `(m.created_at, m.id) > (SELECT a.created_at, a.id FROM chat_messages a
           WHERE a.id = :after AND a.conversation_id = :conversationId)`,
        { after: params.after },
      );
    }
    if (params.before !== undefined) {
      qb.andWhere(
        `(m.created_at, m.id) < (SELECT b.created_at, b.id FROM chat_messages b
           WHERE b.id = :before AND b.conversation_id = :conversationId)`,
        { before: params.before },
      );
    }
    qb.orderBy('m.created_at', ascending ? 'ASC' : 'DESC').addOrderBy(
      'm.id',
      ascending ? 'ASC' : 'DESC',
    );
    const found = await qb.getMany();
    const hasMore = found.length > limit;
    const page = found.slice(0, limit);
    if (!ascending) {
      page.reverse();
    }

    return { items: page.map(toChatMessageModel), hasMore };
  }

  /**
   * Idempotent by `clientId`: a retry returns the stored message.
   */
  async send(params: SendChatMessageParams): Promise<ChatMessageModel> {
    const body = normalizeChatBody(params.body);
    const existing = await this.findByClientId(params);
    if (existing) {
      return toChatMessageModel(existing);
    }

    let conversation: ChatConversationEntity;
    let message: ChatMessageEntity;
    try {
      ({ conversation, message } = await this.dataSource.transaction(
        async manager => {
          const found = await this.requireParticipant(manager, params);
          const link = await manager.findOne(CoachStudentLinkEntity, {
            where: { coachId: found.coachId, studentId: found.studentId },
          });
          if (!link) {
            throw new ForbiddenException('No coach–student link with this user');
          }
          const saved = await manager.save(
            manager.create(ChatMessageEntity, {
              conversationId: found.id,
              senderId: params.actorId,
              kind: 'text',
              body,
              systemType: null,
              payload: null,
              clientId: params.clientId,
            }),
          );
          await touchLastMessage(manager, found.id, saved.id);
          // Writing implies having read everything up to the own message.
          await this.moveReadMarker(
            manager,
            found,
            this.roleOf(found, params.actorId),
            saved.id,
          );

          return { conversation: found, message: saved };
        },
      ));
    } catch (error) {
      if (isUniqueViolation(error)) {
        const raced = await this.findByClientId(params);
        if (raced) {
          return toChatMessageModel(raced);
        }
      }
      throw error;
    }

    this.events.messageCreated({
      message,
      coachId: conversation.coachId,
      studentId: conversation.studentId,
    });

    return toChatMessageModel(message);
  }

  /**
   * Moves the caller's read marker forward to the given message.
   */
  async markRead(params: MarkChatReadParams): Promise<ChatReadModel> {
    const { conversation, lastReadAt } = await this.dataSource.transaction(
      async manager => {
        const found = await this.requireParticipant(manager, params);
        const message = await manager.findOne(ChatMessageEntity, {
          where: { id: params.upToMessageId, conversationId: found.id },
        });
        if (!message) {
          throw new NotFoundException('Message not found');
        }
        const marker = await this.moveReadMarker(
          manager,
          found,
          this.roleOf(found, params.actorId),
          message.id,
        );

        return { conversation: found, lastReadAt: marker };
      },
    );
    const read: ChatReadModel = {
      conversationId: conversation.id,
      readerId: params.actorId,
      lastReadAt: lastReadAt.toISOString(),
    };
    this.events.conversationRead(
      [conversation.coachId, conversation.studentId],
      read,
    );

    return read;
  }

  /**
   *
   */
  private conversationSelect(): string {
    return `SELECT c."id", c."coach_id" AS "coachId", c."student_id" AS "studentId",
                   c."last_message_at" AS "lastMessageAt",
                   CASE WHEN c."coach_id" = $1 THEN c."student_last_read_at"
                        ELSE c."coach_last_read_at" END AS "counterpartLastReadAt",
                   u."id" AS "counterpartId", u."email" AS "counterpartEmail",
                   p."display_name" AS "counterpartName",
                   ${UNREAD_SQL} AS "unread"
              FROM "chat_conversations" c
              JOIN "users" u ON u."id" = CASE WHEN c."coach_id" = $1
                                              THEN c."student_id" ELSE c."coach_id" END
              LEFT JOIN "user_profiles" p ON p."user_id" = u."id"`;
  }

  /**
   *
   */
  private async toConversationModels(
    actorId: string,
    rows: ConversationRow[],
  ): Promise<ChatConversationModel[]> {
    if (rows.length === 0) {
      return [];
    }
    const lastMessages = await this.dataSource.manager
      .createQueryBuilder(ChatMessageEntity, 'm')
      .distinctOn(['m.conversation_id'])
      .where('m.conversation_id IN (:...ids)', { ids: rows.map(row => row.id) })
      .orderBy('m.conversation_id')
      .addOrderBy('m.created_at', 'DESC')
      .addOrderBy('m.id', 'DESC')
      .getMany();
    const lastById = new Map(
      lastMessages.map(message => [message.conversationId, message]),
    );

    return rows.map(row => {
      const last = lastById.get(row.id);
      const name = row.counterpartName?.trim();

      return {
        id: row.id,
        coachId: row.coachId,
        studentId: row.studentId,
        myRole: row.coachId === actorId ? 'coach' : 'student',
        counterpart: {
          id: row.counterpartId,
          email: row.counterpartEmail,
          displayName: name && name.length > 0 ? name : null,
        },
        lastMessage: last ? toChatMessageModel(last) : null,
        lastMessageAt: row.lastMessageAt?.toISOString() ?? null,
        unreadCount: Number(row.unread),
        counterpartLastReadAt:
          row.counterpartLastReadAt?.toISOString() ?? null,
      };
    });
  }

  /**
   * Non-participants get 404 so conversation ids are not probeable.
   */
  private async requireParticipant(
    manager: EntityManager,
    params: { actorId: string; conversationId: string; },
  ): Promise<ChatConversationEntity> {
    const conversation = await manager.findOne(ChatConversationEntity, {
      where: { id: params.conversationId },
    });
    if (
      !conversation ||
      conversation.coachId !== params.actorId &&
        conversation.studentId !== params.actorId
    ) {
      throw new NotFoundException('Conversation not found');
    }

    return conversation;
  }

  /**
   *
   */
  private async findLink(
    manager: EntityManager,
    actorId: string,
    counterpartId: string,
  ): Promise<CoachStudentLinkEntity | null> {
    return (
      await manager.findOne(CoachStudentLinkEntity, {
        where: { coachId: actorId, studentId: counterpartId },
      }) ??
      await manager.findOne(CoachStudentLinkEntity, {
        where: { coachId: counterpartId, studentId: actorId },
      })
    );
  }

  /**
   *
   */
  private async findByClientId(
    params: SendChatMessageParams,
  ): Promise<ChatMessageEntity | null> {
    return this.dataSource.manager.findOne(ChatMessageEntity, {
      where: {
        conversationId: params.conversationId,
        senderId: params.actorId,
        clientId: params.clientId,
      },
    });
  }

  /**
   *
   */
  private roleOf(
    conversation: ChatConversationEntity,
    actorId: string,
  ): ChatParticipantRole {
    return conversation.coachId === actorId ? 'coach' : 'student';
  }

  /**
   * Forward-only, done in SQL to keep microsecond precision of `created_at`.
   */
  private async moveReadMarker(
    manager: EntityManager,
    conversation: ChatConversationEntity,
    role: ChatParticipantRole,
    messageId: string,
  ): Promise<Date> {
    const column =
      role === 'coach' ? 'coach_last_read_at' : 'student_last_read_at';
    const [row] = (await manager.query(
      `UPDATE "chat_conversations" c
          SET "${column}" = GREATEST(
            COALESCE(c."${column}", '-infinity'::timestamptz), m."created_at")
         FROM "chat_messages" m
        WHERE c."id" = $1 AND m."id" = $2
    RETURNING c."${column}" AS "lastReadAt"`,
      [conversation.id, messageId],
    )) as [Array<{ lastReadAt: Date; }>, number];

    return row[0]!.lastReadAt;
  }
}

/**
 *
 */
function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, char => `\\${char}`);
}

/**
 *
 */
function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof QueryFailedError &&
    (error.driverError as { code?: string; }).code === '23505'
  );
}
