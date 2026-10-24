import 'package:flutter/material.dart';

/// Специализации тренера для ученика: чипы переносятся на новые строки,
/// текст тега не обрезается.
class SpecialtyChips extends StatelessWidget {
  const SpecialtyChips({
    required this.specialties,
    this.alignment = WrapAlignment.start,
    super.key,
  });

  final List<String> specialties;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    alignment: alignment,
    children: [
      for (final item in specialties)
        Chip(
          label: Text(item, softWrap: true),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
    ],
  );
}
