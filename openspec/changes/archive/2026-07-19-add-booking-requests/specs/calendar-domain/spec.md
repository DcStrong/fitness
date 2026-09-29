## MODIFIED Requirements

### Requirement: Calendar separates availability from appointments
The backend calendar SHALL model bookable availability (`ScheduleSlot`), pre-appointment intent (`BookingRequest`), and confirmed appointments (`Session`) separately. A student request MUST NOT create a Session. Accepting a valid request or direct coach booking SHALL create a Session and mark its resolved availability slot as no longer open. Session times MUST be snapshotted from the resolved slot at booking time.

#### Scenario: Student request precedes appointment
- **WHEN** a valid student request is created against an open slot
- **THEN** a pending BookingRequest exists while no Session or charge exists

#### Scenario: Accepted request converts slot into booked session
- **WHEN** the coach accepts a valid pending request at its requested slot
- **THEN** a Session exists with status `booked` and the slot is no longer open for another booking

#### Scenario: Coach direct booking remains immediate
- **WHEN** a coach directly books a linked student into an own open slot
- **THEN** a Session is created without requiring a BookingRequest

### Requirement: Booking is atomic against double-book
Direct coach booking and BookingRequest acceptance/alternate resolution SHALL run as server-side atomic operations such that concurrent operations cannot create more than one Session for the same slot or more than one Session/charge for the same request.

#### Scenario: Concurrent accept of same request
- **WHEN** two acceptance operations target the same pending request concurrently
- **THEN** exactly one creates a Session and charge and the other fails with a conflict-style error

#### Scenario: Direct booking races request acceptance
- **WHEN** direct coach booking and request acceptance concurrently target the same open slot
- **THEN** exactly one operation books the slot and the other fails without partial records

## ADDED Requirements

### Requirement: Pending request holds availability
A non-expired pending BookingRequest SHALL make its requested slot unavailable to other student requests and SHALL prevent deletion of that slot. Rejected, withdrawn, and expired requests SHALL release the logical hold.

#### Scenario: Held slot omitted from student availability
- **WHEN** an open slot has a non-expired pending request
- **THEN** another student does not receive that slot as requestable availability

#### Scenario: Terminal request releases hold
- **WHEN** a pending request becomes rejected, withdrawn, or expired
- **THEN** its still-open requested slot can be listed and requested again

### Requirement: Alternate request resolution preserves canonical slots
Resolving a request at another time SHALL create a one-off ScheduleSlot and then create the Session from that slot. The original requested slot MUST remain open unless separately changed.

#### Scenario: Alternate appointment is materialized
- **WHEN** a coach assigns a conflict-free alternate time
- **THEN** the Session snapshots duration and mode through a new one-off slot and the original slot remains available
