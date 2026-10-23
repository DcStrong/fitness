import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/plans_format.dart';
import '../../data/plans_models.dart';
import '../../data/plans_repository.dart';
import '../widgets/assign_plan_sheet.dart';
import '../../../../core/widgets/fy_button.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_chip.dart';
import '../widgets/plans_header.dart';

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
    final theme = Theme.of(context);
    final canAssign =
        plan != null &&
        plan.isTemplate &&
        context.read<AuthCubit>().state.user?.id == plan.ownerCoachId;
    final canClone = plan != null && plan.isCatalog;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PlansHeader(title: 'Шаблон'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : plan == null
                  ? const Center(child: Text('План не найден'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        Text(plan.title, style: theme.textTheme.headlineSmall),
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
                            for (final tag in plan.tags)
                              FyChip(
                                label: '#${tag.name}',
                                selected: false,
                                outlined: true,
                                compact: true,
                                showCheckmark: false,
                              ),
                          ],
                        ),
                        if (plan.ownerCoachEmail != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Тренер: ${plan.ownerCoachEmail}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (plan.exercises.isNotEmpty) ...[
                          Text('Упражнения', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          FyCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                for (final (i, exercise)
                                    in plan.exercises.indexed) ...[
                                  if (i > 0) const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.exerciseName,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        Text(
                                          formatPlanExerciseRow(exercise),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else
                          FyCard(
                            child: Text(
                              plan.displayNotes.isEmpty
                                  ? 'Без содержания'
                                  : plan.displayNotes,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                      ],
                    ),
            ),
            if (canClone)
              _ActionBar(
                child: FyButton.primary(
                  label: _cloning ? 'Добавление…' : 'Добавить к себе',
                  onPressed: _cloning ? null : _clone,
                ),
              )
            else if (canAssign)
              _ActionBar(
                child: FyButton.primary(
                  key: const Key('assign-plan-button'),
                  label: 'Назначить',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () async {
                    final assigned = await showAssignPlanSheet(
                      context,
                      plan: plan,
                    );
                    if (!assigned || !context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Назначено')));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The one filled action of the screen, pinned above the safe area.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: child,
      ),
    );
  }
}
