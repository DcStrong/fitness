## Context

После archived change `polish-trainer-home-bento` главная тренера уже грузит день и неделю, рисует `HomeWeekStrip`, `HomeStatChips` и `HomeBentoShortcuts`. Якорь визуала — `app/design/generated/mock-home-c-asymmetric-bento.png`. Session row на Home показывает имя контрагента без аватара; отдельного photo URL в home payload нет. Свободные слоты на Home не считаются.

## Goals / Non-Goals

**Goals:**

- Приблизить иерархию главной тренера к mock C: date chip, stat cards (иконка + label + число), timeline «Сегодня» с аватаром/инициалами, sparkline недели внутри tall «Расписание», «Перейти», белые soft-cards.
- Оставить текущие маршруты, collapse, refresh, pending count и загрузку недели.
- «Свободно» показывать только если число уже есть в загруженном состоянии без нового запроса.

**Non-Goals:**

- Nest API, dark theme, pixel-perfect, student hub и смена главной ученика.

## Decisions

1. **Date chip в header тренера.** Отдельный chip с локальной датой («Сегодня, …» / дата) рядом с заголовком Home. `HomeWeekStrip` остаётся: spec уже требует полоску недели, mock её не отменяет.
2. **Stat cards вместо однострочных chips у тренера.** Три карточки: иконка, подпись, число. «Сегодня» — count дня. «Заявки» — только при успешном pending count (включая 0 без «срочного» оформления, если count = 0 карточка может быть спокойной, без фейкового нуля при ошибке). Третья: label «На неделе» и `weekCount`. Label «Свободно» — только если в `HomeState` уже лежит free-slot count из существующих данных; нового repository/API нет. Студенческие chips не трогаем.
3. **Timeline «Сегодня».** Строки дня с вертикальной шкалой времени и круглым аватаром: network image только если URL уже есть на модели; иначе инициалы из имени контрагента. Пустой день — прежний empty copy.
4. **Sparkline внутри «Расписание».** Семь столбиков по числу booked sessions уже загруженной недели. Тап по плитке и «Перейти» ведут на `/schedule`, как сейчас вся плитка.
5. **Поверхности.** Bento и stat cards — белый/canvas soft surface, mint только акцент (иконка, график, chip). Сплошной mint fill у тренерских плиток убираем.
6. **«Перейти».** Текстовая кнопка на tall «Расписание» и full-width «Регулярные тренировки»; вся карточка остаётся tappable в тот же route.

## Risks / Trade-offs

- [Mock плотнее текущего strip + timeline] → Не удаляем week strip, чтобы не сломать requirement мини-календаря; визуально уплотняем отступы.
- [«Свободно» на mock, данных нет] → Остаёмся на «На неделе», чтобы не выдумывать слоты.
- [Нет photo URL] → Инициалы; не добавляем загрузку профиля ради аватара.

## Migration Plan

Только Flutter UI и widget-тесты. Откат — revert виджетов Home. API не мигрируем.

## Open Questions

- Нет. Если позже появится free-slot в уже загруженном state, третья карточка переключается на «Свободно» без отдельного change API.
