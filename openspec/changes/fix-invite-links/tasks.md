## 1. Backend
- [x] 1.1 `inviteUrl` из `INVITE_HTTPS_BASE`, дефолт `http://localhost:8080`; unit-тесты
- [x] 1.2 `INVITE_HTTPS_BASE` в `docker-compose.deploy.yml`, `backend/api/.env.example`

## 2. Deploy
- [x] 2.1 Caddy: SPA fallback `/i/*`, `/.well-known/assetlinks.json`, `apple-app-site-association`
- [x] 2.2 Шаблоны `deploy/well-known/*` с плейсхолдерами

## 3. Flutter
- [x] 3.1 `usePathUrlStrategy`
- [x] 3.2 Redirect `/i/<token>` (гость → сохранить токен → вход), авто-принятие
- [x] 3.3 `app_links`, Android intent-filters, iOS URL type + Associated Domains
- [x] 3.4 Тесты `inviteRouteForUri`, очистка отклонённого токена

## 4. Docs / проверка
- [x] 4.1 Документация (`docs/deploy-test-stand.md`, `docs/domain/invitations.md`, `docs/mobile/tooling.md`)
- [x] 4.2 Живая проверка web-цепочки локально
- [ ] 4.3 Проверка App Links / Universal Links на реальных устройствах и домене стенда
