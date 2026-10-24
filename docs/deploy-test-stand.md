# Тестовый веб-стенд: пошаговая инструкция

Цель: ссылка, которую можно открыть с телефона. Не production.

## Нужен ли VDS?
Не обязателен, но для вашего случая это лучший вариант. Сравнение (цены на 23.10.2026, проверяйте на сайтах):

| Вариант | Цена | Плюсы | Минусы |
|---|---|---|---|
| **Маленький VDS + docker compose + Caddy** (рекомендуем) | от ~150–500 ₽/мес (hostinghub: VDSina 1 ГБ 150 ₽, Selectel 200 ₽, aeza SWE 4 ГБ ~187 ₽ по акции, Timeweb Cloud 530 ₽) | Всё работает постоянно, WebSocket чата ок, данные не пропадают, оплата российскими способами у российских провайдеров | Один раз настроить сервер (~30 мин) |
| Render free (PaaS) | 0 ₽ | Без сервера | Засыпает через 15 мин без трафика (пробуждение ~1 мин), бесплатная БД удаляется через 30 дней (+14 дней grace), диск временный; оплата/карта из РФ сложна |
| Свой компьютер + туннель (Cloudflare Tunnel) | 0 ₽ | Быстро | Работает, только пока включён компьютер |

Рекомендация: VDS в РФ (или с оплатой, доступной вам), **минимум 2 ГБ ОЗУ** (сборка Flutter web ресурсоёмкая; при 1 ГБ добавьте swap, см. ниже), Ubuntu 22.04/24.04.

## Шаги
1. **Купите VDS** (Ubuntu, 2 ГБ+ ОЗУ). Получите IP-адрес и доступ по SSH (логин root и пароль приходят на почту).
2. **Адрес без покупки домена.** Если IP, например, `203.0.113.10`, то адреса будут:
   `app.203-0-113-10.sslip.io` (приложение) и `api.203-0-113-10.sslip.io` (сервер). HTTPS-сертификаты получатся сами. Свой домен тоже можно: создайте две A-записи на IP.
3. Подключитесь: `ssh root@IP`. Установите Docker:
   `curl -fsSL https://get.docker.com | sh`
   (если 1 ГБ ОЗУ: `fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile`)
4. Скачайте проект: `git clone https://github.com/DcStrong/fitness.git && cd fitness`
5. Создайте настройки: `cp deploy/.env.example .env && nano .env`. Впишите адреса из шага 2 и пароли: для `POSTGRES_PASSWORD`, `S3_SECRET_KEY`, `JWT_ACCESS_SECRET` и `JWT_REFRESH_SECRET` придумайте разные случайные строки командой `openssl rand -hex 32` (подробнее про базу — раздел «База данных» ниже). У каждой переменной в файле есть комментарий. Заполните `ADMIN_EMAIL` и `ADMIN_PASSWORD`, если нужен админ. Файл `.env` никому не отправляйте.
6. Запустите: `docker compose -f docker-compose.deploy.yml up -d --build` (первая сборка 10–20 минут).
   Миграции и начальные данные (`db:seed`) выполняются автоматически при старте API.
7. Откройте `https://app.<ваш-адрес>` на телефоне. Войдите или зарегистрируйтесь и раздайте ссылку знакомым.

## Полезное
- Логи: `docker compose -f docker-compose.deploy.yml logs -f api`
- Обновить до новой версии: `git pull && docker compose -f docker-compose.deploy.yml up -d --build`
- **После обновления до версии со ссылками-приглашениями** в `.env` ничего добавлять не обязательно: `INVITE_HTTPS_BASE` по умолчанию берётся как `https://<APP_HOST>`. Нужны `up -d --build` (пересобираются `api` и `web`: новый Caddyfile и Flutter с path-ссылками). Чтобы задать другой адрес — добавьте в `.env` `INVITE_HTTPS_BASE=https://app.149.154.64.173.sslip.io` (без `/i` и без завершающего `/`).
- Остановить: `docker compose -f docker-compose.deploy.yml down` (данные сохраняются; `down -v` удалит их).
- Если сертификат не выдался: проверьте, что порты 80 и 443 открыты у провайдера, а адреса из `.env` открываются.
- Сделать сайт доступным только знакомым: на тестовом стенде CORS открыт для всех; для production его нужно сузить.
- Веб-консоль тренера (`web_app`, Next.js) в стенд не входит, при необходимости добавим отдельным шагом.

