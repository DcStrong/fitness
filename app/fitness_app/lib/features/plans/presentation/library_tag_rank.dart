import '../data/plans_models.dart';
import 'cubit/plans_library_state.dart';

const compactTagChipLimit = 5;
const compactTagTopCount = 4;

Map<String, int> tagUsageCounts({
  required PlansLibraryMode mode,
  required List<TrainingPlanItem> plans,
  required List<ExerciseItem> exercises,
}) {
  final counts = <String, int>{};
  if (mode == PlansLibraryMode.exercises) {
    for (final exercise in exercises) {
      for (final tag in exercise.tags) {
        counts[tag.id] = (counts[tag.id] ?? 0) + 1;
      }
    }
  } else {
    for (final plan in plans) {
      for (final tag in plan.tags) {
        counts[tag.id] = (counts[tag.id] ?? 0) + 1;
      }
    }
  }
  return counts;
}

/// When there are more than 5 tags, show 4 ranked chips; «Ещё» is rendered by UI.
List<TagItem> compactLibraryTags({
  required List<TagItem> all,
  required Set<String> selectedIds,
  required Map<String, int> usage,
}) {
  if (all.length <= compactTagChipLimit) return all;
  final ranked = [...all]
    ..sort((a, b) {
      final byUse = (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0);
      if (byUse != 0) return byUse;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final top = ranked.take(compactTagTopCount).toList();
  final extraSelected = selectedIds.where(
    (id) => !top.any((tag) => tag.id == id),
  );
  for (final id in extraSelected) {
    final extra = all.where((tag) => tag.id == id).firstOrNull;
    if (extra == null) continue;
    if (top.isNotEmpty) top.removeLast();
    top.insert(0, extra);
  }
  return top;
}

bool showLibraryTagsMore(List<TagItem> all) => all.length > compactTagChipLimit;
