## 1. Backend requestable list cutoff

- [x] 1.1 Add `earliestRequestableSlotStart(now)` next to `calculateBookingRequestExpiry` using `BOOKING_REQUEST_SLOT_CUTOFF_HOURS`
- [x] 1.2 In `listOpenForLinkedCoach`, set `from` to `max(query.from, cutoff)` and never below cutoff
- [x] 1.3 In `findRequestableForCoach`, filter `slot.starts_at > :from` (do not change trainer `findForCoach` overlap-by-`ends_at`)
- [x] 1.4 Unit tests: reject `startsAt == now + 2h`; accept later start; cutoff helper matches expiry rule

## 2. Student booking copy

- [x] 2.1 Map create conflicts `decision window has already closed` and `slot is not requestable` to «Записаться можно не позже чем за 2 часа до начала тренировки» without changing trainer `deadline has passed` copy
- [x] 2.2 Update `StudentBookScreen` caption and empty-slots banner to explain the 2-hour cutoff
- [x] 2.3 Update `booking_requests_repository_test` for the new closed-window create message

## 3. Verification

- [x] 3.1 Run focused Nest unit tests for booking-request rules (and any schedule list test added)
- [x] 3.2 Run focused Flutter tests for booking_requests repository
- [x] 3.3 Manual smoke as student: «Запись к тренеру» does not show sendable slots starting within 2 hours; a later open slot still sends a request
