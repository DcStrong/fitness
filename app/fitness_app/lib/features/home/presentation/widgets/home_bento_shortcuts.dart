import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';

/// Ярлыки тренера на главной: карточки идут одна за другой на всю ширину.
class HomeBentoShortcuts extends StatelessWidget {
  const HomeBentoShortcuts({required this.canReadFinance, super.key});

  final bool canReadFinance;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('home-bento-shortcuts'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BentoTile(
          key: const Key('home-bento-students'),
          title: 'Ученики',
          subtitle: 'Клиенты, прогресс и заметки',
          icon: Icons.groups_outlined,
          goKey: const Key('home-bento-students-go'),
          onTap: () => context.go('/session-packages'),
        ),
        const SizedBox(height: 12),
        _BentoTile(
          key: const Key('home-bento-plans'),
          title: 'Планирование',
          subtitle: 'Запланировать тренировку',
          icon: Icons.assignment_outlined,
          goKey: const Key('home-bento-plans-go'),
          onTap: () => context.go('/plans'),
        ),
        const SizedBox(height: 12),
        _BentoTile(
          key: const Key('home-bento-recurring'),
          title: 'Регулярные тренировки',
          subtitle: 'Серии занятий по дням недели',
          icon: Icons.event_repeat_outlined,
          goKey: const Key('home-bento-recurring-go'),
          onTap: () => context.go('/schedule/recurring'),
        ),
        if (canReadFinance) ...[
          const SizedBox(height: 12),
          _BentoTile(
            key: const Key('home-bento-finance'),
            title: 'Финансы',
            subtitle: 'Доходы, оплаты и операции',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => context.go('/finance'),
          ),
        ],
      ],
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.goKey,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Key? goKey;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 88),
      child: FyCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: _FullWidthBody(
          title: title,
          subtitle: subtitle,
          icon: icon,
          goButton: goKey == null
              ? null
              : _GoButton(key: goKey, onPressed: onTap),
        ),
      ),
    );
  }
}

class _FullWidthBody extends StatelessWidget {
  const _FullWidthBody({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.goButton,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? goButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AccentIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        if (goButton != null) ...[const SizedBox(width: 8), goButton!],
      ],
    );
  }
}

class _AccentIcon extends StatelessWidget {
  const _AccentIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.mintSoft,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  const _GoButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.mintSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Перейти', style: TextStyle(fontWeight: FontWeight.w700)),
          Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}