## База данных (Postgres)
- **Ставить Postgres на сервер не нужно.** Он запускается сам в контейнере `postgres` из `docker-compose.deploy.yml` вместе с остальным (`up -d --build`). API подключается к нему по внутренней сети Docker; наружу порт базы не открыт.
- **`POSTGRES_PASSWORD`** — пароль к этой базе, его придумываете вы сами. Сгенерировать: `openssl rand -hex 16` (получится строка из букв и цифр; спецсимволы вроде `@ : / #` не используйте, пароль входит в адрес подключения). Вписывать его больше никуда не надо, только в `.env`. Пользователь `postgres` и база `fitness_yoda` создаются автоматически.
- **Не меняйте пароль после первого запуска.** Пароль записывается в базу только при её первом создании. Если поменять его в `.env` позже, API перестанет подключаться (в логах `password authentication failed`). Чтобы сменить, пересоздайте базу: `docker compose -f docker-compose.deploy.yml down -v`, поправьте `.env`, снова `up -d --build`. **Все данные при этом удалятся** (пользователи, записи, чаты; админ и начальные данные создаются заново автоматически).
- **Где хранятся данные:** в Docker-томе `pgdata` на сервере (обычно `/var/lib/docker/volumes/<папка проекта>_pgdata`). Переживает перезапуск и `down`; удаляется только `down -v`.
- **Бэкап:** `docker compose -f docker-compose.deploy.yml exec -T postgres pg_dump -U postgres fitness_yoda > backup.sql`
- **Восстановить из бэкапа** (в запущенный стенд): `docker compose -f docker-compose.deploy.yml exec -T postgres psql -U postgres fitness_yoda < backup.sql` (лучше сначала сбросить базу, как ниже, иначе будут ошибки «уже существует»).
- **Сбросить базу с нуля:** `docker compose -f docker-compose.deploy.yml down -v && docker compose -f docker-compose.deploy.yml up -d --build`. Миграции и начальные данные применятся заново. Заодно сотрутся и сертификаты Caddy (`caddy_data`), они выдадутся снова.

