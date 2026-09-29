import 'package:equatable/equatable.dart';

import '../../../plans/data/plans_models.dart';
import '../../../schedule/data/schedule_models.dart';

enum SessionWorkoutStatus { initial, loading, ready, failure, mutating }

class SessionWorkoutState extends Equatable {
  const SessionWorkoutState({
    this.status = SessionWorkoutStatus.initial,
    this.session,
    this.remainingSessions,
    this.errorMessage,
    this.infoMessage,
  });

  final SessionWorkoutStatus status;
  final TrainingSession? session;
  final int? remainingSessions;
  final String? errorMessage;
  final String? infoMessage;

  TrainingPlanItem? get plan => session?.plan;

  bool get hasPlan =>
      (session?.workouts.isNotEmpty ?? false) ||
      (session?.studentPlanId != null && session?.plan != null);

  SessionWorkoutState copyWith({
    SessionWorkoutStatus? status,
    TrainingSession? session,
    Object? remainingSessions = _unset,
    Object? errorMessage = _unset,
    Object? infoMessage = _unset,
  }) {
    return SessionWorkoutState(
      status: status ?? this.status,
      session: session ?? this.session,
      remainingSessions: identical(remainingSessions, _unset)
          ? this.remainingSessions
          : remainingSessions as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      infoMessage: identical(infoMessage, _unset)
          ? this.infoMessage
          : infoMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    session,
    remainingSessions,
    errorMessage,
    infoMessage,
  ];
}

const _unset = Object();
