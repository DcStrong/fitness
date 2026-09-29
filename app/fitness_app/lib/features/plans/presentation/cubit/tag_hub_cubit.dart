import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../data/plans_models.dart';
import '../../data/plans_repository.dart';
import 'tag_hub_state.dart';

class TagHubCubit extends Cubit<TagHubState> {
  TagHubCubit({
    required PlansRepository plans,
    required InvitationsRepository invitations,
    required this.tagId,
  }) : _plans = plans,
       _invitations = invitations,
       super(const TagHubState());

  final PlansRepository _plans;
  final InvitationsRepository _invitations;
  final String tagId;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: TagHubStatus.loading,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      final hubFuture = _plans.getTagHub(tagId);
      final relsFuture = _invitations.listRelationships();
      final plansFuture = _plans.listOwnPlans();
      final exercisesFuture = _plans.listExercises();
      final hub = await hubFuture;
      final rels = await relsFuture;
      final ownPlans = await plansFuture;
      final ownExercises = await exercisesFuture;
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TagHubStatus.success,
          hub: hub,
          students: rels
              .where((item) => item.roleForViewer == 'coach')
              .toList(),
          ownPlans: ownPlans,
          ownExercises: ownExercises,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TagHubStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }

  void setSection(TagHubSection section) {
    emit(state.copyWith(section: section));
  }

  Future<void> assignStudents(Iterable<String> userIds) async {
    await _mutate(() async {
      for (final userId in userIds) {
        await _plans.assignTag(tagId: tagId, userId: userId);
      }
    }, info: 'Тег назначен ученикам');
  }

  Future<void> unassignStudent(String userId) async {
    await _mutate(() async {
      await _plans.unassignTag(tagId: tagId, userId: userId);
    }, info: 'Тег снят с ученика');
  }

  Future<void> attachPlans(Iterable<String> planIds) async {
    await _mutate(() async {
      for (final planId in planIds) {
        final plan = _planById(planId);
        if (plan == null) continue;
        final tagIds = {...plan.tags.map((tag) => tag.id), tagId}.toList();
        await _plans.updatePlan(id: planId, tagIds: tagIds);
      }
    }, info: 'Тег привязан к тренировкам');
  }

  Future<void> attachExercises(Iterable<String> exerciseIds) async {
    await _mutate(() async {
      for (final exerciseId in exerciseIds) {
        final exercise = _exerciseById(exerciseId);
        if (exercise == null) continue;
        final tagIds = {...exercise.tags.map((tag) => tag.id), tagId}.toList();
        await _plans.replaceExerciseTags(
          exerciseId: exerciseId,
          tagIds: tagIds,
        );
      }
    }, info: 'Тег привязан к упражнениям');
  }

  Future<bool> deleteTag() async {
    try {
      await _plans.deleteTag(tagId);
      return true;
    } catch (error) {
      if (isClosed) return false;
      emit(state.copyWith(errorMessage: _message(error)));
      return false;
    }
  }

  Future<void> _mutate(
    Future<void> Function() action, {
    required String info,
  }) async {
    emit(state.copyWith(busy: true, errorMessage: null, infoMessage: null));
    try {
      await action();
      await load();
      if (isClosed) return;
      if (state.status == TagHubStatus.success) {
        emit(state.copyWith(busy: false, infoMessage: info));
      }
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, errorMessage: _message(error)));
    }
  }

  TrainingPlanItem? _planById(String id) {
    for (final plan in state.ownPlans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  ExerciseItem? _exerciseById(String id) {
    for (final exercise in state.ownExercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  String _message(Object error) {
    return error is ApiException ? error.message : error.toString();
  }
}
