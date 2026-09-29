import 'package:equatable/equatable.dart';

class ProgressPoint extends Equatable {
  const ProgressPoint({
    required this.sessionId,
    required this.completedAt,
    required this.volume,
    this.weightKg,
    this.coachId,
  });

  factory ProgressPoint.fromJson(Map<String, dynamic> json) {
    return ProgressPoint(
      sessionId: json['sessionId'] as String,
      completedAt: json['completedAt'] as String,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toDouble() ?? 0,
      coachId: json['coachId'] as String?,
    );
  }

  final String sessionId;
  final String completedAt;
  final double? weightKg;
  final double volume;
  final String? coachId;

  @override
  List<Object?> get props => [sessionId, completedAt, weightKg, volume];
}

class ProgressSeries extends Equatable {
  const ProgressSeries({
    required this.exerciseId,
    required this.points,
    this.goal,
  });

  factory ProgressSeries.fromJson(Map<String, dynamic> json) {
    final raw = json['points'];
    final points = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) =>
                    ProgressPoint.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <ProgressPoint>[];
    return ProgressSeries(
      exerciseId: json['exerciseId'] as String,
      goal: json['goal'] as String?,
      points: points,
    );
  }

  final String exerciseId;
  final String? goal;
  final List<ProgressPoint> points;

  bool get usesVolume =>
      goal == 'fat_loss' || (goal == 'general' && !_hasWeight);

  bool get _hasWeight => points.any((point) => point.weightKg != null);

  double? get firstValue => _valueAt(0);

  double? get currentValue =>
      points.isEmpty ? null : _valueAt(points.length - 1);

  double? get delta {
    final first = firstValue;
    final current = currentValue;
    if (first == null || current == null) return null;
    return current - first;
  }

  double? _valueAt(int index) {
    if (index < 0 || index >= points.length) return null;
    final point = points[index];
    return usesVolume ? point.volume : point.weightKg;
  }

  List<double> get chartValues {
    return [
      for (final point in points)
        (usesVolume ? point.volume : point.weightKg) ?? 0,
    ];
  }

  @override
  List<Object?> get props => [exerciseId, goal, points];
}

class ProgressExerciseSummary extends Equatable {
  const ProgressExerciseSummary({
    required this.exerciseId,
    required this.name,
    required this.sessionCount,
  });

  factory ProgressExerciseSummary.fromJson(Map<String, dynamic> json) {
    return ProgressExerciseSummary(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String exerciseId;
  final String name;
  final int sessionCount;

  @override
  List<Object?> get props => [exerciseId, name, sessionCount];
}
