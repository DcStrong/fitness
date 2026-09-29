import 'package:equatable/equatable.dart';

/// ISO weekday: 1 = Monday … 7 = Sunday.
typedef WeekdayNumber = int;

class CoachScheduleSettings extends Equatable {
  const CoachScheduleSettings({
    required this.coachId,
    required this.timezone,
    required this.defaultDurationMinutes,
    required this.breakMinutes,
    required this.horizonWeeks,
    required this.defaultMode,
    this.onlineDurationMinutes,
    this.offlineDurationMinutes,
    this.updatedAt,
  });

  factory CoachScheduleSettings.fromJson(Map<String, dynamic> json) {
    return CoachScheduleSettings(
      coachId: json['coachId'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'Europe/Moscow',
      defaultDurationMinutes:
          (json['defaultDurationMinutes'] as num?)?.toInt() ?? 60,
      breakMinutes: (json['breakMinutes'] as num?)?.toInt() ?? 0,
      horizonWeeks: (json['horizonWeeks'] as num?)?.toInt() ?? 8,
      onlineDurationMinutes: (json['onlineDurationMinutes'] as num?)?.toInt(),
      offlineDurationMinutes: (json['offlineDurationMinutes'] as num?)?.toInt(),
      defaultMode: json['defaultMode'] as String? ?? 'offline',
      updatedAt: json['updatedAt'] as String?,
    );
  }

  factory CoachScheduleSettings.defaults() {
    return const CoachScheduleSettings(
      coachId: '',
      timezone: 'Europe/Moscow',
      defaultDurationMinutes: 60,
      breakMinutes: 0,
      horizonWeeks: 8,
      defaultMode: 'offline',
    );
  }

  final String coachId;
  final String timezone;
  final int defaultDurationMinutes;
  final int breakMinutes;
  final int horizonWeeks;
  final int? onlineDurationMinutes;
  final int? offlineDurationMinutes;
  final String defaultMode;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'timezone': timezone,
    'defaultDurationMinutes': defaultDurationMinutes,
    'breakMinutes': breakMinutes,
    'horizonWeeks': horizonWeeks,
    'onlineDurationMinutes': onlineDurationMinutes,
    'offlineDurationMinutes': offlineDurationMinutes,
    'defaultMode': defaultMode,
  };

  CoachScheduleSettings copyWith({
    String? timezone,
    int? defaultDurationMinutes,
    int? breakMinutes,
    int? horizonWeeks,
    int? onlineDurationMinutes,
    int? offlineDurationMinutes,
    String? defaultMode,
    bool clearOnlineDuration = false,
    bool clearOfflineDuration = false,
  }) {
    return CoachScheduleSettings(
      coachId: coachId,
      timezone: timezone ?? this.timezone,
      defaultDurationMinutes:
          defaultDurationMinutes ?? this.defaultDurationMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      horizonWeeks: horizonWeeks ?? this.horizonWeeks,
      onlineDurationMinutes: clearOnlineDuration
          ? null
          : (onlineDurationMinutes ?? this.onlineDurationMinutes),
      offlineDurationMinutes: clearOfflineDuration
          ? null
          : (offlineDurationMinutes ?? this.offlineDurationMinutes),
      defaultMode: defaultMode ?? this.defaultMode,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    coachId,
    timezone,
    defaultDurationMinutes,
    breakMinutes,
    horizonWeeks,
    onlineDurationMinutes,
    offlineDurationMinutes,
    defaultMode,
  ];
}

class AvailabilityWindow extends Equatable {
  const AvailabilityWindow({
    required this.dayOfWeek,
    required this.startMinute,
    required this.endMinute,
    this.mode,
  });

  factory AvailabilityWindow.fromJson(Map<String, dynamic> json) {
    return AvailabilityWindow(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      startMinute: (json['startMinute'] as num).toInt(),
      endMinute: (json['endMinute'] as num).toInt(),
      mode: json['mode'] as String?,
    );
  }

  final WeekdayNumber dayOfWeek;
  final int startMinute;
  final int endMinute;
  final String? mode;

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'mode': mode,
  };

