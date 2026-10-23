import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/auth/data/auth_models.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fitness_app/features/chats/data/chat_models.dart';
import 'package:fitness_app/features/chats/presentation/chat_thread_page.dart';
import 'package:fitness_app/features/chats/presentation/chats_page.dart';
import 'package:fitness_app/features/chats/presentation/cubit/chat_list_cubit.dart';
import 'package:fitness_app/features/chats/presentation/cubit/chat_thread_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'chat_test_helpers.dart';

class _ListCubit extends MockCubit<ChatListState> implements ChatListCubit {}

class _ThreadCubit extends MockCubit<ChatThreadState>
    implements ChatThreadCubit {}

class _AuthCubit extends MockCubit<AuthState> implements AuthCubit {}

final _now = DateTime(2026, 10, 23, 12);

void main() {
  for (final viewport in const [
    (name: 'compact', size: Size(320, 700)),
    (name: 'standard', size: Size(390, 844)),
  ]) {
    testWidgets(
      'trainer list shows name, preview and unread (${viewport.name})',
      (tester) async {
        _setViewport(tester, viewport.size);
        final cubit = _ListCubit();
        whenListen(
          cubit,
          const Stream<ChatListState>.empty(),
          initialState: ChatListState(
            status: ChatListStatus.ready,
            conversations: [conversation(unread: 2)],
          ),
        );

        await _pumpList(tester, cubit);

        expect(find.text('Чаты'), findsOneWidget);
        expect(find.text('Мария Соколова'), findsOneWidget);
        expect(find.text('10:12'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.byKey(const Key('chat-search')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'thread renders bubbles, day and system card (${viewport.name})',
      (tester) async {
        _setViewport(tester, viewport.size);
        final cubit = _ThreadCubit();
        whenListen(
          cubit,
          const Stream<ChatThreadState>.empty(),
          initialState: ChatThreadState(
            status: ChatThreadStatus.ready,
            conversation: conversation(),
            messages: [
              textMessage(
                'm1',
                studentId,
                'Можно сегодня чуть позже, в 11:15?',
              ),
              textMessage(
                'm2',
                coachId,
                'Да, без проблем.',
                at: DateTime(2026, 10, 23, 10, 14),
              ),
              systemMessage('s1', ChatSystemType.sessionRescheduled),
            ],
          ),
        );

        await _pumpThread(tester, cubit);

        expect(find.text('Сегодня'), findsOneWidget);
        expect(find.text('Можно сегодня чуть позже, в 11:15?'), findsOneWidget);
        expect(find.text('Да, без проблем.'), findsOneWidget);
        expect(find.text('Занятие перенесено'), findsOneWidget);
        expect(find.text('11:15'), findsOneWidget);
        expect(find.byKey(const Key('chat-book')), findsOneWidget);
        expect(find.byKey(const Key('chat-input')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('own failed message offers retry', (tester) async {
    final cubit = _ThreadCubit();
    when(() => cubit.retry(any())).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<ChatThreadState>.empty(),
      initialState: ChatThreadState(
        status: ChatThreadStatus.ready,
        conversation: conversation(),
        messages: [
          ChatMessage.pending(
            clientId: 'c1',
            conversationId: conversationId,
            senderId: coachId,
            body: 'Привет',
          ).copyWith(delivery: ChatDeliveryState.failed),
        ],
      ),
    );

    await _pumpThread(tester, cubit);
    await tester.tap(find.byKey(const Key('chat-retry-c1')));

    verify(() => cubit.retry('c1')).called(1);
  });

  testWidgets('composer sends trimmed text and clears the field', (
    tester,
  ) async {
    final cubit = _ThreadCubit();
    when(() => cubit.send(any())).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<ChatThreadState>.empty(),
      initialState: ChatThreadState(
        status: ChatThreadStatus.ready,
        conversation: conversation(),
      ),
    );

    await _pumpThread(tester, cubit);
    expect(find.text('Сообщений пока нет. Напишите первым.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('chat-input')), ' Привет ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pump();

    verify(() => cubit.send('Привет')).called(1);
    expect(find.text(' Привет '), findsNothing);
  });

  testWidgets('student thread has no back button and no booking action', (
    tester,
  ) async {
    final cubit = _ThreadCubit();
    whenListen(
      cubit,
      const Stream<ChatThreadState>.empty(),
      initialState: ChatThreadState(
        status: ChatThreadStatus.ready,
        conversation: conversation(isCoach: false),
      ),
    );

    await _pumpThread(tester, cubit, showBack: false, me: studentId);

    expect(find.text('Алексей Морозов'), findsOneWidget);
    expect(find.text('Ваш тренер'), findsOneWidget);
    expect(find.byKey(const Key('chat-back')), findsNothing);
    expect(find.byKey(const Key('chat-book')), findsNothing);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpList(WidgetTester tester, ChatListCubit cubit) async {
  final auth = _AuthCubit();
  whenListen(
    auth,
    const Stream<AuthState>.empty(),
    initialState: const AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser(
        id: coachId,
        email: 'coach@example.com',
        roles: ['trainer'],
        permissions: [],
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<ChatListCubit>.value(value: cubit),
        ],
        child: ChatListView(
          title: 'Чаты',
          searchHint: 'Поиск по ученикам',
          clock: () => _now,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpThread(
  WidgetTester tester,
  ChatThreadCubit cubit, {
  bool showBack = true,
  String me = coachId,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: BlocProvider<ChatThreadCubit>.value(
        value: cubit,
        child: ChatThreadView(
          myUserId: me,
          showBack: showBack,
          clock: () => _now,
        ),
      ),
    ),
  );
  await tester.pump();
}
