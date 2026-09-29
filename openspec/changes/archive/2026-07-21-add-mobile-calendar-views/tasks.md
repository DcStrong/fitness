## 1. Prerequisites and data access

- [x] 1.1 Verify that `add-booking-requests` has been applied and that Flutter exposes a repository/model for listing trainer pending requests by visible time range.
- [x] 1.2 Extend `ScheduleRepository.listOwnSlots` with optional `from`/`to` parameters, serialize them as UTC ISO-8601 query values, and preserve existing parameterless callers.
- [x] 1.3 Add repository tests for slot range parameters and confirm that no new Flutter runtime dependency is required.

## 2. Calendar domain projection

- [x] 2.1 Add `CalendarMode`, `CalendarRange` and pure local day/week/month boundary calculations with Monday as the first weekday.
- [x] 2.2 Add immutable `CalendarEvent` models for Session, free availability and pending request source records.
- [x] 2.3 Implement chronological mapping, booked-slot deduplication and pending-request precedence over held free slots.
- [x] 2.4 Add unit tests for normal, cross-month, leap-month and DST-sensitive period boundaries and UTC serialization.
- [x] 2.5 Add unit tests for event labels, sorting, terminal Session presentation and slot/request/session deduplication.

## 3. Calendar state management

- [x] 3.1 Add feature-scoped `CalendarCubit` and Equatable state for mode, anchor date, selected date, events, source status and refresh state.
- [x] 3.2 Load Sessions, own slots and pending requests for the visible range without introducing Bloc-to-Bloc dependencies.
- [x] 3.3 Preserve existing content during refresh and implement degraded warning behavior when only the booking-request source fails.
- [x] 3.4 Implement previous/next period, «Сегодня», date selection and mode-switch actions with cubit tests.

## 4. Schedule workspace shell

- [x] 4.1 Add `TrainerCalendarPage` that provides `CalendarCubit` from existing repository providers and a thin `TrainerCalendarView`.
- [x] 4.2 Replace the trainer branch of `ScheduleLandingScreen` with the calendar page while leaving student and fallback branches unchanged.
- [x] 4.3 Build the «Календарь / Заявки / Доступность» top tabs and retain calendar mode/date state while switching tabs.
- [x] 4.4 Wire «Заявки» to the booking-request inbox and keep «Доступность» on supported one-off management until recurring availability exists.

## 5. Day, week and month views

- [x] 5.1 Build the shared «День / Неделя / Месяц» segmented control, period title, previous/next controls and conditional «Сегодня» action.
- [x] 5.2 Build day agenda with chronological event cards, readable overlap stacking and empty state.
- [x] 5.3 Build Monday-through-Sunday week rows with type/count summaries and one expanded selected-day agenda.
- [x] 5.4 Build Monday-first month grid with adjacent dates, semantic event indicators, legend and selected-day agenda.
- [x] 5.5 Add consistent Session, free-time and pending-request visual/semantic treatments using existing Fitness Yoda tokens and shared widgets.

## 6. One-off free-time flow

- [x] 6.1 Replace «Добавить слот» copy with «Свободное время» / «Добавить свободное время» throughout the trainer schedule UI.
- [x] 6.2 Add a bottom-sheet form for local date, start, end and `online|offline` mode with inline interval validation.
- [x] 6.3 Submit through the existing create-slot API, keep recoverable API errors in the form, and refresh/focus the created date on success.

## 7. Navigation and accessibility

- [x] 7.1 Preserve the existing `/schedule` `go_router` branch and verify `AuthCubit` role selection still sends trainers to calendar and students to their existing booking flow.
- [x] 7.2 Verify the trainer bottom navigation remains exactly «Главная / Расписание / Ученики / Профиль» and marks «Расписание» selected.
- [x] 7.3 Add semantic labels and adequate touch targets for mode controls, dates, period navigation, indicators and event cards without relying on color alone.
- [x] 7.4 Verify day/week/month layouts at narrow and standard phone widths without horizontal page overflow or nested-scroll conflicts.

## 8. Tests and delivery verification

