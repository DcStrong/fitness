## ADDED Requirements

### Requirement: Trainer can open a tag hub of members and tagged content
The system SHALL let a user with `tags:read_own` who created the tag read a hub payload for that tag: linked students currently assigned the tag, own `kind=template` plans that include the tag, and exercises that include the tag (including catalog exercises tagged by that trainer). Foreign tags MUST be rejected.

#### Scenario: Hub lists students and content
- **WHEN** the creator requests the hub for a tag assigned to two students and attached to one plan and two exercises
- **THEN** the response includes those two students, that plan, and those two exercises

#### Scenario: Foreign tag hub rejected
- **WHEN** a trainer requests a hub for a tag they did not create
- **THEN** the system rejects the request

### Requirement: Trainer can filter own plans and exercises by tag
The system SHALL allow listing own templates and the trainer's tagged exercise set filtered by a tag they own.

#### Scenario: Filter plans by tag
- **WHEN** a trainer lists own plans with a tag they own
- **THEN** only templates that include that tag are returned
