import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../data/recurring_booking_models.dart';
import '../../data/schedule_repository.dart';
import '../cubit/recurring_booking_cubit.dart';
import '../schedule_format.dart';
import '../widgets/weekday_multi_picker.dart';
import 'recurring_booking_detail_page.dart';
import '../../../../core/widgets/fy_top_bar.dart';

class RecurringBookingsListPage extends StatelessWidget {
  const RecurringBookingsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecurringBookingCubit(
        scheduleRepository: context.read<ScheduleRepository>(),
        invitationsRepository: context.read<InvitationsRepository>(),
      )..loadList(),
      child: const _RecurringBookingsListView(),
    );
  }
}

class _RecurringBookingsListView extends StatefulWidget {
  const _RecurringBookingsListView();

  @override
  State<_RecurringBookingsListView> createState() =>
      _RecurringBookingsListViewState();
}

class _RecurringBookingsListViewState extends State<_RecurringBookingsListView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  var _archiveBootstrapped = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(_onTab);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_archiveBootstrapped) return;
    _archiveBootstrapped = true;
    final archive =
        GoRouterState.of(context).uri.queryParameters['tab'] == 'archive';
    if (archive) {
      _tabs.index = 1;
      context.read<RecurringBookingCubit>().loadList(status: 'cancelled');
    }
  }

  void _onTab() {
    if (_tabs.indexIsChanging) return;
    final status = _tabs.index == 0 ? 'active' : 'cancelled';
    context.read<RecurringBookingCubit>().loadList(status: status);
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTab)
      ..dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final result = await context.push<CreateRecurringBookingResult>(
      '/schedule/recurring/create',
    );
    if (!mounted) return;
    await context.read<RecurringBookingCubit>().loadList(
      status: _tabs.index == 0 ? 'active' : 'cancelled',
    );
    if (result == null || !mounted) return;
    await context.push<void>(
      '/schedule/recurring/${result.booking.id}',
      extra: RecurringBookingDetailArgs(initialSync: result.sync),
    );
    if (mounted) {
      await context.read<RecurringBookingCubit>().loadList(
        status: _tabs.index == 0 ? 'active' : 'cancelled',
      );
    }
  }

  String? _relative(String? isoOrDate) =>
      formatRelativeCalendarDateString(isoOrDate);

  @override
  Widget build(BuildContext context) {
    final isArchive = _tabs.index == 1;
    return Scaffold(
      appBar: FyTopBar(
        title: 'Регулярные тренировки',
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(key: Key('recurring-tab-active'), text: 'Активные'),
            Tab(key: Key('recurring-tab-archive'), text: 'Архив'),
          ],
        ),
      ),
      floatingActionButton: isArchive
          ? null
          : FloatingActionButton.extended(
              key: const Key('recurring-create-fab'),
              onPressed: _openCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add),
              label: const Text('Новая серия'),
            ),
      body: BlocBuilder<RecurringBookingCubit, RecurringBookingState>(
        builder: (context, state) {
          if (state.status == RecurringBookingStatus.loading &&
              state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == RecurringBookingStatus.failure &&
              state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.errorMessage ?? 'Ошибка загрузки'),
                    const SizedBox(height: 12),
                    FyPrimaryButton(
                      label: 'Повторить',
                      onPressed: () => context
                          .read<RecurringBookingCubit>()
                          .loadList(status: isArchive ? 'cancelled' : 'active'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: FyInfoBanner(
                message: isArchive
                    ? 'Архив пуст. Отменённые серии появятся здесь.'
                    : 'Пока нет регулярных тренировок. Создайте серию для ученика — занятия будут бронироваться на горизонт доступности.',
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<RecurringBookingCubit>().loadList(
              status: isArchive ? 'cancelled' : 'active',
            ),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 16, 16, isArchive ? 24 : 88),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = state.items[index];
                final name = item.studentTitle;
                final showEmail =
                    item.studentDisplayName != null &&
                    item.studentDisplayName!.trim().isNotEmpty &&
                    item.studentEmail != null &&
                    item.studentEmail!.trim().isNotEmpty;
                final patternLine =
                    '${formatWeekdays(item.weekdays)} · '
                    '${formatStartMinute(item.startMinute)} · '
                    '${recurringModeLabel(item.mode)}';
                final metaParts = <String>[];
                if (item.isActive) {
                  final nextLabel = _relative(item.nextOccurrenceLocalDate);
                  if (nextLabel != null) {
                    metaParts.add(
                      'ближайшее $nextLabel · ${formatStartMinute(item.startMinute)}',
                    );
                  }
                  final createdLabel = _relative(item.createdAt);
                  if (createdLabel != null) {
                    metaParts.add('создана $createdLabel');
                  }
                } else {
                  final cancelledLabel = _relative(item.cancelledAt);
                  if (cancelledLabel != null) {
                    metaParts.add('отменена $cancelledLabel');
                  }
                  final createdLabel = _relative(item.createdAt);
                  if (createdLabel != null) {
                    metaParts.add('создана $createdLabel');
                  }
                }
                return FyCard(
                  child: ListTile(
                    key: Key('recurring-item-${item.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          showEmail
                              ? '${item.studentEmail} · $patternLine'
                              : patternLine,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metaParts.isEmpty
                              ? patternLine
                              : metaParts.join(' · '),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                    ),
                    onTap: () async {
                      await context.push<void>(
                        '/schedule/recurring/${item.id}',
                      );
                      if (context.mounted) {
                        await context.read<RecurringBookingCubit>().loadList(
                          status: isArchive ? 'cancelled' : 'active',
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
