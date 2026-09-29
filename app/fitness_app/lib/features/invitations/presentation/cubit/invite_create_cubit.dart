import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/invitations_repository.dart';
import 'invite_create_state.dart';

class InviteCreateCubit extends Cubit<InviteCreateState> {
  InviteCreateCubit({required InvitationsRepository repository})
    : _repository = repository,
      super(const InviteCreateState());

  final InvitationsRepository _repository;

  Future<void> create() async {
    emit(state.copyWith(isLoading: true, clearError: true, copied: false));
    try {
      final invitation = await _repository.create();
      emit(InviteCreateState(invitation: invitation, isLoading: false));
    } on ApiException catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.message));
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Не удалось создать приглашение: $error',
        ),
      );
    }
  }

  void markCopied() {
    emit(state.copyWith(copied: true));
  }
}
