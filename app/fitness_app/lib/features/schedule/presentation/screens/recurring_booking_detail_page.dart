import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_button.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_secondary_button.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../../session_packages/data/session_packages_repository.dart';
import '../../data/recurring_booking_models.dart';
import '../../data/schedule_repository.dart';
import '../cubit/recurring_booking_cubit.dart';
import '../schedule_calendar_sync.dart';
import '../schedule_format.dart';
import '../widgets/weekday_multi_picker.dart';
import '../../../../core/widgets/fy_top_bar.dart';

/// Route `extra` when opening recurring detail (e.g. after create).
class RecurringBookingDetailArgs {
  const RecurringBookingDetailArgs({
    this.initialSync,
    this.fromCalendar = false,
  });

  final RecurringSyncSummary? initialSync;
  final bool fromCalendar;
}

class RecurringBookingDetailPage extends StatelessWidget {
  const RecurringBookingDetailPage({required this.id, this.args, super.key});

  final String id;
  final RecurringBookingDetailArgs? args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecurringBookingCubit(
        scheduleRepository: context.read<ScheduleRepository>(),
        invitationsRepository: context.read<InvitationsRepository>(),
      )..loadDetail(id, initialSync: args?.initialSync),
      child: _RecurringBookingDetailView(
        id: id,
        fromCalendar: args?.fromCalendar ?? false,
      ),
    );
  }
}

class _RecurringBookingDetailView extends StatelessWidget {
  const _RecurringBookingDetailView({
    required this.id,
    required this.fromCalendar,
  });

  final String id;
  final bool fromCalendar;

