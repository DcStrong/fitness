## 1. Backend

- [x] 1.1 `requireEnv` (`common/util`), порт `StoragePort`, `S3StorageService`, `StorageModule`
- [x] 1.2 `MediaModule`: `POST /media/images`, `MediaService` (сигнатура, 5 МБ, ключ), `UploadedImageResponseDto`
- [x] 1.3 `@IsMediaUrl()` для `avatarUrl` / `imageUrl`; миграция `MediaUploadUrls`
- [x] 1.4 Лимиты портфолио: 5 записей (`MAX_PORTFOLIO_ITEMS`, `PORTFOLIO_LIMIT_REACHED`) и 5 фото в записи (`MAX_PHOTOS_PER_ITEM`, `PORTFOLIO_ITEM_PHOTOS_LIMIT_REACHED`), reorder ≤ 5
- [x] 1.5 Unit-тесты: media service, валидатор URL, `requireEnv`, лимит портфолио
- [x] 1.6 e2e `media.e2e-spec.ts`: загрузка, тип/размер/пустое поле, URL хранилища, лимит 5

- [x] 1.7 Пакетная загрузка `POST /media/portfolio-images` (≤5 файлов, ≤5 МБ каждый, ≤25 МБ всего, с учётом свободных мест), константы в одном месте, unit и e2e
- [x] 1.8 Перекодирование в WebP через `sharp` (ресайз, поворот по EXIF, без метаданных), `IMAGE_CORRUPT`, тесты

## 2. Инфраструктура

- [x] 2.1 `minio` + `minio-init` + volume в `docker-compose.yml` и `docker-compose.deploy.yml`
- [x] 2.2 Caddy `/files/*` → MinIO, `S3_*` в `deploy/.env.example`
- [x] 2.3 Раздел «Хранилище картинок» в `docs/deploy-test-stand.md`
- [ ] 2.4 Проверить `up` на тестовом стенде (образы MinIO не скачивались в среде разработки)

## 3. Завершение

- [ ] 3.1 Flutter-интеграция загрузки (поток D)
- [ ] 3.2 `/opsx-sync` и `/opsx-archive`, обновить `.cursor/project/docs/map.md`
