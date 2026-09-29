## 1. Backend — next occurrence + restore

- [x] 1.1 Student enrichment on list/get (`studentDisplayName`, `studentEmail`)
- [x] 1.2 Create pattern guard: active → 409 + `existingId`; cancelled twin → reactivate + sync
- [x] 1.3 Add `nextOccurrenceLocalDate` to model; compute via `expandDesiredOccurrences` (+ overrides) for active only
- [x] 1.4 Extract shared reactivate helper; add `POST /recurring-bookings/:id/restore` → `{ booking, sync }`
- [x] 1.5 Restore: reject active; 409 if another active matches pattern
- [x] 1.6 Unit/e2e: next occurrence on list; restore success; restore conflict 409

## 2. Flutter — models, dates, cards

- [x] 2.1 Entry: schedule AppBar «Регулярные» + Home feature card
- [x] 2.2 Models: student fields; create 409 → snackbar + open existing
- [x] 2.3 Model field `nextOccurrenceLocalDate`; parse on list/get
- [x] 2.4 Helper `formatRelativeCalendarDate` (сегодня/завтра/вчера/`DD.MM.YY`) + unit tests
- [x] 2.5 List/detail cards: active shows next occurrence + time; created/cancelled via relative labels

## 3. Flutter — restore UX

- [x] 3.1 Repository + cubit `restoreRecurringBooking`
- [x] 3.2 Detail (and archive list if simple): «Восстановить»; success → active UI + snackbar; 409 → existing series
- [x] 3.3 Cubit/widget tests for restore path

## 4. Verify

- [x] 4.1 API unit + e2e green for new cases
- [x] 4.2 Flutter tests green
- [x] 4.3 Smoke: list shows next date labels; archive restore works; duplicate create still 409