- [x] 8.1 Add widget tests for initial day mode, mode switching, period navigation, «Сегодня», selection persistence and empty/error/retry states.
- [x] 8.2 Add widget tests for week expansion, month date selection, mixed event indicators and request-source degraded warning.
- [x] 8.3 Add widget tests for the free-time form validation, successful refresh and mapped API errors.
- [x] 8.4 Run `dart format`, `flutter analyze` and all relevant schedule/calendar unit and widget tests.
- [x] 8.5 Manually smoke test against the local NestJS API with confirmed Sessions, open slots and pending requests across day/week/month modes.
- [x] 8.6 Compare the implemented standard-width screens with `fitness-yoda-calendar-day-week-month-v2.png` and record intentional deviations in the change notes.

## Implementation Notes

- Pending requests have no API `from`/`to` filter; the calendar loads trainer inbox `status=pending` (limit 50) and filters client-side by the visible local range.
- `listOwnSlots` sends UTC `from`/`to` and also applies a client-side start-time filter as a correctness fallback for older backends.
- Trainer bottom navigation no longer includes a separate «Заявки» item; inbox lives under schedule top tab «Заявки» (Home pending badge still deep-links to `/booking-requests/inbox`).
- Reference assets: day layout mockup in workspace comparison screenshots; `fitness-yoda-calendar-day-week-month-v2.png` for day/week/month modes; `fitness-yoda-trainer-calendar-concept.png` for schedule tabs and pending inbox action order/styling. Amber request tint may remain a local calendar color rather than a new design-token entry.
- 2026-07-21 UI gap: shipped day mode still used a flat `CalendarAgenda` list and chevron date title; section 9 reopens presentation alignment to the timeline + date-strip mockup without changing domain/API decisions.
- 2026-07-21 UI alignment done: day mode now uses `CalendarDateStrip` + day title + `CalendarDayTimeline`; event cards use left accent bars; «Заявки» shows `pendingCount` badge; FAB is labelled «Свободное время». Intentional deviations vs mockup: keep `День/Неделя/Месяц` segmented control above the strip; FAB uses Material extended button with `+` icon + label rather than a custom pill; free-time soft fill uses warm beige local color; overlapping events stack vertically instead of exact concurrent time lanes.
- 2026-07-21 follow-up: sticky `CalendarToolbar` above the scrollable calendar body; pending inbox actions realigned to concept order («Принять» → «Другое время» → «Отклонить») with compact ~40 height and outlined error decline (section 10).
- Verification before UI alignment: `flutter analyze` clean; schedule/calendar tests passed; local API smoke confirmed ranged slots + pending inbox for a linked pair.
- Verification after UI alignment: schedule suite `46` tests passed; analyze clean on schedule feature paths.

## 9. Day UI alignment to mockup

- [x] 9.1 Replace day-mode chevron date title with a Monday–Sunday horizontal date strip that labels the current local date «Сегодня» and updates `selectedDate` on tap.
- [x] 9.2 Add the localized day title under the strip (e.g. «Пятница, 19 июля») while keeping `День / Неделя / Месяц` above the strip.
- [x] 9.3 Replace the flat day agenda list with an hour timeline: left hour labels, dashed guides, and event cards positioned by `startsAt`/`endsAt`.
- [x] 9.4 Restyle timeline cards with left accent bar, soft type fill, interval + participant/«Свободно» + mode/status label (not color alone); stack overlaps vertically.
- [x] 9.5 Show a numeric pending badge on the «Заявки» tab when count > 0.
- [x] 9.6 Ensure the free-time action is a labelled pill FAB «+ Свободное время» (not «Добавить слот» and not an unlabeled chevron control).
- [x] 9.7 Update day-mode widget tests for strip selection, day title, timeline presence, badge and FAB label; re-run analyze and relevant schedule tests.
- [x] 9.8 Manually compare standard-width day mode to the agreed mockup screenshot and note any intentional remaining deviations.

## 10. Sticky toolbar and inbox action alignment

- [x] 10.1 Pin `День / Неделя / Месяц` (and period navigation) above the scrollable calendar body so the toolbar stays visible while scrolling day/week/month content.
- [x] 10.2 Align pending inbox card actions to the trainer calendar concept: order «Принять» → «Другое время» → «Отклонить»; filled primary / outlined primary / outlined error; compact height (~40), not theme auth CTA 54.
- [x] 10.3 Record intentional remaining deviations and update planning notes / visual references for inbox concept asset.
