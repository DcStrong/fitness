## ADDED Requirements

### Requirement: Student can book a free slot with linked coach
The system SHALL allow a user with `sessions:book_self` to create a session in status `booked` for an **open** slot belonging to a linked coach. The session MUST be 1:1 (one student). Booking MUST be atomic: snapshot times from the slot, create the session, and mark the slot booked so it cannot be double-booked.

#### Scenario: Successful student booking
- **WHEN** a linked student books an open coach slot
- **THEN** a session is created with status `booked`, coachId, studentId, startsAt/endsAt copied from the slot, `createdBy` = student, and the slot is no longer open

#### Scenario: Double-book rejected
- **WHEN** a student books a slot that is already booked
- **THEN** the system rejects the request

#### Scenario: Unlinked booking rejected
- **WHEN** a student books a slot for a coach without an active link
- **THEN** the system rejects the request

### Requirement: Trainer can book a session for a linked student
The system SHALL allow a user with `sessions:book_for_student` to create a `booked` session for one of their linked students on a free own slot (or explicit time range equivalent). `createdBy` MUST be coach.

#### Scenario: Coach books for linked student
- **WHEN** a trainer books their free slot for a linked student
- **THEN** a `booked` session is created with that student and `createdBy` = coach

#### Scenario: Coach books unlinked student rejected
- **WHEN** a trainer books for a user who is not linked as their student
- **THEN** the system rejects the request

### Requirement: Users can list their sessions
The system SHALL allow users with `sessions:read_own` to list sessions where they are the coach or the student.

#### Scenario: Student sees own bookings
- **WHEN** a student lists sessions
- **THEN** sessions where they are the student are returned

#### Scenario: Coach sees own sessions
- **WHEN** a coach lists sessions
- **THEN** sessions where they are the coach are returned

### Requirement: Session status for this change is booked-only lifecycle start
Sessions created in this change MUST start as `booked`. Transitions to `completed` / `cancelled` / `no_show` are out of scope here.

#### Scenario: New session is booked
- **WHEN** a booking succeeds
- **THEN** session.status equals `booked`
