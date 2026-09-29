import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/features/schedule/domain/calendar_range.dart';

void main() {
  group('calendar ranges', () {
    test('day uses local midnight boundaries', () {
      final range = rangeForMode(
        CalendarMode.day,
        DateTime(2026, 7, 19, 15, 30),
      );
      expect(range.start, DateTime(2026, 7, 19));
      expect(range.end, DateTime(2026, 7, 20));
    });

    test('week starts on Monday including cross-month', () {
      final range = rangeForMode(CalendarMode.week, DateTime(2026, 8, 1));
      expect(range.start, DateTime(2026, 7, 27));
      expect(range.end, DateTime(2026, 8, 3));
      expect(daysInWeek(DateTime(2026, 8, 1)).length, 7);
    });

    test('month uses first-of-month to next-month boundary', () {
      final leap = rangeForMode(CalendarMode.month, DateTime(2024, 2, 15));
      expect(leap.start, DateTime(2024, 2, 1));
      expect(leap.end, DateTime(2024, 3, 1));
    });

    test('DST-sensitive day still uses calendar constructors', () {
      // Local constructors avoid fixed 24h durations.
      final day = DateTime(2026, 3, 29);
      final range = rangeForMode(CalendarMode.day, day);
      expect(range.start, DateTime(2026, 3, 29));
      expect(range.end, DateTime(2026, 3, 30));
      expect(range.start.toUtc().isBefore(range.end.toUtc()), isTrue);
    });

    test('shiftAnchor moves by calendar units', () {
      expect(
        shiftAnchor(CalendarMode.day, DateTime(2026, 7, 31), 1),
        DateTime(2026, 8, 1),
      );
      expect(
        shiftAnchor(CalendarMode.week, DateTime(2026, 7, 20), 1),
        DateTime(2026, 7, 27),
      );
      expect(
        shiftAnchor(CalendarMode.month, DateTime(2026, 1, 31), 1),
        DateTime(2026, 3, 3),
      );
    });

    test('month grid is Monday-first with adjacent padding', () {
      final grid = monthGridDays(DateTime(2026, 7, 1));
      expect(grid.first.weekday, DateTime.monday);
      expect(grid.length % 7, 0);
      expect(grid.any((day) => day.month == 6), isTrue);
    });
  });
}
