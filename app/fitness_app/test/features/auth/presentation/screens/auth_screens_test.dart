import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/auth/data/auth_models.dart';
import 'package:fitness_app/features/auth/data/auth_repository.dart';
import 'package:fitness_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fitness_app/features/auth/presentation/screens/login_screen.dart';
import 'package:fitness_app/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late AuthCubit authCubit;

  setUp(() {
    authRepository = _MockAuthRepository();
    authCubit = AuthCubit(authRepository: authRepository);
  });

  tearDown(() => authCubit.close());

  Widget buildSubject(Widget child) {
    return BlocProvider.value(
      value: authCubit,
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
  }

  testWidgets('login remains scrollable on a compact keyboard viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(buildSubject(const LoginScreen()));
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('С возвращением!'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Введите email'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);

    final passwordField = tester.widget<EditableText>(
      find.byType(EditableText).last,
    );
    expect(passwordField.obscureText, isTrue);

    await tester.ensureVisible(find.byTooltip('Показать пароль'));
    await tester.tap(find.byTooltip('Показать пароль'));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isFalse,
    );
    expect(find.byTooltip('Скрыть пароль'), findsOneWidget);
  });

  testWidgets('register submits the selected student role', (tester) async {
    const session = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      user: AuthUser(
        id: 'user-id',
        email: 'student@example.com',
        roles: ['student'],
        permissions: [],
      ),
    );
    when(
      () => authRepository.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async => session);

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject(const RegisterScreen()));

    await tester.enterText(find.byType(TextField).at(0), 'student@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.ensureVisible(find.text('Ученик'));
    await tester.tap(find.text('Ученик'));
    await tester.ensureVisible(find.text('Зарегистрироваться'));
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pump();

    verify(
      () => authRepository.register(
        email: 'student@example.com',
        password: 'password123',
        role: 'student',
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });
}
