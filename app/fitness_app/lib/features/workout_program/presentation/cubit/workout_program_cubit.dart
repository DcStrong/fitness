import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../plans/data/plans_format.dart';
import '../../../plans/data/plans_models.dart';
import '../../../plans/data/plans_repository.dart';
import '../../../schedule/data/schedule_repository.dart';
import '../../data/workout_program_models.dart';
import 'workout_program_state.dart';

class WorkoutProgramCubit extends Cubit<WorkoutProgramState> {
  WorkoutProgramCubit({
    required this.recurringBookingId,
    required ScheduleRepository schedule,
    required PlansRepository plans,
  }) : _schedule = schedule,
       _plans = plans,
       super(const WorkoutProgramState());

  final String recurringBookingId;
  final ScheduleRepository _schedule;
  final PlansRepository _plans;

  Future<void> load() async {
    emit(
      state.copyWith(status: WorkoutProgramStatus.loading, errorMessage: null),
    );
    try {
      final booking = await _schedule.getRecurringBooking(recurringBookingId);
      final program = await _schedule.getWorkoutProgram(recurringBookingId);
      final own = await _plans.listOwnPlans();
      final templates = own.where((item) => item.isTemplate).toList();
      final days = <int, List<ProgramDayDraftItem>>{
        for (final weekday in booking.weekdays)
          weekday: <ProgramDayDraftItem>[],
      };
      if (program != null) {
        for (final day in program.days) {
          days[day.weekday] = [
            for (final item in day.items)
              ProgramDayDraftItem(
                templateId: item.templateId,
                title: item.title,
                studentPlanId: item.studentPlanId,
              ),
          ];
        }
      }
      final plansById = <String, TrainingPlanItem>{
        for (final template in templates) template.id: template,
      };
      await _hydratePlans(plansById, days);
      final rules = _mergeRules(
        days: days,
        plansById: plansById,
        saved: program?.progressionRules ?? const [],
      );
      if (isClosed) return;
      emit(
        WorkoutProgramState(
          status: WorkoutProgramStatus.ready,
          booking: booking,
          horizonWeeks: program?.horizonWeeks ?? 2,
          days: days,
          plansById: plansById,
          templates: templates,
          rules: rules,
          preview: program?.preview ?? const [],
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: WorkoutProgramStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  void setHorizonWeeks(int weeks) {
    final clamped = weeks < 1 ? 1 : (weeks > 8 ? 8 : weeks);
    emit(state.copyWith(horizonWeeks: clamped, validationMessage: null));
  }

  void addTemplate({required int weekday, required TrainingPlanItem template}) {
    final current = [...(state.days[weekday] ?? const <ProgramDayDraftItem>[])];
    current.add(
      ProgramDayDraftItem(templateId: template.id, title: template.title),
    );
    final days = Map<int, List<ProgramDayDraftItem>>.from(state.days)
      ..[weekday] = current;
    final plansById = Map<String, TrainingPlanItem>.from(state.plansById)
      ..[template.id] = template;
    emit(
      state.copyWith(
        days: days,
        plansById: plansById,
        rules: _mergeRules(
          days: days,
          plansById: plansById,
          saved: _rulesAsSaved(state.rules),
        ),
        validationMessage: null,
      ),
    );
  }

  void removeItem({required int weekday, required int index}) {
    final current = [...(state.days[weekday] ?? const <ProgramDayDraftItem>[])];
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    final days = Map<int, List<ProgramDayDraftItem>>.from(state.days)
      ..[weekday] = current;
    emit(
      state.copyWith(
        days: days,
        rules: _mergeRules(
          days: days,
          plansById: state.plansById,
          saved: _rulesAsSaved(state.rules),
        ),
        validationMessage: null,
      ),
    );
  }

  void setRuleDelta(String exerciseId, double deltaKg) {
    emit(
      state.copyWith(
        rules: [
          for (final rule in state.rules)
            if (rule.exerciseId == exerciseId)
              rule.copyWith(deltaKg: deltaKg)
            else
              rule,
        ],
        validationMessage: null,
      ),
    );
  }

  void setRuleStart(String exerciseId, double startWeightKg) {
    emit(
      state.copyWith(
        rules: [
          for (final rule in state.rules)
            if (rule.exerciseId == exerciseId)
              rule.copyWith(startWeightKg: startWeightKg)
            else
              rule,
        ],
        validationMessage: null,
      ),
    );
  }

  Future<void> setCopyLoad({
    required String planId,
    required String exerciseId,
    required double weightKg,
  }) async {
    final previous = state.plansById[planId];
    if (previous == null) return;
    final updated = previous.copyWith(
      exercises: [
        for (final exercise in previous.exercises)
          if (exercise.exerciseId == exerciseId &&
              exercise.exerciseKind == 'weight_reps')
            exercise.copyWith(
              sets: [
                for (final set in exercise.sets)
                  set.copyWith(weightKg: weightKg),
              ],
            )
          else
            exercise,
      ],
    );
    emit(
      state.copyWith(
        plansById: {...state.plansById, planId: updated},
        rules: _mergeRules(
          days: state.days,
          plansById: {...state.plansById, planId: updated},
          saved: _rulesAsSaved(state.rules),
        ),
      ),
    );
    if (previous.isStudentCopy) {
      try {
        await _plans.updatePlanLoads(
          id: planId,
          items: [(exerciseId: exerciseId, weightKg: weightKg)],
        );
      } catch (error) {
        if (isClosed) return;
        emit(state.copyWith(errorMessage: _message(error)));
      }
    }
  }

  Future<bool> save() async {
    final booking = state.booking;
    if (booking == null) return false;
    final empty = booking.weekdays.where(
      (weekday) => (state.days[weekday] ?? const []).isEmpty,
    );
    if (empty.isNotEmpty) {
      emit(
        state.copyWith(
          validationMessage: 'Добавьте тренировку в каждый день серии',
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        status: WorkoutProgramStatus.saving,
        validationMessage: null,
        errorMessage: null,
      ),
    );
    try {
      final saved = await _schedule.putWorkoutProgram(
        recurringBookingId: recurringBookingId,
        horizonWeeks: state.horizonWeeks,
        days: [
          for (final weekday in booking.weekdays)
            {
              'weekday': weekday,
              'items': [
                for (final item in state.days[weekday] ?? const [])
                  {'templateId': item.templateId},
              ],
            },
        ],
        progressionRules: [
          for (final rule in state.rules)
            {
              'exerciseId': rule.exerciseId,
              if (rule.startWeightKg != null)
                'startWeightKg': rule.startWeightKg,
              'deltaKg': rule.deltaKg,
            },
        ],
      );
      await _applyPendingLoads(saved);
      await load();
      return true;
    } catch (error) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          status: WorkoutProgramStatus.ready,
          errorMessage: _message(error),
        ),
      );
      return false;
    }
  }

  Future<void> _applyPendingLoads(WorkoutProgram saved) async {
    for (final day in saved.days) {
      for (final item in day.items) {
        final cached =
            state.plansById[item.studentPlanId] ??
            state.plansById[item.templateId];
        if (cached == null) continue;
        final loads = [
          for (final exercise in cached.exercises)
            if (exercise.exerciseKind == 'weight_reps')
              (
                exerciseId: exercise.exerciseId,
                weightKg: workingWeightKg(exercise) ?? 0,
              ),
        ].where((row) => row.weightKg > 0).toList();
        if (loads.isEmpty) continue;
        await _plans.updatePlanLoads(id: item.studentPlanId, items: loads);
      }
    }
  }

  Future<void> _hydratePlans(
    Map<String, TrainingPlanItem> plansById,
    Map<int, List<ProgramDayDraftItem>> days,
  ) async {
    final ids = <String>{};
    for (final items in days.values) {
      for (final item in items) {
        ids.add(item.templateId);
        if (item.studentPlanId != null) ids.add(item.studentPlanId!);
      }
    }
    for (final id in ids) {
      if (plansById.containsKey(id)) continue;
      try {
        plansById[id] = await _plans.getPlan(id);
      } catch (_) {}
    }
  }

  List<ProgramRuleDraft> _mergeRules({
    required Map<int, List<ProgramDayDraftItem>> days,
    required Map<String, TrainingPlanItem> plansById,
    required List<WorkoutProgressionRule> saved,
  }) {
    final savedById = {for (final rule in saved) rule.exerciseId: rule};
    final seen = <String>{};
    final result = <ProgramRuleDraft>[];
    for (final items in days.values) {
      for (final item in items) {
        final plan =
            plansById[item.studentPlanId] ?? plansById[item.templateId];
        if (plan == null) continue;
        for (final exercise in plan.exercises) {
          if (exercise.exerciseKind != 'weight_reps') continue;
          if (!seen.add(exercise.exerciseId)) continue;
          final existing = savedById[exercise.exerciseId];
          result.add(
            ProgramRuleDraft(
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.exerciseName,
              startWeightKg:
                  existing?.startWeightKg ?? workingWeightKg(exercise),
              deltaKg: existing?.deltaKg ?? 0,
            ),
          );
        }
      }
    }
    return result;
  }

  List<WorkoutProgressionRule> _rulesAsSaved(List<ProgramRuleDraft> rules) {
    return [
      for (final rule in rules)
        WorkoutProgressionRule(
          exerciseId: rule.exerciseId,
          startWeightKg: rule.startWeightKg,
          deltaKg: rule.deltaKg,
          incrementKg: 2.5,
          holdOnMiss: true,
        ),
    ];
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}
