import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../../core/widgets/fy_top_bar.dart';
import '../../../core/widgets/person_name_email.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../schedule/data/schedule_models.dart';
import '../../schedule/presentation/schedule_format.dart';
import '../../social/presentation/widgets/safe_network_image.dart';
import '../domain/home_schedule.dart';
import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';
import 'home_format.dart';
import 'widgets/home_bento_shortcuts.dart';
import 'widgets/home_feature_cards.dart';
import 'widgets/home_stat_chips.dart';
import 'widgets/home_week_strip.dart';

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
        final todayCount = state.status == HomeStatus.success
            ? countHomeTodayUpcomingSessions(state.sessions, now)
            : 0;
        final weekCount = state.status == HomeStatus.success
            ? countHomeWeekBookedSessions(state.sessions)
            : 0;
        return Scaffold(
          appBar: FyTopBar(
            title: 'Главная',
            actions: [
              if (isTrainer)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(child: _HomeDateChip(now: now)),
                ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: context.read<HomeCubit>().refresh,
              child: ListView(
                key: const Key('home-scroll'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  _DateHeader(now: now, showInvite: isTrainer),
                  if (state.status == HomeStatus.success ||
                      state.status == HomeStatus.loading) ...[
                    const SizedBox(height: 16),
                    HomeStatChips(
                      isTrainer: isTrainer,
                      todayCount: todayCount,
                      weekCount: weekCount,
                      state: state,
                    ),
                  ],
                  if (state.status == HomeStatus.success) ...[
                    const SizedBox(height: 16),
                    HomeWeekStrip(
                      sessions: state.sessions,
                      anchor: now,
                      now: now,
                      upcomingOnly: !isTrainer,
                    ),
                  ],
                  if (!isTrainer &&
                      state.studentPackageStatus ==
                          StudentPackageStatus.success &&
                      (state.studentPackageRemaining != null ||
                          state.studentPackageExhausted)) ...[
                    const SizedBox(height: 16),
                    FyCard(
                      key: const Key('home-session-package-badge'),
                      child: Text(
                        state.studentPackageExhausted
                            ? 'Абонемент закончился — напишите тренеру'
                            : 'Абонемент: осталось ${state.studentPackageRemaining}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _ScheduleArea(
                    state: state,
                    now: now,
                    userId: user.id,
                    isTrainer: isTrainer,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Всё необходимое',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isTrainer)
                    HomeBentoShortcuts(
                      canReadFinance: canReadFinance,
                      sessions: state.status == HomeStatus.success
                          ? state.sessions
                          : const [],
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

class _HomeDateChip extends StatelessWidget {
  const _HomeDateChip({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final label = formatHomeDateChip(now);
    return Semantics(
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 168),
        child: DecoratedBox(
          key: const Key('home-date-chip'),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.now, required this.showInvite});

  final DateTime now;
  final bool showInvite;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                now.year.toString(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatHomeDate(now),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatHomeWeekday(now),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (showInvite)
          Semantics(
            button: true,
            label: 'Пригласить ученика',
            child: IconButton.filledTonal(
              key: const Key('home-qr-invite'),
              tooltip: 'Пригласить ученика',
              onPressed: () => context.push('/invite'),
              icon: const Icon(Icons.qr_code_2_rounded),
            ),
          ),
      ],
    );
  }
}

class _ScheduleArea extends StatelessWidget {
  const _ScheduleArea({
    required this.state,
    required this.now,
    required this.userId,
    required this.isTrainer,
  });

  final HomeState state;
  final DateTime now;
  final String userId;
  final bool isTrainer;

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

    final groups = groupHomeSessions(
      homeSessionsForLocalDay(state.sessions, now),
      now,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (groups.history.isNotEmpty) ...[
          InkWell(
            key: const Key('home-history-toggle'),
            borderRadius: BorderRadius.circular(12),
            onTap: context.read<HomeCubit>().toggleHistory,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    'История ${groups.history.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Divider(
                      color: AppColors.outlineVariant,
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    state.historyExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (state.historyExpanded) ...[
            const SizedBox(height: 12),
            ..._sessionCards(
              context,
              groups.history,
              now,
              userId,
              history: true,
              timeline: isTrainer,
            ),
          ],
          const SizedBox(height: 24),
        ],
        InkWell(
          key: const Key('home-upcoming-toggle'),
          borderRadius: BorderRadius.circular(12),
          onTap: context.read<HomeCubit>().toggleUpcoming,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    groups.currentAndUpcoming.isEmpty
                        ? 'Предстоящие тренировки'
                        : 'Предстоящие тренировки ${groups.currentAndUpcoming.length}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  state.upcomingExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (state.upcomingExpanded) ...[
          const SizedBox(height: 14),
          if (groups.currentAndUpcoming.isEmpty)
            FyCard(
              child: FyInfoBanner(
                message: homeSessionsForLocalDay(state.sessions, now).isEmpty
                    ? 'Сегодня тренировок нет.'
                    : 'На сегодня больше нет запланированных тренировок.',
                icon: Icons.event_available_rounded,
              ),
            )
          else
            ..._sessionCards(
              context,
              groups.currentAndUpcoming,
              now,
              userId,
              history: false,
              timeline: isTrainer,
            ),
        ],
      ],
    );
  }

  List<Widget> _sessionCards(
    BuildContext context,
    List<TrainingSession> sessions,
    DateTime now,
    String userId, {
    required bool history,
    required bool timeline,
  }) {
    if (timeline) {
      return [
        _HomeTimeline(
          sessions: sessions,
          now: now,
          userId: userId,
          history: history,
        ),
      ];
    }

    return [
      for (var index = 0; index < sessions.length; index++) ...[
        _HomeSessionCard(
          key: Key(
            history
                ? 'home-history-session-${sessions[index].id}'
                : 'home-upcoming-session-${sessions[index].id}',
          ),
          session: sessions[index],
          now: now,
          userId: userId,
        ),
        if (index < sessions.length - 1) const SizedBox(height: 12),
      ],
    ];
  }
}

class _HomeTimeline extends StatelessWidget {
  const _HomeTimeline({
    required this.sessions,
    required this.now,
    required this.userId,
    required this.history,
  });

  final List<TrainingSession> sessions;
  final DateTime now;
  final String userId;
  final bool history;

  @override
  Widget build(BuildContext context) {
    return FyCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          for (var index = 0; index < sessions.length; index++)
            _HomeTimelineRow(
              key: Key(
                history
                    ? 'home-history-session-${sessions[index].id}'
                    : 'home-upcoming-session-${sessions[index].id}',
              ),
              session: sessions[index],
              now: now,
              userId: userId,
              drawLineAbove: index > 0,
              drawLineBelow: index < sessions.length - 1,
            ),
        ],
      ),
    );
  }
}

class _HomeTimelineRow extends StatelessWidget {
  const _HomeTimelineRow({
    required this.session,
    required this.now,
    required this.userId,
    required this.drawLineAbove,
    required this.drawLineBelow,
    super.key,
  });

  final TrainingSession session;
  final DateTime now;
  final String userId;
  final bool drawLineAbove;
  final bool drawLineBelow;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(session.startsAt).toLocal();
    final counterpartName = userId == session.coachId
        ? personPrimaryLabel(
            displayName: session.studentDisplayName,
            email: session.studentEmail,
            fallback: session.studentId,
          )
        : personPrimaryLabel(
            displayName: session.coachDisplayName,
            email: session.coachEmail,
            fallback: session.coachId,
          );
    final counterpartEmail = userId == session.coachId
        ? personEmailCaption(
            displayName: session.studentDisplayName,
            email: session.studentEmail,
          )
        : personEmailCaption(
            displayName: session.coachDisplayName,
            email: session.coachEmail,
          );
    final status = _sessionStatus(session, now);
    final imageUrl = session.peerAvatarUrl(userId);

    return InkWell(
      onTap: () => context.push('/sessions/${session.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                formatHomeTime(start),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              width: 18,
              child: Column(
                children: [
                  Container(
                    width: 2,
                    height: 8,
                    color: drawLineAbove
                        ? AppColors.outlineVariant
                        : Colors.transparent,
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: drawLineBelow
                        ? AppColors.outlineVariant
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
            _CounterpartAvatar(
              name: counterpartName,
              imageUrl: imageUrl,
              sessionId: session.id,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counterpartName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (counterpartEmail != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      counterpartEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    status.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: status.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (session.workoutTitle != null &&
                      session.workoutTitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      session.workoutTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.iconInactive,
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterpartAvatar extends StatelessWidget {
  const _CounterpartAvatar({
    required this.name,
    required this.imageUrl,
    required this.sessionId,
  });

  final String name;
  final String? imageUrl;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    if (imageUrl != null) {
      return ClipOval(
        child: SafeNetworkImage(url: imageUrl, width: size, height: size),
      );
    }

    return CircleAvatar(
      key: Key('home-avatar-initials-$sessionId'),
      radius: size / 2,
      backgroundColor: AppColors.mintSoft,
      foregroundColor: AppColors.primary,
      child: Text(
        initialsFromLabel(name),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _HomeSessionCard extends StatelessWidget {
  const _HomeSessionCard({
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
    final start = DateTime.parse(session.startsAt).toLocal();
    final end = DateTime.parse(session.endsAt).toLocal();
    final counterpartName = userId == session.coachId
        ? personPrimaryLabel(
            displayName: session.studentDisplayName,
            email: session.studentEmail,
            fallback: session.studentId,
          )
        : personPrimaryLabel(
            displayName: session.coachDisplayName,
            email: session.coachEmail,
            fallback: session.coachId,
          );
    final counterpartEmail = userId == session.coachId
        ? personEmailCaption(
            displayName: session.studentDisplayName,
            email: session.studentEmail,
          )
        : personEmailCaption(
            displayName: session.coachDisplayName,
            email: session.coachEmail,
          );
    final status = _sessionStatus(session, now);

    return FyCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/sessions/${session.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 34,
              child: Icon(status.icon, color: status.color, size: 19),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatHomeTime(start)}–${formatHomeTime(end)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  counterpartName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (counterpartEmail != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    counterpartEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (session.workoutTitle != null &&
                    session.workoutTitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    session.workoutTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.iconInactive,
            ),
          ),
        ],
      ),
    );
  }
}

({String label, IconData icon, Color color}) _sessionStatus(
  TrainingSession session,
  DateTime now,
) {
  if (isExpiredBookedSession(session, now)) {
    return (
      label: 'Требует отметки',
      icon: Icons.priority_high_rounded,
      color: Colors.orange.shade800,
    );
  }
  if (isHomeSessionCurrent(session, now)) {
    return (
      label: 'Идёт сейчас',
      icon: Icons.play_arrow_rounded,
      color: AppColors.mint,
    );
  }
  return switch (session.status) {
    'booked' => (
      label: 'Запланирована',
      icon: Icons.schedule_rounded,
      color: AppColors.secondary,
    ),
    'completed' => (
      label: 'Проведена',
      icon: Icons.check_rounded,
      color: AppColors.success,
    ),
    'cancelled' => (
      label: 'Отменена',
      icon: Icons.close_rounded,
      color: AppColors.error,
    ),
    'no_show' => (
      label: 'Неявка',
      icon: Icons.person_off_outlined,
      color: Colors.orange.shade800,
    ),
    _ => (
      label: session.status,
      icon: Icons.info_outline_rounded,
      color: AppColors.textMuted,
    ),
  };
}
