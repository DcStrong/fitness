import 'package:equatable/equatable.dart';

import '../../../plans/data/plans_models.dart';
import '../../../schedule/data/recurring_booking_models.dart';
import '../../data/workout_program_models.dart';

enum WorkoutProgramStatus { loading, ready, saving, failure }

class ProgramDayDraftItem extends Equatable {
  const ProgramDayDraftItem({
    required this.templateId,
    required this.title,
    this.studentPlanId,
  });

  final String templateId;
  final String title;
  final String? studentPlanId;

  @override
  List<Object?> get props => [templateId, studentPlanId, title];
}

class ProgramRuleDraft extends Equatable {
  const ProgramRuleDraft({
    required this.exerciseId,
    required this.exerciseName,
    this.startWeightKg,
    this.deltaKg = 0,
  });

  final String exerciseId;
  final String exerciseName;
  final double? startWeightKg;
  final double deltaKg;

  ProgramRuleDraft copyWith({double? startWeightKg, double? deltaKg}) {
    return ProgramRuleDraft(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      startWeightKg: startWeightKg ?? this.startWeightKg,
      deltaKg: deltaKg ?? this.deltaKg,
    );
  }

  @override
  List<Object?> get props => [exerciseId, exerciseName, startWeightKg, deltaKg];
}

class WorkoutProgramState extends Equatable {
  const WorkoutProgramState({
    this.status = WorkoutProgramStatus.loading,
    this.booking,
    this.horizonWeeks = 2,
    this.days = const {},
    this.plansById = const {},
    this.templates = const [],
    this.rules = const [],
    this.preview = const [],
    this.validationMessage,
    this.errorMessage,
  });

  final WorkoutProgramStatus status;
  final RecurringBooking? booking;
  final int horizonWeeks;
  final Map<int, List<ProgramDayDraftItem>> days;
  final Map<String, TrainingPlanItem> plansById;
  final List<TrainingPlanItem> templates;
  final List<ProgramRuleDraft> rules;
  final List<WorkoutProgramPreviewPoint> preview;
  final String? validationMessage;
  final String? errorMessage;

  WorkoutProgramState copyWith({
    WorkoutProgramStatus? status,
    RecurringBooking? booking,
    int? horizonWeeks,
    Map<int, List<ProgramDayDraftItem>>? days,
    Map<String, TrainingPlanItem>? plansById,
    List<TrainingPlanItem>? templates,
    List<ProgramRuleDraft>? rules,
    List<WorkoutProgramPreviewPoint>? preview,
    Object? validationMessage = _unset,
    Object? errorMessage = _unset,
  }) {
    return WorkoutProgramState(
      status: status ?? this.status,
      booking: booking ?? this.booking,
      horizonWeeks: horizonWeeks ?? this.horizonWeeks,
      days: days ?? this.days,
      plansById: plansById ?? this.plansById,
      templates: templates ?? this.templates,
      rules: rules ?? this.rules,
      preview: preview ?? this.preview,
      validationMessage: identical(validationMessage, _unset)
          ? this.validationMessage
          : validationMessage as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    booking,
    horizonWeeks,
    days,
    plansById,
    templates,
    rules,
    preview,
    validationMessage,
    errorMessage,
  ];
}

const _unset = Object();
