# Промпты внедрения дизайна

Использовать **по одному** в Agent mode. Не склеивать всё сразу.

Перед каждым промптом агент должен прочитать:

- `app/design/tokens.md`
- соответствующий `app/design/components/*.md`
- указанные `app/design/crops/*.png` (визуальный якорь)

После шага — `flutter analyze` по затронутым файлам, UI на симуляторе.

| # | Файл | Что делает |
|---|------|------------|
| 01 | `01-theme-tokens.md` | Цвета / ThemeData |
| 02 | `02-buttons.md` | Кнопки в теме + опциональный виджет |
| 03 | `03-cards-inputs.md` | Card / InputDecoration / shared widgets |
| 04 | `04-navigation-shell.md` | Bottom nav shell |
| 05 | `05-auth-screens.md` | Login / Register |
| 06 | `06-home-schedule.md` | Home + schedule screens |

Код приложения: `app/fitness_app/`.  
**Не** менять API / Bloc логику без явной необходимости.
