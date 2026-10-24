import 'package:image_picker/image_picker.dart';

import 'social_models.dart';

/// Выбор фото на устройстве (галерея / файловый диалог в вебе).
abstract interface class DeviceImagePicker {
  /// Возвращает до [maxCount] фото; пустой список — пользователь отменил выбор.
  Future<List<PickedImage>> pick({int maxCount = 1});
}

class ImagePickerDeviceImagePicker implements DeviceImagePicker {
  const ImagePickerDeviceImagePicker();

  @override
  Future<List<PickedImage>> pick({int maxCount = 1}) async {
    final picker = ImagePicker();
    final List<XFile> files;
    if (maxCount <= 1) {
      final file = await picker.pickImage(source: ImageSource.gallery);
      files = [?file];
    } else {
      // `limit` на вебе игнорируется, поэтому обрезаем сами.
      files = (await picker.pickMultiImage(
        limit: maxCount,
      )).take(maxCount).toList();
    }
    return [
      for (final file in files)
        PickedImage(
          name: file.name,
          bytes: await file.readAsBytes(),
          mimeType: file.mimeType,
        ),
    ];
  }
}
