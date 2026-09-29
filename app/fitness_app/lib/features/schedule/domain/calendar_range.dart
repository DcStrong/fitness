enum CalendarMode { day, week, month }

class CalendarRange {
  const CalendarRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool containsLocal(DateTime value) {
    final local = DateTime(value.year, value.month, value.day);
    return !local.isBefore(start) && local.isBefore(end);
  }
}

DateTime calendarDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Monday-first weekday index: Mon=0 … Sun=6.
int mondayBasedWeekday(DateTime date) => (date.weekday + 6) % 7;

CalendarRange rangeForMode(CalendarMode mode, DateTime anchor) {
  final day = calendarDateOnly(anchor);
  switch (mode) {
    case CalendarMode.day:
      return CalendarRange(
        start: day,
        end: DateTime(day.year, day.month, day.day + 1),
      );
    case CalendarMode.week:
      final monday = DateTime(
        day.year,
        day.month,
        day.day - mondayBasedWeekday(day),
      );
      return CalendarRange(
        start: monday,
        end: DateTime(monday.year, monday.month, monday.day + 7),
      );
    case CalendarMode.month:
      final first = DateTime(day.year, day.month, 1);
      return CalendarRange(
        start: first,
        end: DateTime(first.year, first.month + 1, 1),
      );
  }
}

DateTime shiftAnchor(CalendarMode mode, DateTime anchor, int direction) {
  final day = calendarDateOnly(anchor);
  switch (mode) {
    case CalendarMode.day:
      return DateTime(day.year, day.month, day.day + direction);
    case CalendarMode.week:
      return DateTime(day.year, day.month, day.day + (7 * direction));
    case CalendarMode.month:
      return DateTime(day.year, day.month + direction, day.day);
  }
}

List<DateTime> daysInWeek(DateTime anchor) {
  final range = rangeForMode(CalendarMode.week, anchor);
  return List.generate(
    7,
    (index) =>
        DateTime(range.start.year, range.start.month, range.start.day + index),
  );
}

/// Monday-first month grid including adjacent-month padding cells.
List<DateTime> monthGridDays(DateTime anchor) {
  final range = rangeForMode(CalendarMode.month, anchor);
  final first = range.start;
  final leading = mondayBasedWeekday(first);
  final gridStart = DateTime(first.year, first.month, first.day - leading);
  final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
  final total = ((leading + daysInMonth + 6) ~/ 7) * 7;
  return List.generate(
    total,
    (index) => DateTime(gridStart.year, gridStart.month, gridStart.day + index),
  );
}

bool isSameCalendarDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

bool rangeContainsToday(CalendarMode mode, DateTime anchor, DateTime now) {
  final range = rangeForMode(mode, anchor);
  final today = calendarDateOnly(now);
  return !today.isBefore(range.start) && today.isBefore(range.end);
}
