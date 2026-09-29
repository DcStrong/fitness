import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/availability_models.dart';
import '../../data/schedule_models.dart';
import '../../domain/calendar_events.dart';
import '../../domain/calendar_range.dart';
import 'calendar_event_card.dart';

const _hourHeight = 72.0;
const _labelWidth = 48.0;
const _minCardHeight = 68.0;
const _defaultStartHour = 8;
const _defaultEndHour = 20;
const _basePxPerMinute = _hourHeight / 60; // 1.2
const _maxPxPerMinute = _basePxPerMinute * 2;

class CalendarDayTimeline extends StatelessWidget {
  const CalendarDayTimeline({
    required this.events,
    required this.selectedDate,
    this.workingHours = const [],
    this.onEventTap,
    this.onEmptyHourTap,
    super.key,
  });

  final List<CalendarEvent> events;
  final DateTime selectedDate;

  /// Hours from the trainer's schedule (weekly windows + created slots).
  /// Always kept visible even when empty of bookings.
  final List<int> workingHours;

  final void Function(CalendarEvent event)? onEventTap;
  final void Function(DateTime localHourStart)? onEmptyHourTap;

  @override
  Widget build(BuildContext context) {
    final hours = debugTimelineHours(events, workingHours: workingHours);
    final layout = _layoutDay(events, hours);
    final halfHourHours = _hoursNeedingHalfHourLabel(events, hours);

    return SizedBox(
      key: const Key('calendar-day-timeline'),
      height: layout.timelineHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Column(
              children: [
                for (var index = 0; index < hours.length; index++)
                  SizedBox(
                    height: layout.hourHeights[index],
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${hours[index].toString().padLeft(2, '0')}:00',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (halfHourHours.contains(hours[index]))
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${hours[index].toString().padLeft(2, '0')}:30',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.textMuted.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                for (var index = 0; index < hours.length; index++)
                  Positioned(
                    top: layout.hourTops[index],
                    left: 0,
                    right: 0,
                    height: layout.hourHeights[index],
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: Key('calendar-empty-hour-${hours[index]}'),
                        onTap: onEmptyHourTap == null
                            ? null
                            : () => onEmptyHourTap!(
                                DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  hours[index],
                                ),
                              ),
                        child: CustomPaint(
                          painter: _DashedLinePainter(
                            color: AppColors.outlineVariant,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                for (final placement in layout.placements)
                  Positioned(
                    top: placement.top,
                    left: 0,
                    right: 0,
                    height: placement.height,
                    child: CalendarEventCard(
                      event: placement.event,
                      dense: true,
                      onTap: onEventTap == null
                          ? null
                          : () => onEventTap!(placement.event),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventPlacement {
  const _EventPlacement({
    required this.event,
    required this.top,
    required this.height,
  });

  final CalendarEvent event;
  final double top;
  final double height;
}

class _DayLayout {
  const _DayLayout({
    required this.hourHeights,
    required this.hourTops,
    required this.placements,
    required this.pxPerMinute,
    required this.timelineHeight,
  });

  final List<double> hourHeights;
  final List<double> hourTops;
  final List<_EventPlacement> placements;
  final double pxPerMinute;
  final double timelineHeight;
}

int _durationMinutes(CalendarEvent event) {
  final minutes = event.endsAt.difference(event.startsAt).inMinutes;
  return minutes <= 0 ? 60 : minutes;
}

double _cardHeightFor(CalendarEvent event, double pxPerMinute) {
  final durationHeight = _durationMinutes(event) * pxPerMinute;
  return durationHeight < _minCardHeight ? _minCardHeight : durationHeight;
}

/// Day-wide minutes→pixels scale (capped so short events do not explode the day).
double _pxPerMinuteFor(List<CalendarEvent> events) {
  var needed = _basePxPerMinute;
  for (final event in events) {
    final duration = _durationMinutes(event);
    // Short events inflate scale; ignore under 30m for the driver (design risk).
    if (duration < 30) continue;
    final candidate = _minCardHeight / duration;
    if (candidate > needed) needed = candidate;
  }
  if (needed > _maxPxPerMinute) return _maxPxPerMinute;
  return needed;
}

bool _isContainedInStartHour(CalendarEvent event) {
  return _durationMinutes(event) <= 60;
}

List<double> _hourHeightsFor({
  required List<int> hours,
  required List<CalendarEvent> events,
  required double pxPerMinute,
}) {
  final base = 60 * pxPerMinute;
  final heights = List<double>.filled(hours.length, base);

  for (final event in events) {
    final startIndex = hours.indexOf(event.startsAt.hour);
    if (startIndex < 0) continue;

    if (_isContainedInStartHour(event)) {
      // Expand the start-hour row so the full card fits below the minute
      // offset and does not paint into the next hour's band.
      final offsetInHour = event.startsAt.minute * pxPerMinute;
      final cardHeight = _cardHeightFor(event, pxPerMinute);
      final needed = offsetInHour + cardHeight;
      if (needed > heights[startIndex]) heights[startIndex] = needed;
      continue;
    }

    // Longer events: keep continuous clock bands; inflate hours if min-card
    // makes a slice taller than the proportional share of [h, h+1).
    final duration = _durationMinutes(event);
    final cardHeight = _cardHeightFor(event, pxPerMinute);
    for (var index = 0; index < hours.length; index++) {
      final hour = hours[index];
      final hourStart = DateTime(
        event.startsAt.year,
        event.startsAt.month,
        event.startsAt.day,
        hour,
      );
      final hourEnd = hourStart.add(const Duration(hours: 1));
      final overlapStart = event.startsAt.isAfter(hourStart)
          ? event.startsAt
          : hourStart;
      final overlapEnd = event.endsAt.isBefore(hourEnd)
          ? event.endsAt
          : hourEnd;
      if (!overlapStart.isBefore(overlapEnd)) continue;

      final sliceMin = overlapEnd.difference(overlapStart).inMinutes;
      if (sliceMin <= 0) continue;
      final leadMin = overlapStart.difference(hourStart).inMinutes;
      final needed = leadMin * pxPerMinute + cardHeight * (sliceMin / duration);
      if (needed > heights[index]) heights[index] = needed;
    }
  }

  return heights;
}

List<double> _prefixTops(List<double> hourHeights) {
  final tops = List<double>.filled(hourHeights.length, 0);
  for (var index = 1; index < hourHeights.length; index++) {
    tops[index] = tops[index - 1] + hourHeights[index - 1];
  }
  return tops;
}

double _offsetFor(
  DateTime time,
  List<int> hours,
  List<double> hourTops,
  double pxPerMinute,
) {
  final index = hours.indexOf(time.hour);
  final safeIndex = index >= 0 ? index : 0;
  return hourTops[safeIndex] + time.minute * pxPerMinute;
}

List<_EventPlacement> _placeEvents({
  required List<CalendarEvent> events,
  required List<int> hours,
  required List<double> hourTops,
  required double pxPerMinute,
}) {
  final sorted = [...events]
    ..sort((left, right) {
      final byStart = left.startsAt.compareTo(right.startsAt);
      if (byStart != 0) return byStart;
      return left.id.compareTo(right.id);
    });

  final placements = <_EventPlacement>[];

  for (final event in sorted) {
    final naturalTop = _offsetFor(event.startsAt, hours, hourTops, pxPerMinute);
    final height = _cardHeightFor(event, pxPerMinute);

    var top = naturalTop;
    for (final previous in placements) {
      if (!_timeOverlaps(previous.event, event)) continue;
      final stackedTop = previous.top + previous.height + 6;
      if (stackedTop > top) top = stackedTop;
    }

    placements.add(_EventPlacement(event: event, top: top, height: height));
  }

  return placements;
}

_DayLayout _layoutDay(List<CalendarEvent> events, List<int> hours) {
  final pxPerMinute = _pxPerMinuteFor(events);
  final hourHeights = _hourHeightsFor(
    hours: hours,
    events: events,
    pxPerMinute: pxPerMinute,
  );
  final hourTops = _prefixTops(hourHeights);
  final placements = _placeEvents(
    events: events,
    hours: hours,
    hourTops: hourTops,
    pxPerMinute: pxPerMinute,
  );

  final hoursExtent = hourHeights.isEmpty
      ? 0.0
      : hourTops.last + hourHeights.last;
  final contentExtent = placements.isEmpty
      ? hoursExtent
      : placements
            .map((placement) => placement.top + placement.height)
            .reduce((left, right) => left > right ? left : right);
  final timelineHeight = contentExtent > hoursExtent
      ? contentExtent + 8
      : hoursExtent;

  return _DayLayout(
    hourHeights: hourHeights,
    hourTops: hourTops,
    placements: placements,
    pxPerMinute: pxPerMinute,
    timelineHeight: timelineHeight,
  );
}

bool _timeOverlaps(CalendarEvent left, CalendarEvent right) {
  return left.startsAt.isBefore(right.endsAt) &&
      right.startsAt.isBefore(left.endsAt);
}

Set<int> _hoursNeedingHalfHourLabel(
  List<CalendarEvent> events,
  List<int> hours,
) {
  final hourSet = hours.toSet();
  final result = <int>{};
  for (final event in events) {
    if (event.startsAt.minute == 30 && hourSet.contains(event.startsAt.hour)) {
      result.add(event.startsAt.hour);
    }
    if (event.endsAt.minute == 30) {
      final endHour = event.endsAt.hour;
      // End at HH:30 still "belongs" to hour HH for the tick.
      if (hourSet.contains(endHour)) result.add(endHour);
    }
  }
  return result;
}

List<int> _hoursCoveredByRange(DateTime start, DateTime end) {
  final hours = <int>{};
  var cursor = DateTime(start.year, start.month, start.day, start.hour);
  if (!cursor.isBefore(end)) {
    hours.add(start.hour.clamp(0, 23));
    return hours.toList()..sort();
  }
  while (cursor.isBefore(end)) {
    hours.add(cursor.hour);
    cursor = cursor.add(const Duration(hours: 1));
  }
  return hours.toList()..sort();
}

List<int> _hoursFromMinuteWindow(int startMinute, int endMinute) {
  final hours = <int>{};
  var minute = startMinute;
  while (minute < endMinute) {
    hours.add((minute ~/ 60).clamp(0, 23));
    minute += 60;
  }
  return hours.toList()..sort();
}

/// Working hours for [day]: weekly availability windows ∪ created slots.
List<int> workingHoursForDay({
  required DateTime day,
  List<AvailabilityWindow> windows = const [],
  List<ScheduleSlot> slots = const [],
}) {
  final target = calendarDateOnly(day);
  final hours = <int>{};

  for (final window in windows) {
    if (window.dayOfWeek != target.weekday) continue;
    hours.addAll(_hoursFromMinuteWindow(window.startMinute, window.endMinute));
  }

  for (final slot in slots) {
    final start = DateTime.parse(slot.startsAt).toLocal();
    if (!isSameCalendarDay(start, target)) continue;
    final end = DateTime.parse(slot.endsAt).toLocal();
    hours.addAll(_hoursCoveredByRange(start, end));
  }

  return hours.toList()..sort();
}

/// Hours rendered on the timeline.
///
/// - Always include [workingHours] (trainer schedule), even if empty of bookings.
/// - Also include hours of events that fall outside working hours (e.g. 23:00),
///   without filling empty gaps between the end of the schedule and that event.
/// - Empty day with no schedule → default 08–20 band.
List<int> _hoursForTimeline(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final working = {...workingHours};
  final hours = <int>{...working};

  for (final event in events) {
    for (final hour in _hoursCoveredByRange(event.startsAt, event.endsAt)) {
      if (working.isEmpty || !working.contains(hour)) {
        hours.add(hour);
      }
    }
  }

  if (hours.isEmpty) {
    return [
      for (var hour = _defaultStartHour; hour < _defaultEndHour; hour++) hour,
    ];
  }

  return hours.toList()..sort();
}

@visibleForTesting
List<int> debugTimelineHours(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) => _hoursForTimeline(events, workingHours: workingHours);

@visibleForTesting
double debugTimelinePxPerMinute(List<CalendarEvent> events) =>
    _pxPerMinuteFor(events);

@visibleForTesting
List<double> debugTimelineHourHeights(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final hours = debugTimelineHours(events, workingHours: workingHours);
  return _layoutDay(events, hours).hourHeights;
}

@visibleForTesting
List<double> debugTimelineTops(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final hours = debugTimelineHours(events, workingHours: workingHours);
  return _layoutDay(
    events,
    hours,
  ).placements.map((placement) => placement.top).toList(growable: false);
}

@visibleForTesting
List<double> debugTimelineHeights(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final hours = debugTimelineHours(events, workingHours: workingHours);
  return _layoutDay(
    events,
    hours,
  ).placements.map((placement) => placement.height).toList(growable: false);
}

@visibleForTesting
double debugTimelineOffsetFor(
  DateTime time,
  List<int> hours, {
  List<CalendarEvent> events = const [],
}) {
  final layout = _layoutDay(events, hours);
  return _offsetFor(time, hours, layout.hourTops, layout.pxPerMinute);
}

@visibleForTesting
Set<int> debugHalfHourLabelHours(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final hours = debugTimelineHours(events, workingHours: workingHours);
  return _hoursNeedingHalfHourLabel(events, hours);
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