## Хранилище картинок (MinIO)
- Аватары и фото портфолио загружаются через `POST /media/images` и лежат в **MinIO** — S3-совместимом хранилище в контейнере `minio` (ставить ничего не нужно). Одноразовый контейнер `minio-init` создаёт бакет `media` и включает анонимное **чтение**; писать может только API по ключу `S3_ACCESS_KEY`/`S3_SECRET_KEY`.
- **Адреса:** MinIO наружу не открыт. Картинки отдаёт Caddy по `https://<API_HOST>/files/media/images/<id пользователя>/<файл>`; этот адрес API сам подставляет в `avatarUrl`/`imageUrl` (переменная `S3_PUBLIC_URL` задаётся в `docker-compose.deploy.yml`).
- **Образ MinIO.** С октября 2025 MinIO не публикует образы на Docker Hub. В compose по умолчанию стоит последний community-релиз из `quay.io/minio/minio` (имена образов задаются `MINIO_IMAGE` и `MINIO_MC_IMAGE` в `.env`). Если `up` не может скачать образ — соберите свой из исходников MinIO или возьмите зеркало и впишите его в `.env`. Код API от конкретного хранилища не зависит (порт `StoragePort`, любой S3-совместимый сервер).
- **`S3_SECRET_KEY`** — придумайте сами (`openssl rand -hex 16`, только буквы и цифры). Как и пароль Postgres, он записывается при первом создании `miniodata`; позже менять нельзя без сброса тома.
- **Где данные:** Docker-том `miniodata` (`/var/lib/docker/volumes/<папка проекта>_miniodata`). Переживает перезапуск и `down`; удаляется `down -v`.
- **Бэкап:** `docker run --rm -v <папка проекта>_miniodata:/data -v "$PWD":/backup alpine tar czf /backup/minio-backup.tgz -C /data .` (имя тома смотрите в `docker volume ls`). Восстановление — обратная распаковка в пустой том при остановленном `minio`. Делайте бэкап вместе с `pg_dump`: в базе лежат только ссылки.
- **Лимиты:** до 5 МБ на файл, только JPEG/PNG/WebP (проверяется по содержимому); при сохранении всё перекодируется в WebP (аватар до 512 px, фото портфолио до 1600 px, метаданные удаляются); до 5 фото в портфолио тренера.
- **Локальная разработка:** `docker compose up -d` поднимает Postgres и MinIO (консоль http://localhost:9001, `minioadmin`/`minioadmin`). В `backend/api/.env` задайте: `S3_ENDPOINT=http://localhost:9000`, `S3_BUCKET=media`, `S3_ACCESS_KEY=minioadmin`, `S3_SECRET_KEY=minioadmin`, `S3_PUBLIC_URL=http://localhost:9000/media`. Без этих переменных API стартует, а загрузка вернёт 503 `STORAGE_NOT_CONFIGURED`.

## Производительность Flutter web

Flutter web рисует всё на canvas (CanvasKit) и не равен нативному приложению: на слабых телефонах и в Safari будет заметно медленнее, ввод текста идёт через скрытый `<input>`. Для настоящей оценки плавности собирайте APK/iOS. Что уже сделано на стенде: release-сборка, CanvasKit раздаётся с нашего сервера (`--no-web-resources-cdn`), Caddy сжимает zstd/gzip и кеширует тяжёлые ассеты, картинки карточек главной уменьшены до 640 px (webp).

## Ссылки-приглашения (QR) и открытие приложения
- **Ссылка:** `https://<APP_HOST>/i/<token>` (для стенда `https://app.149.154.64.173.sslip.io/i/<token>`). API строит её из `INVITE_HTTPS_BASE`; в `docker-compose.deploy.yml` она по умолчанию равна `https://${APP_HOST}`. Локально: `http://localhost:8080/i/<token>` (`backend/api/.env.example`, веб на `--web-port 8080`).
- **Веб:** Flutter использует path-ссылки (без `#`), Caddy на любой путь без файла отдаёт `index.html`, поэтому `/i/<token>` открывается напрямую и из QR. Гость попадает на вход/регистрацию, токен запоминается и принимается после входа; вошедший ученик принимает приглашение сразу.
- **Мобильное приложение вместо веба** (Android App Links / iOS Universal Links). Caddy отдаёт `/.well-known/assetlinks.json` и `/.well-known/apple-app-site-association` из `deploy/well-known/`. В репозитории **плейсхолдеры, их нужно заполнить вам**:
  - `deploy/well-known/assetlinks.json`: `REPLACE_WITH_RELEASE_SHA256_CERT_FINGERPRINT` → SHA-256 отпечаток ключа подписи приложения (`keytool -list -v -keystore <keystore>` или Play Console → App signing). `package_name` сейчас `com.example.fitness_app` (как в `build.gradle`); при смене applicationId обновите и здесь.
  - `deploy/well-known/apple-app-site-association`: `REPLACE_WITH_APPLE_TEAM_ID` → Apple Team ID (developer.apple.com → Membership). Bundle ID: `com.dcstrong.fitnessApp`.
  - Хост стенда прописан в `android/app/src/main/AndroidManifest.xml` (intent-filter `autoVerify`) и `ios/Runner/Runner.entitlements` (`applinks:`); при другом `APP_HOST` замените его там.
  - После правки файлов: `up -d --build`, затем проверка `curl -i https://<APP_HOST>/.well-known/assetlinks.json` (ответ `200`, `application/json`). Без подписи/Team ID верификация не пройдёт, и ссылка откроется в браузере (веб-версия): это ожидаемый запасной вариант.
- **Запасной вариант:** кастомная схема `fitnessyoda://invite/<token>` (`INVITE_SCHEME_BASE`) работает без верификации домена, если приложение установлено.
- **Не проверено без реальных устройств и домена:** App Links / Universal Links, запуск приложения из QR камерой.
