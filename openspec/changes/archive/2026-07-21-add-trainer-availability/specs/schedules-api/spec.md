## ADDED Requirements

### Requirement: Trainer can read and update schedule settings via API
The schedules API SHALL expose authenticated coach endpoints to get and upsert own schedule settings (timezone, durations, break, horizon, default mode). Callers MUST hold existing schedule own-read / create-style permissions already used for slot management. Responses MUST NOT include finance price fields.

#### Scenario: Get settings
- **WHEN** a coach with schedule read permission requests availability settings
- **THEN** the API returns the stored settings or sensible defaults/empty state for first-time setup

#### Scenario: Put settings
- **WHEN** a coach upserts valid settings
- **THEN** the API persists them and returns the saved representation

### Requirement: Trainer can read and update weekly template via API
The schedules API SHALL expose endpoints to get and upsert the coach's weekly availability template (series identity and weekday windows). Invalid overlapping windows or invalid time bounds MUST be rejected. Upsert MUST be scoped to the authenticated coach.

#### Scenario: Upsert template
- **WHEN** a coach puts a valid Monday–Sunday window set
- **THEN** the API stores the template for that coach and subsequent GET returns the same windows and series id

#### Scenario: Foreign template denied
- **WHEN** a caller attempts to modify another coach's template
- **THEN** the API rejects the request as forbidden or not found without leaking data

### Requirement: Trainer can manage date exceptions via API
The schedules API SHALL allow a coach to list and replace (or create/update/delete) availability exceptions for local dates: closed or custom hours. Exception payloads MUST be validated like template windows.

#### Scenario: Replace exceptions
- **WHEN** a coach submits a valid set of exceptions including one closed date and one custom-hours date
- **THEN** the API stores that set for the coach series and returns it on list

### Requirement: Trainer can generate slots from the template
The schedules API SHALL provide a generate operation that materializes open slots for the configured horizon using fixed-grid rules from calendar-domain. The operation MUST be idempotent, MUST use a coach-scoped lock/transaction consistent with booking mutations, and MUST return a summary of created/skipped/(optional) removed counts. Existing `POST /schedule/slots`, `GET /schedule/slots`, `DELETE /schedule/slots/:id` and linked-coach slot listing MUST remain backward compatible.

#### Scenario: Generate creates open slots
- **WHEN** a coach with a valid template and settings calls generate
- **THEN** open slots appear in `GET /schedule/slots` within the horizon and carry the template series id

#### Scenario: Generate respects holds and bookings
- **WHEN** generate runs while some series intervals are booked or held by pending requests
- **THEN** those intervals are left intact and conflicting candidates are skipped

#### Scenario: List own slots remains compatible
- **WHEN** a client lists own slots with optional `from` and `to` after generation
- **THEN** both one-off and generated slots in range are returned without requiring new query parameters

### Requirement: Optional preview does not persist slots
If the API exposes a preview endpoint, it SHALL return the candidate intervals that generate would create for a range without inserting rows. Preview MUST use the same fixed-grid rules as generate.

#### Scenario: Preview without side effects
- **WHEN** a coach requests availability preview for a date range
- **THEN** the response lists candidate starts/ends and no new `ScheduleSlot` rows are persisted
