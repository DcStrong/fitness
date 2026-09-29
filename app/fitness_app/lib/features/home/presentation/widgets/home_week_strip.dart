import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../schedule/data/schedule_models.dart';
import '../../../schedule/domain/calendar_range.dart';
import '../../../schedule/presentation/widgets/calendar_period_format.dart';
import '../../domain/home_schedule.dart';

class HomeWeekStrip extends StatefulWidget {
  const HomeWeekStrip({
    required this.sessions,
    required this.anchor,
    this.now,
    this.upcomingOnly = false,
    super.key,
  });

  final List<TrainingSession> sessions;
  final DateTime anchor;
  final DateTime? now;
  final bool upcomingOnly;

  @override
  State<HomeWeekStrip> createState() => _HomeWeekStripState();
}

class _HomeWeekStripState extends State<HomeWeekStrip> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = calendarDateOnly(widget.now ?? widget.anchor);
  }

  @override
  void didUpdateWidget(covariant HomeWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final today = calendarDateOnly(widget.now ?? widget.anchor);
    if (!isSameCalendarDay(_selectedDay, today) &&
        isSameCalendarDay(oldWidget.now ?? oldWidget.anchor, _selectedDay)) {
      _selectedDay = today;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = calendarDateOnly(widget.now ?? DateTime.now());
    final days = daysInWeek(widget.anchor);
    final width = MediaQuery.sizeOf(context).width;
    final showHints = width >= 360 && !widget.upcomingOnly;

    return Semantics(
      label: 'Мини-календарь недели',
      child: SizedBox(
        key: const Key('home-week-strip'),
        height: showHints ? 98 : 64,
        child: Row(
          children: [
            for (final day in days)
              Expanded(
                child: _HomeWeekStripCell(
                  day: day,
                  selected: isSameCalendarDay(day, _selectedDay),
                  isToday: isSameCalendarDay(day, today),
                  hint: showHints ? _hintForDay(day, today) : null,
                  onTap: () {
                    setState(() => _selectedDay = day);
                    context.go('/schedule');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _hintForDay(DateTime day, DateTime today) {
    if (widget.upcomingOnly && day.isBefore(today)) {
      return null;
    }
    return homeSessionHintForDay(widget.sessions, day);
  }
}

class _HomeWeekStripCell extends StatelessWidget {
  const _HomeWeekStripCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
    this.hint,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final String? hint;
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
          key: Key('home-week-day-${calendarDayKey(day)}'),
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
              label: hint == null ? label : '$label, $hint',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isToday ? 'Сегодня' : weekday,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: selected || isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
