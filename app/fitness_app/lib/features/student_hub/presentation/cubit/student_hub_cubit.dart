import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../../plans/data/plans_models.dart';
import '../../../plans/data/plans_repository.dart';
import '../../../schedule/data/recurring_booking_models.dart';
import '../../../schedule/data/schedule_models.dart';
import '../../../schedule/data/schedule_repository.dart';
import '../../../workout_program/data/workout_program_models.dart';
import '../../../session_packages/data/session_package_models.dart';
import '../../../session_packages/data/session_packages_repository.dart';
import '../../data/progress_models.dart';
import '../../data/progress_repository.dart';
import 'student_hub_state.dart';

SessionPackage? pickStudentPackage(List<SessionPackage> all, String studentId) {
  final mine = all.where((item) => item.studentId == studentId);
  return mine.where((item) => item.isActive).firstOrNull ?? mine.firstOrNull;
}

class StudentHubCubit extends Cubit<StudentHubState> {
  StudentHubCubit({
    required this.studentId,
    required this.viewerId,
    required this.isTrainer,
    required ScheduleRepository schedule,
    required PlansRepository plans,
    required SessionPackagesRepository packages,
    required ProgressRepository progress,
    required InvitationsRepository invitations,
    String? initialDisplayName,
  }) : _schedule = schedule,
       _plans = plans,
       _packages = packages,
       _progress = progress,
       _invitations = invitations,
       super(StudentHubState(studentDisplayName: initialDisplayName));

  final String studentId;
  final String viewerId;
  final bool isTrainer;
  final ScheduleRepository _schedule;
  final PlansRepository _plans;
  final SessionPackagesRepository _packages;
  final ProgressRepository _progress;
  final InvitationsRepository _invitations;

  bool get isSelf => viewerId == studentId;

  Future<void> load() async {
    emit(state.copyWith(status: StudentHubStatus.loading, errorMessage: null));
    try {
      final now = DateTime.now();
      final sessionsFuture = _schedule.listSessions(
        status: 'booked',
        from: now,
        studentId: isTrainer ? studentId : null,
      );
      final assignedFuture = _plans.listAssignedPlans(
        studentId: isTrainer ? studentId : null,
      );
      final packageFuture = _loadPackage();
      final exercisesFuture = _progress.listExercises(studentId: studentId);
      final sessions = await sessionsFuture;
      final assigned = await assignedFuture;
      final package = await packageFuture;
      final exercises = await exercisesFuture;
      final selected = exercises.isNotEmpty
          ? exercises.first.exerciseId
          : _firstAssignedExerciseId(assigned);
      ProgressSeries? series;
      if (selected != null) {
        series = await _progress.getSeries(
          studentId: studentId,
          exerciseId: selected,
        );
      }
      String? recurringId;
      var displayName = state.studentDisplayName;
      List<RecurringBooking> bookings = const [];
      if (isTrainer) {
        try {
          bookings = await _schedule.listRecurringBookings();
          recurringId = bookings
              .where((item) => item.studentId == studentId && item.isActive)
              .map((item) => item.id)
              .firstOrNull;
        } catch (_) {}
      }
      displayName = await _resolveDisplayName(
        current: displayName,
        sessions: sessions,
        bookings: bookings,
      );
      var weekSlots = weekSlotsFromSessions(sessions);
      if (weekSlots.isEmpty && recurringId != null) {
        try {
          final program = await _schedule.getWorkoutProgram(recurringId);
          weekSlots = weekSlotsFromProgram(program);
        } catch (_) {}
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          status: StudentHubStatus.ready,
          upcoming: sessions,
          assigned: assigned,
          package: package,
          exercises: exercises,
          selectedExerciseId: selected,
          series: series,
          recurringBookingId: recurringId,
          weekSlots: weekSlots,
          studentDisplayName: displayName,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: StudentHubStatus.failure,
          errorMessage: error is ApiException
              ? error.message
              : error.toString(),
        ),
      );
    }
  }

  Future<void> selectExercise(String exerciseId) async {
    emit(state.copyWith(selectedExerciseId: exerciseId));
    try {
      final series = await _progress.getSeries(
        studentId: studentId,
        exerciseId: exerciseId,
      );
      if (isClosed) return;
      emit(state.copyWith(series: series));
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          errorMessage: error is ApiException
              ? error.message
              : error.toString(),
        ),
      );
    }
  }

  Future<String?> _resolveDisplayName({
    required String? current,
    required List<TrainingSession> sessions,
    required List<RecurringBooking> bookings,
  }) async {
    final fromCurrent = current?.trim();
    if (fromCurrent != null && fromCurrent.isNotEmpty) return fromCurrent;
    for (final session in sessions) {
      final name = session.studentDisplayName?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    for (final booking in bookings) {
      if (booking.studentId != studentId) continue;
      final name = booking.studentDisplayName?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    if (!isTrainer) return current;
    try {
      final rels = await _invitations.listRelationships();
      final match = rels
          .where((item) => item.studentId == studentId)
          .firstOrNull;
      final name = match?.studentDisplayName?.trim();
      if (name != null && name.isNotEmpty) return name;
      final email = match?.studentEmail?.trim();
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {}
    return current;
  }

  Future<SessionPackage?> _loadPackage() async {
    try {
      final packages = await _packages.list();
      return pickStudentPackage(packages, studentId);
    } catch (_) {
      return null;
    }
  }

  String? _firstAssignedExerciseId(List<TrainingPlanItem> assigned) {
    for (final plan in assigned) {
      if (plan.exercises.isNotEmpty) {
        return plan.exercises.first.exerciseId;
      }
    }
    return null;
  }
}

List<WeekProgramSlot> weekSlotsFromSessions(
  List<TrainingSession> sessions, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final start = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: today.weekday - 1));
  final end = start.add(const Duration(days: 7));
  final slots = <WeekProgramSlot>[];
  for (final session in sessions) {
    final local = DateTime.parse(session.startsAt).toLocal();
    if (local.isBefore(start) || !local.isBefore(end)) continue;
    slots.add(
      WeekProgramSlot(
        weekday: local.weekday,
        title: session.workoutTitle ?? 'без программы',
      ),
    );
  }
  return slots;
}

List<WeekProgramSlot> weekSlotsFromProgram(WorkoutProgram? program) {
  if (program == null) return const [];
  return [
    for (final day in program.days)
      if (day.items.isNotEmpty)
        WeekProgramSlot(
          weekday: day.weekday,
          title: day.items
              .map((item) => item.title)
              .where((title) => title.isNotEmpty)
              .join(' · '),
        ),
  ];
}
