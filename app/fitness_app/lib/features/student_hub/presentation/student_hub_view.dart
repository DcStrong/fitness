import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_chip.dart';
import '../../../core/widgets/fy_icon_badge.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../../core/widgets/fy_top_bar.dart';
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

const _weekdayShort = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const _monthsGenitive = [
  '',
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];
const _monthsUpper = [
  '',
  'ЯНВ',
  'ФЕВ',
  'МАР',
  'АПР',
  'МАЯ',
  'ИЮН',
  'ИЮЛ',
  'АВГ',
  'СЕН',
  'ОКТ',
  'НОЯ',
  'ДЕК',
];

class StudentHubView extends StatelessWidget {
  const StudentHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentHubCubit, StudentHubState>(
      builder: (context, state) {
        final cubit = context.read<StudentHubCubit>();
        final displayName = _hubDisplayName(state);
        return Scaffold(
          appBar: FyTopBar(
            title: cubit.isSelf ? 'Мои тренировки' : _shortName(displayName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(cubit.isTrainer ? '/session-packages' : '/home');
                }
              },
            ),
          ),
          body: switch (state.status) {
            StudentHubStatus.initial || StudentHubStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            StudentHubStatus.failure => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.errorMessage ?? 'Не удалось загрузить'),
              ),
            ),
            StudentHubStatus.ready => RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _PersonHeader(
                    name: displayName,
                    package: state.package,
                  ),
                  if (cubit.isTrainer) ...[
                    const SizedBox(height: 20),
                    _ActionGrid(
                      studentId: cubit.studentId,
                      recurringBookingId: state.recurringBookingId,
                      onAssigned: cubit.load,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Ближайшие',
                    actionLabel: cubit.isTrainer ? 'Смотреть все ›' : null,
                    onAction: cubit.isTrainer
                        ? () => context.go('/schedule')
                        : null,
                  ),
                  _UpcomingSessions(sessions: state.upcoming),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Назначенные',
                    actionLabel: cubit.isTrainer ? 'Назначить' : null,
                    onAction: cubit.isTrainer
                        ? () => _assign(context, cubit.studentId, cubit.load)
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
                  const _SectionHeader(title: 'Прогресс'),
                  _ProgressSection(state: state, cubit: cubit),
                ],
              ),
            ),
          },
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

String _shortName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final last = parts.last;
    final initial = last.isEmpty ? '' : '${last.characters.first}.';
    return '${parts.first} $initial'.trim();
  }
  return name;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
  if (name.isEmpty) return '?';
  return name.characters.take(2).toString().toUpperCase();
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.name, required this.package});

  final String name;
  final SessionPackage? package;

  @override
  Widget build(BuildContext context) {
    final packageLine = _packageBadge(package);
    return Row(
      key: const Key('hub-person-header'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.mintSoft,
          foregroundColor: AppColors.primary,
          child: Text(
            _initials(name),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.eco_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          packageLine,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _packageBadge(SessionPackage? package) {
  if (package == null) return 'Нет активного пакета';
  if (!package.isActive) return package.remainingLabel;
  final n = package.remainingSessions;
  if (n == 1) return 'Осталась 1 тренировка';
  return 'Осталось $n тренировок';
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
    final weekday = _weekdayShort[start.weekday];
    final month = _monthsGenitive[start.month];
    final monthUpper = _monthsUpper[start.month];
    final title = session.workoutTitle?.trim();
    final subtitle = (title == null || title.isEmpty)
        ? 'Персональная тренировка'
        : title;
    final place = session.mode == 'online' ? 'Онлайн' : 'Очно';
    return FyCard(
      key: Key('hub-session-${session.id}'),
      onTap: () => context.push('/sessions/${session.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 56,
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${start.day}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthUpper,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: AppColors.primary,
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
                  '$weekday, ${start.day} $month в ${formatTime(start)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      place,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const FyIconBadge(
            icon: Icons.calendar_today_rounded,
            size: 40,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.studentId,
    required this.recurringBookingId,
    required this.onAssigned,
  });

  final String studentId;
  final String? recurringBookingId;
  final Future<void> Function() onAssigned;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('hub-action-grid'),
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCell(
                key: const Key('hub-action-book'),
                icon: Icons.event_available_outlined,
                label: 'Записать',
                onTap: () => context.push(
                  '/schedule/book-for-student',
                  extra: CoachBookPrefill(studentId: studentId),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCell(
                key: const Key('hub-action-assign'),
                icon: Icons.assignment_outlined,
                label: 'Назначить',
                onTap: () => _assign(context, studentId, onAssigned),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCell(
                key: const Key('hub-action-package'),
                icon: Icons.credit_card_outlined,
                label: 'Абонемент',
                onTap: () => context.push('/session-packages'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCell(
                key: const Key('hub-action-program'),
                icon: Icons.fitness_center_outlined,
                label: 'Программа',
                onTap: () {
                  if (recurringBookingId != null) {
                    context.push(
                      '/schedule/recurring/$recurringBookingId/program',
                    );
                    return;
                  }
                  context.push('/schedule/recurring/create');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: FyCard(
        color: AppColors.actionFill,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.actionShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
        for (final plan in plans) ...[
          FyCard(
            key: Key('hub-plan-${plan.id}'),
            onTap: isTrainer ? () => context.push('/plans/${plan.id}') : null,
            child: Row(
              children: [
                const FyIconBadge(
                  icon: Icons.fitness_center_rounded,
                  size: 52,
                  iconSize: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plan.exercises.length} упражнений',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                    onSelected: (_) => cubit.selectExercise(exercise.exerciseId),
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
