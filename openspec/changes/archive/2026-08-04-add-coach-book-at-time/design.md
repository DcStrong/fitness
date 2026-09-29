## Context

Слой A даёт генерацию open-слотов; Слой B (`add-recurring-booking`, archived) закрепляет ученика за графиком, но материализация **только** бронирует уже существующие open-слоты и при отсутствии возвращает `missing_slot`. Coach book-for-student (`POST /sessions`) принимает только `scheduleSlotId`.

Слой C, часть 1 (этот change) снимает API-блокер: тренер может записать ученика на произвольный интервал без предварительной публикации доступности, а recurring sync молча создаёт слот при чистом `missing_slot`. Flutter UX (FAB, tap) — отдельный change.

Constraints: NestJS + TypeORM, coach-row `pessimistic_write`, half-open overlap, permissions `sessions:book_for_student` / `schedules:create`, API `localhost:3001`. Прецедент атомарного create+book уже есть в `BookingRequestsService.alternate`.

## Goals / Non-Goals

**Goals:**

- `POST /sessions` (coach): XOR `scheduleSlotId` | `{startsAt, endsAt, mode}` + `studentId`.
- Book-at-time: одна транзакция → create slot (`seriesId=null`) → Session + charge → slot `booked` (open не публикуется).
- Recurring sync: при отсутствии exact open slot и отсутствии overlap — создать слот и забронировать; summary `slotsCreated`.
- Conflict reason `mode_mismatch` отдельно от `missing_slot`.
- `POST /schedule/slots` и create-on-demand: overlap с `open`/`booked`/`blocked` → reject.

**Non-Goals:**

- Flutter UI / удаление orphan screens.
- Student BookingRequest changes, finance, packages.
- Одна транзакция на весь sync loop.
- gist EXCLUDE, groups, web.

## Decisions

### 1. Один shared path «create slot + book» в `CalendarBookingService`

Вынести из `alternate` и переиспользовать:

```text
bookExisting(slotId, ...)     — текущий путь
bookAtTime({startsAt, endsAt, mode, studentId, ...})
  lock coach
  assert no overlap with open|booked (half-open)
  create ScheduleSlot { status: open, seriesId: null, ... }
  create Session + charge (createdBy=coach)
  slot.status = booked
  return session
```

`SessionsService.bookForStudent` выбирает путь по DTO. Recurring sync вызывает тот же `bookAtTime` (или internal helper с уже вычисленным range) при auto-create.

Альтернатива — compose `POST /schedule/slots` + `POST /sessions` на клиенте. Отклонена: две транзакции, orphan open-слот, гонка с заявками.

### 2. DTO: XOR, не два независимых optional

`BookSessionDto`:

- либо `scheduleSlotId` (+ optional `studentId`, `priceMinor`);
- либо `startsAt` + `endsAt` + optional `mode` (default `offline`) + `studentId` (required for coach book-at-time).

Validation: ровно одна форма. **BREAKING** для невалидных тел с обоими полями — reject 400; существующие клиенты с одним `scheduleSlotId` без изменений.

### 3. Auto-create только для чистого `missing_slot`

В `classifyConflict` / `runSync`:

| Условие | Действие |
|---|---|
| Session already exists for `(recurringId, localDate)` | `skippedExisting` |
| Exact open + matching mode + unheld | book existing |
| Exact slot, wrong mode | conflict `mode_mismatch` (NEW; не auto-create) |
| Exact non-open | `booked_other` |
| Exact open + held | `held` |
| Any overlapping open/booked (no exact match) | `overlap` |
| No exact, no overlap | **create slot + book**; increment `slotsCreated` |

Созданный слот: `seriesId=null`, `startsAt`/`endsAt` строго из `occurrenceToUtcRange`, `mode` из серии. Generate availability потом пропустит интервал как occupied; orphan cleanup (только `seriesId === template`) не удалит.

Альтернатива — сначала `availability.generate` на горизонт. Отклонена: зависит от weekly template и не покрывает «договорились вне шаблона».

### 4. Атомарность на occurrence, не на весь sync

Каждый book / bookAtTime — своя транзакция с coach lock. Partial success сохраняется. Эфемерный lock вокруг всего цикла (как сейчас) можно убрать или оставить как soft serialization hint — не критично.

### 5. Строгий overlap в `SchedulesService.createSlot`

Сегодня: только `status = 'open'`. Стало: `status IN ('open', 'booked', 'blocked')` — константа `OCCUPIED_SLOT_STATUSES`, та же для bookAtTime. Решение на apply: **включать blocked**.

**Поведенческое ужесточение:** клиент, который раньше мог создать open поверх booked/blocked, получит 409. Это багфикс, не feature flag.

### 6. Sync summary расширяется, не ломается

```text
{ booked, skippedExisting, slotsCreated, conflicts[] }
```

`slotsCreated` ≥ 0; старые клиенты, игнорирующие поле, остаются валидны. Conflict `reason` enum + `mode_mismatch`.

## Risks / Trade-offs

- [Orphan booked slots without Session if mid-transaction fails] → одна транзакция create+book; нет промежуточного commit open.
- [Auto-create outside fixed grid confuses trainer] → `slotsCreated` в summary; Flutter UX позже покажет; доменно это «факт», не «предложение».
- [mode_mismatch still confuses if clients only handle missing_slot] → document enum; e2e asserts new reason.
- [Stricter createSlot breaks a caller that relied on open-over-booked] → unlikely intentional; treat as bugfix; cover e2e.
- [Recurring e2e that expected missing_slot must update] → rewrite to expect book or slotsCreated when no overlap.

## Migration Plan

1. Deploy backend: DTO + service + stricter createSlot + recurring sync.
2. No DB migration required (reuse `schedule_slots` / `sessions` columns).
3. Existing `scheduleSlotId` clients unchanged.
4. Rollback: revert code; no data migration. Auto-created slots remain valid booked appointments.

## Open Questions

- ~~Включать ли `blocked` в overlap check для createSlot / bookAtTime?~~ **Решено на apply: да** — `OCCUPIED_SLOT_STATUSES = open|booked|blocked`.
- Нужен ли отдельный HTTP path `POST /sessions/book-at-time` вместо XOR на `POST /sessions`? Рекомендация: **XOR на существующем** — меньше surface, один permission.
