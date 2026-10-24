## Why

QR и ссылка приглашения вели на несуществующий домен `https://app.fitness-yoda.local/i/<token>`, поэтому связать тренера и ученика было невозможно. Ссылка должна вести на реальный адрес веб-приложения и открывать приложение (или веб), если оно установлено.

## What Changes

- Бэкенд строит `inviteUrl` из `INVITE_HTTPS_BASE` (origin веб-приложения, дефолт `http://localhost:8080`); в compose-деплое база = `https://${APP_HOST}`.
- Flutter web переходит на path-стратегию URL; Caddy отдаёт `index.html` на `/i/*` (SPA fallback) и файлы верификации `/.well-known/assetlinks.json`, `/.well-known/apple-app-site-association`.
- Маршрут `/i/<token>`: гость сохраняет токен и идёт на вход/регистрацию, после входа токен принимается автоматически; вошедший ученик принимает сразу. Отклонённый сервером токен очищается.
- Мобильное приложение обрабатывает входящие ссылки (Android App Links, iOS Universal Links, `fitnessyoda://invite/<token>`) через `app_links`.

## Impact

- `backend/api/src/invitations`, `docker-compose.deploy.yml`, `deploy/Caddyfile`, `deploy/web/Dockerfile`, `deploy/well-known/*`.
- `app/fitness_app`: `main.dart`, `app_router.dart`, `invite_deep_links.dart`, Android/iOS конфигурация.
- Операторы стенда: после обновления пересобрать `web` и `api`; Android SHA-256 и Apple Team ID вписать в `deploy/well-known/*` (см. `docs/deploy-test-stand.md`).
