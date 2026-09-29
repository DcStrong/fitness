## REMOVED Requirements

### Requirement: Student can book a free slot with linked coach
**Reason**: Student self-booking is replaced by a pending BookingRequest requiring a coach decision; a Session must represent only a confirmed training.

**Migration**: Updated clients use `POST /booking-requests` and read request status. `POST /sessions` explicitly rejects student actors even when an old token still contains `sessions:book_self`.

## ADDED Requirements

### Requirement: Accepted booking request creates a booked session
The system SHALL create a `booked` Session only when a coach accepts a valid pending BookingRequest at the requested slot or an alternate one-off slot. The Session MUST reference the resolved slot, snapshot its time/mode, use `createdBy=coach`, and reference the accepted request through its response/audit relation.

#### Scenario: Requested slot accepted
- **WHEN** a coach accepts a pending request at the requested slot
- **THEN** one booked Session is created from that slot and returned through normal own-session reads

#### Scenario: Alternate slot accepted
- **WHEN** a coach resolves a pending request at another conflict-free time
- **THEN** one booked Session is created from the new one-off slot

#### Scenario: Student calls direct booking endpoint
- **WHEN** a student attempts to create a Session directly
- **THEN** the system rejects the request with an actionable error directing the client to BookingRequests

## MODIFIED Requirements

### Requirement: Booking atomically creates financial snapshot
A successful direct coach booking or accepted BookingRequest SHALL atomically create its Session charge. Direct coach booking SHALL use the configured default or allowed one-session override; request acceptance SHALL use the immutable quoted amount/currency stored on the BookingRequest.

#### Scenario: Request acceptance and charge commit together
- **WHEN** BookingRequest acceptance succeeds
- **THEN** request status, Session, resolved slot status, and one pending charge using the quote are committed in the same transaction

#### Scenario: Direct coach booking and charge commit together
- **WHEN** trainer book-for-student succeeds
- **THEN** Session, slot status, and one pending charge with the applicable price snapshot are committed in the same transaction

#### Scenario: Charge creation fails
- **WHEN** charge persistence fails during direct booking or request acceptance
- **THEN** neither Session creation, slot booking, nor request acceptance is committed
