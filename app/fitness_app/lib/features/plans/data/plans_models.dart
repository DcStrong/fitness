import 'package:equatable/equatable.dart';

const _unset = Object();

class PlanTag extends Equatable {
  const PlanTag({required this.id, required this.name});

  factory PlanTag.fromJson(Map<String, dynamic> json) {
    return PlanTag(id: json['id'] as String, name: json['name'] as String);
  }

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class TagItem extends Equatable {
  const TagItem({
    required this.id,
    required this.name,
    required this.creatorId,
    this.creatorEmail,
  });

  factory TagItem.fromJson(Map<String, dynamic> json) {
    return TagItem(
      id: json['id'] as String,
      name: json['name'] as String,
      creatorId: json['creatorId'] as String,
      creatorEmail: json['creatorEmail'] as String?,
    );
  }

  final String id;
  final String name;
  final String creatorId;
  final String? creatorEmail;

  String get displayLabel {
    if (creatorEmail == null || creatorEmail!.isEmpty) {
      return '#$name';
    }
    return '#$name#$creatorEmail';
  }

  @override
  List<Object?> get props => [id, name];
}

class TagAssignee extends Equatable {
  const TagAssignee({
    required this.userId,
    required this.assignedAt,
    this.email,
    this.displayName,
  });

  factory TagAssignee.fromJson(Map<String, dynamic> json) {
    return TagAssignee(
      userId: json['userId'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      assignedAt: json['assignedAt'] as String,
    );
  }

  final String userId;
  final String? email;
  final String? displayName;
  final String assignedAt;

  @override
  List<Object?> get props => [userId, displayName];
}

class PlanSetItem extends Equatable {
  const PlanSetItem({
    this.id,
    this.sortOrder = 0,
    this.reps,
    this.weightKg,
    this.durationSeconds,
  });

  factory PlanSetItem.fromJson(Map<String, dynamic> json) {
    return PlanSetItem(
      id: json['id'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      reps: (json['reps'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );
  }

  final String? id;
  final int sortOrder;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;

  Map<String, dynamic> toJson() => {
    if (reps != null) 'reps': reps,
    if (weightKg != null) 'weightKg': weightKg,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
  };

  PlanSetItem copyWith({
    Object? reps = _unset,
    Object? weightKg = _unset,
    Object? durationSeconds = _unset,
  }) {
    return PlanSetItem(
      id: id,
      sortOrder: sortOrder,
      reps: identical(reps, _unset) ? this.reps : reps as int?,
      weightKg: identical(weightKg, _unset)
          ? this.weightKg
          : weightKg as double?,
      durationSeconds: identical(durationSeconds, _unset)
          ? this.durationSeconds
          : durationSeconds as int?,
    );
  }

  @override
  List<Object?> get props => [id, sortOrder, reps, weightKg, durationSeconds];
}

class PlanExerciseItem extends Equatable {
  const PlanExerciseItem({
    this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseKind,
    this.sortOrder = 0,
    this.restSeconds,
    this.notes = '',
    this.sets = const [],
  });

  factory PlanExerciseItem.fromJson(Map<String, dynamic> json) {
    final setsRaw = json['sets'];
    final sets = setsRaw is List
        ? setsRaw
              .whereType<Map>()
              .map((e) => PlanSetItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <PlanSetItem>[];
    return PlanExerciseItem(
      id: json['id'] as String?,
      exerciseId: json['exerciseId'] as String,
      exerciseName: (json['exerciseName'] as String?) ?? '',
      exerciseKind: (json['exerciseKind'] as String?) ?? 'weight_reps',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      restSeconds: (json['restSeconds'] as num?)?.toInt(),
      notes: (json['notes'] as String?) ?? '',
      sets: sets,
    );
  }

  final String? id;
  final String exerciseId;
  final String exerciseName;
  final String exerciseKind;
  final int sortOrder;
  final int? restSeconds;
  final String notes;
  final List<PlanSetItem> sets;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    if (restSeconds != null) 'restSeconds': restSeconds,
    if (notes.isNotEmpty) 'notes': notes,
    'sets': sets.map((set) => set.toJson()).toList(),
  };

  PlanExerciseItem copyWith({
    String? exerciseName,
    int? restSeconds,
    List<PlanSetItem>? sets,
  }) {
    return PlanExerciseItem(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseKind: exerciseKind,
      sortOrder: sortOrder,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes,
      sets: sets ?? this.sets,
    );
  }

  @override
  List<Object?> get props => [
    id,
    exerciseId,
    exerciseName,
    exerciseKind,
    restSeconds,
    sets,
  ];
}

class ExerciseItem extends Equatable {
  const ExerciseItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.source,
    this.ownerCoachId,
    this.tags = const [],
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final tags = tagsRaw is List
        ? tagsRaw
              .whereType<Map>()
              .map((e) => PlanTag.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <PlanTag>[];
    return ExerciseItem(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      source: (json['source'] as String?) ?? 'own',
      ownerCoachId: json['ownerCoachId'] as String?,
      tags: tags,
    );
  }

  final String id;
  final String name;
  final String kind;
  final String source;
  final String? ownerCoachId;
  final List<PlanTag> tags;

  bool get isCatalog => source == 'catalog' || ownerCoachId == null;

  @override
  List<Object?> get props => [id, name, kind, source, tags];
}

class TagHubPlan extends Equatable {
  const TagHubPlan({
    required this.id,
    required this.title,
    this.kind = 'template',
  });

  factory TagHubPlan.fromJson(Map<String, dynamic> json) {
    return TagHubPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      kind: (json['kind'] as String?) ?? 'template',
    );
  }

  final String id;
  final String title;
  final String kind;

  @override
  List<Object?> get props => [id, title, kind];
}

class TagHubExercise extends Equatable {
  const TagHubExercise({
    required this.id,
    required this.name,
    required this.kind,
    required this.source,
  });

  factory TagHubExercise.fromJson(Map<String, dynamic> json) {
    return TagHubExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      source: (json['source'] as String?) ?? 'own',
    );
  }

  final String id;
  final String name;
  final String kind;
  final String source;

  @override
  List<Object?> get props => [id, name];
}

class TagHub extends Equatable {
  const TagHub({
    required this.tag,
    required this.users,
    required this.plans,
    required this.exercises,
  });

