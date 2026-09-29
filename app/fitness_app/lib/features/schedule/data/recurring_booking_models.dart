import 'package:equatable/equatable.dart';

/// ISO weekday: 1 = Monday … 7 = Sunday.
typedef WeekdayNumber = int;

class RecurringBooking extends Equatable {
  const RecurringBooking({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.weekdays,
    required this.startMinute,
    required this.mode,
    required this.timezone,
    required this.status,
    required this.horizonWeeksOverride,
    required this.createdAt,
    required this.updatedAt,
    required this.cancelledAt,
    this.studentDisplayName,
    this.studentEmail,
    this.nextOccurrenceLocalDate,
  });

  factory RecurringBooking.fromJson(Map<String, dynamic> json) {
    final rawWeekdays = json['weekdays'];
    return RecurringBooking(
      id: json['id'] as String,
      coachId: json['coachId'] as String,
      studentId: json['studentId'] as String,
      studentDisplayName: json['studentDisplayName'] as String?,
      studentEmail: json['studentEmail'] as String?,
      nextOccurrenceLocalDate: json['nextOccurrenceLocalDate'] as String?,
      weekdays: rawWeekdays is List
          ? rawWeekdays.map((e) => (e as num).toInt()).toList()
          : const [],
      startMinute: (json['startMinute'] as num).toInt(),
      mode: json['mode'] as String,
      timezone: json['timezone'] as String,
      status: json['status'] as String,
      horizonWeeksOverride: json['horizonWeeksOverride'] as int?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      cancelledAt: json['cancelledAt'] as String?,
    );
  }

  final String id;
  final String coachId;
  final String studentId;
  final String? studentDisplayName;
  final String? studentEmail;
  final String? nextOccurrenceLocalDate;
  final List<WeekdayNumber> weekdays;
  final int startMinute;
  final String mode;
  final String timezone;
  final String status;
  final int? horizonWeeksOverride;
  final String createdAt;
  final String updatedAt;
  final String? cancelledAt;

  bool get isActive => status == 'active';

  /// Prefer display name, then email, then short id.
  String get studentTitle {
    final name = studentDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = studentEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    if (studentId.length <= 8) return studentId;
    return studentId.substring(0, 8);
  }

  @override
  List<Object?> get props => [
    id,
    coachId,
    studentId,
    studentDisplayName,
    studentEmail,
    nextOccurrenceLocalDate,
    weekdays,
    startMinute,
    mode,
    timezone,
    status,
    horizonWeeksOverride,
    createdAt,
    updatedAt,
    cancelledAt,
  ];
}

class RecurringConflict extends Equatable {
  const RecurringConflict({
    required this.localDate,
    required this.reason,
    required this.startsAt,
    required this.endsAt,
  });

  factory RecurringConflict.fromJson(Map<String, dynamic> json) {
    return RecurringConflict(
      localDate: json['localDate'] as String,
      reason: json['reason'] as String,
      startsAt: json['startsAt'] as String,
      endsAt: json['endsAt'] as String,
    );
  }

  final String localDate;
  final String reason;
  final String startsAt;
  final String endsAt;

  @override
  List<Object?> get props => [localDate, reason, startsAt, endsAt];
}

class RecurringSyncSummary extends Equatable {
  const RecurringSyncSummary({
    required this.booked,
    required this.skippedExisting,
    required this.conflicts,
    this.slotsCreated = 0,
  });

  factory RecurringSyncSummary.fromJson(Map<String, dynamic> json) {
    final rawConflicts = json['conflicts'];
    return RecurringSyncSummary(
      booked: (json['booked'] as num).toInt(),
      skippedExisting: (json['skippedExisting'] as num).toInt(),
      slotsCreated: (json['slotsCreated'] as num?)?.toInt() ?? 0,
      conflicts: rawConflicts is List
          ? rawConflicts
                .whereType<Map>()
                .map(
                  (e) =>
                      RecurringConflict.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }

  final int booked;
  final int skippedExisting;
  final int slotsCreated;
  final List<RecurringConflict> conflicts;

  @override
  List<Object?> get props => [booked, skippedExisting, slotsCreated, conflicts];
}

class CreateRecurringBookingResult extends Equatable {
  const CreateRecurringBookingResult({
    required this.booking,
    required this.sync,
  });

  factory CreateRecurringBookingResult.fromJson(Map<String, dynamic> json) {
    return CreateRecurringBookingResult(
      booking: RecurringBooking.fromJson(
        Map<String, dynamic>.from(json['booking'] as Map),
      ),
      sync: RecurringSyncSummary.fromJson(
        Map<String, dynamic>.from(json['sync'] as Map),
      ),
    );
  }

  final RecurringBooking booking;
  final RecurringSyncSummary sync;

  @override
  List<Object?> get props => [booking, sync];
}
