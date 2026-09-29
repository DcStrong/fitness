## ADDED Requirements

### Requirement: Optional status filter on session list
The system SHALL allow `GET /sessions` callers with `sessions:read_own` to optionally filter by session status (e.g. query `status=booked` or multiple values as defined by the API).

#### Scenario: Filter booked only
- **WHEN** a user lists sessions with status filter `booked`
- **THEN** only sessions with status `booked` where they are coach or student are returned

## REMOVED Requirements

### Requirement: Session status for this change is booked-only lifecycle start
**Reason**: Phase 5 introduces complete / cancel / no_show transitions.
**Migration**: Use `session-lifecycle` requirements; new sessions still start as `booked`, then may transition.
