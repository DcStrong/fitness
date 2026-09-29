## Why

Asymmetric bento на главной тренера уже есть после `polish-trainer-home-bento`, но экран ещё не совпадает с иерархией `app/design/generated/mock-home-c-asymmetric-bento.png`: нет date chip, stat-карточек с иконкой, timeline «Сегодня» с аватарами, мини-графика недели внутри высокой плитки «Расписание» и кнопок «Перейти». Сплошной mint fill читается тяжелее, чем белые soft-cards на mock.

## What Changes

- Date chip в header главной тренера (текущая локальная дата, без нового API).
- Stat cards: иконка + label + число вместо плоских chips (сегодня, заявки, недельная метрика).
- Секция «Сегодня» как timeline с аватарами контрагента, если аватар уже есть в payload; иначе инициалы.
- Внутри tall-плитки «Расписание» — мини-график недели по уже загруженным сессиям.
- Кнопки «Перейти» на ключевых плитках bento, те же маршруты.
- Белые soft-cards вместо сплошного mint fill; mint остаётся акцентом.
- Третий stat: «Свободно» только если число собирается из уже загруженных данных без нового API; иначе оставить «На неделе».

## Non-goals

- Новые Nest endpoints и смена контрактов.
- Dark theme.
- Pixel-perfect до пикселя относительно mock.
- Student hub и редизайн главной ученика.

## Capabilities

### New Capabilities

- (нет)

### Modified Capabilities

- `mobile-home-dashboard`: визуальная иерархия главной тренера к mock C — date chip, icon stat cards, timeline с аватарами, week sparkline в «Расписание», «Перейти», белые soft-cards, метрика «Свободно» только из существующих данных.

## Impact

- Flutter: `app/fitness_app` feature home (header, stat row, today timeline, bento «Расписание»).
- Якорь: `app/design/generated/mock-home-c-asymmetric-bento.png`.
- Widget-тесты главной тренера под новую иерархию.
- Backend и web без изменений.
