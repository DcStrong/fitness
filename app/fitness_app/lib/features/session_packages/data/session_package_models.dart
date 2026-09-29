import 'package:equatable/equatable.dart';

import '../../finance/data/finance_models.dart';

typedef SessionPackageStatus = String;

class SessionPackage extends Equatable {
  const SessionPackage({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.totalSessions,
    required this.remainingSessions,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.archivedAt,
    this.coachEmail,
    this.studentEmail,
  });

  factory SessionPackage.fromJson(Map<String, dynamic> json) {
    return SessionPackage(
      id: json['id'] as String,
      coachId: json['coachId'] as String,
      studentId: json['studentId'] as String,
      totalSessions: json['totalSessions'] as int,
      remainingSessions: json['remainingSessions'] as int,
      expiresAt: json['expiresAt'] as String?,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      archivedAt: json['archivedAt'] as String?,
      coachEmail: json['coachEmail'] as String?,
      studentEmail: json['studentEmail'] as String?,
    );
  }

  final String id;
  final String coachId;
  final String studentId;
  final int totalSessions;
  final int remainingSessions;
  final String? expiresAt;
  final SessionPackageStatus status;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
  final String? coachEmail;
  final String? studentEmail;

  bool get isActive => status == 'active';
  bool get isExhausted => status == 'exhausted';
  bool get isExpired => status == 'expired';
  bool get isArchived => status == 'archived';

  String get remainingLabel {
    if (isExhausted) return 'Исчерпан';
    if (isExpired) return 'Истёк';
    if (isArchived) return 'В архиве';
    return 'Осталось $remainingSessions';
  }

  @override
  List<Object?> get props => [id, remainingSessions, status, totalSessions];
}

Map<String, dynamic> sessionPackageJsonMap(dynamic value) => jsonMap(value);
