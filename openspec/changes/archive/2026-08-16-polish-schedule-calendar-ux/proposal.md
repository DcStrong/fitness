## Why

После ручного QA тренерского Flutter-расписания (`#/schedule` и соседние экраны) всплыли пробелы понятности и навигации: неочевидные поля доступности, слабая обратная связь копирования окон, слепой выбор альтернативного времени заявки, невозможность листать дни за пределы текущей недели, нет фильтра учеников по оплате/ожиданию, нельзя свернуть предстоящие на главной, и day-timeline ломает карточки вне сетки часов. Нужен единый UX-polish без расширения Nest API.

## What Changes

- Добавить help-иконки с русскими подсказками к полям редактора доступности (в т.ч. «Горизонт генерации»).
- Переименовать «Скопировать на Пн–Пт» → «Скопировать на каждый день» (копия окон на Пн–Вс) и показать SnackBar об успехе.
- В flow «другое время» заявки встроить месячный календарь занятости (как вкладка «Месяц») с выбором дня, просмотром занятости и выбором времени.
- В режиме «День» показать prev/next стрелки (сдвиг ±1 день), по аналогии с неделей.
- На экране «Ученики и абонементы» добавить фильтр chips: Все / Оплачен / Не оплачен / Ожидает.
- На главной сделать блок «Предстоящие тренировки» сворачиваемым (как «История»).
- Исправить визуальный баг day-timeline, когда тренировка выходит за типичные слоты/часы сетки.

## Capabilities

### New Capabilities

_(нет — расширяем существующие mobile capabilities)_

### Modified Capabilities

- `mobile-availability`: field help affordances; copy windows to all seven days; success feedback on copy.
- `mobile-calendar-views`: day-mode period chevrons; day-timeline placement for out-of-default-hour events.
- `mobile-schedule-booking`: alternate-time picker uses occupied month calendar + day occupancy before confirming time.
- `mobile-session-packages`: student list filter Оплачен / Не оплачен / Ожидает (pending booking request).
- `mobile-home-dashboard`: collapsible upcoming sessions section.

## Impact

- Flutter only: `app/fitness_app` — schedule/availability, calendar widgets/cubit, booking-requests alternate sheet, session-packages list, home cubit/view.
- Reuses existing calendar event loading and booking-requests inbox; **no** Nest API / migration / web_app changes.
- Unit/widget tests for availability copy, home toggle, packages filter categorization, timeline hour range.

## Non-goals

- Backend API, DB schema, or web console changes.
- Push notifications or redesign of calendar visual language.
- Dark theme / Riverpod / new bottom-nav destinations.
- Finance ledger as the sole source of «оплачен» (package `active` is the paid signal for this filter).
