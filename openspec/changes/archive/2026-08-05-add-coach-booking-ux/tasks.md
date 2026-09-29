## 1. Repository and models (API contract)

- [x] 1.1 Extend `ScheduleRepository` with `bookAtTime({startsAt, endsAt, mode, studentId, priceMinor?})` posting XOR body to `POST /sessions`
- [x] 1.2 Keep existing `book(scheduleSlotId:…)` path; share error mapping for conflict/held responses
- [x] 1.3 Update recurring models: parse `slotsCreated`, conflict reason `mode_mismatch`; pass `horizonWeeksOverride` on create
- [x] 1.4 Confirm dependency: backend `add-coach-book-at-time` applied (or document blocker) before e2e smoke

## 2. Create-actions and slot sheets

- [x] 2.1 Add `ScheduleCreateActionsSheet` («Записать ученика» / «Регулярные тренировки» / «Свободное время») with Russian subtitles
- [x] 2.2 Replace calendar FAB «Свободное время» with FAB «+» that opens the create sheet (calendar tab only)
- [x] 2.3 Remove AppBar TextButton «Регулярный график»
- [x] 2.4 Add `OpenSlotActionsSheet`: book student / regular (optional) / delete open unheld slot; wire delete via existing API
- [x] 2.5 Wire `_onEventTap`: availability → slot sheet; request → existing detail; session → history/detail if available

## 3. Empty-hour and book-student flow

- [x] 3.1 Add `onEmptyHourTap` to day timeline; open create sheet or book flow with prefilled local start
- [x] 3.2 Refactor/replace `CoachBookForStudentScreen` into reachable flow supporting prefill `slotId` **or** `startsAt`/`endsAt`/`mode`
- [x] 3.3 Load linked students only; optional price dialog; call `book` or `bookAtTime`; refresh calendar on success
- [x] 3.4 Cubit or local state with loading/error; no Riverpod; Russian validation copy

## 4. Recurring UI updates

- [x] 4.1 Add horizon weeks field on create form (1–52, default from schedule settings or 8)
- [x] 4.2 Show `slotsCreated` in create result / detail sync summary
- [x] 4.3 Localize `mode_mismatch` in conflict list; keep skip/reschedule actions
- [x] 4.4 Rename user-facing «Регулярный график» → «Регулярные тренировки» where still present

## 5. Router cleanup

- [x] 5.1 Keep `/schedule/book-for-student` as deep link into the same book flow (or redirect with query prefill)
- [x] 5.2 Redirect or remove `/schedule/slots` legacy CRUD from primary navigation; update tests that depended on it
- [x] 5.3 Ensure no dead AppBar/home links point at removed labels

## 6. Tests and verification

- [x] 6.1 Widget/cubit tests: create sheet actions, open-slot tap opens book path, empty-hour prefill, horizon field on create
- [x] 6.2 Update recurring cubit tests for `slotsCreated` / `mode_mismatch` parsing
- [x] 6.3 `dart format`, `flutter analyze`, run schedule/recurring-related tests
- [x] 6.4 Manual smoke against `:3001`: FAB → book at empty time; tap free slot → book; FAB → recurring with horizon; free time still works
- [x] 6.5 Optional: note in `docs/design/availability-recurring-booking.md` that Слой C part 2 UX is this change
- [x] 6.6 Ready for `/opsx-archive` after apply (after `add-coach-book-at-time` archived or both complete)
