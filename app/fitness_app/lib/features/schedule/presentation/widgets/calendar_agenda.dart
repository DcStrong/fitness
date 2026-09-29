import 'package:flutter/material.dart';

import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../domain/calendar_events.dart';
import 'calendar_event_card.dart';

class CalendarAgenda extends StatelessWidget {
  const CalendarAgenda({required this.events, this.onEventTap, super.key});

  final List<CalendarEvent> events;
  final void Function(CalendarEvent event)? onEventTap;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const FyCard(
        child: FyInfoBanner(
          message: 'На этот день событий нет',
          icon: Icons.event_busy_outlined,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final event in events)
          CalendarEventCard(
            event: event,
            onTap: onEventTap == null ? null : () => onEventTap!(event),
          ),
      ],
    );
  }
}
