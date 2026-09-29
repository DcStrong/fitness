import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_chip.dart';
import '../../../../core/widgets/fy_icon_badge.dart';
import '../../../../core/widgets/fy_segmented_control.dart';
import '../../../../core/widgets/fy_top_bar.dart';
import '../../data/plans_format.dart';
import '../../data/plans_models.dart';
import '../../data/plans_repository.dart';
import '../cubit/plans_library_cubit.dart';
import '../cubit/plans_library_state.dart';
import '../library_tag_rank.dart';
import '../widgets/assign_exercises_sheet.dart';
import '../widgets/pick_student_sheet.dart';
import '../widgets/tag_search_sheet.dart';

class PlansListScreen extends StatelessWidget {
  const PlansListScreen({super.key, required this.visibleOnly});

  final bool visibleOnly;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlansLibraryCubit(
        repository: context.read<PlansRepository>(),
        visibleOnly: visibleOnly,
      )..load(),
      child: PlansLibraryView(visibleOnly: visibleOnly),
    );
  }
}

class PlansLibraryView extends StatelessWidget {
  const PlansLibraryView({super.key, required this.visibleOnly});

  final bool visibleOnly;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlansLibraryCubit, PlansLibraryState>(
      listener: (context, state) {
        if (state.errorMessage != null &&
            state.status != PlansLibraryStatus.failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<PlansLibraryCubit>();
        final isCatalog =
            !visibleOnly && state.mode == PlansLibraryMode.catalog;
        final isExercises =
            !visibleOnly && state.mode == PlansLibraryMode.exercises;
        final showBack = context.canPop();
        return Scaffold(
          appBar: FyTopBar(
            title: visibleOnly ? 'Доступные' : 'Тренировки',
            automaticallyImplyLeading: false,
            leading: showBack
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  )
                : null,
            actions: [
              if (!visibleOnly && state.mode == PlansLibraryMode.own)
                IconButton(
                  tooltip: state.selecting ? 'Готово' : 'Выбрать',
                  onPressed: cubit.toggleSelecting,
                  icon: Icon(state.selecting ? Icons.check : Icons.checklist),
                ),
              if (!visibleOnly)
                IconButton(
                  key: const Key('plans-tags-button'),
                  tooltip: 'Теги',
                  onPressed: () => context.push('/tags'),
                  icon: const Icon(Icons.sell_outlined),
                ),
              IconButton(
                onPressed: state.status == PlansLibraryStatus.loading
                    ? null
                    : cubit.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: _fab(context, state, isCatalog, isExercises),
          body: Column(
            children: [
              if (!visibleOnly) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: FySegmentedControl<PlansLibraryMode>(
                    value: state.mode,
                    onChanged: cubit.setMode,
                    segments: const [
                      FySegment(
                        value: PlansLibraryMode.own,
                        label: 'Мои',
                      ),
                      FySegment(
                        value: PlansLibraryMode.catalog,
                        label: 'База',
                      ),
                      FySegment(
                        value: PlansLibraryMode.exercises,
                        label: 'Упражнения',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: isExercises
                          ? 'Поиск упражнения'
                          : 'Поиск по названию',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: cubit.setQuery,
                  ),
                ),
                if (state.tags.isNotEmpty)
                  _CompactTagRow(state: state, cubit: cubit),
              ],
              Expanded(child: _body(context, state, isCatalog: isCatalog)),
            ],
          ),
        );
      },
    );
  }

  Widget? _fab(
    BuildContext context,
    PlansLibraryState state,
    bool isCatalog,
    bool isExercises,
  ) {
    if (visibleOnly || isCatalog) return null;
    final cubit = context.read<PlansLibraryCubit>();
    if (state.selecting && state.mode == PlansLibraryMode.own) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: const StadiumBorder(),
        onPressed: state.selectedPlanIds.isEmpty
            ? null
            : () async {
                final studentId = await showPickStudentSheet(context);
                if (studentId == null || !context.mounted) return;
                final ok = await cubit.assignSelectedPlans(studentId);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Тренировки назначены')),
                  );
                }
              },
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('Назначить (${state.selectedPlanIds.length})'),
      );
    }
    if (isExercises && state.selectedExerciseIds.isNotEmpty) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: const StadiumBorder(),
        onPressed: () async {
          final selected = state.visibleExercises
              .where((item) => state.selectedExerciseIds.contains(item.id))
              .toList();
          final ok = await showAssignExercisesSheet(
            context,
            exercises: selected,
          );
          if (ok && context.mounted) {
            cubit.clearExerciseSelection();
            await cubit.load();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Упражнения назначены')),
              );
            }
          }
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('Назначить (${state.selectedExerciseIds.length})'),
      );
    }
    if (isExercises) return null;
    return FloatingActionButton(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      shape: const CircleBorder(),
      elevation: 3,
      onPressed: () async {
        await context.push('/plans/edit');
        if (context.mounted) {
          await cubit.load();
        }
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _body(
    BuildContext context,
    PlansLibraryState state, {
    required bool isCatalog,
  }) {
    if (state.status == PlansLibraryStatus.loading ||
        state.status == PlansLibraryStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == PlansLibraryStatus.failure) {
      return Center(child: Text(state.errorMessage ?? 'Ошибка'));
    }
    if (visibleOnly) {
      return _StudentVisibleBody(state: state);
    }
    if (state.mode == PlansLibraryMode.exercises) {
      return _ExercisesBody(state: state);
    }
    final plans = state.visiblePlans;
    if (plans.isEmpty) {
      return Center(
        child: Text(isCatalog ? 'Каталог пуст' : 'Пока нет шаблонов'),
      );
    }
    final cubit = context.read<PlansLibraryCubit>();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final plan = plans[index];
        final selected = state.selectedPlanIds.contains(plan.id);
        return _PlanCard(
          plan: plan,
          isCatalog: isCatalog,
          cloning: state.cloningId == plan.id,
          selecting: state.selecting,
          selected: selected,
          onOpen: () async {
            if (state.selecting) {
              cubit.togglePlanSelected(plan.id);
              return;
            }
            await context.push('/plans/${plan.id}');
            if (context.mounted) {
              await cubit.load();
            }
          },
          onEdit: isCatalog
              ? null
              : () async {
                  await context.push('/plans/edit?id=${plan.id}');
                  if (context.mounted) {
                    await cubit.load();
                  }
                },
          onClone: isCatalog
              ? () async {
                  final ok = await cubit.clonePlan(plan.id);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Добавлено в «Мои»')),
                    );
                  }
                }
              : null,
        );
      },
    );
  }
}

