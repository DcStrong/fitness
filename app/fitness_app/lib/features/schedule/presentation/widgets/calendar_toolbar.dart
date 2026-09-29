import 'package:flutter/material.dart';

import '../../domain/calendar_range.dart';
import 'calendar_period_format.dart';

class CalendarToolbar extends StatelessWidget {
  const CalendarToolbar({
    required this.mode,
    required this.anchorDate,
    required this.onModeChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    this.now,
    super.key,
  });

  final CalendarMode mode;
  final DateTime anchorDate;
  final ValueChanged<CalendarMode> onModeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final todayVisible = rangeContainsToday(
      mode,
      anchorDate,
      now ?? DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SegmentedButton<CalendarMode>(
              segments: const [
                ButtonSegment(
                  value: CalendarMode.day,
                  label: Text('День', key: Key('calendar-mode-day')),
                ),
                ButtonSegment(
                  value: CalendarMode.week,
                  label: Text('Неделя', key: Key('calendar-mode-week')),
                ),
                ButtonSegment(
                  value: CalendarMode.month,
                  label: Text('Месяц', key: Key('calendar-mode-month')),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) => onModeChanged(selection.first),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              key: const Key('calendar-prev'),
              tooltip: 'Назад',
              visualDensity: VisualDensity.compact,
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatCalendarPeriodTitle(mode, anchorDate),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              key: const Key('calendar-next'),
              tooltip: 'Вперёд',
              visualDensity: VisualDensity.compact,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        if (!todayVisible)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              key: const Key('calendar-today'),
              onPressed: onToday,
              child: const Text('Сегодня'),
            ),
          ),
      ],
    );
  }
}
