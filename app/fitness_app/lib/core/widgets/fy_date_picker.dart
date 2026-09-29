import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'fy_button.dart';

/// Shows a branded single-date calendar in a bottom sheet.
///
/// Returns the selected day (date-only, local midnight) or `null` if cancelled.
Future<DateTime?> showFyDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? title,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final first = DateTime(firstDate.year, firstDate.month, firstDate.day);
  final last = DateTime(lastDate.year, lastDate.month, lastDate.day);

  var initial = initialDate == null
      ? today
      : DateTime(initialDate.year, initialDate.month, initialDate.day);
  if (initial.isBefore(first)) initial = first;
  if (initial.isAfter(last)) initial = last;

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _FyDatePickerSheet(
      title: title ?? 'Выберите дату',
      firstDate: first,
      lastDate: last,
      initialDate: initial,
    ),
  );
}

class _FyDatePickerSheet extends StatefulWidget {
  const _FyDatePickerSheet({
    required this.title,
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
  });

  final String title;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialDate;

  @override
  State<_FyDatePickerSheet> createState() => _FyDatePickerSheetState();
}

class _FyDatePickerSheetState extends State<_FyDatePickerSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            CalendarDatePicker2(
              config: CalendarDatePicker2Config(
                calendarType: CalendarDatePicker2Type.single,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                currentDate: DateTime.now(),
                firstDayOfWeek: 1,
                selectedDayHighlightColor: AppColors.primary,
                selectedDayTextStyle: const TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                dayTextStyle: const TextStyle(color: AppColors.textPrimary),
                disabledDayTextStyle: const TextStyle(
                  color: AppColors.textMuted,
                ),
                weekdayLabelTextStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                controlsTextStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                dayBorderRadius: BorderRadius.circular(12),
                centerAlignModePicker: true,
              ),
              value: [_selected],
              onValueChanged: (dates) {
                final next = dates.whereType<DateTime>().firstOrNull;
                if (next == null) return;
                setState(() {
                  _selected = DateTime(next.year, next.month, next.day);
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FyButton.secondary(
                    label: 'Отмена',
                    size: FyButtonSize.medium,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FyButton.primary(
                    label: 'Выбрать',
                    size: FyButtonSize.medium,
                    onPressed: () => Navigator.pop(context, _selected),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
