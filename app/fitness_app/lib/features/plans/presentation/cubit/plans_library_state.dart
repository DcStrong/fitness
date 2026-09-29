import 'package:equatable/equatable.dart';

import '../../data/plans_models.dart';

enum PlansLibraryStatus { initial, loading, success, failure }

enum PlansLibraryMode { own, catalog, exercises }

class PlansLibraryState extends Equatable {
  const PlansLibraryState({
    this.status = PlansLibraryStatus.initial,
    this.mode = PlansLibraryMode.own,
    this.plans = const [],
    this.exercises = const [],
    this.tags = const [],
    this.selectedTagIds = const {},
    this.selectedPlanIds = const {},
    this.selectedExerciseIds = const {},
    this.selecting = false,
    this.query = '',
    this.errorMessage,
    this.cloningId,
  });

  final PlansLibraryStatus status;
  final PlansLibraryMode mode;
  final List<TrainingPlanItem> plans;
  final List<ExerciseItem> exercises;
  final List<TagItem> tags;
  final Set<String> selectedTagIds;
  final Set<String> selectedPlanIds;
  final Set<String> selectedExerciseIds;
  final bool selecting;
  final String query;
  final String? errorMessage;
  final String? cloningId;

  List<TrainingPlanItem> get visiblePlans {
    final q = query.trim().toLowerCase();
    return plans.where((plan) {
      if (q.isNotEmpty && !plan.title.toLowerCase().contains(q)) {
        return false;
      }
      if (selectedTagIds.isEmpty) return true;
      return plan.tags.any((tag) => selectedTagIds.contains(tag.id));
    }).toList();
  }

  List<ExerciseItem> get visibleExercises {
    final q = query.trim().toLowerCase();
    return exercises.where((exercise) {
      if (q.isNotEmpty && !exercise.name.toLowerCase().contains(q)) {
        return false;
      }
      if (selectedTagIds.isEmpty) return true;
      return exercise.tags.any((tag) => selectedTagIds.contains(tag.id));
    }).toList();
  }

  PlansLibraryState copyWith({
    PlansLibraryStatus? status,
    PlansLibraryMode? mode,
    List<TrainingPlanItem>? plans,
    List<ExerciseItem>? exercises,
    List<TagItem>? tags,
    Set<String>? selectedTagIds,
    Set<String>? selectedPlanIds,
    Set<String>? selectedExerciseIds,
    bool? selecting,
    String? query,
    Object? errorMessage = _unset,
    Object? cloningId = _unset,
  }) {
    return PlansLibraryState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      plans: plans ?? this.plans,
      exercises: exercises ?? this.exercises,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      selectedPlanIds: selectedPlanIds ?? this.selectedPlanIds,
      selectedExerciseIds: selectedExerciseIds ?? this.selectedExerciseIds,
      selecting: selecting ?? this.selecting,
      query: query ?? this.query,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      cloningId: identical(cloningId, _unset)
          ? this.cloningId
          : cloningId as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    mode,
    plans,
    exercises,
    tags,
    selectedTagIds,
    selectedPlanIds,
    selectedExerciseIds,
    selecting,
    query,
    errorMessage,
    cloningId,
  ];
}

const _unset = Object();
