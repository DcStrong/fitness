# Prompt 06 — Home & Schedule

Скопируй целиком в Agent:

---

Рескин **Home + ключевые schedule screens** selection-cards / list-cards языком рефа. Логику repository/cubit не ломать.

## Прочитай

- `app/design/mapping-fitness-yoda.md`
- `app/design/components/cards.md`
- `app/design/components/headers.md`
- `app/design/crops/05_header_hero.png`
- `app/design/crops/05_card_workout.png`
- `home_screen.dart` + screens в `features/schedule/presentation/screens/`

## Сделай

1. Home: вместо длинного ListTile-меню — 2–4 `FyCard` quick actions с title, short subtitle, `FyPrimaryButton` или стрелка («Расписание», «Приглашения», «Занятия» по роли).
2. Relationships list — rows внутри white card (как list item в nutrition card рефа: thumbnail/icon + texts).
3. Coach slots / student book / sessions list: каждая сущность — soft white card; primary actions — stadium button.
4. Единые отступы 24 horizontal, gaps 12–16.
5. Empty states: короткая mint info banner внутри card.

## Не делай

- Workout plans / BMI / nutrition.
- Новые API endpoints.
- Pixel-perfect иллюстрации мышц.

## Done

- [ ] Home и schedule визуально в одной системе с auth
- [ ] Функционал записи/слотов работает как раньше
- [ ] Analyze clean
