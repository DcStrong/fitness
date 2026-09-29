import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/schedule/data/availability_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_repository.dart';
import 'package:fitness_app/features/schedule/presentation/cubit/availability_editor_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late _MockScheduleRepository repository;

  final settings = CoachScheduleSettings.fromJson(const {
    'coachId': 'c1',
    'timezone': 'Europe/Moscow',
    'defaultDurationMinutes': 60,
    'breakMinutes': 15,
    'horizonWeeks': 2,
    'defaultMode': 'offline',
    'updatedAt': '2026-07-21T00:00:00.000Z',
  });

  setUpAll(() {
    registerFallbackValue(CoachScheduleSettings.defaults());
    registerFallbackValue(const <AvailabilityWindow>[]);
    registerFallbackValue(const <AvailabilityExceptionItem>[]);
  });

  setUp(() {
    repository = _MockScheduleRepository();
    when(
      () => repository.previewAvailability(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => const []);
  });

  AvailabilityEditorCubit buildCubit() =>
      AvailabilityEditorCubit(scheduleRepository: repository);

  blocTest<AvailabilityEditorCubit, AvailabilityEditorState>(
    'load fetches settings, template and exceptions',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.getAvailabilitySettings(),
      ).thenAnswer((_) async => settings);
      when(() => repository.getAvailabilityTemplate()).thenAnswer(
        (_) async => const AvailabilityTemplate(
          seriesId: 's1',
          coachId: 'c1',
          windows: [
            AvailabilityWindow(dayOfWeek: 1, startMinute: 540, endMinute: 780),
          ],
        ),
      );
      when(
        () => repository.listAvailabilityExceptions(),
      ).thenAnswer((_) async => const []);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AvailabilityEditorState>().having(
        (s) => s.status,
        'status',
        AvailabilityEditorStatus.loading,
      ),
      isA<AvailabilityEditorState>()
          .having((s) => s.status, 'status', AvailabilityEditorStatus.ready)
          .having((s) => s.windows, 'windows', hasLength(1))
          .having((s) => s.seriesId, 'seriesId', 's1'),
    ],
  );

  blocTest<AvailabilityEditorCubit, AvailabilityEditorState>(
    'copySelectedDayToAllDays copies Monday windows to Mon–Sun',
    build: buildCubit,
    seed: () => AvailabilityEditorState(
      status: AvailabilityEditorStatus.ready,
      settings: settings,
      selectedDayOfWeek: 1,
      windows: const [
        AvailabilityWindow(dayOfWeek: 1, startMinute: 540, endMinute: 780),
        AvailabilityWindow(dayOfWeek: 6, startMinute: 600, endMinute: 720),
      ],
    ),
    act: (cubit) => cubit.copySelectedDayToAllDays(),
    verify: (cubit) {
      final days = cubit.state.windows.map((w) => w.dayOfWeek).toSet();
      expect(days, {1, 2, 3, 4, 5, 6, 7});
      expect(
        cubit.state.windows.where((w) => w.dayOfWeek == 2).single.startMinute,
        540,
      );
      expect(
        cubit.state.windows.where((w) => w.dayOfWeek == 7).single.startMinute,
        540,
      );
      expect(
        cubit.state.windows.where((w) => w.dayOfWeek == 6).single.startMinute,
        540,
      );
    },
  );

  blocTest<AvailabilityEditorCubit, AvailabilityEditorState>(
    'generate success stores summary',
    build: buildCubit,
    seed: () => AvailabilityEditorState(
      status: AvailabilityEditorStatus.ready,
      settings: settings,
      windows: const [
        AvailabilityWindow(dayOfWeek: 1, startMinute: 540, endMinute: 780),
      ],
    ),
    setUp: () {
      when(
        () => repository.upsertAvailabilitySettings(any()),
      ).thenAnswer((_) async => settings);
      when(() => repository.upsertAvailabilityTemplate(any())).thenAnswer(
        (_) async => AvailabilityTemplate(
          seriesId: 's1',
          coachId: 'c1',
          windows: const [
            AvailabilityWindow(dayOfWeek: 1, startMinute: 540, endMinute: 780),
          ],
        ),
      );
      when(
        () => repository.replaceAvailabilityExceptions(any()),
      ).thenAnswer((_) async => const []);
      when(() => repository.generateAvailability()).thenAnswer(
        (_) async => const GenerateAvailabilitySummary(
          created: 5,
          skippedExisting: 0,
          skippedConflict: 0,
          removedOrphanOpen: 0,
        ),
      );
    },
    act: (cubit) => cubit.generate(),
    expect: () => [
      isA<AvailabilityEditorState>().having(
        (s) => s.status,
        'status',
        AvailabilityEditorStatus.generating,
      ),
      isA<AvailabilityEditorState>()
          .having((s) => s.status, 'status', AvailabilityEditorStatus.ready)
          .having((s) => s.lastGenerateSummary?.created, 'created', 5),
    ],
  );

  blocTest<AvailabilityEditorCubit, AvailabilityEditorState>(
    'generate failure surfaces Russian error',
    build: buildCubit,
    seed: () => AvailabilityEditorState(
      status: AvailabilityEditorStatus.ready,
      settings: settings,
    ),
    setUp: () {
      when(
        () => repository.upsertAvailabilitySettings(any()),
      ).thenAnswer((_) async => settings);
      when(() => repository.upsertAvailabilityTemplate(any())).thenAnswer(
        (_) async => const AvailabilityTemplate(
          seriesId: '',
          coachId: 'c1',
          windows: [],
        ),
      );
      when(
        () => repository.replaceAvailabilityExceptions(any()),
      ).thenAnswer((_) async => const []);
      when(
        () => repository.generateAvailability(),
      ).thenThrow(ApiException('Шаблон не найден', statusCode: 404));
    },
    act: (cubit) => cubit.generate(),
    expect: () => [
      isA<AvailabilityEditorState>().having(
        (s) => s.status,
        'status',
        AvailabilityEditorStatus.generating,
      ),
      isA<AvailabilityEditorState>()
          .having((s) => s.status, 'status', AvailabilityEditorStatus.failure)
          .having((s) => s.errorMessage, 'error', 'Шаблон не найден'),
    ],
  );
}
