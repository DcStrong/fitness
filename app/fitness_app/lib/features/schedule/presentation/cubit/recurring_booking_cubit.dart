import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../data/recurring_booking_models.dart';
import '../../data/schedule_repository.dart';

enum RecurringBookingStatus { loading, ready, saving, syncing, failure }

class RecurringBookingState extends Equatable {
  const RecurringBookingState({
    this.status = RecurringBookingStatus.loading,
    this.items = const [],
    this.selected,
    this.lastSync,
    this.students = const [],
    this.errorMessage,
    this.conflictExistingId,
  });

  final RecurringBookingStatus status;
  final List<RecurringBooking> items;
  final RecurringBooking? selected;
  final RecurringSyncSummary? lastSync;
  final List<RelationshipItem> students;
  final String? errorMessage;
  final String? conflictExistingId;

  RecurringBookingState copyWith({
    RecurringBookingStatus? status,
    List<RecurringBooking>? items,
    RecurringBooking? selected,
    RecurringSyncSummary? lastSync,
    List<RelationshipItem>? students,
    String? errorMessage,
    String? conflictExistingId,
    bool clearSelected = false,
    bool clearError = false,
    bool clearSync = false,
    bool clearConflict = false,
  }) {
    return RecurringBookingState(
      status: status ?? this.status,
      items: items ?? this.items,
      selected: clearSelected ? null : (selected ?? this.selected),
      lastSync: clearSync ? null : (lastSync ?? this.lastSync),
      students: students ?? this.students,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      conflictExistingId: clearConflict
          ? null
          : (conflictExistingId ?? this.conflictExistingId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    selected,
    lastSync,
    students,
    errorMessage,
    conflictExistingId,
  ];
}

class RecurringBookingCubit extends Cubit<RecurringBookingState> {
  RecurringBookingCubit({
    required ScheduleRepository scheduleRepository,
    required InvitationsRepository invitationsRepository,
  }) : _schedule = scheduleRepository,
       _invitations = invitationsRepository,
       super(const RecurringBookingState());

  final ScheduleRepository _schedule;
  final InvitationsRepository _invitations;

  Future<void> loadList({String status = 'active'}) async {
    emit(
      state.copyWith(status: RecurringBookingStatus.loading, clearError: true),
    );
    try {
      final items = await _schedule.listRecurringBookings(status: status);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          items: items,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<void> loadCreateForm() async {
    emit(
      state.copyWith(status: RecurringBookingStatus.loading, clearError: true),
    );
    try {
      final rels = await _invitations.listRelationships();
      final students = rels.where((r) => r.roleForViewer == 'coach').toList();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          students: students,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<void> loadDetail(
    String id, {
    RecurringSyncSummary? initialSync,
  }) async {
    emit(
      state.copyWith(
        status: RecurringBookingStatus.loading,
        clearError: true,
        clearSync: initialSync == null,
        lastSync: initialSync,
      ),
    );
    try {
      final booking = await _schedule.getRecurringBooking(id);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          selected: booking,
          lastSync: initialSync ?? state.lastSync,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<CreateRecurringBookingResult?> create({
    required String studentId,
    required List<int> weekdays,
    required int startMinute,
    required String mode,
    int? horizonWeeksOverride,
  }) async {
    emit(
      state.copyWith(
        status: RecurringBookingStatus.saving,
        clearError: true,
        clearConflict: true,
      ),
    );
    try {
      final result = await _schedule.createRecurringBooking(
        studentId: studentId,
        weekdays: weekdays,
        startMinute: startMinute,
        mode: mode,
        horizonWeeksOverride: horizonWeeksOverride,
      );
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          selected: result.booking,
          lastSync: result.sync,
          items: [result.booking, ...state.items],
          clearError: true,
          clearConflict: true,
        ),
      );
      return result;
    } on ApiException catch (error) {
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
          conflictExistingId: error.existingId,
          clearConflict: error.existingId == null,
        ),
      );
      return null;
    }
  }

  Future<void> sync(String id) async {
    emit(
      state.copyWith(status: RecurringBookingStatus.syncing, clearError: true),
    );
    try {
      final summary = await _schedule.syncRecurringBooking(id);
      final booking = await _schedule.getRecurringBooking(id);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          selected: booking,
          lastSync: summary,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<void> resolveSkip({
    required String id,
    required String localDate,
  }) async {
    emit(
      state.copyWith(status: RecurringBookingStatus.syncing, clearError: true),
    );
    try {
      final summary = await _schedule.resolveRecurringOccurrence(
        id: id,
        localDate: localDate,
        type: 'skip',
      );
      final booking = await _schedule.getRecurringBooking(id);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          selected: booking,
          lastSync: summary,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<bool> cancel(String id) async {
    emit(
      state.copyWith(status: RecurringBookingStatus.saving, clearError: true),
    );
    try {
      final booking = await _schedule.cancelRecurringBooking(id);
      if (isClosed) return false;
      final items = state.items
          .map((item) => item.id == id ? booking : item)
          .toList();
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          selected: booking,
          items: items,
          clearError: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
        ),
      );
      return false;
    }
  }

  /// Returns restored result, or null on failure (see [conflictExistingId]).
  Future<CreateRecurringBookingResult?> restore(String id) async {
    emit(
      state.copyWith(
        status: RecurringBookingStatus.saving,
        clearError: true,
        clearConflict: true,
      ),
    );
    try {
      final result = await _schedule.restoreRecurringBooking(id);
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          selected: result.booking,
          lastSync: result.sync,
          items: [
            result.booking,
            ...state.items.where((item) => item.id != id),
          ],
          clearError: true,
          clearConflict: true,
        ),
      );
      return result;
    } on ApiException catch (error) {
      if (isClosed) return null;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
          conflictExistingId: error.existingId,
          clearConflict: error.existingId == null,
        ),
      );
      return null;
    }
  }

  Future<bool> deleteCancelled(String id) async {
    emit(
      state.copyWith(status: RecurringBookingStatus.saving, clearError: true),
    );
    try {
      await _schedule.deleteRecurringBooking(id);
      if (isClosed) return false;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.ready,
          items: state.items.where((item) => item.id != id).toList(),
          clearSelected: true,
          clearError: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          status: RecurringBookingStatus.failure,
          errorMessage: error.message,
        ),
      );
      return false;
    }
  }
}
