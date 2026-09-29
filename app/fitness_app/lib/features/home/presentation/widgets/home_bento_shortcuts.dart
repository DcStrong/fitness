import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../schedule/data/schedule_models.dart';
import '../../../schedule/presentation/widgets/calendar_period_format.dart';
import '../../domain/home_schedule.dart';

class HomeBentoShortcuts extends StatelessWidget {
  const HomeBentoShortcuts({
    required this.canReadFinance,
    this.sessions = const [],
    this.anchor,
    super.key,
  });

  final bool canReadFinance;
  final List<TrainingSession> sessions;
  final DateTime? anchor;

  @override
  Widget build(BuildContext context) {
    final chartAnchor = anchor ?? DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;

        if (narrow) {
          return Column(
            key: const Key('home-bento-shortcuts'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BentoTile(
                key: const Key('home-bento-schedule'),
                title: 'Расписание',
                subtitle: 'Список тренировок на неделю и день',
                icon: Icons.calendar_month_outlined,
                fullWidth: true,
                showWeekChart: true,
                sessions: sessions,
                anchor: chartAnchor,
                showGo: true,
                goKey: const Key('home-bento-schedule-go'),
                onTap: () => context.go('/schedule'),
              ),
              const SizedBox(height: 12),
              _BentoTile(
                key: const Key('home-bento-students'),
                title: 'Ученики',
                subtitle: 'Клиенты, прогресс и заметки',
                icon: Icons.groups_outlined,
                stacked: true,
                showGo: true,
                goKey: const Key('home-bento-students-go'),
                onTap: () => context.go('/session-packages'),
              ),
              const SizedBox(height: 12),
              _BentoTile(
                key: const Key('home-bento-plans'),
                title: 'Планирование',
                subtitle: 'Запланировать тренировку',
                icon: Icons.assignment_outlined,
                stacked: true,
                showGo: true,
                goKey: const Key('home-bento-plans-go'),
                onTap: () => context.go('/plans'),
              ),
              const SizedBox(height: 12),
              _BentoTile(
                key: const Key('home-bento-recurring'),
                title: 'Регулярные тренировки',
                subtitle: 'Серии занятий по дням недели',
                icon: Icons.event_repeat_outlined,
                fullWidth: true,
                showGo: true,
                goKey: const Key('home-bento-recurring-go'),
                onTap: () => context.go('/schedule/recurring'),
              ),
              if (canReadFinance) ...[
                const SizedBox(height: 12),
                _BentoTile(
                  key: const Key('home-bento-finance'),
                  title: 'Финансы',
                  icon: Icons.account_balance_wallet_outlined,
                  fullWidth: true,
                  onTap: () => context.go('/finance'),
                ),
              ],
            ],
          );
        }

        return Column(
          key: const Key('home-bento-shortcuts'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 320,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: _BentoTile(
                      key: const Key('home-bento-schedule'),
                      title: 'Расписание',
                      subtitle: 'Список тренировок на неделю и день',
                      icon: Icons.calendar_month_outlined,
                      tall: true,
                      showWeekChart: true,
                      sessions: sessions,
                      anchor: chartAnchor,
                      showGo: true,
                      goKey: const Key('home-bento-schedule-go'),
                      onTap: () => context.go('/schedule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                          child: _BentoTile(
                            key: const Key('home-bento-students'),
                            title: 'Ученики',
                            subtitle: 'Клиенты, прогресс и заметки',
                            icon: Icons.groups_outlined,
                            compact: true,
                            stacked: true,
                            showGo: true,
                            goKey: const Key('home-bento-students-go'),
                            onTap: () => context.go('/session-packages'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _BentoTile(
                            key: const Key('home-bento-plans'),
                            title: 'Планирование',
                            subtitle: 'Запланировать тренировку',
                            icon: Icons.assignment_outlined,
                            compact: true,
                            stacked: true,
                            showGo: true,
                            goKey: const Key('home-bento-plans-go'),
                            onTap: () => context.go('/plans'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _BentoTile(
              key: const Key('home-bento-recurring'),
              title: 'Регулярные тренировки',
              subtitle: 'Серии занятий по дням недели',
              icon: Icons.event_repeat_outlined,
              fullWidth: true,
              showGo: true,
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
                fullWidth: true,
                onTap: () => context.go('/finance'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.tall = false,
    this.fullWidth = false,
    this.compact = false,
    this.stacked = false,
    this.showGo = false,
    this.showWeekChart = false,
    this.sessions = const [],
    this.anchor,
    this.goKey,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool tall;
  final bool fullWidth;
  final bool compact;
  final bool stacked;
  final bool showGo;
  final bool showWeekChart;
  final List<TrainingSession> sessions;
  final DateTime? anchor;
  final Key? goKey;

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 12)
        : const EdgeInsets.all(16);
    final goButton = showGo
        ? _GoButton(key: goKey, onPressed: onTap, expanded: stacked)
        : null;

    final card = FyCard(
      onTap: onTap,
      padding: padding,
      child: stacked
          ? _StackedBody(
              title: title,
              subtitle: subtitle,
              icon: icon,
              goButton: goButton,
              pinButton: compact,
            )
          : fullWidth && !showWeekChart
          ? _FullWidthBody(
              title: title,
              subtitle: subtitle,
              icon: icon,
              goButton: goButton,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                _AccentIcon(icon: icon, large: tall),
                SizedBox(height: compact ? 6 : 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 14 : null,
                  ),
                ),
                if (subtitle != null && !compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.25,
                    ),
                  ),
                ],
                if (showWeekChart && anchor != null) ...[
                  const SizedBox(height: 10),
                  HomeWeekSparkline(sessions: sessions, anchor: anchor!),
                ],
                if (goButton != null) ...[
                  if (tall) const Spacer(),
                  if (!tall) const SizedBox(height: 10),
                  goButton,
                ],
              ],
            ),
    );

    if (tall || compact) {
      return SizedBox.expand(child: card);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: fullWidth ? 88 : 82),
      child: card,
    );
  }
}

class _StackedBody extends StatelessWidget {
  const _StackedBody({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.goButton,
    required this.pinButton,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? goButton;
  final bool pinButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccentIcon(icon: icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (goButton != null) ...[
          if (pinButton) const Spacer() else const SizedBox(height: 12),
          goButton!,
        ],
      ],
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
  final String? subtitle;
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
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (goButton != null) ...[const SizedBox(width: 8), goButton!],
      ],
    );
  }
}

class _AccentIcon extends StatelessWidget {
  const _AccentIcon({required this.icon, this.large = false});

  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final dimension = large ? 40.0 : 32.0;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.mintSoft,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Icon(icon, color: AppColors.primary, size: large ? 22 : 18),
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  const _GoButton({required this.onPressed, this.expanded = false, super.key});

  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.mintSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: expanded ? const Size.fromHeight(36) : const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: expanded ? Alignment.centerLeft : Alignment.center,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: expanded
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: const [
          Text('Перейти', style: TextStyle(fontWeight: FontWeight.w700)),
          Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class HomeWeekSparkline extends StatelessWidget {
  const HomeWeekSparkline({
    required this.sessions,
    required this.anchor,
    super.key,
  });

  final List<TrainingSession> sessions;
  final DateTime anchor;

  @override
  Widget build(BuildContext context) {
    final counts = homeWeekBookedCounts(sessions, anchor);
    final maxCount = counts.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );

    return SizedBox(
      key: const Key('home-week-sparkline'),
      height: 84,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < counts.length; index++)
            Expanded(
              child: Semantics(
                container: true,
                excludeSemantics: true,
                label: '${weekdayShortRu[index]}: ${counts[index]}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: maxCount == 0
                              ? 0.12
                              : (counts[index] / maxCount).clamp(0.12, 1),
                          widthFactor: 0.62,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: counts[index] == 0
                                  ? AppColors.mint.withValues(alpha: 0.28)
                                  : counts[index] == maxCount
                                  ? AppColors.primary
                                  : AppColors.mint,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekdayShortRu[index].toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
