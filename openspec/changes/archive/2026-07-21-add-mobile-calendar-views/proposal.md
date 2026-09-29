## Why

Текущий мобильный экран расписания показывает разрозненные списки и не даёт тренеру быстро оценить загрузку конкретного дня, недели или месяца. После появления booking requests нужен единый календарный workspace, который различает подтверждённые тренировки, свободное время и ожидающие решения заявки без переноса desktop-сетки на узкий экран.

## What Changes

- Заменить trainer schedule management screen на единый раздел «Расписание» с верхними вкладками «Календарь», «Заявки» и «Доступность».
- Добавить внутри «Календаря» переключатель «День / Неделя / Месяц» с сохранением выбранного периода при переходе между представлениями; переключатель остаётся sticky над прокручиваемым телом календаря.
- Реализовать day mode по согласованному макету: горизонтальная лента 7 дат, заголовок выбранного дня, вертикальный таймлайн с часовыми метками и карточками событий на шкале (не плоский список); типы визуально различимы: подтверждённая тренировка, свободное время и pending-заявка.
- Реализовать mobile-first week overview как вертикальный список семи дней с количеством событий и раскрываемым preview выбранного дня, а не как семь узких колонок.
- Реализовать month grid с индикаторами типов событий и компактной agenda выбранной даты под сеткой.
- Добавить навигацию по предыдущему/следующему периоду и действие возврата к текущей дате.
- Переименовать неоднозначное действие «Добавить слот» в pill FAB «+ Свободное время». Оно открывает существующий one-off slot flow с датой, началом, окончанием и форматом `online|offline`.
- Показывать badge с числом pending на вкладке «Заявки»; карточки pending в inbox выравнивать по concept: порядок «Принять» → «Другое время» → «Отклонить», compact height, filled / outlined primary / outlined error.
- Использовать фактическую role-aware нижнюю навигацию тренера: «Главная», «Расписание», «Ученики», «Профиль»; не добавлять «Сообщения» или «Аналитику».
- Сохранить Fitness Yoda visual language, loading/empty/error/retry состояния и доступность на узких экранах.
- Visual source of truth for day layout: mockup comparison in workspace assets (date strip + timeline); mode switcher `День / Неделя / Месяц` остаётся sticky над лентой дат; inbox actions — `fitness-yoda-trainer-calendar-concept.png`.

## Non-goals

- Изменение NestJS API, TypeORM entities, calendar/booking invariants или permission catalog.
- Недельные recurrence rules, массовая генерация слотов и date overrides; ими владеет отдельный change availability.
- Создание чата, сообщений, аналитического раздела или новых bottom-navigation destinations.
- Desktop-style seven-column week grid, drag-and-drop, resize событий и landscape-only интерфейс.
- Редактирование Session lifecycle, финансов и заявки непосредственно из календарной карточки; карточка ведёт в соответствующий detail/action flow.
- Student booking redesign, web calendar, push/realtime и внешняя синхронизация календарей.

## Capabilities

### New Capabilities

- `mobile-calendar-views`: trainer-facing day/week/month calendar, unified event presentation, period navigation and quick one-off availability action.

### Modified Capabilities

- `mobile-schedule-booking`: trainer schedule management becomes the «Календарь / Заявки / Доступность» workspace and uses «Свободное время» for manual one-off availability.

## Impact

- Flutter `app/fitness_app`: schedule feature presentation/state, period calculations, API aggregation, reusable calendar event view models and widget tests.
- Existing `ScheduleRepository` calls for sessions and slots are reused with UTC `from`/`to` boundaries derived from the device timezone; pending requests use contracts from prerequisite change `add-booking-requests`.
- Routing keeps the existing `/schedule` destination and trainer shell branches; no new bottom-navigation branch is introduced.
- UI follows `docs/mobile/tooling.md`, current theme tokens and shared widgets. Visual reference: `/Users/dc_strong/.cursor/projects/Users-dc-strong-myProject-fitness/assets/fitness-yoda-calendar-day-week-month-v2.png`.
- Tests cover period boundaries, timezone conversion, event-type mapping, mode switching, selected-day behavior and narrow-screen rendering.
