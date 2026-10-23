import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fy_avatar.dart';
import '../../../core/widgets/fy_bottom_sheet.dart';
import '../../../core/widgets/fy_button.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_chip.dart';
import '../../../core/widgets/fy_icon_badge.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../../core/widgets/fy_square_icon_button.dart';
import '../../../core/widgets/fy_status_chip.dart';
import '../../more/presentation/more_page.dart';
import '../../plans/data/plans_models.dart';
import '../../schedule/data/schedule_models.dart';
import '../../schedule/presentation/schedule_format.dart';
import '../../schedule/presentation/screens/coach_book_for_student_screen.dart';
import '../../session_packages/data/session_package_models.dart';
import '../data/progress_models.dart';
import 'cubit/student_hub_cubit.dart';
import 'cubit/student_hub_state.dart';
import 'widgets/assign_to_student_sheet.dart';
import 'widgets/progress_line_chart.dart';

const _weekdayShort = ['', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

class StudentHubView extends StatelessWidget {
  const StudentHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentHubCubit, StudentHubState>(
      builder: (context, state) {
        final cubit = context.read<StudentHubCubit>();
        final displayName = _hubDisplayName(state);
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HubHeader(cubit: cubit, state: state),
                Expanded(
                  child: switch (state.status) {
                    StudentHubStatus.initial || StudentHubStatus.loading =>
                      const Center(child: CircularProgressIndicator()),
                    StudentHubStatus.failure => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.errorMessage ?? 'Не удалось загрузить',
                        ),
                      ),
                    ),
                    StudentHubStatus.ready => RefreshIndicator(
                      onRefresh: cubit.load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        children: [
                          _PersonHeader(
                            name: displayName,
                            package: state.package,
                          ),
                          if (cubit.isTrainer) ...[
                            const SizedBox(height: 16),
                            _ActionRow(
                              studentId: cubit.studentId,
                              onAssigned: cubit.load,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _StatsRow(state: state),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'БЛИЖАЙШИЕ',
                            actionLabel: cubit.isTrainer
                                ? 'Смотреть все ›'
                                : null,
                            onAction: cubit.isTrainer
                                ? () => context.go('/schedule')
                                : null,
                          ),
                          _UpcomingSessions(sessions: state.upcoming),
                          const SizedBox(height: 20),
                          _SectionHeader(
                            title: 'НАЗНАЧЕННЫЕ',
                            actionLabel: cubit.isTrainer ? 'Назначить' : null,
                            onAction: cubit.isTrainer
                                ? () => _assign(
                                    context,
                                    cubit.studentId,
                                    cubit.load,
                                  )
                                : null,
                          ),
                          if (state.assigned.isEmpty)
                            const FyCard(
                              child: FyInfoBanner(
                                message: 'Пока нет назначенных тренировок.',
                                icon: Icons.assignment_outlined,
                              ),
                            )
                          else
                            _AssignedWorkouts(
                              plans: state.assigned,
                              isTrainer: cubit.isTrainer,
                            ),
                          const SizedBox(height: 16),
                          const _SectionHeader(title: 'ПРОГРЕСС'),
                          _ProgressSection(state: state, cubit: cubit),
                        ],
                      ),
                    ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _assign(
  BuildContext context,
  String studentId,
  Future<void> Function() reload,
) async {
  final ok = await showAssignToStudentSheet(context, studentId: studentId);
  if (ok == true && context.mounted) {
    await reload();
  }
}

String _hubDisplayName(StudentHubState state) {
  final named = state.studentDisplayName?.trim();
  if (named != null && named.isNotEmpty) return named;
  for (final session in state.upcoming) {
    final name = session.studentDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return 'Ученик';
}

/// Back button, screen title for the student's own view, and the trainer's
/// «more» menu.
class _HubHeader extends StatelessWidget {
  const _HubHeader({required this.cubit, required this.state});

  final StudentHubCubit cubit;
  final StudentHubState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          FySquareIconButton(
            buttonKey: const Key('hub-back'),
            tooltip: 'Назад',
            icon: Icons.arrow_back_rounded,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(cubit.isTrainer ? '/session-packages' : '/home');
              }
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: cubit.isSelf
                ? Text(
                    'Мои тренировки',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  )
                : const SizedBox.shrink(),
          ),
          if (cubit.isTrainer)
            FySquareIconButton(
              buttonKey: const Key('hub-more'),
              tooltip: 'Ещё действия',
              icon: Icons.more_horiz_rounded,
              onPressed: () => _showMoreSheet(
                context,
                recurringBookingId: state.recurringBookingId,
              ),
            ),
        ],
      ),
    );
  }
}

