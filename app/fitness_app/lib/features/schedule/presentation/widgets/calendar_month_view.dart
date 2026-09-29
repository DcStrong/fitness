import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/calendar_events.dart';
import '../../domain/calendar_range.dart';
import 'calendar_agenda.dart';
import 'calendar_period_format.dart';

const _requestAmber = Color(0xFFE0A800);

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
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
    final anchorMonth = calendarDateOnly(anchorDate).month;
    final anchorYear = calendarDateOnly(anchorDate).year;
    final gridDays = monthGridDays(anchorDate);
    final selected = calendarDateOnly(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in weekdayShortRu)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: gridDays.length,
          itemBuilder: (context, index) {
            final day = gridDays[index];
            final inMonth = day.month == anchorMonth && day.year == anchorYear;
            final isSelected = isSameCalendarDay(day, selected);
            final dayEvents = eventsOnLocalDay(events, day);
            final types = {for (final event in dayEvents) event.type};

            return _MonthDayCell(
              key: Key('calendar-month-day-${calendarDayKey(day)}'),
              day: day.day,
              muted: !inMonth,
              selected: isSelected,
              types: types,
              onTap: () => onSelectDate(day),
            );
          },
        ),
        const SizedBox(height: 16),
        const _MonthLegend(),
        const SizedBox(height: 16),
        CalendarAgenda(
          events: eventsOnLocalDay(events, selected),
          onEventTap: onEventTap,
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.muted,
    required this.selected,
    required this.types,
    required this.onTap,
    super.key,
  });

  final int day;
  final bool muted;
  final bool selected;
  final Set<CalendarEventType> types;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mintSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: muted ? AppColors.textMuted : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (types.contains(CalendarEventType.session))
                    const _EventDot(color: AppColors.primary),
                  if (types.contains(CalendarEventType.availability))
                    const Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: _EventDot(
                        color: AppColors.secondary,
                        outlined: true,
                      ),
                    ),
                  if (types.contains(CalendarEventType.request))
                    const Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: _EventDot(color: _requestAmber),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDot extends StatelessWidget {
  const _EventDot({required this.color, this.outlined = false});

  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: color, width: 1.2) : null,
      ),
    );
  }
}

class _MonthLegend extends StatelessWidget {
  const _MonthLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: const [
        _LegendItem(color: AppColors.primary, label: 'Тренировка'),
        _LegendItem(
          color: AppColors.secondary,
          label: 'Свободно',
          outlined: true,
        ),
        _LegendItem(color: _requestAmber, label: 'Заявка'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EventDot(color: color, outlined: outlined),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
