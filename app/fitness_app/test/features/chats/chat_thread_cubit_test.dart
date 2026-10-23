import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/chats/data/chat_models.dart';
import 'package:fitness_app/features/chats/presentation/cubit/chat_thread_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'chat_test_helpers.dart';

void main() {
  late MockChatsRepository repository;
  late FakeChatRealtime realtime;

  ChatThreadCubit build({String? counterpart}) => ChatThreadCubit(
    repository: repository,
    realtime: realtime,
    myUserId: coachId,
    conversationId: counterpart == null ? conversationId : null,
    counterpartId: counterpart,
    newClientId: () => 'client-1',
    readDebounce: Duration.zero,
  );

  setUp(() {
    repository = MockChatsRepository();
    realtime = FakeChatRealtime();
    when(
      () => repository.get(conversationId),
    ).thenAnswer((_) async => conversation());
    when(
      () => repository.open(studentId),
    ).thenAnswer((_) async => conversation());
    when(
      () => repository.messages(conversationId, limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async => ChatMessagesPage(
        items: [textMessage('m1', studentId, 'Можно в 11:15?')],
        hasMore: false,
      ),
    );
    when(() => repository.markRead(any(), any())).thenAnswer((_) async {});
  });

  test('loads history and marks the last message read', () async {
    final cubit = build();
    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, ChatThreadStatus.ready);
    expect(cubit.state.messages.map((m) => m.id), ['m1']);
    verify(() => repository.markRead(conversationId, 'm1')).called(1);
    await cubit.close();
  });

  test('opens by counterpart id when no conversation id is known', () async {
    final cubit = build(counterpart: studentId);
    await cubit.load();

    expect(cubit.state.conversation?.id, conversationId);
    verify(() => repository.open(studentId)).called(1);
    await cubit.close();
  });

  test(
    'send shows the bubble at once and replaces it with the server copy',
    () async {
      when(
        () => repository.send(
          conversationId,
          clientId: 'client-1',
          body: 'Перенёс, жду в 11:15.',
        ),
      ).thenAnswer(
        (_) async => textMessage(
          'm2',
          coachId,
          'Перенёс, жду в 11:15.',
          at: DateTime(2026, 10, 23, 10, 14),
          clientId: 'client-1',
        ),
      );
      final cubit = build();
      await cubit.load();
      final states = <ChatThreadState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.send('  Перенёс, жду в 11:15.  ');

      expect(states.first.messages.last.delivery, ChatDeliveryState.sending);
      expect(cubit.state.messages.map((m) => m.id), ['m1', 'm2']);
      await sub.cancel();
      await cubit.close();
    },
  );

  test('a failed send can be retried with the same client id', () async {
    var attempts = 0;
    when(
      () =>
          repository.send(conversationId, clientId: 'client-1', body: 'Привет'),
    ).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) throw ApiException('Нет соединения с сервером');
      return textMessage(
        'm2',
        coachId,
        'Привет',
        clientId: 'client-1',
        at: DateTime(2026, 10, 23, 10, 20),
      );
    });
    final cubit = build();
    await cubit.load();

    await cubit.send('Привет');
    expect(cubit.state.messages.last.delivery, ChatDeliveryState.failed);

    await cubit.retry('client-1');
    expect(cubit.state.messages.map((m) => m.id), ['m1', 'm2']);
    expect(cubit.state.messages.last.delivery, ChatDeliveryState.sent);
    await cubit.close();
  });

  test(
    'live messages merge once, even when the socket echoes own sends',
    () async {
      final cubit = build();
      await cubit.load();

      final incoming = textMessage(
        'm3',
        studentId,
        'Спасибо!',
        at: DateTime(2026, 10, 23, 10, 15),
      );
      realtime.messagesController
        ..add(incoming)
        ..add(incoming);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.messages.map((m) => m.id), ['m1', 'm3']);
      await cubit.close();
    },
  );

  test('ignores live messages of other conversations', () async {
    final cubit = build();
    await cubit.load();

    realtime.messagesController.add(
      ChatMessage(
        id: 'x',
        conversationId: 'other',
        senderId: studentId,
        kind: ChatMessageKind.text,
        body: 'чужое',
        createdAt: DateTime(2026, 10, 23, 11),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.messages.map((m) => m.id), ['m1']);
    await cubit.close();
  });

  test('catches up with after-cursor on reconnect', () async {
    when(
      () => repository.messages(
        conversationId,
        after: 'm1',
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => ChatMessagesPage(
        items: [
          textMessage(
            'm4',
            studentId,
            'Пока сокет лежал',
            at: DateTime(2026, 10, 23, 10, 30),
          ),
        ],
        hasMore: false,
      ),
    );
    final cubit = build();
    await cubit.load();

    realtime.connectedController.add(null);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.messages.map((m) => m.id), ['m1', 'm4']);
    await cubit.close();
  });
}
