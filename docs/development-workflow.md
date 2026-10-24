# Ветки и локальная разработка

## Ветки

| Ветка | Что отражает |
|-------|--------------|
| `main` | Ровно то, что сейчас залито на VDS (тестовый стенд). |
| `dev` | Локальный запуск, тестирование, доработки. Создаётся от `main`. |

Правила:

- Новые MR создаются из `dev` (или цепочкой из ветки, от которой зависят) и вливаются в `dev`.
- Перед тем как что-то попадёт в `main`: `dev` собран и проверен локально (бэк, миграции, web).
- В `main` попадает только проверенный `dev`. После слияния обновляем VDS (см. ниже).

## Локальный запуск

```bash
# 1. Postgres и MinIO (хранилище картинок)
docker compose up -d postgres minio minio-init

# 2. API
cd backend/api
cp ../.env.example .env        # один раз; дополните S3_* (см. docs/deploy-test-stand.md, «Локальная разработка»)
npm install
npm run migration:run
npm run start:dev              # http://localhost:3001/health

# 3. Web (Flutter) в debug-режиме, с DevTools и hot reload
cd ../../app/fitness_app
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:3001
```

В консоли `flutter run` печатается ссылка на DevTools (`The Flutter DevTools debugger and profiler on Chrome is available at: …`). Горячие клавиши: `r` — hot reload, `R` — hot restart, `q` — выход. Release-сборку для проверки как на проде: `flutter build web --release --dart-define=API_BASE_URL=http://localhost:3001`, затем `python3 -m http.server 8080` из `build/web`.

Если `quay.io` недоступен (ответ 401 при `docker pull`), поднимите MinIO из зеркала на Docker Hub:

```bash
docker run -d --name fitness_yoda_minio --restart unless-stopped \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=minioadmin123 \
  -e MINIO_DEFAULT_BUCKETS=media:download \
  -v fitness_yoda_minio:/bitnami/minio/data bitnamilegacy/minio:latest
```

и в `backend/api/.env`: `S3_ENDPOINT=http://localhost:9000`, `S3_BUCKET=media`, `S3_ACCESS_KEY=minioadmin`, `S3_SECRET_KEY=minioadmin123`, `S3_PUBLIC_URL=http://localhost:9000/media`.

## Обновление VDS после слияния в `main`

Если новых компонентов не появилось, как раньше:

```bash
git pull && docker compose -f docker-compose.deploy.yml up -d --build
```

Если добавились компоненты или переменные, перед этой командой сделайте шаги из таблицы ниже.

| Изменение в `dev` | Что сделать на VDS перед `git pull && … up -d --build` |
|-------------------|---------------------------------------------------------|
| **MinIO + загрузка фото** (`add-media-upload`) | Добавить в `.env` на VDS переменные из `deploy/.env.example`: `S3_SECRET_KEY` (`openssl rand -hex 16`, только буквы и цифры, после первого запуска не менять), `S3_BUCKET`, `S3_ACCESS_KEY`, а также `MINIO_IMAGE` / `MINIO_MC_IMAGE`, если `quay.io` недоступен. Новый Caddyfile (маршрут `/files/*`) подхватится при пересборке. Бэкап тома `miniodata` — см. `docs/deploy-test-stand.md`. |
| **Залы тренера** (`add-trainer-gyms`) | Ничего нового в окружении; миграция `TrainerGyms` применяется при старте API. Перед обновлением сделайте `pg_dump`. |

Проверка после обновления: `curl https://<API_HOST>/health`, затем загрузка фото в профиле тренера.
