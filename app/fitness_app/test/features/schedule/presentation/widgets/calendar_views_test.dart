import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/widgets/fy_card.dart';
import 'package:fitness_app/core/widgets/fy_info_banner.dart';
import 'package:fitness_app/features/schedule/domain/calendar_events.dart';
import 'package:fitness_app/features/schedule/domain/calendar_range.dart';
import 'package:fitness_app/features/schedule/presentation/cubit/calendar_cubit.dart';
import 'package:fitness_app/features/schedule/presentation/cubit/calendar_view_event.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/calendar_day_timeline.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/calendar_day_view.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/calendar_month_view.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/calendar_toolbar.dart';
import 'package:fitness_app/features/schedule/presentation/widgets/calendar_week_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _CalendarBloc extends MockBloc<CalendarViewEvent, CalendarState>
    implements CalendarBloc {}

void main() {
  final anchor = DateTime(2026, 7, 19);
  final otherDay = DateTime(2026, 7, 18);

  setUpAll(() {
    registerFallbackValue(CalendarMode.day);
    registerFallbackValue(DateTime(2026, 7, 19));
    registerFallbackValue(const CalendarViewStarted());
  });

  CalendarState readyState({
    CalendarMode mode = CalendarMode.day,
    DateTime? selectedDate,
    List<CalendarEvent>? events,
    String? errorMessage,
    bool requestsDegraded = false,
    String? requestsWarning,
    DateTime? anchorDate,
    int pendingRequestCount = 0,
  }) {
    return CalendarState(
      mode: mode,
      anchorDate: anchorDate ?? anchor,
      selectedDate: selectedDate ?? anchor,
      events: events ?? const [],
      status: CalendarLoadStatus.ready,
      requestsDegraded: requestsDegraded,
      requestsWarning: requestsWarning,
      errorMessage: errorMessage,
      pendingRequestCount: pendingRequestCount,
    );
  }

  _CalendarBloc mockBloc(CalendarState state) {
    final bloc = _CalendarBloc();
    whenListen(bloc, const Stream<CalendarState>.empty(), initialState: state);
    when(() => bloc.add(any())).thenReturn(null);
    return bloc;
  }

  testWidgets('initial day mode shows strip, title and timeline chrome', (
    tester,
  ) async {
    final bloc = mockBloc(readyState(events: [_sessionEvent(anchor)]));

    await _pumpCalendar(tester, bloc);

    expect(find.byKey(const Key('calendar-mode-day')), findsOneWidget);
    expect(find.byKey(const Key('calendar-day-view')), findsOneWidget);
    expect(find.byKey(const Key('calendar-date-strip')), findsOneWidget);
    expect(find.byKey(const Key('calendar-day-title')), findsOneWidget);
    expect(find.text('Воскресенье, 19 июля'), findsOneWidget);
    expect(find.byKey(const Key('calendar-day-timeline')), findsOneWidget);
    expect(find.byKey(const Key('calendar-prev')), findsOneWidget);
    expect(find.byKey(const Key('calendar-next')), findsOneWidget);
  });

  testWidgets('date strip selection dispatches CalendarViewDateSelected', (
    tester,
  ) async {
    final bloc = mockBloc(readyState());

    await _pumpCalendar(tester, bloc);

    await tester.tap(find.byKey(const Key('calendar-strip-day-2026-07-18')));
    await tester.pump();

    verify(() => bloc.add(CalendarViewDateSelected(otherDay))).called(1);
  });

  testWidgets('mode switches dispatch CalendarViewModeSelected', (
    tester,
  ) async {
    final bloc = mockBloc(readyState());

    await _pumpCalendar(tester, bloc);

    await tester.tap(find.byKey(const Key('calendar-mode-week')));
    await tester.pump();
    verify(
      () => bloc.add(const CalendarViewModeSelected(CalendarMode.week)),
    ).called(1);

    await tester.tap(find.byKey(const Key('calendar-mode-month')));
    await tester.pump();
    verify(
      () => bloc.add(const CalendarViewModeSelected(CalendarMode.month)),
    ).called(1);
  });

  testWidgets('week navigation controls dispatch view events', (tester) async {
    final bloc = mockBloc(
      readyState(mode: CalendarMode.week, anchorDate: DateTime(2026, 6, 1)),
    );

    await _pumpCalendar(tester, bloc);

    await tester.tap(find.byKey(const Key('calendar-prev')));
    await tester.pump();
    verify(() => bloc.add(const CalendarViewPreviousPressed())).called(1);

    await tester.tap(find.byKey(const Key('calendar-next')));
    await tester.pump();
    verify(() => bloc.add(const CalendarViewNextPressed())).called(1);

    await tester.tap(find.byKey(const Key('calendar-today')));
    await tester.pump();
    verify(() => bloc.add(const CalendarViewTodayPressed())).called(1);
  });

  testWidgets('empty selected day keeps strip and hour timeline', (
    tester,
  ) async {
    final bloc = mockBloc(readyState(events: const []));

    await _pumpCalendar(tester, bloc);

    expect(find.byKey(const Key('calendar-day-timeline')), findsOneWidget);
    expect(find.byKey(const Key('calendar-empty-hour-10')), findsOneWidget);
    expect(find.byKey(const Key('calendar-date-strip')), findsOneWidget);
  });

  testWidgets('failure state shows retry banner', (tester) async {
    final bloc = mockBloc(
      CalendarState(
        mode: CalendarMode.day,
        anchorDate: anchor,
        selectedDate: anchor,
        status: CalendarLoadStatus.failure,
        errorMessage: 'Сеть недоступна',
      ),
    );

    await _pumpCalendar(tester, bloc);

    expect(find.text('Сеть недоступна'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pump();

    verify(() => bloc.add(const CalendarViewStarted())).called(1);
  });

  testWidgets('degraded requests warning is shown', (tester) async {
    final bloc = mockBloc(
      readyState(
        requestsDegraded: true,
        requestsWarning: 'Заявки могут отображаться неполностью',
      ),
    );

    await _pumpCalendar(tester, bloc);

    expect(find.text('Заявки могут отображаться неполностью'), findsOneWidget);
  });

  testWidgets('week day tap dispatches date selected and expands agenda', (
    tester,
  ) async {
    final events = [_sessionEvent(anchor), _slotEvent(anchor)];
    final bloc = mockBloc(readyState(mode: CalendarMode.week, events: events));

    await _pumpCalendar(tester, bloc);

    expect(
      find.byKey(const Key('calendar-event-session:s1'), skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('calendar-week-day-2026-07-18')));
    await tester.pump();

    verify(() => bloc.add(CalendarViewDateSelected(otherDay))).called(1);
  });

  testWidgets('month day tap dispatches CalendarViewDateSelected', (
    tester,
  ) async {
    final monthDay = DateTime(2026, 7, 21);
    final bloc = mockBloc(
      readyState(mode: CalendarMode.month, events: [_sessionEvent(monthDay)]),
    );

    await _pumpCalendar(tester, bloc);

    await tester.tap(find.byKey(const Key('calendar-month-day-2026-07-21')));
    await tester.pump();

    verify(() => bloc.add(CalendarViewDateSelected(monthDay))).called(1);
  });

  testWidgets('week view shows mixed event type indicators', (tester) async {
    final day = anchor;
    final events = [
      _sessionEvent(day, id: 's1'),
      _slotEvent(day, id: 'slot1'),
      _requestEvent(day, id: 'req1'),
    ];
    final bloc = mockBloc(readyState(mode: CalendarMode.week, events: events));

    await _pumpCalendar(tester, bloc);

    final weekDay = find.byKey(const Key('calendar-week-day-2026-07-19'));
    expect(weekDay, findsOneWidget);
    expect(
      find.descendant(of: weekDay, matching: find.text('1')),
      findsNWidgets(3),
    );
  });

  testWidgets('month view shows event cards for mixed types', (tester) async {
    final day = anchor;
    final events = [
      _sessionEvent(day, id: 's1'),
      _slotEvent(day, id: 'slot1'),
      _requestEvent(day, id: 'req1'),
    ];
    final bloc = mockBloc(readyState(mode: CalendarMode.month, events: events));

    await _pumpCalendar(tester, bloc);

    expect(
      find.byKey(const Key('calendar-event-session:s1'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('calendar-event-slot:slot1'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('calendar-event-request:req1'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('partial error banner is shown when events exist', (
    tester,
  ) async {
    final bloc = mockBloc(
      readyState(
        events: [_sessionEvent(anchor)],
        errorMessage: 'Не удалось обновить заявки',
      ),
    );

    await _pumpCalendar(tester, bloc);

    expect(find.text('Не удалось обновить заявки'), findsOneWidget);
    expect(find.byKey(const Key('calendar-day-view')), findsOneWidget);
  });

  testWidgets('requests badge appears when pending count > 0', (tester) async {
    final bloc = mockBloc(readyState(pendingRequestCount: 3));

    await _pumpShell(tester, bloc);

    expect(find.byKey(const Key('schedule-requests-badge')), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.byKey(const Key('calendar-create-fab')), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('requests badge hidden when pending count is 0', (tester) async {
    final bloc = mockBloc(readyState());

    await _pumpShell(tester, bloc);

    expect(find.byKey(const Key('schedule-requests-badge')), findsNothing);
  });

  for (final viewport in const [
    (name: 'compact', size: Size(320, 700)),
    (name: 'standard', size: Size(390, 844)),
  ]) {
    for (final mode in CalendarMode.values) {
      testWidgets(
        '${mode.name} mode fits ${viewport.name} ${viewport.size.width.toInt()}x${viewport.size.height.toInt()}',
        (tester) async {
          _setViewport(tester, viewport.size);
          final events = [
            _sessionEvent(anchor, id: 's1'),
            _slotEvent(anchor, id: 'slot1'),
            _requestEvent(anchor, id: 'req1'),
          ];
          final bloc = mockBloc(readyState(mode: mode, events: events));

          await _pumpCalendar(tester, bloc);
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Future<void> _pumpCalendar(WidgetTester tester, CalendarBloc bloc) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: BlocProvider<CalendarBloc>.value(
        value: bloc,
        child: const _CalendarHarness(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpShell(WidgetTester tester, CalendarBloc bloc) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: BlocProvider<CalendarBloc>.value(
        value: bloc,
        child: const _ShellHarness(),
      ),
    ),
  );
  await tester.pump();
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

CalendarEvent _sessionEvent(DateTime day, {String id = 's1'}) {
  return CalendarEvent(
    id: 'session:$id',
    type: CalendarEventType.session,
    startsAt: DateTime(day.year, day.month, day.day, 10),
    endsAt: DateTime(day.year, day.month, day.day, 11),
    title: 'student@example.com',
    secondaryLabel: 'Тренировка',
    mode: 'offline',
    sessionId: id,
  );
}

CalendarEvent _slotEvent(DateTime day, {String id = 'slot1'}) {
  return CalendarEvent(
    id: 'slot:$id',
    type: CalendarEventType.availability,
    startsAt: DateTime(day.year, day.month, day.day, 14),
    endsAt: DateTime(day.year, day.month, day.day, 15),
    title: 'Свободное время',
    secondaryLabel: 'очно',
    mode: 'offline',
    slotId: id,
  );
}

CalendarEvent _requestEvent(DateTime day, {String id = 'req1'}) {
  return CalendarEvent(
    id: 'request:$id',
    type: CalendarEventType.request,
    startsAt: DateTime(day.year, day.month, day.day, 16),
    endsAt: DateTime(day.year, day.month, day.day, 17),
    title: 'Ученик',
    secondaryLabel: 'Ожидает решения',
    mode: 'online',
    requestId: id,
  );
}

class _CalendarHarness extends StatelessWidget {
  const _CalendarHarness();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state.status == CalendarLoadStatus.loading &&
            state.events.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!(state.status == CalendarLoadStatus.failure &&
                  state.events.isEmpty))
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
                      now: DateTime(2026, 7, 19),
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
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
                    children: [
                      if (state.status == CalendarLoadStatus.failure &&
                          state.events.isEmpty)
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
                                onPressed: () => context
                                    .read<CalendarBloc>()
                                    .add(const CalendarViewStarted()),
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      else ...[
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
                        _ModeBody(state: state),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShellHarness extends StatelessWidget {
  const _ShellHarness();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Расписание'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    const Text('Календарь'),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Заявки'),
                        if (state.pendingRequestCount > 0) ...[
                          const SizedBox(width: 6),
                          Badge(
                            key: const Key('schedule-requests-badge'),
                            label: Text('${state.pendingRequestCount}'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 16),
                    const Text('Доступность'),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            key: const Key('calendar-create-fab'),
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ModeBody extends StatelessWidget {
  const _ModeBody({required this.state});

  final CalendarState state;

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
        now: DateTime(2026, 7, 19),
      ),
      CalendarMode.week => CalendarWeekView(
        anchorDate: state.anchorDate,
        selectedDate: state.selectedDate,
        events: state.events,
        onSelectDate: (date) => bloc.add(CalendarViewDateSelected(date)),
      ),
      CalendarMode.month => CalendarMonthView(
        anchorDate: state.anchorDate,
        selectedDate: state.selectedDate,
        events: state.events,
        onSelectDate: (date) => bloc.add(CalendarViewDateSelected(date)),
      ),
    };
  }
}
