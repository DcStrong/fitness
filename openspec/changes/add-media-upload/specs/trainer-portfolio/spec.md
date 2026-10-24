## MODIFIED Requirements

### Requirement: Trainer manages own portfolio
The system SHALL allow a trainer with `portfolio:manage_own` to create, update, reorder, and remove only their own portfolio. A portfolio item has a title, an optional description and **a list of photos (`imageUrls`)**; the portfolio holds **at most 5 photos in total across all items** (and at most 5 items). There is no minimum, and portfolio size does not affect profile publication. Photos are uploads from the trainer's device (storage URLs returned by `POST /media/portfolio-images`); external HTTPS URLs remain accepted. The legacy single `imageUrl` is still accepted on write (treated as `imageUrls: [imageUrl]`) and is returned on read as the first photo.

#### Scenario: Trainer adds portfolio item with several photos
- **WHEN** a trainer submits a valid title, optional description and up to 5 photo URLs
- **THEN** one item is stored with all photos in the given order and appears in owner-defined order

#### Scenario: Portfolio photo limit is enforced across items
- **WHEN** the sum of photos of the trainer's other items plus the submitted photos exceeds 5
- **THEN** the system responds 409 with `code: PORTFOLIO_LIMIT_REACHED` and stores nothing

#### Scenario: Batch upload respects remaining slots
- **WHEN** a trainer uploads more files than free photo slots (5 minus photos already in the portfolio)
- **THEN** `POST /media/portfolio-images` responds 409 `PORTFOLIO_LIMIT_REACHED`

#### Scenario: Empty portfolio is allowed
- **WHEN** a trainer has no portfolio items
- **THEN** the trainer can still publish the profile
