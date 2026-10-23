import 'package:equatable/equatable.dart';

import '../../../core/widgets/person_name_email.dart';
import '../../booking_requests/data/booking_request_models.dart';
import '../data/schedule_models.dart';
import 'calendar_range.dart';

enum CalendarEventType { session, availability, request }

class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.type,
    required this.startsAt,
    required this.endsAt,
    required this.title,
    required this.secondaryLabel,
    required this.mode,
    this.caption,
    this.sessionId,
    this.slotId,
    this.requestId,
    this.sessionStatus,
    this.isTerminal = false,
  });

  final String id;
  final CalendarEventType type;
  final DateTime startsAt;
  final DateTime endsAt;
  final String title;
  final String secondaryLabel;

  /// Optional tiny secondary line (usually email).
  final String? caption;
  final String mode;
  final String? sessionId;
  final String? slotId;
  final String? requestId;
  final String? sessionStatus;
  final bool isTerminal;

  String get typeLabel => switch (type) {
    CalendarEventType.session => isTerminal ? 'Завершена' : 'Тренировка',
    CalendarEventType.availability => 'Свободно',
    CalendarEventType.request => 'Ожидает решения',
  };

  String get modeLabel => mode == 'online' ? 'онлайн' : 'очно';

  @override
  List<Object?> get props => [
    id,
    type,
    startsAt,
    endsAt,
    title,
    secondaryLabel,
    caption,
    mode,
    sessionId,
    slotId,
    requestId,
    sessionStatus,
    isTerminal,
  ];
}

String? sessionPageLocation(CalendarEvent event) {
  if (event.type != CalendarEventType.session || event.sessionId == null) {
    return null;
  }
  return '/sessions/${event.sessionId}';
}

const _terminalStatuses = {'completed', 'cancelled', 'no_show'};

List<CalendarEvent> mapCalendarEvents({
  required Iterable<TrainingSession> sessions,
  required Iterable<ScheduleSlot> slots,
  required Iterable<BookingRequest> requests,
  CalendarRange? range,
}) {
  final pending = requests
      .where((request) => request.status == BookingRequestStatus.pending)
      .toList();
  final heldSlotIds = {for (final request in pending) request.scheduleSlotId};
  final sessionSlotHints = <String>{};
  final events = <CalendarEvent>[];

  for (final session in sessions) {
    if (session.status == 'cancelled') continue;
    final start = DateTime.parse(session.startsAt).toLocal();
    final end = DateTime.parse(session.endsAt).toLocal();
    if (range != null && !_overlapsRange(start, end, range)) continue;
    final counterpart = personPrimaryLabel(
      displayName: session.studentDisplayName,
      email: session.studentEmail,
      fallback: session.studentId,
    );
    final emailCaption = personEmailCaption(
      displayName: session.studentDisplayName,
      email: session.studentEmail,
    );
    final terminal = _terminalStatuses.contains(session.status);
    events.add(
      CalendarEvent(
        id: 'session:${session.id}',
        type: CalendarEventType.session,
        startsAt: start,
        endsAt: end,
        title: counterpart,
        caption: emailCaption,
        secondaryLabel: terminal
            ? _sessionStatusLabel(session.status)
            : session.calendarWorkoutLabel,
        mode: session.mode,
        sessionId: session.id,
        sessionStatus: session.status,
        isTerminal: terminal,
      ),
    );
    sessionSlotHints.add('${start.toIso8601String()}|${end.toIso8601String()}');
  }

  for (final request in pending) {
    final slot = request.requestedSlot;
    final start = slot.startsAt.toLocal();
    final end = slot.endsAt.toLocal();
    if (range != null && !_overlapsRange(start, end, range)) continue;
    events.add(
      CalendarEvent(
        id: 'request:${request.id}',
        type: CalendarEventType.request,
        startsAt: start,
        endsAt: end,
        title: request.counterpart.label.isEmpty
            ? request.counterpart.id
            : request.counterpart.label,
        secondaryLabel: 'Ожидает решения',
        mode: slot.mode,
        requestId: request.id,
        slotId: request.scheduleSlotId,
      ),
    );
  }

  for (final slot in slots) {
    if (slot.status != 'open') continue;
    if (heldSlotIds.contains(slot.id) || slot.held) continue;
    final start = DateTime.parse(slot.startsAt).toLocal();
    final end = DateTime.parse(slot.endsAt).toLocal();
    if (range != null && !_overlapsRange(start, end, range)) continue;
    final key = '${start.toIso8601String()}|${end.toIso8601String()}';
    if (sessionSlotHints.contains(key)) continue;
    events.add(
      CalendarEvent(
        id: 'slot:${slot.id}',
        type: CalendarEventType.availability,
        startsAt: start,
        endsAt: end,
        title: 'Свободное время',
        secondaryLabel: slot.mode == 'online' ? 'онлайн' : 'очно',
        mode: slot.mode,
        slotId: slot.id,
      ),
    );
  }

  events.sort((left, right) {
    final byStart = left.startsAt.compareTo(right.startsAt);
    if (byStart != 0) return byStart;
    return left.id.compareTo(right.id);
  });
  return events;
}

List<CalendarEvent> eventsOnLocalDay(
  Iterable<CalendarEvent> events,
  DateTime day,
) {
  final target = calendarDateOnly(day);
  return events
      .where((event) => isSameCalendarDay(event.startsAt, target))
      .toList(growable: false);
}

bool _overlapsRange(DateTime start, DateTime end, CalendarRange range) {
  return start.isBefore(range.end) && end.isAfter(range.start);
}

String _sessionStatusLabel(String status) => switch (status) {
  'completed' => 'Завершена',
  'cancelled' => 'Отменена',
  'no_show' => 'Неявка',
  _ => status,
};
