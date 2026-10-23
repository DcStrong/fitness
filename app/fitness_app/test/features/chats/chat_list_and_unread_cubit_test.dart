import 'package:fitness_app/features/chats/presentation/cubit/chat_list_cubit.dart';
import 'package:fitness_app/features/chats/presentation/cubit/chat_unread_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'chat_test_helpers.dart';

void main() {
  late MockChatsRepository repository;
  late FakeChatRealtime realtime;

  setUp(() {
    repository = MockChatsRepository();
    realtime = FakeChatRealtime();
  });

  test('list reloads when a live message arrives', () async {
    var calls = 0;
    when(() => repository.list(query: any(named: 'query'))).thenAnswer((
      _,
    ) async {
      calls++;
      return [conversation(unread: calls)];
    });
    final cubit = ChatListCubit(
      repository: repository,
      realtime: realtime,
      refreshDebounce: Duration.zero,
    );
    await cubit.load();
    expect(cubit.state.conversations.single.unreadCount, 1);

    realtime.messagesController.add(textMessage('m9', studentId, 'ещё'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.conversations.single.unreadCount, 2);
    await cubit.close();
  });

  test('search passes the query to the API', () async {
    when(
      () => repository.list(query: any(named: 'query')),
    ).thenAnswer((_) async => []);
    final cubit = ChatListCubit(repository: repository, realtime: realtime);
    await cubit.load();

    await cubit.search('мар');

    verify(() => repository.list(query: 'мар')).called(1);
    expect(cubit.state.query, 'мар');
    await cubit.close();
  });

  test('unread badge starts the socket and follows events', () async {
    var total = 3;
    when(() => repository.unreadCount()).thenAnswer((_) async => total);
    final cubit = ChatUnreadCubit(
      repository: repository,
      realtime: realtime,
      refreshDebounce: Duration.zero,
    );

    cubit.start();
    await Future<void>.delayed(Duration.zero);
    expect(realtime.starts, 1);
    expect(cubit.state, 3);

    total = 0;
    realtime.connectedController.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state, 0);

    await cubit.stop();
    expect(realtime.stops, 1);
    await cubit.close();
  });
}
