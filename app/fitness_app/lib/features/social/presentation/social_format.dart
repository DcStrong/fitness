String trainingModeLabel(String mode) => switch (mode) {
  'online' => 'Онлайн',
  'offline' => 'Очно',
  _ => mode,
};

String ratingLabel(double? rating, int? reviewCount) {
  if (rating == null || reviewCount == null) return 'Рейтинг скрыт';
  return '${rating.toStringAsFixed(1)} · $reviewCount '
      '${_reviewWord(reviewCount)}';
}

String _reviewWord(int value) {
  final mod100 = value % 100;
  final mod10 = value % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'отзывов';
  if (mod10 == 1) return 'отзыв';
  if (mod10 >= 2 && mod10 <= 4) return 'отзыва';
  return 'отзывов';
}
