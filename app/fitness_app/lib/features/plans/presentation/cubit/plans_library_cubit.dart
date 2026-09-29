import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/plans_repository.dart';
import 'plans_library_state.dart';

class PlansLibraryCubit extends Cubit<PlansLibraryState> {
  PlansLibraryCubit({
    required PlansRepository repository,
    this.visibleOnly = false,
  }) : _repository = repository,
       super(const PlansLibraryState());

  final PlansRepository _repository;
  final bool visibleOnly;

  Future<void> load() async {
    emit(
      state.copyWith(status: PlansLibraryStatus.loading, errorMessage: null),
    );
    try {
      if (visibleOnly) {
        final plans = await _repository.listVisiblePlans();
        final exercises = await _repository.listVisibleExercises();
        if (isClosed) return;
        emit(
          state.copyWith(
            status: PlansLibraryStatus.success,
            plans: plans,
            exercises: exercises,
            tags: const [],
          ),
        );
        return;
      }
      final tags = await _repository.listTags();
      if (state.mode == PlansLibraryMode.exercises) {
        final exercises = await _repository.listExercises();
        if (isClosed) return;
        emit(
          state.copyWith(
            status: PlansLibraryStatus.success,
            exercises: exercises,
            tags: tags,
          ),
        );
        return;
      }
      final plans = state.mode == PlansLibraryMode.catalog
          ? await _repository.listCatalogPlans()
          : await _repository.listOwnPlans();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlansLibraryStatus.success,
          plans: plans,
          tags: tags,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlansLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> setMode(PlansLibraryMode mode) async {
    if (visibleOnly || mode == state.mode) return;
    emit(
      state.copyWith(
        mode: mode,
        selectedTagIds: {},
        selectedPlanIds: {},
        selectedExerciseIds: {},
        selecting: false,
      ),
    );
    await load();
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }

  void toggleTag(String tagId) {
    final next = {...state.selectedTagIds};
    if (!next.add(tagId)) {
      next.remove(tagId);
    }
    emit(state.copyWith(selectedTagIds: next));
  }

  void replaceSelectedTags(Set<String> tagIds) {
    emit(state.copyWith(selectedTagIds: tagIds));
  }

  void toggleSelecting() {
    emit(
      state.copyWith(
        selecting: !state.selecting,
        selectedPlanIds: {},
        selectedExerciseIds: {},
      ),
    );
  }

  void togglePlanSelected(String planId) {
    final next = {...state.selectedPlanIds};
    if (!next.add(planId)) {
      next.remove(planId);
    }
    emit(state.copyWith(selectedPlanIds: next));
  }

  void toggleExerciseSelected(String exerciseId) {
    final next = {...state.selectedExerciseIds};
    if (!next.add(exerciseId)) {
      next.remove(exerciseId);
    }
    emit(state.copyWith(selectedExerciseIds: next));
  }

  void clearExerciseSelection() {
    emit(state.copyWith(selectedExerciseIds: {}));
  }

  Future<bool> clonePlan(String planId) async {
    emit(state.copyWith(cloningId: planId, errorMessage: null));
    try {
      await _repository.clonePlan(planId);
      if (isClosed) return false;
      emit(state.copyWith(cloningId: null));
      await load();
      return true;
    } catch (error) {
      if (isClosed) return false;
      emit(state.copyWith(cloningId: null, errorMessage: error.toString()));
      return false;
    }
  }

  Future<bool> assignSelectedPlans(String studentId) async {
    final planIds = state.selectedPlanIds.toList();
    if (planIds.isEmpty) return false;
    try {
      await _repository.assignPlansBatch(
        studentId: studentId,
        planIds: planIds,
      );
      if (isClosed) return false;
      emit(state.copyWith(selecting: false, selectedPlanIds: {}));
      return true;
    } catch (error) {
      if (isClosed) return false;
      emit(state.copyWith(errorMessage: error.toString()));
      return false;
    }
  }

  Future<bool> replaceExerciseTags({
    required String exerciseId,
    required List<String> tagIds,
  }) async {
    try {
      await _repository.replaceExerciseTags(
        exerciseId: exerciseId,
        tagIds: tagIds,
      );
      await load();
      return true;
    } catch (error) {
      if (isClosed) return false;
      emit(state.copyWith(errorMessage: error.toString()));
      return false;
    }
  }
}
