import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/auth/data/auth_models.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/schedule/domain/calendar_events.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/session_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  testWidgets('SessionActionsSheet offers complete and history', (
    tester,
  ) async {
    final schedule = _MockScheduleRepository();
    final auth = _MockAuthCubit();
    when(() => auth.state).thenReturn(
      AuthState(
        status: AuthStatus.authenticated,
        user: AuthUser(
          id: 'coach',
          email: 'c@test.com',
          roles: const ['trainer'],
          permissions: const [
            'sessions:complete',
            'sessions:cancel',
            'sessions:mark_no_show',
            'sessions:read_history',
          ],
        ),
      ),
    );

    final event = CalendarEvent(
      id: 'session:s1',
      type: CalendarEventType.session,
      startsAt: DateTime(2026, 8, 8, 10),
      endsAt: DateTime(2026, 8, 8, 11),
      title: 'olga@test.com',
      secondaryLabel: 'Тренировка',
      mode: 'offline',
      sessionId: 's1',
      sessionStatus: 'booked',
    );

    SessionSheetResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ScheduleRepository>.value(value: schedule),
          ],
          child: BlocProvider<AuthCubit>.value(
            value: auth,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () async {
                      result = await SessionActionsSheet.show(
                        context,
                        event: event,
                      );
                    },
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Проведена'), findsOneWidget);
    expect(find.text('Отменить'), findsOneWidget);
    expect(find.text('Неявка'), findsOneWidget);
    expect(find.byKey(const Key('session-action-history')), findsOneWidget);
    expect(result, isNull);
  });
}
