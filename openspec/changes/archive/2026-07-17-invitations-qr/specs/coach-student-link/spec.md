## ADDED Requirements

### Requirement: Accepting an invitation creates a coach–student relationship
When an invitation is successfully accepted, the system SHALL create a durable link between the invitation's coach and the accepting student user. Duplicate accepts for the same pair MUST be idempotent (no duplicate active links).

#### Scenario: First accept creates link
- **WHEN** a student successfully accepts a coach invitation
- **THEN** an active coach–student relationship exists for that pair

#### Scenario: Duplicate link is idempotent
- **WHEN** the same student accepts another invitation from the same coach while a link already exists
- **THEN** the system does not create a second active link and still reports success (or clearly reports already linked)

### Requirement: Users can read their coach–student links
The system SHALL expose a way for an authenticated user to read relationships they participate in (as coach and/or student), gated by permission `relationships:read_own`.

#### Scenario: Student sees linked coach
- **WHEN** a linked student requests their relationships
- **THEN** the response includes the coach identity needed for UI context (at least coach user id and email or display label)

#### Scenario: Coach sees linked students
- **WHEN** a linked coach requests their relationships
- **THEN** the response includes linked student identities
