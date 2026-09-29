## Context

Fitness Yoda mobile already ships design tokens, `Fy*` widgets (волна A), StatefulShell bottom nav, Login/Register with soft hero layout, and a trainer calendar. Authenticated screens still lean on Material `AppBar`; auth lacks a brand illustration asset; motion from `app/design/tokens.md` is undocumented in behavior. Product flows (packages, workout program) are stable enough for polish-only wave B.

Stakeholders: mobile Flutter (`app/fitness_app`); design pack (`app/design/**`, `app/design/generated/`). Web console and Nest API are out of scope.

## Goals / Non-Goals

**Goals:**

- Shared custom top bar (title + optional subtitle) on the authenticated shell.
- Auth visual polish: hero asset + mint décor + ~40–42% hero proportion without changing form contracts.
- Motion: CTA press scale, shell tab transition, auth panel entrance, calendar day switch.
- Specs updated so archive can sync into main `openspec/specs/`.

**Non-Goals:**

- Dark theme / ThemeMode (wave C).
- Notifications UI or APIs.
- Auth field/CTA/AuthCubit/API rewrites.
- Next.js web console.
- Wave D components (gauge, dots, twin cards, floating icons, section badge).

## Decisions

1. **Top bar as `FyTopBar` (or equivalent) in `core/widgets`**  
   Prefer one shared preferred-size / sliver-friendly widget used from shell or per-page AppBar wrappers, rather than forking Material theme only.  
   *Alternatives:* Theme `AppBarTheme` only — rejected: hard to get title+subtitle rhythm and accent-word pattern from headers.md.  
   Scope: all authenticated shell destinations (Home, Schedule, Packages/Trainers branch, Profile, nested routes that currently show an AppBar). Nested full-screen flows MAY keep a back-enabled variant of the same widget.

2. **Content of top bar**  
   Title + optional subtitle only. No notification bell, avatar, or overflow menu in this change (avatar already lives on Profile tab).

3. **Auth décor = asset + painter, light layout tweak**  
   Copy `app/design/generated/fy-auth-hero.png` (and optional `fy-header-accent.png`) into Flutter assets. Soft mint circle / wave via CustomPainter or stacked decorations behind the hero. Adjust hero height fraction toward 40–42% of viewport when keyboard is closed; keep scroll behavior for small heights. Do not change TextFields, role chips, validators, or submit handlers.

4. **Motion implementation**  
   - Primary CTA: `ScaleTransition` / press feedback at `0.98` on `FyPrimaryButton` (or wrapper) without changing loading/disabled contracts.  
   - Shell tabs: `FadeTransition` + slight slide on IndexedStack branch change (AnimatedSwitcher or shell branch listener).  
   - Auth panel: entrance fade/slide once per route push.  
   - Calendar day: short AnimatedSwitcher when selected local date changes (day mode body).  
   Prefer durations from `tokens.md` §Motion if present; otherwise 150–250 ms ease-out. Respect `MediaQuery.disableAnimations` / reduce-motion.

5. **No backend / no web console**  
   Pure presentation change; rollback = revert Flutter commit / disable asset.

## Risks / Trade-offs

- [Nested screens fight custom AppBar] → Provide `FyTopBar` with leading back + title API; migrate high-traffic authenticated routes first, leave obscure dialogs alone.  
- [Hero asset too large / wrong crop] → Optimize PNG or regenerate; use `BoxFit.cover` with alignment; keep abstract fallback if asset missing.  
- [Motion feels sluggish on web Chrome] → Cap duration; skip heavy painters on low-end; test Flutter web + mobile.  
- [Calendar day animation double-fires with mode switch] → Gate animation on date-only changes, not day/week/month mode.

## Migration Plan

1. Add assets + `FyTopBar` + motion hooks behind existing widgets.  
2. Wire shell / primary authenticated AppBars.  
3. Polish auth screens.  
4. Calendar day switch.  
5. Visual smoke Login/Register + tab switch + calendar day; `flutter analyze` on touched files.  
Rollback: revert change; assets unused.

## Open Questions

_(none blocking — decisions locked in explore: shell-wide top bar, no bell, décor+asset+proportion, motion including auth panel + calendar day, web console untouched)_
