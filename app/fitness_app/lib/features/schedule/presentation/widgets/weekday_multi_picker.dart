import 'package:flutter/material.dart';

import '../../../../core/widgets/fy_chip.dart';

const weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Monday-first multi-select weekday chips (values 1..7).
class WeekdayMultiPicker extends StatelessWidget {
  const WeekdayMultiPicker({
    required this.selectedWeekdays,
    required this.onChanged,
    super.key,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var day = 1; day <= 7; day++)
          FyChip(
            key: Key('recurring-dow-$day'),
            label: weekdayLabels[day - 1],
            selected: selectedWeekdays.contains(day),
            onSelected: (selected) {
              final next = Set<int>.from(selectedWeekdays);
              if (selected) {
                next.add(day);
              } else {
                next.remove(day);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

String formatWeekdays(Iterable<int> weekdays) {
  final sorted = weekdays.toList()..sort();
  return sorted.map((d) => weekdayLabels[d - 1]).join(', ');
}

String formatStartMinute(int minute) {
  final hour = minute ~/ 60;
  final min = minute % 60;
  return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

String recurringConflictReasonLabel(String reason) {
  return switch (reason) {
    'missing_slot' => 'Нет слота',
    'held' => 'Слот удерживается',
    'booked_other' => 'Занято другой записью',
    'overlap' => 'Пересечение',
    'mode_mismatch' => 'Другой формат слота',
    _ => reason,
  };
}

String recurringModeLabel(String mode) => mode == 'online' ? 'онлайн' : 'очно';