  AvailabilityWindow copyWith({
    WeekdayNumber? dayOfWeek,
    int? startMinute,
    int? endMinute,
    String? mode,
  }) {
    return AvailabilityWindow(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object?> get props => [dayOfWeek, startMinute, endMinute, mode];
}

class AvailabilityTemplate extends Equatable {
  const AvailabilityTemplate({
    required this.seriesId,
    required this.coachId,
    required this.windows,
  });

  factory AvailabilityTemplate.fromJson(Map<String, dynamic> json) {
    final rawWindows = json['windows'];
    final windows = rawWindows is List
        ? rawWindows
              .whereType<Map>()
              .map(
                (e) =>
                    AvailabilityWindow.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <AvailabilityWindow>[];
    return AvailabilityTemplate(
      seriesId: json['seriesId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      windows: windows,
    );
  }

  final String seriesId;
  final String coachId;
  final List<AvailabilityWindow> windows;

  Map<String, dynamic> toJson() => {
    'windows': windows.map((w) => w.toJson()).toList(),
  };

  @override
  List<Object?> get props => [seriesId, coachId, windows];
}

class AvailabilityExceptionItem extends Equatable {
  const AvailabilityExceptionItem({
    required this.localDate,
    required this.type,
    this.id,
    this.windows,
  });

  factory AvailabilityExceptionItem.fromJson(Map<String, dynamic> json) {
    final rawWindows = json['windows'];
    List<AvailabilityWindow>? windows;
    if (rawWindows is List) {
      windows = rawWindows
          .whereType<Map>()
          .map(
            (e) => AvailabilityWindow(
              dayOfWeek: 1,
              startMinute: (e['startMinute'] as num).toInt(),
              endMinute: (e['endMinute'] as num).toInt(),
              mode: e['mode'] as String?,
            ),
          )
          .toList();
    }
    return AvailabilityExceptionItem(
      id: json['id'] as String?,
      localDate: (json['localDate'] as String).substring(0, 10),
      type: json['type'] as String,
      windows: windows,
    );
  }

  final String? id;
  final String localDate;
  final String type; // closed | custom_hours
  final List<AvailabilityWindow>? windows;

  Map<String, dynamic> toJson() => {
    'localDate': localDate,
    'type': type,
    'windows': type == 'closed'
        ? null
        : (windows ?? [])
              .map(
                (w) => {
                  'startMinute': w.startMinute,
                  'endMinute': w.endMinute,
                  'mode': w.mode,
                },
              )
              .toList(),
  };

  @override
  List<Object?> get props => [id, localDate, type, windows];
}

class AvailabilityPreviewSlot extends Equatable {
  const AvailabilityPreviewSlot({
    required this.startsAt,
    required this.endsAt,
    required this.mode,
  });

  factory AvailabilityPreviewSlot.fromJson(Map<String, dynamic> json) {
    return AvailabilityPreviewSlot(
      startsAt: json['startsAt'] as String,
      endsAt: json['endsAt'] as String,
      mode: json['mode'] as String? ?? 'offline',
    );
  }

  final String startsAt;
  final String endsAt;
  final String mode;

  @override
  List<Object?> get props => [startsAt, endsAt, mode];
}

class GenerateAvailabilitySummary extends Equatable {
  const GenerateAvailabilitySummary({
    required this.created,
    required this.skippedExisting,
    required this.skippedConflict,
    required this.removedOrphanOpen,
  });

  factory GenerateAvailabilitySummary.fromJson(Map<String, dynamic> json) {
    return GenerateAvailabilitySummary(
      created: (json['created'] as num?)?.toInt() ?? 0,
      skippedExisting: (json['skippedExisting'] as num?)?.toInt() ?? 0,
      skippedConflict: (json['skippedConflict'] as num?)?.toInt() ?? 0,
      removedOrphanOpen: (json['removedOrphanOpen'] as num?)?.toInt() ?? 0,
    );
  }

  final int created;
  final int skippedExisting;
  final int skippedConflict;
  final int removedOrphanOpen;

  @override
  List<Object?> get props => [
    created,
    skippedExisting,
    skippedConflict,
    removedOrphanOpen,
  ];
}
