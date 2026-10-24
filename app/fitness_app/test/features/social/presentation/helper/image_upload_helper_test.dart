import 'dart:typed_data';

import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/social/data/social_models.dart';
import 'package:fitness_app/features/social/presentation/helper/image_upload.helper.dart';
import 'package:flutter_test/flutter_test.dart';

PickedImage _image(String name, int size, {String? mime}) =>
    PickedImage(name: name, bytes: Uint8List(size), mimeType: mime);

void main() {
  group('validateImages', () {
    test('accepts supported images within limits', () {
      expect(validateImages([_image('a.jpg', 1000)]), isNull);
      expect(
        validateImages([_image('a.PNG', 1000, mime: 'image/png')]),
        isNull,
      );
    });

    test('rejects empty selection, empty file and unsupported format', () {
      expect(validateImages(const []), isNotNull);
      expect(validateImages([_image('a.jpg', 0)]), contains('пустой'));
      expect(validateImages([_image('a.heic', 10)]), contains('JPEG'));
      expect(
        validateImages([_image('a.jpg', 10, mime: 'image/gif')]),
        contains('JPEG'),
      );
    });

    test('rejects file over 5 MB but accepts exactly 5 MB', () {
      expect(validateImages([_image('a.jpg', maxImageBytes)]), isNull);
      expect(
        validateImages([_image('big.jpg', maxImageBytes + 1)]),
        contains('больше 5 МБ'),
      );
    });

    test('rejects batch over 25 MB total even if each is under 5 MB', () {
      final images = List.generate(
        6,
        (i) => _image('p$i.jpg', maxImageBytes - 1),
      );
      expect(validateImages(images, maxCount: 6), contains('25 МБ'));
    });

    test('respects free portfolio slots', () {
      final images = List.generate(3, (i) => _image('p$i.jpg', 10));
      expect(validateImages(images, maxCount: 2), contains('не больше 2'));
      expect(validateImages(images, maxCount: 0), contains('лимит'));
      expect(validateImages(images, maxCount: 3), isNull);
    });
  });

  group('uploadErrorMessage', () {
    test('maps backend codes', () {
      expect(
        uploadErrorMessage(ApiException('x', code: 'PORTFOLIO_LIMIT_REACHED')),
        contains('максимум'),
      );
      expect(
        uploadErrorMessage(ApiException('x', code: 'IMAGE_TOO_LARGE')),
        contains('5 МБ'),
      );
      expect(
        uploadErrorMessage(ApiException('x', statusCode: 413)),
        'Фото слишком большое',
      );
    });

    test('passes through offline message and hides unknown errors', () {
      expect(
        uploadErrorMessage(ApiException('Нет соединения с сервером')),
        'Нет соединения с сервером',
      );
      expect(uploadErrorMessage(StateError('boom')), isNot(contains('boom')));
    });
  });
}
