## Context

Сегодня тренер наполняет доступность вручную: `POST /schedule/slots` создаёт разовые `ScheduleSlot`, а вкладка «Доступность» (`CoachSlotsScreen`) — stateful CRUD-список с жёсткой длительностью 1 час. `seriesId` на слоте nullable и не используется. Календарный workspace уже разделяет «Календарь / Заявки / Доступность»; one-off путь «Свободное время» (`FreeTimeSheet`) живёт в «Календаре».

Booking/finance остаются pay-per-session: цена слота для ученика = `defaultSessionPriceMinor`. Overlap open-слотов — app-level (half-open) + coach-row `pessimistic_write` в транзакциях booking. Полный DB `EXCLUDE` gist — вне scope.

Этот change реализует **Слой A** из `docs/design/availability-recurring-booking.md`: настройки + недельный шаблон + исключения + fixed-grid генератор + Flutter-редактор. Слой B (`add-recurring-booking`) и абонементы (`add-session-packages`) не входят.

## Goals / Non-Goals

**Goals:**

- Дать тренеру настройки длительности/перерыва/горизонта и IANA timezone.
- Сохранить недельный шаблон окон (Пн–Вс) и date exceptions.
- Материализовать бронируемые `ScheduleSlot` по фиксированной сетке идемпотентно, уважая booked/held и one-off слоты.
- Расширить schedules API без breaking changes для list/create/delete slots.
- Заменить UI «Доступность» редактором по концепту `docs/assets/fitness-yoda-availability-fixed-grid-v1.png`.

**Non-Goals:**

- Recurring booking ученика, пакеты занятий, изменения finance.
- Произвольный старт внутри окна (не фикс-сетка).
- PostgreSQL gist overlap, group capacity, gym, web console, drag-and-drop, push.

## Decisions

### 1. Отдельная сущность `CoachScheduleSettings`, не Finance

Новая таблица `coach_schedule_settings` (1:1 с coach):

| Поле | Смысл |
|---|---|
| `coachId` (PK/unique) | владелец |
| `timezone` | IANA, напр. `Europe/Moscow` |
| `defaultDurationMinutes` | базовая длительность (> 0) |
| `breakMinutes` | перерыв ≥ 0 (default 0) |
| `horizonWeeks` | горизонт генерации (default 8, разумный max) |
| `onlineDurationMinutes` / `offlineDurationMinutes` | nullable; если null — берётся default |
| `defaultMode` | `online` \| `offline` для генерируемых слотов (default `offline`) |

Альтернатива — расширить `CoachFinanceSettings`. Отклонена: финансы и график разные bounded contexts; цена остаётся в finance.

### 2. Шаблон = `ScheduleSeries` + окна + исключения

- `schedule_series`: id (= `seriesId` на слотах), `coachId`, `kind=weekly_availability`, timestamps. Один активный weekly-series на тренера на MVP (upsert).
- `availability_windows`: `seriesId`, `dayOfWeek` (1=Mon … 7=Sun), `startMinute` / `endMinute` (локальные минуты от полуночи, half-open), опциональный `mode` override.
- `availability_exceptions`: `seriesId`, `localDate` (YYYY-MM-DD в timezone тренера), `type` (`closed` | `custom_hours`), при `custom_hours` — набор окон на дату.

Окна внутри одного дня не должны пересекаться. Валидация `endMinute > startMinute` и границ 0…24×60.

Альтернатива — JSON blob в settings. Отклонена: сложнее валидировать, индексировать и тестировать.

### 3. Fixed-grid алгоритм (чистая функция)

Для каждого календарного дня горизонта:

1. Взять окна дня из шаблона; если есть exception `closed` — окон нет; если `custom_hours` — только они.
2. Для каждого окна в локальном времени: `step = durationMinutes + breakMinutes`; старты `windowStart, windowStart+step, …` пока `start + duration ≤ windowEnd`.
3. Конвертировать каждый кандидат в UTC (`timestamptz`) через timezone серии.
4. Слот создаётся только если целиком помещается (пример: 09:00–13:00, 60+15 → 09:00–10:00, 10:15–11:15, 11:30–12:30).

Duration для кандидата: per-mode override если задан, иначе `defaultDurationMinutes`. Mode слота — window override → `defaultMode`.

Алгоритм живёт в чистом util/helper без Nest DI; service только оркестрирует persistence. Unit-тесты покрывают границы, DST spring-forward/fall-back и пустые окна.

### 4. Идемпотентная генерация под coach lock

`POST /schedule/availability/generate` (или эквивалент):

