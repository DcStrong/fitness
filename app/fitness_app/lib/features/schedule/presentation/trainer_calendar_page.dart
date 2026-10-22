import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_observer.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../booking_requests/data/booking_requests_repository.dart';
import '../../booking_requests/presentation/trainer_inbox_page.dart';
import '../data/recurring_booking_models.dart';
import '../data/schedule_repository.dart';
import '../domain/calendar_events.dart';
import '../domain/calendar_range.dart';
import 'cubit/calendar_cubit.dart';
import 'cubit/calendar_view_event.dart';
import 'schedule_calendar_sync.dart';
import 'screens/availability_editor_page.dart';
import 'screens/coach_book_for_student_screen.dart';
import 'screens/recurring_booking_create_page.dart';
import 'screens/recurring_booking_detail_page.dart';
import 'widgets/calendar_day_timeline.dart';
import 'widgets/calendar_day_view.dart';
import 'widgets/calendar_month_view.dart';
import 'widgets/calendar_toolbar.dart';
import 'widgets/calendar_week_view.dart';
import 'widgets/free_time_sheet.dart';
import 'widgets/open_slot_actions_sheet.dart';
import 'widgets/schedule_create_actions_sheet.dart';

class TrainerCalendarPage extends StatelessWidget {
  const TrainerCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CalendarBloc(
        scheduleRepository: context.read<ScheduleRepository>(),
        bookingRequestsRepository: context.read<BookingRequestsRepository>(),
        calendarSync: context.read<ScheduleCalendarSync>(),
      )..add(const CalendarViewStarted()),
      child: const _TrainerCalendarView(),
    );
  }
}

class _TrainerCalendarView extends StatefulWidget {
  const _TrainerCalendarView();

  @override
  State<_TrainerCalendarView> createState() => _TrainerCalendarViewState();
}

enum _ScheduleSection { calendar, requests, availability }

