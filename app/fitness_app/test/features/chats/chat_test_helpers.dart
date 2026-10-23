import 'dart:async';

import 'package:fitness_app/features/chats/data/chat_models.dart';
import 'package:fitness_app/features/chats/data/chat_realtime.dart';
import 'package:fitness_app/features/chats/data/chats_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockChatsRepository extends Mock implements ChatsRepository {}

/// In-memory [ChatRealtime] driven by the test.
class FakeChatRealtime implements ChatRealtime {
  final messagesController = StreamController<ChatMessage>.broadcast();
  final readsController = StreamController<ChatReadEvent>.broadcast();
  final connectedController = StreamController<void>.broadcast();
  int starts = 0;
  int stops = 0;

  @override
  Stream<ChatMessage> get messages => messagesController.stream;

  @override
  Stream<ChatReadEvent> get reads => readsController.stream;

  @override
  Stream<void> get connected => connectedController.stream;

  @override
  void start() => starts++;

  @override
  void stop() => stops++;
}

const coachId = 'coach-1';
const studentId = 'student-1';
const conversationId = 'conv-1';

ChatConversation conversation({bool isCoach = true, int unread = 0}) =>
    ChatConversation(
      id: conversationId,
      coachId: coachId,
      studentId: studentId,
      isCoach: isCoach,
      counterpart: isCoach
          ? const ChatCounterpart(
              id: studentId,
              email: 'maria@example.com',
              displayName: 'Мария Соколова',
            )
          : const ChatCounterpart(
              id: coachId,
              email: 'alex@example.com',
              displayName: 'Алексей Морозов',
            ),
      lastMessage: textMessage('m1', studentId, 'Можно в 11:15?'),
      lastMessageAt: DateTime(2026, 10, 23, 10, 12),
      unreadCount: unread,
    );

ChatMessage textMessage(
  String id,
  String senderId,
  String body, {
  DateTime? at,
  String? clientId,
}) => ChatMessage(
  id: id,
  conversationId: conversationId,
  senderId: senderId,
  kind: ChatMessageKind.text,
  body: body,
  clientId: clientId,
  createdAt: at ?? DateTime(2026, 10, 23, 10, 12),
);

ChatMessage systemMessage(String id, ChatSystemType type, {DateTime? at}) =>
    ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: null,
      kind: ChatMessageKind.system,
      body: 'Занятие перенесено',
      systemType: type,
      payload: ChatSystemPayload(
        sessionId: 'session-1',
        startsAt: DateTime(2026, 10, 21, 11, 15),
      ),
      createdAt: at ?? DateTime(2026, 10, 23, 10, 14),
    );
