# Prompt 03 — Cards & Inputs

Скопируй целиком в Agent:

---

Внедри **карточки и поля ввода** по рефу soft-UI.

## Прочитай

- `app/design/components/cards.md`
- `app/design/components/inputs.md`
- `app/design/tokens.md`
- `app/design/crops/04_input_cards.png`
- `app/design/crops/05_card_workout.png`
- `app/design/crops/03_result_bmi_card.png`

## Сделай

1. `FyCard` — white, radius 20, soft shadow, padding 16–20.
2. `FyTextField` / `FyInputCard` — белая карточка, leading icon tile `#166246` + white icon, `TextField` без тяжёлого outline (border none или underline), optional unit/trailing chip.
3. Обнови `InputDecorationTheme` в `AppTheme` согласованно.
4. На login/register замени голые `TextFormField` на `FyInputCard` (email, password) — валидаторы сохранить.

## Не делай

- BMI / nutrition UI.
- Bottom navigation.

## Done

- [ ] Login выглядит как «поля в карточках» на мятном фоне
- [ ] Общие виджеты в core/app widgets
- [ ] Analyze clean
