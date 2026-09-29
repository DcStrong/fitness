## ADDED Requirements

### Requirement: Trainer manages own portfolio
The system SHALL allow a trainer with `portfolio:manage_own` to create, update, reorder, and remove only their own bounded set of portfolio items.

#### Scenario: Trainer adds portfolio item
- **WHEN** a trainer submits a valid title, optional description, and optional HTTPS image URL
- **THEN** the item is stored under that trainer and appears in owner-defined order

#### Scenario: Portfolio limit is enforced
- **WHEN** a trainer attempts to exceed the documented maximum number of items
- **THEN** the system rejects the new item

### Requirement: Portfolio ownership is enforced
A trainer MUST NOT mutate another trainer's portfolio item, even when the item identifier is known.

#### Scenario: Foreign item update is denied
- **WHEN** a trainer attempts to update or delete another trainer's item
- **THEN** the system rejects the request without changing either portfolio

### Requirement: Portfolio is visible only through a published trainer profile
Public readers SHALL receive portfolio items only when the owning trainer profile is currently discoverable. Hiding the profile SHALL immediately hide all portfolio items from social public reads.

#### Scenario: Trainer hides profile
- **WHEN** a published trainer disables discoverability
- **THEN** the trainer's portfolio disappears from discovery and direct public profile responses
