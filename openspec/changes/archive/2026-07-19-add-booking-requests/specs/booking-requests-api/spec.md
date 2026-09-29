## ADDED Requirements

### Requirement: Linked student creates an exclusive booking request
The system SHALL allow a student with `booking_requests:create` to create a pending request for an open future slot of an actively linked coach. Creation MUST lock and revalidate the slot, snapshot the coach's configured positive price/currency, calculate `expiresAt`, and create the request and its initial history event atomically.

#### Scenario: Valid request is created
- **WHEN** a linked student requests an open slot with a configured coach price and a future decision deadline
- **THEN** one pending request is created with the slot, coach, student, quoted price, expiry deadline, and creation event

#### Scenario: Slot is already held
- **WHEN** two students concurrently request the same slot
- **THEN** exactly one pending request succeeds and the other receives a conflict response

#### Scenario: Student already has a pending request to coach
- **WHEN** a student with an existing non-expired pending request creates another request to the same coach
- **THEN** the system rejects the second request with a conflict response

#### Scenario: Relationship is missing
- **WHEN** a student requests a slot without an active relationship to its coach
- **THEN** the system rejects the action as forbidden

#### Scenario: Decision window is too short
- **WHEN** the calculated deadline is not later than request creation time
- **THEN** the system rejects the request without holding the slot

### Requirement: Booking request expiry is deterministic
A pending request MUST expire at the earlier of 12 hours after creation and 2 hours before its requested slot starts. Expiry processing SHALL be idempotent and SHALL release the logical slot hold without creating a Session or charge.

#### Scenario: Twelve-hour deadline arrives first
- **WHEN** a pending request reaches 12 hours after creation before the slot's two-hour cutoff
- **THEN** the request becomes `expired`, an expiry event is recorded, and the slot becomes requestable again

#### Scenario: Slot cutoff arrives first
- **WHEN** a pending request reaches two hours before slot start before its twelve-hour deadline
- **THEN** the request becomes `expired`

#### Scenario: Expiry processor repeats
- **WHEN** expiry processing runs more than once for an already expired request
- **THEN** status remains `expired` and no duplicate expiry event is created

### Requirement: Student reads and withdraws own requests
The system SHALL allow a student with `booking_requests:read_own` to list only their requests with bounded pagination/status filtering and SHALL allow the owner to withdraw a pending request without a reason.

#### Scenario: Student lists own requests
- **WHEN** a student requests their booking-request list
- **THEN** only requests where they are the student are returned with status, requested/resolved time, quote, deadline, feedback, and Session reference when present

#### Scenario: Student withdraws pending request
- **WHEN** the owning student withdraws a non-expired pending request
- **THEN** it atomically becomes `withdrawn`, a history event is created, and the slot hold is released

#### Scenario: Student withdraws terminal request
- **WHEN** a student attempts to withdraw an accepted, rejected, withdrawn, or expired request
- **THEN** the system rejects the invalid transition

### Requirement: Trainer reads an owner-scoped request inbox
The system SHALL allow a trainer with `booking_requests:read_inbox` to list only requests for slots they own. Pending requests SHALL be ordered by nearest `expiresAt` before terminal requests, and a lightweight endpoint SHALL return the current pending count.

#### Scenario: Trainer opens inbox
- **WHEN** a trainer lists their booking requests
- **THEN** requests for that trainer are returned with pending items ordered by urgency and without requests for another trainer

#### Scenario: Trainer reads pending count
- **WHEN** a trainer requests their pending count
- **THEN** the response counts only their non-expired pending requests

### Requirement: Trainer accepts a requested slot atomically
The system SHALL allow the request's coach with `booking_requests:respond` to accept a non-expired pending request. Acceptance MUST atomically lock request and slot, revalidate relationship and availability, create exactly one booked Session and one pending charge using the quoted price, mark the slot booked, mark the request accepted, and append an event.

#### Scenario: Trainer accepts valid request
- **WHEN** the owning trainer accepts a pending request whose slot remains open
- **THEN** the request becomes `accepted`, references one booked Session, and the Session has one charge using the request quote

#### Scenario: Concurrent accept is exactly once
- **WHEN** acceptance is submitted concurrently more than once
- **THEN** exactly one transaction creates the Session/charge and later attempts receive a conflict

#### Scenario: Slot no longer available
- **WHEN** acceptance finds that the requested slot is no longer open
- **THEN** the transaction fails without accepting the request or creating financial records

### Requirement: Trainer rejects with student-visible feedback
The system SHALL allow the request's coach with `booking_requests:respond` to reject a pending request only with reason `time_unavailable`, `plans_changed`, or `other`, plus an optional length-limited comment visible to the student.

#### Scenario: Trainer rejects with reason
- **WHEN** the owning trainer rejects a pending request with a supported reason
- **THEN** the request becomes `rejected`, feedback and a rejection event are persisted, and no Session or charge is created

#### Scenario: Rejection reason omitted
- **WHEN** the trainer submits rejection without a supported reason
- **THEN** validation rejects the request and the booking request remains pending

### Requirement: Trainer assigns an externally agreed alternate time
The system SHALL allow the request's coach with `booking_requests:respond` to resolve a pending request at another final time after external coordination. Duration and mode MUST be copied from the requested slot. The operation MUST atomically validate conflicts, create one one-off slot, one booked Session and one quoted-price charge, accept the request with alternate resolution, and leave the original slot open.

#### Scenario: Alternate time is assigned
- **WHEN** the owning trainer submits a valid conflict-free start time for a pending request
- **THEN** a one-off slot and booked Session are created for the copied duration/mode, the request becomes accepted, and the original slot remains open

#### Scenario: Alternate time conflicts
- **WHEN** the submitted alternate range overlaps unavailable trainer time
- **THEN** the system rejects the operation without changing the request or creating partial records

#### Scenario: Student cannot counter-propose
- **WHEN** a student reads an alternate-time accepted request
- **THEN** the API exposes the final resolved time and no counter-proposal action

### Requirement: Booking request transitions are authorized and audited
Every request mutation SHALL require both the relevant permission and request ownership/participation policy. Every successful creation or transition MUST append exactly one durable request event in the same transaction.

#### Scenario: Foreign trainer attempts response
- **WHEN** a trainer attempts to accept or reject a request owned by another trainer
- **THEN** the system rejects the action

#### Scenario: Successful transition is audited
- **WHEN** a request successfully changes status
- **THEN** the status, actor, timestamp, transition metadata, and append-only event commit together
