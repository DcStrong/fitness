## 1. OpenSpec / docs

- [x] 1.1 proposal, design, tasks, delta specs

## 2. Backend recurring + lifecycle

- [x] 2.1 `releaseSlot` on session cancel; recurring cancel passes it for future booked sessions
- [x] 2.2 `GET /recurring-bookings?status=` default `active`
- [x] 2.3 `DELETE /recurring-bookings/:id` for cancelled only
- [x] 2.4 Lifecycle/API: `releaseSlot` wired; list/delete endpoints (Flutter + tsc verify)

## 3. Flutter recurring detail / list

- [x] 3.1 Pass create sync via route extra; detail shows summary; «Обновить горизонт» + «Готово»
- [x] 3.2 List active + archive tab/section; hard delete cancelled
- [x] 3.3 Repository/cubit: status query + delete

## 4. Navigation + session manage

- [x] 4.1 SessionHistory Back: pop if canPop
- [x] 4.2 SessionActionsSheet; calendar session tap opens it
- [x] 4.3 Skip cancelled sessions in calendar event map

## 5. Verify

- [x] 5.1 Flutter widget/unit tests for sheet/back/map
- [x] 5.2 analyze / format clean on touched paths
