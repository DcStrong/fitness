## ADDED Requirements

### Requirement: Coach console manages public profile
The web coach console SHALL provide Russian UI for the trainer to edit owner profile fields and privacy settings, including an explicit publish/unpublish control.

#### Scenario: Trainer saves hidden draft
- **WHEN** a trainer saves profile content without enabling discovery
- **THEN** the owner data persists but public discovery remains unchanged

### Requirement: Coach console manages portfolio
The web console SHALL allow the trainer to create, edit, reorder, and remove own portfolio items with validation feedback.

#### Scenario: Trainer reorders portfolio
- **WHEN** the trainer changes item order and saves
- **THEN** owner preview and subsequent public profile reads use the new order

### Requirement: Coach console previews public projection
The web console SHALL show a preview based on the privacy-safe public projection and clearly indicate when the profile is hidden.

#### Scenario: Hidden profile preview
- **WHEN** a hidden trainer opens preview
- **THEN** the console shows how the card would look and states that other users cannot discover it

### Requirement: Coach console lists received reviews read-only
The web console SHALL show reviews received by the trainer and derived rating/count without controls that edit student rating or text.

#### Scenario: Trainer opens reviews
- **WHEN** a trainer opens the review section
- **THEN** the console displays owner-authorized reviews with privacy-safe reviewer attribution and no edit/delete action

### Requirement: Student remains excluded from coach console
Social web routes SHALL remain protected by the existing coach-console auth shell.

#### Scenario: Student opens profile editor
- **WHEN** an authenticated student opens the web profile-management route
- **THEN** the console denies access without loading owner trainer data
