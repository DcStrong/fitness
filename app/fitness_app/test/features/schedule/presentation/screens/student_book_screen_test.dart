import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/booking_requests/data/booking_requests_repository.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:fitness_app/features/invitations/data/invitation_models.dart';
import 'package:fitness_app/features/invitations/data/invitations_repository.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/schedule/presentation/booking_format.dart';
import 'package:fitness_app/features/schedule/presentation/screens/student_book_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Invitations extends Mock implements InvitationsRepository {}

class _Schedule extends Mock implements ScheduleRepository {}

class _Requests extends Mock implements BookingRequestsRepository {}

ScheduleSlot _slot(String id, DateTime start, {String mode = 'offline'}) =>
    ScheduleSlot(
      id: id,
      coachId: 'coach-1',
      startsAt: start.toUtc().toIso8601String(),
      endsAt: start.add(const Duration(hours: 1)).toUtc().toIso8601String(),
      mode: mode,
      status: 'open',
      price: const MoneyAmount(amountMinor: '200000', currency: 'RUB'),
    );

void main() {
  late _Invitations invitations;
  late _Schedule schedule;
  late _Requests requests;

  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 10);
  final later = DateTime(now.year, now.month, now.day + 3, 12);

  setUp(() {
    invitations = _Invitations();
    schedule = _Schedule();
    requests = _Requests();
    when(() => invitations.listRelationships()).thenAnswer(
      (_) async => const [
        RelationshipItem(
          id: 'rel-1',
          coachId: 'coach-1',
          studentId: 'student-1',
          roleForViewer: 'student',
          coachDisplayName: 'Алексей Морозов',
        ),
      ],
    );
    when(() => schedule.listCoachOpenSlots('coach-1')).thenAnswer(
      (_) async => [
        _slot('slot-1', tomorrow),
        _slot('slot-2', tomorrow.add(const Duration(hours: 2)), mode: 'online'),
        _slot('slot-3', later),
      ],
    );
    when(() => requests.create(any())).thenThrow(Exception('offline'));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<InvitationsRepository>.value(value: invitations),
          RepositoryProvider<ScheduleRepository>.value(value: schedule),
          RepositoryProvider<BookingRequestsRepository>.value(value: requests),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StudentBookScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('coach, first day with slots, summary only after a pick', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Алексей Морозов'), findsOneWidget);
    expect(find.textContaining('Разовое 2'), findsOneWidget);
    expect(find.text('Свободно завтра'), findsOneWidget);
    expect(find.byKey(const Key('book-slot-slot-1')), findsOneWidget);
    expect(find.byKey(const Key('book-slot-slot-2')), findsOneWidget);
    expect(find.byKey(const Key('book-slot-slot-3')), findsNothing);
    expect(find.byKey(const Key('book-summary')), findsNothing);

    await tester.tap(find.byKey(const Key('book-slot-slot-2')));
    await tester.pump();
    expect(find.byKey(const Key('book-summary')), findsOneWidget);

    await tester.tap(find.byKey(const Key('book-submit')));
    await tester.pumpAndSettle();
    verify(() => requests.create('slot-2')).called(1);
  });

  testWidgets('another day shows its own slots', (tester) async {
    await pump(tester);
    await tester.tap(
      find.byKey(Key('book-day-${later.year}-${later.month}-${later.day}')),
    );
    await tester.pump();
    expect(find.byKey(const Key('book-slot-slot-3')), findsOneWidget);
    expect(find.byKey(const Key('book-slot-slot-1')), findsNothing);
  });

  test('day title reads naturally', () {
    final wed = DateTime(2026, 10, 21);
    expect(formatBookingDayTitle(wed, now: wed), 'Свободно сегодня');
    expect(
      formatBookingDayTitle(DateTime(2026, 10, 22), now: wed),
      'Свободно завтра',
    );
    expect(
      formatBookingDayTitle(DateTime(2026, 10, 23), now: wed),
      'Свободно в пятницу',
    );
    expect(
      formatBookingDayTitle(DateTime(2026, 10, 27), now: wed),
      'Свободно во вторник',
    );
    expect(
      formatBookingDayTitle(DateTime(2026, 11, 2), now: wed),
      'Свободно 2 ноя',
    );
    expect(
      formatBookingSummary(DateTime(2026, 10, 23, 10)),
      'Пт, 23 окт · 10:00',
    );
  });
}
