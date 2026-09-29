## Why

Этапы 1–6 дизайн-системы уже в коде, но отложенные примитивы (шрифт, secondary button, chip, bottom sheet shell) и локальный debt в календаре/recurring ломают правило «собирать из `core/widgets`». После закрытия MVP и coach booking UX пора закрыть **волну A** инфраструктурного долга, не трогая product flows и не раздувая change до dark theme / auth décor.

## What Changes

- Подключить фирменный шрифт **Plus Jakarta Sans** в theme (через `google_fonts` или bundled `fonts:`).
- Добавить `FySecondaryButton` (outlined stadium) и заменить сырые `OutlinedButton` в затронутых schedule/recurring экранах.
- Добавить `FyChip` и мигрировать локальные mode/type/weekday chips в schedule.
- Добавить `showFyBottomSheet` и перевести create/slot/free-time sheets на общий shell.
- Добавить barrel-экспорт `core/widgets` (без обязательного `lib/core/design_system/` path).
- Debt cleanup: `calendar_event_card` → `FyCard`; recurring detail secondary actions → `FySecondaryButton`.
- Обновить `mobile-design-system` requirements и точечно calendar/recurring потребители.

## Capabilities

### New Capabilities

_(нет — расширяем существующую дизайн-систему)_

### Modified Capabilities

- `mobile-design-system`: шрифт, secondary button, chip, bottom sheet helper, barrel export.
- `mobile-calendar-views`: event cards и action sheets используют shared primitives.
- `mobile-recurring-booking`: detail/create actions и chips используют shared primitives.

## Impact

- Flutter only: `app/fitness_app/lib/app/theme/`, `lib/core/widgets/`, schedule/recurring presentation.
- Возможна зависимость `google_fonts` **или** локальные font assets в `pubspec.yaml`.
- Backend / API / web — без изменений.
- Волны B (auth décor, motion, top bar) и C (dark theme) — **вне** этого change.
- Волна D (metric gauge, pagination, twin cards, floating icons, section badge) — parked.

## Non-goals

- Dark theme / `ThemeMode` switcher.
- Custom AppBar / decorative auth background / hero illustration asset.
- Motion (press scale, tab fade+slide) как отдельный polish.
- Новые product screens (onboarding, analytics metric card).
- Riverpod или смена state-management.
- Переименование всего `core/widgets` в `core/design_system` (достаточно barrel).
