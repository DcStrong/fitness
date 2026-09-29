import 'package:equatable/equatable.dart';

class WorkoutProgramItem extends Equatable {
  const WorkoutProgramItem({
    required this.templateId,
    required this.studentPlanId,
    required this.title,
    required this.sortOrder,
  });

  factory WorkoutProgramItem.fromJson(Map<String, dynamic> json) {
    return WorkoutProgramItem(
      templateId: json['templateId'] as String,
      studentPlanId: json['studentPlanId'] as String,
      title: (json['title'] as String?) ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  final String templateId;
  final String studentPlanId;
  final String title;
  final int sortOrder;

  @override
  List<Object?> get props => [templateId, studentPlanId, sortOrder];
}

class WorkoutProgramDay extends Equatable {
  const WorkoutProgramDay({required this.weekday, required this.items});

  factory WorkoutProgramDay.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return WorkoutProgramDay(
      weekday: (json['weekday'] as num).toInt(),
      items: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => WorkoutProgramItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  final int weekday;
  final List<WorkoutProgramItem> items;

  @override
  List<Object?> get props => [weekday, items];
}

class WorkoutProgressionRule extends Equatable {
  const WorkoutProgressionRule({
    required this.exerciseId,
    required this.deltaKg,
    required this.incrementKg,
    required this.holdOnMiss,
    this.startWeightKg,
    this.heldWeightKg,
  });

  factory WorkoutProgressionRule.fromJson(Map<String, dynamic> json) {
    return WorkoutProgressionRule(
      exerciseId: json['exerciseId'] as String,
      startWeightKg: (json['startWeightKg'] as num?)?.toDouble(),
      deltaKg: (json['deltaKg'] as num?)?.toDouble() ?? 0,
      incrementKg: (json['incrementKg'] as num?)?.toDouble() ?? 2.5,
      holdOnMiss: json['holdOnMiss'] != false,
      heldWeightKg: (json['heldWeightKg'] as num?)?.toDouble(),
    );
  }

  final String exerciseId;
  final double? startWeightKg;
  final double deltaKg;
  final double incrementKg;
  final bool holdOnMiss;
  final double? heldWeightKg;

  @override
  List<Object?> get props => [exerciseId, startWeightKg, deltaKg, heldWeightKg];
}

class WorkoutProgramPreviewPoint extends Equatable {
  const WorkoutProgramPreviewPoint({
    required this.date,
    required this.weekday,
    required this.exerciseId,
    required this.weightKg,
  });

  factory WorkoutProgramPreviewPoint.fromJson(Map<String, dynamic> json) {
    return WorkoutProgramPreviewPoint(
      date: json['date'] as String,
      weekday: (json['weekday'] as num).toInt(),
      exerciseId: json['exerciseId'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
    );
  }

  final String date;
  final int weekday;
  final String exerciseId;
  final double weightKg;

  @override
  List<Object?> get props => [date, weekday, exerciseId, weightKg];
}

class WorkoutProgram extends Equatable {
  const WorkoutProgram({
    required this.id,
    required this.recurringBookingId,
    required this.studentId,
    required this.horizonWeeks,
    required this.days,
    required this.progressionRules,
    required this.preview,
  });

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'];
    final rulesRaw = json['progressionRules'];
    final previewRaw = json['preview'];
    return WorkoutProgram(
      id: json['id'] as String,
      recurringBookingId: json['recurringBookingId'] as String,
      studentId: json['studentId'] as String,
      horizonWeeks: (json['horizonWeeks'] as num?)?.toInt() ?? 2,
      days: daysRaw is List
          ? daysRaw
                .whereType<Map>()
                .map(
                  (item) => WorkoutProgramDay.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      progressionRules: rulesRaw is List
          ? rulesRaw
                .whereType<Map>()
                .map(
                  (item) => WorkoutProgressionRule.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      preview: previewRaw is List
          ? previewRaw
                .whereType<Map>()
                .map(
                  (item) => WorkoutProgramPreviewPoint.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  final String id;
  final String recurringBookingId;
  final String studentId;
  final int horizonWeeks;
  final List<WorkoutProgramDay> days;
  final List<WorkoutProgressionRule> progressionRules;
  final List<WorkoutProgramPreviewPoint> preview;

  @override
  List<Object?> get props => [id, horizonWeeks, days, progressionRules];
}
