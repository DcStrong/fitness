import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type {
  ChatMessageKind,
  ChatSystemPayload,
  ChatSystemType,
} from '../../chat/interface/chat.types';
import { ChatConversationEntity } from './chat-conversation.entity';
import { UserEntity } from './user.entity';

@Entity({ name: 'chat_messages' })
@Index('IDX_chat_messages_conversation_created', [
  'conversationId',
  'createdAt',
  'id',
])
export class ChatMessageEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'conversation_id', type: 'uuid' })
  conversationId!: string;

  @ManyToOne(() => ChatConversationEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'conversation_id' })
  conversation!: ChatConversationEntity;

  @Column({ name: 'sender_id', type: 'uuid', nullable: true })
  senderId!: string | null;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'sender_id' })
  sender!: UserEntity | null;

  @Column({ type: 'varchar', length: 16 })
  kind!: ChatMessageKind;

  @Column({ type: 'text' })
  body!: string;

  @Column({ name: 'system_type', type: 'varchar', length: 32, nullable: true })
  systemType!: ChatSystemType | null;

  @Column({ type: 'jsonb', nullable: true })
  payload!: ChatSystemPayload | null;

  @Column({ name: 'client_id', type: 'uuid', nullable: true })
  clientId!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
