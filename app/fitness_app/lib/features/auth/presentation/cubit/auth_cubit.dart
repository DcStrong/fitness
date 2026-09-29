import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState());

  final AuthRepository _authRepository;

  Future<void> bootstrap() async {
    try {
      final hasToken = await _authRepository.hasAccessToken();
      if (!hasToken) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
      final user = await _authRepository.me();
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      await _authRepository.logout();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final session = await _authRepository.login(
        email: email.trim(),
        password: password,
      );
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
          isSubmitting: false,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          status: AuthStatus.unauthenticated,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          status: AuthStatus.unauthenticated,
          errorMessage: 'Не удалось войти: $error',
        ),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final session = await _authRepository.register(
        email: email.trim(),
        password: password,
        role: role,
      );
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
          isSubmitting: false,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          status: AuthStatus.unauthenticated,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          status: AuthStatus.unauthenticated,
          errorMessage: 'Не удалось зарегистрироваться: $error',
        ),
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void onSessionExpired() {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
