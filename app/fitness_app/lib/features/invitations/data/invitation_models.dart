import 'package:equatable/equatable.dart';

class InvitationCreated extends Equatable {
  const InvitationCreated({
    required this.id,
    required this.coachId,
    required this.status,
    required this.expiresAt,
    required this.token,
    required this.inviteUrl,
    required this.deepLink,
  });

  factory InvitationCreated.fromJson(Map<String, dynamic> json) {
    return InvitationCreated(
      id: json['id'] as String,
      coachId: json['coachId'] as String,
      status: json['status'] as String,
      expiresAt: json['expiresAt'] as String,
      token: json['token'] as String,
      inviteUrl: json['inviteUrl'] as String,
      deepLink: json['deepLink'] as String,
    );
  }

  final String id;
  final String coachId;
  final String status;
  final String expiresAt;
  final String token;
  final String inviteUrl;
  final String deepLink;

  @override
  List<Object?> get props => [id, token, inviteUrl];
}

class RelationshipItem extends Equatable {
  const RelationshipItem({
    required this.id,
    required this.coachId,
    required this.studentId,
    required this.roleForViewer,
    this.coachEmail,
    this.studentEmail,
    this.coachDisplayName,
    this.studentDisplayName,
    this.createdAt,
  });

  factory RelationshipItem.fromJson(Map<String, dynamic> json) {
    return RelationshipItem(
      id: json['id'] as String,
      coachId: json['coachId'] as String,
      studentId: json['studentId'] as String,
      roleForViewer: json['roleForViewer'] as String,
      coachEmail: json['coachEmail'] as String?,
      studentEmail: json['studentEmail'] as String?,
      coachDisplayName: json['coachDisplayName'] as String?,
      studentDisplayName: json['studentDisplayName'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  final String id;
  final String coachId;
  final String studentId;
  final String roleForViewer;
  final String? coachEmail;
  final String? studentEmail;
  final String? coachDisplayName;
  final String? studentDisplayName;
  final String? createdAt;

  /// Name for the student side (displayName, else email, else id).
  String get studentLabel {
    final name = studentDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = studentEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return studentId;
  }

  /// Name for the coach side.
  String get coachLabel {
    final name = coachDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = coachEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return coachId;
  }

  @override
  List<Object?> get props => [
    id,
    coachId,
    studentId,
    roleForViewer,
    coachDisplayName,
    studentDisplayName,
  ];
}

class AcceptInvitationResult extends Equatable {
  const AcceptInvitationResult({
    required this.coachId,
    required this.studentId,
    this.coachEmail,
  });

  factory AcceptInvitationResult.fromJson(Map<String, dynamic> json) {
    final relationship = json['relationship'] as Map<String, dynamic>? ?? {};
    return AcceptInvitationResult(
      coachId: relationship['coachId'] as String,
      studentId: relationship['studentId'] as String,
      coachEmail: relationship['coachEmail'] as String?,
    );
  }

  final String coachId;
  final String studentId;
  final String? coachEmail;

  @override
  List<Object?> get props => [coachId, studentId, coachEmail];
}
