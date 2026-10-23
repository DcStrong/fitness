import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/person_name_email.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';

@immutable
class MoreMenuItem {
  const MoreMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.subtitle,
    this.switchesTab = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String route;

  /// The route lives in another tab: open that tab instead of stacking it
  /// on top of «Ещё».
  final bool switchesTab;
}

/// Trainer «Ещё» groups: work tools first, then account.
List<List<MoreMenuItem>> trainerMoreSections({required bool canReadFinance}) {
  return [
    [
      const MoreMenuItem(
        title: 'Тренировки',
        subtitle: 'Шаблоны, база и упражнения',
        icon: Icons.fitness_center_rounded,
        route: '/plans',
      ),
      if (canReadFinance)
        const MoreMenuItem(
          title: 'Финансы',
          subtitle: 'Доходы, оплаты и долги',
          icon: Icons.account_balance_wallet_outlined,
          route: '/finance',
        ),
      const MoreMenuItem(
        title: 'Журнал тренировок',
        subtitle: 'Все занятия и их история',
        icon: Icons.list_alt_rounded,
        route: '/sessions',
        switchesTab: true,
      ),
      const MoreMenuItem(
        title: 'Регулярные тренировки',
        subtitle: 'Серии занятий по дням недели',
        icon: Icons.event_repeat_outlined,
        route: '/schedule/recurring',
        switchesTab: true,
      ),
    ],
    const [
      MoreMenuItem(
        title: 'Пригласить ученика',
        subtitle: 'QR-код или ссылка',
        icon: Icons.qr_code_2_rounded,
        route: '/invite',
        switchesTab: true,
      ),
      MoreMenuItem(
        title: 'Отзывы',
        icon: Icons.star_outline_rounded,
        route: '/reviews',
      ),
      MoreMenuItem(
        title: 'Профиль и настройки',
        icon: Icons.tune_rounded,
        route: '/profile',
      ),
    ],
  ];
}

/// «Ещё» tab of the trainer: everything that is used less than daily.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final permissions = user?.permissions ?? const <String>[];
    final sections = trainerMoreSections(
      canReadFinance: permissions.contains('finance:read_own'),
    );
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xl,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            Text('Ещё', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            FyCard(
              onTap: () => context.push('/profile'),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  FyAvatar(
                    displayName: user?.displayName,
                    email: user?.email,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personPrimaryLabel(
                            displayName: user?.displayName,
                            email: user?.email,
                          ),
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Тренер', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            for (final (index, section) in sections.indexed) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  index == 0 ? 'Работа' : 'Аккаунт',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MoreMenuGroup(items: section),
            ],
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton.icon(
                key: const Key('more-logout'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Выйти из аккаунта'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rows of [MoreMenuItem] in one card (also used on the profile).
class MoreMenuGroup extends StatelessWidget {
  const MoreMenuGroup({required this.items, super.key});

  final List<MoreMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return FyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: 70),
            _MoreRow(item: item),
          ],
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.item});

  final MoreMenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () =>
          item.switchesTab ? context.go(item.route) : context.push(item.route),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FyIconBadge(icon: item.icon, size: 40, iconSize: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium),
                    if (item.subtitle != null)
                      Text(item.subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
