import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/social/data/social_models.dart';
import 'package:fitness_app/features/social/data/social_repository.dart';
import 'package:fitness_app/features/social/presentation/bloc/trainers_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SocialRepositoryMock extends Mock implements SocialRepository {}

void main() {
  late SocialRepository repository;

  setUp(() {
    repository = _SocialRepositoryMock();
    when(() => repository.changes).thenAnswer((_) => const Stream.empty());
  });

  blocTest<TrainersBloc, TrainersState>(
    'loads first discovery page',
    setUp: () {
      when(
        () => repository.discoverTrainers(
          page: 1,
          query: '',
          specialty: '',
          mode: null,
          gymId: null,
          district: '',
          gymQuery: '',
        ),
      ).thenAnswer(
        (_) async => const TrainerDiscoveryPage(
          items: [PublicTrainer(id: '1', displayName: 'Анна')],
          meta: PageMeta(page: 1, limit: 20, total: 1, totalPages: 1),
        ),
      );
    },
    build: () => TrainersBloc(repository: repository),
    act: (bloc) => bloc.add(const TrainersStarted()),
    expect: () => [
      isA<TrainersState>().having(
        (state) => state.status,
        'status',
        TrainersStatus.loading,
      ),
      isA<TrainersState>()
          .having((state) => state.status, 'status', TrainersStatus.ready)
          .having((state) => state.items.single.displayName, 'name', 'Анна'),
    ],
  );

  blocTest<TrainersBloc, TrainersState>(
    'keeps loaded items when next page fails',
    setUp: () {
      when(
        () => repository.discoverTrainers(
          page: 2,
          query: '',
          specialty: '',
          mode: null,
          gymId: null,
          district: '',
          gymQuery: '',
        ),
      ).thenThrow(Exception('offline'));
    },
    seed: () => const TrainersState(
      status: TrainersStatus.ready,
      items: [PublicTrainer(id: '1', displayName: 'Анна')],
      page: 1,
      totalPages: 2,
    ),
    build: () => TrainersBloc(repository: repository),
    act: (bloc) => bloc.add(const TrainersNextPageRequested()),
    expect: () => [
      isA<TrainersState>().having(
        (state) => state.loadingMore,
        'loading more',
        true,
      ),
      isA<TrainersState>()
          .having((state) => state.loadingMore, 'loading more', false)
          .having((state) => state.items.length, 'items', 1)
          .having((state) => state.error, 'error', contains('offline')),
    ],
  );
}
