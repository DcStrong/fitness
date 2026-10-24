import 'package:flutter/widgets.dart';

/// Точка интеграции выбора и загрузки фото портфолио.
///
/// Реализация выбирает фото на устройстве, загружает его в хранилище
/// и возвращает итоговый HTTPS-URL (или `null`, если пользователь отменил).
abstract interface class PortfolioPhotoPicker {
  Future<String?> pickPhoto(BuildContext context);
}

/// Заглушка до подключения реальной загрузки: ничего не выбирает.
class StubPortfolioPhotoPicker implements PortfolioPhotoPicker {
  const StubPortfolioPhotoPicker();

  @override
  Future<String?> pickPhoto(BuildContext context) async => null;
}
