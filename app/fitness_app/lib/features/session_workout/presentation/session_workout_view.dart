import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fy_button.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_chip.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../../core/widgets/fy_top_bar.dart';
import '../../plans/data/plans_format.dart';
import '../../plans/data/plans_models.dart';
import '../../plans/presentation/widgets/plan_loads_table.dart';
import '../../schedule/data/schedule_models.dart';
import '../../schedule/presentation/schedule_format.dart';
import 'cubit/session_workout_cubit.dart';
import 'cubit/session_workout_state.dart';
import 'widgets/attach_workout_sheet.dart';
import 'widgets/confirm_sets_sheet.dart';

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
        final session = state.session;
        final busy = state.status == SessionWorkoutStatus.mutating;
        final hasWorkout =
            session != null &&
            (session.workouts.isNotEmpty || state.plan != null);
        final overflow = session == null
            ? const <_OverflowAction>[]
            : _overflowActions(cubit, hasWorkout: hasWorkout);
        final showOverflowMenu =
            overflow.length > 1 ||
            overflow.contains(_OverflowAction.complete);
        return Scaffold(
          appBar: FyTopBar(
            title: 'Занятие',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (showOverflowMenu)
                PopupMenuButton<_OverflowAction>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) =>
                      _onOverflow(context, cubit, session, action, busy),
                  itemBuilder: (context) => [
                    for (final action in overflow)
                      PopupMenuItem(
                        key: Key(action.keyName),
                        value: action,
                        enabled: !busy,
                        child: Text(action.label),
                      ),
                  ],
                ),
            ],
          ),
          body: switch (state.status) {
            SessionWorkoutStatus.initial || SessionWorkoutStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            SessionWorkoutStatus.failure => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage ?? 'Не удалось загрузить занятие',
                ),
              ),
            ),
            SessionWorkoutStatus.ready || SessionWorkoutStatus.mutating =>
              _SessionBody(
                cubit: cubit,
                state: state,
                singleOverflow: overflow.length == 1 &&
                        overflow.first != _OverflowAction.complete
                    ? overflow.first
                    : null,
              ),
          },
          bottomNavigationBar:
              state.status == SessionWorkoutStatus.ready ||
                  state.status == SessionWorkoutStatus.mutating
              ? _SessionPrimaryBar(cubit: cubit, state: state)
              : null,
        );
      },
    );
  }
}

enum _OverflowAction { complete, noShow, cancel, history }

extension on _OverflowAction {
  String get label => switch (this) {
    _OverflowAction.complete => 'Проведена',
    _OverflowAction.noShow => 'Неявка',
    _OverflowAction.cancel => 'Отменить',
    _OverflowAction.history => 'История',
  };

  String get keyName => switch (this) {
    _OverflowAction.complete => 'session-complete',
    _OverflowAction.noShow => 'session-no-show',
    _OverflowAction.cancel => 'session-cancel',
    _OverflowAction.history => 'session-history',
  };
}

List<_OverflowAction> _overflowActions(
  SessionWorkoutCubit cubit, {
  required bool hasWorkout,
}) {
  return [
    if (!hasWorkout && cubit.canComplete) _OverflowAction.complete,
    if (cubit.canNoShow) _OverflowAction.noShow,
    if (cubit.canCancel) _OverflowAction.cancel,
    if (cubit.canHistory) _OverflowAction.history,
  ];
}

void _onOverflow(
  BuildContext context,
  SessionWorkoutCubit cubit,
  TrainingSession? session,
  _OverflowAction action,
  bool busy,
) {
  if (busy || session == null) return;
  switch (action) {
    case _OverflowAction.complete:
      cubit.complete();
    case _OverflowAction.noShow:
      _confirmNoShow(context, cubit);
    case _OverflowAction.cancel:
      _confirmCancel(context, cubit);
    case _OverflowAction.history:
      context.push('/sessions/${session.id}/history');
  }
}

class _SessionPrimaryBar extends StatelessWidget {
  const _SessionPrimaryBar({required this.cubit, required this.state});

  final SessionWorkoutCubit cubit;
  final SessionWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    if (session == null) return const SizedBox.shrink();
    final busy = state.status == SessionWorkoutStatus.mutating;
    final hasWorkout =
        session.workouts.isNotEmpty || state.plan != null;
    if (!hasWorkout && cubit.canAttach) {
      return _Bar(
        footer: _quietLifecycle(context, cubit, busy),
        child: FyButton.primary(
          key: const Key('session-choose-workout'),
          label: 'Выбрать тренировку',
          isLoading: busy,
          onPressed: busy ? null : () => showAttachWorkoutSheet(context),
        ),
      );
    }
    if (cubit.canComplete) {
      return _Bar(
        footer: _quietLifecycle(context, cubit, busy),
        child: FyButton.primary(
          key: const Key('session-complete'),
          label: 'Проведена',
          isLoading: busy,
          onPressed: busy
              ? null
              : () {
                  final exercises = _sessionExercises(session, state.plan);
                  if (exercises.isNotEmpty) {
                    showConfirmSetsSheet(context, exercises: exercises);
                  } else {
                    cubit.complete();
                  }
                },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget? _quietLifecycle(
    BuildContext context,
    SessionWorkoutCubit cubit,
    bool busy,
  ) {
    final overflowCount =
        (cubit.canNoShow ? 1 : 0) +
        (cubit.canCancel ? 1 : 0) +
        (cubit.canHistory ? 1 : 0);
    if (overflowCount <= 1) return null;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      children: [
        if (cubit.canNoShow)
          _QuietLink(
            label: 'Неявка',
            muted: true,
            onPressed: busy ? null : () => _confirmNoShow(context, cubit),
          ),
        if (cubit.canCancel)
          _QuietLink(
            label: 'Отменить',
            muted: true,
            onPressed: busy ? null : () => _confirmCancel(context, cubit),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.child, this.footer});

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            if (footer != null) ...[const SizedBox(height: 8), footer!],
          ],
        ),
      ),
    );
  }
}

