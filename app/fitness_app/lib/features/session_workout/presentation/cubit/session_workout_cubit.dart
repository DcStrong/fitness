import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../plans/data/plans_models.dart';
import '../../../plans/data/plans_repository.dart';
import '../../../schedule/data/schedule_repository.dart';
import '../../../session_packages/data/session_packages_repository.dart';
import 'session_workout_state.dart';

class SessionWorkoutCubit extends Cubit<SessionWorkoutState> {
  SessionWorkoutCubit({
    required this.sessionId,
    required this.viewerId,
    required this.permissions,
    required ScheduleRepository schedule,
    required PlansRepository plans,
    required SessionPackagesRepository packages,
  }) : _schedule = schedule,
       _plans = plans,
       _packages = packages,
       super(const SessionWorkoutState());

  final String sessionId;
  final String viewerId;
  final List<String> permissions;
  final ScheduleRepository _schedule;
  final PlansRepository _plans;
  final SessionPackagesRepository _packages;

  bool get isCoach {
    final session = state.session;
    return session != null && session.coachId == viewerId;
  }

  bool get isParticipant {
    final session = state.session;
    if (session == null) return false;
    return session.coachId == viewerId || session.studentId == viewerId;
  }

  bool get isBooked => state.session?.status == 'booked';

  bool get canComplete =>
      isBooked && isCoach && permissions.contains('sessions:complete');

  bool get canNoShow =>
      isBooked && isCoach && permissions.contains('sessions:mark_no_show');

  bool get canCancel =>
      isBooked && isParticipant && permissions.contains('sessions:cancel');

  bool get canHistory =>
      isParticipant && permissions.contains('sessions:read_history');

  bool get canAttach =>
      isCoach && permissions.contains('sessions:book_for_student');

  bool get canEditAttachedPlan =>
      isCoach && isBooked && permissions.contains('plans:update_own');

  bool get canCreateAdHocPlan =>
      isCoach && isBooked && permissions.contains('plans:create');

  Future<void> load() async {
    emit(
      state.copyWith(status: SessionWorkoutStatus.loading, errorMessage: null),
    );
    try {
      final session = await _schedule.getSession(sessionId);
      final remaining = await _loadRemaining(session.studentId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SessionWorkoutStatus.ready,
          session: session,
          remainingSessions: remaining,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SessionWorkoutStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<void> complete({List<Map<String, dynamic>>? logs}) async {
    await _runAction(() => _schedule.completeSession(sessionId, logs: logs));
  }

  Future<void> cancel({String? note}) async {
    await _runAction(() => _schedule.cancelSession(sessionId, note: note));
  }

  Future<void> markNoShow({required bool charge}) async {
    await _runAction(() => _schedule.markNoShow(sessionId, charge: charge));
  }

  Future<void> attachCopy(String studentPlanId) async {
    await _runAction(
      () => _schedule.patchSessionPlan(
        sessionId: sessionId,
        studentPlanId: studentPlanId,
      ),
      info: 'Тренировка привязана',
    );
  }

  Future<void> addCopy(String studentPlanId) async {
    final ids = _currentWorkoutIds();
    if (ids.contains(studentPlanId)) return;
    await _runAction(
      () => _schedule.patchSessionPlan(
        sessionId: sessionId,
        workoutPlanIds: [...ids, studentPlanId],
      ),
      info: 'Тренировка добавлена',
    );
  }

  Future<void> removeWorkout(String studentPlanId) async {
    final ids = _currentWorkoutIds()
        .where((id) => id != studentPlanId)
        .toList();
    await _runAction(
      () =>
          _schedule.patchSessionPlan(sessionId: sessionId, workoutPlanIds: ids),
      info: ids.isEmpty ? 'Программа убрана' : 'Тренировка убрана',
    );
  }

  Future<void> overrideLoads({
    required String studentPlanId,
    required List<({String exerciseId, double weightKg})> items,
  }) async {
    await _runAction(
      () => _schedule.patchSessionPlan(
        sessionId: sessionId,
        workoutLoads: (studentPlanId: studentPlanId, items: items),
      ),
      info: 'Вес обновлён',
    );
  }

  Future<void> detachPlan() async {
    await _runAction(
      () =>
          _schedule.patchSessionPlan(sessionId: sessionId, studentPlanId: null),
      info: 'Программа убрана',
    );
  }

  Future<void> ensureAdHocCopy() async {
    final session = state.session;
    if (session == null) return;
    if (state.plan != null) return;
    emit(
      state.copyWith(status: SessionWorkoutStatus.mutating, errorMessage: null),
    );
    try {
      final name = session.studentDisplayName?.trim();
      final title = (name == null || name.isEmpty)
          ? 'Занятие'
          : 'Занятие · $name';
      final created = await _plans.createPlan(
        title: title,
        assignedStudentId: session.studentId,
      );
      final updated = await _schedule.patchSessionPlan(
        sessionId: sessionId,
        studentPlanId: created.id,
      );
      final remaining = await _loadRemaining(updated.studentId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SessionWorkoutStatus.ready,
          session: updated,
          remainingSessions: remaining,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SessionWorkoutStatus.ready,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<void> attachTemplate(String templateId, {bool append = false}) async {
    final session = state.session;
    if (session == null) return;
    emit(
      state.copyWith(status: SessionWorkoutStatus.mutating, errorMessage: null),
    );
    try {
      final copies = await _plans.assignPlan(
        planId: templateId,
        studentIds: [session.studentId],
      );
      final copy = copies.isNotEmpty ? copies.first : null;
      if (copy == null) {
        throw ApiException('Не удалось назначить шаблон');
      }
      final ids = append ? [..._currentWorkoutIds(), copy.id] : null;
      final updated = await _schedule.patchSessionPlan(
        sessionId: sessionId,
        studentPlanId: append ? null : copy.id,
        workoutPlanIds: ids,
      );
      final remaining = await _loadRemaining(updated.studentId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SessionWorkoutStatus.ready,
          session: updated,
          remainingSessions: remaining,
          infoMessage: append ? 'Тренировка добавлена' : 'Тренировка привязана',
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SessionWorkoutStatus.ready,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<List<TrainingPlanItem>> loadAssignedCopies() {
    final session = state.session;
    if (session == null) {
      return Future.value(const []);
    }
    return _plans.listAssignedPlans(studentId: session.studentId);
  }

  Future<List<TrainingPlanItem>> loadTemplates() {
    return _plans.listOwnPlans();
  }

  Future<void> _runAction(
    Future<dynamic> Function() action, {
    String? info,
  }) async {
    emit(
      state.copyWith(status: SessionWorkoutStatus.mutating, errorMessage: null),
    );
    try {
      await action();
      final session = await _schedule.getSession(sessionId);
      final remaining = await _loadRemaining(session.studentId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SessionWorkoutStatus.ready,
          session: session,
          remainingSessions: remaining,
          infoMessage: info,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SessionWorkoutStatus.ready,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<int?> _loadRemaining(String studentId) async {
    if (!permissions.contains('packages:read_own')) {
      return null;
    }
    try {
      final packages = await _packages.list();
      final active = packages.where(
        (pkg) => pkg.studentId == studentId && pkg.isActive,
      );
      if (active.isEmpty) return null;
      return active.first.remainingSessions;
    } catch (_) {
      return null;
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  List<String> _currentWorkoutIds() {
    final session = state.session;
    if (session == null) return const [];
    if (session.workouts.isNotEmpty) {
      return [for (final item in session.workouts) item.studentPlanId];
    }
    final id = session.studentPlanId;
    return id == null ? const [] : [id];
  }
}
