import 'package:fitness_app/features/social/presentation/social_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats hidden and visible ratings', () {
    expect(ratingLabel(null, null), 'Рейтинг скрыт');
    expect(ratingLabel(4.75, 21), '4.8 · 21 отзыв');
    expect(ratingLabel(5, 12), '5.0 · 12 отзывов');
  });

  test('localizes training modes', () {
    expect(trainingModeLabel('online'), 'Онлайн');
    expect(trainingModeLabel('offline'), 'Очно');
  });
}
