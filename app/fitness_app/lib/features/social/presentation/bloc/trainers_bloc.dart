import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/social_models.dart';
import '../../data/social_repository.dart';

sealed class TrainersEvent extends Equatable {
  const TrainersEvent();

  @override
  List<Object?> get props => [];
}

class TrainersStarted extends TrainersEvent {
  const TrainersStarted();
}

class TrainersFiltersChanged extends TrainersEvent {
  const TrainersFiltersChanged({
    this.query,
    this.specialty,
    this.mode,
    this.district,
    this.gymQuery,
    this.gym,
  });

  final String? query;
  final String? specialty;
  final String? mode;
  final String? district;
  final String? gymQuery;

  /// Выбранный зал (фильтр по `gymId`); `null` сбрасывает фильтр.
  final Gym? gym;

  @override
  List<Object?> get props => [query, specialty, mode, district, gymQuery, gym];
}

class TrainersNextPageRequested extends TrainersEvent {
  const TrainersNextPageRequested();
}

class TrainersRetryRequested extends TrainersEvent {
  const TrainersRetryRequested();
}

enum TrainersStatus { initial, loading, ready, failure }

class TrainersState extends Equatable {
  const TrainersState({
    this.status = TrainersStatus.initial,
    this.items = const [],
    this.query = '',
    this.specialty = '',
    this.mode,
    this.district = '',
    this.gymQuery = '',
    this.gym,
    this.page = 0,
    this.totalPages = 0,
    this.loadingMore = false,
    this.error,
  });

  final TrainersStatus status;
  final List<PublicTrainer> items;
  final String query;
  final String specialty;
  final String? mode;
  final String district;
  final String gymQuery;
  final Gym? gym;
  final int page;
  final int totalPages;
  final bool loadingMore;
  final String? error;

  bool get hasNext => page < totalPages;

  TrainersState copyWith({
    TrainersStatus? status,
    List<PublicTrainer>? items,
    String? query,
    String? specialty,
    String? mode,
    bool clearMode = false,
    String? district,
    String? gymQuery,
    Gym? gym,
    bool clearGym = false,
    int? page,
    int? totalPages,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) => TrainersState(
    status: status ?? this.status,
    items: items ?? this.items,
    query: query ?? this.query,
    specialty: specialty ?? this.specialty,
    mode: clearMode ? null : mode ?? this.mode,
    district: district ?? this.district,
    gymQuery: gymQuery ?? this.gymQuery,
    gym: clearGym ? null : gym ?? this.gym,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    query,
    specialty,
    mode,
    district,
    gymQuery,
    gym,
    page,
    totalPages,
    loadingMore,
    error,
  ];
}

class TrainersBloc extends Bloc<TrainersEvent, TrainersState> {
  TrainersBloc({required SocialRepository repository})
    : _repository = repository,
      super(const TrainersState()) {
    on<TrainersStarted>(_onStarted);
    on<TrainersFiltersChanged>(_onFiltersChanged);
    on<TrainersNextPageRequested>(_onNextPage);
    on<TrainersRetryRequested>(_onRetry);
    _changesSubscription = repository.changes.listen(
      (_) => add(const TrainersRetryRequested()),
    );
  }

  final SocialRepository _repository;
  late final StreamSubscription<void> _changesSubscription;

  @override
  Future<void> close() async {
    await _changesSubscription.cancel();
    return super.close();
  }

  Future<void> _onStarted(TrainersStarted event, Emitter<TrainersState> emit) =>
      _loadFirst(emit);

  Future<void> _onFiltersChanged(
    TrainersFiltersChanged event,
    Emitter<TrainersState> emit,
  ) async {
    emit(
      state.copyWith(
        query: event.query ?? state.query,
        specialty: event.specialty ?? state.specialty,
        mode: event.mode,
        clearMode: event.mode == null,
        district: event.district,
        gymQuery: event.gymQuery,
        gym: event.gym,
        clearGym: event.gym == null,
      ),
    );
    await _loadFirst(emit);
  }

  Future<void> _onRetry(
    TrainersRetryRequested event,
    Emitter<TrainersState> emit,
  ) => _loadFirst(emit);

  Future<void> _onNextPage(
    TrainersNextPageRequested event,
    Emitter<TrainersState> emit,
  ) async {
    if (!state.hasNext || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true, clearError: true));
    try {
      final result = await _fetch(state.page + 1);
      emit(
        state.copyWith(
          status: TrainersStatus.ready,
          items: [...state.items, ...result.items],
          page: result.meta.page,
          totalPages: result.meta.totalPages,
          loadingMore: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(loadingMore: false, error: error.toString()));
    }
  }

  Future<void> _loadFirst(Emitter<TrainersState> emit) async {
    emit(
      state.copyWith(
        status: TrainersStatus.loading,
        items: const [],
        page: 0,
        totalPages: 0,
        clearError: true,
      ),
    );
    try {
      final result = await _fetch(1);
      emit(
        state.copyWith(
          status: TrainersStatus.ready,
          items: result.items,
          page: result.meta.page,
          totalPages: result.meta.totalPages,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: TrainersStatus.failure, error: error.toString()),
      );
    }
  }

  Future<TrainerDiscoveryPage> _fetch(int page) => _repository.discoverTrainers(
    page: page,
    query: state.query,
    specialty: state.specialty,
    mode: state.mode,
    gymId: state.gym?.id,
    district: state.district,
    gymQuery: state.gymQuery,
  );
}
