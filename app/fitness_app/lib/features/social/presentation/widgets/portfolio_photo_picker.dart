import 'package:flutter/widgets.dart';

import '../../data/device_image_picker.dart';
import '../../data/social_repository.dart';
import '../helper/image_upload.helper.dart';

/// Ошибка выбора/загрузки фото с текстом, который можно показать пользователю.
class PhotoPickException implements Exception {
  const PhotoPickException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Точка интеграции выбора и загрузки фото портфолио.
///
/// Реализация выбирает фото на устройстве, загружает их в хранилище и
/// возвращает итоговые HTTPS-URL (пустой список, если пользователь отменил).
/// Ошибки лимитов и загрузки бросаются как [PhotoPickException].
abstract interface class PortfolioPhotoPicker {
  Future<List<String>> pickPhotos(
    BuildContext context, {
    required int maxCount,
  });
}

/// Выбор через `image_picker` и пакетная загрузка `POST /media/portfolio-images`.
class DevicePortfolioPhotoPicker implements PortfolioPhotoPicker {
  const DevicePortfolioPhotoPicker({
    required this.repository,
    this.picker = const ImagePickerDeviceImagePicker(),
  });

  final SocialRepository repository;
  final DeviceImagePicker picker;

  @override
  Future<List<String>> pickPhotos(
    BuildContext context, {
    required int maxCount,
  }) async {
    if (maxCount <= 0) {
      throw PhotoPickException(
        'Достигнут лимит: не больше $maxPhotosPerItem фото в одной работе',
      );
    }
    try {
      final images = await picker.pick(maxCount: maxCount);
      if (images.isEmpty) return const [];
      final problem = validateImages(images, maxCount: maxCount);
      if (problem != null) throw PhotoPickException(problem);
      final uploaded = await repository.uploadPortfolioImages(images);
      return [for (final item in uploaded) item.url];
    } on PhotoPickException {
      rethrow;
    } catch (error) {
      throw PhotoPickException(uploadErrorMessage(error));
    }
  }
}
