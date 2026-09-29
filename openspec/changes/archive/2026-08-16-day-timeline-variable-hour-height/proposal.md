## Why

В day-timeline каждый час имеет фиксированную высоту (72px). Запись не кратная часу (например 12:10–13:10) стартует внутри часа `12` и по длительности уходит ниже метки `13:00`, визуально «наезжая» на следующий слот. Нужно, чтобы ряды часов растягивались так, чтобы карточки оставались привязаны к часовой шкале без ложного перекрытия соседнего часа.

## What Changes

- Перейти с фиксированной высоты часа на **переменную** (единый масштаб минут→пиксели на день), чтобы занятия с минутами ≠ `:00` и карточки с `_minCardHeight` не выталкивались поверх следующего часа.
- Сохранить текущую логику видимых часов: рабочие часы тренера ∪ out-of-band события без заполнения пустых дыр.
- **Опционально (фаза 2):** на левой шкале показывать метку `HH:30` только у часов, где есть активная запись с временем, кратным получасу (например 12:30–13:30); если окажется тяжело — отложить.

## Capabilities

### New Capabilities

_(нет)_

### Modified Capabilities

- `mobile-calendar-views`: day-timeline hour row heights scale with events so non-hour-aligned bookings stay clock-aligned without overlapping the next hour’s visual band; optional half-hour labels on affected hours.

## Impact

- Flutter only: `app/fitness_app/lib/features/schedule/presentation/widgets/calendar_day_timeline.dart` (+ tests).
- No Nest API, migrations, or week/month view changes.

## Non-goals

- Backend / availability generation / slot duration rules.
- Labels every 15 minutes or continuous minute grid.
- Redesign of event cards or week/month layouts.
- Changing working-hours ∪ out-of-band hour selection from the previous polish.
