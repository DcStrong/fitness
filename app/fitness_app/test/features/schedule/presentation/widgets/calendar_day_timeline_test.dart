import 'package:fitness_app/features/schedule/data/availability_models.dart';
import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/schedule/domain/calendar_events.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/calendar_day_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalendarEvent event({
    required String id,
    required DateTime startsAt,
    required DateTime endsAt,
    CalendarEventType type = CalendarEventType.session,
  }) {
    return CalendarEvent(
      id: id,
      type: type,
      startsAt: startsAt,
      endsAt: endsAt,
      title: id,
      secondaryLabel: '',
      mode: 'offline',
      sessionId: type == CalendarEventType.session ? id : null,
      slotId: type == CalendarEventType.availability ? id : null,
    );
  }

  test('empty day keeps default 08–20 band', () {
    expect(debugTimelineHours(const []), [
      for (var hour = 8; hour < 20; hour++) hour,
    ]);
  });

  test('working hours stay visible even without bookings', () {
    final day = DateTime(2026, 8, 16); // Sunday
    final working = workingHoursForDay(
      day: day,
      windows: const [
        AvailabilityWindow(
          dayOfWeek: 7,
          startMinute: 9 * 60,
          endMinute: 13 * 60,
        ),
        AvailabilityWindow(
          dayOfWeek: 7,
          startMinute: 14 * 60,
          endMinute: 19 * 60,
        ),
      ],
    );

    expect(working, [9, 10, 11, 12, 14, 15, 16, 17, 18]);

    final hours = debugTimelineHours(const [], workingHours: working);
    expect(hours, working);
    expect(hours.contains(13), isFalse); // break
  });

  test('out-of-band session sits right after last working hour', () {
    final day = DateTime(2026, 8, 16);
    final working = [9, 10, 11, 12, 14, 15, 16, 17, 18];
    final events = [
      event(
        id: 'booked',
        startsAt: DateTime(day.year, day.month, day.day, 12, 10),
        endsAt: DateTime(day.year, day.month, day.day, 13, 10),
      ),
      event(
        id: 'late',
        startsAt: DateTime(day.year, day.month, day.day, 23),
        endsAt: DateTime(day.year, day.month, day.day + 1),
      ),
    ];

    final hours = debugTimelineHours(events, workingHours: working);
    // 12:10–13:10 booking also covers hour 13; empty 19–22 stay collapsed.
    expect(hours, [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 23]);
    expect(hours.contains(19), isFalse);
    expect(hours.contains(20), isFalse);
    expect(hours.contains(21), isFalse);
    expect(hours.contains(22), isFalse);

    final hourHeights = debugTimelineHourHeights(events, workingHours: working);
    final tops = debugTimelineTops(events, workingHours: working);
    final lateIndex = hours.indexOf(23);
    final expectedLateTop = hourHeights
        .take(lateIndex)
        .fold<double>(0, (sum, height) => sum + height);
    expect(tops.last, expectedLateTop);
  });

  test('slots enrich working hours beyond weekly windows', () {
    final day = DateTime(2026, 8, 16);
    final hours = workingHoursForDay(
      day: day,
      windows: const [
        AvailabilityWindow(
          dayOfWeek: 7,
          startMinute: 9 * 60,
          endMinute: 13 * 60,
        ),
      ],
      slots: [
        ScheduleSlot(
          id: 'extra',
          coachId: 'c1',
          startsAt: DateTime(
            day.year,
            day.month,
            day.day,
            20,
          ).toUtc().toIso8601String(),
          endsAt: DateTime(
            day.year,
            day.month,
            day.day,
            21,
          ).toUtc().toIso8601String(),
          status: 'open',
          mode: 'offline',
        ),
      ],
    );

    expect(hours, containsAll([9, 10, 11, 12, 20]));
  });

  test(
    'mid-hour 60-minute session expands start hour and stays above next band',
    () {
      final day = DateTime(2026, 8, 16);
      final working = [12, 13, 14];
      final events = [
        event(
          id: 'mid',
          startsAt: DateTime(day.year, day.month, day.day, 12, 10),
          endsAt: DateTime(day.year, day.month, day.day, 13, 10),
        ),
      ];

      final px = debugTimelinePxPerMinute(events);
      expect(px, 1.2);

      final hourHeights = debugTimelineHourHeights(
        events,
        workingHours: working,
      );
      final tops = debugTimelineTops(events, workingHours: working);
      final heights = debugTimelineHeights(events, workingHours: working);

      // Start hour grows: 10min offset + 60min card at baseline scale.
      expect(hourHeights[0], 10 * px + 60 * px);
      expect(hourHeights[1], 60 * px); // 13 stays baseline
      expect(tops.single, 10 * px);
      expect(heights.single, 60 * px);
      // Card bottom lands on the 13:00 boundary — no invasion into hour 13 band.
      expect(tops.single + heights.single, hourHeights[0]);
    },
  );

  test('hour-aligned session keeps baseline scale and hour height', () {
    final day = DateTime(2026, 8, 16);
    final working = [12, 13, 14];
    final events = [
      event(
        id: 'aligned',
        startsAt: DateTime(day.year, day.month, day.day, 12),
        endsAt: DateTime(day.year, day.month, day.day, 13),
      ),
    ];

    expect(debugTimelinePxPerMinute(events), 1.2);
    final hourHeights = debugTimelineHourHeights(events, workingHours: working);
    expect(hourHeights, everyElement(72.0));
    expect(debugTimelineTops(events, workingHours: working).single, 0);
  });

  test('empty working hour remains on scaled grid', () {
    final day = DateTime(2026, 8, 16);
    final working = [12, 13, 14];
    final events = [
      event(
        id: 'mid',
        startsAt: DateTime(day.year, day.month, day.day, 12, 10),
        endsAt: DateTime(day.year, day.month, day.day, 13, 10),
      ),
    ];

    final hours = debugTimelineHours(events, workingHours: working);
    expect(hours, containsAll([12, 13, 14]));
    final hourHeights = debugTimelineHourHeights(events, workingHours: working);
    expect(hourHeights[2], 72.0); // empty 14 stays baseline
  });

  test('half-hour labels only on hours with :30 boundaries', () {
    final day = DateTime(2026, 8, 16);
    final working = [12, 13, 14];
    final halfHour = [
      event(
        id: 'half',
        startsAt: DateTime(day.year, day.month, day.day, 12, 30),
        endsAt: DateTime(day.year, day.month, day.day, 13, 30),
      ),
    ];
    final wholeHour = [
      event(
        id: 'whole',
        startsAt: DateTime(day.year, day.month, day.day, 12),
        endsAt: DateTime(day.year, day.month, day.day, 13),
      ),
    ];

    expect(debugHalfHourLabelHours(halfHour, workingHours: working), {12, 13});
    expect(debugHalfHourLabelHours(wholeHour, workingHours: working), isEmpty);
  });
}
