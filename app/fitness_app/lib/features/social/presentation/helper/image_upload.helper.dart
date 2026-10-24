import '../../../../core/network/api_exception.dart';
import '../../data/social_models.dart';

/// Лимиты совпадают с бэкендом (`backend/api/src/media/media.constants.ts`).
const maxImageBytes = 5 * 1024 * 1024;
const maxImagesTotalBytes = 25 * 1024 * 1024;

/// Фото в одной записи портфолио (в каждой независимо).
const maxPhotosPerItem = 5;

/// Записей (работ) в портфолио тренера.
const maxPortfolioItems = 5;

const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
const _allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

bool _isSupported(PickedImage image) {
  final mime = image.mimeType?.toLowerCase();
  if (mime != null && mime.isNotEmpty && mime != 'application/octet-stream') {
    return _allowedMimeTypes.contains(mime);
  }
  return _allowedExtensions.contains(image.extension);
}

/// Проверка до отправки: возвращает текст ошибки или `null`.
///
/// [maxCount] — сколько фото ещё можно добавить (для аватара — 1).
String? validateImages(List<PickedImage> images, {int maxCount = 1}) {
  if (images.isEmpty) return 'Выберите фото';
  if (maxCount <= 0) {
    return 'Достигнут лимит: не больше $maxPhotosPerItem фото в одной работе';
  }
  if (images.length > maxCount) {
    return 'Можно добавить не больше $maxCount фото';
  }
  for (final image in images) {
    if (image.size == 0) return 'Файл «${image.name}» пустой';
    if (!_isSupported(image)) {
      return 'Файл «${image.name}»: поддерживаются только JPEG, PNG и WebP';
    }
    if (image.size > maxImageBytes) {
      return 'Файл «${image.name}» больше 5 МБ';
    }
  }
  final total = images.fold<int>(0, (sum, image) => sum + image.size);
  if (total > maxImagesTotalBytes) {
    return 'Суммарный размер фото больше 25 МБ';
  }
  return null;
}

/// Понятный пользователю текст ошибки загрузки по коду бэкенда.
String uploadErrorMessage(Object error) {
  if (error is ApiException) {
    return switch (error.code) {
      'IMAGE_TOO_LARGE' => 'Фото больше 5 МБ',
      'IMAGES_TOTAL_TOO_LARGE' => 'Суммарный размер фото больше 25 МБ',
      'IMAGE_UNSUPPORTED_TYPE' => 'Поддерживаются только JPEG, PNG и WebP',
      'IMAGE_CORRUPT' => 'Не удалось прочитать фото, выберите другое',
      'IMAGE_EMPTY' => 'Файл пустой',
      'IMAGE_MISSING' => 'Выберите фото',
      'PORTFOLIO_LIMIT_REACHED' =>
        'Можно добавить не более $maxPortfolioItems работ',
      'PORTFOLIO_ITEM_PHOTOS_LIMIT_REACHED' =>
        'В одной работе не больше $maxPhotosPerItem фото',
      _ when error.statusCode == 413 => 'Фото слишком большое',
      _ => error.message,
    };
  }
  return 'Не удалось загрузить фото';
}
