import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/social/data/social_models.dart';
import 'package:fitness_app/features/social/data/social_repository.dart';
import 'package:fitness_app/features/social/presentation/widgets/social_profile_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SocialRepository extends Mock implements SocialRepository {}

void main() {
  testWidgets('contact controls show privacy and validate selected phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SocialRepository();
    when(() => repository.getOwnProfile()).thenAnswer(
      (_) async => const OwnerProfile(
        userId: 'student',
        displayName: 'Иван',
        email: 'student@example.com',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RepositoryProvider<SocialRepository>.value(
              value: repository,
              child: const SocialProfileEditor(isTrainer: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Мои контакты'), findsOneWidget);
    expect(find.textContaining('только связанным'), findsOneWidget);
    expect(find.textContaining('student@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Телефон'));
    await tester.tap(find.widgetWithText(FilterChip, 'Телефон'));
    await tester.ensureVisible(find.text('Сохранить профиль'));
    await tester.tap(find.text('Сохранить профиль'));
    await tester.pump();

    expect(find.text('Укажите телефон для выбранного канала'), findsOneWidget);
    expect(tester.takeException(), isNull);
    verifyNever(
      () => repository.updateOwnProfile(displayName: any(named: 'displayName')),
    );
  });
}
