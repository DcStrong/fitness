import 'package:equatable/equatable.dart';

import '../../../core/widgets/person_name_email.dart';
import '../../finance/data/finance_models.dart';
import '../../plans/data/plans_models.dart';

class ScheduleSlot extends Equatable {
  const ScheduleSlot({
    required this.id,
    required this.coachId,
    required this.startsAt,
    required this.endsAt,
    required this.mode,
    required this.status,
    this.price,
    this.held = false,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id'] as String,
      coachId: json['coachId'] as String,
      startsAt: json['startsAt'] as String,
      endsAt: json['endsAt'] as String,
      mode: json['mode'] as String,
      status: json['status'] as String,
      price: json['price'] is Map
          ? MoneyAmount.fromJson(jsonMap(json['price']))
          : null,
      held: json['held'] == true,
    );
  }

  final String id;
  final String coachId;
  final String startsAt;
  final String endsAt;
  final String mode;
  final String status;
  final MoneyAmount? price;
  final bool held;

  @override
  List<Object?> get props => [id, startsAt, endsAt, status, price, held];
}

class TrainingSession extends Equatable {
  const TrainingSession({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.createdBy,
    this.coachEmail,
    this.studentEmail,
    this.coachDisplayName,
    this.studentDisplayName,
    this.coachAvatarUrl,
    this.studentAvatarUrl,
    required this.finance,
    this.packageExhausted = false,
    this.mode = 'offline',
    this.studentPlanId,
    this.planTitle,
    this.plan,
    this.workouts = const [],
    this.recurringBookingId,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      coachId: json['coachId'] as String,
      studentId: json['studentId'] as String,
      startsAt: json['startsAt'] as String,
      endsAt: json['endsAt'] as String,
      status: json['status'] as String,
      createdBy: json['createdBy'] as String,
      coachEmail: json['coachEmail'] as String?,
      studentEmail: json['studentEmail'] as String?,
      coachDisplayName: json['coachDisplayName'] as String?,
      studentDisplayName: json['studentDisplayName'] as String?,
      coachAvatarUrl: json['coachAvatarUrl'] as String?,
      studentAvatarUrl: json['studentAvatarUrl'] as String?,
      finance: SessionFinance.fromJson(
        json['finance'] is Map
            ? jsonMap(json['finance'])
            : const {'status': 'not_tracked'},
      ),
      packageExhausted: json['packageExhausted'] == true,
      mode: (json['mode'] as String?) ?? 'offline',
      studentPlanId: json['studentPlanId'] as String?,
      planTitle: json['planTitle'] as String?,
      plan: json['plan'] is Map
          ? TrainingPlanItem.fromJson(jsonMap(json['plan']))
          : null,
      workouts: _workoutsFromJson(json['workouts']),
      recurringBookingId: json['recurringBookingId'] as String?,
    );
  }

  final String id;
  final String coachId;
  final String studentId;
  final String startsAt;
  final String endsAt;
  final String status;
  final String createdBy;
  final String? coachEmail;
  final String? studentEmail;
  final String? coachDisplayName;
  final String? studentDisplayName;
  final String? coachAvatarUrl;
  final String? studentAvatarUrl;
  final SessionFinance finance;
  final bool packageExhausted;
  final String mode;
  final String? studentPlanId;
  final String? planTitle;
  final TrainingPlanItem? plan;
  final List<SessionWorkoutAttached> workouts;
  final String? recurringBookingId;

  String? get workoutTitle {
    if (workouts.isNotEmpty) {
      return workouts
          .map((item) => item.title)
          .where((t) => t.isNotEmpty)
          .join(' · ');
    }
    return plan?.title ?? planTitle;
  }

  String get calendarWorkoutLabel {
    final titles = workouts
        .map((item) => item.title)
        .where((title) => title.isNotEmpty)
        .take(2)
        .toList();
    if (titles.isEmpty) {
      final fallback = plan?.title ?? planTitle;
      return fallback == null || fallback.isEmpty ? 'Тренировка' : fallback;
    }
    return titles.join(', ');
  }

  /// Counterpart as seen by [viewerUserId] (coach sees student, and vice versa).
  String peerPrimaryLabel(String viewerUserId) {
    final isCoach = viewerUserId == coachId;
    return personPrimaryLabel(
      displayName: isCoach ? studentDisplayName : coachDisplayName,
      email: isCoach ? studentEmail : coachEmail,
      fallback: isCoach ? studentId : coachId,
    );
  }

  String? peerEmailCaption(String viewerUserId) {
    final isCoach = viewerUserId == coachId;
    return personEmailCaption(
      displayName: isCoach ? studentDisplayName : coachDisplayName,
      email: isCoach ? studentEmail : coachEmail,
    );
  }

  /// Counterpart image already present on the session. Null when absent.
  String? peerAvatarUrl(String viewerUserId) {
    final isCoach = viewerUserId == coachId;
    final url = (isCoach ? studentAvatarUrl : coachAvatarUrl)?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  @override
  List<Object?> get props => [
    id,
    startsAt,
    status,
    finance,
    packageExhausted,
    coachDisplayName,
    studentDisplayName,
    coachAvatarUrl,
    studentAvatarUrl,
    mode,
    studentPlanId,
    planTitle,
    plan,
    workouts,
    recurringBookingId,
  ];
}

List<SessionWorkoutAttached> _workoutsFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (item) =>
            SessionWorkoutAttached.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList();
}

class SessionWorkoutAttached extends Equatable {
  const SessionWorkoutAttached({
    required this.studentPlanId,
    required this.title,
    required this.goal,
    required this.source,
    required this.overridden,
    this.exercises = const [],
  });

  factory SessionWorkoutAttached.fromJson(Map<String, dynamic> json) {
    final raw = json['exercises'];
    return SessionWorkoutAttached(
      studentPlanId: json['studentPlanId'] as String,
      title: (json['title'] as String?) ?? '',
      goal: (json['goal'] as String?) ?? 'general',
      source: (json['source'] as String?) ?? 'manual',
      overridden: json['overridden'] == true,
      exercises: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => PlanExerciseItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  final String studentPlanId;
  final String title;
  final String goal;
  final String source;
  final bool overridden;
  final List<PlanExerciseItem> exercises;

  @override
  List<Object?> get props => [studentPlanId, title, source, overridden];
}

class SessionHistoryEvent extends Equatable {
  const SessionHistoryEvent({
    required this.id,
    required this.sessionId,
    required this.actorUserId,
    required this.fromStatus,
    required this.toStatus,
    required this.createdAt,
    this.actorEmail,
    this.note,
  });

  factory SessionHistoryEvent.fromJson(Map<String, dynamic> json) {
    return SessionHistoryEvent(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      actorUserId: json['actorUserId'] as String,
      actorEmail: json['actorEmail'] as String?,
      fromStatus: json['fromStatus'] as String,
      toStatus: json['toStatus'] as String,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  final String id;
  final String sessionId;
  final String actorUserId;
  final String? actorEmail;
  final String fromStatus;
  final String toStatus;
  final String? note;
  final String createdAt;

  @override
  List<Object?> get props => [id, toStatus, createdAt];
}
