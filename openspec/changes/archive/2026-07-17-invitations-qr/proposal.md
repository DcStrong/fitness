## Why

Auth и mobile shell уже работают, но тренер не может привести ученика в систему без «поиска». QR-приглашение — основной способ связать trainer↔student (фаза 3 roadmap) и разблокировать запись на занятия.

## What Changes

- Backend (TypeORM): сущность `Invitation` + связь coach–student после accept.
- API: создать / список / отозвать (trainer); принять (student или authenticated user с нужным permission).
- Новые permission codes + seed для ролей `trainer` / `student`.
- Mobile: экран тренера «Пригласить» (QR + копирование ссылки); поток студента scan/open deep link → accept → home с контекстом связи.
- Deep link placeholder в design (`fitnessyoda://invite/<token>` + HTTPS fallback host).

## Non-goals

- Web / Next.js.
- NFC, barcode, Fastag и прочие codec-носители (только QR + deep link URL).
- Push / email уведомления об приглашении.
- Регистрация «сквозь» QR без отдельного login/register (студент должен быть авторизован или пройти auth shell, затем accept).
- Календарь, занятия, планы, биллинг.
- Production App Store deep-link domain / Universal Links verification (только placeholder).

## Capabilities

### New Capabilities

- `invitations-api`: серверные приглашения, токены, статусы, accept → связь trainer↔student.
- `coach-student-link`: устойчивая связь coach–student после принятия приглашения (для будущих sessions).
- `mobile-invitations`: Flutter UI/flows для создания QR и принятия приглашения.

### Modified Capabilities

- `access-control`: добавить permissions для create/list/revoke/accept invitations (и чтения своих связей).
- `mobile-app-shell`: новые маршруты (`/invite`, `/invite/accept`) и вход в поток с home.

## Impact

- Backend: `backend/api` — entities/migrations/seed, module `invitations`, permissions constants.
- Mobile: `app/fitness_app` — feature `invitations`, QR package, deep link handling, copy-to-clipboard.
- Docs: `docs/domain/invitations.md`, `docs/roadmap/plan.md` (фаза 3).
- Порядок реализации: **backend first**, затем Flutter.
