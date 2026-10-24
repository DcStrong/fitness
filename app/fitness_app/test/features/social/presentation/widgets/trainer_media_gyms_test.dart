import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/social/data/device_image_picker.dart';
import 'package:fitness_app/features/social/data/social_models.dart';
import 'package:fitness_app/features/social/data/social_repository.dart';
import 'package:fitness_app/features/social/presentation/bloc/trainers_bloc.dart';
import 'package:fitness_app/features/social/presentation/widgets/social_profile_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements SocialRepository {}

class _Picker implements DeviceImagePicker {
  _Picker(this.size);

  final int size;

  @override
  Future<List<PickedImage>> pick({int maxCount = 1}) async => [
    PickedImage(name: 'big.jpg', bytes: Uint8List(size)),
  ];
}

const _gym = Gym(id: 'g1', name: 'Iron', address: 'Ленина 1', city: 'Тверь');

Future<void> _pump(
  WidgetTester tester,
  _Repository repository, {
  DeviceImagePicker picker = const ImagePickerDeviceImagePicker(),
}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: RepositoryProvider<SocialRepository>.value(
            value: repository,
            child: SocialProfileEditor(isTrainer: true, devicePicker: picker),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _Repository repository;

  setUpAll(
    () =>
        registerFallbackValue(PickedImage(name: 'f.jpg', bytes: Uint8List(1))),
  );

  setUp(() {
    repository = _Repository();
    when(() => repository.getOwnProfile()).thenAnswer(
      (_) async => const OwnerProfile(
        userId: 't',
        displayName: 'Тренер',
        email: 't@example.com',
        city: 'Тверь',
        gyms: [_gym],
      ),
    );
  });

  testWidgets('avatar link field is gone, photo picker and gyms are shown', (
    tester,
  ) async {
    await _pump(tester, repository);

    expect(find.text('HTTPS-ссылка на фото'), findsNothing);
    expect(find.text('Выбрать фото'), findsOneWidget);
    expect(find.text('Залы, где я тренирую'), findsOneWidget);
    expect(find.text('Iron'), findsOneWidget);
    expect(find.textContaining('Ленина 1'), findsOneWidget);
  });

  testWidgets('oversized avatar shows an error and does not upload', (
    tester,
  ) async {
    await _pump(tester, repository, picker: _Picker(5 * 1024 * 1024 + 1));

    await tester.tap(find.text('Выбрать фото'));
    await tester.pumpAndSettle();

    expect(find.textContaining('больше 5 МБ'), findsOneWidget);
    verifyNever(() => repository.uploadAvatar(any()));
  });

  testWidgets('adding a gym requires name and address', (tester) async {
    await _pump(tester, repository);

    await tester.ensureVisible(find.text('Добавить зал'));
    await tester.tap(find.text('Добавить зал'));
    await tester.pump();

    expect(find.text('Обязательное поле'), findsNWidgets(2));
    verifyNever(
      () => repository.attachGym(
        name: any(named: 'name'),
        address: any(named: 'address'),
        city: any(named: 'city'),
        district: any(named: 'district'),
      ),
    );
  });

  testWidgets('removing a gym calls the backend', (tester) async {
    when(() => repository.detachGym('g1')).thenAnswer((_) async {});
    await _pump(tester, repository);

    await tester.tap(find.byTooltip('Убрать зал'));
    await tester.pumpAndSettle();

    verify(() => repository.detachGym('g1')).called(1);
    expect(find.text('Залы пока не добавлены.'), findsOneWidget);
  });

  blocTest<TrainersBloc, TrainersState>(
    'filters by gym, district and gym query are sent to the repository',
    build: () {
      when(
        () => repository.discoverTrainers(
          page: any(named: 'page'),
          query: any(named: 'query'),
          specialty: any(named: 'specialty'),
          mode: any(named: 'mode'),
          gymId: any(named: 'gymId'),
          district: any(named: 'district'),
          gymQuery: any(named: 'gymQuery'),
        ),
      ).thenAnswer(
        (_) async => const TrainerDiscoveryPage(
          items: [],
          meta: PageMeta(page: 1, limit: 20, total: 0, totalPages: 0),
        ),
      );
      when(() => repository.changes).thenAnswer((_) => const Stream.empty());
      return TrainersBloc(repository: repository);
    },
    act: (bloc) => bloc.add(
      const TrainersFiltersChanged(
        district: 'Центр',
        gymQuery: 'Ленина',
        gym: _gym,
      ),
    ),
    verify: (_) => verify(
      () => repository.discoverTrainers(
        page: 1,
        query: '',
        specialty: '',
        mode: null,
        gymId: 'g1',
        district: 'Центр',
        gymQuery: 'Ленина',
      ),
    ).called(1),
  );
}
