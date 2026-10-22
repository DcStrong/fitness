import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Session / request statuses of DS v2. A status is a label, never a button.
enum FyStatus { confirmed, waiting, done, noShow, cancelled }

/// Always icon + word, so colour is never the only signal.
class FyStatusChip extends StatelessWidget {
  const FyStatusChip({required this.status, this.label, super.key});

  final FyStatus status;

  /// Overrides the default word («Ждёт ответа» → «5 ч», «Осталось 6»).
  final String? label;

  static String defaultLabel(FyStatus status) => switch (status) {
    FyStatus.confirmed => 'Подтверждено',
    FyStatus.waiting => 'Ждёт ответа',
    FyStatus.done => 'Проведено',
    FyStatus.noShow => 'Не пришёл',
    FyStatus.cancelled => 'Отменено',
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      FyStatus.confirmed => (
        AppColors.confirmedBg,
        AppColors.confirmedFg,
        Icons.check_rounded,
      ),
      FyStatus.waiting => (
        AppColors.waitingBg,
        AppColors.waitingFg,
        Icons.schedule_rounded,
      ),
      FyStatus.done => (
        AppColors.doneBg,
        AppColors.doneFg,
        Icons.info_outline_rounded,
      ),
      FyStatus.noShow => (
        AppColors.noShowBg,
        AppColors.noShowFg,
        Icons.close_rounded,
      ),
      FyStatus.cancelled => (
        AppColors.cancelledBg,
        AppColors.cancelledFg,
        Icons.remove_rounded,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label ?? defaultLabel(status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
