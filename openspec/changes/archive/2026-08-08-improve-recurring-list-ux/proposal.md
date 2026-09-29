# Change: improve-recurring-list-ux

## Why

Список регулярных серий плохо находи́м (нет входа из Расписания/Главной), карточки без имени ученика и понятной даты занятия, повторный create после cancel плодит дубли, а из архива нельзя явно восстановить серию.

## What Changes

- Entry points: AppBar «Регулярные» в расписании и feature-card на Home для тренера
- List/get: `studentDisplayName`, `studentEmail`; для active — ближайшая дата занятия (`nextOccurrenceLocalDate`)
- UI карточки: имя/email, дни · время · формат; active — ближайшее занятие; archive — дата отмены; даты в формате сегодня/завтра/вчера/`DD.MM.YY`
- Create: 409 при active-дубликате (`existingId`); реактивация newest cancelled с тем же паттерном вместо новой строки
- Явный **restore** cancelled-серии из архива (API + UI), с sync как при create-reactivate

## Capabilities

### Modified Capabilities

- `recurring-bookings-api` — enrichment, create guard/reactivate, next occurrence, restore
- `mobile-recurring-booking` — entry points, rich cards, relative dates, restore from archive, 409 navigation

## Impact

- Specs: `recurring-bookings-api`, `mobile-recurring-booking`
- Code: Nest recurring-bookings; Flutter schedule/home/recurring (+ shared date label helper)
