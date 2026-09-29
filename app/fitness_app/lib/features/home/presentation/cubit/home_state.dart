import 'package:equatable/equatable.dart';

import '../../../schedule/data/schedule_models.dart';

enum HomeStatus { initial, loading, success, failure }

enum PendingCountStatus { initial, loading, success, failure }

enum StudentPackageStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.sessions = const [],
    this.now,
    this.dayStart,
    this.weekStart,
    this.errorMessage,
    this.historyExpanded = false,
    this.upcomingExpanded = true,
    this.pendingCountStatus = PendingCountStatus.initial,
    this.pendingRequestCount,
    this.studentPackageStatus = StudentPackageStatus.initial,
    this.studentPackageRemaining,
    this.studentPackageExhausted = false,
    this.freeSlotCount,
  });

  final HomeStatus status;
  final List<TrainingSession> sessions;
  final DateTime? now;
  final DateTime? dayStart;
  final DateTime? weekStart;
  final String? errorMessage;
  final bool historyExpanded;
  final bool upcomingExpanded;
  final PendingCountStatus pendingCountStatus;
  final int? pendingRequestCount;
  final StudentPackageStatus studentPackageStatus;
  final int? studentPackageRemaining;
  final bool studentPackageExhausted;

  /// Free slots already present in loaded state. Null means the count is unknown.
  final int? freeSlotCount;

  HomeState copyWith({
    HomeStatus? status,
    List<TrainingSession>? sessions,
    DateTime? now,
    DateTime? dayStart,
    DateTime? weekStart,
    Object? errorMessage = _notProvided,
    bool? historyExpanded,
    bool? upcomingExpanded,
    PendingCountStatus? pendingCountStatus,
    Object? pendingRequestCount = _notProvided,
    StudentPackageStatus? studentPackageStatus,
    Object? studentPackageRemaining = _notProvided,
    bool? studentPackageExhausted,
    Object? freeSlotCount = _notProvided,
  }) {
    return HomeState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      now: now ?? this.now,
      dayStart: dayStart ?? this.dayStart,
      weekStart: weekStart ?? this.weekStart,
      errorMessage: identical(errorMessage, _notProvided)
          ? this.errorMessage
          : errorMessage as String?,
      historyExpanded: historyExpanded ?? this.historyExpanded,
      upcomingExpanded: upcomingExpanded ?? this.upcomingExpanded,
      pendingCountStatus: pendingCountStatus ?? this.pendingCountStatus,
      pendingRequestCount: identical(pendingRequestCount, _notProvided)
          ? this.pendingRequestCount
          : pendingRequestCount as int?,
      studentPackageStatus: studentPackageStatus ?? this.studentPackageStatus,
      studentPackageRemaining: identical(studentPackageRemaining, _notProvided)
          ? this.studentPackageRemaining
          : studentPackageRemaining as int?,
      studentPackageExhausted:
          studentPackageExhausted ?? this.studentPackageExhausted,
      freeSlotCount: identical(freeSlotCount, _notProvided)
          ? this.freeSlotCount
          : freeSlotCount as int?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sessions,
    now,
    dayStart,
    weekStart,
    errorMessage,
    historyExpanded,
    upcomingExpanded,
    pendingCountStatus,
    pendingRequestCount,
    studentPackageStatus,
    studentPackageRemaining,
    studentPackageExhausted,
    freeSlotCount,
  ];
}

const _notProvided = Object();
