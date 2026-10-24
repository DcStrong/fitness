# Mobile (Flutter)

## Зафиксировано

| Тема | Выбор |
|------|--------|
| State | **Bloc / Cubit** (`flutter_bloc`) — не Riverpod |
| Routing | `go_router` |
| HTTP | `dio` |
| Tokens | `flutter_secure_storage` |
| App path | `app/fitness_app/` |

## API base URL

Передаётся через `--dart-define=API_BASE_URL=...` (`lib/core/config/api_config.dart`).

| Среда | Значение |
|-------|----------|
| По умолчанию / iOS Simulator / desktop | `http://localhost:3001` |
| Android Emulator | `http://10.0.2.2:3001` |

Примеры:

```bash
cd app/fitness_app
flutter run --dart-define=API_BASE_URL=http://localhost:3001
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

## Deep links (приглашения)

Ссылку формирует бэкенд (`INVITE_HTTPS_BASE`), клиент разбирает её в `lib/core/config/invite_links.dart`, входящие ссылки на мобильных ловит `lib/app/router/invite_deep_links.dart` (`app_links`).

| Тип | Формат |
|-----|--------|
| HTTPS (в QR) | `https://<APP_HOST>/i/<token>`; локально `http://localhost:8080/i/<token>` |
| App scheme | `fitnessyoda://invite/<token>` |
| In-app route | `/i/<token>` (или `/invite/accept?token=<token>`) |

App Links / Universal Links и плейсхолдеры подписи: `docs/deploy-test-stand.md`, раздел «Ссылки-приглашения».

## Cursor skills (project)

После `./.cursor/activate.sh` доступны:

1. **`flutter-bloc-feature`** — фича с Bloc, Page/View (на базе практик [VGV bloc skill](https://github.com/VeryGoodOpenSource/very_good_ai_flutter_plugin/blob/main/skills/bloc/SKILL.md), ужато под проект)
2. **`flutter-api-client`** — Dio + JWT refresh под Nest API
3. **`flutter-auth-shell`** — login/register/me + go_router redirects

Готовые огромные «starter packs» с GitHub (freezed+hive+get_it+clean arch на 600 строк) **не копировали** — они конфликтуют с тонким MVP. При необходимости можно точечно заимствовать паттерны из VGV / flutter/skills.

## Postgres MCP

Не подключаем: хватает TypeORM migrations + seed.
