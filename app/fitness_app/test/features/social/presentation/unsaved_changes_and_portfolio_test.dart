import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/social/data/device_image_picker.dart';
import 'package:fitness_app/features/social/data/social_models.dart';
import 'package:fitness_app/features/social/data/social_repository.dart';
import 'package:fitness_app/features/social/presentation/controller/unsaved_changes_guard.dart';
import 'package:fitness_app/features/social/presentation/screens/portfolio_editor_screen.dart';
import 'package:fitness_app/features/social/presentation/widgets/portfolio_photo_picker.dart';
import 'package:fitness_app/features/social/presentation/widgets/social_profile_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements SocialRepository {}

class _FakePhotoPicker implements PortfolioPhotoPicker {
  _FakePhotoPicker(this.urls);

  final List<String> urls;
  int? lastMaxCount;

  @override
  Future<List<String>> pickPhotos(
    BuildContext context, {
    required int maxCount,
  }) async {
    lastMaxCount = maxCount;
    return urls.take(maxCount).toList();
  }
}

OwnerProfile _profile({List<PortfolioItem> portfolio = const []}) =>
    OwnerProfile(
      userId: 't',
      displayName: 'Тренер',
      email: 't@example.com',
      city: 'Тверь',
      portfolio: portfolio,
    );

