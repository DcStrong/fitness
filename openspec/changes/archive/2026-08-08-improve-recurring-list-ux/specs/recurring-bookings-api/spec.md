## ADDED Requirements

### Requirement: Recurring booking list includes student identity
`GET /recurring-bookings` and `GET /recurring-bookings/:id` responses SHALL include `studentDisplayName` (nullable) and `studentEmail` (nullable) for the linked student, resolved from profile display name and user email.

#### Scenario: List returns student fields
- **WHEN** a coach lists recurring bookings
- **THEN** each item includes `studentDisplayName` and `studentEmail`

### Requirement: Recurring booking exposes next occurrence date
For an **active** RecurringBooking, list and get responses SHALL include `nextOccurrenceLocalDate` (nullable ISO local date `YYYY-MM-DD`) for the nearest future occurrence in the booking timezone according to weekdays, startMinute, and overrides. For **cancelled** bookings the field SHALL be `null`.

#### Scenario: Active list includes next occurrence
- **WHEN** a coach lists active recurring bookings
- **THEN** each active item includes `nextOccurrenceLocalDate` when a future occurrence exists within the computable horizon, otherwise `null`

#### Scenario: Cancelled has no next occurrence
- **WHEN** a coach lists cancelled recurring bookings
- **THEN** each item has `nextOccurrenceLocalDate` equal to `null`

### Requirement: Create rejects active pattern duplicate
The pattern key is `(coachId, studentId, sorted weekdays, startMinute, mode)`. When creating a RecurringBooking, if an **active** series with the same key already exists for the coach, the system SHALL respond with `409 Conflict`, include `existingId` of that series, and MUST NOT create a new row.

#### Scenario: Duplicate active create
- **WHEN** a coach creates a series whose pattern matches an existing active series
- **THEN** the response is 409 with `existingId` and no new booking is created

### Requirement: Create reactivates cancelled pattern twin
When creating a RecurringBooking, if no active series matches the pattern but one or more **cancelled** series match, the system SHALL reactivate the newest cancelled twin (`status=active`, `cancelledAt=null`), apply optional horizon override from the request, run sync, and return `{ booking, sync }` with the **same id**. A new row MUST NOT be inserted.

#### Scenario: Create after cancel reuses id
- **WHEN** a coach cancels a series and then creates again with the same student, weekdays, startMinute, and mode
- **THEN** the response is success with the cancelled series id reactivated and status `active`

### Requirement: Restore cancelled recurring series
The system SHALL allow the owning coach to restore a **cancelled** RecurringBooking via an explicit restore endpoint (e.g. `POST /recurring-bookings/:id/restore`). Restore SHALL set `status=active`, clear `cancelledAt`, run sync, and return `{ booking, sync }` with the same id. Restoring an already **active** series MUST be rejected. If another **active** series already matches the same pattern key, restore MUST be rejected with `409` and `existingId`.

#### Scenario: Restore cancelled series
- **WHEN** a coach restores a cancelled series
- **THEN** the series becomes `active`, `cancelledAt` is null, sync runs, and the response uses the same booking id

#### Scenario: Restore active rejected
- **WHEN** a coach attempts to restore an active series
- **THEN** the system rejects the request

#### Scenario: Restore conflicts with other active pattern
- **WHEN** a coach restores a cancelled series whose pattern matches a different active series
- **THEN** the response is 409 with `existingId` of the conflicting active series
