## Why

API Слоя C (`add-coach-book-at-time`) даёт запись на время и автосоздание слотов, но в приложении тренер по-прежнему не может интуитивно записать ученика: tap по «Свободному времени» ничего не делает, экран book-for-student — маршрут-сирота, а «Регулярный график» в AppBar читается как график тренера, а не запись ученика. Нужен Flutter UX, который делает запись первичным действием календаря.

## What Changes

- Единый FAB «+» на вкладке «Календарь» с листом из трёх пунктов: «Записать ученика», «Регулярные тренировки», «Свободное время»; убрать TextButton «Регулярный график» из AppBar.
- Tap по карточке open-слота → bottom sheet: записать ученика / записать регулярно / изменить / удалить.
- Tap по пустой строке дневной сетки → тот же лист записи с подставленными датой/временем (book-at-time без предварительного слота).
- Поток «Записать ученика»: выбор связанного ученика, время/длительность/режим (из слота или из точки нажатия), опциональная цена; вызов API book-slot **или** book-at-time; русский copy, loading/error.
- Recurring create: поле горизонта (недель) поверх `horizonWeeksOverride`; в detail показывать `slotsCreated` и reason `mode_mismatch`; действия на конфликтах (skip / reschedule) остаются.
- Удалить или переиспользовать orphan-маршруты `/schedule/book-for-student` и `/schedule/slots` (legacy CRUD) так, чтобы не оставалось мёртвых экранов без входа.
- Дизайн-система: `FyCard` / `FyButton` / sheets; не вводить Riverpod.

## Non-goals

- Backend API (book-at-time, auto-create, строгий overlap) — change `add-coach-book-at-time` (должен быть применён до или вместе с этим UX).
- Student BookingRequest UX, finance, packages, web.
- Полный redesign календаря / week grid drag-and-drop.
- Фирменный шрифт, dark theme и прочий дизайн-долг из `docs/design/design-system-status.md` (отдельный follow-up).

## Capabilities

### New Capabilities

- `mobile-coach-booking`: Flutter-поток тренера «Записать ученика» (разово на слот или на произвольное время), русские sheet/экраны, repository вызовы book-slot / book-at-time.

### Modified Capabilities

- `mobile-calendar-views`: FAB «+» вместо только «Свободное время»; tap по availability-событию и по пустому времени дня открывает действия записи; session/request taps сохраняют осмысленное поведение.
- `mobile-schedule-booking`: book-for-student достижим из календаря; legacy «Мои слоты» не является основным путём; entry naming не путает с «Доступность».
- `mobile-recurring-booking`: entry через FAB «Регулярные тренировки»; горизонт в форме create; sync summary показывает созданные слоты; конфликт `mode_mismatch` отображается отдельно.

## Impact

- Flutter `app/fitness_app`: `trainer_calendar_page`, calendar day timeline, event card handlers, new/refactored book-student sheet/screen, recurring create/detail, router cleanup for orphans.
- Зависит от API `add-coach-book-at-time` (`POST /sessions` XOR time range, sync `slotsCreated` / `mode_mismatch`).
- Backend в этом change **не** меняем (кроме если обнаружен блокирующий баг контракта).
- Референс: `docs/design/availability-recurring-booking.md` (Слой C), `docs/design/design-system-status.md`.
