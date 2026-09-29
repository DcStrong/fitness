# Component: Cards

Реф: `crops/05_card_workout.png`, `crops/01_card_bmi.png`, `crops/01_card_nutrition.png`, `crops/03_result_bmi_card.png`

## Surface card (базовая)

| Prop | Value |
|------|-------|
| Background | `#FFFFFF` |
| Radius | 20 |
| Padding | 16–20 |
| Shadow | soft (см. tokens) |
| Border | none (или 1px outlineVariant @ 20% если тень выключена) |

Контент внутри — Column/Row, не «Material Card с title слотом» по умолчанию.

## Selection / Action card (ref_05)

Структура:

```
┌──────────────────────────────────────────┐
│ [icon tile]  Title                       │
│              meta line (green)           │
│                         [illustration?]  │
│ ┌──────────────────────────────────────┐ │
│ │  Get Started                      →  │ │
│ └──────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

Для Yoda home:
- «Расписание» / «Пригласить ученика» / «Мои занятия» — те же cards с primary CTA внутри.

## Booking request card (trainer inbox)

Implementation: `lib/features/booking_requests/presentation/widgets/fy_booking_request_card.dart`

Concept: `docs/assets/fitness-yoda-trainer-calendar-concept.png` (middle screen).

```
┌──────────────────────────────────────────┐
│ (avatar)  Анна Смирнова                  │
│ 📅 Сегодня · 18:00–19:00                 │
│ 💳 1 500 ₽                               │
│ ⏱ Ответить до 21:30           02:48:12  │
│ [ Принять ]                              │  ← FyButton.primary medium
│ [ Другое время ]                         │  ← FyButton.secondary medium
│ [ Отклонить ]                            │  ← FyButton.danger medium
└──────────────────────────────────────────┘
```

- Header (avatar + meta + deadline) tappable → detail.
- Actions use shared `FyButton` pills (не boxy radius).
- Countdown updates every second while pending.
- Avatar: initials until photo URL exists on counterpart.

## Stat / metric card (ref_03 BMI)

```
┌──────────────────────────────────────────┐
│  (○ gauge)   Category label              │
│              Big number                  │
│  ┌────────────────────────────────────┐  │
│  │ i  helper text on mintSoft bg      │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

Адаптация: статус связи тренер↔ученик, ближайшая сессия, счётчик open slots — не обязательно gauge.

## Input card (см. inputs.md)

Белая карточка-обёртка вокруг поля, не «голое» TextField на canvas.

## Info banner (внутри card)

- bg: mintSoft (`#57CEA8` @ ~15%)
- radius: 12
- leading: circle `i` на primary
- text: 12–13 `#2E2E2E` / secondary
