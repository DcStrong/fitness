## MODIFIED Requirements

### Requirement: Trainer manages own portfolio
The system SHALL allow a trainer with `portfolio:manage_own` to create, update, reorder, and remove only their own portfolio of **at most 5 items**. There is no minimum, and portfolio size does not affect profile publication. An item's image is an upload from the trainer's device (a storage URL returned by `POST /media/images`); an external HTTPS URL remains accepted.

#### Scenario: Trainer adds portfolio item
- **WHEN** a trainer submits a valid title, optional description, and optional image URL (uploaded file URL or HTTPS URL)
- **THEN** the item is stored under that trainer and appears in owner-defined order

#### Scenario: Portfolio limit is enforced
- **WHEN** a trainer who already has 5 items attempts to add another
- **THEN** the system responds 409 with `code: PORTFOLIO_LIMIT_REACHED` and stores nothing

#### Scenario: Empty portfolio is allowed
- **WHEN** a trainer has no portfolio items
- **THEN** the trainer can still publish the profile
