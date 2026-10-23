import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/plans_format.dart';
import '../../data/plans_models.dart';
import '../../data/plans_repository.dart';
import '../cubit/plan_editor_cubit.dart';
import '../cubit/plan_editor_state.dart';
import '../widgets/plan_loads_table.dart';
import '../../../../core/widgets/fy_button.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_chip.dart';
import '../widgets/plans_header.dart';

class PlanEditScreen extends StatelessWidget {
  const PlanEditScreen({super.key, this.planId});

  final String? planId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlanEditorCubit(
        repository: context.read<PlansRepository>(),
        planId: planId,
      )..load(),
      child: const PlanEditorView(),
    );
  }
}

class PlanEditorView extends StatefulWidget {
  const PlanEditorView({super.key});

  @override
  State<PlanEditorView> createState() => _PlanEditorViewState();
}

class _PlanEditorViewState extends State<PlanEditorView> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  var _synced = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _editorTitle(PlanEditorCubit cubit) {
    if (!cubit.isEdit) return 'Новый шаблон';
    if (cubit.state.kind == 'student_copy') return 'Состав занятия';
    return 'Редактировать шаблон';
  }

  void _syncFromState(PlanEditorState state) {
    if (_synced || state.status != PlanEditorStatus.ready) return;
    _title.text = state.title;
    _notes.text = state.notes;
    _synced = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanEditorCubit, PlanEditorState>(
      listener: (context, state) {
        _syncFromState(state);
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.validationMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.validationMessage!)));
        }
      },
      builder: (context, state) {
        _syncFromState(state);
        final cubit = context.read<PlanEditorCubit>();
        final theme = Theme.of(context);
        final ready =
            state.status != PlanEditorStatus.loading &&
            state.status != PlanEditorStatus.initial &&
            state.status != PlanEditorStatus.failure;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlansHeader(title: _editorTitle(cubit)),
                Expanded(
                  child: !ready
                      ? state.status == PlanEditorStatus.failure
                            ? Center(
                                child: Text(state.errorMessage ?? 'Ошибка'),
                              )
                            : const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          children: [
                            TextField(
                              controller: _title,
                              decoration: const InputDecoration(
                                labelText: 'Название *',
                              ),
                              onChanged: cubit.setTitle,
                            ),
                            const SizedBox(height: 20),
                            Text('Цель', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final goal in const [
                                  ('hypertrophy', 'Набор'),
                                  ('fat_loss', 'Похудение'),
                                  ('general', 'Общее'),
                                ])
                                  FyChip(
                                    label: goal.$2,
                                    selected: state.goal == goal.$1,
                                    outlined: state.goal != goal.$1,
                                    onSelected: (_) => cubit.setGoal(goal.$1),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text('Теги', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 12),
                            if (state.tags.isEmpty)
                              FyButton.soft(
                                label: 'Создать теги',
                                icon: Icons.sell_outlined,
                                size: FyButtonSize.medium,
                                fullWidth: false,
                                onPressed: () => context.push('/tags'),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final tag in state.tags)
                                    FyChip(
                                      label: '#${tag.name}',
                                      selected: state.selectedTagIds.contains(
                                        tag.id,
                                      ),
                                      outlined: !state.selectedTagIds.contains(
                                        tag.id,
                                      ),
                                      onSelected: (_) =>
                                          cubit.toggleTag(tag.id),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _notes,
                              minLines: 2,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Заметка',
                                alignLabelWithHint: true,
                              ),
                              onChanged: cubit.setNotes,
                            ),
                            const SizedBox(height: 20),
                            PlanLoadsTable(
                              exercises: state.exercises,
                              onWeightChanged: cubit.setLoadWeight,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Упражнения',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            if (state.exercises.isEmpty)
                              FyCard(
                                child: Text(
                                  'Добавьте упражнение из поиска',
                                  style: theme.textTheme.bodySmall,
                                ),
                              )
                            else
                              for (final exercise in state.exercises) ...[
                                _ExerciseRow(
                                  exercise: exercise,
                                  onEdit: () =>
                                      _editSets(context, cubit, exercise),
                                  onRemove: () =>
                                      cubit.removeExercise(exercise.exerciseId),
                                ),
                                const SizedBox(height: 12),
                              ],
                            const SizedBox(height: 8),
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Найти или создать упражнение',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: cubit.setExerciseQuery,
                            ),
                            const SizedBox(height: 8),
                            for (final item in state.filteredExercises.take(8))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.name),
                                subtitle: Text(item.isCatalog ? 'База' : 'Моё'),
                                trailing: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.primary,
                                ),
                                onTap: () => cubit.addExercise(item),
                              ),
                            if (state.exerciseQuery.trim().isNotEmpty)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FyButton.soft(
                                  label:
                                      'Создать «${state.exerciseQuery.trim()}»',
                                  icon: Icons.add_rounded,
                                  size: FyButtonSize.medium,
                                  fullWidth: false,
                                  onPressed: () =>
                                      _createExercise(context, cubit),
                                ),
                              ),
                          ],
                        ),
                ),
                if (ready)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: FyButton.primary(
                        label: state.status == PlanEditorStatus.saving
                            ? 'Сохранение…'
                            : 'Сохранить',
                        onPressed: state.status == PlanEditorStatus.saving
                            ? null
                            : () async {
                                final ok = await cubit.save();
                                if (ok && context.mounted) context.pop();
                              },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createExercise(
    BuildContext context,
    PlanEditorCubit cubit,
  ) async {
    var kind = 'weight_reps';
    final name = cubit.state.exerciseQuery.trim();
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Создать «$name»'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return RadioGroup<String>(
                groupValue: kind,
                onChanged: (value) {
                  if (value == null) return;
                  setLocal(() => kind = value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in const [
                      ('weight_reps', 'Вес × повторы'),
                      ('bodyweight_reps', 'Свои повторы'),
                      ('duration', 'Время'),
                    ])
                      RadioListTile<String>(
                        title: Text(option.$2),
                        value: option.$1,
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, kind),
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
    if (selected == null) return;
    await cubit.createAndAddExercise(name: name, kind: selected);
  }

  Future<void> _editSets(
    BuildContext context,
    PlanEditorCubit cubit,
    PlanExerciseItem exercise,
  ) async {
    final first = exercise.sets.isEmpty ? null : exercise.sets.first;
    final setsCtrl = TextEditingController(
      text: '${exercise.sets.isEmpty ? 3 : exercise.sets.length}',
    );
    final repsCtrl = TextEditingController(text: '${first?.reps ?? 10}');
    final weightCtrl = TextEditingController(
      text: first?.weightKg == null ? '' : '${first!.weightKg}',
    );
    final durationCtrl = TextEditingController(
      text: '${first?.durationSeconds ?? 30}',
    );
    final restCtrl = TextEditingController(
      text: '${exercise.restSeconds ?? 60}',
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                exercise.exerciseName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: setsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Подходы'),
              ),
              if (exercise.exerciseKind == 'duration')
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Секунды'),
                )
              else ...[
                TextField(
                  controller: repsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Повторы'),
                ),
                if (exercise.exerciseKind == 'weight_reps')
                  TextField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Вес, кг'),
                  ),
              ],
              TextField(
                controller: restCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Отдых, сек'),
              ),
              const SizedBox(height: 16),
              FyButton.primary(
                label: 'Готово',
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );
    if (saved != true) return;
    cubit.updateExerciseSets(
      exerciseId: exercise.exerciseId,
      setCount: int.tryParse(setsCtrl.text) ?? exercise.sets.length,
      reps: int.tryParse(repsCtrl.text) ?? 10,
      weightKg: double.tryParse(weightCtrl.text.replaceAll(',', '.')),
      durationSeconds: int.tryParse(durationCtrl.text),
      restSeconds: int.tryParse(restCtrl.text) ?? 60,
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.onEdit,
    required this.onRemove,
  });

  final PlanExerciseItem exercise;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FyCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.exerciseName, style: theme.textTheme.titleMedium),
                Text(
                  formatPlanExerciseRow(exercise),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Убрать',
            icon: const Icon(Icons.close_rounded),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
