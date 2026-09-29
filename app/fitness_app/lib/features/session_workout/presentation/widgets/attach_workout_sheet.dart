import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../../core/widgets/fy_secondary_button.dart';
import '../../../plans/data/plans_format.dart';
import '../../../plans/data/plans_models.dart';
import '../cubit/session_workout_cubit.dart';

Future<void> showAttachWorkoutSheet(
  BuildContext context, {
  bool append = false,
}) {
  final cubit = context.read<SessionWorkoutCubit>();
  return showFyBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => BlocProvider.value(
      value: cubit,
      child: AttachWorkoutSheet(append: append),
    ),
  );
}

class AttachWorkoutSheet extends StatefulWidget {
  const AttachWorkoutSheet({this.append = false, super.key});

  final bool append;

  @override
  State<AttachWorkoutSheet> createState() => _AttachWorkoutSheetState();
}

class _AttachWorkoutSheetState extends State<AttachWorkoutSheet> {
  final _query = TextEditingController();
  List<TrainingPlanItem> _copies = const [];
  List<TrainingPlanItem> _templates = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cubit = context.read<SessionWorkoutCubit>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final copies = await cubit.loadAssignedCopies();
      final templates = await cubit.loadTemplates();
      if (!mounted) return;
      setState(() {
        _copies = copies;
        _templates = templates;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  bool _matches(TrainingPlanItem plan) {
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return plan.title.toLowerCase().contains(query);
  }

  Future<void> _pickCopy(TrainingPlanItem plan) async {
    final cubit = context.read<SessionWorkoutCubit>();
    final attached =
        cubit.state.session?.workouts
            .map((item) => item.studentPlanId)
            .toSet() ??
        {};
    Navigator.pop(context);
    if (widget.append) {
      await cubit.addCopy(plan.id);
      return;
    }
    if (plan.id == cubit.state.session?.studentPlanId) return;
    if (attached.contains(plan.id) && attached.length == 1) return;
    await cubit.attachCopy(plan.id);
  }

  Future<void> _pickTemplate(TrainingPlanItem plan) async {
    final cubit = context.read<SessionWorkoutCubit>();
    Navigator.pop(context);
    await cubit.attachTemplate(plan.id, append: widget.append);
  }

  Future<void> _detach() async {
    final cubit = context.read<SessionWorkoutCubit>();
    Navigator.pop(context);
    await cubit.detachPlan();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SessionWorkoutCubit>();
    final currentId = cubit.state.session?.studentPlanId;
    final copies = _copies.where(_matches).toList();
    final templates = _templates.where(_matches).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _loading
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? Text(_error!)
            : SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.append
                          ? 'Добавить тренировку'
                          : currentId == null
                          ? 'Выбрать тренировку'
                          : 'Сменить тренировку',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _query,
                      decoration: const InputDecoration(
                        hintText: 'Поиск',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          if (copies.isNotEmpty) ...[
                            Text(
                              'Назначенные',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            for (final plan in copies)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(plan.title),
                                subtitle: Text(planGoalLabel(plan.goal)),
                                trailing: plan.id == currentId
                                    ? const Icon(Icons.check)
                                    : null,
                                onTap: () => _pickCopy(plan),
                              ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            'Из моих шаблонов',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          if (templates.isEmpty && copies.isEmpty)
                            const Text('Ничего не найдено')
                          else if (templates.isEmpty && _query.text.isEmpty)
                            const Text('Нет шаблонов — создайте в «Тренировки»')
                          else
                            for (final plan in templates)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(plan.title),
                                subtitle: const Text('Назначить и привязать'),
                                onTap: () => _pickTemplate(plan),
                              ),
                        ],
                      ),
                    ),
                    if (currentId != null && !widget.append) ...[
                      const SizedBox(height: 12),
                      FySecondaryButton(
                        key: const Key('session-detach-plan'),
                        label: 'Убрать программу',
                        onPressed: _detach,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
