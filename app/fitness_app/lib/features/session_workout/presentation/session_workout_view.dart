import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/fy_avatar.dart';
import '../../../core/widgets/fy_button.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../../core/widgets/fy_square_icon_button.dart';
import '../../../core/widgets/fy_status_chip.dart';
import '../../finance/data/money_formatter.dart';
import '../../home/presentation/home_format.dart';
import '../../plans/data/plans_format.dart';
import '../../plans/data/plans_models.dart';
import '../../plans/presentation/widgets/plan_loads_table.dart';
import '../../schedule/data/schedule_models.dart';
import '../../schedule/presentation/schedule_format.dart';
import '../../schedule/presentation/session_status.dart';
import 'cubit/session_workout_cubit.dart';
import 'cubit/session_workout_state.dart';
import 'widgets/attach_workout_sheet.dart';
import 'widgets/confirm_sets_sheet.dart';

/// Session card (DS v2): who and when on top, the workout below, one filled
/// action at the bottom; cancel and history live in the header.
class SessionWorkoutView extends StatelessWidget {
  const SessionWorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionWorkoutCubit, SessionWorkoutState>(
      listenWhen: (previous, next) =>
          previous.errorMessage != next.errorMessage ||
          previous.infoMessage != next.infoMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
        final info = state.infoMessage;
        if (info != null && info.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(info)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<SessionWorkoutCubit>();
        final ready =
            state.status == SessionWorkoutStatus.ready ||
            state.status == SessionWorkoutStatus.mutating;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SessionHeader(cubit: cubit, state: state),
                Expanded(
                  child: switch (state.status) {
                    SessionWorkoutStatus.initial ||
                    SessionWorkoutStatus.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    SessionWorkoutStatus.failure => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.errorMessage ?? 'Не удалось загрузить занятие',
                        ),
                      ),
                    ),
                    SessionWorkoutStatus.ready ||
                    SessionWorkoutStatus.mutating => _SessionBody(
                      cubit: cubit,
                      state: state,
                    ),
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: ready
              ? _SessionActionBar(cubit: cubit, state: state)
              : null,
        );
      },
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.cubit, required this.state});

  final SessionWorkoutCubit cubit;
  final SessionWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    final busy = state.status == SessionWorkoutStatus.mutating;
    final loaded = session != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          FySquareIconButton(
            buttonKey: const Key('session-back'),
            tooltip: 'Назад',
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Занятие',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (loaded && cubit.canHistory)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FySquareIconButton(
                buttonKey: const Key('session-history'),
                tooltip: 'История',
                icon: Icons.history_rounded,
                onPressed: () =>
                    context.push('/sessions/${session.id}/history'),
              ),
            ),
          if (loaded && cubit.canCancel)
            TextButton(
              key: const Key('session-cancel'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              onPressed: busy ? null : () => _confirmCancel(context, cubit),
              child: const Text('Отменить'),
            ),
        ],
      ),
    );
  }
}

/// Bottom actions: one filled button (choose a workout, or mark the session
/// done) and quiet outlined alternatives below it.
class _SessionActionBar extends StatelessWidget {
  const _SessionActionBar({required this.cubit, required this.state});

  final SessionWorkoutCubit cubit;
  final SessionWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    if (session == null) return const SizedBox.shrink();
    final busy = state.status == SessionWorkoutStatus.mutating;
    final hasWorkout = session.workouts.isNotEmpty || state.plan != null;
    final needsWorkout = !hasWorkout && cubit.canAttach;

    void complete() {
      final exercises = _sessionExercises(session, state.plan);
      if (exercises.isNotEmpty) {
        showConfirmSetsSheet(context, exercises: exercises);
      } else {
        cubit.complete();
      }
    }

    final Widget? primary;
    if (needsWorkout) {
      primary = FyButton.primary(
        key: const Key('session-choose-workout'),
        label: 'Выбрать тренировку',
        icon: Icons.fitness_center_rounded,
        isLoading: busy,
        onPressed: busy ? null : () => showAttachWorkoutSheet(context),
      );
    } else if (cubit.canComplete) {
      primary = FyButton.primary(
        key: const Key('session-complete'),
        label: 'Отметить проведённым',
        icon: Icons.check_rounded,
        isLoading: busy,
        onPressed: busy ? null : complete,
      );
    } else {
      primary = null;
    }

    final secondary = <Widget>[
      if (needsWorkout && cubit.canComplete)
        _OutlinedAction(
          key: const Key('session-complete'),
          label: 'Без тренировки',
          onPressed: busy ? null : cubit.complete,
        ),
      if (cubit.canNoShow)
        _OutlinedAction(
          key: const Key('session-no-show'),
          label: 'Не пришёл',
          onPressed: busy ? null : () => _confirmNoShow(context, cubit),
        ),
    ];

