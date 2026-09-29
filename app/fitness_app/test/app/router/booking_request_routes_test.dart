import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/router/app_router.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fitness_app/features/invitations/data/invitations_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _InvitationsRepository extends Mock implements InvitationsRepository {}

void main() {
  test('booking request routes enforce role visibility', () {
    expect(
      bookingRequestRoleRedirect(const ['student'], trainerRoute: false),
      isNull,
    );
    expect(
      bookingRequestRoleRedirect(const ['student'], trainerRoute: true),
      '/home',
    );
    expect(
      bookingRequestRoleRedirect(const ['trainer'], trainerRoute: true),
      isNull,
    );
    expect(
      bookingRequestRoleRedirect(const ['trainer'], trainerRoute: false),
      '/home',
    );
  });

  testWidgets('logged-out booking request deep link redirects to login', (
    tester,
  ) async {
    final auth = _AuthCubit();
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(status: AuthStatus.unauthenticated),
    );
    final router = createAppRouter(
      auth,
      _InvitationsRepository(),
      themeMode: ValueNotifier(ThemeMode.light),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/booking-requests/request-id');
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.text('Войти'), findsWidgets);
  });
}
