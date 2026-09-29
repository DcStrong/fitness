import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/auth/data/auth_models.dart';
import 'package:fitness_app/features/auth/data/auth_repository.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  const user = AuthUser(
    id: 'u1',
    email: 'a@b.c',
    roles: ['trainer'],
    permissions: ['users:read_self'],
  );

  const session = AuthSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    user: user,
  );

  setUp(() {
    repository = MockAuthRepository();
  });

  group('AuthCubit.login', () {
    blocTest<AuthCubit, AuthState>(
      'emits authenticated on success',
      build: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => session);
        return AuthCubit(authRepository: repository);
      },
      act: (cubit) => cubit.login(email: 'a@b.c', password: 'password1'),
      expect: () => [
        const AuthState(status: AuthStatus.unknown, isSubmitting: true),
        const AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits error on ApiException',
      build: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(ApiException('Неверный email или пароль', statusCode: 401));
        return AuthCubit(authRepository: repository);
      },
      act: (cubit) => cubit.login(email: 'a@b.c', password: 'bad'),
      expect: () => [
        const AuthState(status: AuthStatus.unknown, isSubmitting: true),
        const AuthState(
          status: AuthStatus.unauthenticated,
          isSubmitting: false,
          errorMessage: 'Неверный email или пароль',
        ),
      ],
    );
  });
}