1. Транзакция + `pessimistic_write` на строку coach user (как booking).
2. Загрузить settings + series + windows + exceptions + существующие слоты coach в `[now, horizonEnd]` (все статусы) и pending holds.
3. Вычислить desired set кандидатов с `seriesId`.
4. **Insert** только те open-кандидаты, чей `[startsAt, endsAt)` не пересекается ни с одним существующим слотом coach (open/booked/blocked) — half-open overlap.
5. **Не удалять и не обновлять** booked/held/one-off/`seriesId=null` слоты.
6. Опционально для MVP sync: удалять только `open` слоты с этим `seriesId` без pending hold, которых больше нет в desired set (после смены шаблона). Не трогать booked/held даже если шаблон их «исключил».
7. Вернуть summary: `created`, `skippedExisting`, `skippedConflict`, `removedOrphanOpen` (если sync включён).

Повторный generate без изменений шаблона → `created=0`. One-off слоты (`seriesId=null`) остаются и блокируют пересекающиеся кандидаты.

Альтернатива — всегда wipe+recreate всех series-слотов. Отклонена: ломает booked/held и заявки.

### 5. API surface под существующим `/schedule`

Переиспользовать permissions `schedules:create|read_own|delete_own` (генерация/шаблон = create; чтение = read_own). Новые permission codes не обязательны.

Предлагаемые endpoints (имена могут уточняться в OpenAPI, семантика фиксирована):

| Method | Path | Назначение |
|---|---|---|
| `GET/PUT` | `/schedule/availability/settings` | читать/upsert settings |
| `GET/PUT` | `/schedule/availability/template` | читать/upsert series+windows |
| `GET/PUT` | `/schedule/availability/exceptions` | list/replace exceptions (или CRUD по id) |
| `POST` | `/schedule/availability/generate` | материализация слотов |
| `GET` | `/schedule/availability/preview?from&to` | опционально: кандидаты без записи (для UI preview) |

Существующие `POST/GET/DELETE /schedule/slots` и `GET /schedule/coaches/:id/slots` без breaking changes. `listOwn(from,to)` продолжает отдавать все слоты включая сгенерированные.

### 6. Flutter: отдельный Cubit редактора

- Расширить `ScheduleRepository` методами settings/template/exceptions/generate/(preview).
- Новый `AvailabilityEditorCubit` + Page/View под вкладкой «Доступность» в `trainer_calendar_page` (замена `CoachSlotsScreen`).
- UI-блоки: «Настройки графика», «Рабочая неделя» (day chips Пн–Вс), список окон дня с time pickers и удалением, «+ Добавить часы», «Скопировать на Пн–Пт», предпросмотр сетки, «Исключения».
- Widgets: `FyButton` (pill), `FyInputCard`, `FyCard`; day-of-week picker — новый shared/feature widget (готового нет); `CalendarDateStrip` — для исключений/дат где уместно.
- Networking только в repository; View — loading/empty/error/saving/generating/success.
- One-off `FreeTimeSheet` не переносится во вкладку «Доступность».

### 7. Локальное время тренера — источник шаблона

Шаблон хранит локальные минуты + IANA timezone в settings. Сервер всегда материализует UTC. Клиент редактирует локальные часы в timezone settings (по умолчанию — device timezone при первом создании settings, с возможностью смены). Preview на клиенте может считать локально теми же правилами, но источником истины после generate остаётся API list slots.

### 8. Финансы и booking не меняются

Сгенерированные open-слоты участвуют в существующих student requestable list и coach book flows. Charge по-прежнему на фактическую Session; цена = finance default. Нет полей цены на шаблоне.

## Risks / Trade-offs

- [DST сдвигает локальные окна] → конверсия через IANA timezone + явные unit-тесты spring/fall; слоты хранятся как absolute UTC.
- [Параллельный generate и booking] → один coach-row lock сериализует; generate пропускает overlapping existing.
- [Смена шаблона оставляет «лишние» open series-слоты] → sync удаляет только orphan **open unheld** series slots; booked/held сохраняются (возможны «дыры» относительно нового шаблона — ожидаемо).
- [Preview на клиенте разойдётся с сервером] → опциональный server preview endpoint; после generate UI обновляет calendar/slots из API.
- [Нет gist overlap] → generator + createSlot продолжают app-level overlap checks; hardening — отдельная задача.
- [Долгая генерация на большом горизонте] → default 8 недель, cap horizon; bulk insert в одной транзакции.

## Migration Plan

1. Добавить таблицы settings/series/windows/exceptions + FK; существующие слоты без `seriesId` остаются one-off.
2. Задеплоить API endpoints (feature-flag не обязателен: UI ещё старый).
3. Обновить Flutter: repository → Cubit → заменить вкладку «Доступность»; сохранить FreeTimeSheet.
4. E2E: upsert template → generate → listOwn видит слоты; повторный generate идемпотентен; booked/held не затираются.
5. Rollback: откатить Flutter на `CoachSlotsScreen`; API settings/generate можно оставить (безвредно) или удалить таблицы после отсутствия клиентов.

## Open Questions

Блокирующих нет. Принятые MVP defaults:

- `horizonWeeks` default = 8;
- week starts Monday;
- один active weekly series на coach;
- generate sync удаляет orphan open unheld series-slots;
- server-side preview желателен, но клиентский preview допустим в первой итерации, если совпадает алгоритм.
