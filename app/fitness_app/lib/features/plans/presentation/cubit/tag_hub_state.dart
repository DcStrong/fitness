import 'package:equatable/equatable.dart';

import '../../../invitations/data/invitation_models.dart';
import '../../data/plans_models.dart';

enum TagHubStatus { initial, loading, success, failure }

enum TagHubSection { all, students, plans, exercises }

class TagHubState extends Equatable {
  const TagHubState({
    this.status = TagHubStatus.initial,
    this.hub,
    this.students = const [],
    this.ownPlans = const [],
    this.ownExercises = const [],
    this.section = TagHubSection.all,
    this.query = '',
    this.busy = false,
    this.errorMessage,
    this.infoMessage,
  });

  final TagHubStatus status;
  final TagHub? hub;
  final List<RelationshipItem> students;
  final List<TrainingPlanItem> ownPlans;
  final List<ExerciseItem> ownExercises;
  final TagHubSection section;
  final String query;
  final bool busy;
  final String? errorMessage;
  final String? infoMessage;

  List<TagAssignee> get visibleUsers {
    final users = hub?.users ?? const <TagAssignee>[];
    return [
      for (final user in users)
        if (_matches(_userLabel(user))) user,
    ];
  }

  List<TagHubPlan> get visiblePlans {
    final plans = hub?.plans ?? const <TagHubPlan>[];
    return [
      for (final plan in plans)
        if (_matches(plan.title)) plan,
    ];
  }

  List<TagHubExercise> get visibleExercises {
    final exercises = hub?.exercises ?? const <TagHubExercise>[];
    return [
      for (final exercise in exercises)
        if (_matches(exercise.name)) exercise,
    ];
  }

  String _userLabel(TagAssignee user) {
    final student = _student(user.userId);
    return [
      user.displayName,
      student?.studentDisplayName,
      user.email,
      student?.studentEmail,
      user.userId,
    ].whereType<String>().join(' ');
  }

  RelationshipItem? _student(String userId) {
    for (final student in students) {
      if (student.studentId == userId) return student;
    }
    return null;
  }

  bool _matches(String text) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return text.toLowerCase().contains(needle);
  }

  TagHubState copyWith({
    TagHubStatus? status,
    TagHub? hub,
    List<RelationshipItem>? students,
    List<TrainingPlanItem>? ownPlans,
    List<ExerciseItem>? ownExercises,
    TagHubSection? section,
    String? query,
    bool? busy,
    Object? errorMessage = _unset,
    Object? infoMessage = _unset,
  }) {
    return TagHubState(
      status: status ?? this.status,
      hub: hub ?? this.hub,
      students: students ?? this.students,
      ownPlans: ownPlans ?? this.ownPlans,
      ownExercises: ownExercises ?? this.ownExercises,
      section: section ?? this.section,
      query: query ?? this.query,
      busy: busy ?? this.busy,
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
    hub,
    students,
    ownPlans,
    ownExercises,
    section,
    query,
    busy,
    errorMessage,
    infoMessage,
  ];
}

const _unset = Object();
