import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_chip.dart';
import '../../domain/calendar_events.dart';
import '../../domain/calendar_range.dart';
import 'calendar_agenda.dart';
import 'calendar_period_format.dart';

const _requestAmber = Color(0xFFE0A800);

class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    required this.anchorDate,
    required this.selectedDate,
    required this.events,
    required this.onSelectDate,
    this.onEventTap,
    super.key,
  });

  final DateTime anchorDate;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onSelectDate;
  final void Function(CalendarEvent event)? onEventTap;

  @override
  Widget build(BuildContext context) {
    final days = daysInWeek(anchorDate);
    final selected = calendarDateOnly(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final day in days) ...[
          _WeekDayRow(
            day: day,
            selected: isSameCalendarDay(day, selected),
            counts: _typeCounts(events, day),
            onTap: () => onSelectDate(day),
          ),
          if (isSameCalendarDay(day, selected)) ...[
            const SizedBox(height: 12),
            CalendarAgenda(
              events: eventsOnLocalDay(events, day),
              onEventTap: onEventTap,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  Map<CalendarEventType, int> _typeCounts(
    List<CalendarEvent> events,
    DateTime day,
  ) {
    final dayEvents = eventsOnLocalDay(events, day);
    return {
      for (final type in CalendarEventType.values)
        type: dayEvents.where((event) => event.type == type).length,
    };
  }
}

class _WeekDayRow extends StatelessWidget {
  const _WeekDayRow({
    required this.day,
    required this.selected,
    required this.counts,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final Map<CalendarEventType, int> counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = weekdayShortRu[mondayBasedWeekday(day)];

    return Material(
      key: Key('calendar-week-day-${calendarDayKey(day)}'),
      color: selected ? AppColors.mintSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  weekday,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
              Text(
                '${day.day}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (counts[CalendarEventType.session]! > 0)
                FyChip(
                  label: '${counts[CalendarEventType.session]}',
                  compact: true,
                  showCheckmark: false,
                  selected: true,
                  selectedColor: AppColors.mintSoft,
                  selectedForeground: AppColors.primary,
                ),
              if (counts[CalendarEventType.availability]! > 0) ...[
                const SizedBox(width: 6),
                FyChip(
                  label: '${counts[CalendarEventType.availability]}',
                  compact: true,
                  showCheckmark: false,
                  selected: false,
                  outlined: true,
                  foregroundColor: AppColors.secondary,
                  backgroundColor: AppColors.canvas,
                ),
              ],
              if (counts[CalendarEventType.request]! > 0) ...[
                const SizedBox(width: 6),
                FyChip(
                  label: '${counts[CalendarEventType.request]}',
                  compact: true,
                  showCheckmark: false,
                  selected: true,
                  selectedColor: const Color(0x29E0A800),
                  selectedForeground: _requestAmber,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
