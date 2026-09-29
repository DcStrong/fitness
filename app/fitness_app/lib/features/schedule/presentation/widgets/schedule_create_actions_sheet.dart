import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_bottom_sheet.dart';

enum ScheduleCreateAction { bookStudent, recurring, freeTime }

/// FAB / empty-hour entry: three create actions with clear student vs time copy.
class ScheduleCreateActionsSheet extends StatelessWidget {
  const ScheduleCreateActionsSheet({super.key});

  static Future<ScheduleCreateAction?> show(BuildContext context) {
    return showFyBottomSheet<ScheduleCreateAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ScheduleCreateActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Что добавить?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ListTile(
            key: const Key('create-action-book-student'),
            leading: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
            ),
            title: const Text('Записать ученика'),
            subtitle: Text(
              'Разова на дату и время',
              style: TextStyle(color: AppColors.textMuted),
            ),
            onTap: () =>
                Navigator.pop(context, ScheduleCreateAction.bookStudent),
          ),
          ListTile(
            key: const Key('create-action-recurring'),
            leading: const Icon(Icons.repeat_rounded, color: AppColors.primary),
            title: const Text('Регулярные тренировки'),
            subtitle: Text(
              'Закрепить ученика за днями недели',
              style: TextStyle(color: AppColors.textMuted),
            ),
            onTap: () => Navigator.pop(context, ScheduleCreateAction.recurring),
          ),
          ListTile(
            key: const Key('create-action-free-time'),
            leading: const Icon(
              Icons.event_available_rounded,
              color: AppColors.primary,
            ),
            title: const Text('Свободное время'),
            subtitle: Text(
              'Открыть окно для заявок учеников',
              style: TextStyle(color: AppColors.textMuted),
            ),
            onTap: () => Navigator.pop(context, ScheduleCreateAction.freeTime),
          ),
        ],
      ),
    );
  }
}
