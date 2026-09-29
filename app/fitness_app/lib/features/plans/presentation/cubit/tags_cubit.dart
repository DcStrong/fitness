import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/plans_models.dart';
import '../../data/plans_repository.dart';
import 'tags_state.dart';

class TagsCubit extends Cubit<TagsState> {
  TagsCubit({required PlansRepository plans})
    : _plans = plans,
      super(const TagsState());

  final PlansRepository _plans;

  Future<void> load() async {
    emit(state.copyWith(status: TagsStatus.loading, errorMessage: null));
    try {
      final tags = await _plans.listTags();
      if (isClosed) return;
      emit(state.copyWith(status: TagsStatus.ready, tags: tags, summaries: {}));
      await _loadSummaries(tags);
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TagsStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query, errorMessage: null));
  }

  Future<TagItem?> createFromQuery() async {
    final name = state.query.trim();
    if (name.isEmpty) return null;
    emit(state.copyWith(errorMessage: null));
    try {
      final tag = await _plans.createTag(name);
      if (isClosed) return tag;
      emit(
        state.copyWith(
          tags: [tag, ...state.tags.where((item) => item.id != tag.id)],
          query: name,
        ),
      );
      return tag;
    } catch (error) {
      if (isClosed) return null;
      emit(state.copyWith(errorMessage: _message(error)));
      return null;
    }
  }

  Future<void> deleteTag(String id) async {
    try {
      await _plans.deleteTag(id);
      if (isClosed) return;
      final nextSummaries = Map<String, String>.from(state.summaries)
        ..remove(id);
      emit(
        state.copyWith(
          tags: state.tags.where((tag) => tag.id != id).toList(),
          summaries: nextSummaries,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(errorMessage: _message(error)));
    }
  }

  Future<void> _loadSummaries(List<TagItem> tags) async {
    final slice = tags.take(15).toList();
    final entries = await Future.wait(
      slice.map((tag) async {
        try {
          final hub = await _plans.getTagHub(tag.id);
          return MapEntry(tag.id, tagCompositionLabel(hub));
        } catch (_) {
          return MapEntry(tag.id, '');
        }
      }),
    );
    if (isClosed) return;
    final summaries = <String, String>{
      for (final entry in entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
    emit(state.copyWith(summaries: summaries));
  }

  String _message(Object error) {
    return error is ApiException ? error.message : error.toString();
  }
}

String tagCompositionLabel(TagHub hub) {
  final parts = <String>[];
  if (hub.users.isNotEmpty) {
    parts.add(
      '${hub.users.length} ${hub.users.length == 1 ? 'ученик' : 'ученика'}',
    );
  }
  if (hub.plans.isNotEmpty) {
    parts.add(
      '${hub.plans.length} ${hub.plans.length == 1 ? 'тренировка' : 'тренировки'}',
    );
  }
  if (hub.exercises.isNotEmpty) {
    parts.add(
      '${hub.exercises.length} ${hub.exercises.length == 1 ? 'упражнение' : 'упражнения'}',
    );
  }
  return parts.join(' · ');
}
