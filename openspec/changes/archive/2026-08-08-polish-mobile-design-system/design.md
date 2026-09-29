## Context

MVP и coach booking UX закрыты. Базовая DS (этапы 1–6) в коде, но `docs/design/design-system-status.md` фиксирует волну A: шрифт, secondary button, chip, bottom sheet shell, barrel, debt в calendar/recurring.

Constraints: Bloc/Cubit only, Russian UI copy, no backend, no Riverpod, волны B/C/D вне scope.

Stakeholders: mobile Flutter (`app/fitness_app`), visual SoT `app/design/**`, roadmap `docs/roadmap/plan.md`.

## Goals / Non-Goals

**Goals:**

- Theme использует Plus Jakarta Sans end-to-end на redesigned surfaces.
- Shared primitives: `FySecondaryButton`, `FyChip`, `showFyBottomSheet`, barrel `core/widgets.dart`.
- Schedule/recurring consumers перестают плодить локальные chips / raw `Card` / raw `OutlinedButton` / ad-hoc sheets для create/slot/free-time.

**Non-Goals:**

- Dark theme, custom AppBar, auth décor/hero asset, motion polish (B/C).
- Parked D components (metric gauge, pagination, twin cards, floating icons, section badge).
- New product screens or API changes.

## Decisions

### 1. Font: Plus Jakarta Sans via `google_fonts`

`tokens.md` допускает Plus Jakarta Sans **или** Manrope. Фиксируем **Plus Jakarta Sans** (roadmap). Доставка: пакет `google_fonts` с `GoogleFonts.plusJakartaSansTextTheme` в `AppTheme.light()` — быстрее, чем bundling TTF в первом apply. Offline/bundled fonts — follow-up, не блокер волны A.

Альтернатива (bundled `fonts:` в pubspec) отклонена для A из‑за большего churn assets; API theme остаётся тем же.

### 2. Keep widgets under `lib/core/widgets/` + barrel

Не вводим `lib/core/design_system/` path. Добавляем `lib/core/widgets/widgets.dart` (или `core_widgets.dart`) как barrel export существующих + новых примитивов. Импорты в фичах постепенно через barrel; массовый rewrite всех import paths не обязателен в A.

### 3. `showFyBottomSheet` — thin Material wrapper

Единый helper: `showModalBottomSheet` + documented shape/padding/background из tokens (surface white, top radius). Не тащит Bloc/networking. Существующие sheets (`ScheduleCreateActionsSheet`, `OpenSlotActionsSheet`, `FreeTimeSheet`) вызывают helper вместо прямого `showModalBottomSheet`.

### 4. `FyChip` API

Минимальный selected/unselected chip (label, optional leading check, `onSelected`/`onTap`) для mode/type/weekday. Не полный Material 3 FilterChip redesign. Локальные `_ModeChip` / `_TypeChip` / weekday pills мигрируют на `FyChip`.

### 5. Debt scope = schedule + recurring only

Не охотимся за каждым `OutlinedButton` в приложении. Минимум из status doc: `calendar_event_card.dart`, `recurring_booking_detail_page.dart`, weekday/mode chips, create/slot/free-time sheets.

## Risks / Trade-offs

- [google_fonts network fetch on first run] → Mitigation: document; optional later bundle.
- [Sheet migration misses a sheet] → Mitigation: task list names concrete files; analyze/search for `showModalBottomSheet` under schedule.
- [Chip visual drift] → Mitigation: match `app/design/components` / existing mint selected style on weekday picker.

## Migration Plan

1. Theme + font.
2. Add primitives + barrel.
3. Migrate schedule/recurring consumers.
4. `dart format`, `flutter analyze`, targeted widget tests.
5. Visual smoke on macOS/Chrome light theme.

Rollback: revert change; no DB/API.

## Open Questions

_(none — font and path decisions fixed above)_
