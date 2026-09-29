## Context

Тренерский Flutter UX уже закрывает календарь (день/неделя/месяц), редактор доступности, inbox заявок с alternate-time, Home и «Ученики и абонементы». После ручного QA нужны точечные UX-правки без Nest API. State: Bloc/Cubit only; UI Russian; reuse `core/widgets` и существующих calendar projection helpers.

## Goals / Non-Goals

**Goals:**

- Понятность полей доступности (help) и копирование окон на все 7 дней с SnackBar.
- Alternate-time выбор даты через месячную сетку занятости + просмотр дня.
- Day-mode prev/next (±1 день); корректный timeline для событий вне дефолтных часов.
- Фильтр учеников Оплачен / Не оплачен / Ожидает; сворачивание «Предстоящие» на Home.

**Non-Goals:**

- Изменения Nest API, web_app, push, dark theme, полный redesign календаря.
- Использование finance ledger как единственного источника «оплачен».

## Decisions

1. **Help affordance** — `Icons.help_outline` рядом с лейблами настроек/окон/исключений; по tap — `Tooltip` на desktop/web и короткий bottom sheet / dialog с русским текстом на touch (один shared helper, без нового dependency).

2. **Copy to every day** — переименовать action и cubit method в смысл «all days»: заменить окна дней `1…7` копией окон выбранного дня; Сб/Вс больше не сохраняются отдельно при copy. UI: SnackBar «Скопировано на каждый день» после успешного apply в state (до Save).

3. **Alternate occupancy picker** — из `_AlternateSheet` открывать fullscreen/route sheet, который:
   - грузит calendar events за видимый месяц теми же репозиториями, что `CalendarBloc`;
   - рендерит переиспользуемую month grid (extract shared widget из `CalendarMonthView` или wrap с `readOnly` occupancy);
   - по выбору дня показывает agenda занятости;
   - затем `showTimePicker` → возвращает `DateTime`.
   Без нового API.

4. **Day chevrons** — убрать `mode != day` guard в `CalendarToolbar`; оставить date strip. `shiftAnchor(day, ±1)` уже есть. Spec period navigation уже требует day next — UI догоняет спеку.

5. **Student filter categorization** (взаимоисключающая, приоритет):
   1. **Ожидает** — `studentId` встречается в pending inbox (`BookingRequestsRepository.inbox`);
   2. **Оплачен** — `SessionPackage.status == active`;
   3. **Не оплачен** — linked student без active package.
   Chip «Все» по умолчанию. Cubit грузит relationships + packages + pending inbox в одном `load()`.

6. **Upcoming collapse** — `upcomingExpanded` default `true` (в отличие от history `false`); тот же header+chevron паттерн, что у History.

7. **Timeline fix** — hour range = union(default 8–20, event extents); `_placeEvents` позиционирует по `top` от реального start относительно `startHour`; overlap-стек не должен уводить карточку так, будто она «перепрыгнула» час-метки (clamp / column layout within true time band; если overlap — вертикальный стек только внутри пересекающегося интервала, высота контейнера растёт с hour rows, не создавая дыр между labels и card).

## Risks / Trade-offs

- [Pending students not in relationships] → API create требует active link; всё равно merge по `counterpart.id` из inbox. Если pending без row — добавить synthetic row с меткой «Ожидает».
- [Month picker data cost] → грузить только visible month range; кэш в sheet state.
- [Overlap vs absolute time] → приоритет корректного clock alignment над плотным стеком; читаемость пересечений сохраняем минимальным сдвигом с визуальной привязкой к start.

## Migration Plan

Нет миграций данных. Выкат: Flutter-only. Откат: revert change.

## Open Questions

_(нет — решения зафиксированы с продуктом: фильтр на «Ученики и абонементы», статусы Оплачен/Не оплачен/Ожидает.)_
