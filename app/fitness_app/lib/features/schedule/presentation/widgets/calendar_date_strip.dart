import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/calendar_range.dart';
import 'calendar_period_format.dart';

class CalendarDateStrip extends StatelessWidget {
  const CalendarDateStrip({
    required this.selectedDate,
    required this.onSelectDate,
    this.now,
    super.key,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = calendarDateOnly(now ?? DateTime.now());
    final days = daysInWeek(selectedDate);

    return Semantics(
      label: 'Лента дат недели',
      child: SizedBox(
        key: const Key('calendar-date-strip'),
        height: 64,
        child: Row(
          children: [
            for (final day in days)
              Expanded(
                child: _DateStripCell(
                  day: day,
                  selected: isSameCalendarDay(day, selectedDate),
                  isToday: isSameCalendarDay(day, today),
                  onTap: () => onSelectDate(day),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateStripCell extends StatelessWidget {
  const _DateStripCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = weekdayShortRu[mondayBasedWeekday(day)];
    final label = isToday
        ? 'Сегодня, $weekday ${day.day}'
        : '$weekday ${day.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('calendar-strip-day-${calendarDayKey(day)}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? AppColors.mintSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Semantics(
              button: true,
              selected: selected,
              label: label,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isToday ? 'Сегодня' : weekday,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                fontSize: 10,
                                color: selected || isToday
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                color: selected || isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
