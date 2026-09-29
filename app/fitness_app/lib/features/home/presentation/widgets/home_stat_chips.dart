import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../cubit/home_state.dart';

class HomeStatChips extends StatelessWidget {
  const HomeStatChips({
    required this.isTrainer,
    required this.todayCount,
    required this.weekCount,
    this.state,
    super.key,
  });

  final bool isTrainer;
  final int todayCount;
  final int weekCount;
  final HomeState? state;

  @override
  Widget build(BuildContext context) {
    if (!isTrainer) {
      return _StudentChips(todayCount: todayCount, weekCount: weekCount);
    }

    final pendingStatus = state?.pendingCountStatus;
    final pendingCount = state?.pendingRequestCount;
    final freeSlotCount = state?.freeSlotCount;
    final weekLabel = freeSlotCount != null ? 'Свободно' : 'На неделе';
    final weekValue = freeSlotCount ?? weekCount;

    final cards = <Widget>[
      _TrainerStatCard(
        key: const Key('home-stat-chip-today'),
        icon: Icons.task_alt_rounded,
        label: 'Сегодня',
        value: todayCount,
      ),
      if (pendingStatus == PendingCountStatus.success && pendingCount != null)
        _TrainerStatCard(
          key: const Key('home-stat-chip-requests'),
          icon: Icons.person_outline_rounded,
          label: 'Заявки',
          value: pendingCount,
          onTap: pendingCount > 0
              ? () => context.go('/booking-requests/inbox')
              : null,
        ),
      _TrainerStatCard(
        key: const Key('home-stat-chip-week'),
        icon: Icons.calendar_today_outlined,
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

class _StudentChips extends StatelessWidget {
  const _StudentChips({required this.todayCount, required this.weekCount});

  final int todayCount;
  final int weekCount;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _HomeStatChip(
        key: const Key('home-stat-chip-today'),
        label: 'Сегодня · $todayCount',
      ),
      _HomeStatChip(
        key: const Key('home-stat-chip-book'),
        label: 'Запись',
        onTap: () => context.go('/schedule/book'),
      ),
      _HomeStatChip(
        key: const Key('home-stat-chip-week'),
        label: 'На неделе · $weekCount',
        onTap: () => context.go('/schedule'),
      ),
    ];

    return SingleChildScrollView(
      key: const Key('home-stat-chips'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < chips.length; index++) ...[
            chips[index],
            if (index < chips.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TrainerStatCard extends StatelessWidget {
  const _TrainerStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FyCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.mintSoft,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 28,
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeStatChip extends StatelessWidget {
  const _HomeStatChip({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}
