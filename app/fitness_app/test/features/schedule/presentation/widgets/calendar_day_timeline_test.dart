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

  test('working hours stay visible as one continuous run', () {
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

    // The grid stays continuous: the 13:00 break is shown as an empty hour.
    final hours = debugTimelineHours(const [], workingHours: working);
    expect(hours, [for (var hour = 9; hour <= 18; hour++) hour]);
  });

  test('hours run continuously up to an out-of-band session', () {
    final day = DateTime(2026, 8, 16);
    final working = [9, 10, 11, 12, 14, 15, 16, 17, 18];
    final events = [
      event(
        id: 'late',
        startsAt: DateTime(day.year, day.month, day.day, 21),
        endsAt: DateTime(day.year, day.month, day.day, 22),
      ),
    ];

    final hours = debugTimelineHours(events, workingHours: working);
    expect(hours, [for (var hour = 9; hour <= 21; hour++) hour]);
    // 21:00 is 12 hours below 09:00 at 64 px per hour.
    expect(
      debugTimelineTops(events, workingHours: working).single,
      12 * 64 + 1,
    );
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

  test('cards sit exactly on the clock: 13:20–14:20 spans two hour bands', () {
    final day = DateTime(2026, 8, 16);
    final events = [
      event(
        id: 'mid',
        startsAt: DateTime(day.year, day.month, day.day, 13, 20),
        endsAt: DateTime(day.year, day.month, day.day, 14, 20),
      ),
    ];
    final working = [12, 13, 14, 15];

    final top = debugTimelineTops(events, workingHours: working).single;
    final height = debugTimelineHeights(events, workingHours: working).single;
    const px = 64 / 60;
    expect(top, closeTo(80 * px + 1, 0.01)); // 12:00 + 1h20m
    expect(height, closeTo(60 * px - 2, 0.01));
    expect(debugOffHourMarkers(events, workingHours: working), [
      '13:20',
      '14:20',
    ]);
  });

  test('whole-hour sessions add no off-hour markers', () {
    final day = DateTime(2026, 8, 16);
    final events = [
      event(
        id: 'aligned',
        startsAt: DateTime(day.year, day.month, day.day, 12),
        endsAt: DateTime(day.year, day.month, day.day, 13),
      ),
    ];
    expect(debugOffHourMarkers(events), isEmpty);
  });

  test('back-to-back short sessions never overlap', () {
    final day = DateTime(2026, 8, 16);
    final events = [
      event(
        id: 'a',
        startsAt: DateTime(day.year, day.month, day.day, 12),
        endsAt: DateTime(day.year, day.month, day.day, 12, 30),
      ),
      event(
        id: 'b',
        startsAt: DateTime(day.year, day.month, day.day, 12, 30),
        endsAt: DateTime(day.year, day.month, day.day, 13),
      ),
    ];
    final tops = debugTimelineTops(events);
    final heights = debugTimelineHeights(events);
    expect(tops[1], greaterThanOrEqualTo(tops[0] + heights[0]));
  });
}
