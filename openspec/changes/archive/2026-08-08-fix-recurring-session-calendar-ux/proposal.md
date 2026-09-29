# Change: fix-recurring-session-calendar-ux

## Why

После создания регулярной серии detail выглядит незавершённым (ложный CTA «Синхронизировать»), отмена серии оставляет слоты `booked` и конфликты в календаре, Back из истории уводит в «Мои тренировки», а тап по занятию открывает только историю вместо управления.

## What Changes

- Detail: показать sync-сводку с create, «Готово», переименовать sync в «Обновить горизонт» с пояснением
- Cancel серии: освобождать будущие слоты; list default `active`; DELETE только для cancelled; UI архив без restore
- Session history Back: `pop` если есть стек
- Calendar session tap → actions sheet (complete / cancel / no-show / history)
- Calendar: не показывать cancelled sessions (чтобы освобождённый слот был виден)

## Impact

- Specs: `recurring-bookings-api`, `mobile-recurring-booking`, `mobile-calendar-views`, `mobile-schedule-booking`
- Code: Nest recurring + session lifecycle; Flutter schedule/recurring/session screens
