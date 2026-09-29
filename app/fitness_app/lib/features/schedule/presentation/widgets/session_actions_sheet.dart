import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../../domain/calendar_events.dart';
import '../schedule_format.dart';

enum SessionSheetAction { completed, cancelled, noShow, history }

class SessionSheetResult {
  const SessionSheetResult(this.action, {this.packageExhausted = false});

  final SessionSheetAction action;
  final bool packageExhausted;
}

/// Manage a booked calendar session: status actions + history.
class SessionActionsSheet extends StatelessWidget {
  const SessionActionsSheet({
    required this.event,
    required this.permissions,
    required this.repository,
    super.key,
  });

  final CalendarEvent event;
  final List<String> permissions;
  final ScheduleRepository repository;

  static Future<SessionSheetResult?> show(
    BuildContext context, {
    required CalendarEvent event,
  }) {
    final permissions =
        context.read<AuthCubit>().state.user?.permissions ?? const <String>[];
    final repository = context.read<ScheduleRepository>();
    return showFyBottomSheet<SessionSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SessionActionsSheet(
        event: event,
        permissions: permissions,
        repository: repository,
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<TrainingSession> Function() action,
    SessionSheetAction result,
  ) async {
    try {
      final session = await action();
      if (!context.mounted) return;
      Navigator.pop(
        context,
        SessionSheetResult(result, packageExhausted: session.packageExhausted),
      );
    } on ApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final booked =
        (event.sessionStatus == 'booked' || event.sessionStatus == null) &&
        !event.isTerminal;
    final sessionId = event.sessionId;

    final canComplete = booked && permissions.contains('sessions:complete');
    final canNoShow = booked && permissions.contains('sessions:mark_no_show');
    final canCancel = booked && permissions.contains('sessions:cancel');
    final canHistory = permissions.contains('sessions:read_history');

    final timeLabel =
        '${formatTime(event.startsAt)}–${formatTime(event.endsAt)}';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  'Тренировка',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  '${event.title}\n$timeLabel · ${event.modeLabel}'
                  '${event.isTerminal ? ' · ${event.secondaryLabel}' : ''}',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              if (sessionId != null && canComplete)
                ListTile(
                  key: const Key('session-action-complete'),
                  leading: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Проведена'),
                  onTap: () => _run(
                    context,
                    () => repository.completeSession(sessionId),
                    SessionSheetAction.completed,
                  ),
                ),
              if (sessionId != null && canCancel)
                ListTile(
                  key: const Key('session-action-cancel'),
                  leading: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Отменить'),
                  onTap: () => _run(
                    context,
                    () => repository.cancelSession(sessionId),
                    SessionSheetAction.cancelled,
                  ),
                ),
              if (sessionId != null && canNoShow)
                ListTile(
                  key: const Key('session-action-no-show'),
                  leading: const Icon(
                    Icons.person_off_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Неявка'),
                  onTap: () => _run(
                    context,
                    () => repository.markNoShow(sessionId, charge: false),
                    SessionSheetAction.noShow,
                  ),
                ),
              if (sessionId != null && canHistory)
                ListTile(
                  key: const Key('session-action-history'),
                  leading: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('История'),
                  onTap: () => Navigator.pop(
                    context,
                    const SessionSheetResult(SessionSheetAction.history),
                  ),
                ),
              if (!canComplete && !canCancel && !canNoShow && !canHistory)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Нет доступных действий для этой тренировки.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showPackageExhaustedSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Пакет исчерпан — продлите абонемент'),
      action: SnackBarAction(
        label: 'Продлить',
        onPressed: () => context.push('/session-packages'),
      ),
    ),
  );
}
