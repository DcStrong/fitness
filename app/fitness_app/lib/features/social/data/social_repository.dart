import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'social_models.dart';

class SocialRepository {
  SocialRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<OwnerProfile> getOwnProfile() => _getProfile('/profiles/me');

  Future<OwnerProfile> updateOwnProfile({
    required String displayName,
    String? avatarUrl,
    String? bio,
    String? city,
    List<String> specialties = const [],
    List<String> trainingModes = const [],
    String? phone,
    String? telegramUsername,
    List<PreferredContactChannel> preferredContactChannels = const [],
  }) => _request(
    () => _dio.put<dynamic>(
      '/profiles/me',
      data: {
        'displayName': displayName.trim(),
        'avatarUrl': _nullable(avatarUrl),
        'bio': _nullable(bio),
        'city': _nullable(city),
        'specialties': specialties,
        'trainingModes': trainingModes,
        'phone': _nullable(phone),
        'telegramUsername': _nullable(telegramUsername),
        'preferredContactChannels': preferredContactChannels
            .map((channel) => channel.wireValue)
            .toList(growable: false),
      },
    ),
    (data) => OwnerProfile.fromJson(_map(data)),
  );

  Future<LinkedContacts> getLinkedContacts(String userId) => _request(
    () => _dio.get<dynamic>('/profiles/$userId/contacts'),
    (data) => LinkedContacts.fromJson(_map(data)),
  );

  Future<OwnerProfile> updatePrivacy(ProfilePrivacy privacy) => _request(
    () => _dio.put<dynamic>('/profiles/me/privacy', data: privacy.toJson()),
    (data) => OwnerProfile.fromJson(_map(data)),
  );

  Future<PortfolioItem> createPortfolioItem({
    required String title,
    String? description,
    String? imageUrl,
  }) => _request(
    () => _dio.post<dynamic>(
      '/profiles/me/portfolio',
      data: _portfolioData(title, description, imageUrl),
    ),
    (data) => PortfolioItem.fromJson(_map(data)),
  );

  Future<PortfolioItem> updatePortfolioItem({
    required String id,
    required String title,
    String? description,
    String? imageUrl,
  }) => _request(
    () => _dio.put<dynamic>(
      '/profiles/me/portfolio/$id',
      data: _portfolioData(title, description, imageUrl),
    ),
    (data) => PortfolioItem.fromJson(_map(data)),
  );

  Future<List<PortfolioItem>> reorderPortfolio(List<String> itemIds) =>
      _request(
        () => _dio.put<dynamic>(
          '/profiles/me/portfolio/reorder',
          data: {'itemIds': itemIds},
        ),
        (data) => _list(
          data,
        ).map((item) => PortfolioItem.fromJson(item)).toList(growable: false),
      );

  Future<void> deletePortfolioItem(String id) => _request(
    () => _dio.delete<dynamic>('/profiles/me/portfolio/$id'),
    (_) {},
  );

  Future<TrainerDiscoveryPage> discoverTrainers({
    int page = 1,
    int limit = 20,
    String? query,
    String? specialty,
    String? mode,
  }) => _request(
    () => _dio.get<dynamic>(
      '/trainers',
      queryParameters: {
        'page': page,
        'limit': limit.clamp(1, 50),
        if (query?.trim().isNotEmpty == true) 'query': query!.trim(),
        if (specialty?.trim().isNotEmpty == true)
          'specialty': specialty!.trim(),
        if (mode?.isNotEmpty == true) 'mode': mode,
      },
    ),
    (data) => TrainerDiscoveryPage.fromJson(_map(data)),
  );

  Future<PublicTrainer> getTrainer(String id) => _request(
    () => _dio.get<dynamic>('/trainers/$id'),
    (data) => PublicTrainer.fromJson(_map(data)),
  );

  Future<ReviewPage> getTrainerReviews(
    String id, {
    int page = 1,
    int limit = 20,
  }) => _request(
    () => _dio.get<dynamic>(
      '/trainers/$id/reviews',
      queryParameters: {'page': page, 'limit': limit.clamp(1, 50)},
    ),
    (data) => ReviewPage.fromJson(_map(data)),
  );

  Future<List<EligibleReviewSession>> getEligibleReviews() => _request(
    () => _dio.get<dynamic>('/reviews/eligible'),
    (data) => _list(data)
        .map((item) => EligibleReviewSession.fromJson(item))
        .toList(growable: false),
  );

  Future<List<SessionReview>> getMyReviews() => _request(
    () => _dio.get<dynamic>('/reviews/mine'),
    (data) => _list(
      data,
    ).map((item) => SessionReview.fromJson(item)).toList(growable: false),
  );

  Future<SessionReview> createReview({
    required String sessionId,
    required int rating,
    String? text,
  }) async {
    final review = await _request(
      () => _dio.post<dynamic>(
        '/sessions/$sessionId/review',
        data: {'rating': rating, 'text': _nullable(text)},
      ),
      (data) => SessionReview.fromJson(_map(data)),
    );
    _changes.add(null);
    return review;
  }

  Future<SessionReview> updateReview({
    required String id,
    required int rating,
    String? text,
  }) async {
    final review = await _request(
      () => _dio.put<dynamic>(
        '/reviews/$id',
        data: {'rating': rating, 'text': _nullable(text)},
      ),
      (data) => SessionReview.fromJson(_map(data)),
    );
    _changes.add(null);
    return review;
  }

  Future<ReviewPage> getReceivedReviews({int page = 1, int limit = 20}) =>
      _request(
        () => _dio.get<dynamic>(
          '/profiles/me/reviews',
          queryParameters: {'page': page, 'limit': limit.clamp(1, 50)},
        ),
        (data) => ReviewPage.fromJson(_map(data)),
      );

  Future<OwnerProfile> _getProfile(String path) => _request(
    () => _dio.get<dynamic>(path),
    (data) => OwnerProfile.fromJson(_map(data)),
  );

  Map<String, dynamic> _portfolioData(
    String title,
    String? description,
    String? imageUrl,
  ) => {
    'title': title.trim(),
    'description': _nullable(description),
    'imageUrl': _nullable(imageUrl),
  };

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<T> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parse,
  ) async {
    try {
      return parse((await call()).data);
    } on DioException catch (error) {
      final data = error.response?.data;
      var message = 'Ошибка сети';
      if (data is Map && data['message'] is String) {
        message = data['message'] as String;
      } else if (data is Map && data['message'] is List) {
        message = (data['message'] as List).whereType<String>().join('\n');
      }
      throw ApiException(message, statusCode: error.response?.statusCode);
    }
  }

  Map<String, dynamic> _map(dynamic data) {
    final value = socialJsonMap(data);
    if (value.isEmpty && data is! Map) {
      throw ApiException('Неверный ответ сервера');
    }
    return value;
  }

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data is! List) return const [];
    return data.map(socialJsonMap).toList(growable: false);
  }
}