  factory TagHub.fromJson(Map<String, dynamic> json) {
    return TagHub(
      tag: TagItem.fromJson(json),
      users: (json['users'] is List)
          ? (json['users'] as List)
                .whereType<Map>()
                .map((e) => TagAssignee.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      plans: (json['plans'] is List)
          ? (json['plans'] as List)
                .whereType<Map>()
                .map((e) => TagHubPlan.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      exercises: (json['exercises'] is List)
          ? (json['exercises'] as List)
                .whereType<Map>()
                .map(
                  (e) => TagHubExercise.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }

  final TagItem tag;
  final List<TagAssignee> users;
  final List<TagHubPlan> plans;
  final List<TagHubExercise> exercises;

  @override
  List<Object?> get props => [tag, users, plans, exercises];
}

class TrainingPlanItem extends Equatable {
  const TrainingPlanItem({
    required this.id,
    required this.ownerCoachId,
    required this.title,
    required this.body,
    required this.tags,
    this.ownerCoachEmail,
    this.kind = 'template',
    this.goal = 'general',
    this.notes = '',
    this.exercises = const [],
    this.parentTemplateId,
    this.assignedStudentId,
  });

  factory TrainingPlanItem.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final tags = tagsRaw is List
        ? tagsRaw
              .whereType<Map>()
              .map((e) => PlanTag.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <PlanTag>[];
    final exercisesRaw = json['exercises'];
    final exercises = exercisesRaw is List
        ? exercisesRaw
              .whereType<Map>()
              .map(
                (e) => PlanExerciseItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <PlanExerciseItem>[];
    final body = (json['body'] as String?) ?? '';
    final notes = (json['notes'] as String?) ?? body;
    return TrainingPlanItem(
      id: json['id'] as String,
      ownerCoachId: json['ownerCoachId'] as String,
      ownerCoachEmail: json['ownerCoachEmail'] as String?,
      title: json['title'] as String,
      body: body,
      notes: notes,
      kind: (json['kind'] as String?) ?? 'template',
      goal: (json['goal'] as String?) ?? 'general',
      tags: tags,
      exercises: exercises,
      parentTemplateId: json['parentTemplateId'] as String?,
      assignedStudentId: json['assignedStudentId'] as String?,
    );
  }

  final String id;
  final String ownerCoachId;
  final String? ownerCoachEmail;
  final String title;
  final String body;
  final String notes;
  final String kind;
  final String goal;
  final List<PlanTag> tags;
  final List<PlanExerciseItem> exercises;
  final String? parentTemplateId;
  final String? assignedStudentId;

  bool get isCatalog => kind == 'catalog_seed';
  bool get isTemplate => kind == 'template';
  bool get isStudentCopy => kind == 'student_copy';

  String get displayNotes => notes.isNotEmpty ? notes : body;

  TrainingPlanItem copyWith({
    String? title,
    List<PlanExerciseItem>? exercises,
  }) {
    return TrainingPlanItem(
      id: id,
      ownerCoachId: ownerCoachId,
      ownerCoachEmail: ownerCoachEmail,
      title: title ?? this.title,
      body: body,
      notes: notes,
      kind: kind,
      goal: goal,
      tags: tags,
      exercises: exercises ?? this.exercises,
      parentTemplateId: parentTemplateId,
      assignedStudentId: assignedStudentId,
    );
  }

  @override
  List<Object?> get props => [id, title, kind, goal, tags, exercises];
}
