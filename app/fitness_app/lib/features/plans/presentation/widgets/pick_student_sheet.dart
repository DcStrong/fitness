import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../../invitations/data/invitations_repository.dart';

Future<String?> showPickStudentSheet(BuildContext context) {
  return showFyBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _PickStudentSheet(),
  );
}

class _PickStudentSheet extends StatefulWidget {
  const _PickStudentSheet();

  @override
  State<_PickStudentSheet> createState() => _PickStudentSheetState();
}

class _PickStudentSheetState extends State<_PickStudentSheet> {
  List<RelationshipItem> _students = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rels = await context
          .read<InvitationsRepository>()
          .listRelationships();
      if (!mounted) return;
      setState(() {
        _students = rels
            .where((item) => item.roleForViewer == 'coach')
            .toList();
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
                    'Кому назначить',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) Text(_error!),
                  if (_students.isEmpty)
                    const Text('Нет связанных учеников')
                  else
                    ..._students.map(
                      (student) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(student.studentLabel),
                        onTap: () => Navigator.pop(context, student.studentId),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
