import 'package:flutter/material.dart';

import '../../../../core/widgets/fy_motion.dart';
import '../../domain/calendar_events.dart';
import 'calendar_date_strip.dart';
import 'calendar_day_timeline.dart';

class CalendarDayView extends StatelessWidget {
  const CalendarDayView({
    required this.selectedDate,
    required this.events,
    required this.onSelectDate,
    this.workingHours = const [],
    this.onEventTap,
    this.onEmptyHourTap,
    this.now,
    super.key,
  });

  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onSelectDate;
  final List<int> workingHours;
  final void Function(CalendarEvent event)? onEventTap;
  final void Function(DateTime localHourStart)? onEmptyHourTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final dayKey = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final reduceMotion = fyReduceMotion(context);

    return KeyedSubtree(
      key: const Key('calendar-day-view'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalendarDateStrip(
            selectedDate: selectedDate,
            onSelectDate: onSelectDate,
            now: now,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : FyMotion.daySwitch,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              if (reduceMotion) return child;
              final offset = Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(dayKey.toIso8601String()),
              child: CalendarDayTimeline(
                events: events,
                selectedDate: selectedDate,
                workingHours: workingHours,
                onEventTap: onEventTap,
                onEmptyHourTap: onEmptyHourTap,
                now: now,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
