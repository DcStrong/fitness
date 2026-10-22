import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/fy_status_chip.dart';
import '../../domain/calendar_events.dart';
import '../schedule_format.dart';

/// DS v2 calendar card. Sessions and requests are white cards with a status
/// chip; free time is a dashed, filled outline so it never reads as booked.
class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    required this.event,
    this.onTap,
    this.dense = false,
    super.key,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;

  /// Timeline placement: fills the given height, tighter padding.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final interval =
        '${formatTime(event.startsAt)} – ${formatTime(event.endsAt)}';
    final semanticsLabel =
        '${event.typeLabel}, $interval, ${event.title}, ${event.modeLabel}';
    final isFree = event.type == CalendarEventType.availability;
    final radius = BorderRadius.circular(AppRadii.control);

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 6 : 12),
      child: _CardContent(event: event, interval: interval, dense: dense),
    );

    final card = Material(
      key: Key('calendar-event-${event.id}'),
      color: isFree ? AppColors.sunken : AppColors.surface,
      shape: isFree
          ? RoundedRectangleBorder(borderRadius: radius)
          : RoundedRectangleBorder(
              borderRadius: radius,
              side: const BorderSide(color: AppColors.border),
            ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: isFree
            ? CustomPaint(
                painter: _DashedBorderPainter(
                  color: AppColors.borderStrong,
                  radius: AppRadii.control,
                ),
                child: content,
              )
            : content,
      ),
    );

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: dense ? 0 : 10),
        child: card,
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.event,
    required this.interval,
    required this.dense,
  });

  final CalendarEvent event;
  final String interval;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFree = event.type == CalendarEventType.availability;
    final muted = isFree || event.isTerminal;
    final status = calendarEventStatus(event);

    final details = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: interval,
            style: TextStyle(
              fontWeight: isFree ? FontWeight.w500 : FontWeight.w700,
              color: isFree ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
          TextSpan(
            text: ' · ${event.modeLabel}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall,
    );

    return Align(
      alignment: dense ? Alignment.centerLeft : Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: muted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: isFree ? FontWeight.w600 : FontWeight.w700,
                    ),
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 8),
                  // The name keeps at least half of the row.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth / 2,
                    ),
                    child: FyStatusChip(status: status.$1, label: status.$2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          details,
          if (!dense && event.caption != null && event.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                event.caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip shown on a calendar card; free time has none.
(FyStatus, String)? calendarEventStatus(CalendarEvent event) {
  return switch (event.type) {
    CalendarEventType.availability => null,
    CalendarEventType.request => (FyStatus.waiting, 'Ждёт ответа'),
    CalendarEventType.session => switch (event.sessionStatus) {
      'completed' => (FyStatus.done, 'Проведено'),
      'no_show' => (FyStatus.noShow, 'Не пришёл'),
      'cancelled' => (FyStatus.cancelled, 'Отменено'),
      _ => (FyStatus.confirmed, 'Записан'),
    },
  };
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.6),
      );
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
