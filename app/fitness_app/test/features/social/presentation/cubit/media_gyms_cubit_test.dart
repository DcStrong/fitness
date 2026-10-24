import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/social/data/device_image_picker.dart';
import 'package:fitness_app/features/social/data/social_models.dart';
import 'package:fitness_app/features/social/data/social_repository.dart';
import 'package:fitness_app/features/social/presentation/cubit/avatar_upload_cubit.dart';
import 'package:fitness_app/features/social/presentation/cubit/gyms_cubit.dart';
import 'package:fitness_app/features/social/presentation/helper/image_upload.helper.dart';
import 'package:fitness_app/features/social/presentation/widgets/portfolio_photo_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements SocialRepository {}

class _FakePicker implements DeviceImagePicker {
  _FakePicker(this.images);

  final List<PickedImage> images;
  int? lastMaxCount;

  @override
  Future<List<PickedImage>> pick({int maxCount = 1}) async {
    lastMaxCount = maxCount;
    return images;
  }
}

PickedImage _image(String name, int size) =>
    PickedImage(name: name, bytes: Uint8List(size));

const _gym = Gym(
  id: 'g1',
  name: 'Зал',
  address: 'ул. Ленина, 1',
  city: 'Москва',
  district: 'Центр',
);

void main() {
  late _Repository repository;

  setUpAll(() => registerFallbackValue(_image('f.jpg', 1)));
  setUp(() => repository = _Repository());

  group('AvatarUploadCubit', () {
    AvatarUploadCubit build(List<PickedImage> images) => AvatarUploadCubit(
      repository: repository,
      picker: _FakePicker(images),
      initialUrl: 'https://old',
    );

    blocTest<AvatarUploadCubit, AvatarUploadState>(
      'uploads the picked photo and stores its url',
      build: () => build([_image('a.jpg', 100)]),
      setUp: () => when(
        () => repository.uploadAvatar(any()),
      ).thenAnswer((_) async => const UploadedImage(url: 'https://new')),
      act: (cubit) => cubit.pickAndUpload(),
      expect: () => [
        isA<AvatarUploadState>().having(
          (s) => s.status,
          'status',
          AvatarUploadStatus.picking,
        ),
        isA<AvatarUploadState>().having(
          (s) => s.status,
          'status',
          AvatarUploadStatus.uploading,
        ),
        const AvatarUploadState(avatarUrl: 'https://new'),
      ],
    );

    blocTest<AvatarUploadCubit, AvatarUploadState>(
      'does not call the backend for a file over 5 MB',
      build: () => build([_image('big.jpg', maxImageBytes + 1)]),
      act: (cubit) => cubit.pickAndUpload(),
      verify: (cubit) {
        expect(cubit.state.error, contains('5 МБ'));
        expect(cubit.state.avatarUrl, 'https://old');
        verifyNever(() => repository.uploadAvatar(any()));
      },
    );

    blocTest<AvatarUploadCubit, AvatarUploadState>(
      'keeps old avatar and reports offline error',
      build: () => build([_image('a.jpg', 100)]),
      setUp: () => when(
        () => repository.uploadAvatar(any()),
      ).thenThrow(ApiException('Нет соединения с сервером')),
      act: (cubit) => cubit.pickAndUpload(),
      verify: (cubit) {
        expect(cubit.state.error, 'Нет соединения с сервером');
        expect(cubit.state.avatarUrl, 'https://old');
      },
    );

    blocTest<AvatarUploadCubit, AvatarUploadState>(
      'cancelled picker changes nothing',
      build: () => build(const []),
      act: (cubit) => cubit.pickAndUpload(),
      verify: (cubit) {
        expect(cubit.state.avatarUrl, 'https://old');
        expect(cubit.state.error, isNull);
      },
    );

    blocTest<AvatarUploadCubit, AvatarUploadState>(
      'remove clears the avatar',
      build: () => build(const []),
      act: (cubit) => cubit.remove(),
      expect: () => [const AvatarUploadState()],
    );
  });

  group('DevicePortfolioPhotoPicker', () {
    Future<List<String>> run(List<PickedImage> images, int maxCount) {
      final picker = DevicePortfolioPhotoPicker(
        repository: repository,
        picker: _FakePicker(images),
      );
      return picker.pickPhotos(_NoContext(), maxCount: maxCount);
    }

    test('uploads batch and returns urls in order', () async {
      when(() => repository.uploadPortfolioImages(any())).thenAnswer(
        (_) async => const [UploadedImage(url: 'u1'), UploadedImage(url: 'u2')],
      );
      final urls = await run([_image('a.jpg', 10), _image('b.png', 10)], 3);
      expect(urls, ['u1', 'u2']);
    });

    test('blocks when no free slots without calling backend', () async {
      await expectLater(
        run([_image('a.jpg', 10)], 0),
        throwsA(isA<PhotoPickException>()),
      );
      verifyNever(() => repository.uploadPortfolioImages(any()));
    });

    test('blocks total over 25 MB on the client', () async {
      final images = List.generate(
        6,
        (i) => _image('p$i.jpg', maxImageBytes - 1),
      );
      await expectLater(
        run(images, 6),
        throwsA(
          isA<PhotoPickException>().having(
            (e) => e.message,
            'message',
            contains('25 МБ'),
          ),
        ),
      );
      verifyNever(() => repository.uploadPortfolioImages(any()));
    });

    test('maps PORTFOLIO_LIMIT_REACHED from backend', () async {
      when(() => repository.uploadPortfolioImages(any())).thenThrow(
        ApiException('x', statusCode: 409, code: 'PORTFOLIO_LIMIT_REACHED'),
      );
      await expectLater(
        run([_image('a.jpg', 10)], 1),
        throwsA(
          isA<PhotoPickException>().having(
            (e) => e.message,
            'message',
            contains('максимум'),
          ),
        ),
      );
    });

    test('returns empty list when user cancels', () async {
      expect(await run(const [], 2), isEmpty);
    });
  });

  group('GymsCubit', () {
    blocTest<GymsCubit, GymsState>(
      'add appends the created gym',
      build: () => GymsCubit(repository: repository),
      setUp: () => when(
        () => repository.attachGym(
          name: any(named: 'name'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          district: any(named: 'district'),
        ),
      ).thenAnswer((_) async => _gym),
      act: (cubit) =>
          cubit.add(name: 'Зал', address: 'ул. Ленина, 1', city: 'Москва'),
      verify: (cubit) => expect(cubit.state.gyms, [_gym]),
    );

    blocTest<GymsCubit, GymsState>(
      'remove detaches and drops the gym',
      build: () => GymsCubit(repository: repository, initial: const [_gym]),
      setUp: () =>
          when(() => repository.detachGym('g1')).thenAnswer((_) async {}),
      act: (cubit) => cubit.remove(_gym),
      verify: (cubit) => expect(cubit.state.gyms, isEmpty),
    );

    blocTest<GymsCubit, GymsState>(
      'suggest hides already attached gyms and ignores short queries',
      build: () => GymsCubit(repository: repository, initial: const [_gym]),
      setUp: () =>
          when(
            () => repository.suggestGyms(
              query: any(named: 'query'),
              city: any(named: 'city'),
            ),
          ).thenAnswer(
            (_) async => const [
              _gym,
              Gym(id: 'g2', name: 'Другой', address: 'a', city: 'Москва'),
            ],
          ),
      act: (cubit) async {
        await cubit.suggest('з');
        await cubit.suggest('зал');
      },
      verify: (cubit) {
        expect(cubit.state.suggestions.map((g) => g.id), ['g2']);
        verify(
          () => repository.suggestGyms(
            query: 'зал',
            city: any(named: 'city'),
          ),
        ).called(1);
      },
    );

    blocTest<GymsCubit, GymsState>(
      'add failure keeps list and exposes error',
      build: () => GymsCubit(repository: repository),
      setUp: () => when(
        () => repository.attachGym(
          name: any(named: 'name'),
          address: any(named: 'address'),
          city: any(named: 'city'),
          district: any(named: 'district'),
        ),
      ).thenThrow(ApiException('Слишком много залов')),
      act: (cubit) => cubit.add(name: 'a', address: 'b', city: 'c'),
      verify: (cubit) {
        expect(cubit.state.gyms, isEmpty);
        expect(cubit.state.error, 'Слишком много залов');
        expect(cubit.state.saving, isFalse);
      },
    );
  });
}

/// Контекст не используется реализацией, поэтому достаточно заглушки.
class _NoContext extends Fake implements BuildContext {}
