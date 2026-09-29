## Why

Запись на занятие уже создаёт `Session` в статусе `booked`, но продукт неполный без **lifecycle**: отметить проведённым / отменить / no-show и зафиксировать это в **истории**. Это фаза 5 roadmap и следующий слой поверх `docs/architecture/calendar.md` (Session → History).

## What Changes

- API переходов статуса сессии: `booked → completed | cancelled | no_show` с проверкой прав и ролей (coach/student where appropriate).
- Запись **history events** на каждый значимый переход (кто, когда, from→to, опциональный комментарий).
- List history для участников сессии (и/или фильтр по своей истории).
- Permissions + seed для lifecycle/history.
- Flutter: действия на экране тренировок + простой просмотр истории (RU).
- Обновить `docs/architecture/calendar.md` в части фазы 5 (что реализовано / что ещё out of scope).

## Non-goals

- Invoices / billing, push/email уведомления.
- Reschedule (перенос на другой слот) — только cancel + новый book при необходимости.
- Recurrence, groups, gym UI.
- Возврат слота в `open` при cancel (политика: зафиксировать явно в design; MVP может **не** освобождать слот автоматически, чтобы не усложнять).
- Web / Next.js.
- Редактирование прошлого history event (append-only).

## Capabilities

### New Capabilities

- `session-lifecycle`: правила и API смены статуса session (`complete` / `cancel` / `no_show`).
- `session-history`: append-only события истории по session (и list).
- `mobile-session-lifecycle`: Flutter UI переходов и просмотра истории.

### Modified Capabilities

- `sessions-api`: снять «booked-only»; list может фильтровать по статусу.
- `calendar-domain`: зафиксировать допустимые переходы и связь Session ↔ HistoryEvent.
- `access-control`: permissions `sessions:complete`, `sessions:cancel`, `sessions:mark_no_show`, `sessions:read_history` (или эквивалентный минимальный набор).
- `mobile-app-shell`: маршруты/entry points к истории при необходимости.

## Impact

- Backend: `sessions` (+ optional thin history module), TypeORM entity/migration `session_history_events` (или аналог), permissions seed.
- Mobile: экраны sessions list / detail actions.
- Docs: calendar architecture phase 5 notes.
- Порядок: **backend lifecycle + history → Flutter**.
