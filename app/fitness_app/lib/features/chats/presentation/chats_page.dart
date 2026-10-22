import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/widgets.dart';

/// Chat tab. The messaging backend is not built yet, so the tab explains what
/// will live here instead of showing an empty list.
class ChatsPage extends StatelessWidget {
  const ChatsPage({required this.isTrainer, super.key});

  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
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
            Text(
              isTrainer ? 'Чаты' : 'Чат',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FyCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const FyIconBadge(
                    icon: Icons.chat_bubble_outline_rounded,
                    size: 56,
                    iconSize: 28,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Чат скоро появится',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isTrainer
                        ? 'Здесь будут переписки с учениками: перенос занятий, '
                              'вопросы по тренировкам и напоминания.'
                        : 'Здесь будет переписка с тренером: перенос занятий '
                              'и вопросы по тренировкам.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.sunken,
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Пока договаривайтесь о переносах через заявки '
                        'в расписании.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
