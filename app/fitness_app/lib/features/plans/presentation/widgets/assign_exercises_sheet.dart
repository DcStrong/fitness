import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../data/plans_models.dart';
import '../../data/plans_repository.dart';

Future<bool> showAssignExercisesSheet(
  BuildContext context, {
  required List<ExerciseItem> exercises,
}) async {
  final assigned = await showFyBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AssignExercisesSheet(exercises: exercises),
  );
  return assigned == true;
}

class AssignExercisesSheet extends StatefulWidget {
  const AssignExercisesSheet({super.key, required this.exercises});

  final List<ExerciseItem> exercises;

  @override
  State<AssignExercisesSheet> createState() => _AssignExercisesSheetState();
}

class _AssignExercisesSheetState extends State<AssignExercisesSheet> {
  List<RelationshipItem> _students = const [];
  List<TagItem> _tags = const [];
  final Set<String> _selectedStudentIds = {};
  final Set<String> _selectedTagIds = {};
  final Set<String> _filterTagIds = {};
  final Map<String, Set<String>> _assigneesByTag = {};
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
      final invitations = context.read<InvitationsRepository>();
      final plans = context.read<PlansRepository>();
      final rels = await invitations.listRelationships();
      final tags = await plans.listTags();
      if (!mounted) return;
      setState(() {
        _students = rels
            .where((item) => item.roleForViewer == 'coach')
            .toList();
        _tags = tags;
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

  List<RelationshipItem> get _visibleStudents {
    if (_filterTagIds.isEmpty) return _students;
    return _students.where((student) {
      return _filterTagIds.every((tagId) {
        final assignees = _assigneesByTag[tagId];
        return assignees != null && assignees.contains(student.studentId);
      });
    }).toList();
  }

  Future<void> _toggleFilter(String tagId) async {
    final next = {..._filterTagIds};
    if (!next.add(tagId)) {
      next.remove(tagId);
      setState(
        () => _filterTagIds
          ..clear()
          ..addAll(next),
      );
      return;
    }
    if (!_assigneesByTag.containsKey(tagId)) {
      final assignees = await context.read<PlansRepository>().listAssignees(
        tagId,
      );
      _assigneesByTag[tagId] = assignees.map((item) => item.userId).toSet();
    }
    if (!mounted) return;
    setState(() {
      _filterTagIds
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _submit() async {
    if (_selectedStudentIds.isEmpty && _selectedTagIds.isEmpty) {
      setState(() => _error = 'Выберите учеников или теги');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<PlansRepository>().assignExercises(
        exerciseIds: widget.exercises.map((item) => item.id).toList(),
        studentIds: _selectedStudentIds.toList(),
        tagIds: _selectedTagIds.toList(),
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
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Назначить ${widget.exercises.length} упражнений',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Найти ученика по тегу',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _tags)
                          FilterChip(
                            label: Text('#${tag.name}'),
                            selected: _filterTagIds.contains(tag.id),
                            onSelected: (_) => _toggleFilter(tag.id),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Ученики',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_visibleStudents.isEmpty)
                    const Text('Нет связанных учеников')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final student in _visibleStudents)
                          FilterChip(
                            label: Text(student.studentLabel),
                            selected: _selectedStudentIds.contains(
                              student.studentId,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedStudentIds.add(student.studentId);
                                } else {
                                  _selectedStudentIds.remove(student.studentId);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Выдать всем с тегом',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_tags.isEmpty)
                    const Text('Нет тегов')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _tags)
                          FilterChip(
                            label: Text('#${tag.name}'),
                            selected: _selectedTagIds.contains(tag.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTagIds.add(tag.id);
                                } else {
                                  _selectedTagIds.remove(tag.id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? 'Назначение…' : 'Назначить'),
                  ),
                ],
              ),
      ),
    );
  }
}
