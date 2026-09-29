import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/invitations/data/invitation_models.dart';
import 'package:fitness_app/features/invitations/data/invitations_repository.dart';
import 'package:fitness_app/features/schedule/data/recurring_booking_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/schedule/presentation/cubit/recurring_booking_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockInvitationsRepository extends Mock
    implements InvitationsRepository {}

void main() {
  late _MockScheduleRepository schedule;
  late _MockInvitationsRepository invitations;

  final booking = RecurringBooking.fromJson(const {
    'id': 'rb1',
    'coachId': 'c1',
    'studentId': 's1',
    'weekdays': [1, 3, 5],
    'startMinute': 1080,
    'mode': 'offline',
    'timezone': 'Europe/Moscow',
    'status': 'active',
    'horizonWeeksOverride': null,
    'createdAt': '2026-08-04T00:00:00.000Z',
    'updatedAt': '2026-08-04T00:00:00.000Z',
    'cancelledAt': null,
  });

  final sync = RecurringSyncSummary.fromJson(const {
    'booked': 1,
    'skippedExisting': 0,
    'slotsCreated': 2,
    'conflicts': [
      {
        'localDate': '2026-08-06',
        'reason': 'missing_slot',
        'startsAt': '2026-08-06T15:00:00.000Z',
        'endsAt': '2026-08-06T16:00:00.000Z',
      },
    ],
  });

  setUp(() {
    schedule = _MockScheduleRepository();
    invitations = _MockInvitationsRepository();
  });

  RecurringBookingCubit buildCubit() => RecurringBookingCubit(
    scheduleRepository: schedule,
    invitationsRepository: invitations,
  );

  blocTest<RecurringBookingCubit, RecurringBookingState>(
    'create сохраняет booking и sync с конфликтами',
    build: buildCubit,
    setUp: () {
      when(
        () => schedule.createRecurringBooking(
          studentId: any(named: 'studentId'),
          weekdays: any(named: 'weekdays'),
          startMinute: any(named: 'startMinute'),
          mode: any(named: 'mode'),
          horizonWeeksOverride: any(named: 'horizonWeeksOverride'),
        ),
      ).thenAnswer(
        (_) async => CreateRecurringBookingResult(booking: booking, sync: sync),
      );
    },
    act: (cubit) => cubit.create(
      studentId: 's1',
      weekdays: const [1, 3, 5],
      startMinute: 1080,
      mode: 'offline',
      horizonWeeksOverride: 8,
    ),
    expect: () => [
      isA<RecurringBookingState>().having(
        (s) => s.status,
        'status',
        RecurringBookingStatus.saving,
      ),
      isA<RecurringBookingState>()
          .having((s) => s.status, 'status', RecurringBookingStatus.ready)
          .having((s) => s.selected?.id, 'selected', 'rb1')
          .having((s) => s.lastSync?.conflicts, 'conflicts', hasLength(1))
          .having((s) => s.lastSync?.slotsCreated, 'slotsCreated', 2),
    ],
  );

  blocTest<RecurringBookingCubit, RecurringBookingState>(
    'resolveSkip обновляет sync',
    build: buildCubit,
    seed: () => RecurringBookingState(
      status: RecurringBookingStatus.ready,
      selected: booking,
      lastSync: sync,
    ),
    setUp: () {
      when(
        () => schedule.resolveRecurringOccurrence(
          id: any(named: 'id'),
          localDate: any(named: 'localDate'),
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) async => const RecurringSyncSummary(
          booked: 0,
          skippedExisting: 1,
          conflicts: [],
        ),
      );
      when(
        () => schedule.getRecurringBooking(any()),
      ).thenAnswer((_) async => booking);
    },
    act: (cubit) => cubit.resolveSkip(id: 'rb1', localDate: '2026-08-06'),
    expect: () => [
      isA<RecurringBookingState>().having(
        (s) => s.status,
        'status',
        RecurringBookingStatus.syncing,
      ),
      isA<RecurringBookingState>()
          .having((s) => s.status, 'status', RecurringBookingStatus.ready)
          .having((s) => s.lastSync?.conflicts, 'conflicts', isEmpty),
    ],
  );

  blocTest<RecurringBookingCubit, RecurringBookingState>(
    'cancel помечает серию отменённой',
    build: buildCubit,
    seed: () => RecurringBookingState(
      status: RecurringBookingStatus.ready,
      items: [booking],
      selected: booking,
    ),
    setUp: () {
      when(() => schedule.cancelRecurringBooking(any())).thenAnswer(
        (_) async => RecurringBooking.fromJson({
          ...{
            'id': 'rb1',
            'coachId': 'c1',
            'studentId': 's1',
            'weekdays': [1, 3, 5],
            'startMinute': 1080,
            'mode': 'offline',
            'timezone': 'Europe/Moscow',
            'status': 'cancelled',
            'horizonWeeksOverride': null,
            'createdAt': '2026-08-04T00:00:00.000Z',
            'updatedAt': '2026-08-04T00:00:00.000Z',
            'cancelledAt': '2026-08-04T12:00:00.000Z',
          },
        }),
      );
    },
    act: (cubit) => cubit.cancel('rb1'),
    expect: () => [
      isA<RecurringBookingState>().having(
        (s) => s.status,
        'status',
        RecurringBookingStatus.saving,
      ),
      isA<RecurringBookingState>()
          .having((s) => s.status, 'status', RecurringBookingStatus.ready)
          .having((s) => s.selected?.status, 'status', 'cancelled'),
    ],
  );

  blocTest<RecurringBookingCubit, RecurringBookingState>(
    'create пишет failure при ApiException',
    build: buildCubit,
    setUp: () {
      when(
        () => schedule.createRecurringBooking(
          studentId: any(named: 'studentId'),
          weekdays: any(named: 'weekdays'),
          startMinute: any(named: 'startMinute'),
          mode: any(named: 'mode'),
          horizonWeeksOverride: any(named: 'horizonWeeksOverride'),
        ),
      ).thenThrow(ApiException('Нет связи тренер ↔ ученик'));
    },
    act: (cubit) => cubit.create(
      studentId: 's1',
      weekdays: const [1],
      startMinute: 600,
      mode: 'offline',
      horizonWeeksOverride: 4,
    ),
    expect: () => [
      isA<RecurringBookingState>().having(
        (s) => s.status,
        'status',
        RecurringBookingStatus.saving,
      ),
      isA<RecurringBookingState>()
          .having((s) => s.status, 'status', RecurringBookingStatus.failure)
          .having((s) => s.errorMessage, 'error', 'Нет связи тренер ↔ ученик'),
    ],
  );

  blocTest<RecurringBookingCubit, RecurringBookingState>(
    'create при 409 сохраняет conflictExistingId',
    build: buildCubit,
    setUp: () {
      when(
        () => schedule.createRecurringBooking(
          studentId: any(named: 'studentId'),
          weekdays: any(named: 'weekdays'),
          startMinute: any(named: 'startMinute'),
          mode: any(named: 'mode'),
          horizonWeeksOverride: any(named: 'horizonWeeksOverride'),
        ),
      ).thenThrow(
        ApiException(
          'Такая серия уже есть',
          statusCode: 409,
          existingId: 'existing-rb',
        ),
      );
    },
    act: (cubit) => cubit.create(
      studentId: 's1',
      weekdays: const [6],
      startMinute: 600,
      mode: 'offline',
    ),
    expect: () => [
      isA<RecurringBookingState>().having(
        (s) => s.status,
        'status',
        RecurringBookingStatus.saving,
      ),
      isA<RecurringBookingState>()
          .having((s) => s.status, 'status', RecurringBookingStatus.failure)
          .having((s) => s.conflictExistingId, 'conflict', 'existing-rb')
          .having((s) => s.errorMessage, 'error', 'Такая серия уже есть'),
    ],
  );

  blocTest<RecurringBookingCubit, RecurringBookingState>(
    'restore поднимает серию и sync',
    build: buildCubit,
    seed: () => RecurringBookingState(
      status: RecurringBookingStatus.ready,
      selected: RecurringBooking.fromJson({
        ...{
          'id': 'rb1',
          'coachId': 'c1',
          'studentId': 's1',
          'weekdays': [1, 3, 5],
          'startMinute': 1080,
          'mode': 'offline',
          'timezone': 'Europe/Moscow',
          'status': 'cancelled',
          'horizonWeeksOverride': null,
          'createdAt': '2026-08-04T00:00:00.000Z',
          'updatedAt': '2026-08-04T00:00:00.000Z',
          'cancelledAt': '2026-08-04T12:00:00.000Z',
        },
      }),
      items: [
        RecurringBooking.fromJson({
          'id': 'rb1',
          'coachId': 'c1',
          'studentId': 's1',
          'weekdays': [1, 3, 5],
          'startMinute': 1080,
          'mode': 'offline',
          'timezone': 'Europe/Moscow',
          'status': 'cancelled',
          'horizonWeeksOverride': null,
          'createdAt': '2026-08-04T00:00:00.000Z',
          'updatedAt': '2026-08-04T00:00:00.000Z',
          'cancelledAt': '2026-08-04T12:00:00.000Z',
        }),
      ],
    ),
    setUp: () {
      when(() => schedule.restoreRecurringBooking(any())).thenAnswer(
        (_) async => CreateRecurringBookingResult(booking: booking, sync: sync),
      );
    },
    act: (cubit) => cubit.restore('rb1'),
    expect: () => [
      isA<RecurringBookingState>().having(
        (s) => s.status,
        'status',
        RecurringBookingStatus.saving,
      ),
      isA<RecurringBookingState>()
          .having((s) => s.status, 'status', RecurringBookingStatus.ready)
          .having((s) => s.selected?.status, 'status', 'active')
          .having((s) => s.lastSync?.booked, 'booked', 1),
    ],
  );

  blocTest<RecurringBookingCubit, RecurringBookingState>(
    'loadCreateForm загружает связанных учеников',
    build: buildCubit,
    setUp: () {
      when(() => invitations.listRelationships()).thenAnswer(
        (_) async => const [
          RelationshipItem(
            id: 'rel1',
            coachId: 'c1',
            studentId: 's1',
            roleForViewer: 'coach',
            studentEmail: 's@example.com',
          ),
        ],
      );
    },
    act: (cubit) => cubit.loadCreateForm(),
    expect: () => [
      isA<RecurringBookingState>().having(
        (s) => s.status,
        'status',
        RecurringBookingStatus.loading,
      ),
      isA<RecurringBookingState>()
          .having((s) => s.status, 'status', RecurringBookingStatus.ready)
          .having((s) => s.students, 'students', hasLength(1)),
    ],
  );
}
