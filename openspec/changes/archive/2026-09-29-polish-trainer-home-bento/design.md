## Context

Home (`/home`) для тренера: date header, optional pending/package banners, collapsible «Предстоящие» + History, затем вертикальный `_FeatureCardGrid` (1 col на phone). `HomeCubit` грузит sessions только за **текущий локальный день** + pending count.

Макет-якорь: `app/design/generated/mock-home-c-asymmetric-bento.png`. Референсы: bento dashboards (Stride), «На этой неделе» strip в `mock-student-hub-a-profile.png`, `CalendarDateStrip` в schedule.

Стек: Flutter Bloc, `ScheduleRepository.listSessions(from, to)`, `BookingRequestsRepository.pendingCount`, существующие `FyCard` / `FyChip` / `AppColors.actionFill`.

## Goals / Non-Goals

**Goals:**

- Trainer Home читается за 3–5 сек: неделя → сегодня → shortcuts.
- Week strip с реальными данными (booked sessions текущей недели).
- Asymmetric bento для 4–5 shortcuts без равноправной «ленты кнопок».
- Студент: 2-col grid shortcuts; week strip опционально (упрощённый — только upcoming, без coach bento).

**Non-Goals:** Nest API; полный календарь; pixel-perfect mock; dark theme; stats dashboard.

## Decisions

### 1. Порядок блоков (trainer)

1. `FyTopBar` «Главная» (как сейчас).
2. Date header + QR invite.
3. **Stat chips** (горизонтальный scroll при нехватке ширины).
4. **Week mini-calendar strip** (7 cells, текущая календарная неделя пн–вс).
5. Pending banner **скрыть**, если count уже в chip «Заявки» и >0 chip tappable → inbox (избежать дубля).
6. «Сегодня» / upcoming list (compact, max 2–3 rows + «ещё N» link → `/schedule` или expand).
7. History collapse (без изменений логики).
8. «Всё необходимое» → **asymmetric bento**.

### 2. Week strip — поведение и данные

- **Data:** `HomeCubit` дополнительно (или вместо одного day-call — один week-call) запрашивает `listSessions(from: weekStart, to: weekEnd)` где week = локальная ISO неделя пн 00:00 – вс+1 00:00. Daily list для «Сегодня» берётся из того же payload (filter by day) **или** остаётся отдельный day request — предпочтение **один week request** + client filter для today/upcoming/history.
- **UI:** переиспользовать стиль `CalendarDateStrip` (`_DateStripCell`: weekday + day number, selected = today, mint pill). Под weekday — **одна строка** title первой booked session этого дня (truncate) или «—» если пусто.
- **Tap day:** v1 — `context.go('/schedule')` с передачей даты через query/extra **если** schedule landing уже умеет; иначе только visual highlight + scroll к today list when same day. Не блокирует apply: минимум — highlight + navigate schedule без date preselect.
- **Selected day:** по умолчанию today; смена selected не меняет API, только UI focus.

Alternatives rejected: embedded `CalendarMonthView` (too heavy); static decorative strip without data (не соответствует «сделать правильным»).

### 3. Stat chips

| Chip | Trainer | Student |
|------|---------|---------|
| Сегодня · N | booked+upcoming sessions today | same |
| Заявки · N | if pending load success | hidden |
| Третий | «На неделе · N» (sessions in week) | «Запись» → `/schedule/book` or package chip |

- Компонент: `FyChip`-like mint soft pills, tappable where есть destination.
- Failures: chip скрыт или без числа, не показывать «0» misleading для failed pending load.

«Свободно · N» из mock — **отложено** (нет cheap slot count на Home без API). Третий chip = «На неделе».

### 4. Asymmetric bento layout (trainer)

Grid on ~390px width, gap 12, используя `actionFill` / white cards:

```
┌─────────────┬─────────────┐
│ Расписание  │  Ученики    │
│   (tall)    │─────────────│
│             │ Планирование│
├─────────────┴─────────────┤
│   Регулярные (full width) │
└───────────────────────────┘
[ Финансы — half or full row if permission ]
```

- Tall left: min height ~2× right cell, icon + title + subtitle, tap → `/schedule`.
- Right top: `/session-packages`.
- Right bottom: `/plans`.
- Bottom wide: `/schedule/recurring`.
- Finance: если permission — плитка под bento (full width, lower visual weight) → `/finance`.

Reuse routes from `_featureCards()`; не новые маршруты.

Alternatives rejected: equal 2×2 (variant A); hero card (variant B).

### 5. Student Home

- Week strip: показать upcoming 3–5 days с labels (lighter).
- Feature grid: **always 2 columns** on phone (`columns = 2` unconditionally).
- No asymmetric bento.

### 6. Shared widgets

- `HomeWeekStrip` — `features/home/presentation/widgets/` (может internally compose `CalendarDateStrip` or fork cells for subtitle line).
- `HomeStatChips` — row of tappable chips.
- `HomeBentoShortcuts` — trainer-only layout table.

Не выносить в `core/widgets` до второго потребителя.

### 7. Mock allowlist

**Copy:** asymmetric bento, week strip with workout hints, stat chips, compact today list.

**Do not copy:** debug labels, exact mock typography, fake «Свободно» if no data.

## Risks / Trade-offs

- [Week fetch heavier than day-only] → один запрос на неделю обычно ≤7× day size но 1 round-trip; acceptable.
- [Schedule date preselect on tap] → optional; fallback navigate `/schedule` only.
- [Duplicate заявки banner + chip] → убрать banner when chips ship.
- [Bento on small phones] → min font 12, 2-line titles, test 320px width.

## Migration Plan

Flutter-only. Phased: week data in cubit → strip + chips → bento → student 2-col → tests. Rollback: revert commit.

## Open Questions

- Preselect date on `/schedule` when tapping week day — verify `ScheduleLandingScreen` / calendar bloc accepts initial date; if not, follow-up small route extra (still no API).
