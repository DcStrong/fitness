## Why

Аватар и фото портфолио сейчас принимаются только как внешняя https-ссылка; тренер не может загрузить фото с телефона. Портфолио ограничено 20 элементами, что избыточно для карточки тренера. Нужны загрузка файлов в собственное хранилище и лимит «до 5 фото». Источник: `docs/plans/trainer-profile-polish.md` (п. 3–4).

## What Changes

- Новый модуль `media`: `POST /media/images` (multipart, поле `file`) для аватара и фото портфолио; JPEG/PNG/WebP, до 5 МБ, тип по сигнатуре файла, ключ `images/<userId>/<uuid>.<ext>`, ответ `{ url, contentType, size }`.
- Порт `StoragePort` (`put`, `isOwnUrl`) и реализация `S3StorageService` (MinIO/S3 через `@aws-sdk/client-s3`, конфиг `S3_*` через `requireEnv`, читается лениво).
- `avatarUrl` / `imageUrl`: допустимы URL нашего хранилища (в dev — http) и любые внешние https-ссылки (обратная совместимость, существующие данные не трогаем).
- Портфолио: два независимых лимита — максимум **5 записей** (работ) на тренера (было 20; шестая → `409 PORTFOLIO_LIMIT_REACHED`) и максимум **5 фото в каждой записи** (шестое → `409 PORTFOLIO_ITEM_PHOTOS_LIMIT_REACHED`); общего лимита фото на портфолио нет. Минимума нет, на публикацию профиля не влияет. Reorder принимает не более 5 id.
- Миграция: CHECK на `user_profiles.avatar_url` / `trainer_portfolio_items.image_url` допускает `http://` и `https://`.
- Деплой: сервис `minio` + volume `miniodata` + `minio-init` (бакет, анонимное чтение), раздача через Caddy `https://API_HOST/files/<bucket>/…`; обновлена `docs/deploy-test-stand.md`.

## Capabilities

### New Capabilities
- `media-upload`: загрузка изображений в хранилище.

### Modified Capabilities
- `trainer-portfolio`: лимит 5 и загрузка файлов вместо только HTTPS-URL.
- `profile-privacy`: `avatarUrl` может быть адресом нашего хранилища.

## Impact

- `backend/api/src/{media,storage,common/util,social}`, миграция `1755500000000-MediaUploadUrls`, `test/media.e2e-spec.ts`.
- `docker-compose.yml`, `docker-compose.deploy.yml`, `deploy/Caddyfile`, `deploy/.env.example`, `docs/deploy-test-stand.md`.
- Flutter (отдельный поток D) использует `POST /media/images` и подставляет `url` в `avatarUrl` / `imageUrl`.
- Существующие тренеры с >5 элементами сохраняют их; лимит действует на создание новых.
