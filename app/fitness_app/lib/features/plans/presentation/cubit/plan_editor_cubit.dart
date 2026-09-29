import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/plans_format.dart';
import '../../data/plans_models.dart';
import '../../data/plans_repository.dart';
import 'plan_editor_state.dart';

class PlanEditorCubit extends Cubit<PlanEditorState> {
  PlanEditorCubit({required PlansRepository repository, this.planId})
    : _repository = repository,
      super(const PlanEditorState());

  final PlansRepository _repository;
  final String? planId;

  bool get isEdit => planId != null;

  Future<void> load() async {
    emit(state.copyWith(status: PlanEditorStatus.loading, errorMessage: null));
    try {
      final tags = await _repository.listTags();
      final available = await _repository.listExercises();
      var next = state.copyWith(
        status: PlanEditorStatus.ready,
        tags: tags,
        availableExercises: available,
      );
      if (isEdit) {
        final plan = await _repository.getPlan(planId!);
        next = next.copyWith(
          title: plan.title,
          notes: plan.displayNotes,
          goal: plan.goal,
          kind: plan.kind,
          selectedTagIds: plan.tags.map((tag) => tag.id).toSet(),
          exercises: plan.exercises,
        );
      }
      emit(next);
    } catch (error) {
      emit(
        state.copyWith(
          status: PlanEditorStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void setTitle(String title) {
    emit(state.copyWith(title: title, validationMessage: null));
  }

  void setNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  void setGoal(String goal) {
    emit(state.copyWith(goal: goal));
  }

  void setExerciseQuery(String query) {
    emit(state.copyWith(exerciseQuery: query));
  }

  void toggleTag(String tagId) {
    final next = {...state.selectedTagIds};
    if (!next.add(tagId)) {
      next.remove(tagId);
    }
    emit(state.copyWith(selectedTagIds: next));
  }

  void addExercise(ExerciseItem exercise) {
    if (state.exercises.any((item) => item.exerciseId == exercise.id)) {
      return;
    }
    final defaults = goalExerciseDefaults(state.goal);
    emit(
      state.copyWith(
        exercises: [
          ...state.exercises,
          PlanExerciseItem(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseKind: exercise.kind,
            restSeconds: defaults.restSeconds,
            sets: identicalSets(
              count: defaults.sets,
              kind: exercise.kind,
              reps: defaults.reps,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> createAndAddExercise({
    required String name,
    required String kind,
  }) async {
    final created = await _repository.createExercise(name: name, kind: kind);
    emit(
      state.copyWith(
        availableExercises: [...state.availableExercises, created],
      ),
    );
    addExercise(created);
  }

  void removeExercise(String exerciseId) {
    emit(
      state.copyWith(
        exercises: state.exercises
            .where((item) => item.exerciseId != exerciseId)
            .toList(),
      ),
    );
  }

  void setLoadWeight(String exerciseId, double weightKg) {
    emit(
      state.copyWith(
        exercises: state.exercises.map((item) {
          if (item.exerciseId != exerciseId) return item;
          if (item.exerciseKind != 'weight_reps') return item;
          return item.copyWith(
            sets: item.sets
                .map((set) => set.copyWith(weightKg: weightKg))
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  void updateExerciseSets({
    required String exerciseId,
    required int setCount,
    required int reps,
    double? weightKg,
    int? durationSeconds,
    required int restSeconds,
  }) {
    emit(
      state.copyWith(
        exercises: state.exercises.map((item) {
          if (item.exerciseId != exerciseId) return item;
          return item.copyWith(
            restSeconds: restSeconds,
            sets: identicalSets(
              count: setCount,
              kind: item.exerciseKind,
              reps: reps,
              weightKg: weightKg,
              durationSeconds: durationSeconds ?? 30,
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<bool> save() async {
    final title = state.title.trim();
    if (title.isEmpty) {
      emit(state.copyWith(validationMessage: 'Укажите название'));
      return false;
    }
    emit(
      state.copyWith(
        status: PlanEditorStatus.saving,
        validationMessage: null,
        errorMessage: null,
      ),
    );
    try {
      if (isEdit) {
        await _repository.updatePlan(
          id: planId!,
          title: title,
          notes: state.notes,
          goal: state.goal,
          tagIds: state.selectedTagIds.toList(),
          exercises: state.exercises,
        );
        final loads = [
          for (final exercise in state.exercises)
            if (exercise.exerciseKind == 'weight_reps')
              (
                exerciseId: exercise.exerciseId,
                weightKg: workingWeightKg(exercise) ?? 0,
              ),
        ].where((item) => item.weightKg > 0).toList();
        if (loads.isNotEmpty) {
          await _repository.updatePlanLoads(id: planId!, items: loads);
        }
      } else {
        await _repository.createPlan(
          title: title,
          notes: state.notes,
          goal: state.goal,
          tagIds: state.selectedTagIds.toList(),
          exercises: state.exercises,
        );
      }
      emit(state.copyWith(status: PlanEditorStatus.ready));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlanEditorStatus.ready,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }
}
