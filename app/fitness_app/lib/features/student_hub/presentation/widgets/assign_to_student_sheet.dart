import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../../core/widgets/fy_button.dart';
import '../../../plans/data/plans_models.dart';
import '../../../plans/data/plans_repository.dart';

Future<bool> showAssignToStudentSheet(
  BuildContext context, {
  required String studentId,
}) async {
  final assigned = await showFyBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AssignToStudentSheet(studentId: studentId),
  );
  return assigned == true;
}

class _AssignToStudentSheet extends StatefulWidget {
  const _AssignToStudentSheet({required this.studentId});

  final String studentId;

  @override
  State<_AssignToStudentSheet> createState() => _AssignToStudentSheetState();
}

class _AssignToStudentSheetState extends State<_AssignToStudentSheet> {
  List<TrainingPlanItem> _plans = const [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final plans = await context.read<PlansRepository>().listOwnPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans.where((plan) => plan.kind == 'template').toList();
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

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await context.read<PlansRepository>().assignPlansBatch(
        studentId: widget.studentId,
        planIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: _loading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Назначить тренировку',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) Text(_error!),
                  if (_plans.isEmpty)
                    const Text('Нет своих шаблонов')
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final plan in _plans)
                            CheckboxListTile(
                              key: Key('hub-assign-${plan.id}'),
                              value: _selected.contains(plan.id),
                              title: Text(plan.title),
                              contentPadding: EdgeInsets.zero,
                              onChanged: _submitting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selected.add(plan.id);
                                        } else {
                                          _selected.remove(plan.id);
                                        }
                                      });
                                    },
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  FyButton.primary(
                    key: const Key('hub-assign-confirm'),
                    label: 'Назначить',
                    isLoading: _submitting,
                    onPressed: _selected.isEmpty || _submitting
                        ? null
                        : _submit,
                  ),
                ],
              ),
      ),
    );
  }
}