class _StudentVisibleBody extends StatelessWidget {
  const _StudentVisibleBody({required this.state});

  final PlansLibraryState state;

  @override
  Widget build(BuildContext context) {
    if (state.plans.isEmpty && state.exercises.isEmpty) {
      return const Center(child: Text('Нет тренировок и упражнений по тегам'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Тренировки', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.plans.isEmpty)
          const Text('Нет тренировок по общим тегам')
        else
          ...state.plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plan,
                isCatalog: false,
                cloning: false,
                selecting: false,
                selected: false,
                onOpen: () => context.push('/plans/${plan.id}'),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Упражнения', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.exercises.isEmpty)
          const Text('Нет упражнений по тегам')
        else
          ...state.exercises.map(
            (exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExerciseCard(exercise: exercise, readOnly: true),
            ),
          ),
      ],
    );
  }
}

class _ExercisesBody extends StatelessWidget {
  const _ExercisesBody({required this.state});

  final PlansLibraryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlansLibraryCubit>();
    final exercises = state.visibleExercises;
    if (exercises.isEmpty) {
      return const Center(child: Text('Нет упражнений'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _ExerciseCard(
          exercise: exercise,
          selected: state.selectedExerciseIds.contains(exercise.id),
          onToggle: () => cubit.toggleExerciseSelected(exercise.id),
          onEditTags: () => _editTags(context, cubit, exercise),
        );
      },
    );
  }

  Future<void> _editTags(
    BuildContext context,
    PlansLibraryCubit cubit,
    ExerciseItem exercise,
  ) async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _ExerciseTagsDialog(
        tags: cubit.state.tags,
        selectedIds: exercise.tags.map((tag) => tag.id).toSet(),
      ),
    );
    if (selected == null) return;
    await cubit.replaceExerciseTags(
      exerciseId: exercise.id,
      tagIds: selected.toList(),
    );
  }
}

