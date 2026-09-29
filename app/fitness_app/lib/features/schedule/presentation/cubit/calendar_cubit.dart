import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../booking_requests/data/booking_request_models.dart';
import '../../../booking_requests/data/booking_requests_repository.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/availability_models.dart';
import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../../domain/calendar_events.dart';
import '../../domain/calendar_range.dart';
import '../schedule_calendar_sync.dart';
import 'calendar_view_event.dart';

enum CalendarLoadStatus { initial, loading, ready, failure }

class CalendarState extends Equatable {
  const CalendarState({
    this.mode = CalendarMode.day,
    required this.anchorDate,
    required this.selectedDate,
    this.events = const [],
    this.availabilityWindows = const [],
    this.slots = const [],
    this.status = CalendarLoadStatus.initial,
    this.isRefreshing = false,
    this.errorMessage,
    this.requestsDegraded = false,
    this.requestsWarning,
    this.pendingRequestCount = 0,
  });

  factory CalendarState.initial({DateTime? now}) {
    final today = calendarDateOnly(now ?? DateTime.now());
    return CalendarState(anchorDate: today, selectedDate: today);
  }

  final CalendarMode mode;
  final DateTime anchorDate;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final List<AvailabilityWindow> availabilityWindows;
  final List<ScheduleSlot> slots;
  final CalendarLoadStatus status;
  final bool isRefreshing;
  final String? errorMessage;
  final bool requestsDegraded;
  final String? requestsWarning;
  final int pendingRequestCount;

  CalendarRange get visibleRange => rangeForMode(mode, anchorDate);

  List<CalendarEvent> get selectedDayEvents =>
      eventsOnLocalDay(events, selectedDate);

  CalendarState copyWith({
    CalendarMode? mode,
    DateTime? anchorDate,
    DateTime? selectedDate,
    List<CalendarEvent>? events,
    List<AvailabilityWindow>? availabilityWindows,
    List<ScheduleSlot>? slots,
    CalendarLoadStatus? status,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    bool? requestsDegraded,
    String? requestsWarning,
    bool clearRequestsWarning = false,
    int? pendingRequestCount,
  }) {
    return CalendarState(
      mode: mode ?? this.mode,
      anchorDate: anchorDate ?? this.anchorDate,
      selectedDate: selectedDate ?? this.selectedDate,
      events: events ?? this.events,
      availabilityWindows: availabilityWindows ?? this.availabilityWindows,
      slots: slots ?? this.slots,
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      requestsDegraded: requestsDegraded ?? this.requestsDegraded,
      requestsWarning: clearRequestsWarning
          ? null
          : (requestsWarning ?? this.requestsWarning),
      pendingRequestCount: pendingRequestCount ?? this.pendingRequestCount,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    anchorDate,
    selectedDate,
    events,
    availabilityWindows,
    slots,
    status,
    isRefreshing,
    errorMessage,
    requestsDegraded,
    requestsWarning,
    pendingRequestCount,
  ];
}

class CalendarBloc extends Bloc<CalendarViewEvent, CalendarState> {
  CalendarBloc({
    required ScheduleRepository scheduleRepository,
    required BookingRequestsRepository bookingRequestsRepository,
    ScheduleCalendarSync? calendarSync,
    DateTime? now,
  }) : _scheduleRepository = scheduleRepository,
       _bookingRequestsRepository = bookingRequestsRepository,
       _calendarSync = calendarSync,
       super(CalendarState.initial(now: now)) {
    on<CalendarViewStarted>(_onStarted);
    on<CalendarViewRefreshed>(_onRefreshed);
    on<CalendarViewModeSelected>(_onModeSelected);
    on<CalendarViewPreviousPressed>(_onPrevious);
    on<CalendarViewNextPressed>(_onNext);
    on<CalendarViewTodayPressed>(_onToday);
    on<CalendarViewDateSelected>(_onDateSelected);
    _calendarSync?.addListener(_onCalendarSync);
  }

  final ScheduleRepository _scheduleRepository;
  final BookingRequestsRepository _bookingRequestsRepository;
  final ScheduleCalendarSync? _calendarSync;

  void _onCalendarSync() {
    if (!isClosed) {
      add(const CalendarViewRefreshed());
    }
  }

  @override
  Future<void> close() {
    _calendarSync?.removeListener(_onCalendarSync);
    return super.close();
  }

  Future<void> _onStarted(
    CalendarViewStarted event,
    Emitter<CalendarState> emit,
  ) => _load(emit, refresh: false);

  Future<void> _onRefreshed(
    CalendarViewRefreshed event,
    Emitter<CalendarState> emit,
  ) => _load(emit, refresh: true);

  Future<void> _onModeSelected(
    CalendarViewModeSelected event,
    Emitter<CalendarState> emit,
  ) async {
    if (state.mode == event.mode) return;
    emit(state.copyWith(mode: event.mode, clearError: true));
    await _load(emit, refresh: false);
  }

  Future<void> _onPrevious(
    CalendarViewPreviousPressed event,
    Emitter<CalendarState> emit,
  ) async {
    final nextAnchor = shiftAnchor(state.mode, state.anchorDate, -1);
    emit(
      state.copyWith(
        anchorDate: nextAnchor,
        selectedDate: _clampSelection(nextAnchor, state.selectedDate),
        clearError: true,
      ),
    );
    await _load(emit, refresh: false);
  }