    if (primary == null && secondary.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?primary,
              if (primary != null && secondary.isNotEmpty)
                const SizedBox(height: 8),
              if (secondary.isNotEmpty)
                Row(
                  children: [
                    for (var i = 0; i < secondary.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: secondary[i]),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      onPressed: onPressed,
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    );
  }
}

class _SessionBody extends StatelessWidget {
  const _SessionBody({required this.cubit, required this.state});

  final SessionWorkoutCubit cubit;
  final SessionWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    if (session == null) {
      return const Center(child: Text('Занятие не найдено'));
    }
    final plan = state.plan;
    final busy = state.status == SessionWorkoutStatus.mutating;
    final links = <Widget>[];

    if (cubit.isCoach && session.recurringBookingId != null) {
      links.add(
        _QuietLink(
          key: const Key('session-open-program'),
          label: 'Программа',
          onPressed: () => context.push(
            '/schedule/recurring/${session.recurringBookingId}/program',
          ),
        ),
      );
    }

    if (session.workouts.isNotEmpty) {
      if (cubit.canEditAttachedPlan) {
        links.add(
          _QuietLink(
            key: const Key('session-compose-exercises'),
            label: 'Изменить состав',
            onPressed: busy
                ? null
                : () => _openSessionPlanEditor(context, cubit),
          ),
        );
      }
      if (cubit.canAttach) {
        links.add(
          _QuietLink(
            key: const Key('session-add-workout'),
            label: 'Добавить',
            onPressed: busy
                ? null
                : () => showAttachWorkoutSheet(context, append: true),
          ),
        );
      }
    } else if (plan != null) {
      if (cubit.canEditAttachedPlan) {
        links.add(
          _QuietLink(
            key: const Key('session-compose-exercises'),
            label: plan.exercises.isEmpty
                ? 'Добавить упражнения'
                : 'Изменить состав',
            onPressed: busy
                ? null
                : () => _openSessionPlanEditor(context, cubit),
          ),
        );
      }
      if (cubit.canAttach) {
        links.add(
          _QuietLink(
            key: const Key('session-change-workout'),
            label: 'Сменить',
            onPressed: busy ? null : () => showAttachWorkoutSheet(context),
          ),
        );
      }
    } else if (cubit.canCreateAdHocPlan) {
      links.add(
        _QuietLink(
          key: const Key('session-compose-exercises'),
          label: 'Упражнения из списка',
          onPressed: busy
              ? null
              : () => _openSessionPlanEditor(
                  context,
                  cubit,
                  createIfMissing: true,
                ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _SessionSummaryCard(
          session: session,
          viewerId: cubit.viewerId,
          isCoach: cubit.isCoach,
          remainingSessions: state.remainingSessions,
        ),
        const SizedBox(height: 20),
        Text(
          'Тренировка',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (session.workouts.isNotEmpty) ...[
          for (final workout in session.workouts) ...[
            _WorkoutCard(
              title: workout.title,
              subtitle: [
                planGoalLabel(workout.goal),
                if (workout.overridden) 'правка на занятие',
              ].join(' · '),
              exercises: workout.exercises,
              emptyMessage: 'Упражнения не заданы — добавьте из списка',
              footer: [
                if (workout.exercises.isNotEmpty && cubit.canEditAttachedPlan)
                  PlanLoadsTable(
                    exercises: workout.exercises,
                    onWeightChanged: busy
                        ? null
                        : (exerciseId, weightKg) => cubit.overrideLoads(
                            studentPlanId: workout.studentPlanId,
                            items: [
                              (exerciseId: exerciseId, weightKg: weightKg),
                            ],
                          ),
                  ),
                if (cubit.canAttach)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _QuietLink(
                      key: Key(
                        'session-remove-workout-${workout.studentPlanId}',
                      ),
                      label: 'Убрать эту тренировку',
                      muted: true,
                      onPressed: busy
                          ? null
                          : () => cubit.removeWorkout(workout.studentPlanId),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ] else if (plan != null) ...[
          _WorkoutCard(
            title: plan.title,
            subtitle: [
              planGoalLabel(plan.goal),
              for (final tag in plan.tags) '#${tag.name}',
            ].join(' · '),
            exercises: plan.exercises,
            emptyMessage:
                'Упражнения не заданы — добавьте из списка или смените программу',
          ),
          if (plan.displayNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _NoteCard(text: plan.displayNotes),
          ],
        ] else
          const _EmptyWorkoutCard(),
        if (links.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: links),
        ],
      ],
    );
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({
    required this.session,
    required this.viewerId,
    required this.isCoach,
    required this.remainingSessions,
  });

  final TrainingSession session;
  final String viewerId;
  final bool isCoach;
  final int? remainingSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.parse(session.startsAt).toLocal();
    final end = DateTime.parse(session.endsAt).toLocal();
    final (status, statusLabel) = sessionStatusChip(session.status);
    final peer = session.peerPrimaryLabel(viewerId);
    final online = session.mode == 'online';
    final finance = session.finance;
    final peerCaption = remainingSessions != null
        ? 'Пакет · осталось $remainingSessions'
        : (isCoach ? 'Ученик' : 'Тренер');
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );

    Widget meta(IconData icon, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: metaStyle)),
      ],
    );

    return FyCard(
      key: const Key('session-summary'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatHomeHeaderDate(start),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${formatTime(start)} – ${formatTime(end)}',
                        key: const Key('session-time'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FyStatusChip(status: status, label: statusLabel),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              FyAvatar(
                displayName: isCoach
                    ? session.studentDisplayName
                    : session.coachDisplayName,
                email: isCoach ? session.studentEmail : session.coachEmail,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      peerCaption,
                      key: const Key('session-peer-caption'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FySquareIconButton(
                buttonKey: const Key('session-open-chat'),
                tooltip: 'Написать',
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                onPressed: () => context.go('/chats'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              meta(
                online ? Icons.videocam_outlined : Icons.place_outlined,
                online ? 'Онлайн' : 'Офлайн',
              ),
              if (finance.isTracked)
                meta(
                  Icons.account_balance_wallet_outlined,
                  MoneyFormatter.format(
                    finance.amountMinor!,
                    currency: finance.currency ?? 'RUB',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.title,
    required this.subtitle,
    required this.exercises,
    required this.emptyMessage,
    this.footer = const [],
  });

  final String title;
  final String subtitle;
  final List<PlanExerciseItem> exercises;
  final String emptyMessage;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FyCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FyInfoBanner(message: emptyMessage),
            )
          else
            for (var i = 0; i < exercises.length; i++)
              _NumberedExercise(index: i, exercise: exercises[i]),
          ...footer,
        ],
      ),
    );
  }
}

class _NumberedExercise extends StatelessWidget {
  const _NumberedExercise({required this.index, required this.exercise});

  final int index;
  final PlanExerciseItem exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sunken,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                exercise.exerciseName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                formatPlanExerciseRow(exercise),
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FyCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sticky_note_2_outlined,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkoutCard extends StatelessWidget {
  const _EmptyWorkoutCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('session-no-workout'),
      decoration: BoxDecoration(
        color: AppColors.sunken,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.fitness_center_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Тренировка ещё не выбрана',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietLink extends StatelessWidget {
  const _QuietLink({
    required this.label,
    required this.onPressed,
    this.muted = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: muted ? AppColors.textSecondary : AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      child: Text(label),
    );
  }
}

Future<void> _confirmCancel(
  BuildContext context,
  SessionWorkoutCubit cubit,
) async {
  final noteController = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Отменить тренировку?'),
      content: TextField(
        controller: noteController,
        decoration: const InputDecoration(
          labelText: 'Комментарий (необязательно)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Нет'),
        ),
        FyButton.primary(
          label: 'Отменить',
          fullWidth: false,
          size: FyButtonSize.medium,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  final note = noteController.text.trim();
  noteController.dispose();
  if (ok == true) {
    await cubit.cancel(note: note.isEmpty ? null : note);
  }
}

Future<void> _confirmNoShow(
  BuildContext context,
  SessionWorkoutCubit cubit,
) async {
  final charge = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Отметить неявку'),
      content: const Text('Списать стоимость тренировки?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Нет, без оплаты'),
        ),
        FyButton.primary(
          label: 'Да, начислить',
          fullWidth: false,
          size: FyButtonSize.medium,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (charge == null) return;
  await cubit.markNoShow(charge: charge);
}

Future<void> _openSessionPlanEditor(
  BuildContext context,
  SessionWorkoutCubit cubit, {
  bool createIfMissing = false,
}) async {
  if (createIfMissing && cubit.state.plan == null) {
    await cubit.ensureAdHocCopy();
  }
  final planId = cubit.state.plan?.id;
  if (planId == null || !context.mounted) return;
  await context.push('/sessions/${cubit.sessionId}/plan-edit?id=$planId');
  if (!context.mounted) return;
  await cubit.load();
}

List<PlanExerciseItem> _sessionExercises(
  TrainingSession session,
  TrainingPlanItem? plan,
) {
  if (session.workouts.isNotEmpty) {
    return [for (final workout in session.workouts) ...workout.exercises];
  }
  return plan?.exercises ?? const [];
}
