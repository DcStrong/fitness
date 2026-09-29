## 1. Assets and primitives

- [x] 1.1 Copy `app/design/generated/fy-auth-hero.png` (and optional `fy-header-accent.png`) into Flutter assets; register in `pubspec.yaml`
- [x] 1.2 Add `FyTopBar` (title + optional subtitle, optional leading back; no notification bell) under `core/widgets` + barrel export
- [x] 1.3 Add press-scale (~0.98) to shared primary CTA path (`FyPrimaryButton` / `FyButton`) with reduce-motion respect

## 2. Authenticated shell chrome

- [x] 2.1 Wire `FyTopBar` into shell / primary authenticated destinations (Home, Schedule hub, Packages/Trainers branch, Profile, and nested back routes that currently use AppBar)
- [x] 2.2 Add fade+slide when switching StatefulShell / bottom-nav branches; respect reduce-motion

## 3. Auth polish

- [x] 3.1 Login: hero asset + mint circle/wave décor + ~40–42% hero proportion (keyboard closed); keep fields/CTA/AuthCubit unchanged
- [x] 3.2 Register: same hero/décor system as Login; role chips and submit path unchanged
- [x] 3.3 Auth panel entrance fade/slide on route show; scroll/keyboard overflow still OK

## 4. Calendar motion

- [x] 4.1 Day mode: AnimatedSwitcher-style fade/slide when selected local date changes; do not force same animation for day/week/month mode switches

## 5. Verify

- [x] 5.1 `flutter analyze` clean on touched files; widget tests if cheap for `FyTopBar` / press-scale
- [x] 5.2 Manual smoke: Login/Register vs local API unchanged; tab switch motion; calendar day change; no bell in top bar; web console untouched
- [x] 5.3 Update `docs/design/design-system-status.md` wave B rows to reflect implementation (after visual pass)