  Future<void> _onNext(
    CalendarViewNextPressed event,
    Emitter<CalendarState> emit,
  ) async {
    final nextAnchor = shiftAnchor(state.mode, state.anchorDate, 1);
    emit(
      state.copyWith(
        anchorDate: nextAnchor,
        selectedDate: _clampSelection(nextAnchor, state.selectedDate),
        clearError: true,
      ),
    );
    await _load(emit, refresh: false);
  }

  Future<void> _onToday(
    CalendarViewTodayPressed event,
    Emitter<CalendarState> emit,
  ) async {
    final today = calendarDateOnly(event.now ?? DateTime.now());
    emit(
      state.copyWith(anchorDate: today, selectedDate: today, clearError: true),
    );
    await _load(emit, refresh: false);
  }

  Future<void> _onDateSelected(
    CalendarViewDateSelected event,
    Emitter<CalendarState> emit,
  ) async {
    final day = calendarDateOnly(event.date);
    final dayChanged = !isSameCalendarDay(day, state.selectedDate);
    final needsReload = switch (state.mode) {
      CalendarMode.day => !isSameCalendarDay(day, state.anchorDate),
      CalendarMode.week => false,
      CalendarMode.month =>
        day.year != state.anchorDate.year ||
            day.month != state.anchorDate.month,
    };
    if (!dayChanged && !needsReload) return;
    emit(
      state.copyWith(
        selectedDate: day,
        anchorDate: state.mode == CalendarMode.day || needsReload
            ? day
            : state.anchorDate,
        clearError: true,
      ),
    );
    if (needsReload) {
      await _load(emit, refresh: false);
    }
  }

  Future<void> _load(
    Emitter<CalendarState> emit, {
    required bool refresh,
  }) async {
    final hadContent =
        state.events.isNotEmpty || state.status == CalendarLoadStatus.ready;
    emit(
      state.copyWith(
        status: hadContent ? state.status : CalendarLoadStatus.loading,
        isRefreshing: refresh || hadContent,
        clearError: true,
        clearRequestsWarning: true,
        requestsDegraded: false,
      ),
    );

    final range = state.visibleRange;
    try {
      final sessionsFuture = _scheduleRepository.listSessions(
        from: range.start,
        to: range.end,
      );
      final slotsFuture = _scheduleRepository.listOwnSlots(
        from: range.start,
        to: range.end,
      );
      final requestsFuture = _loadPendingRequests(range);
      final pendingCountFuture = _loadPendingCount();
      final templateFuture = _loadAvailabilityWindows();

      final sessions = await sessionsFuture;
      final slots = await slotsFuture;
      final requestsResult = await requestsFuture;
      final pendingCount = await pendingCountFuture;
      final windows = await templateFuture;

      final events = mapCalendarEvents(
        sessions: sessions,
        slots: slots,
        requests: requestsResult.requests,
        range: range,
      );

      emit(
        state.copyWith(
          events: events,
          slots: slots,
          availabilityWindows: windows,
          status: CalendarLoadStatus.ready,
          isRefreshing: false,
          clearError: true,
          requestsDegraded: requestsResult.failed,
          requestsWarning: requestsResult.failed
              ? 'Заявки могут отображаться неполностью'
              : null,
          clearRequestsWarning: !requestsResult.failed,
          pendingRequestCount: pendingCount ?? state.pendingRequestCount,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: hadContent
              ? CalendarLoadStatus.ready
              : CalendarLoadStatus.failure,
          isRefreshing: false,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<int?> _loadPendingCount() async {
    try {
      return await _bookingRequestsRepository.pendingCount();
    } catch (_) {
      return null;
    }
  }

  Future<List<AvailabilityWindow>> _loadAvailabilityWindows() async {
    try {
      final template = await _scheduleRepository.getAvailabilityTemplate();
      return template.windows;
    } catch (_) {
      return state.availabilityWindows;
    }
  }

  Future<_RequestsLoadResult> _loadPendingRequests(CalendarRange range) async {
    try {
      final page = await _bookingRequestsRepository.inbox(
        page: 1,
        limit: 50,
        status: BookingRequestStatus.pending,
      );
      final filtered = page.items.where((request) {
        final start = request.requestedSlot.startsAt.toLocal();
        final end = request.requestedSlot.endsAt.toLocal();
        return start.isBefore(range.end) && end.isAfter(range.start);
      }).toList();
      return _RequestsLoadResult(requests: filtered, failed: false);
    } catch (_) {
      return const _RequestsLoadResult(requests: [], failed: true);
    }
  }

  DateTime _clampSelection(DateTime anchor, DateTime selected) {
    final range = rangeForMode(state.mode, anchor);
    final day = calendarDateOnly(selected);
    if (!day.isBefore(range.start) && day.isBefore(range.end)) return day;
    return calendarDateOnly(anchor);
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return 'Не удалось загрузить календарь';
  }
}

class _RequestsLoadResult {
  const _RequestsLoadResult({required this.requests, required this.failed});

  final List<BookingRequest> requests;
  final bool failed;
}
