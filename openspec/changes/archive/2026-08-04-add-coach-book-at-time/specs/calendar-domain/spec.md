## MODIFIED Requirements

### Requirement: Materialization reuses open availability slots
Materializing an occurrence MUST prefer booking an existing matching open ScheduleSlot and create a Session. Matching MUST use absolute UTC bounds derived from local wall time via the series timezone. Pending holds, non-open exact slots, mode mismatches, and non-exact overlaps MUST block materialization and surface as conflicts.

When no matching slot exists and no open or booked slot overlaps the occurrence interval, materialization MUST create a one-off ScheduleSlot (`seriesId` null) with those exact bounds and book it atomically rather than reporting `missing_slot`. Materialization MUST NOT create a second slot on top of an exact slot that exists with a different mode.

#### Scenario: Exact open slot booked
- **WHEN** an occurrence needs 18:00–19:00 local and a matching open unheld slot exists
- **THEN** that slot is booked into a Session for the series student

#### Scenario: Exact open slot required when only partial overlap exists
- **WHEN** an occurrence needs 18:00–19:00 local and only a 17:30–18:30 open slot exists
- **THEN** the occurrence is a conflict (`overlap`) rather than a partial or shifted automatic book

#### Scenario: Missing interval is created on demand
- **WHEN** an occurrence has no exact slot and no overlapping open or booked slot
- **THEN** a one-off booked slot and Session are created for that interval

### Requirement: Partial conflicts do not roll back successful books
When some occurrences can be booked and others cannot, the domain MUST keep successful Sessions and expose unresolved conflicts for coach resolution. Conflict reasons MUST distinguish at least: missing-or-created path is no longer a residual conflict after success; held slot; unavailable/booked slot; non-exact overlap; and mode mismatch.

#### Scenario: Mixed week result
- **WHEN** two of three weekly occurrences have free slots and one overlaps an existing booked appointment
- **THEN** two Sessions exist and one conflict remains for coach action

## ADDED Requirements

### Requirement: Coach may book a linked student at an arbitrary free interval
The calendar domain SHALL allow a coach to create an appointment for a linked student at an absolute time range without a pre-existing open ScheduleSlot. The operation MUST atomically create a ScheduleSlot with `seriesId` null, create the Session (`createdBy=coach`) with charge, and leave the slot in status `booked`. The interval MUST NOT overlap any open or booked slot of the coach.

#### Scenario: Book without prior availability
- **WHEN** a coach books a linked student at an interval with no existing slot
- **THEN** a booked Session and a booked ScheduleSlot exist for that interval and no open slot was exposed for student requests

#### Scenario: Overlap blocks book-at-time
- **WHEN** a coach books a linked student at an interval overlapping an existing booked Session slot
- **THEN** the domain rejects the operation and leaves the calendar unchanged
