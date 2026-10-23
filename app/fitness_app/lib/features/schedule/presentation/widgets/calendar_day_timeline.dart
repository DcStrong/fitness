import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/availability_models.dart';
import '../../data/schedule_models.dart';
import '../../domain/calendar_events.dart';
import '../../domain/calendar_range.dart';
import '../schedule_format.dart';
import 'calendar_event_card.dart';

/// One hour is always 64 px, so a card's edges sit exactly where its clock
/// times are on the gutter (DS v2 calendar).
const timelineHourHeight = 64.0;
const _pxPerMinute = timelineHourHeight / 60;
const _gutterWidth = 56.0;
const _minCardHeight = 52.0;
const _cardGap = 2.0;
const _defaultStartHour = 8;
const _defaultEndHour = 20;

/// An hour label is hidden when an off-hour marker sits closer than this.
const _labelClearance = 14.0;

class CalendarDayTimeline extends StatelessWidget {
  const CalendarDayTimeline({
    required this.events,
    required this.selectedDate,
    this.workingHours = const [],
    this.onEventTap,
    this.onEmptyHourTap,
    this.now,
    super.key,
  });

  final List<CalendarEvent> events;
  final DateTime selectedDate;

  /// Hours from the trainer's schedule (weekly windows + created slots).
  /// Always kept visible even when empty of bookings.
  final List<int> workingHours;

  final void Function(CalendarEvent event)? onEventTap;
  final void Function(DateTime localHourStart)? onEmptyHourTap;

  /// Clock for the «now» marker; defaults to [DateTime.now].
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final hours = debugTimelineHours(events, workingHours: workingHours);
    final layout = _layoutDay(events, hours);
    final firstHour = hours.first;
    double yFor(DateTime time) => _offsetFor(time, firstHour);

    final markers = _offHourMarkers(events, hours);
    final markerYs = [for (final marker in markers) yFor(marker)];
    final clock = now ?? DateTime.now();
    final showNow =
        isSameCalendarDay(clock, selectedDate) &&
        clock.hour >= firstHour &&
        clock.hour <= hours.last;
    final nowY = showNow ? yFor(clock) : null;

