## Decisions

- `INVITE_HTTPS_BASE` — origin веб-приложения без `/i`; сервис добавляет `/i/<token>` (старое значение с суффиксом `/i` тоже работает). Отдельной настройки на VDS не нужно: compose выводит её из `APP_HOST`, при необходимости переопределяется в `.env`.
- Path-стратегия (`usePathUrlStrategy`) вместо `#/`: App/Universal Links не умеют hash-фрагменты, а QR-сканер должен открывать чистый URL.
- Входящие ссылки на мобильных обрабатывает `app_links`; встроенный deep linking Flutter отключён (`flutter_deeplinking_enabled=false`, `FlutterDeepLinkingEnabled=false`), чтобы обе схемы (https и `fitnessyoda://invite/...`) шли одним путём: `inviteRouteForUri` → `/i/<token>` → общий redirect.
- Токен для гостя хранится в `shared_preferences` (`pending_invite_token`) и применяется после входа/регистрации.
- Значения, которых нет в репозитории (SHA-256 ключа подписи Android, Apple Team ID, хост стенда в манифесте/entitlements), оставлены явными плейсхолдерами/значением стенда; не выдуманы.
