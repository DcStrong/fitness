## ADDED Requirements

### Requirement: Trainer books a linked student from a free slot
The mobile app SHALL provide a Russian coach flow to book a linked student onto an existing open availability slot. The flow MUST list only actively linked students, show the slot’s local time and mode, allow an optional one-session price override when the product already supports it, call the sessions book API with `scheduleSlotId`, and expose loading, validation, conflict and success states without networking inside widgets. UI MUST reuse `FyButton` / `FyCard` / `FyInputCard` (or equivalent shared primitives) and MUST NOT introduce Riverpod.

#### Scenario: Book from open slot succeeds
- **WHEN** a trainer selects a linked student on an open slot and confirms
- **THEN** the app creates a booked session, closes the flow, and the calendar shows a training event instead of free time at that interval

#### Scenario: Unlinked student not offered
- **WHEN** the trainer opens student selection for a one-off booking
- **THEN** only actively linked students are available

#### Scenario: Slot conflict surfaced
- **WHEN** booking fails because the slot is held, booked, or otherwise rejected
- **THEN** the app shows a specific Russian error and does not claim the training was created

### Requirement: Trainer books a linked student at an arbitrary free time
When no open slot exists for the chosen interval, the app SHALL let the trainer pick a linked student, local start (and end derived from schedule duration settings or an explicit end), and mode, then call coach book-at-time (`startsAt`/`endsAt`/`mode` + `studentId`) so the backend creates the appointment without a prior published open slot. Overlap conflicts returned by the API MUST be shown in Russian and MUST leave the calendar unchanged.

#### Scenario: Book on empty calendar day
- **WHEN** a trainer chooses a future local start with no open slot and confirms a linked student
- **THEN** the app books via book-at-time and a training event appears after refresh

#### Scenario: Overlap blocks booking
- **WHEN** book-at-time fails because the interval overlaps an existing open or booked slot
- **THEN** the app shows a Russian conflict message and does not navigate away as success

### Requirement: Booking flow is reachable from calendar actions
The one-off coach booking flow MUST be openable from the calendar create-actions sheet, from an open-slot actions sheet, and from an empty day-timeline hour tap with prefilled date/time. Deep link `/schedule/book-for-student` MAY open the same flow without prefill but MUST NOT be the only entry.

#### Scenario: Prefill from empty hour
- **WHEN** the trainer taps an empty hour on the day timeline and chooses «Записать ученика»
- **THEN** the booking flow opens with that local date and start time prefilled
