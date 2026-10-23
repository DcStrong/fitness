import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

class HomeFeatureCardData {
  const HomeFeatureCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    this.backgroundAsset,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;
  final String? backgroundAsset;
}

List<HomeFeatureCardData> homeFeatureCards({
  required bool isTrainer,
  required bool canReadFinance,
}) {
  if (isTrainer) {
    return [
      const HomeFeatureCardData(
        title: 'Расписание',
        description: 'Свободные слоты и запись учеников',
        icon: Icons.calendar_month_outlined,
        route: '/schedule',
        backgroundAsset: 'assets/images/home/home_feature_schedule.webp',
      ),
      const HomeFeatureCardData(
        title: 'Регулярные тренировки',
        description: 'Серии занятий по дням недели',
        icon: Icons.event_repeat_outlined,
        route: '/schedule/recurring',
        backgroundAsset: 'assets/images/home/home_feature_recurring.webp',
      ),
      const HomeFeatureCardData(
        title: 'Ученики',
        description: 'Абонементы и связи',
        icon: Icons.groups_outlined,
        route: '/session-packages',
        backgroundAsset: 'assets/images/home/home_feature_students.webp',
      ),
      const HomeFeatureCardData(
        title: 'Планирование',
        description: 'Программы и планы тренировок',
        icon: Icons.assignment_outlined,
        route: '/plans',
        backgroundAsset: 'assets/images/home/home_feature_plans.webp',
      ),
      if (canReadFinance)
        const HomeFeatureCardData(
          title: 'Финансы',
          description: 'Доходы, оплаты и операции',
          icon: Icons.account_balance_wallet_outlined,
          route: '/finance',
          backgroundAsset: 'assets/images/home/home_feature_finance.webp',
        ),
    ];
  }

  return const [
    HomeFeatureCardData(
      title: 'Тренировки',
      description: 'Предстоящие занятия и назначенные программы',
      icon: Icons.self_improvement_outlined,
      route: '/me/training',
      backgroundAsset: 'assets/images/home/home_feature_recurring.webp',
    ),
    HomeFeatureCardData(
      title: 'Записаться',
      description: 'Выбрать свободное время тренера',
      icon: Icons.event_available_outlined,
      route: '/schedule/book',
      backgroundAsset: 'assets/images/home/home_feature_schedule.webp',
    ),
    HomeFeatureCardData(
      title: 'Мои заявки',
      description: 'Статусы запросов на тренировку',
      icon: Icons.event_note_outlined,
      route: '/booking-requests/mine',
      backgroundAsset: 'assets/images/home/home_feature_plans.webp',
    ),
    HomeFeatureCardData(
      title: 'Тренеры',
      description: 'Найти тренера для занятий',
      icon: Icons.person_search_outlined,
      route: '/trainers',
      backgroundAsset: 'assets/images/home/home_feature_students.webp',
    ),
    HomeFeatureCardData(
      title: 'Планы',
      description: 'Назначенные тренировки и прогресс',
      icon: Icons.assignment_outlined,
      route: '/me/training',
      backgroundAsset: 'assets/images/home/home_feature_plans.webp',
    ),
  ];
}

class HomeFeatureCardGrid extends StatelessWidget {
  const HomeFeatureCardGrid({required this.cards, this.columns = 2, super.key});

  final List<HomeFeatureCardData> cards;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                height: 148,
                child: _HomeFeatureCard(card: card),
              ),
          ],
        );
      },
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  const _HomeFeatureCard({required this.card});

  final HomeFeatureCardData card;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: () => context.go(card.route),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (card.backgroundAsset != null)
                Positioned.fill(
                  // opacity на самом Image — без saveLayer (Opacity-виджет
                  // заставляет Flutter web перерисовывать слой на каждый кадр).
                  child: Image.asset(
                    card.backgroundAsset!,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    opacity: const AlwaysStoppedAnimation(0.52),
                    cacheWidth: 640,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.surface,
                        Color(0xE6FFFFFF),
                        Color(0x8CFFFFFF),
                        Color(0x26FFFFFF),
                      ],
                      stops: [0, 0.32, 0.62, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(card.icon, color: AppColors.primary),
                    const Spacer(),
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
