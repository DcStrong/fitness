import 'package:equatable/equatable.dart';

import '../../data/plans_models.dart';

enum PlanEditorStatus { initial, loading, ready, saving, failure }

class PlanEditorState extends Equatable {
  const PlanEditorState({
    this.status = PlanEditorStatus.initial,
    this.title = '',
    this.notes = '',
    this.goal = 'general',
    this.tags = const [],
    this.selectedTagIds = const {},
    this.exercises = const [],
    this.availableExercises = const [],
    this.exerciseQuery = '',
    this.kind = 'template',
    this.errorMessage,
    this.validationMessage,
  });

  final PlanEditorStatus status;
  final String title;
  final String notes;
  final String goal;
  final List<TagItem> tags;
  final Set<String> selectedTagIds;
  final List<PlanExerciseItem> exercises;
  final List<ExerciseItem> availableExercises;
  final String exerciseQuery;
  final String kind;
  final String? errorMessage;
  final String? validationMessage;

  List<ExerciseItem> get filteredExercises {
    final q = exerciseQuery.trim().toLowerCase();
    if (q.isEmpty) return availableExercises;
    return availableExercises
        .where((item) => item.name.toLowerCase().contains(q))
        .toList();
  }

  PlanEditorState copyWith({
    PlanEditorStatus? status,
    String? title,
    String? notes,
    String? goal,
    List<TagItem>? tags,
    Set<String>? selectedTagIds,
    List<PlanExerciseItem>? exercises,
    List<ExerciseItem>? availableExercises,
    String? exerciseQuery,
    String? kind,
    Object? errorMessage = _unset,
    Object? validationMessage = _unset,
  }) {
    return PlanEditorState(
      status: status ?? this.status,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      goal: goal ?? this.goal,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      exercises: exercises ?? this.exercises,
      availableExercises: availableExercises ?? this.availableExercises,
      exerciseQuery: exerciseQuery ?? this.exerciseQuery,
      kind: kind ?? this.kind,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      validationMessage: identical(validationMessage, _unset)
          ? this.validationMessage
          : validationMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    title,
    notes,
    goal,
    tags,
    selectedTagIds,
    exercises,
    availableExercises,
    exerciseQuery,
    kind,
    errorMessage,
    validationMessage,
  ];
}

const _unset = Object();
