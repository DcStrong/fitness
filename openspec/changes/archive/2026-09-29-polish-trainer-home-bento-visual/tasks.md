## 1. Header and stat cards

- [x] 1.1 Add a trainer date chip in the Home header for the current local day
- [x] 1.2 Restyle trainer stats as icon + label + number cards on a light soft surface
- [x] 1.3 Keep «На неделе» unless a free-slot count is already in Home state; then show «Свободно»
- [x] 1.4 Hide «Заявки» when pending count failed; keep inbox navigation when count > 0

## 2. Today timeline

- [x] 2.1 Render trainer today sessions as a vertical timeline with time and training identity
- [x] 2.2 Show counterpart avatar from an existing image URL, otherwise initials
- [x] 2.3 Keep the empty-day message when the day list is empty

## 3. Bento visual

- [x] 3.1 Switch trainer bento tiles to white/canvas soft cards with mint accents
- [x] 3.2 Draw a seven-day booked-count chart inside the tall «Расписание» tile from loaded week data
- [x] 3.3 Add «Перейти» on «Расписание» and «Регулярные тренировки» to the same routes as the tiles
- [x] 3.4 Keep week strip, finance tile, and existing tile routes

## 4. Tests

- [x] 4.1 Update widget tests for date chip, stat card labels, initials avatar, sparkline, and «Перейти»
- [x] 4.2 Run the home widget tests in `app/fitness_app`
