import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_chip.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/person_name_email.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../data/plans_models.dart';
import '../cubit/tag_hub_cubit.dart';
import '../cubit/tag_hub_state.dart';
import '../widgets/tag_attach_sheet.dart';
import '../widgets/plans_header.dart';

class TagHubView extends StatelessWidget {
  const TagHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TagHubCubit, TagHubState>(
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
        final title = state.hub == null ? 'Тег' : state.hub!.tag.name;
        return Scaffold(
          floatingActionButton: state.status == TagHubStatus.success
              ? FloatingActionButton.extended(
                  key: const Key('tag-hub-attach'),
                  onPressed: state.busy ? null : () => _attach(context, state),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const StadiumBorder(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Привязать'),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlansHeader(
                  title: title,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/tags');
                    }
                  },
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') _delete(context);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          key: Key('tag-hub-delete'),
                          value: 'delete',
                          child: Text('Удалить тег'),
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: switch (state.status) {
                    TagHubStatus.initial || TagHubStatus.loading =>
                      const Center(child: CircularProgressIndicator()),
                    TagHubStatus.failure => Center(
                      child: Text(state.errorMessage ?? 'Ошибка'),
                    ),
                    TagHubStatus.success => _HubBody(state: state),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<TagHubCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тег?'),
        content: Text(cubit.state.hub?.tag.name ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final deleted = await cubit.deleteTag();
    if (deleted && context.mounted) {
      context.go('/tags');
    }
  }

  Future<void> _attach(BuildContext context, TagHubState state) async {
    final kind = await showModalBottomSheet<TagHubSection>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('tag-attach-students'),
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Ученикам'),
              onTap: () => Navigator.pop(context, TagHubSection.students),
            ),
            ListTile(
              key: const Key('tag-attach-plans'),
              leading: const Icon(Icons.fitness_center_outlined),
              title: const Text('Тренировкам'),
              onTap: () => Navigator.pop(context, TagHubSection.plans),
            ),
            ListTile(
              key: const Key('tag-attach-exercises'),
              leading: const Icon(Icons.sports_gymnastics_outlined),
              title: const Text('Упражнениям'),
              onTap: () => Navigator.pop(context, TagHubSection.exercises),
            ),
          ],
        ),
      ),
    );
    if (kind == null || !context.mounted) return;
    final cubit = context.read<TagHubCubit>();
    switch (kind) {
      case TagHubSection.students:
        final attached = {
          for (final user in state.hub?.users ?? const <TagAssignee>[])
            user.userId,
        };
        final ids = await showTagAttachSheet(
          context,
          title: 'Ученики',
          attachedIds: attached,
          options: [
            for (final student in state.students)
              TagAttachOption(
                id: student.studentId,
                label: student.studentLabel,
                subtitle: student.studentEmail,
              ),
          ],
        );
        if (ids != null && ids.isNotEmpty) {
          await cubit.assignStudents(ids);
        }
      case TagHubSection.plans:
        final attached = {
          for (final plan in state.hub?.plans ?? const <TagHubPlan>[]) plan.id,
        };
        final ids = await showTagAttachSheet(
          context,
          title: 'Тренировки',
          attachedIds: attached,
          options: [
            for (final plan in state.ownPlans)
              TagAttachOption(id: plan.id, label: plan.title),
          ],
        );
        if (ids != null && ids.isNotEmpty) {
          await cubit.attachPlans(ids);
        }
      case TagHubSection.exercises:
        final attached = {
          for (final exercise
              in state.hub?.exercises ?? const <TagHubExercise>[])
            exercise.id,
        };
        final ids = await showTagAttachSheet(
          context,
          title: 'Упражнения',
          attachedIds: attached,
          options: [
            for (final exercise in state.ownExercises)
              TagAttachOption(
                id: exercise.id,
                label: exercise.name,
                subtitle: exercise.isCatalog ? 'База' : null,
              ),
          ],
        );
        if (ids != null && ids.isNotEmpty) {
          await cubit.attachExercises(ids);
        }
      case TagHubSection.all:
        break;
    }
  }
}