class _TrainerCalendarViewState extends State<_TrainerCalendarView>
    with RouteAware {
  _ScheduleSection _section = _ScheduleSection.calendar;
  int _lastSectionIndex = 0;
  String? _lastMatchedLocation;
  GoRouter? _router;
  VoidCallback? _routerListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _attachRouterListener(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      scheduleRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    final bloc = context.read<CalendarBloc>();
    if (!bloc.isClosed) {
      bloc.add(const CalendarViewRefreshed());
    }
  }

  void _attachRouterListener() {
    if (!mounted) return;
    _router = GoRouter.of(context);
    _lastMatchedLocation = _router!.state.matchedLocation;
    _routerListener = () {
      if (!mounted) return;
      final loc = _router!.state.matchedLocation;
      final previous = _lastMatchedLocation;
      _lastMatchedLocation = loc;
      if (previous != null &&
          previous != '/schedule' &&
          loc == '/schedule' &&
          !context.read<CalendarBloc>().isClosed) {
        context.read<CalendarBloc>().add(const CalendarViewRefreshed());
      }
    };
    _router!.routerDelegate.addListener(_routerListener!);
  }

  void _onSectionChanged(_ScheduleSection section) {
    final index = section.index;
    if (index == 0 && _lastSectionIndex != 0 && mounted) {
      context.read<CalendarBloc>().add(const CalendarViewRefreshed());
    }
    setState(() {
      _lastSectionIndex = _section.index;
      _section = section;
    });
  }

  @override
  void dispose() {
    scheduleRouteObserver.unsubscribe(this);
    if (_router != null && _routerListener != null) {
      _router!.routerDelegate.removeListener(_routerListener!);
    }
    super.dispose();
  }

  Future<int> _defaultDurationMinutes(BuildContext context) async {
    try {
      final settings = await context
          .read<ScheduleRepository>()
          .getAvailabilitySettings();
      return settings.defaultDurationMinutes;
    } catch (_) {
      return 60;
    }
  }

  DateTime _defaultBookStart(CalendarBloc bloc) {
    final selected = bloc.state.selectedDate;
    final now = DateTime.now();
    if (selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day) {
      return DateTime(now.year, now.month, now.day, now.hour + 1);
    }
    return DateTime(selected.year, selected.month, selected.day, 10);
  }

  Future<void> _openFreeTimeSheet(
    BuildContext context, {
    DateTime? prefillHour,
  }) async {
    final bloc = context.read<CalendarBloc>();
    final created = await FreeTimeSheet.show(
      context,
      initialDate: prefillHour ?? bloc.state.selectedDate,
      initialStartTime: prefillHour == null
          ? null
          : TimeOfDay.fromDateTime(prefillHour),
      initialEndTime: prefillHour == null
          ? null
          : TimeOfDay.fromDateTime(prefillHour.add(const Duration(hours: 1))),
    );
    if (created == null || !context.mounted) return;
    bloc.add(CalendarViewDateSelected(created));
    bloc.add(const CalendarViewRefreshed());
  }

  Future<void> _openBookStudent(
    BuildContext context, {
    CoachBookPrefill? prefill,
  }) async {
    final bloc = context.read<CalendarBloc>();
    CoachBookPrefill resolved = prefill ?? const CoachBookPrefill();
    if (!resolved.hasSlot && !resolved.hasTimeRange) {
      final duration = await _defaultDurationMinutes(context);
      if (!context.mounted) return;
      final starts = _defaultBookStart(bloc);
      resolved = CoachBookPrefill(
        startsAt: starts,
        endsAt: starts.add(Duration(minutes: duration)),
        mode: 'offline',
      );
    }
    final booked = await context.push<bool>(
      '/schedule/book-for-student',
      extra: resolved,
    );
    if (!context.mounted) return;
    if (booked == true) {
      bloc.add(const CalendarViewRefreshed());
    }
  }

  Future<void> _openAndRefresh(BuildContext context, String location) async {
    final bloc = context.read<CalendarBloc>();
    await context.push<void>(location);
    if (!context.mounted || bloc.isClosed) return;
    bloc.add(const CalendarViewRefreshed());
  }

  Future<void> _openRecurringCreate(
    BuildContext context, {
    RecurringBookingPrefill? prefill,
  }) async {
    final bloc = context.read<CalendarBloc>();
    final result = await context.push<CreateRecurringBookingResult>(
      '/schedule/recurring/create',
      extra: prefill,
    );
    if (!context.mounted || bloc.isClosed) return;
    bloc.add(const CalendarViewRefreshed());
    if (result == null) return;
    await context.push<void>(
      '/schedule/recurring/${result.booking.id}',
      extra: RecurringBookingDetailArgs(
        initialSync: result.sync,
        fromCalendar: true,
      ),
    );
    if (!context.mounted || bloc.isClosed) return;
    bloc.add(const CalendarViewRefreshed());
  }

  Future<void> _openCreateActions(
    BuildContext context, {
    DateTime? prefillHour,
  }) async {
    final action = await ScheduleCreateActionsSheet.show(context);
    if (action == null || !context.mounted) return;
    switch (action) {
      case ScheduleCreateAction.bookStudent:
        if (prefillHour != null) {
          final duration = await _defaultDurationMinutes(context);
          if (!context.mounted) return;
          await _openBookStudent(
            context,
            prefill: CoachBookPrefill(
              startsAt: prefillHour,
              endsAt: prefillHour.add(Duration(minutes: duration)),
              mode: 'offline',
            ),
          );
        } else {
          await _openBookStudent(context);
        }
      case ScheduleCreateAction.recurring:
        await _openRecurringCreate(
          context,
          prefill: prefillHour == null
              ? null
              : RecurringBookingPrefill.fromLocalDateTime(prefillHour),
        );
      case ScheduleCreateAction.freeTime:
        await _openFreeTimeSheet(context, prefillHour: prefillHour);
    }
  }

  Future<void> _onEventTap(BuildContext context, CalendarEvent event) async {
    final bloc = context.read<CalendarBloc>();
    switch (event.type) {
      case CalendarEventType.request:
        if (event.requestId != null) {
          await _openAndRefresh(
            context,
            '/booking-requests/${event.requestId}',
          );
        }
      case CalendarEventType.availability:
        final action = await OpenSlotActionsSheet.show(context, event: event);
        if (!context.mounted) return;
        switch (action) {
          case OpenSlotAction.bookStudent:
            await _openBookStudent(
              context,
              prefill: CoachBookPrefill(
                slotId: event.slotId,
                startsAt: event.startsAt,
                endsAt: event.endsAt,
                mode: event.mode,
              ),
            );
          case OpenSlotAction.recurring:
            await _openRecurringCreate(
              context,
              prefill: RecurringBookingPrefill.fromLocalDateTime(
                event.startsAt,
                mode: event.mode,
              ),
            );
          case OpenSlotAction.delete:
            bloc.add(const CalendarViewRefreshed());
          case null:
            break;
        }
      case CalendarEventType.session:
        final location = sessionPageLocation(event);
        if (location == null) return;
        await _openAndRefresh(context, location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Расписание',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  _HeaderIconButton(
                    buttonKey: const Key('schedule-recurring-button'),
                    tooltip: 'Регулярные тренировки',
                    icon: Icons.event_repeat_rounded,
                    onPressed: () => context.push('/schedule/recurring'),
                  ),
                  if (_section == _ScheduleSection.calendar) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: const Key('calendar-create-fab'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () => _openCreateActions(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Добавить'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<CalendarBloc, CalendarState>(
              buildWhen: (previous, current) =>
                  previous.pendingRequestCount != current.pendingRequestCount,
              builder: (context, state) {
                return _SectionTabs(
                  value: _section,
                  pendingCount: state.pendingRequestCount,
                  onChanged: _onSectionChanged,
                );
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _section.index,
                children: [
                  _CalendarTab(
                    onEventTap: (event) => _onEventTap(context, event),
                    onEmptyHourTap: (hour) =>
                        _openCreateActions(context, prefillHour: hour),
                  ),
                  const TrainerInboxPage(),
                  const AvailabilityEditorPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          key: buttonKey,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Underlined section tabs: Календарь · Заявки (count) · Доступность.
class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.value,
    required this.pendingCount,
    required this.onChanged,
  });

  final _ScheduleSection value;
  final int pendingCount;
  final ValueChanged<_ScheduleSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tab(_ScheduleSection section, String label, Key key, {int? count}) {
      final selected = section == value;
      return InkWell(
        key: key,
        onTap: selected ? null : () => onChanged(section),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  key: const Key('schedule-requests-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            tab(
              _ScheduleSection.calendar,
              'Календарь',
              const Key('schedule-tab-calendar'),
            ),
            tab(
              _ScheduleSection.requests,
              'Заявки',
              const Key('schedule-tab-requests'),
              count: pendingCount,
            ),
            tab(
              _ScheduleSection.availability,
              'Доступность',
              const Key('schedule-tab-availability'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab({required this.onEventTap, required this.onEmptyHourTap});

  final void Function(CalendarEvent event) onEventTap;
  final void Function(DateTime localHourStart) onEmptyHourTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state.status == CalendarLoadStatus.loading &&
            state.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == CalendarLoadStatus.failure &&
            state.events.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
            children: [
              FyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FyInfoBanner(
                      message:
                          state.errorMessage ??
                          'Не удалось загрузить календарь',
                      icon: Icons.sync_problem_rounded,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.read<CalendarBloc>().add(
                        const CalendarViewStarted(),
                      ),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: CalendarToolbar(
                  mode: state.mode,
                  anchorDate: state.anchorDate,
                  onModeChanged: (mode) => context.read<CalendarBloc>().add(
                    CalendarViewModeSelected(mode),
                  ),
                  onPrevious: () => context.read<CalendarBloc>().add(
                    const CalendarViewPreviousPressed(),
                  ),
                  onNext: () => context.read<CalendarBloc>().add(
                    const CalendarViewNextPressed(),
                  ),
                  onToday: () => context.read<CalendarBloc>().add(
                    const CalendarViewTodayPressed(),
                  ),
                ),
              ),
            ),
            if (state.isRefreshing) const LinearProgressIndicator(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<CalendarBloc>().add(
                    const CalendarViewRefreshed(),
                  );
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    if (state.errorMessage != null) ...[
                      FyInfoBanner(
                        message: state.errorMessage!,
                        icon: Icons.sync_problem_rounded,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (state.requestsDegraded &&
                        state.requestsWarning != null) ...[
                      FyInfoBanner(
                        message: state.requestsWarning!,
                        icon: Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _ModeBody(
                      state: state,
                      onEventTap: onEventTap,
                      onEmptyHourTap: onEmptyHourTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModeBody extends StatelessWidget {
  const _ModeBody({
    required this.state,
    required this.onEventTap,
    required this.onEmptyHourTap,
  });

  final CalendarState state;
  final void Function(CalendarEvent event) onEventTap;
  final void Function(DateTime localHourStart) onEmptyHourTap;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CalendarBloc>();

    return switch (state.mode) {
      CalendarMode.day => CalendarDayView(
        selectedDate: state.selectedDate,
        events: state.selectedDayEvents,
        workingHours: workingHoursForDay(
          day: state.selectedDate,
          windows: state.availabilityWindows,
          slots: state.slots,
        ),
        onSelectDate: (date) => bloc.add(CalendarViewDateSelected(date)),
        onEventTap: onEventTap,
        onEmptyHourTap: onEmptyHourTap,
      ),
      CalendarMode.week => CalendarWeekView(
        anchorDate: state.anchorDate,
        selectedDate: state.selectedDate,
        events: state.events,
        onSelectDate: (date) => bloc.add(CalendarViewDateSelected(date)),
        onEventTap: onEventTap,
      ),
      CalendarMode.month => CalendarMonthView(
        anchorDate: state.anchorDate,
        selectedDate: state.selectedDate,
        events: state.events,
        onSelectDate: (date) => bloc.add(CalendarViewDateSelected(date)),
        onEventTap: onEventTap,
      ),
    };
  }
}