void main() {
  late _Repository repository;

  setUpAll(() => registerFallbackValue(const ProfilePrivacy()));

  setUp(() {
    repository = _Repository();
    when(() => repository.getOwnProfile()).thenAnswer((_) async => _profile());
  });

  group('PortfolioItem', () {
    test('parses imageUrls and falls back to legacy imageUrl', () {
      final many = PortfolioItem.fromJson(const {
        'title': 'a',
        'imageUrls': ['u1', 'u2', 'u3'],
        'imageUrl': 'u1',
      });
      expect(many.imageUrls, ['u1', 'u2', 'u3']);
      expect(many.imageUrl, 'u1');

      final legacy = PortfolioItem.fromJson(const {
        'title': 'a',
        'imageUrl': 'old',
      });
      expect(legacy.imageUrls, ['old']);
      expect(PortfolioItem.fromJson(const {'title': 'a'}).imageUrls, isEmpty);
    });

    test('OwnerProfile counts photos across items', () {
      final profile = _profile(
        portfolio: const [
          PortfolioItem(title: 'a', imageUrls: ['1', '2'], sortOrder: 0),
          PortfolioItem(title: 'b', imageUrls: ['3'], sortOrder: 1),
        ],
      );
      expect(profile.portfolioPhotoCount, 3);
    });
  });

  group('UnsavedChangesGuard dialog', () {
    Future<bool> askAndTap(WidgetTester tester, Key button) async {
      final guard = UnsavedChangesGuard()..setDirty(true);
      var saved = 0;
      guard.attach(
        save: () async {
          saved++;
          guard.setDirty(false);
          return true;
        },
      );
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final result = guard.confirmLeave(ctx);
      await tester.pumpAndSettle();
      expect(find.text('Есть несохранённые изменения'), findsOneWidget);
      await tester.tap(find.byKey(button));
      await tester.pumpAndSettle();
      final allowed = await result;
      if (button == const Key('unsaved-save')) expect(saved, 1);
      return allowed;
    }

    testWidgets('«Сохранить» сохраняет и разрешает уход', (tester) async {
      expect(await askAndTap(tester, const Key('unsaved-save')), isTrue);
    });

    testWidgets('«Отменить и перейти» отбрасывает изменения', (tester) async {
      expect(await askAndTap(tester, const Key('unsaved-discard')), isTrue);
    });

    testWidgets('«Остаться» блокирует уход', (tester) async {
      expect(await askAndTap(tester, const Key('unsaved-stay')), isFalse);
    });

    testWidgets('без изменений диалог не показывается', (tester) async {
      final guard = UnsavedChangesGuard();
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(await guard.confirmLeave(ctx), isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SocialProfileEditor dirty tracking', () {
    Future<UnsavedChangesGuard> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final guard = UnsavedChangesGuard();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepositoryProvider<SocialRepository>.value(
                value: repository,
                child: SocialProfileEditor(
                  isTrainer: true,
                  guard: guard,
                  devicePicker: const ImagePickerDeviceImagePicker(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return guard;
    }

    testWidgets(
      'не dirty после загрузки, dirty после правки, чисто при откате',
      (tester) async {
        final guard = await pump(tester);
        expect(guard.dirty, isFalse);

        await tester.enterText(
          find.widgetWithText(TextField, 'Тренер'),
          'Новое имя',
        );
        await tester.pump();
        expect(guard.dirty, isTrue);

        await tester.enterText(
          find.widgetWithText(TextField, 'Новое имя'),
          'Тренер',
        );
        await tester.pump();
        expect(guard.dirty, isFalse);
      },
    );

    testWidgets('переключение приватности делает форму dirty', (tester) async {
      final guard = await pump(tester);

      await tester.ensureVisible(find.text('Показывать рейтинг'));
      await tester.tap(find.text('Показывать рейтинг'));
      await tester.pump();
      await tester.pump();

      expect(guard.dirty, isTrue);
    });

    testWidgets('сохранение шлёт прежний город и сбрасывает dirty', (
      tester,
    ) async {
      when(
        () => repository.updateOwnProfile(
          displayName: any(named: 'displayName'),
          avatarUrl: any(named: 'avatarUrl'),
          bio: any(named: 'bio'),
          city: any(named: 'city'),
          specialties: any(named: 'specialties'),
          trainingModes: any(named: 'trainingModes'),
          phone: any(named: 'phone'),
          telegramUsername: any(named: 'telegramUsername'),
          preferredContactChannels: any(named: 'preferredContactChannels'),
        ),
      ).thenAnswer((_) async => _profile());
      when(
        () => repository.updatePrivacy(any()),
      ).thenAnswer((_) async => _profile());
      final guard = await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Тренер'),
        'Другое имя',
      );
      await tester.pump();
      expect(guard.canSave, isTrue);
      await guard.save();
      await tester.pumpAndSettle();

      verify(
        () => repository.updateOwnProfile(
          displayName: 'Другое имя',
          avatarUrl: any(named: 'avatarUrl'),
          bio: any(named: 'bio'),
          city: 'Тверь',
          specialties: any(named: 'specialties'),
          trainingModes: any(named: 'trainingModes'),
          phone: any(named: 'phone'),
          telegramUsername: any(named: 'telegramUsername'),
          preferredContactChannels: any(named: 'preferredContactChannels'),
        ),
      ).called(1);
      expect(guard.dirty, isFalse);
    });

    testWidgets('ошибка валидации не сохраняет', (tester) async {
      final guard = await pump(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Тренер'), 'я');
      await tester.pump();
      final saved = await guard.save();
      await tester.pumpAndSettle();

      expect(saved, isFalse);
      expect(find.text('От 2 до 80 символов'), findsOneWidget);
      verifyNever(() => repository.updatePrivacy(any()));
    });
  });

  group('PortfolioEditorScreen', () {
    Future<void> pump(
      WidgetTester tester,
      PortfolioPhotoPicker picker, {
      String? itemId,
    }) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/edit'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, _) =>
                PortfolioEditorScreen(itemId: itemId, photoPicker: picker),
          ),
        ],
      );
      await tester.pumpWidget(
        RepositoryProvider<SocialRepository>.value(
          value: repository,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('одна запись с тремя фото сохраняется одним запросом', (
      tester,
    ) async {
      when(
        () => repository.createPortfolioItem(
          title: any(named: 'title'),
          description: any(named: 'description'),
          imageUrls: any(named: 'imageUrls'),
        ),
      ).thenAnswer(
        (_) async => const PortfolioItem(title: 'Мне 20', sortOrder: 0),
      );
      final picker = _FakePhotoPicker(['u1', 'u2', 'u3']);
      await pump(tester, picker);

      expect(find.textContaining('можно ещё 5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('portfolio-add-photo')));
      await tester.pumpAndSettle();
      expect(picker.lastMaxCount, 5);
      expect(find.byKey(const ValueKey('portfolio-photo-2')), findsOneWidget);
      expect(find.textContaining('можно ещё 2'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Название'),
        'Мне 20',
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      verify(
        () => repository.createPortfolioItem(
          title: 'Мне 20',
          description: any(named: 'description'),
          imageUrls: ['u1', 'u2', 'u3'],
        ),
      ).called(1);
    });

    testWidgets('лимит считается по фото других записей', (tester) async {
      when(() => repository.getOwnProfile()).thenAnswer(
        (_) async => _profile(
          portfolio: const [
            PortfolioItem(
              id: 'a',
              title: 'a',
              imageUrls: ['1', '2', '3', '4'],
              sortOrder: 0,
            ),
          ],
        ),
      );
      final picker = _FakePhotoPicker(['u1', 'u2', 'u3']);
      await pump(tester, picker);

      expect(find.textContaining('можно ещё 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('portfolio-add-photo')));
      await tester.pumpAndSettle();

      expect(picker.lastMaxCount, 1);
      expect(find.textContaining('можно ещё 0'), findsOneWidget);
      expect(find.byKey(const Key('portfolio-add-photo')), findsNothing);
    });

    testWidgets('при несохранённых изменениях back показывает диалог', (
      tester,
    ) async {
      await pump(tester, _FakePhotoPicker(const []));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Название'),
        'x',
      );
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Есть несохранённые изменения'), findsOneWidget);

      await tester.tap(find.byKey(const Key('unsaved-stay')));
      await tester.pumpAndSettle();
      expect(find.text('Новая работа'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unsaved-discard')));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('без изменений back уходит без диалога', (tester) async {
      await pump(tester, _FakePhotoPicker(const []));

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Есть несохранённые изменения'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
