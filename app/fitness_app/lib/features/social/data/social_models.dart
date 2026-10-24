import 'dart:typed_data';

import 'package:equatable/equatable.dart';

Map<String, dynamic> socialJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<String> _strings(dynamic value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];

enum PreferredContactChannel { phone, telegram, email }

PreferredContactChannel? _contactChannel(String value) => switch (value) {
  'phone' => PreferredContactChannel.phone,
  'telegram' => PreferredContactChannel.telegram,
  'email' => PreferredContactChannel.email,
  _ => null,
};

extension PreferredContactChannelWire on PreferredContactChannel {
  String get wireValue => name;
}

class LinkedContacts extends Equatable {
  const LinkedContacts({
    required this.userId,
    required this.email,
    this.phone,
    this.telegramUsername,
    this.preferredContactChannels = const [],
  });

  factory LinkedContacts.fromJson(Map<String, dynamic> json) => LinkedContacts(
    userId: json['userId'] as String? ?? '',
    phone: json['phone'] as String?,
    telegramUsername: json['telegramUsername'] as String?,
    email: json['email'] as String? ?? '',
    preferredContactChannels: _strings(json['preferredContactChannels'])
        .map(_contactChannel)
        .whereType<PreferredContactChannel>()
        .toList(growable: false),
  );

  final String userId;
  final String? phone;
  final String? telegramUsername;
  final String email;
  final List<PreferredContactChannel> preferredContactChannels;

  @override
  List<Object?> get props => [
    userId,
    phone,
    telegramUsername,
    email,
    preferredContactChannels,
  ];
}

DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

class ProfilePrivacy extends Equatable {
  const ProfilePrivacy({
    this.isDiscoverable = false,
    this.showRating = true,
    this.showReviews = true,
    this.showReviewerName = false,
  });

  factory ProfilePrivacy.fromJson(Map<String, dynamic> json) => ProfilePrivacy(
    isDiscoverable: json['isDiscoverable'] == true,
    showRating: json['showRating'] != false,
    showReviews: json['showReviews'] != false,
    showReviewerName: json['showReviewerName'] == true,
  );

  final bool isDiscoverable;
  final bool showRating;
  final bool showReviews;
  final bool showReviewerName;

  Map<String, dynamic> toJson() => {
    'isDiscoverable': isDiscoverable,
    'showRating': showRating,
    'showReviews': showReviews,
    'showReviewerName': showReviewerName,
  };

  ProfilePrivacy copyWith({
    bool? isDiscoverable,
    bool? showRating,
    bool? showReviews,
    bool? showReviewerName,
  }) => ProfilePrivacy(
    isDiscoverable: isDiscoverable ?? this.isDiscoverable,
    showRating: showRating ?? this.showRating,
    showReviews: showReviews ?? this.showReviews,
    showReviewerName: showReviewerName ?? this.showReviewerName,
  );

  @override
  List<Object?> get props => [
    isDiscoverable,
    showRating,
    showReviews,
    showReviewerName,
  ];
}

class Gym extends Equatable {
  const Gym({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.district,
  });

  factory Gym.fromJson(Map<String, dynamic> json) => Gym(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    city: json['city'] as String? ?? '',
    district: json['district'] as String?,
  );

  final String id;
  final String name;
  final String address;
  final String city;
  final String? district;

  /// Адрес с районом для подписей: «Район, Город, улица».
  String get fullAddress => [
    if (district?.isNotEmpty == true) district!,
    city,
    address,
  ].where((part) => part.isNotEmpty).join(', ');

  @override
  List<Object?> get props => [id, name, address, city, district];
}

List<Gym> _gyms(dynamic value) => (value as List<dynamic>? ?? const [])
    .map((item) => Gym.fromJson(socialJsonMap(item)))
    .toList(growable: false);

/// Файл, выбранный на устройстве и готовый к загрузке.
class PickedImage extends Equatable {
  const PickedImage({required this.name, required this.bytes, this.mimeType});

  final String name;
  final Uint8List bytes;
  final String? mimeType;

  int get size => bytes.length;

