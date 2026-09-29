import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../data/schedule_repository.dart';
import '../../domain/calendar_events.dart';
import '../schedule_format.dart';

enum OpenSlotAction { bookStudent, recurring, delete }

/// Actions for an open availability card on the trainer calendar.
class OpenSlotActionsSheet extends StatelessWidget {
  const OpenSlotActionsSheet({required this.event, super.key});

  final CalendarEvent event;

  static Future<OpenSlotAction?> show(
    BuildContext context, {
    required CalendarEvent event,
  }) {
    final repository = context.read<ScheduleRepository>();
    return showFyBottomSheet<OpenSlotAction>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RepositoryProvider.value(
        value: repository,
        child: OpenSlotActionsSheet(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final interval =
        '${formatTime(event.startsAt)} – ${formatTime(event.endsAt)}';
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Свободное время',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$interval · ${event.modeLabel}',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          ListTile(
            key: const Key('slot-action-book'),
            leading: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
            ),
            title: const Text('Записать ученика'),
            onTap: () => Navigator.pop(context, OpenSlotAction.bookStudent),
          ),
          ListTile(
            key: const Key('slot-action-recurring'),
            leading: const Icon(Icons.repeat_rounded, color: AppColors.primary),
            title: const Text('Регулярные тренировки'),
            subtitle: Text(
              'Создать серию с этим временем',
              style: TextStyle(color: AppColors.textMuted),
            ),
            onTap: () => Navigator.pop(context, OpenSlotAction.recurring),
          ),
          ListTile(
            key: const Key('slot-action-delete'),
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            title: const Text('Удалить слот'),
            onTap: () async {
              final slotId = event.slotId;
              if (slotId == null) {
                Navigator.pop(context);
                return;
              }
              try {
                await context.read<ScheduleRepository>().deleteSlot(slotId);
                if (!context.mounted) return;
                Navigator.pop(context, OpenSlotAction.delete);
              } on ApiException catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
          ),
        ],
      ),
    );
  }
}
