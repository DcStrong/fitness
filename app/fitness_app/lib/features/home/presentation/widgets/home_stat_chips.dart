import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../cubit/home_state.dart';

/// Trainer counters under the hero: today, pending requests, the week.
class HomeStatChips extends StatelessWidget {
  const HomeStatChips({
    required this.todayCount,
    required this.weekCount,
    this.state,
    super.key,
  });

  final int todayCount;
  final int weekCount;
  final HomeState? state;

  @override
  Widget build(BuildContext context) {
    final pendingStatus = state?.pendingCountStatus;
    final pendingCount = state?.pendingRequestCount;
    final freeSlotCount = state?.freeSlotCount;
    final weekLabel = freeSlotCount != null ? 'Свободно' : 'На неделе';
    final weekValue = freeSlotCount ?? weekCount;

    final cards = <Widget>[
      _TrainerStatCard(
        key: const Key('home-stat-chip-today'),
        label: 'Сегодня',
        value: todayCount,
      ),
      if (pendingStatus == PendingCountStatus.success && pendingCount != null)
        _TrainerStatCard(
          key: const Key('home-stat-chip-requests'),
          label: 'Заявки',
          value: pendingCount,
          onTap: pendingCount > 0
              ? () => context.go('/booking-requests/inbox')
              : null,
        ),
      _TrainerStatCard(
        key: const Key('home-stat-chip-week'),
        label: weekLabel,
        value: weekValue,
        onTap: () => context.go('/schedule'),
      ),
    ];

    return Row(
      key: const Key('home-stat-chips'),
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          Expanded(child: cards[index]),
          if (index < cards.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _TrainerStatCard extends StatelessWidget {
  const _TrainerStatCard({
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FyCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
