import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/booking_requests/data/booking_request_models.dart';
import 'package:fitness_app/features/booking_requests/presentation/cubit/student_requests_cubit.dart';
import 'package:fitness_app/features/booking_requests/presentation/cubit/trainer_inbox_cubit.dart';
import 'package:fitness_app/features/booking_requests/presentation/student_requests_page.dart';
import 'package:fitness_app/features/booking_requests/presentation/trainer_inbox_page.dart';
import 'package:fitness_app/features/booking_requests/presentation/booking_request_detail_page.dart';
import 'package:fitness_app/features/booking_requests/data/booking_requests_repository.dart';
import 'package:fitness_app/features/auth/data/auth_models.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fitness_app/features/social/data/social_models.dart';
import 'package:fitness_app/features/social/data/social_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _StudentCubit extends MockCubit<StudentRequestsState>
    implements StudentRequestsCubit {}

class _TrainerCubit extends MockCubit<TrainerInboxState>
    implements TrainerInboxCubit {}

class _SocialRepository extends Mock implements SocialRepository {}

class _AuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _BookingRepository extends Mock implements BookingRequestsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(BookingRequestRejectionReason.other);
  });

  for (final viewport in const [
    (name: 'compact', size: Size(320, 700)),
    (name: 'standard', size: Size(390, 844)),
  ]) {
    testWidgets(
      'student pending actions fit ${viewport.name} ${viewport.size.width.toInt()}x${viewport.size.height.toInt()}',
      (tester) async {
        _setViewport(tester, viewport.size);
        final cubit = _StudentCubit();
        whenListen(
          cubit,
          const Stream<StudentRequestsState>.empty(),
          initialState: StudentRequestsState(
            status: StudentRequestsStatus.success,
            items: [_request(BookingRequestStatus.pending)],
          ),
        );

        await _pumpStudent(tester, cubit);
        await tester.pumpAndSettle();

        expect(find.text('Ожидает тренера'), findsOneWidget);
        expect(find.text('Отозвать заявку'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'trainer pending actions fit ${viewport.name} ${viewport.size.width.toInt()}x${viewport.size.height.toInt()}',
      (tester) async {
        _setViewport(tester, viewport.size);
        final cubit = _TrainerCubit();
        whenListen(
          cubit,
          const Stream<TrainerInboxState>.empty(),
          initialState: TrainerInboxState(
            status: TrainerInboxStatus.success,
            items: [_request(BookingRequestStatus.pending)],
          ),
        );

        await _pumpTrainer(tester, cubit, _SocialRepository());
        await tester.pumpAndSettle();

        expect(find.text('Принять'), findsOneWidget);
        expect(find.text('Отклонить'), findsOneWidget);
        expect(find.text('Другое время'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('alternate sheet fits compact 320x700 viewport', (tester) async {
    _setViewport(tester, const Size(320, 700));
    final cubit = _TrainerCubit();
    final social = _SocialRepository();
    whenListen(
      cubit,
      const Stream<TrainerInboxState>.empty(),
      initialState: TrainerInboxState(
        status: TrainerInboxStatus.success,
        items: [_request(BookingRequestStatus.pending)],
      ),
    );
    when(() => social.getLinkedContacts('student')).thenAnswer(
      (_) async => const LinkedContacts(
        userId: 'student',
        email: 'student@example.com',
        preferredContactChannels: [PreferredContactChannel.email],
      ),
    );

    await _pumpTrainer(tester, cubit, social);
    await tester.tap(find.text('Другое время'));
    await tester.pumpAndSettle();

    expect(find.text('Согласуйте другое время'), findsOneWidget);
    expect(find.text('Email: student@example.com'), findsOneWidget);
    expect(find.text('Назначить это время'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student renders terminal states and rejection feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = _StudentCubit();
    final items = [
      _request(BookingRequestStatus.accepted, id: 'accepted', session: true),
      _request(
        BookingRequestStatus.rejected,
        id: 'rejected',
        reason: BookingRequestRejectionReason.plansChanged,
        comment: 'Буду в отъезде',
      ),
      _request(BookingRequestStatus.withdrawn, id: 'withdrawn'),
      _request(BookingRequestStatus.expired, id: 'expired'),
      _request(
        BookingRequestStatus.accepted,
        id: 'alternate',
        resolution: BookingRequestResolution.alternateSlot,
      ),
    ];
    whenListen(
      cubit,
      const Stream<StudentRequestsState>.empty(),
      initialState: StudentRequestsState(
        status: StudentRequestsStatus.success,
        items: items,
      ),
    );

    await _pumpStudent(tester, cubit);

    expect(find.text('Принята'), findsNWidgets(2));
    expect(find.text('Отклонена'), findsOneWidget);
    expect(find.text('Причина: Планы изменились'), findsOneWidget);
    expect(find.text('Буду в отъезде'), findsOneWidget);
    expect(find.text('Отозвана'), findsOneWidget);
    expect(find.text('Истекла'), findsOneWidget);
    expect(
      find.text('Тренер назначил согласованное другое время.'),
      findsOneWidget,
    );
    expect(find.textContaining('встречн'), findsNothing);
  });

  testWidgets('student confirms pending withdrawal', (tester) async {
    final cubit = _StudentCubit();
    whenListen(
      cubit,
      const Stream<StudentRequestsState>.empty(),
      initialState: StudentRequestsState(
        status: StudentRequestsStatus.success,
        items: [_request(BookingRequestStatus.pending)],
      ),
    );
    when(() => cubit.withdraw('request')).thenAnswer((_) async => true);

    await _pumpStudent(tester, cubit);
    await tester.tap(find.text('Отозвать заявку'));
    await tester.pumpAndSettle();
    expect(find.text('Отозвать заявку?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Отозвать'));
    await tester.pump();

    verify(() => cubit.withdraw('request')).called(1);
  });

  testWidgets('student conflict is shown as Russian feedback', (tester) async {
    final cubit = _StudentCubit();
    whenListen(
      cubit,
      Stream.value(
        const StudentRequestsState(
          status: StudentRequestsStatus.conflict,
          message: 'Это время уже занято другой заявкой',
        ),
      ),
      initialState: const StudentRequestsState(
        status: StudentRequestsStatus.empty,
      ),
    );

    await _pumpStudent(tester, cubit);
    await tester.pump();

    expect(find.text('Это время уже занято другой заявкой'), findsOneWidget);
  });

  testWidgets('trainer accepts and rejects with bounded feedback', (
    tester,
  ) async {
    final cubit = _TrainerCubit();
    whenListen(
      cubit,
      const Stream<TrainerInboxState>.empty(),
      initialState: TrainerInboxState(
        status: TrainerInboxStatus.success,
        items: [_request(BookingRequestStatus.pending)],
      ),
    );
    when(() => cubit.accept('request')).thenAnswer((_) async => true);
    when(
      () => cubit.reject(
        'request',
        reason: any(named: 'reason'),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer((_) async => true);

    await _pumpTrainer(tester, cubit, _SocialRepository());
    await tester.tap(find.text('Принять'));
    verify(() => cubit.accept('request')).called(1);

    await tester.tap(find.text('Отклонить'));
    await tester.pumpAndSettle();
    expect(find.text('Причина'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, 500);
    await tester.enterText(find.byType(TextField), 'Не смогу провести');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(OutlinedButton, 'Отклонить'),
      ),
    );
    await tester.pump();

    verify(
      () => cubit.reject(
        'request',
        reason: BookingRequestRejectionReason.timeUnavailable,
        comment: 'Не смогу провести',
      ),
    ).called(1);
  });

  testWidgets('alternate shows email fallback and no counter proposal', (
    tester,
  ) async {
    final cubit = _TrainerCubit();
    final social = _SocialRepository();
    whenListen(
      cubit,
      const Stream<TrainerInboxState>.empty(),
      initialState: TrainerInboxState(
        status: TrainerInboxStatus.success,
        items: [_request(BookingRequestStatus.pending)],
      ),
    );
    when(() => social.getLinkedContacts('student')).thenAnswer(
      (_) async => const LinkedContacts(
        userId: 'student',
        email: 'student@example.com',
        preferredContactChannels: [PreferredContactChannel.email],
      ),
    );

    await _pumpTrainer(tester, cubit, social);
    await tester.tap(find.text('Другое время'));
    await tester.pumpAndSettle();

    expect(find.text('Email: student@example.com'), findsOneWidget);
    expect(
      find.textContaining('подтверждение ученика не потребуется'),
      findsOneWidget,
    );
    final submit = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Назначить это время'),
    );
    expect(submit.onPressed, isNull);
    expect(find.textContaining('встречное предложение'), findsNothing);
  });

  testWidgets('detail experience exposes only role-appropriate action', (
    tester,
  ) async {
    final auth = _AuthCubit();
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: AuthUser(
          id: 'student',
          email: 'student@example.com',
          roles: ['student'],
          permissions: [],
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<BookingRequestsRepository>.value(
          value: _BookingRepository(),
          child: BlocProvider<AuthCubit>.value(
            value: auth,
            child: BookingRequestDetailPage(
              request: _request(BookingRequestStatus.pending),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Отозвать заявку'), findsOneWidget);
    expect(find.text('Принять'), findsNothing);
    expect(find.text('Другое время'), findsNothing);
  });
}

Future<void> _pumpStudent(WidgetTester tester, StudentRequestsCubit cubit) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<StudentRequestsCubit>.value(
          value: cubit,
          child: const StudentRequestsView(),
        ),
      ),
    );

Future<void> _pumpTrainer(
  WidgetTester tester,
  TrainerInboxCubit cubit,
  SocialRepository social,
) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: RepositoryProvider<SocialRepository>.value(
      value: social,
      child: BlocProvider<TrainerInboxCubit>.value(
        value: cubit,
        child: const TrainerInboxView(),
      ),
    ),
  ),
);

BookingRequest _request(
  BookingRequestStatus status, {
  String id = 'request',
  bool session = false,
  BookingRequestRejectionReason? reason,
  String? comment,
  BookingRequestResolution? resolution,
}) => BookingRequest(
  id: id,
  coachId: 'coach',
  studentId: 'student',
  scheduleSlotId: 'slot',
  status: status,
  quotedPriceMinor: '250000',
  quotedCurrency: 'RUB',
  expiresAt: DateTime.utc(2026, 7, 20),
  rejectionReason: reason,
  rejectionComment: comment,
  resolution: resolution,
  sessionId: session ? 'session' : null,
  requestedSlot: BookingRequestSlotSummary(
    id: 'slot',
    startsAt: DateTime.utc(2026, 7, 21, 10),
    endsAt: DateTime.utc(2026, 7, 21, 11),
    mode: 'offline',
  ),
  resolvedSlot: resolution == BookingRequestResolution.alternateSlot
      ? BookingRequestSlotSummary(
          id: 'alternate-slot',
          startsAt: DateTime.utc(2026, 7, 22, 10),
          endsAt: DateTime.utc(2026, 7, 22, 11),
          mode: 'offline',
        )
      : null,
  counterpart: const BookingRequestCounterpart(id: 'student', label: 'Ученик'),
  createdAt: DateTime.utc(2026, 7, 19),
  updatedAt: DateTime.utc(2026, 7, 19),
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
