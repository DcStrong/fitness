import 'package:equatable/equatable.dart';

import '../../data/invitation_models.dart';

class InviteAcceptState extends Equatable {
  const InviteAcceptState({
    this.token = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.result,
  });

  final String token;
  final bool isSubmitting;
  final String? errorMessage;
  final AcceptInvitationResult? result;

  InviteAcceptState copyWith({
    String? token,
    bool? isSubmitting,
    String? errorMessage,
    AcceptInvitationResult? result,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return InviteAcceptState(
      token: token ?? this.token,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: clearResult ? null : (result ?? this.result),
    );
  }

  @override
  List<Object?> get props => [token, isSubmitting, errorMessage, result];
}
