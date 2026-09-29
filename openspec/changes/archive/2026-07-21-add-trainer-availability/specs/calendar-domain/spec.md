## ADDED Requirements

### Requirement: Trainer manages schedule settings
The system SHALL persist per-coach schedule settings including IANA timezone, default session duration in minutes, optional break minutes between sessions, generation horizon in weeks, optional per-mode durations for `online` and `offline`, and a default slot mode. Duration values MUST be positive; break minutes and horizon MUST be non-negative within configured bounds. Settings MUST be owned by the authenticated coach and MUST NOT alter finance defaults.

#### Scenario: Coach upserts settings
- **WHEN** a coach saves valid duration, break, horizon, timezone and optional per-mode durations
- **THEN** the system stores those settings for that coach and returns them on subsequent read

#### Scenario: Invalid duration rejected
- **WHEN** a coach submits a non-positive default duration or negative break minutes
- **THEN** the system rejects the request

### Requirement: Weekly availability template defines working windows
The system SHALL allow a coach to define a weekly availability template with zero or more working windows per weekday Monday through Sunday. Each window MUST use local time-of-day bounds in the coach timezone as a half-open range. Multiple windows on the same weekday MUST NOT overlap. The template SHALL be associated with a durable series identity used as `seriesId` on generated slots.

#### Scenario: Coach saves Monday windows
- **WHEN** a coach upserts two non-overlapping Monday windows such as 09:00–13:00 and 14:00–18:00
- **THEN** the template stores both windows for Monday under the coach series

#### Scenario: Overlapping windows rejected
- **WHEN** a coach submits overlapping windows on the same weekday
- **THEN** the system rejects the request

### Requirement: Date exceptions override the weekly template
The system SHALL allow exceptions for specific local calendar dates: a closed day with no windows, or custom hours that replace the weekday template for that date only. Exception dates are interpreted in the coach timezone.

#### Scenario: Closed-day exception
- **WHEN** a coach marks a local date as closed
- **THEN** generation produces no slots from the weekly template on that local date

#### Scenario: Custom-hours exception
- **WHEN** a coach sets custom hours for a local date
- **THEN** generation uses only those custom windows for that date instead of the weekday template

### Requirement: Fixed-grid generation materializes open slots
Given settings and an effective window, the system SHALL generate discrete open `ScheduleSlot` records on a fixed grid where the step equals session duration plus break minutes. A candidate slot MUST be created only when its full `[start, start+duration)` fits inside the window. Generated slots MUST store absolute UTC timestamps, the series id, and the resolved mode. Flexible arbitrary start times inside a window MUST NOT be offered by this generator.

#### Scenario: Grid fits whole slots only
- **WHEN** a local window is 09:00–13:00 with duration 60 and break 15
- **THEN** the generator creates 09:00–10:00, 10:15–11:15 and 11:30–12:30 and does not create 12:45–13:45

#### Scenario: Empty remainder skipped
- **WHEN** a window is shorter than one full duration
- **THEN** no slot is created for that window

### Requirement: Generation is idempotent and preserves booked or held slots
Slot generation SHALL run as an atomic coach-scoped operation. It MUST NOT create a duplicate open slot for an identical interval that already exists. It MUST NOT delete, recreate, or overwrite booked slots or open slots with a non-expired pending BookingRequest. It MUST NOT remove one-off slots (`seriesId` null). Re-running generation without template changes MUST report no new creates for already materialized intervals. Open unheld series slots that are no longer produced by the current template MAY be removed as orphan cleanup.

#### Scenario: Second generate is idempotent
- **WHEN** a coach runs generate twice with an unchanged template and settings
- **THEN** the second run creates zero additional slots for the same intervals

#### Scenario: Booked slot preserved
- **WHEN** a previously generated interval is already booked
- **THEN** generation leaves that slot unchanged and does not create a conflicting open duplicate

#### Scenario: Held slot preserved
- **WHEN** an open series slot has a non-expired pending BookingRequest
- **THEN** generation does not delete or replace that slot

#### Scenario: One-off slot blocks overlapping candidate
- **WHEN** a one-off open slot overlaps a generated candidate interval
- **THEN** the generator skips creating that candidate

### Requirement: Existing open-slot non-overlap invariant still holds
Generated and one-off open slots for the same coach MUST continue to obey the half-open non-overlap rule. Generation MUST skip candidates that would violate it rather than leaving the coach calendar in an overlapping open state.

#### Scenario: Overlapping candidate skipped
- **WHEN** a generate candidate overlaps any existing slot of the coach
- **THEN** that candidate is not inserted as an open slot
