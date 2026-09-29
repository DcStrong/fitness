import 'package:equatable/equatable.dart';

enum BookingRequestStatus { pending, accepted, rejected, withdrawn, expired }

enum BookingRequestRejectionReason { timeUnavailable, plansChanged, other }

enum BookingRequestResolution { requestedSlot, alternateSlot }

enum BookingRequestEventType { created, accepted, rejected, withdrawn, expired }

T _enumByWire<T extends Enum>(Iterable<T> values, String? wire, T fallback) =>
    values.firstWhere((value) => _wire(value) == wire, orElse: () => fallback);

String _wire(Enum value) => switch (value) {
  BookingRequestRejectionReason.timeUnavailable => 'time_unavailable',
  BookingRequestRejectionReason.plansChanged => 'plans_changed',
  BookingRequestResolution.requestedSlot => 'requested_slot',
  BookingRequestResolution.alternateSlot => 'alternate_slot',
  _ => value.name,
};

extension BookingRequestRejectionReasonWire on BookingRequestRejectionReason {
  String get wireValue => _wire(this);
}

class BookingRequestSlotSummary extends Equatable {
  const BookingRequestSlotSummary({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.mode,
  });

  factory BookingRequestSlotSummary.fromJson(Map<String, dynamic> json) =>
      BookingRequestSlotSummary(
        id: json['id'] as String? ?? '',
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
        mode: json['mode'] as String? ?? 'offline',
      );

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final String mode;

  @override
  List<Object?> get props => [id, startsAt, endsAt, mode];
}

class BookingRequestCounterpart extends Equatable {
  const BookingRequestCounterpart({required this.id, required this.label});

  factory BookingRequestCounterpart.fromJson(Map<String, dynamic> json) =>
      BookingRequestCounterpart(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

class BookingRequest extends Equatable {
  const BookingRequest({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.scheduleSlotId,
    required this.status,
    required this.quotedPriceMinor,
    required this.quotedCurrency,
    required this.expiresAt,
    required this.requestedSlot,
    required this.counterpart,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedBy,
    this.resolvedAt,
    this.rejectionReason,
    this.rejectionComment,
    this.resolution,
    this.resolvedScheduleSlotId,
    this.sessionId,
    this.resolvedSlot,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    final reason = json['rejectionReason'] as String?;
    final resolution = json['resolution'] as String?;
    return BookingRequest(
      id: json['id'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      scheduleSlotId: json['scheduleSlotId'] as String? ?? '',
      status: _enumByWire(
        BookingRequestStatus.values,
        json['status'] as String?,
        BookingRequestStatus.pending,
      ),
      quotedPriceMinor: json['quotedPriceMinor']?.toString() ?? '0',
      quotedCurrency: json['quotedCurrency'] as String? ?? 'RUB',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      resolvedBy: json['resolvedBy'] as String?,
      resolvedAt: _date(json['resolvedAt']),
      rejectionReason: reason == null
          ? null
          : _enumByWire(
              BookingRequestRejectionReason.values,
              reason,
              BookingRequestRejectionReason.other,
            ),
      rejectionComment: json['rejectionComment'] as String?,
      resolution: resolution == null
          ? null
          : _enumByWire(
              BookingRequestResolution.values,
              resolution,
              BookingRequestResolution.requestedSlot,
            ),
      resolvedScheduleSlotId: json['resolvedScheduleSlotId'] as String?,
      sessionId: json['sessionId'] as String?,
      requestedSlot: BookingRequestSlotSummary.fromJson(
        _map(json['requestedSlot']),
      ),
      resolvedSlot: json['resolvedSlot'] is Map
          ? BookingRequestSlotSummary.fromJson(_map(json['resolvedSlot']))
          : null,
      counterpart: BookingRequestCounterpart.fromJson(
        _map(json['counterpart']),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String coachId;
  final String studentId;
  final String scheduleSlotId;
  final BookingRequestStatus status;
  final String quotedPriceMinor;
  final String quotedCurrency;
  final DateTime expiresAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final BookingRequestRejectionReason? rejectionReason;
  final String? rejectionComment;
  final BookingRequestResolution? resolution;
  final String? resolvedScheduleSlotId;
  final String? sessionId;
  final BookingRequestSlotSummary requestedSlot;
  final BookingRequestSlotSummary? resolvedSlot;
  final BookingRequestCounterpart counterpart;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == BookingRequestStatus.pending;
  BookingRequestSlotSummary get displayedSlot => resolvedSlot ?? requestedSlot;

  @override
  List<Object?> get props => [
    id,
    status,
    quotedPriceMinor,
    expiresAt,
    resolvedAt,
    rejectionReason,
    rejectionComment,
    resolution,
    sessionId,
    requestedSlot,
    resolvedSlot,
    counterpart,
    updatedAt,
  ];
}

class BookingRequestPage extends Equatable {
  const BookingRequestPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory BookingRequestPage.fromJson(Map<String, dynamic> json) {
    final meta = _map(json['meta']);
    return BookingRequestPage(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => BookingRequest.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? 20,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  final List<BookingRequest> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasNext => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class BookingRequestEvent extends Equatable {
  const BookingRequestEvent({
    required this.id,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final BookingRequestEventType type;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, type, createdAt];
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
