## ADDED Requirements

### Requirement: Trainer can create and manage own training plans
The system SHALL allow a user with `plans:create` / `plans:update_own` / `plans:delete_own` / `plans:read_own` to create, update, delete, and list training plans they own. A plan MUST include `title` and MAY include `body` text content. Only the owner coach may mutate the plan.

#### Scenario: Create plan
- **WHEN** a trainer creates a plan with a title
- **THEN** a training plan owned by that trainer is stored and listed in their own plans

#### Scenario: Update own plan
- **WHEN** the owner updates title or body
- **THEN** the stored plan reflects the new values

#### Scenario: Non-owner cannot update
- **WHEN** another user attempts to update the plan
- **THEN** the system rejects the request

### Requirement: Trainer can attach own tags to own plans
The system SHALL allow the plan owner to set the plan's tag set to tags they created. Foreign tags MUST be rejected.

#### Scenario: Attach own tags on create or update
- **WHEN** a trainer sets `tagIds` to tags they own on create or update
- **THEN** those tags are linked to the plan

#### Scenario: Foreign tag rejected
- **WHEN** a trainer includes a tagId they did not create
- **THEN** the system rejects the request

### Requirement: Student can list and read visible plans
The system SHALL allow a user with `plans:read_visible` to list and read plans that are **visible**: the plan's owner is a linked coach of the student, and the intersection of the student's assigned tags and the plan's tags is non-empty. Plans with no tags MUST NOT appear in the visible list.

#### Scenario: Shared tag makes plan visible
- **WHEN** a linked student shares at least one tag with a coach's plan
- **THEN** that plan appears in the student's visible plans list

#### Scenario: No shared tag hides plan
- **WHEN** a linked student has no tag in common with a plan
- **THEN** that plan does not appear in the visible list

#### Scenario: Unlinked coach plan not visible
- **WHEN** a student is not linked to the plan's coach
- **THEN** the plan is not visible even if tag names coincide
