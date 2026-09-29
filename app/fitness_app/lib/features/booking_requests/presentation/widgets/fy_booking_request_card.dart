import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_button.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../finance/data/money_formatter.dart';
import '../../../schedule/presentation/schedule_format.dart';
import '../../data/booking_request_models.dart';

/// Trainer inbox card aligned to the calendar concept mockup.
class FyBookingRequestCard extends StatelessWidget {
  const FyBookingRequestCard({
    required this.request,
    this.processing = false,
    this.onOpen,
    this.onAccept,
    this.onAlternate,
    this.onReject,
    super.key,
  });

  final BookingRequest request;
  final bool processing;
  final VoidCallback? onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onAlternate;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final slot = request.displayedSlot;
    final textTheme = Theme.of(context).textTheme;

    return FyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.mintSoft,
                          foregroundColor: AppColors.primary,
                          child: Text(
                            initialsFromLabel(request.counterpart.label),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            request.counterpart.label,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _MetaRow(
                      icon: Icons.calendar_today_outlined,
                      label: formatSlotDayRange(slot.startsAt, slot.endsAt),
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: MoneyFormatter.format(
                        request.quotedPriceMinor,
                        currency: request.quotedCurrency,
                      ),
                      emphasize: true,
                    ),
                    const SizedBox(height: 8),
                    if (request.isPending)
                      _DeadlineRow(expiresAt: request.expiresAt)
                    else
                      _MetaRow(
                        icon: Icons.info_outline_rounded,
                        label: _terminalLabel(request.status),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (request.isPending) ...[
            const SizedBox(height: 16),
            FyButton.primary(
              label: 'Принять',
              icon: Icons.check_rounded,
              size: FyButtonSize.medium,
              onPressed: processing ? null : onAccept,
            ),
            const SizedBox(height: 8),
            FyButton.secondary(
              label: 'Другое время',
              icon: Icons.event_available_outlined,
              size: FyButtonSize.medium,
              onPressed: processing ? null : onAlternate,
            ),
            const SizedBox(height: 8),
            FyButton.danger(
              label: 'Отклонить',
              icon: Icons.close_rounded,
              size: FyButtonSize.medium,
              onPressed: processing ? null : onReject,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.expiresAt});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.schedule_rounded, size: 18, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            formatReplyBy(expiresAt),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _CountdownText(expiresAt: expiresAt),
      ],
    );
  }
}

class _CountdownText extends StatefulWidget {
  const _CountdownText({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.expiresAt.difference(DateTime.now());
      });
    });
  }

  @override
  void didUpdateWidget(covariant _CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _remaining = widget.expiresAt.difference(DateTime.now());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatCountdown(_remaining),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.warning,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

String _terminalLabel(BookingRequestStatus status) => switch (status) {
  BookingRequestStatus.pending => 'Ожидает решения',
  BookingRequestStatus.accepted => 'Принята',
  BookingRequestStatus.rejected => 'Отклонена',
  BookingRequestStatus.withdrawn => 'Отозвана учеником',
  BookingRequestStatus.expired => 'Истекла',
};
