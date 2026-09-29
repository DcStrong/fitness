import '../../../../core/widgets/fy_search_select_field.dart';
import '../../../invitations/data/invitation_models.dart';

/// Searchable options for coach→student pickers (label = display name).
List<FySearchSelectOption<String>> studentSearchSelectOptions(
  Iterable<RelationshipItem> students,
) {
  return [
    for (final student in students)
      FySearchSelectOption(
        value: student.studentId,
        label: student.studentLabel,
        subtitle: _emailSubtitle(student),
        searchText: [
          student.studentDisplayName,
          student.studentEmail,
          student.studentId,
        ].whereType<String>().join(' '),
      ),
  ];
}

String? _emailSubtitle(RelationshipItem student) {
  final name = student.studentDisplayName?.trim();
  final email = student.studentEmail?.trim();
  if (name == null || name.isEmpty) return null;
  if (email == null || email.isEmpty) return null;
  return email;
}
