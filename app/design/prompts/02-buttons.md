# Prompt 02 — Buttons

Скопируй целиком в Agent:

---

Внедри **кнопки** по дизайн-пакету. Тема уже должна содержать primary stadium (шаг 01). Этот шаг — виджеты и единообразие CTA.

## Прочитай

- `app/design/components/buttons.md`
- `app/design/tokens.md`
- `app/design/crops/04_button_next.png`
- `app/design/crops/03_button_calculate.png`
- `app/fitness_app/lib/app/theme/app_theme.dart`

## Сделай

1. Создай `lib/core/widgets/fy_primary_button.dart` (или `lib/app/widgets/` — как принято в проекте):
   - full width optional;
   - label + optional trailing `Icons.arrow_forward_rounded`;
   - loading state (CircularProgressIndicator white, маленький);
   - disabled state;
   - высота 52–56, stadium, `#166246`.
2. Опционально `FySecondaryButton` (outlined stadium).
3. Замени на экранах auth (login/register) основные Elevated/Filled на `FyPrimaryButton` **без** смены логики submit.
4. Не трогай остальные экраны в этом шаге (или только самые очевидные CTA если тривиально).

## Done

- [ ] Виджет переиспользуемый
- [ ] Login CTA = stadium green + optional arrow
- [ ] Analyze clean
