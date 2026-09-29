import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_chip.dart';
import '../../domain/calendar_events.dart';
import '../schedule_format.dart';

const _requestAmber = Color(0xFFE0A800);
const _requestAmberSoft = Color(0x29E0A800);
const _availabilitySoft = Color(0xFFF3EDE4);
const _availabilityAccent = Color(0xFFB08968);

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    required this.event,
    this.onTap,
    this.dense = false,
    super.key,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final interval =
        '${formatTime(event.startsAt)} – ${formatTime(event.endsAt)}';
    final semanticsLabel =
        '${event.typeLabel}, $interval, ${event.title}, ${event.modeLabel}';

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      child: Padding(
        padding: EdgeInsets.only(bottom: dense ? 0 : 12),
        child: FyCard(
          key: Key('calendar-event-${event.id}'),
          onTap: onTap,
          color: _backgroundColor(event),
          borderRadius: BorderRadius.circular(14),
          border: _border(event),
          boxShadow: const [],
          padding: EdgeInsets.zero,
          child: dense
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: _accentColor(event)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: _DenseContent(event: event, interval: interval),
                      ),
                    ),
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: _accentColor(event)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: _FullContent(event: event, interval: interval),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Color _backgroundColor(CalendarEvent event) => switch (event.type) {
    CalendarEventType.session =>
      event.isTerminal ? AppColors.canvas : AppColors.mintSoft,
    CalendarEventType.availability => _availabilitySoft,
    CalendarEventType.request => _requestAmberSoft,
  };

  Color _accentColor(CalendarEvent event) => switch (event.type) {
    CalendarEventType.session =>
      event.isTerminal ? AppColors.iconInactive : AppColors.primary,
    CalendarEventType.availability => _availabilityAccent,
    CalendarEventType.request => _requestAmber,
  };

  Border? _border(CalendarEvent event) {
    if (event.type != CalendarEventType.availability) return null;
    return Border.all(color: AppColors.outlineVariant);
  }
}

class _DenseContent extends StatelessWidget {
  const _DenseContent({required this.event, required this.interval});

  final CalendarEvent event;
  final String interval;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  interval,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _textColor(event),
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _ModeChip(event: event, compactLabel: true),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _textColor(event),
              height: 1.1,
            ),
          ),
          if (event.caption != null && event.caption!.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              event.caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
                height: 1.05,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullContent extends StatelessWidget {
  const _FullContent({required this.event, required this.interval});

  final CalendarEvent event;
  final String interval;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                interval,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _textColor(event),
                ),
              ),
            ),
            _ModeChip(event: event),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: _textColor(event),
          ),
        ),
        if (event.caption != null && event.caption!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            event.caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '${event.typeLabel} · ${event.modeLabel}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.event, this.compactLabel = false});

  final CalendarEvent event;
  final bool compactLabel;

  @override
  Widget build(BuildContext context) {
    final online = event.mode == 'online';
    final color = switch (event.type) {
      CalendarEventType.session => AppColors.primary,
      CalendarEventType.availability => _availabilityAccent,
      CalendarEventType.request => _requestAmber,
    };
    final label = event.type == CalendarEventType.request
        ? (compactLabel ? 'Заявка' : event.typeLabel)
        : (online ? 'Онлайн' : 'Офлайн');

    return FyChip(
      label: label,
      compact: true,
      showCheckmark: false,
      showBorder: false,
      selected: false,
      foregroundColor: color,
      backgroundColor: Colors.transparent,
      leading: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

Color _textColor(CalendarEvent event) {
  if (event.type == CalendarEventType.session && event.isTerminal) {
    return AppColors.textMuted;
  }
  return AppColors.textPrimary;
}
