## Why

Вкладка «Доступность» сейчас — плоский CRUD разовых `ScheduleSlot` с зашитой длительностью 1 час. Тренер не может задать недельный график, длительность/перерыв и массово наполнить календарь бронируемыми слотами. Без Слоя A (генерация доступности) нельзя перейти к повторяющейся записи ученика (Слой B) и абонементам.

## What Changes

- Добавить настройки графика тренера: базовая длительность тренировки (минуты), опциональный перерыв, горизонт генерации; заложить optional per-mode duration (`online`/`offline`) с единым default.
- Добавить недельный шаблон рабочих окон (Пн–Вс, несколько окон в день) в локальном времени тренера с конвертацией границ в UTC; первый день недели — понедельник.
- Добавить исключения на конкретные даты: выходной или спец-часы, переопределяющие шаблон.
- Добавить генератор слотов по **фиксированной сетке** (шаг = длительность + перерыв): слот создаётся только если целиком помещается в окно; генерация идемпотентна, не дублирует существующие интервалы, не затирает `booked`/held слоты; сгенерированные слоты получают `seriesId` шаблона.
- Расширить schedules API: CRUD/чтение настроек, шаблона, исключений и операция генерации; сохранить обратную совместимость `listOwnSlots(from, to)` и one-off create/delete.
- Обновить Flutter «Доступность»: редактор «Настройки графика» + «Рабочая неделя» (чипы дней, окна, «+ Добавить часы», «Скопировать на Пн–Пт»), предпросмотр слотов, секция «Исключения»; UI через `FyButton` / `FyInputCard` / существующие shared widgets (концепт `docs/assets/fitness-yoda-availability-fixed-grid-v1.png`).
- Сохранить one-off путь «Свободное время» (`FreeTimeSheet`) поверх шаблона.

## Non-goals

- Повторяющаяся запись ученика за графиком (Пн/Ср/Пт 18:00) — следующий change `add-recurring-booking` (Слой B).
- Абонемент / лимит занятий — будущий change `add-session-packages`.
- Изменение модели финансов, предоплата, эквайринг; цена слота остаётся `defaultSessionPriceMinor`.
- Гибкий выбор произвольного старта внутри окна (вне фикс-сетки).
- Полный PostgreSQL overlap-hardening (`EXCLUDE` gist) — отдельная задача; используем app-level + coach lock.
- Групповые слоты (`capacity > 1`), gym, drag-and-drop, web coach console, push/realtime.

## Capabilities

### New Capabilities

- `mobile-availability`: Flutter-редактор доступности тренера — настройки длительности/перерыва/горизонта, недельный шаблон окон, исключения, предпросмотр и запуск генерации слотов.

### Modified Capabilities

- `calendar-domain`: доменные инварианты шаблона, исключений и fixed-grid генерации; использование `seriesId`; уважение booked/held при материализации слотов.
- `schedules-api`: endpoints настроек графика, недельного шаблона, исключений и генерации при сохранении list/create/delete one-off слотов.
- `mobile-schedule-booking`: вкладка «Доступность» перестаёт быть плоским CRUD-списком и открывает редактор шаблона; one-off «Свободное время» остаётся в календаре.

## Impact

- Backend `backend/api/src`: новые TypeORM entities + migration (settings, weekly windows, date exceptions, series identity), generation service с транзакцией и coach-row lock (как booking), расширение schedules module (DTO/controller/OpenAPI), unit + e2e тесты границ сетки/DST/идемпотентности.
- PostgreSQL: таблицы настроек/шаблона/исключений; `schedule_slots.series_id` начинает ссылаться на реальную серию шаблона.
- API `localhost:3001`: новые authenticated coach endpoints; существующие `listOwn` / create one-off / delete open / linked student list без breaking changes.
- Flutter `app/fitness_app`: расширение `ScheduleRepository`, отдельный Cubit редактора доступности, day-of-week picker, замена UI вкладки «Доступность»; переиспользование `FyCard`/`FyButton`/`FyInputCard`/`CalendarDateStrip` по `docs/mobile/tooling.md`.
- Тесты: unit (окна/сетка/DST/идемпотентность/booked-held), e2e шаблон+генерация, widget-тесты редактора.
- Предпосылка/референс: `docs/design/availability-recurring-booking.md`; visual SoT: `docs/assets/fitness-yoda-availability-fixed-grid-v1.png`.
