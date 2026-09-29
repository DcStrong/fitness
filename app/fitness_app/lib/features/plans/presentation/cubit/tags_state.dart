import 'package:equatable/equatable.dart';

import '../../data/plans_models.dart';

enum TagsStatus { initial, loading, ready, failure }

class TagsState extends Equatable {
  const TagsState({
    this.status = TagsStatus.initial,
    this.tags = const [],
    this.query = '',
    this.summaries = const {},
    this.errorMessage,
  });

  final TagsStatus status;
  final List<TagItem> tags;
  final String query;
  final Map<String, String> summaries;
  final String? errorMessage;

  List<TagItem> get visible {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return tags;
    return [
      for (final tag in tags)
        if (tag.name.toLowerCase().contains(needle)) tag,
    ];
  }

  bool get canCreate {
    final name = query.trim();
    if (name.isEmpty) return false;
    return !tags.any((tag) => tag.name.toLowerCase() == name.toLowerCase());
  }

  TagsState copyWith({
    TagsStatus? status,
    List<TagItem>? tags,
    String? query,
    Map<String, String>? summaries,
    Object? errorMessage = _unset,
  }) {
    return TagsState(
      status: status ?? this.status,
      tags: tags ?? this.tags,
      query: query ?? this.query,
      summaries: summaries ?? this.summaries,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, tags, query, summaries, errorMessage];
}

const _unset = Object();