  void _done(BuildContext context) {
    if (fromCalendar) {
      context.go('/schedule');
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/schedule/recurring');
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить серию?'),
        content: const Text(
          'Будущие забронированные тренировки этой серии будут отменены, '
          'а время снова станет свободным.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отменить серию'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await context.read<RecurringBookingCubit>().cancel(id);
    if (!context.mounted || !success) return;
    context.read<ScheduleCalendarSync>().notifyChanged();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Серия отменена')));
    context.go('/schedule/recurring');
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить серию навсегда?'),
        content: const Text(
          'Серия исчезнет из архива. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await context.read<RecurringBookingCubit>().deleteCancelled(
      id,
    );
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Серия удалена')));
    context.go('/schedule/recurring?tab=archive');
  }

  Future<void> _restore(BuildContext context) async {
    final cubit = context.read<RecurringBookingCubit>();
    final result = await cubit.restore(id);
    if (!context.mounted) return;
    if (result == null) {
      final conflictId = cubit.state.conflictExistingId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cubit.state.errorMessage ?? 'Не удалось восстановить'),
        ),
      );
      if (conflictId != null) {
        context.push('/schedule/recurring/$conflictId');
      }
      return;
    }
    context.read<ScheduleCalendarSync>().notifyChanged();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Серия восстановлена')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FyTopBar(title: 'Регулярные тренировки'),
      body: BlocBuilder<RecurringBookingCubit, RecurringBookingState>(
        builder: (context, state) {
          final booking = state.selected;
          if (state.status == RecurringBookingStatus.loading &&
              booking == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (booking == null) {
            return Center(
              child: Text(state.errorMessage ?? 'Серия не найдена'),
            );
          }
          final sync = state.lastSync;
          final busy =
              state.status == RecurringBookingStatus.syncing ||
              state.status == RecurringBookingStatus.saving;
          final nextLabel = formatRelativeCalendarDateString(
            booking.nextOccurrenceLocalDate,
          );
          final createdLabel = formatRelativeCalendarDateString(
            booking.createdAt,
          );
          final cancelledLabel = formatRelativeCalendarDateString(
            booking.cancelledAt,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.studentTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (booking.studentEmail != null &&
                        booking.studentEmail!.trim().isNotEmpty &&
                        booking.studentDisplayName != null &&
                        booking.studentDisplayName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        booking.studentEmail!,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                    _PackageRemainingHint(studentId: booking.studentId),
                    const SizedBox(height: 12),
                    Text(
                      formatWeekdays(booking.weekdays),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatStartMinute(booking.startMinute)} · ${recurringModeLabel(booking.mode)}',
                    ),
                    if (booking.isActive && nextLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ближайшее: $nextLabel · ${formatStartMinute(booking.startMinute)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (createdLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Создана: $createdLabel',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                    if (!booking.isActive && cancelledLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Отменена: $cancelledLabel',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      booking.isActive ? 'Активна' : 'Отменена',
                      style: TextStyle(
                        color: booking.isActive
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (booking.isActive) ...[
                const FyInfoBanner(
                  message:
                      'Серия уже создана и активна. «Обновить горизонт» '
                      'досоздаёт занятия на горизонт доступности или после '
                      'изменений расписания.',
                ),
                const SizedBox(height: 12),
              ] else ...[
                const FyInfoBanner(
                  message:
                      'Серия отменена. Можно восстановить — занятия снова '
                      'появятся на горизонте. Или удалите запись из архива.',
                ),
                const SizedBox(height: 12),
              ],
              if (sync != null) ...[
                FyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Результат бронирования',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Забронировано: ${sync.booked}'),
                      Text('Создано слотов: ${sync.slotsCreated}'),
                      Text('Уже было: ${sync.skippedExisting}'),
                      Text('Конфликтов: ${sync.conflicts.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (sync.conflicts.isNotEmpty) ...[
                  Text(
                    'Конфликты',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final conflict in sync.conflicts) ...[
                    FyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conflict.localDate,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(recurringConflictReasonLabel(conflict.reason)),
                          if (booking.isActive) ...[
                            const SizedBox(height: 8),
                            FySecondaryButton(
                              key: Key('recurring-skip-${conflict.localDate}'),
                              label: 'Пропустить дату',
                              size: FyButtonSize.medium,
                              fullWidth: true,
                              onPressed: busy
                                  ? null
                                  : () => context
                                        .read<RecurringBookingCubit>()
                                        .resolveSkip(
                                          id: id,
                                          localDate: conflict.localDate,
                                        ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
              const SizedBox(height: 8),
              if (booking.isActive) ...[
                FySecondaryButton(
                  key: const Key('recurring-program'),
                  label: 'Программа',
                  onPressed: busy
                      ? null
                      : () => context.push('/schedule/recurring/$id/program'),
                ),
                const SizedBox(height: 12),
                FyPrimaryButton(
                  key: const Key('recurring-done'),
                  label: 'Готово',
                  onPressed: busy ? null : () => _done(context),
                ),
                const SizedBox(height: 12),
                FySecondaryButton(
                  key: const Key('recurring-sync'),
                  label: 'Обновить горизонт',
                  isLoading: state.status == RecurringBookingStatus.syncing,
                  onPressed: busy
                      ? null
                      : () async {
                          await context.read<RecurringBookingCubit>().sync(id);
                          if (!context.mounted) return;
                          context.read<ScheduleCalendarSync>().notifyChanged();
                        },
                ),
                const SizedBox(height: 12),
                FySecondaryButton(
                  key: const Key('recurring-cancel'),
                  label: 'Отменить серию',
                  onPressed: busy ? null : () => _confirmCancel(context),
                ),
              ] else ...[
                FyPrimaryButton(
                  key: const Key('recurring-restore'),
                  label: 'Восстановить',
                  isLoading: state.status == RecurringBookingStatus.saving,
                  onPressed: busy ? null : () => _restore(context),
                ),
                const SizedBox(height: 12),
                FySecondaryButton(
                  key: const Key('recurring-done'),
                  label: 'Готово',
                  onPressed: busy ? null : () => _done(context),
                ),
                const SizedBox(height: 12),
                FySecondaryButton(
                  key: const Key('recurring-delete'),
                  label: 'Удалить навсегда',
                  onPressed: busy ? null : () => _confirmDelete(context),
                ),
              ],
              if (state.errorMessage != null &&
                  state.conflictExistingId == null) ...[
                const SizedBox(height: 12),
                FyInfoBanner(message: state.errorMessage!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PackageRemainingHint extends StatelessWidget {
  const _PackageRemainingHint({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SessionPackagesRepository>();
    return FutureBuilder(
      future: repo.list(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final packages = snapshot.data!;
        final match = packages.where((p) => p.studentId == studentId).toList();
        if (match.isEmpty) return const SizedBox.shrink();
        final active = match.where((p) => p.isActive).toList();
        final pkg = active.isNotEmpty ? active.first : match.first;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            pkg.remainingLabel,
            key: const Key('recurring-package-remaining'),
            style: TextStyle(
              color: pkg.isExhausted || pkg.isExpired
                  ? Theme.of(context).colorScheme.error
                  : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
