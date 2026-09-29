# Prompt 04 — Navigation shell

Скопируй целиком в Agent:

---

Добавь **bottom navigation shell** в стиле рефа (mint active pill). Только shell + маршруты; контент tab = существующие экраны.

## Прочитай

- `app/design/components/navigation.md`
- `app/design/mapping-fitness-yoda.md`
- `app/design/crops/05_bottom_nav.png`
- `app/fitness_app/lib/app/router/app_router.dart`
- home / schedule / invitations screens

## Сделай

1. `ScaffoldWithNavBar` / `AppShell`: 3–4 пункта по mapping (Home, Schedule, Invite или People, Profile).
2. Active: mintSoft pill + icon primary + label; inactive: icon only grey.
3. Встрой в `go_router` StatefulShellRoute или эквивалент проекта.
4. Profile tab: минимум — user info + logout (можно вынести с AppBar home).
5. Спрячь дублирующие AppBar actions где они переезжают в Profile.

## Не делай

- Полный редизайн всех schedule screens.
- Новые фичи API.

## Done

- [ ] После логина виден bottom nav как на `05_bottom_nav.png`
- [ ] Роли coach/student: скрыть/заменить Invite tab если нужно
- [ ] Analyze clean
