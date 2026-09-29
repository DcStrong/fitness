import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/booking_requests/data/booking_request_models.dart';
import 'package:fitness_app/features/booking_requests/data/booking_requests_repository.dart';
import 'package:fitness_app/features/booking_requests/presentation/cubit/student_requests_cubit.dart';
import 'package:fitness_app/features/booking_requests/presentation/cubit/trainer_inbox_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements BookingRequestsRepository {}

void main() {
  late _Repository repository;
  setUpAll(() => registerFallbackValue(DateTime.utc(2026)));
  setUp(() => repository = _Repository());

  blocTest<StudentRequestsCubit, StudentRequestsState>(
    'student load exposes empty state',
    setUp: () => when(() => repository.listMine()).thenAnswer(
      (_) async => const BookingRequestPage(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 0,
      ),
    ),
    build: () => StudentRequestsCubit(repository: repository),
    act: (cubit) => cubit.load(),
    expect: () => const [
      StudentRequestsState(status: StudentRequestsStatus.loading),
      StudentRequestsState(status: StudentRequestsStatus.empty),
    ],
  );

  blocTest<StudentRequestsCubit, StudentRequestsState>(
    'student create surfaces a conflict without losing list',
    setUp: () => when(
      () => repository.create('slot'),
    ).thenThrow(ApiException('Это время уже занято другой заявкой')),
    build: () => StudentRequestsCubit(repository: repository),
    act: (cubit) => cubit.create('slot'),
    expect: () => const [
      StudentRequestsState(status: StudentRequestsStatus.submitting),
      StudentRequestsState(
        status: StudentRequestsStatus.conflict,
        message: 'Это время уже занято другой заявкой',
      ),
    ],
  );

  blocTest<TrainerInboxCubit, TrainerInboxState>(
    'trainer accept replaces request and clears processing marker',
    setUp: () => when(
      () => repository.accept('request'),
    ).thenAnswer((_) async => _request(BookingRequestStatus.accepted)),
    seed: () => TrainerInboxState(
      status: TrainerInboxStatus.success,
      items: [_request(BookingRequestStatus.pending)],
    ),
    build: () => TrainerInboxCubit(repository: repository),
    act: (cubit) => cubit.accept('request'),
    expect: () => [
      TrainerInboxState(
        status: TrainerInboxStatus.submitting,
        items: [_request(BookingRequestStatus.pending)],
        processingId: 'request',
      ),
      TrainerInboxState(
        status: TrainerInboxStatus.success,
        items: [_request(BookingRequestStatus.accepted)],
        message: 'Заявка принята',
      ),
    ],
  );

  blocTest<TrainerInboxCubit, TrainerInboxState>(
    'trainer alternate surfaces conflict and keeps request pending',
    setUp: () => when(() => repository.alternate('request', any())).thenThrow(
      ApiException('Выбранное время пересекается с другой тренировкой'),
    ),
    seed: () => TrainerInboxState(
      status: TrainerInboxStatus.success,
      items: [_request(BookingRequestStatus.pending)],
    ),
    build: () => TrainerInboxCubit(repository: repository),
    act: (cubit) => cubit.alternate('request', DateTime.utc(2026, 7, 22, 10)),
    expect: () => [
      TrainerInboxState(
        status: TrainerInboxStatus.submitting,
        items: [_request(BookingRequestStatus.pending)],
        processingId: 'request',
      ),
      TrainerInboxState(
        status: TrainerInboxStatus.failure,
        items: [_request(BookingRequestStatus.pending)],
        message: 'Выбранное время пересекается с другой тренировкой',
      ),
    ],
  );

  blocTest<TrainerInboxCubit, TrainerInboxState>(
    'trainer alternate replaces request after success',
    setUp: () => when(
      () => repository.alternate('request', any()),
    ).thenAnswer((_) async => _request(BookingRequestStatus.accepted)),
    seed: () => TrainerInboxState(
      status: TrainerInboxStatus.success,
      items: [_request(BookingRequestStatus.pending)],
    ),
    build: () => TrainerInboxCubit(repository: repository),
    act: (cubit) => cubit.alternate('request', DateTime.utc(2026, 7, 22, 10)),
    expect: () => [
      TrainerInboxState(
        status: TrainerInboxStatus.submitting,
        items: [_request(BookingRequestStatus.pending)],
        processingId: 'request',
      ),
      TrainerInboxState(
        status: TrainerInboxStatus.success,
        items: [_request(BookingRequestStatus.accepted)],
        message: 'Другое время назначено',
      ),
    ],
  );
}

BookingRequest _request(BookingRequestStatus status) => BookingRequest(
  id: 'request',
  coachId: 'coach',
  studentId: 'student',
  scheduleSlotId: 'slot',
  status: status,
  quotedPriceMinor: '250000',
  quotedCurrency: 'RUB',
  expiresAt: DateTime.utc(2026, 7, 20),
  requestedSlot: BookingRequestSlotSummary(
    id: 'slot',
    startsAt: DateTime.utc(2026, 7, 21),
    endsAt: DateTime.utc(2026, 7, 21, 1),
    mode: 'offline',
  ),
  counterpart: const BookingRequestCounterpart(id: 'student', label: 'Ученик'),
  createdAt: DateTime.utc(2026, 7, 19),
  updatedAt: DateTime.utc(2026, 7, 19),
);
