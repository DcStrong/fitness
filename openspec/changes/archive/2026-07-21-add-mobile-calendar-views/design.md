## Context

Trainer `/schedule` currently opens `CoachSlotsScreen`: a stateful list that loads only slots, creates a fixed one-hour offline slot through sequential date/time pickers, and does not show Sessions. Sessions live on a separate list screen, while pending requests will be introduced by prerequisite change `add-booking-requests`.

The target is the mobile concept at `/Users/dc_strong/.cursor/projects/Users-dc-strong-myProject-fitness/assets/fitness-yoda-calendar-day-week-month-v2.png`: one trainer workspace with `Календарь / Заявки / Доступность`, calendar modes `День / Неделя / Месяц`, and the existing trainer bottom navigation. The Flutter stack remains Bloc/Cubit, `go_router`, Dio repositories and existing Fitness Yoda widgets/tokens. No runtime dependency or backend change is required.

## Goals / Non-Goals

**Goals:**

- Combine open slots, booked Sessions and pending booking requests into a deterministic calendar projection.
- Give each period a mobile-native presentation rather than shrinking a desktop week grid.
- Keep local-time period boundaries correct across DST and convert API query boundaries to UTC.
- Preserve the existing `/schedule` route, role-aware app shell and one-off slot API.
- Make period logic and event mapping pure and testable independently from widgets.
- Support loading, degraded-source warning, failure, empty, refresh and narrow-screen states.

**Non-Goals:**

- Backend/API/schema/permission changes.
- Recurrence editing, date overrides, drag-and-drop or direct lifecycle/finance actions.
- Student calendar redesign, web/tablet week grid, realtime updates or persisted calendar preferences.

## Decisions

### 1. Replace trainer slot screen with a Page/View feature and `CalendarCubit`

`ScheduleLandingScreen` remains the role switch. Its trainer branch creates `TrainerCalendarPage`, which provides a feature-scoped `CalendarCubit`; `TrainerCalendarView` renders state and delegates user actions. The cubit depends on `ScheduleRepository` and, after `add-booking-requests`, `BookingRequestRepository`. It does not depend on `HomeCubit` or another Bloc.

State contains:

- `mode`: `day | week | month`;
- `anchorDate` and `selectedDate` in device-local time;
- calculated visible range;
- normalized calendar events;
- source loading/error metadata and refresh state.

Mode and selected date survive top-tab switches while the `/schedule` branch remains mounted, but are not stored on disk.

Alternative: continue adding `setState` and requests to `CoachSlotsScreen`. Rejected because three period calculations, parallel sources and refresh/error behavior require isolated, unit-testable state.

### 2. Calculate half-open ranges with calendar constructors

Pure `CalendarRange` functions calculate:

- day: `[local midnight, next local midnight)`;
- week: `[Monday local midnight, following Monday local midnight)`;
- month: `[first local day, first local day of next month)`.

The implementation uses calendar constructors such as `DateTime(y, m, d + 1)`, never fixed 24-hour multiplication, then repositories serialize boundaries with `toUtc().toIso8601String()`. Previous/next navigation shifts by one calendar day, seven calendar days, or one calendar month. «Сегодня» resets both anchor and selection.

Alternative: query a fixed rolling number of hours. Rejected because DST and month lengths would produce missing or duplicated local dates.

### 3. Normalize API records into one presentation model

A pure domain mapper creates `CalendarEvent` with:

- stable source id and `CalendarEventType` (`session`, `availability`, `request`);
- local `startsAt`/`endsAt`;
- title, secondary label and mode;
- source reference needed for navigation.

Only `open` slots render as free availability. A booked slot is represented by its Session, not twice. If a pending request and its held slot are both returned, the request has precedence and the free-slot event is suppressed. Terminal Sessions remain available to the selected period but use muted lifecycle styling; the three primary legend categories remain «Тренировка», «Свободно», «Заявка».

Alternative: let each view independently combine raw DTOs. Rejected because day/week/month would drift in filtering, precedence and labels.

### 4. Load only the visible period and tolerate an optional source failure

On mode/anchor changes, the cubit requests Sessions and own slots for the visible range in parallel. `ScheduleRepository.listOwnSlots` gains optional `from`/`to` query parameters while preserving calls without them. Pending requests are loaded for the same range from the prerequisite repository.

Sessions and slots are required sources: failure without previously loaded data produces the calendar error state. Booking requests are an additive source: if that request fails while schedule data succeeds, the calendar remains usable, shows a compact warning and offers refresh rather than claiming there are no pending requests. Refresh preserves current content until replacement data arrives.

Alternative: fetch the full history once and filter on-device. Rejected because payload and parsing cost grow without bound.

### 5. Use purpose-built mobile views for each mode

Shared chrome above the mode body: `День / Неделя / Месяц` segmented control (with period navigation / «Сегодня» as applicable) remains **sticky** above the scrollable calendar body so mode switching stays reachable while the trainer scrolls the day strip/timeline, week rows or month grid. Day mode MUST NOT reduce to a flat list of cards with only chevron date text.

