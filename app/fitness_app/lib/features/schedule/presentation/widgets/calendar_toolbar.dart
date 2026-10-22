import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_segmented_control.dart';
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
    final theme = Theme.of(context);
    final clock = now ?? DateTime.now();
    final todayVisible = rangeContainsToday(mode, anchorDate, clock);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCalendarPeriodTitle(mode, anchorDate),
                    key: const Key('calendar-period-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (mode == CalendarMode.day)
                    Text(
                      formatCalendarPeriodSubtitle(mode, anchorDate, clock),
                      key: const Key('calendar-day-title'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (!todayVisible)
              TextButton(
                key: const Key('calendar-today'),
                onPressed: onToday,
                child: const Text('Сегодня'),
              ),
            _NavButton(
              buttonKey: const Key('calendar-prev'),
              tooltip: 'Назад',
              icon: Icons.chevron_left_rounded,
              onPressed: onPrevious,
            ),
            const SizedBox(width: 6),
            _NavButton(
              buttonKey: const Key('calendar-next'),
              tooltip: 'Вперёд',
              icon: Icons.chevron_right_rounded,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FySegmentedControl<CalendarMode>(
          value: mode,
          onChanged: onModeChanged,
          segments: const [
            FySegment(
              segmentKey: Key('calendar-mode-day'),
              value: CalendarMode.day,
              label: 'День',
            ),
            FySegment(
              segmentKey: Key('calendar-mode-week'),
              value: CalendarMode.week,
              label: 'Неделя',
            ),
            FySegment(
              segmentKey: Key('calendar-mode-month'),
              value: CalendarMode.month,
              label: 'Месяц',
            ),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          key: buttonKey,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
