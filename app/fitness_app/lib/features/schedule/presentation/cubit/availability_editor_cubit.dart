import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/availability_models.dart';
import '../../data/schedule_repository.dart';

enum AvailabilityEditorStatus {
  initial,
  loading,
  ready,
  saving,
  generating,
  failure,
}

class AvailabilityEditorState extends Equatable {
  const AvailabilityEditorState({
    this.status = AvailabilityEditorStatus.initial,
    this.settings = const CoachScheduleSettings(
      coachId: '',
      timezone: 'Europe/Moscow',
      defaultDurationMinutes: 60,
      breakMinutes: 0,
      horizonWeeks: 8,
      defaultMode: 'offline',
    ),
    this.windows = const [],
    this.exceptions = const [],
    this.preview = const [],
    this.selectedDayOfWeek = 1,
    this.seriesId = '',
    this.lastGenerateSummary,
    this.errorMessage,
  });

  final AvailabilityEditorStatus status;
  final CoachScheduleSettings settings;
  final List<AvailabilityWindow> windows;
  final List<AvailabilityExceptionItem> exceptions;
  final List<AvailabilityPreviewSlot> preview;
  final int selectedDayOfWeek;
  final String seriesId;
  final GenerateAvailabilitySummary? lastGenerateSummary;
  final String? errorMessage;

  List<AvailabilityWindow> windowsForSelectedDay() {
    return windows.where((w) => w.dayOfWeek == selectedDayOfWeek).toList()
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  }

  AvailabilityEditorState copyWith({
    AvailabilityEditorStatus? status,
    CoachScheduleSettings? settings,
    List<AvailabilityWindow>? windows,
    List<AvailabilityExceptionItem>? exceptions,
    List<AvailabilityPreviewSlot>? preview,
    int? selectedDayOfWeek,
    String? seriesId,
    GenerateAvailabilitySummary? lastGenerateSummary,
    String? errorMessage,
    bool clearError = false,
    bool clearGenerateSummary = false,
  }) {
    return AvailabilityEditorState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      windows: windows ?? this.windows,
      exceptions: exceptions ?? this.exceptions,
      preview: preview ?? this.preview,
      selectedDayOfWeek: selectedDayOfWeek ?? this.selectedDayOfWeek,
      seriesId: seriesId ?? this.seriesId,
      lastGenerateSummary: clearGenerateSummary
          ? null
          : (lastGenerateSummary ?? this.lastGenerateSummary),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    windows,
    exceptions,
    preview,
    selectedDayOfWeek,
    seriesId,
    lastGenerateSummary,
    errorMessage,
  ];
}

class AvailabilityEditorCubit extends Cubit<AvailabilityEditorState> {
  AvailabilityEditorCubit({required ScheduleRepository scheduleRepository})
    : _repository = scheduleRepository,
      super(const AvailabilityEditorState());

  final ScheduleRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: AvailabilityEditorStatus.loading,
        clearError: true,
      ),
    );
    try {
      final settings = await _repository.getAvailabilitySettings();
      final template = await _repository.getAvailabilityTemplate();
      final exceptions = await _repository.listAvailabilityExceptions();
      final preview = await _loadPreview(settings);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AvailabilityEditorStatus.ready,
          settings: settings,
          windows: template.windows,
          exceptions: exceptions,
          seriesId: template.seriesId,
          preview: preview,
          clearError: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AvailabilityEditorStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  void selectDay(int dayOfWeek) {
    emit(state.copyWith(selectedDayOfWeek: dayOfWeek));
  }

  void updateDuration(int minutes) {
    emit(
      state.copyWith(
        settings: state.settings.copyWith(defaultDurationMinutes: minutes),
      ),
    );
  }

  void updateBreak(int minutes) {
    emit(
      state.copyWith(settings: state.settings.copyWith(breakMinutes: minutes)),
    );
  }

  void updateHorizon(int weeks) {
    emit(
      state.copyWith(settings: state.settings.copyWith(horizonWeeks: weeks)),
    );
  }

  void addWindow({required int startMinute, required int endMinute}) {
    final next = [
      ...state.windows,
      AvailabilityWindow(
        dayOfWeek: state.selectedDayOfWeek,
        startMinute: startMinute,
        endMinute: endMinute,
      ),
    ];
    emit(state.copyWith(windows: next));
  }

  void removeWindow(AvailabilityWindow window) {
    final next = state.windows
        .where(
          (item) =>
              !(item.dayOfWeek == window.dayOfWeek &&
                  item.startMinute == window.startMinute &&
                  item.endMinute == window.endMinute),
        )
        .toList();
    emit(state.copyWith(windows: next));
  }

  /// Copies the selected day's windows onto Monday–Sunday (replaces all days).
  void copySelectedDayToAllDays() {
    final source = state.windowsForSelectedDay();
    final copied = <AvailabilityWindow>[
      for (var day = 1; day <= 7; day++)
        for (final window in source)
          AvailabilityWindow(
            dayOfWeek: day,
            startMinute: window.startMinute,
            endMinute: window.endMinute,
            mode: window.mode,
          ),
    ];
    emit(state.copyWith(windows: copied));
  }

  void addClosedException(String localDate) {
    final next = [
      ...state.exceptions.where((e) => e.localDate != localDate),
      AvailabilityExceptionItem(localDate: localDate, type: 'closed'),
    ]..sort((a, b) => a.localDate.compareTo(b.localDate));
    emit(state.copyWith(exceptions: next));
  }

  void removeException(String localDate) {
    emit(
      state.copyWith(
        exceptions: state.exceptions
            .where((e) => e.localDate != localDate)
            .toList(),
      ),
    );
  }

  Future<void> saveAll() async {
    emit(
      state.copyWith(status: AvailabilityEditorStatus.saving, clearError: true),
    );
    try {
      final settings = await _repository.upsertAvailabilitySettings(
        state.settings,
      );
      final template = await _repository.upsertAvailabilityTemplate(
        state.windows,
      );
      final exceptions = await _repository.replaceAvailabilityExceptions(
        state.exceptions,
      );
      final preview = await _loadPreview(settings);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AvailabilityEditorStatus.ready,
          settings: settings,
          windows: template.windows,
          exceptions: exceptions,
          seriesId: template.seriesId,
          preview: preview,
          clearError: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AvailabilityEditorStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<void> generate() async {
    emit(
      state.copyWith(
        status: AvailabilityEditorStatus.generating,
        clearError: true,
        clearGenerateSummary: true,
      ),
    );
    try {
      await _repository.upsertAvailabilitySettings(state.settings);
      await _repository.upsertAvailabilityTemplate(state.windows);
      await _repository.replaceAvailabilityExceptions(state.exceptions);
      final summary = await _repository.generateAvailability();
      final preview = await _loadPreview(state.settings);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AvailabilityEditorStatus.ready,
          lastGenerateSummary: summary,
          preview: preview,
          clearError: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AvailabilityEditorStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<List<AvailabilityPreviewSlot>> _loadPreview(
    CoachScheduleSettings settings,
  ) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(Duration(days: settings.horizonWeeks * 7));
    try {
      return await _repository.previewAvailability(from: from, to: to);
    } catch (_) {
      return const [];
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}
