import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../../core/widgets/fy_primary_button.dart';
import '../../../core/widgets/fy_secondary_button.dart';
import '../../plans/data/plans_format.dart';
import '../../plans/data/plans_models.dart';
import '../../plans/presentation/widgets/plan_loads_table.dart';
import '../../schedule/presentation/widgets/weekday_multi_picker.dart';
import 'cubit/workout_program_cubit.dart';
import 'cubit/workout_program_state.dart';
import '../../../core/widgets/fy_top_bar.dart';

class WorkoutProgramView extends StatelessWidget {
  const WorkoutProgramView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutProgramCubit, WorkoutProgramState>(
      listenWhen: (previous, next) =>
          previous.errorMessage != next.errorMessage ||
          previous.validationMessage != next.validationMessage,
      listener: (context, state) {
        final message = state.validationMessage ?? state.errorMessage;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: FyTopBar(
            title: 'Программа',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: switch (state.status) {
            WorkoutProgramStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            WorkoutProgramStatus.failure => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.errorMessage ?? 'Не удалось загрузить'),
              ),
            ),
            WorkoutProgramStatus.ready ||
            WorkoutProgramStatus.saving => _ProgramBody(state: state),
          },
        );
      },
    );
  }
}

class _ProgramBody extends StatelessWidget {
  const _ProgramBody({required this.state});

  final WorkoutProgramState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkoutProgramCubit>();
    final booking = state.booking;
    if (booking == null) {
      return const Center(child: Text('Серия не найдена'));
    }
    final busy = state.status == WorkoutProgramStatus.saving;
    final names = {
      for (final exercise in state.plansById.values.expand((p) => p.exercises))
        exercise.exerciseId: exercise.exerciseName,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          booking.studentTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatWeekdays(booking.weekdays)} · ${formatStartMinute(booking.startMinute)}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Text(
          'Горизонт, недель',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              key: const Key('program-horizon-minus'),
              onPressed: busy
                  ? null
                  : () => cubit.setHorizonWeeks(state.horizonWeeks - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${state.horizonWeeks}',
              key: const Key('program-horizon-value'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              key: const Key('program-horizon-plus'),
              onPressed: busy
                  ? null
                  : () => cubit.setHorizonWeeks(state.horizonWeeks + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const FyInfoBanner(
          message:
              'Разные тренировки по дням серии. Веса на карточках — старт ученика; '
              'прогрессия раскладывается по датам при сохранении.',
        ),
        const SizedBox(height: 16),
        for (final weekday in booking.weekdays) ...[
          Text(
            weekdayLabels[weekday - 1],
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < (state.days[weekday]?.length ?? 0); i++)
            _WorkoutCard(
              weekday: weekday,
              index: i,
              item: state.days[weekday]![i],
              plan:
                  state.plansById[state.days[weekday]![i].studentPlanId] ??
                  state.plansById[state.days[weekday]![i].templateId],
              busy: busy,
            ),
          FySecondaryButton(
            key: Key('program-add-$weekday'),
            label: 'Добавить тренировку',
            onPressed: busy
                ? null
                : () => _pickTemplate(context, cubit, weekday),
          ),
          const SizedBox(height: 16),
        ],
        Text('Прогрессия', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.rules.isEmpty)
          const Text('Нет упражнений с весом — добавьте тренировки')
        else
          for (final rule in state.rules) _RuleRow(rule: rule, busy: busy),
        if (state.preview.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Превью дат', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final point in state.preview.take(12))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${point.date} · ${weekdayLabels[point.weekday - 1]} · '
                '${names[point.exerciseId] ?? 'упражнение'} · '
                '${point.weightKg} кг',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
        ],
        const SizedBox(height: 24),
        FyPrimaryButton(
          key: const Key('program-save'),
          label: busy ? 'Сохранение…' : 'Сохранить',
          isLoading: busy,
          onPressed: busy
              ? null
              : () async {
                  final ok = await cubit.save();
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Программа сохранена')),
                    );
                  }
                },
        ),
      ],
    );
  }

  Future<void> _pickTemplate(
    BuildContext context,
    WorkoutProgramCubit cubit,
    int weekday,
  ) async {
    final templates = cubit.state.templates;
    final selected = await showModalBottomSheet<TrainingPlanItem>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Шаблон тренировки',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (templates.isEmpty)
                const Text('Нет шаблонов — создайте в «Тренировки»')
              else
                for (final template in templates)
                  ListTile(
                    title: Text(template.title),
                    subtitle: Text(planGoalLabel(template.goal)),
                    onTap: () => Navigator.pop(context, template),
                  ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    cubit.addTemplate(weekday: weekday, template: selected);
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.weekday,
    required this.index,
    required this.item,
    required this.plan,
    required this.busy,
  });

  final int weekday;
  final int index;
  final ProgramDayDraftItem item;
  final TrainingPlanItem? plan;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkoutProgramCubit>();
    final planId = item.studentPlanId ?? item.templateId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  key: Key('program-remove-$weekday-$index'),
                  onPressed: busy
                      ? null
                      : () => cubit.removeItem(weekday: weekday, index: index),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (plan != null)
              PlanLoadsTable(
                exercises: plan!.exercises,
                onWeightChanged: busy
                    ? null
                    : (exerciseId, weightKg) => cubit.setCopyLoad(
                        planId: planId,
                        exerciseId: exerciseId,
                        weightKg: weightKg,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule, required this.busy});

  final ProgramRuleDraft rule;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkoutProgramCubit>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule.exerciseName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('program-rule-start-${rule.exerciseId}'),
                  enabled: !busy,
                  initialValue: rule.startWeightKg == null
                      ? ''
                      : '${rule.startWeightKg}',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Сейчас, кг',
                    isDense: true,
                  ),
                  onFieldSubmitted: (value) {
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null) return;
                    cubit.setRuleStart(rule.exerciseId, parsed);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: Key('program-rule-delta-${rule.exerciseId}'),
                  enabled: !busy,
                  initialValue: rule.deltaKg == 0 ? '' : '${rule.deltaKg}',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '+ кг за горизонт',
                    isDense: true,
                  ),
                  onFieldSubmitted: (value) {
                    final parsed =
                        double.tryParse(value.replaceAll(',', '.')) ?? 0;
                    cubit.setRuleDelta(rule.exerciseId, parsed);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
