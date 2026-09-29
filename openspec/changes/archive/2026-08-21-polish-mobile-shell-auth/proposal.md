## Why

Волна A закрыла инфраструктурные примитивы DS, но authenticated shell всё ещё на стандартном `AppBar`, auth держит абстрактный hero без фирменного ассета, а motion из `tokens.md` не внедрён. После стабилизации product-контура (packages, workout program) пора закрыть **волну B** — trust/polish shell+auth, не трогая API и web console.

## What Changes

- Добавить shared **custom top bar** (title + optional subtitle) на весь authenticated shell; без колокольчика / notification stub.
- Auth Login/Register: подключить сгенерированный hero-ассет, mint décor (circle / wave), лёгкая подгонка hero ≈ 40–42% высоты; **без** смены полей, CTA, валидаторов, AuthCubit/API.
- Motion: press scale `0.98` на primary CTA; fade+slide при смене tab shell; появление auth-панели; transition при смене дня в календаре.
- Зафиксировать ассеты в Flutter (`assets/`) из `app/design/generated/` (или обновлённых черновиков).
- Обновить requirements `mobile-design-system`, `mobile-app-shell`, `mobile-auth`, `mobile-calendar-views`.

## Capabilities

### New Capabilities

_(нет)_

### Modified Capabilities

- `mobile-design-system`: top bar primitive, motion tokens/behaviors, hero/décor guidance for auth.
- `mobile-app-shell`: authenticated destinations use custom top bar instead of raw Material AppBar where applicable.
- `mobile-auth`: Login/Register hero asset + décor + proportion polish; auth panel entrance motion.
- `mobile-calendar-views`: day-switch transition motion without changing calendar data/projection.

## Impact

- Flutter only: `app/fitness_app` theme/widgets/shell/auth/calendar presentation; `pubspec.yaml` assets.
- Design pack: `app/design/generated/`, `docs/design/design-system-status.md` (после apply/archive).
- Backend / Nest API / Next.js web console — **без изменений**.
- Волны C (dark theme) и D (gauge, dots, twin cards, floating icons) — вне scope.

## Non-goals

- Dark theme / `ThemeMode` switcher (волна C).
- Notification bell, in-app inbox, push.
- Переписывание auth fields/CTA/логики или Nest auth API.
- Web coach console redesign.
- Волна D components; Riverpod; product features (notifications, groups, referrals).
