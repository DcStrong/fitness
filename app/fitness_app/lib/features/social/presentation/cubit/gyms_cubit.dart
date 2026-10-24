import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/social_models.dart';
import '../../data/social_repository.dart';

class GymsState extends Equatable {
  const GymsState({
    this.gyms = const [],
    this.suggestions = const [],
    this.saving = false,
    this.error,
  });

  final List<Gym> gyms;
  final List<Gym> suggestions;
  final bool saving;
  final String? error;

  GymsState copyWith({
    List<Gym>? gyms,
    List<Gym>? suggestions,
    bool? saving,
    String? error,
    bool clearError = false,
  }) => GymsState(
    gyms: gyms ?? this.gyms,
    suggestions: suggestions ?? this.suggestions,
    saving: saving ?? this.saving,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [gyms, suggestions, saving, error];
}

/// Залы тренера: список, добавление (новый или из подсказки), удаление.
class GymsCubit extends Cubit<GymsState> {
  GymsCubit({
    required SocialRepository repository,
    List<Gym> initial = const [],
  }) : _repository = repository,
       super(GymsState(gyms: initial));

  final SocialRepository _repository;
  int _suggestRequest = 0;

  Future<bool> add({
    required String name,
    required String address,
    required String city,
    String? district,
  }) => _attach(
    () => _repository.attachGym(
      name: name,
      address: address,
      city: city,
      district: district,
    ),
  );

  Future<bool> addSuggested(Gym gym) =>
      _attach(() => _repository.attachGym(gymId: gym.id));

  Future<void> remove(Gym gym) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repository.detachGym(gym.id);
      emit(
        state.copyWith(
          saving: false,
          gyms: state.gyms.where((item) => item.id != gym.id).toList(),
        ),
      );
    } catch (error) {
      emit(state.copyWith(saving: false, error: error.toString()));
    }
  }

  /// Подсказки по уже введённым залам; устаревшие ответы отбрасываются.
  Future<void> suggest(String query, {String? city}) async {
    final request = ++_suggestRequest;
    if (query.trim().length < 2) {
      emit(state.copyWith(suggestions: const []));
      return;
    }
    try {
      final found = await _repository.suggestGyms(query: query, city: city);
      if (request != _suggestRequest || isClosed) return;
      final attached = state.gyms.map((gym) => gym.id).toSet();
      emit(
        state.copyWith(
          suggestions: found
              .where((gym) => !attached.contains(gym.id))
              .toList(),
        ),
      );
    } catch (_) {
      if (request == _suggestRequest && !isClosed) {
        emit(state.copyWith(suggestions: const []));
      }
    }
  }

  void clearSuggestions() {
    _suggestRequest++;
    emit(state.copyWith(suggestions: const []));
  }

  Future<bool> _attach(Future<Gym> Function() call) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final gym = await call();
      final gyms = [...state.gyms.where((item) => item.id != gym.id), gym];
      emit(state.copyWith(saving: false, gyms: gyms, suggestions: const []));
      return true;
    } catch (error) {
      emit(state.copyWith(saving: false, error: error.toString()));
      return false;
    }
  }
}
