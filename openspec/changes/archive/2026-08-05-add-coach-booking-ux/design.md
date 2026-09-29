## Context

`add-coach-book-at-time` расширяет API: coach может `POST /sessions` с time range (атомарный create+book) и recurring sync автосоздаёт слоты при чистом miss. Flutter сегодня:

- `_onEventTap` открывает только заявки (`requestId`); open-слот и session — no-op;
- FAB только «Свободное время»;
- AppBar TextButton «Регулярный график» → `/schedule/recurring` (путается с «Доступность»);
- `CoachBookForStudentScreen` / `CoachSlotsScreen` — маршруты без UI-входа;
- recurring create не показывает `horizonWeeksOverride`; summary без `slotsCreated`.

Этот change — только mobile UX. Backend не трогаем. Зависимость: API change должен быть применён (или mockable контракт готов).

Constraints: Bloc/Cubit only, Russian copy, `Fy*` widgets, go_router shell, API `localhost:3001`.

## Goals / Non-Goals

**Goals:**

- Тренер записывает ученика из календаря (слот или пустое время) за ≤3 тапа до формы.
- Один FAB «+» с тремя ясными действиями (ученик / регулярные / свободное время).
- Book-at-time UI вызывает новый API когда слота нет.
- Recurring entry + горизонт + прозрачность `slotsCreated` / `mode_mismatch`.
- Убрать dead routes или явно переиспользовать их.

**Non-Goals:**

- Backend, student flows, design-system debt (шрифт/dark), week drag-and-drop.

## Decisions

### 1. Compose sheet вместо разрозненных экранов

`ScheduleCreateActionsSheet` (modal bottom sheet) с тремя `ListTile`/`FyCard` rows:

| Label | Action |
|---|---|
| Записать ученика | push/open `CoachBookStudentFlow` (prefill date/time/slotId) |
| Регулярные тренировки | `push /schedule/recurring` (list; create via FAB там) |
| Свободное время | existing `FreeTimeSheet` (prefill date/time if from empty tap) |

Источник вызова: calendar FAB «+»; optional same sheet from empty-hour tap with fewer rows (без «Регулярные» optional — лучше оставить все три для consistency).

Альтернатива — четвёртая вкладка «Записи». Отклонена (пользователь выбрал FAB menu).

### 2. Slot vs empty-time prefill

```text
tap availability event
  → SlotActionsSheet:
      Записать ученика (slotId known → book existing)
      Записать регулярно (optional: prefill weekday+time)
      Изменить / Удалить (delete open unheld via existing API)

tap empty hour row (day timeline)
  → BookStudentFlow prefilled startsAt = selectedDate + hour
     duration from CoachScheduleSettings (fallback 60)
     mode default offline
     → POST /sessions { startsAt, endsAt, mode, studentId }

tap session event
  → Session detail / history (minimal: push existing sessions history if available; else no-op → prefer open session detail if route exists)
```

Если session detail route слаб — минимум SnackBar «Тренировка» + переход в `/sessions` later; не блокировать change.

### 3. Coach book student flow

Переиспользовать/рефакторить `CoachBookForStudentScreen` в sheet-friendly flow:

1. Linked students (InvitationsRepository relationships, role coach).
2. Confirm time (read-only if from slot; editable if from empty/FAB).
3. Mode (locked to slot mode if slot; else segmented).
4. Optional price dialog (как сейчас).
5. Repository: `book(scheduleSlotId:…)` **или** `bookAtTime(startsAt, endsAt, mode, studentId)`.

Расширить `ScheduleRepository.book` / добавить `bookAtTime`.

### 4. FAB replacement

Заменить `FloatingActionButton.extended` «Свободное время» на FAB «+» (icon-only или «Добавить»). AppBar action «Регулярный график» **удалить**.

Free time остаётся доступным через sheet → FreeTimeSheet (spec mobile-calendar-views MODIFIED).

### 5. Recurring UX tweaks

- Create form: `FyInputCard` «Горизонт (недель)» 1–52, default = settings.horizonWeeks (load settings once) или 8; pass `horizonWeeksOverride`.
- Detail: show `slotsCreated` in sync summary banner; localize `mode_mismatch` («Другой формат слота»); keep skip/reschedule for remaining conflicts.
- Entry copy: «Регулярные тренировки» everywhere (list AppBar title can stay «Регулярные тренировки»).

### 6. Orphan cleanup

| Route | Action |
|---|---|
| `/schedule/book-for-student` | Redirect to new flow **or** keep as deep link into same Page with no prefill |
| `/schedule/slots` | Remove from router **or** redirect to `/schedule` tab availability; delete dead screen if unused in tests |

Prefer redirect `/schedule/slots` → `/schedule` to avoid breaking bookmarks; delete UI entry only.

### 7. Empty-hour hit target

`CalendarDayTimeline`: add gesture on hour gutters / empty regions. Pass `onEmptyHourTap(DateTime localHourStart)`. Ignore taps that land on event cards (cards already consume).

## Risks / Trade-offs

- [API change not applied yet] → Gate book-at-time behind repository; apply order: book-at-time first, then this UX; document dependency in tasks.
- [Empty-hour taps conflict with scroll] → Use short tap detector; don’t steal vertical drag.
- [Trainer confuses «Свободное время» vs «Записать»] → Copy in sheet: subtitle «открыть окно для заявок» vs «закрепить ученика».
- [Deleting CoachSlotsScreen breaks a test] → Update/remove tests in same change.

## Migration Plan

1. Apply `add-coach-book-at-time` backend.
2. Ship Flutter UX (this change).
3. Smoke: empty September day → book student → Session appears; FAB → recurring; open slot → book; free time still works.

## Open Questions

- Session tap: open detail vs history — default to push `/sessions/:id/history` if id available, else ignore.
- Edit open slot time: out of MVP sheet (only delete + re-create via free time) unless cheap — **MVP: delete only**, no edit.
