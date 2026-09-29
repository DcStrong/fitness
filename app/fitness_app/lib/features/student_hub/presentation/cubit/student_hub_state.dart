import 'package:equatable/equatable.dart';

import '../../../plans/data/plans_models.dart';
import '../../../schedule/data/schedule_models.dart';
import '../../../session_packages/data/session_package_models.dart';
import '../../data/progress_models.dart';

enum StudentHubStatus { initial, loading, ready, failure }

class WeekProgramSlot extends Equatable {
  const WeekProgramSlot({required this.weekday, required this.title});

  final int weekday;
  final String title;

  @override
  List<Object?> get props => [weekday, title];
}

class StudentHubState extends Equatable {
  const StudentHubState({
    this.status = StudentHubStatus.initial,
    this.upcoming = const [],
    this.assigned = const [],
    this.package,
    this.exercises = const [],
    this.selectedExerciseId,
    this.series,
    this.recurringBookingId,
    this.weekSlots = const [],
    this.studentDisplayName,
    this.errorMessage,
  });

  final StudentHubStatus status;
  final List<TrainingSession> upcoming;
  final List<TrainingPlanItem> assigned;
  final SessionPackage? package;
  final List<ProgressExerciseSummary> exercises;
  final String? selectedExerciseId;
  final ProgressSeries? series;
  final String? recurringBookingId;
  final List<WeekProgramSlot> weekSlots;
  final String? studentDisplayName;
  final String? errorMessage;

  StudentHubState copyWith({
    StudentHubStatus? status,
    List<TrainingSession>? upcoming,
    List<TrainingPlanItem>? assigned,
    Object? package = _unset,
    List<ProgressExerciseSummary>? exercises,
    Object? selectedExerciseId = _unset,
    Object? series = _unset,
    Object? recurringBookingId = _unset,
    List<WeekProgramSlot>? weekSlots,
    Object? studentDisplayName = _unset,
    Object? errorMessage = _unset,
  }) {
    return StudentHubState(
      status: status ?? this.status,
      upcoming: upcoming ?? this.upcoming,
      assigned: assigned ?? this.assigned,
      package: identical(package, _unset)
          ? this.package
          : package as SessionPackage?,
      exercises: exercises ?? this.exercises,
      selectedExerciseId: identical(selectedExerciseId, _unset)
          ? this.selectedExerciseId
          : selectedExerciseId as String?,
      series: identical(series, _unset)
          ? this.series
          : series as ProgressSeries?,
      recurringBookingId: identical(recurringBookingId, _unset)
          ? this.recurringBookingId
          : recurringBookingId as String?,
      weekSlots: weekSlots ?? this.weekSlots,
      studentDisplayName: identical(studentDisplayName, _unset)
          ? this.studentDisplayName
          : studentDisplayName as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    upcoming,
    assigned,
    package,
    exercises,
    selectedExerciseId,
    series,
    recurringBookingId,
    weekSlots,
    studentDisplayName,
    errorMessage,
  ];
}

const _unset = Object();
