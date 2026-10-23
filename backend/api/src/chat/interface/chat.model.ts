import type {
  ChatMessageKind,
  ChatParticipantRole,
  ChatSystemPayload,
  ChatSystemType,
} from './chat.types';

/**
 *
 */
export interface ChatMessageModel {
  id: string;
  conversationId: string;
  senderId: string | null;
  kind: ChatMessageKind;
  body: string;
  systemType: ChatSystemType | null;
  payload: ChatSystemPayload | null;
  clientId: string | null;
  createdAt: string;
}

/**
 *
 */
export interface ChatCounterpartModel {
  id: string;
  email: string;
  displayName: string | null;
}

/**
 *
 */
export interface ChatConversationModel {
  id: string;
  coachId: string;
  studentId: string;
  myRole: ChatParticipantRole;
  counterpart: ChatCounterpartModel;
  lastMessage: ChatMessageModel | null;
  lastMessageAt: string | null;
  unreadCount: number;
  counterpartLastReadAt: string | null;
}

/**
 *
 */
export interface ChatUnreadCountModel {
  total: number;
}

/**
 *
 */
export interface ChatReadModel {
  conversationId: string;
  readerId: string;
  lastReadAt: string;
}