class _ExerciseTagsDialog extends StatefulWidget {
  const _ExerciseTagsDialog({required this.tags, required this.selectedIds});

  final List<TagItem> tags;
  final Set<String> selectedIds;

  @override
  State<_ExerciseTagsDialog> createState() => _ExerciseTagsDialogState();
}

class _ExerciseTagsDialogState extends State<_ExerciseTagsDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedIds};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Теги упражнения'),
      content: widget.tags.isEmpty
          ? const Text('Сначала создайте теги')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in widget.tags)
                  FilterChip(
                    label: Text('#${tag.name}'),
                    selected: _selected.contains(tag.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selected.add(tag.id);
                        } else {
                          _selected.remove(tag.id);
                        }
                      });
                    },
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCatalog,
    required this.cloning,
    required this.onOpen,
    this.onEdit,
    this.onClone,
    this.selecting = false,
    this.selected = false,
  });

  final TrainingPlanItem plan;
  final bool isCatalog;
  final bool cloning;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onClone;
  final bool selecting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tags = plan.tags.take(2).map((tag) => '#${tag.name}').join(' · ');
    return FyCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (selecting)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    selected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: AppColors.primary,
                  ),
                ),
              const FyIconBadge(
                icon: Icons.fitness_center_rounded,
                size: 52,
                iconSize: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FyChip(
                label: planGoalLabel(plan.goal),
                selected: false,
                compact: true,
                showCheckmark: false,
                showBorder: false,
                backgroundColor: AppColors.mintSoft,
                foregroundColor: AppColors.primary,
              ),
              if (tags.isNotEmpty)
                Text(tags, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.exercises.length} упражнений',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          if (onEdit != null || onClone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Редактировать'),
                  ),
                if (onClone != null)
                  TextButton(
                    onPressed: cloning ? null : onClone,
                    child: Text(cloning ? 'Добавление…' : 'Добавить к себе'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    this.selected = false,
    this.onToggle,
    this.onEditTags,
    this.readOnly = false,
  });

  final ExerciseItem exercise;
  final bool selected;
  final VoidCallback? onToggle;
  final VoidCallback? onEditTags;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final tags = exercise.tags.map((tag) => '#${tag.name}').join(' · ');
    return FyCard(
      onTap: readOnly ? null : onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!readOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    selected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: AppColors.primary,
                  ),
                ),
              Expanded(
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (exercise.isCatalog)
                Text(
                  'База',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(tags, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (onEditTags != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onEditTags,
                child: const Text('Теги'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactTagRow extends StatelessWidget {
  const _CompactTagRow({required this.state, required this.cubit});

  final PlansLibraryState state;
  final PlansLibraryCubit cubit;

  @override
  Widget build(BuildContext context) {
    final usage = tagUsageCounts(
      mode: state.mode,
      plans: state.plans,
      exercises: state.exercises,
    );
    final visible = compactLibraryTags(
      all: state.tags,
      selectedIds: state.selectedTagIds,
      usage: usage,
    );
    final showMore = showLibraryTagsMore(state.tags);
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + (showMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (showMore && index == visible.length) {
            return FyChip(
              key: const Key('library-tags-more'),
              label: 'Ещё',
              selected: false,
              outlined: true,
              showCheckmark: false,
              compact: true,
              onSelected: (_) async {
                final next = await showTagSearchSheet(
                  context,
                  tags: state.tags,
                  selectedIds: state.selectedTagIds,
                );
                if (next == null || !context.mounted) return;
                cubit.replaceSelectedTags(next);
              },
            );
          }
          final tag = visible[index];
          final selected = state.selectedTagIds.contains(tag.id);
          return FyChip(
            key: Key('library-tag-${tag.id}'),
            label: '#${tag.name}',
            selected: selected,
            outlined: !selected,
            showCheckmark: false,
            compact: true,
            onSelected: (_) => cubit.toggleTag(tag.id),
          );
        },
      ),
    );
  }
}