class _HubBody extends StatelessWidget {
  const _HubBody({required this.state});

  final TagHubState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TagHubCubit>();
    final showStudents =
        state.section == TagHubSection.all ||
        state.section == TagHubSection.students;
    final showPlans =
        state.section == TagHubSection.all ||
        state.section == TagHubSection.plans;
    final showExercises =
        state.section == TagHubSection.all ||
        state.section == TagHubSection.exercises;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        TextField(
          key: const Key('tag-hub-search'),
          decoration: const InputDecoration(
            hintText: 'Фильтр: имя ученика, тренировка, упражнение',
            prefixIcon: Icon(Icons.filter_list_rounded),
          ),
          onChanged: cubit.setQuery,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FyChip(
              key: const Key('tag-filter-all'),
              label: 'Все',
              selected: state.section == TagHubSection.all,
              showCheckmark: false,
              compact: true,
              onSelected: (_) => cubit.setSection(TagHubSection.all),
            ),
            FyChip(
              key: const Key('tag-filter-students'),
              label: 'Ученики ${state.hub?.users.length ?? 0}',
              selected: state.section == TagHubSection.students,
              showCheckmark: false,
              compact: true,
              onSelected: (_) => cubit.setSection(TagHubSection.students),
            ),
            FyChip(
              key: const Key('tag-filter-plans'),
              label: 'Тренировки ${state.hub?.plans.length ?? 0}',
              selected: state.section == TagHubSection.plans,
              showCheckmark: false,
              compact: true,
              onSelected: (_) => cubit.setSection(TagHubSection.plans),
            ),
            FyChip(
              key: const Key('tag-filter-exercises'),
              label: 'Упражнения ${state.hub?.exercises.length ?? 0}',
              selected: state.section == TagHubSection.exercises,
              showCheckmark: false,
              compact: true,
              onSelected: (_) => cubit.setSection(TagHubSection.exercises),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (showStudents) ...[
          Text('Ученики', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.visibleUsers.isEmpty)
            const FyCard(
              child: FyInfoBanner(
                message: 'Никто не назначен. Нажмите «Привязать».',
                icon: Icons.person_outline,
              ),
            )
          else
            for (final user in state.visibleUsers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FyCard(
                  key: Key('tag-user-${user.userId}'),
                  onTap: () => context.push(
                    '/students/${user.userId}',
                    extra: _name(state, user),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PersonNameEmail(
                          displayName: _name(state, user),
                          email: user.email,
                          fallback: user.userId,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Снять тег',
                        onPressed: () => cubit.unassignStudent(user.userId),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
        ],
        if (showPlans) ...[
          Text('Тренировки', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.visiblePlans.isEmpty)
            const FyCard(
              child: FyInfoBanner(
                message: 'Нет тренировок с этим тегом.',
                icon: Icons.fitness_center_outlined,
              ),
            )
          else
            for (final plan in state.visiblePlans)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FyCard(
                  key: Key('tag-plan-${plan.id}'),
                  onTap: () => context.push('/plans/${plan.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (plan.kind == 'student_copy')
                        Text(
                          'Копия ученика',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
        ],
        if (showExercises) ...[
          Text('Упражнения', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.visibleExercises.isEmpty)
            FyCard(
              child: FyInfoBanner(
                message: 'Нет упражнений с этим тегом.',
                icon: Icons.sports_gymnastics_outlined,
              ),
            )
          else
            for (final exercise in state.visibleExercises)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FyCard(
                  key: Key('tag-exercise-${exercise.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (exercise.source == 'catalog')
                        Text(
                          'База',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }

  String? _name(TagHubState state, TagAssignee user) {
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName;
    }
    return _matchStudent(state.students, user.userId)?.studentDisplayName;
  }

  RelationshipItem? _matchStudent(
    List<RelationshipItem> students,
    String userId,
  ) {
    for (final student in students) {
      if (student.studentId == userId) return student;
    }
    return null;
  }
}
