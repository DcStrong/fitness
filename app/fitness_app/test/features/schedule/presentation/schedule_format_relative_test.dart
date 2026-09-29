import 'package:fitness_app/features/schedule/presentation/schedule_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 8, 12);

  test('сегодня / завтра / вчера', () {
    expect(
      formatRelativeCalendarDate(DateTime(2026, 8, 8), now: now),
      'сегодня',
    );
    expect(
      formatRelativeCalendarDate(DateTime(2026, 8, 9), now: now),
      'завтра',
    );
    expect(formatRelativeCalendarDate(DateTime(2026, 8, 7), now: now), 'вчера');
  });

  test('дальние даты DD.MM.YY', () {
    expect(
      formatRelativeCalendarDate(DateTime(2026, 8, 10), now: now),
      '10.08.26',
    );
  });

  test('строка YYYY-MM-DD без сдвига', () {
    expect(formatRelativeCalendarDateString('2026-08-08', now: now), 'сегодня');
  });
}
