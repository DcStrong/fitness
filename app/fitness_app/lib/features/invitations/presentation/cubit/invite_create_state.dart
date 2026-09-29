import 'package:equatable/equatable.dart';

import '../../data/invitation_models.dart';

class InviteCreateState extends Equatable {
  const InviteCreateState({
    this.invitation,
    this.isLoading = false,
    this.errorMessage,
    this.copied = false,
  });

  final InvitationCreated? invitation;
  final bool isLoading;
  final String? errorMessage;
  final bool copied;

  InviteCreateState copyWith({
    InvitationCreated? invitation,
    bool? isLoading,
    String? errorMessage,
    bool? copied,
    bool clearError = false,
  }) {
    return InviteCreateState(
      invitation: invitation ?? this.invitation,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      copied: copied ?? this.copied,
    );
  }

  @override
  List<Object?> get props => [invitation, isLoading, errorMessage, copied];
}
