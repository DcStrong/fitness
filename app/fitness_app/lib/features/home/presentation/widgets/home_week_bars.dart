import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../schedule/data/schedule_models.dart';
import '../../../schedule/domain/calendar_range.dart';
import '../../domain/home_schedule.dart';
import '../home_format.dart';

/// Load of the current week as bars: one per day, today in brand colour.
class HomeWeekBars extends StatelessWidget {
  const HomeWeekBars({required this.sessions, required this.now, super.key});

  final List<TrainingSession> sessions;
  final DateTime now;

  static const _barAreaHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = daysInWeek(now);
    final counts = homeWeekBookedCounts(sessions, now);
    final maxCount = math.max(1, counts.fold<int>(0, math.max));
    final today = calendarDateOnly(now);

    return FyCard(
      key: const Key('home-week-bars'),
      onTap: () => context.go('/schedule'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Неделя', style: theme.textTheme.titleMedium),
              ),
              Text(
                formatHomeWeekRange(days.first),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < days.length; index++)
                Expanded(
                  child: _DayBar(
                    key: Key('home-week-bar-$index'),
                    label: formatHomeWeekdayShort(days[index]),
                    count: counts[index],
                    height: counts[index] == 0
                        ? 6
                        : 12 + (_barAreaHeight - 12) * counts[index] / maxCount,
                    isToday: isSameCalendarDay(days[index], today),
                    isPast: days[index].isBefore(today),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.count,
    required this.height,
    required this.isToday,
    required this.isPast,
    super.key,
  });

  final String label;
  final int count;
  final double height;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final color = isToday
        ? AppColors.primary
        : isPast
        ? AppColors.sunken
        : AppColors.primary.withValues(alpha: 0.28);
    return Semantics(
      label: '$label: $count',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: HomeWeekBars._barAreaHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isToday ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
