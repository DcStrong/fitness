import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/invite_links.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/invitations_repository.dart';
import 'invite_accept_state.dart';

class InviteAcceptCubit extends Cubit<InviteAcceptState> {
  InviteAcceptCubit({
    required InvitationsRepository repository,
    String? initialToken,
  }) : _repository = repository,
       super(InviteAcceptState(token: initialToken ?? ''));

  final InvitationsRepository _repository;

  void setTokenInput(String value) {
    final token = InviteLinks.extractToken(value) ?? value.trim();
    emit(state.copyWith(token: token, clearError: true, clearResult: true));
  }

  Future<void> loadPendingIfEmpty() async {
    if (state.token.isNotEmpty) {
      return;
    }
    final pending = await _repository.readPendingToken();
    if (pending != null && pending.isNotEmpty) {
      emit(state.copyWith(token: pending));
    }
  }

  Future<bool> accept() async {
    final token = InviteLinks.extractToken(state.token) ?? state.token.trim();
    if (token.isEmpty) {
      emit(
        state.copyWith(errorMessage: 'Введите или откройте ссылку-приглашение'),
      );
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true, token: token));
    try {
      final result = await _repository.accept(token);
      emit(
        InviteAcceptState(token: token, isSubmitting: false, result: result),
      );
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.message));
      return false;
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Не удалось принять приглашение: $error',
        ),
      );
      return false;
    }
  }
}
