import 'package:fitness_app/features/plans/data/plans_models.dart';
import 'package:fitness_app/features/plans/presentation/library_tag_rank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TagItem tag(String id, String name) =>
      TagItem(id: id, name: name, creatorId: 'c1');

  test('до пяти тегов все остаются в ряду', () {
    final all = [
      tag('1', 'А'),
      tag('2', 'Б'),
      tag('3', 'В'),
      tag('4', 'Г'),
      tag('5', 'Д'),
    ];
    expect(compactLibraryTags(all: all, selectedIds: {}, usage: {}), all);
    expect(showLibraryTagsMore(all), isFalse);
  });

  test('больше пяти — топ по частоте и Ещё', () {
    final all = [for (var i = 1; i <= 6; i++) tag('$i', 'T$i')];
    final compact = compactLibraryTags(
      all: all,
      selectedIds: {},
      usage: {'6': 9, '1': 3},
    );
    expect(compact.map((item) => item.id), ['6', '1', '2', '3']);
    expect(showLibraryTagsMore(all), isTrue);
  });

  test('выбранный тег не из топа остаётся в ряду', () {
    final all = [for (var i = 1; i <= 6; i++) tag('$i', 'T$i')];
    final compact = compactLibraryTags(
      all: all,
      selectedIds: {'5'},
      usage: {'1': 5, '2': 4, '3': 3, '4': 2},
    );
    expect(compact.map((item) => item.id).contains('5'), isTrue);
  });
}