  String? get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? null : name.substring(dot + 1).toLowerCase();
  }

  /// MIME для multipart: сообщённый платформой или по расширению.
  String get contentType {
    final reported = mimeType?.toLowerCase();
    if (reported == 'image/jpeg' ||
        reported == 'image/png' ||
        reported == 'image/webp') {
      return reported!;
    }
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  @override
  List<Object?> get props => [name, bytes.length, mimeType];
}

/// Результат загрузки картинки в хранилище.
class UploadedImage extends Equatable {
  const UploadedImage({required this.url, this.size = 0});

  factory UploadedImage.fromJson(Map<String, dynamic> json) => UploadedImage(
    url: json['url'] as String? ?? '',
    size: (json['size'] as num?)?.toInt() ?? 0,
  );

  final String url;
  final int size;

  @override
  List<Object?> get props => [url, size];
}

class PortfolioItem extends Equatable {
  const PortfolioItem({
    this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) => PortfolioItem(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  final String? id;
  final String title;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, title, description, imageUrl, sortOrder];
}

class OwnerProfile extends Equatable {
  const OwnerProfile({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.specialties = const [],
    this.trainingModes = const [],
    this.phone,
    this.telegramUsername,
    this.preferredContactChannels = const [],
    this.email = '',
    this.privacy = const ProfilePrivacy(),
    this.portfolio = const [],
    this.gyms = const [],
    this.averageRating,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory OwnerProfile.fromJson(Map<String, dynamic> json) => OwnerProfile(
    userId: json['userId'] as String? ?? '',
    displayName: json['displayName'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    bio: json['bio'] as String?,
    city: json['city'] as String?,
    specialties: _strings(json['specialties']),
    trainingModes: _strings(json['trainingModes']),
    phone: json['phone'] as String?,
    telegramUsername: json['telegramUsername'] as String?,
    preferredContactChannels: _strings(json['preferredContactChannels'])
        .map(_contactChannel)
        .whereType<PreferredContactChannel>()
        .toList(growable: false),
    email: json['email'] as String? ?? '',
    privacy: ProfilePrivacy.fromJson(socialJsonMap(json['privacy'])),
    portfolio: (json['portfolio'] as List<dynamic>? ?? const [])
        .map((item) => PortfolioItem.fromJson(socialJsonMap(item)))
        .toList(growable: false),
    gyms: _gyms(json['gyms']),
    averageRating: (json['averageRating'] as num?)?.toDouble(),
    reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final List<String> specialties;
  final List<String> trainingModes;
  final String? phone;
  final String? telegramUsername;
  final List<PreferredContactChannel> preferredContactChannels;
  final String email;
  final ProfilePrivacy privacy;
  final List<PortfolioItem> portfolio;
  final List<Gym> gyms;
  final double? averageRating;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    userId,
    displayName,
    avatarUrl,
    bio,
    city,
    specialties,
    trainingModes,
    phone,
    telegramUsername,
    preferredContactChannels,
    email,
    privacy,
    portfolio,
    gyms,
    averageRating,
    reviewCount,
  ];
}

class PublicTrainer extends Equatable {
  const PublicTrainer({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.specialties = const [],
    this.trainingModes = const [],
    this.gyms = const [],
    this.averageRating,
    this.reviewCount,
    this.portfolio = const [],
    this.isLinked,
  });

  factory PublicTrainer.fromJson(Map<String, dynamic> json) => PublicTrainer(
    id: json['id'] as String? ?? '',
    displayName: json['displayName'] as String? ?? 'Тренер',
    avatarUrl: json['avatarUrl'] as String?,
    bio: json['bio'] as String?,
    city: json['city'] as String?,
    specialties: _strings(json['specialties']),
    trainingModes: _strings(json['trainingModes']),
    gyms: _gyms(json['gyms']),
    averageRating: (json['averageRating'] as num?)?.toDouble(),
    reviewCount: (json['reviewCount'] as num?)?.toInt(),
    portfolio: (json['portfolio'] as List<dynamic>? ?? const [])
        .map((item) => PortfolioItem.fromJson(socialJsonMap(item)))
        .toList(growable: false),
    isLinked: json['isLinked'] as bool?,
  );

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final List<String> specialties;
  final List<String> trainingModes;
  final List<Gym> gyms;
  final double? averageRating;
  final int? reviewCount;
  final List<PortfolioItem> portfolio;
  final bool? isLinked;

  @override
  List<Object?> get props => [
    id,
    displayName,
    avatarUrl,
    bio,
    city,
    specialties,
    trainingModes,
    gyms,
    averageRating,
    reviewCount,
    portfolio,
    isLinked,
  ];
}

class PageMeta extends Equatable {
  const PageMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
    page: (json['page'] as num?)?.toInt() ?? 1,
    limit: (json['limit'] as num?)?.toInt() ?? 20,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );

  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasNext => page < totalPages;

  @override
  List<Object?> get props => [page, limit, total, totalPages];
}

class TrainerDiscoveryPage extends Equatable {
  const TrainerDiscoveryPage({required this.items, required this.meta});

  factory TrainerDiscoveryPage.fromJson(Map<String, dynamic> json) =>
      TrainerDiscoveryPage(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => PublicTrainer.fromJson(socialJsonMap(item)))
            .toList(growable: false),
        meta: PageMeta.fromJson(socialJsonMap(json['meta'])),
      );

  final List<PublicTrainer> items;
  final PageMeta meta;

  @override
  List<Object?> get props => [items, meta];
}

class Reviewer extends Equatable {
  const Reviewer({required this.displayName, this.avatarUrl});

