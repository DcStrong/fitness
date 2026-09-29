# Prompt 01 — Theme tokens

Скопируй целиком в Agent:

---

Ты внедряешь **только тему** Fitness Yoda по дизайн-пакету. Код экранов не рефакторить, кроме если что-то сломается от ThemeData.

## Прочитай

- `app/design/tokens.md`
- `app/design/README.md`
- `app/design/crops/04_button_next.png`
- `app/design/crops/05_bottom_nav.png`
- текущий `app/fitness_app/lib/app/theme/app_theme.dart`

## Сделай

1. Добавь `app/fitness_app/lib/app/theme/app_colors.dart` с константами из `tokens.md` (primary `#166246`, surface white, canvas `#F1F7F5`, text `#2E2E2E`, secondary `#6F9E8F`, mint `#57CEA8`, и производные).
2. Перепиши `AppTheme.light()`:
   - явный `ColorScheme` (не полагаться только на `fromSeed`);
   - `scaffoldBackgroundColor` = canvas;
   - primary = `#166246`;
   - card radius 20, soft shadow или surface white на canvas;
   - `FilledButton` → height 52–56, `StadiumBorder`, primary fill;
   - `NavigationBar` indicator под mint soft pill (как сможешь через theme);
   - input: подготовка к card-style (можно упрощённо: fill white, radius 16, без тяжёлого outline).
3. Dark theme: либо минимальный осмысленный dark на той же палитре, либо оставь dark как есть но light — строго по токенам. Предпочтение: light = source of truth.
4. Не добавляй google_fonts в этом шаге (отдельным PR позже), если не попросят.

## Не делай

- Новые экраны, bottom nav shell, правки copy.
- Смену архитектуры Bloc.

## Done

- [ ] `AppColors` существует
- [ ] Login/Home визуально уже «зелёнее» без правок layout
- [ ] `flutter analyze` clean на theme файлах

Референс кнопки: stadium deep green. Референс фона: не чисто белый scaffold.