- **Day (source of truth = agreed mockup):**
  1. Horizontal Monday–Sunday date strip for the week containing `selectedDate`; each cell shows weekday abbreviation and day number; the current local date shows a «Сегодня» label; selection uses mint highlight.
  2. Selecting a strip date updates `selectedDate` and the day body without leaving day mode; previous/next on the strip week shifts by seven calendar days when needed.
  3. Below the strip, a day title such as «Пятница, 19 июля».
  4. Vertical timeline: left hour labels (e.g. 08:00…), dashed horizontal guides, and event cards placed by `startsAt`/`endsAt` height/offset. Cards use a left accent bar and soft fill by type; content shows interval, participant or «Свободно», and mode/status with label+dot (not color alone).
  5. Overlapping records stack vertically within the timeline column rather than side-by-side columns.
  6. Rejected for day mode: centered «21 июля 2026» + chevrons only, and flat `FyCard` lists without hour guides.

- **Week:** seven vertical day rows with event counts/type indicators. Selecting a row expands a compact agenda preview below that row.
- **Month:** a seven-column date grid with small semantic type indicators. Selecting a date updates a compact agenda below the grid; event text is not squeezed into date cells.

Week and month keep previous/next period controls and «Сегодня». Day relies primarily on the date strip plus an optional «Сегодня» jump when the selected week does not contain today. Semantics announce date, type, interval and status without relying only on color. Mint denotes Sessions, neutral/beige outline denotes availability (or offline session treatment per mockup), and amber denotes pending requests.

Alternative: use a desktop week grid and full event titles in month cells. Rejected because the available phone width makes touch targets and text unreadable.

### 6. Keep top tabs inside the schedule feature

The header owns `Календарь / Заявки / Доступность`. `Календарь` hosts these three modes; `Заявки` embeds the inbox from `add-booking-requests` and shows a numeric badge with the current pending-request count when that count is greater than zero; `Доступность` routes to the availability editor when that change lands and otherwise keeps the current slot-management entry.

Pending inbox cards on «Заявки» follow the trainer calendar concept at `/Users/dc_strong/.cursor/projects/Users-dc-strong-myProject-fitness/assets/fitness-yoda-trainer-calendar-concept.png`: action order **«Принять» → «Другое время» → «Отклонить»**; filled primary / outlined primary / outlined error; compact control height (~40) rather than the theme auth CTA minimum (54). Lifecycle and API for those actions remain owned by `add-booking-requests`; this change only constrains presentation when the inbox is embedded in the schedule workspace.

The app-level bottom navigation remains exactly `Главная / Расписание / Ученики / Профиль`. The schedule feature MUST NOT introduce `Сообщения` or `Аналитика`.

Alternative: add each schedule subsection to bottom navigation. Rejected because they are local contexts of one primary destination, not app-level destinations.

### 7. Treat «Свободное время» as one-off availability

The primary calendar action is a bottom-right pill FAB labelled «+ Свободное время» (not domain «слот» and not an unlabeled chevron-only control). It opens a bottom sheet that collects local date, start, end and `online|offline`, validates `end > start`, and calls the existing `createSlot`. On success the sheet closes, the current range refreshes and focus returns to the created date.

This action remains useful after recurring availability as an exception/one-off path; recurrence itself is outside this change.

Alternative: remove the action and require switching to «Доступность». Rejected because manually created slots remain the only available inventory until recurring availability is delivered.

### 8. Reuse project visual primitives and add no calendar package

Views use current color tokens, typography, `FyCard`, info/error patterns and Material date semantics. Month and week layouts are small enough to implement with Flutter layout primitives; adding a calendar dependency would bring styling and behavior that must be overridden.

Widget keys are defined for mode selectors, period navigation, date cells and event rows to keep tests stable without coupling to text layout.

## Risks / Trade-offs

- [Slots endpoint does not apply `from`/`to` in an older backend] → Keep client-side range filtering as a correctness fallback and verify the deployed contract before removing it.
- [Pending request change is not applied first] → Calendar compiles behind the repository integration task only after `add-booking-requests`; Sessions and free slots remain independently testable.
- [DST changes period duration] → Build local calendar boundaries first and convert each boundary separately to UTC.
- [Many events make day/month agenda long] → Keep month cells summary-only and use one scroll owner per mode; week expands one day at a time.
- [Color-only status is inaccessible] → Pair color with labels/icons and semantic descriptions.
- [Parallel refresh briefly reorders events] → Emit one normalized replacement after required sources complete and retain stale content during refresh.

## Migration Plan

1. Apply and verify `add-booking-requests` contracts used for pending event projection.
2. Add pure calendar range/event models and tests.
3. Extend `ScheduleRepository.listOwnSlots` with backward-compatible optional range parameters.
4. Add `CalendarCubit`, Page/View and day/week/month widgets behind the existing trainer `/schedule` branch.
5. Replace the fixed one-hour create flow with the «Свободное время» bottom sheet.
6. Wire request/availability top tabs, preserve the current bottom shell and run widget tests on narrow and standard widths.
7. Roll back by restoring `CoachSlotsScreen` as the trainer branch; repository parameter additions remain backward compatible.

## Open Questions

Нет блокирующих продуктовых вопросов. Зафиксировано:

- default mode — «День»;
- week starts on Monday;
- day mode UI = 7-day strip + day title + hour timeline (mockup), not flat list;
- month cells show indicators plus selected-day agenda;
- quick action = pill FAB «+ Свободное время»;
- «Заявки» shows pending count badge;
- mode toolbar is sticky above the scrollable calendar body;
- pending inbox actions: «Принять» → «Другое время» → «Отклонить», compact height, concept styling;
- app bottom navigation remains `Главная / Расписание / Ученики / Профиль`.