    bool labelBlocked(double y) =>
        markerYs.any((markerY) => (markerY - y).abs() < _labelClearance) ||
        (nowY != null && (nowY - y).abs() < _labelClearance + 4);

    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final markerStyle = labelStyle?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w800,
    );

    return SizedBox(
      key: const Key('calendar-day-timeline'),
      height: layout.height + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hour grid: a solid line and a label on every hour boundary,
          // including the closing one.
          for (var index = 0; index <= hours.length; index++) ...[
            Positioned(
              top: index * timelineHourHeight,
              left: _gutterWidth,
              right: 0,
              child: const Divider(height: 1, color: AppColors.border),
            ),
            if (!labelBlocked(index * timelineHourHeight))
              Positioned(
                top: index * timelineHourHeight - 8,
                left: 0,
                width: _gutterWidth - 8,
                child: Text(
                  _hourLabel((firstHour + index) % 24),
                  key: Key('calendar-hour-label-${firstHour + index}'),
                  style: labelStyle,
                ),
              ),
          ],
          for (var index = 0; index < hours.length; index++)
            Positioned(
              top: index * timelineHourHeight,
              left: _gutterWidth,
              right: 0,
              height: timelineHourHeight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('calendar-empty-hour-${hours[index]}'),
                  hoverColor: Colors.transparent,
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
                ),
              ),
            ),
          // Off-hour boundaries (13:20, 14:20…) printed in the gutter.
          for (var index = 0; index < markers.length; index++)
            Positioned(
              top: markerYs[index] - 8,
              left: 0,
              width: _gutterWidth,
              child: Row(
                key: Key('calendar-off-hour-${formatTime(markers[index])}'),
                children: [
                  Text(formatTime(markers[index]), style: markerStyle),
                  const Spacer(),
                  Container(width: 8, height: 2, color: AppColors.primary),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          for (final placement in layout.placements)
            Positioned(
              top: placement.top,
              left: _gutterWidth + 4,
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
          // «Now» lives in the gutter only, so it never crosses card text.
          if (nowY != null)
            Positioned(
              top: nowY - 11,
              left: 0,
              width: _gutterWidth + 4,
              child: Row(
                key: const Key('calendar-now-marker'),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      formatTime(clock),
                      style: markerStyle?.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 2, color: AppColors.error)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

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
  const _DayLayout({required this.placements, required this.height});

  final List<_EventPlacement> placements;
  final double height;
}

double _offsetFor(DateTime time, int firstHour) {
  final minutes = (time.hour - firstHour) * 60 + time.minute;
  return minutes * _pxPerMinute;
}

_DayLayout _layoutDay(List<CalendarEvent> events, List<int> hours) {
  final firstHour = hours.first;
  final sorted = [...events]
    ..sort((left, right) {
      final byStart = left.startsAt.compareTo(right.startsAt);
      if (byStart != 0) return byStart;
      return left.id.compareTo(right.id);
    });

  final placements = <_EventPlacement>[];
  for (final event in sorted) {
    final top = _offsetFor(event.startsAt, firstHour);
    var bottom = event.endsAt.isAfter(event.startsAt)
        ? _offsetFor(event.endsAt, firstHour)
        : top + timelineHourHeight;
    // Midnight end is the next day: clamp to the end of the grid.
    if (!isSameCalendarDay(event.startsAt, event.endsAt)) {
      bottom = (hours.last + 1 - firstHour) * timelineHourHeight;
    }
    var placedTop = top + 1;
    // Only a card that would otherwise collide is pushed down; everything
    // else stays exactly on the clock.
    for (final previous in placements) {
      final previousBottom = previous.top + previous.height;
      if (previousBottom + _cardGap > placedTop && previous.top < bottom) {
        placedTop = previousBottom + _cardGap;
      }
    }
    final exactHeight = bottom - placedTop - 1;
    final height = exactHeight < _minCardHeight ? _minCardHeight : exactHeight;
    placements.add(
      _EventPlacement(event: event, top: placedTop, height: height),
    );
  }

  final gridHeight = hours.length * timelineHourHeight;
  final contentHeight = placements.fold<double>(
    0,
    (max, placement) => placement.top + placement.height > max
        ? placement.top + placement.height
        : max,
  );
  return _DayLayout(
    placements: placements,
    height: (contentHeight > gridHeight ? contentHeight : gridHeight) + 8,
  );
}

/// Event boundaries that do not fall on a whole hour.
List<DateTime> _offHourMarkers(List<CalendarEvent> events, List<int> hours) {
  final seen = <int>{};
  final markers = <DateTime>[];
  for (final event in events) {
    for (final time in [event.startsAt, event.endsAt]) {
      if (time.minute == 0) continue;
      if (!isSameCalendarDay(time, event.startsAt)) continue;
      if (time.hour < hours.first || time.hour > hours.last) continue;
      final key = time.hour * 60 + time.minute;
      if (seen.add(key)) markers.add(time);
    }
  }
  markers.sort();
  return markers;
}

List<int> _hoursCoveredByRange(DateTime start, DateTime end) {
  final hours = <int>{};
  var cursor = DateTime(start.year, start.month, start.day, start.hour);
  if (!cursor.isBefore(end)) {
    hours.add(start.hour.clamp(0, 23));
    return hours.toList()..sort();
  }
  while (cursor.isBefore(end) && isSameCalendarDay(cursor, start)) {
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

/// Hours rendered on the timeline: one continuous run from the first to the
/// last hour that has work or events, so the grid never jumps (09 → 23).
/// An empty day with no schedule shows the default 08–20 band.
@visibleForTesting
List<int> debugTimelineHours(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final hours = <int>{...workingHours};
  for (final event in events) {
    hours.addAll(_hoursCoveredByRange(event.startsAt, event.endsAt));
  }
  if (hours.isEmpty) {
    return [
      for (var hour = _defaultStartHour; hour < _defaultEndHour; hour++) hour,
    ];
  }
  final first = hours.reduce((a, b) => a < b ? a : b);
  final last = hours.reduce((a, b) => a > b ? a : b);
  return [for (var hour = first; hour <= last; hour++) hour];
}

@visibleForTesting
List<double> debugTimelineTops(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final hours = debugTimelineHours(events, workingHours: workingHours);
  return [for (final p in _layoutDay(events, hours).placements) p.top];
}

@visibleForTesting
List<double> debugTimelineHeights(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final hours = debugTimelineHours(events, workingHours: workingHours);
  return [for (final p in _layoutDay(events, hours).placements) p.height];
}

@visibleForTesting
List<String> debugOffHourMarkers(
  List<CalendarEvent> events, {
  List<int> workingHours = const [],
}) {
  final hours = debugTimelineHours(events, workingHours: workingHours);
  return [for (final time in _offHourMarkers(events, hours)) formatTime(time)];
}
