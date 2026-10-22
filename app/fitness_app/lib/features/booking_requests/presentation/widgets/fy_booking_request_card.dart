import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/fy_avatar.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_status_chip.dart';
import '../../../finance/data/money_formatter.dart';
import '../../../schedule/presentation/schedule_format.dart';
import '../../data/booking_request_models.dart';

/// Trainer inbox card (DS v2): who, when and how long is left to answer,
/// with accept as the tonal primary action.
class FyBookingRequestCard extends StatelessWidget {
  const FyBookingRequestCard({
    required this.request,
    this.processing = false,
    this.onOpen,
    this.onAccept,
    this.onAlternate,
    this.onReject,
    this.now,
    super.key,
  });

  final BookingRequest request;
  final bool processing;
  final VoidCallback? onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onAlternate;
  final VoidCallback? onReject;

  /// Clock for the time-left chip; defaults to [DateTime.now].
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final slot = request.displayedSlot;
    final theme = Theme.of(context);
    final (status, statusLabel) = _status(now ?? DateTime.now());

    return FyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(AppRadii.control),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    FyAvatar(displayName: request.counterpart.label, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.counterpart.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            MoneyFormatter.format(
                              request.quotedPriceMinor,
                              currency: request.quotedCurrency,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FyStatusChip(status: status, label: statusLabel),
                  ],
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.sunken,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            formatSlotDayRange(
                              slot.startsAt,
                              slot.endsAt,
                              now: now,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          slot.mode == 'online' ? 'Онлайн' : 'Офлайн',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (request.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: processing ? null : onAccept,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Принять'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: processing ? null : onAlternate,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Другое время', maxLines: 1),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: processing ? null : onReject,
                child: const Text('Отклонить'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (FyStatus, String) _status(DateTime clock) => switch (request.status) {
    BookingRequestStatus.pending => (
      FyStatus.waiting,
      formatTimeLeft(request.expiresAt.difference(clock)),
    ),
    BookingRequestStatus.accepted => (FyStatus.confirmed, 'Принята'),
    BookingRequestStatus.rejected => (FyStatus.noShow, 'Отклонена'),
    BookingRequestStatus.withdrawn => (FyStatus.cancelled, 'Отозвана учеником'),
    BookingRequestStatus.expired => (FyStatus.cancelled, 'Истекла'),
  };
}

/// Compact time left to answer: «5 ч», «40 мин», «1 д».
String formatTimeLeft(Duration remaining) {
  if (remaining.inMinutes <= 0) return 'Срок вышел';
  if (remaining.inHours >= 24) return '${remaining.inDays} д';
  if (remaining.inHours >= 1) return '${remaining.inHours} ч';
  return '${remaining.inMinutes} мин';
}
