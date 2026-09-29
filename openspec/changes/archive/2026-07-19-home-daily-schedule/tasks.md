## 1. Data access

- [x] 1.1 Extend `ScheduleRepository.listSessions` with optional `from` and `to` values and send them as existing `/sessions` query parameters without changing current callers.
- [x] 1.2 Add repository tests that verify `from`, `to`, and optional `status` query serialization and API error mapping.
- [x] 1.3 Confirm the implementation reuses current Flutter/Dart capabilities and existing packages; do not add a runtime dependency for date formatting or time control.

## 2. Home feature state and time model

- [x] 2.1 Create `features/home` with `HomePage`/`HomeView`, an Equatable `HomeState`, and a feature-scoped `HomeCubit` backed by `ScheduleRepository`.
- [x] 2.2 Implement testable local-day boundary calculation using calendar midnights, UTC API conversion, initial load, retry, and manual refresh.
- [x] 2.3 Implement pure chronological grouping for current/upcoming versus history, including terminal future sessions and expired `booked` sessions that require a status update.
- [x] 2.4 Add a disposable minute ticker that reclassifies loaded sessions, reloads on local day rollover, and is cancelled when Home state is closed.
- [x] 2.5 Add unit/Cubit tests for normal and DST-safe day boundaries, midnight overlap, all lifecycle/time groups, loading, success, failure, retry, refresh, and day rollover.

## 3. Daily schedule presentation

- [x] 3.1 Build the Home header with Russian local date formatting and a trainer-only accessible QR icon that opens the existing `/invite` route.
- [x] 3.2 Build compact Fitness Yoda rows that present each Session/slot as a training and show its local time, counterpart email/id, localized status, and status icon/color without requiring a separate title.
- [x] 3.3 Build the collapsed-by-default History section with entry count, inline expand/collapse, chronological rows, and an explicit expired-booked status.
- [x] 3.4 Build the always-visible current/upcoming section ordered by start time and its “no more trainings today” state.
- [x] 3.5 Add schedule-area loading, Russian error with retry, empty-day messaging, and pull-to-refresh while keeping the rest of Home usable.

## 4. Key feature navigation

- [x] 4.1 Replace the old large quick actions and relationship summary with compact, fully tappable cards after the schedule using existing Fitness Yoda cards, tokens, spacing, and icons.
- [x] 4.2 Configure trainer cards for schedule, invitations/students, plans, and permission-gated finance using existing protected routes.
- [x] 4.3 Configure safe student cards for sessions, booking, trainers, and visible plans when `/home` is opened directly.
- [x] 4.4 Make the card layout responsive between two columns and one column without overflow on narrow screens.

## 5. Router and authenticated shell integration

- [x] 5.1 Update the `/home` route to create the feature-scoped `HomeCubit` and render `HomePage` while preserving current auth redirects and the trainer Home branch.
- [x] 5.2 Remove the obsolete auth-owned Home implementation and update imports without moving profile or logout behavior out of the existing Profile destination.
- [x] 5.3 Verify the AuthCubit remains the source for user roles/permissions and that trainer/student route visibility still matches router guards.

## 6. UI tests and verification

- [x] 6.1 Replace the old Home quick-action widget test with populated trainer tests for current/upcoming rows, collapsed history, expand/collapse, QR action, and permission-aware cards.
- [x] 6.2 Add Home widget tests for student direct access, loading, request failure/retry, empty day, manual refresh, and narrow-screen overflow.
- [x] 6.3 Run Dart formatting, `flutter analyze`, repository/unit/Cubit/widget tests, and the full existing Flutter test suite.
- [x] 6.4 Smoke-test against the local API with trainer auth and sessions covering booked, in-progress, completed, cancelled, no-show, and expired-booked states; verify the request uses current-day `from`/`to`.
- [x] 6.5 Visually compare populated, empty, and error Home states on narrow and standard simulator sizes with the supplied prototype, confirming that the information hierarchy matches while the existing Fitness Yoda design remains unchanged.
