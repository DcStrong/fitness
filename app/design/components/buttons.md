# Component: Buttons

Реф: `crops/04_button_next.png`, `crops/03_button_calculate.png`, `crops/05_button_get_started.png`

## Implementation

Flutter: `lib/core/widgets/fy_button.dart` (`FyButton`).

Auth/form shorthand: `FyPrimaryButton` → `FyButton.primary` (large), optional trailing arrow.

**Всегда** `StadiumBorder` (pill / капсула). Не использовать «чуть скруглённый прямоугольник» — он выглядит квадратным на полной ширине.

| Size | Height | Где |
|------|--------|-----|
| `large` | 54 | auth, forms, screen-level CTA |
| `medium` | 44 | card actions (inbox), sheets, dense stacks |

| Variant | Style |
|---------|-------|
| `primary` | filled `#166246` / onPrimary |
| `secondary` | outlined primary 1.5, white fill |
| `danger` | outlined `#C62828` |
| `soft` | filled `#F3EDE4` / textPrimary — quiet utility |

```dart
FyButton.primary(label: 'Принять', icon: Icons.check_rounded, size: FyButtonSize.medium, onPressed: …);
FyButton.secondary(label: 'Другое время', icon: Icons.event_available_outlined, size: FyButtonSize.medium, onPressed: …);
FyButton.danger(label: 'Отклонить', icon: Icons.close_rounded, size: FyButtonSize.medium, onPressed: …);
```

Theme `filledButtonTheme` / `outlinedButtonTheme` остаются stadium + 54 для raw Material fallback; новый UI пишет через `FyButton`.

## Primary (Filled / Stadium)

| Prop | Value |
|------|-------|
| Background | `#166246` |
| Foreground | `#FFFFFF` |
| Height | large 54 / medium 44 |
| Shape | `StadiumBorder` (pill) |
| Width | full width в формах и карточках (минус padding) |
| Label | 16 (large) / 15 (medium) SemiBold, centered |
| Leading icon | optional, 18–20px |
| Trailing | optional white arrow via `FyPrimaryButton(showTrailingArrow: true)` |
| Disabled | primary @ 40% или soft muted |
| Pressed | Material ink / slight darken |

**Варианты label:** `Далее`, `Войти`, `Принять`, `Назначить это время` — один primary CTA на визуальный блок.

## Secondary (Outlined)

| Prop | Value |
|------|-------|
| Border | 1.5 `#166246` |
| Text / icon | `#166246` |
| Fill | white |
| Shape | stadium |
| Height | large 54 / medium 44 |

Использовать: «Другое время», «Показать ещё», cancel-adjacent, secondary actions.

## Danger (Outlined)

Как secondary, но `#C62828` — «Отклонить», destructive confirms.

## Soft (Filled quiet)

| Prop | Value |
|------|-------|
| Fill | `#F3EDE4` |
| Text | `#2E2E2E` |
| Shape | stadium |

Использовать: «Скопировать на Пн–Пт» и похожие utility на availability (когда экран появится).

## Tertiary / Text

- Text `#166246` или `#6F9E8F`
- Для «Выйти», «Пропустить», links — пока `TextButton` темы

## FAB

Для создания слота предпочтительнее labelled extended FAB / `FyButton` pill, не круглый FAB. Copy: «+ Свободное время».