  factory Reviewer.fromJson(Map<String, dynamic> json) => Reviewer(
    displayName: json['displayName'] as String? ?? 'Ученик',
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String displayName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [displayName, avatarUrl];
}

class SessionReview extends Equatable {
  const SessionReview({
    this.id,
    this.sessionId,
    this.coachId,
    required this.rating,
    this.text,
    required this.reviewer,
    required this.sessionStartsAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SessionReview.fromJson(Map<String, dynamic> json) => SessionReview(
    id: json['id'] as String?,
    sessionId: json['sessionId'] as String?,
    coachId: json['coachId'] as String?,
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    text: json['text'] as String?,
    reviewer: Reviewer.fromJson(socialJsonMap(json['reviewer'])),
    sessionStartsAt: _date(json['sessionStartsAt']) ?? DateTime(1970),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  final String? id;
  final String? sessionId;
  final String? coachId;
  final int rating;
  final String? text;
  final Reviewer reviewer;
  final DateTime sessionStartsAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    sessionId,
    coachId,
    rating,
    text,
    reviewer,
    sessionStartsAt,
  ];
}

class ReviewPage extends Equatable {
  const ReviewPage({required this.items, required this.meta});

  factory ReviewPage.fromJson(Map<String, dynamic> json) => ReviewPage(
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((item) => SessionReview.fromJson(socialJsonMap(item)))
        .toList(growable: false),
    meta: PageMeta.fromJson(socialJsonMap(json['meta'])),
  );

  final List<SessionReview> items;
  final PageMeta meta;

  @override
  List<Object?> get props => [items, meta];
}

class EligibleReviewSession extends Equatable {
  const EligibleReviewSession({
    required this.sessionId,
    required this.coachId,
    this.coachDisplayName,
    required this.startsAt,
    required this.endsAt,
    required this.mode,
  });

  factory EligibleReviewSession.fromJson(Map<String, dynamic> json) =>
      EligibleReviewSession(
        sessionId: json['sessionId'] as String? ?? '',
        coachId: json['coachId'] as String? ?? '',
        coachDisplayName: json['coachDisplayName'] as String?,
        startsAt: _date(json['startsAt']) ?? DateTime(1970),
        endsAt: _date(json['endsAt']) ?? DateTime(1970),
        mode: json['mode'] as String? ?? 'offline',
      );

  final String sessionId;
  final String coachId;
  final String? coachDisplayName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String mode;

  @override
  List<Object?> get props => [sessionId, coachId, startsAt, endsAt, mode];
}