class _SessionBody extends StatelessWidget {
  const _SessionBody({
    required this.cubit,
    required this.state,
    required this.singleOverflow,
  });

  final SessionWorkoutCubit cubit;
  final SessionWorkoutState state;
  final _OverflowAction? singleOverflow;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    if (session == null) {
      return const Center(child: Text('Занятие не найдено'));
    }
    final start = DateTime.parse(session.startsAt);
    final end = DateTime.parse(session.endsAt);
    final plan = state.plan;
    final busy = state.status == SessionWorkoutStatus.mutating;
    final modeLabel = session.mode == 'online' ? 'онлайн' : 'очно';
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

    if (singleOverflow != null) {
      links.add(
        _QuietLink(
          key: Key(singleOverflow!.keyName),
          label: singleOverflow!.label,
          muted: true,
          onPressed: busy
              ? null
              : () => _onOverflow(
                  context,
                  cubit,
                  session,
                  singleOverflow!,
                  busy,
                ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '${formatDateTime(start)} – ${formatTime(end)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '${session.peerPrimaryLabel(cubit.viewerId)} · $modeLabel · ${_statusLabel(session.status)}',
          style: TextStyle(color: AppColors.textMuted),
        ),
        if (state.remainingSessions != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FyChip(
              label: 'Осталось ${state.remainingSessions}',
              selected: false,
              backgroundColor: AppColors.mintSoft,
              foregroundColor: AppColors.primary,
              showBorder: false,
              showCheckmark: false,
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (session.workouts.isNotEmpty) ...[
          for (final workout in session.workouts) ...[
            FyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GoalPill(label: planGoalLabel(workout.goal)),
                      if (workout.overridden)
                        const _GoalPill(label: 'правка на занятие'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (workout.exercises.isEmpty)
                    const FyInfoBanner(
                      message: 'Упражнения не заданы — добавьте из списка',
                    )
                  else ...[
                    for (var i = 0; i < workout.exercises.length; i++)
                      _NumberedExercise(
                        index: i,
                        exercise: workout.exercises[i],
                      ),
                    if (cubit.canEditAttachedPlan)
                      PlanLoadsTable(
                        exercises: workout.exercises,
                        onWeightChanged: busy
                            ? null
                            : (exerciseId, weightKg) => cubit.overrideLoads(
                                studentPlanId: workout.studentPlanId,
                                items: [
                                  (
                                    exerciseId: exerciseId,
                                    weightKg: weightKg,
                                  ),
                                ],
                              ),
                      ),
                  ],
                  if (cubit.canAttach)
                    Padding(
                      padding: EdgeInsets.only(
                        top: workout.exercises.isEmpty ? 10 : 12,
                        left: workout.exercises.isEmpty
                            ? FyInfoBanner.messageLeadingInset -
                                _QuietLink.horizontalPadding
                            : 0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _QuietLink(
                          key: Key(
                            'session-remove-workout-${workout.studentPlanId}',
                          ),
                          label: 'Убрать эту тренировку',
                          muted: true,
                          onPressed: busy
                              ? null
                              : () =>
                                    cubit.removeWorkout(workout.studentPlanId),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ] else if (plan != null) ...[
          FyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GoalPill(label: planGoalLabel(plan.goal)),
                    for (final tag in plan.tags)
                      _GoalPill(label: '#${tag.name}'),
                  ],
                ),
                if (plan.displayNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(plan.displayNotes),
                ],
                const SizedBox(height: 12),
                if (plan.exercises.isEmpty)
                  const FyInfoBanner(
                    message:
                        'Упражнения не заданы — добавьте из списка или смените программу',
                  )
                else
                  for (var i = 0; i < plan.exercises.length; i++)
                    _NumberedExercise(index: i, exercise: plan.exercises[i]),
              ],
            ),
          ),
        ] else
          const Text('Тренировка ещё не выбрана'),
        if (links.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: links,
          ),
        ],
      ],
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'booked':
        return 'запланирована';
      case 'completed':
        return 'проведена';
      case 'cancelled':
        return 'отменена';
      case 'no_show':
        return 'неявка';
      default:
        return status;
    }
  }
}

class _GoalPill extends StatelessWidget {
  const _GoalPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FyChip(
      label: label,
      selected: false,
      backgroundColor: AppColors.mintSoft,
      foregroundColor: AppColors.primary,
      showBorder: false,
      showCheckmark: false,
      compact: true,
    );
  }
}

class _NumberedExercise extends StatelessWidget {
  const _NumberedExercise({required this.index, required this.exercise});

  final int index;
  final PlanExerciseItem exercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 12,
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
                  exercise.exerciseName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  formatPlanExerciseRow(exercise),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
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

  static const double horizontalPadding = 12;
  static const double verticalPadding = 10;

  final String label;
  final VoidCallback? onPressed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: muted ? AppColors.textMuted : AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
