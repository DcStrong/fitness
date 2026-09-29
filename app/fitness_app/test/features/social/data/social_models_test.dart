import 'package:fitness_app/features/social/data/social_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses hidden rating fields without inventing values', () {
    final trainer = PublicTrainer.fromJson(const {
      'id': 'trainer-1',
      'displayName': 'Анна',
      'specialties': ['йога'],
      'trainingModes': ['online'],
    });

    expect(trainer.averageRating, isNull);
    expect(trainer.reviewCount, isNull);
    expect(trainer.specialties, ['йога']);
  });

  test('parses owner privacy and nullable dates safely', () {
    final profile = OwnerProfile.fromJson(const {
      'userId': 'user-1',
      'privacy': {
        'isDiscoverable': false,
        'showRating': true,
        'showReviews': false,
        'showReviewerName': true,
      },
      'portfolio': [],
    });

    expect(profile.privacy.isDiscoverable, isFalse);
    expect(profile.privacy.showReviews, isFalse);
    expect(profile.createdAt, isNull);
  });

  test('public review does not require private identifiers', () {
    final review = SessionReview.fromJson(const {
      'rating': 5,
      'reviewer': {'displayName': 'Ученик', 'avatarUrl': null},
      'sessionStartsAt': '2026-07-18T12:00:00.000Z',
    });

    expect(review.id, isNull);
    expect(review.sessionId, isNull);
    expect(review.rating, 5);
  });
}
