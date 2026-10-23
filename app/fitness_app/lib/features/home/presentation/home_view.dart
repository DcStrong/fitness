import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/person_name_email.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../schedule/data/schedule_models.dart';
import '../domain/home_schedule.dart';
import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';
import 'home_format.dart';
import 'widgets/home_bento_shortcuts.dart';
import 'widgets/home_feature_cards.dart';
import 'widgets/home_next_session_card.dart';
import 'widgets/home_stat_chips.dart';
import 'widgets/home_week_bars.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isTrainer = user.roles.contains('trainer');
    final canReadFinance = user.permissions.contains('finance:read_own');
    final featureCards = homeFeatureCards(
      isTrainer: isTrainer,
      canReadFinance: canReadFinance,
    );

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final now = state.now ?? DateTime.now();
        final loaded = state.status == HomeStatus.success;
        final todayCount = loaded
            ? countHomeTodayUpcomingSessions(state.sessions, now)
            : 0;
        final weekCount = loaded
            ? countHomeWeekBookedSessions(state.sessions)
            : 0;
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: context.read<HomeCubit>().refresh,
              child: ListView(
                key: const Key('home-scroll'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.lg,
                  AppSpacing.screen,
                  AppSpacing.xxxl,
                ),
                children: [
                  _HomeHeader(now: now, showInvite: isTrainer),
                  const SizedBox(height: AppSpacing.lg),
                  if (loaded) ...[
                    HomeNextSessionCard(
                      session: homeNextSession(state.sessions, now),
                      now: now,
                      userId: user.id,
                      isTrainer: isTrainer,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (isTrainer && state.status != HomeStatus.failure) ...[
                    HomeStatChips(
                      todayCount: todayCount,
                      weekCount: weekCount,
                      state: state,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (isTrainer && loaded) ...[
                    HomeWeekBars(sessions: state.sessions, now: now),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (!isTrainer &&
                      state.studentPackageStatus ==
                          StudentPackageStatus.success &&
                      (state.studentPackageRemaining != null ||
                          state.studentPackageExhausted)) ...[
                    _StudentPackageCard(state: state),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(
                    title: 'Сегодня',
                    actionLabel: isTrainer ? 'Расписание' : 'Все занятия',
                    onAction: () =>
                        context.go(isTrainer ? '/schedule' : '/sessions'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TodayArea(state: state, now: now, userId: user.id),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Всё необходимое',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isTrainer)
                    HomeBentoShortcuts(
                      canReadFinance: canReadFinance,
                      sessions: loaded ? state.sessions : const [],
                      anchor: now,
                    )
                  else
                    HomeFeatureCardGrid(cards: featureCards),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.now, required this.showInvite});

  final DateTime now;
  final bool showInvite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatHomeHeaderDate(now),
                key: const Key('home-header-date'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text('Главная', style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        if (showInvite)
          FySquareIconButton(
            buttonKey: const Key('home-qr-invite'),
            tooltip: 'Пригласить ученика',
            icon: Icons.qr_code_2_rounded,
            onPressed: () => context.push('/invite'),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _StudentPackageCard extends StatelessWidget {
  const _StudentPackageCard({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exhausted = state.studentPackageExhausted;
    return FyCard(
      key: const Key('home-session-package-badge'),
      child: Row(
        children: [
          const FyIconBadge(icon: Icons.inventory_2_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Абонемент', style: theme.textTheme.titleMedium),
                Text(
                  exhausted
                      ? 'Закончился — напишите тренеру'
                      : 'Осталось занятий: ${state.studentPackageRemaining}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: exhausted ? AppColors.error : null,
                  ),
                ),
              ],
            ),
          ),
          if (!exhausted)
            Text(
              '${state.studentPackageRemaining}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayArea extends StatelessWidget {
  const _TodayArea({
    required this.state,
    required this.now,
    required this.userId,
  });

  final HomeState state;
  final DateTime now;
  final String userId;

  @override
  Widget build(BuildContext context) {
    if (state.status == HomeStatus.initial ||
        state.status == HomeStatus.loading) {
      return const FyCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (state.status == HomeStatus.failure) {
      return FyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FyInfoBanner(
              message: 'Не удалось загрузить расписание на сегодня.',
              icon: Icons.sync_problem_rounded,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('home-schedule-retry'),
              onPressed: context.read<HomeCubit>().load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final today = homeSessionsForLocalDay(state.sessions, now);
    if (today.isEmpty) {
      return const FyCard(
        child: FyInfoBanner(
          message: 'Сегодня тренировок нет.',
          icon: Icons.event_available_rounded,
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < today.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _TodaySessionRow(
            key: Key('home-today-session-${today[index].id}'),
            session: today[index],
            now: now,
            userId: userId,
          ),
        ],
      ],
    );
  }
}

class _TodaySessionRow extends StatelessWidget {
  const _TodaySessionRow({
    required this.session,
    required this.now,
    required this.userId,
    super.key,
  });

  final TrainingSession session;
  final DateTime now;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.parse(session.startsAt).toLocal();
    final viewerIsCoach = userId == session.coachId;
    final displayName = viewerIsCoach
        ? session.studentDisplayName
        : session.coachDisplayName;
    final email = viewerIsCoach ? session.studentEmail : session.coachEmail;
    final name = personPrimaryLabel(
      displayName: displayName,
      email: email,
      fallback: viewerIsCoach ? session.studentId : session.coachId,
    );
    final subtitle = session.workoutTitle?.trim().isNotEmpty == true
        ? session.workoutTitle!
        : personEmailCaption(displayName: displayName, email: email);
    final (status, label) = homeSessionStatus(session, now);

    return FyCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/sessions/${session.id}'),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sunken,
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: Text(
              formatHomeTime(start),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 6),
                FyStatusChip(status: status, label: label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Status of a session as the home list shows it.
(FyStatus, String) homeSessionStatus(TrainingSession session, DateTime now) {
  if (isExpiredBookedSession(session, now)) {
    return (FyStatus.waiting, 'Требует отметки');
  }
  if (isHomeSessionCurrent(session, now)) {
    return (FyStatus.confirmed, 'Идёт сейчас');
  }
  return switch (session.status) {
    'booked' => (FyStatus.confirmed, 'Запланирована'),
    'completed' => (FyStatus.done, 'Проведена'),
    'cancelled' => (FyStatus.cancelled, 'Отменена'),
    'no_show' => (FyStatus.noShow, 'Неявка'),
    _ => (FyStatus.cancelled, session.status),
  };
}
