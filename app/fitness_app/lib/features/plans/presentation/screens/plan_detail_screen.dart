import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/plans_format.dart';
import '../../data/plans_models.dart';
import '../../data/plans_repository.dart';
import '../widgets/assign_plan_sheet.dart';
import '../../../../core/widgets/fy_top_bar.dart';

class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  TrainingPlanItem? _plan;
  bool _loading = true;
  bool _cloning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await context.read<PlansRepository>().getPlan(widget.planId);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _clone() async {
    setState(() => _cloning = true);
    try {
      await context.read<PlansRepository>().clonePlan(widget.planId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Добавлено в «Мои»')));
      context.go('/plans');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _cloning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      appBar: FyTopBar(
        title: 'План',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : plan == null
          ? const Center(child: Text('План не найден'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  plan.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(planGoalLabel(plan.goal)),
                      backgroundColor: AppColors.mintSoft,
                    ),
                    ...plan.tags.map(
                      (tag) => Chip(label: Text('#${tag.name}')),
                    ),
                  ],
                ),
                if (plan.ownerCoachEmail != null) ...[
                  const SizedBox(height: 8),
                  Text('Тренер: ${plan.ownerCoachEmail}'),
                ],
                const SizedBox(height: 16),
                if (plan.exercises.isNotEmpty)
                  ...plan.exercises.map(
                    (exercise) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(exercise.exerciseName),
                      subtitle: Text(formatPlanExerciseRow(exercise)),
                    ),
                  )
                else
                  Text(
                    plan.displayNotes.isEmpty
                        ? 'Без содержания'
                        : plan.displayNotes,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                if (plan.isCatalog) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _cloning ? null : _clone,
                    child: Text(_cloning ? 'Добавление…' : 'Добавить к себе'),
                  ),
                ],
                if (plan.isTemplate &&
                    context.read<AuthCubit>().state.user?.id ==
                        plan.ownerCoachId) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('assign-plan-button'),
                    onPressed: () async {
                      final assigned = await showAssignPlanSheet(
                        context,
                        plan: plan,
                      );
                      if (!assigned || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Назначено')),
                      );
                    },
                    child: const Text('Назначить'),
                  ),
                ],
              ],
            ),
    );
  }
}
