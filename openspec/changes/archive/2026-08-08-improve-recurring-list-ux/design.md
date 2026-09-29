# Design: improve-recurring-list-ux

## Context

Часть списка/навигации/anti-duplicate уже в коде (`studentDisplayName`/`studentEmail`, create 409 + reactivate twin, entry points). Остаётся дельта: **дата ближайшего занятия**, **relative labels**, явный **restore из архива**.

Стек: Nest `RecurringBookingsService` + Flutter list/detail/create. Occurrence math уже есть в `expandDesiredOccurrences`.

## Goals / Non-Goals

**Goals:**
- Active-карточка показывает ближайшее занятие (дата + время), не только «создана»
- Единый relative-формат дат в recurring UI: сегодня / завтра / вчера / `DD.MM.YY`
- Явный restore cancelled → active + sync из архива/detail
- Create-reactivate и pattern-409 остаются как идемпотентность create

**Non-Goals:**
- One-shot SQL cleanup старых active-дублей (опционально вручную)
- 5-й shell-таб; overwrite чужих конфликтов; merge разных паттернов одного ученика
- Показ полного календаря occurrences в списке (только next)

## Decisions

1. **`nextOccurrenceLocalDate` на API** — считать на сервере при `toModel`/`toModels` через существующий `expandDesiredOccurrences` (горизонт settings / `horizonWeeksOverride`, timezone серии, skip overrides). Берём min future `localDate` после «сегодня» в TZ серии (если сегодня ещё не прошло по `startMinute` — сегодня допустима). Cancelled → `null`.  
   *Alt:* считать на клиенте — отвергнуто (дублирование TZ/overrides).

2. **`POST /recurring-bookings/:id/restore`** — тот же permission, что create/cancel (`sessions:book_for_student`). Тело пустое; ответ `{ booking, sync }` как create. Shared private `reactivate(entity)` с create-twin path. Conflict с другим active pattern → 409 + `existingId`. Active restore → 409/400 «already active».  
   *Alt:* только create-reactivate без endpoint — отвергнуто (нет UX «Восстановить» на архивной карточке без пересоздания формы).

3. **Relative labels во Flutter** — helper `formatRelativeCalendarDate` (рядом с `schedule_format.dart`): сравнение calendar-day в **локальном устройстве**; вход — `DateTime` или ISO date/datetime. Created/cancelled: парсить ISO → local day. Next occurrence: `YYYY-MM-DD` как calendar date без TZ shift. Format far: `DD.MM.YY`.

4. **UI карточки** — active primary meta: `«ближайшее: {label} · {HH:mm}»` (или без префикса, если тесно); secondary: `создана {label}`. Archive: `отменена {label}` + action «Восстановить» на detail (и опционально trailing/кнопка на list item — минимум detail). После restore: snackbar, перейти на active detail или `go` list active.

5. **Student title** — без изменений (name → email → short id); на скрине `09427d4b` = fallback id при пустом profile/email в ответе (проверить enrichment после API restart).

## Risks / Trade-offs

- [Next null при пустом горизонте] → UI показывает только паттерн дней/времени без «ближайшее»
- [Restore + уже active twin] → 409 + navigate to existing (как create)
- [List N+1 sync cost] → next occurrence pure compute, без DB sync; batch student enrichment уже есть
- [Device TZ vs series TZ for «сегодня»] → relative labels по device local; next date string from server TZ — осознанный UX trade-off (дата занятия как в TZ серии)

## Migration Plan

- Deploy API (новые поля + restore) до/вместе с приложением
- Старые клиенты игнорируют новые поля; restore только в новом UI
- Rollback: endpoint unused; nullable field harmless

## Open Questions

- Нет блокирующих; list-level restore button vs detail-only — default: **detail + archive list secondary action** если просто
