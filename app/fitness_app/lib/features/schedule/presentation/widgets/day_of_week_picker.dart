import 'package:flutter/material.dart';

import '../../../../core/widgets/fy_chip.dart';

const _weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Monday-first day-of-week chip picker (values 1..7).
class DayOfWeekPicker extends StatelessWidget {
  const DayOfWeekPicker({
    required this.selectedDayOfWeek,
    required this.onSelected,
    super.key,
  });

  final int selectedDayOfWeek;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var day = 1; day <= 7; day++)
          FyChip(
            key: Key('availability-dow-$day'),
            label: _weekdayLabels[day - 1],
            selected: selectedDayOfWeek == day,
            showCheckmark: false,
            onSelected: (_) => onSelected(day),
          ),
      ],
    );
  }
}