void _showMoreSheet(BuildContext context, {String? recurringBookingId}) {
  showFyBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: MoreMenuGroup(
        items: [
          const MoreMenuItem(
            icon: Icons.credit_card_outlined,
            title: 'Абонемент',
            route: '/session-packages',
          ),
          MoreMenuItem(
            icon: Icons.fitness_center_outlined,
            title: 'Программа',
            route: recurringBookingId != null
                ? '/schedule/recurring/$recurringBookingId/program'
                : '/schedule/recurring/create',
          ),
        ],
      ),
    ),
  );
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.name, required this.package});

  final String name;
  final SessionPackage? package;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('hub-person-header'),
      children: [
        FyAvatar(displayName: name, size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  height: 30 / 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _packageLine(package),
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _packageLine(SessionPackage? package) {
  if (package == null) return 'Нет активного пакета';
  if (!package.isActive) return package.remainingLabel;
  final n = package.remainingSessions;
  if (n == 1) return 'Осталась 1 тренировка';
  return 'Осталось $n тренировок';
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final StudentHubState state;

  @override
  Widget build(BuildContext context) {
    final package = state.package;
    final packageValue = package == null || !package.isActive
        ? '—'
        : '${package.remainingSessions} из ${package.totalSessions}';
    return Row(
      key: const Key('hub-stats'),
      children: [
        Expanded(
          child: _StatCard(label: 'Пакет', value: packageValue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Ближайших',
            value: '${state.upcoming.length}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Назначено',
            value: '${state.assigned.length}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FyCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                height: 26 / 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingSessions extends StatelessWidget {
  const _UpcomingSessions({required this.sessions});

  final List<TrainingSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const FyCard(
        child: FyInfoBanner(
          message: 'Ближайших занятий пока нет.',
          icon: Icons.calendar_today_outlined,
        ),
      );
    }
    final visible = sessions.take(3).toList();
    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _UpcomingSessionCard(session: visible[i]),
        ],
      ],
    );
  }
}

class _UpcomingSessionCard extends StatelessWidget {
  const _UpcomingSessionCard({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(session.startsAt).toLocal();
    final title = session.workoutTitle?.trim();
    final subtitle = (title == null || title.isEmpty)
        ? 'Персональная тренировка'
        : title;
    final place = session.mode == 'online' ? 'Онлайн' : 'Очно';
    return FyCard(
      key: Key('hub-session-${session.id}'),
      onTap: () => context.push('/sessions/${session.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.sunken,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SizedBox.square(
              dimension: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatTime(start),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '${_weekdayShort[start.weekday]} ${start.day}',
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  place,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const FyStatusChip(status: FyStatus.confirmed),
        ],
      ),
    );
  }
}

/// One filled button per screen: «Записать»; «Назначить» is outlined.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.studentId, required this.onAssigned});

  final String studentId;
  final Future<void> Function() onAssigned;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('hub-action-grid'),
      children: [
        Expanded(
          child: FyButton.primary(
            key: const Key('hub-action-book'),
            label: 'Записать',
            icon: Icons.add_rounded,
            size: FyButtonSize.medium,
            onPressed: () => context.push(
              '/schedule/book-for-student',
              extra: CoachBookPrefill(studentId: studentId),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FyButton.secondary(
            key: const Key('hub-action-assign'),
            label: 'Назначить',
            icon: Icons.assignment_outlined,
            size: FyButtonSize.medium,
            onPressed: () => _assign(context, studentId, onAssigned),
          ),
        ),
        const SizedBox(width: 8),
        FySquareIconButton(
          buttonKey: const Key('hub-action-chat'),
          tooltip: 'Написать',
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: () => context.push('/chats/with/$studentId'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.26,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              key: Key('hub-section-$actionLabel'),
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _AssignedWorkouts extends StatelessWidget {
  const _AssignedWorkouts({required this.plans, required this.isTrainer});

  final List<TrainingPlanItem> plans;
  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, plan) in plans.indexed) ...[
          if (index > 0) const SizedBox(height: 10),
          FyCard(
            key: Key('hub-plan-${plan.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: isTrainer ? () => context.push('/plans/${plan.id}') : null,
            child: Row(
              children: [
                const FyIconBadge(
                  icon: Icons.fitness_center_rounded,
                  size: 44,
                  iconSize: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 20 / 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${plan.exercises.length} упражнений',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTrainer)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.state, required this.cubit});

  final StudentHubState state;
  final StudentHubCubit cubit;

  @override
  Widget build(BuildContext context) {
    final series = state.series;
    final chips = state.exercises;
    final empty = series == null || series.points.isEmpty;
    return FyCard(
      key: empty
          ? const Key('hub-progress-empty')
          : const Key('hub-progress-chart'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chips.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final exercise in chips.take(6))
                  FyChip(
                    key: Key('hub-exercise-${exercise.exerciseId}'),
                    label: exercise.name,
                    selected: state.selectedExerciseId == exercise.exerciseId,
                    showCheckmark: false,
                    compact: true,
                    onSelected: (_) =>
                        cubit.selectExercise(exercise.exerciseId),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (empty)
            const FyInfoBanner(
              message: 'Проведите занятие с весами, чтобы увидеть график',
              icon: Icons.show_chart_rounded,
            )
          else ...[
            ProgressLineChart(values: series.chartValues),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _ProgressNumbers(series: series),
          ],
        ],
      ),
    );
  }
}

class _ProgressNumbers extends StatelessWidget {
  const _ProgressNumbers({required this.series});

  final ProgressSeries series;

  @override
  Widget build(BuildContext context) {
    final unit = series.usesVolume ? 'кг·повт' : 'кг';
    return Row(
      children: [
        _Stat(label: 'Старт', value: series.firstValue, unit: unit),
        const SizedBox(
          height: 36,
          child: VerticalDivider(width: 24, thickness: 1),
        ),
        _Stat(label: 'Сейчас', value: series.currentValue, unit: unit),
        const SizedBox(
          height: 36,
          child: VerticalDivider(width: 24, thickness: 1),
        ),
        _Stat(label: 'Дельта', value: series.delta, unit: unit, signed: true),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.unit,
    this.signed = false,
  });

  final String label;
  final double? value;
  final String unit;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? '—'
        : '${signed && value! > 0 ? '+' : ''}${value!.toStringAsFixed(1)} $unit';
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
