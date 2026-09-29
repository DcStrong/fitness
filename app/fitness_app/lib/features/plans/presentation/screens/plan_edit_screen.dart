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
import '../../../../core/widgets/fy_top_bar.dart';

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
        return Scaffold(
          appBar: FyTopBar(
            title: _editorTitle(cubit),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body:
              state.status == PlanEditorStatus.loading ||
                  state.status == PlanEditorStatus.initial
              ? const Center(child: CircularProgressIndicator())
              : state.status == PlanEditorStatus.failure
              ? Center(child: Text(state.errorMessage ?? 'Ошибка'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Название *',
                      ),
                      onChanged: cubit.setTitle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Цель',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final goal in const [
                          ('hypertrophy', 'Набор'),
                          ('fat_loss', 'Похудение'),
                          ('general', 'Общее'),
                        ])
                          ChoiceChip(
                            label: Text(goal.$2),
                            selected: state.goal == goal.$1,
                            selectedColor: AppColors.mintSoft,
                            onSelected: (_) => cubit.setGoal(goal.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Теги',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (state.tags.isEmpty)
                      TextButton.icon(
                        onPressed: () => context.push('/tags'),
                        icon: const Icon(Icons.sell_outlined),
                        label: const Text('Создать теги'),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.tags.map((tag) {
                          final selected = state.selectedTagIds.contains(
                            tag.id,
                          );
                          return FilterChip(
                            label: Text('#${tag.name}'),
                            selected: selected,
                            onSelected: (_) => cubit.toggleTag(tag.id),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    PlanLoadsTable(
                      exercises: state.exercises,
                      onWeightChanged: cubit.setLoadWeight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Упражнения',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (state.exercises.isEmpty)
                      const Text('Добавьте упражнение из поиска')
                    else
                      ...state.exercises.map(
                        (exercise) => _ExerciseRow(
                          exercise: exercise,
                          onEdit: () => _editSets(context, cubit, exercise),
                          onRemove: () =>
                              cubit.removeExercise(exercise.exerciseId),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Найти или создать упражнение',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: cubit.setExerciseQuery,
                    ),
                    const SizedBox(height: 8),
                    ...state.filteredExercises.take(8).map((item) {
                      return ListTile(
                        dense: true,
                        title: Text(item.name),
                        subtitle: Text(item.isCatalog ? 'База' : 'Моё'),
                        onTap: () => cubit.addExercise(item),
                      );
                    }),
                    if (state.exerciseQuery.trim().isNotEmpty)
                      TextButton(
                        onPressed: () => _createExercise(context, cubit),
                        child: Text('Создать «${state.exerciseQuery.trim()}»'),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: state.status == PlanEditorStatus.saving
                          ? null
                          : () async {
                              final ok = await cubit.save();
                              if (ok && context.mounted) context.pop();
                            },
                      child: Text(
                        state.status == PlanEditorStatus.saving
                            ? 'Сохранение…'
                            : 'Сохранить',
                      ),
                    ),
                  ],
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
              return Column(
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
                      groupValue: kind,
                      onChanged: (value) {
                        if (value == null) return;
                        setLocal(() => kind = value);
                      },
                    ),
                ],
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
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
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
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Готово'),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(exercise.exerciseName),
      subtitle: Text(formatPlanExerciseRow(exercise)),
      onTap: onEdit,
      trailing: IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
    );
  }
}
