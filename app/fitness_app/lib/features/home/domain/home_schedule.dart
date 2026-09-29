import '../../schedule/data/schedule_models.dart';
import '../../schedule/domain/calendar_range.dart';

const _terminalStatuses = {'completed', 'cancelled', 'no_show'};

class HomeDayRange {
  const HomeDayRange({required this.start, required this.end});

  factory HomeDayRange.forLocalDay(DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    return HomeDayRange(start: start, end: end);
  }

  final DateTime start;
  final DateTime end;
}

class HomeWeekRange {
  const HomeWeekRange({required this.start, required this.end});

  factory HomeWeekRange.forLocalWeek(DateTime now) {
    final range = rangeForMode(CalendarMode.week, now);
    return HomeWeekRange(start: range.start, end: range.end);
  }

  final DateTime start;
  final DateTime end;
}

List<TrainingSession> homeSessionsForLocalDay(
  Iterable<TrainingSession> sessions,
  DateTime day,
) {
  final start = DateTime(day.year, day.month, day.day);
  final end = DateTime(day.year, day.month, day.day + 1);
  final filtered = sessions.where((session) {
    final local = DateTime.parse(session.startsAt).toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }).toList();
  filtered.sort(
    (left, right) =>
        DateTime.parse(left.startsAt).compareTo(DateTime.parse(right.startsAt)),
  );
  return filtered;
}

String? homeSessionHintForDay(
  Iterable<TrainingSession> sessions,
  DateTime day, {
  int maxLength = 14,
}) {
  final daySessions = homeSessionsForLocalDay(sessions, day);
  if (daySessions.isEmpty) return null;
  final booked = daySessions.where((session) => session.status == 'booked');
  final source = booked.isNotEmpty ? booked.first : daySessions.first;
  final label = source.calendarWorkoutLabel.trim();
  if (label.isEmpty) return null;
  if (label.length <= maxLength) return label;
  return '${label.substring(0, maxLength - 1)}…';
}

int countHomeWeekBookedSessions(Iterable<TrainingSession> sessions) {
  return sessions.where((session) => session.status == 'booked').length;
}

/// Booked-session counts for Monday–Sunday of the week containing [anchor].
List<int> homeWeekBookedCounts(
  Iterable<TrainingSession> sessions,
  DateTime anchor,
) {
  return [
    for (final day in daysInWeek(anchor))
      homeSessionsForLocalDay(
        sessions,
        day,
      ).where((session) => session.status == 'booked').length,
  ];
}

int countHomeTodayUpcomingSessions(
  Iterable<TrainingSession> sessions,
  DateTime now,
) {
  final today = homeSessionsForLocalDay(sessions, now);
  return groupHomeSessions(today, now).currentAndUpcoming.length;
}

class HomeScheduleGroups {
  const HomeScheduleGroups({
    required this.history,
    required this.currentAndUpcoming,
  });

  final List<TrainingSession> history;
  final List<TrainingSession> currentAndUpcoming;
}

HomeScheduleGroups groupHomeSessions(
  Iterable<TrainingSession> sessions,
  DateTime now,
) {
  final sorted = sessions.toList()
    ..sort(
      (left, right) => DateTime.parse(
        left.startsAt,
      ).compareTo(DateTime.parse(right.startsAt)),
    );
  final history = <TrainingSession>[];
  final currentAndUpcoming = <TrainingSession>[];

  for (final session in sorted) {
    final end = DateTime.parse(session.endsAt).toLocal();
    final isHistory =
        _terminalStatuses.contains(session.status) ||
        session.status != 'booked' ||
        !end.isAfter(now);
    if (isHistory) {
      history.add(session);
    } else {
      currentAndUpcoming.add(session);
    }
  }

  return HomeScheduleGroups(
    history: history,
    currentAndUpcoming: currentAndUpcoming,
  );
}

bool isHomeSessionCurrent(TrainingSession session, DateTime now) {
  if (session.status != 'booked') return false;
  final start = DateTime.parse(session.startsAt).toLocal();
  final end = DateTime.parse(session.endsAt).toLocal();
  return !start.isAfter(now) && end.isAfter(now);
}

bool isExpiredBookedSession(TrainingSession session, DateTime now) {
  if (session.status != 'booked') return false;
  final end = DateTime.parse(session.endsAt).toLocal();
  return !end.isAfter(now);
}
