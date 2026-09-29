## 1. Availability editor help and copy-all-days

- [x] 1.1 Add shared field-help affordance (icon + Russian copy sheet/tooltip) and wire it on duration, break, horizon, windows, and exceptions labels in `availability_editor_page.dart`
- [x] 1.2 Change cubit copy to replace windows for days 1…7; rename UI to «Скопировать на каждый день»; show SnackBar on success
- [x] 1.3 Update `availability_editor_cubit_test` (and widget test copy if present) for all-days behavior and copy label

## 2. Day navigation and timeline fix

- [x] 2.1 Show prev/next in `CalendarToolbar` for `CalendarMode.day` and verify strip advances across week boundaries
- [x] 2.2 Fix `CalendarDayTimeline` hour range + placement so out-of-slot events (e.g. 21:00) align to hour labels without blank gaps
- [x] 2.3 Add/adjust widget or unit tests for day shift and evening event placement

## 3. Alternate-time occupancy month picker

- [x] 3.1 Extract or wrap reusable month occupancy grid + day agenda for picker use (from `CalendarMonthView` / calendar event loading)
- [x] 3.2 Replace bare `showFyDatePicker` in `_AlternateSheet` with month occupancy → day inspect → time confirm flow
- [x] 3.3 Manual smoke: inbox «Другое время» shows busy markers and submits alternate DateTime

## 4. Students filter and Home upcoming collapse

- [x] 4.1 Extend `SessionPackagesCubit` load with pending inbox; categorize rows (Ожидает > Оплачен > Не оплачен); add filter chips on `SessionPackagesView`
- [x] 4.2 Add cubit/unit tests for filter categorization and chip filtering
- [x] 4.3 Add `upcomingExpanded` / `toggleUpcoming` to Home cubit/state/view mirroring History; default expanded
- [x] 4.4 Update Home tests for collapse/expand upcoming

## 5. Verification

- [x] 5.1 Run focused Flutter tests for availability, calendar, packages, home touched by this change
- [x] 5.2 Manual smoke on Flutter web/mobile: availability help+copy, day arrows, timeline 21:00, alternate month picker, students filter, Home upcoming collapse
