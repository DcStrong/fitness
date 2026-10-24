## MODIFIED Requirements

### Requirement: Trainer manages own portfolio
The system SHALL allow a trainer with `portfolio:manage_own` to create, update, reorder, and remove only their own portfolio of **at most 5 items**, where **each item holds at most 5 photos** (`imageUrls`). The two limits are independent: photos of different items are never summed. There is no minimum, and portfolio size does not affect profile publication. Photos are uploads from the trainer's device (storage URLs returned by `POST /media/portfolio-images`); external HTTPS URLs remain accepted. The legacy single `imageUrl` is still accepted on write (treated as `imageUrls: [imageUrl]`) and is returned on read as the first photo.

#### Scenario: Trainer adds portfolio item with several photos
- **WHEN** a trainer submits a valid title, optional description and up to 5 photo URLs
- **THEN** one item is stored with all photos in the given order and appears in owner-defined order

#### Scenario: Item limit is enforced
- **WHEN** a trainer who already has 5 items attempts to add another
- **THEN** the system responds 409 with `code: PORTFOLIO_LIMIT_REACHED` and stores nothing

#### Scenario: Photo limit per item is enforced
- **WHEN** a trainer submits more than 5 photos for one item
- **THEN** the system responds 409 with `code: PORTFOLIO_ITEM_PHOTOS_LIMIT_REACHED` and stores nothing

#### Scenario: Items do not share a photo budget
- **WHEN** one item already has 5 photos and the trainer adds another item with 5 photos
- **THEN** the second item is stored

#### Scenario: Empty portfolio is allowed
- **WHEN** a trainer has no portfolio items
- **THEN** the trainer can still publish the profile
