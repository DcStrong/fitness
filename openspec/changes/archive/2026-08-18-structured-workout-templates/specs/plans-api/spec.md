## ADDED Requirements

### Requirement: Trainer can store structured exercises and sets on a template
The system SHALL persist trainer-owned templates (`kind=template`) with a `goal` of `hypertrophy`, `fat_loss`, or `general` (default `general`) and an ordered list of plan exercises, each referencing an exercise and optional rest, with ordered sets carrying `reps`, `weightKg`, and/or `durationSeconds` according to the exercise kind. Create and update MUST accept nested `exercises`. A template MAY have zero exercises (legacy rows). Only the owner coach may mutate a `kind=template` plan. Catalog templates (`kind=catalog_seed`) MUST be listable and readable and MUST NOT be mutated via the API.

#### Scenario: Create template with nested exercises
- **WHEN** a trainer creates a plan with title, goal, and nested exercises/sets
- **THEN** the stored plan is `kind=template` owned by that trainer and GET returns the nested exercises

#### Scenario: Update replaces exercise list
- **WHEN** the owner PATCHes `exercises` on their template
- **THEN** the stored plan exercise/set lists match the payload

#### Scenario: Catalog mutation rejected
- **WHEN** a user attempts to PATCH or DELETE a `kind=catalog_seed` plan
- **THEN** the system rejects the request

#### Scenario: Legacy body is notes
- **WHEN** a client reads a plan that previously had only `body` text
- **THEN** the response includes that text as `notes` (and MAY still include `body` as an alias)

### Requirement: Trainer can list own templates separately from catalog
The system SHALL list the authenticated trainer's `kind=template` plans on the default own-plans list and SHALL list `kind=catalog_seed` plans only when catalog scope is requested. Own list MUST NOT include catalog rows or `kind=student_copy` rows.

#### Scenario: Default own list is templates
- **WHEN** a trainer lists own plans without a catalog filter
- **THEN** only that trainer's `kind=template` plans are returned

#### Scenario: Catalog list
- **WHEN** a trainer lists plans with catalog scope
- **THEN** `kind=catalog_seed` plans are returned and own templates are not mixed in

### Requirement: Trainer can clone a catalog template into own library
The system SHALL allow a trainer with `plans:create` to clone a `kind=catalog_seed` plan into a new `kind=template` owned by themselves, copying title, goal, notes, and exercise/set structure. The clone MUST NOT mutate the catalog row.

#### Scenario: Clone catalog
- **WHEN** a trainer clones a catalog template
- **THEN** a new own `kind=template` plan exists with the same goal and exercise structure and the catalog plan is unchanged

## MODIFIED Requirements

### Requirement: Trainer can create and manage own training plans
The system SHALL allow a user with `plans:create` / `plans:update_own` / `plans:delete_own` / `plans:read_own` to create, update, delete, and list training plans they own. A plan MUST include `title` and MAY include `notes` (legacy `body`) plus structured exercises. Only the owner coach may mutate a `kind=template` plan. Catalog seed plans are not owner-mutable.

#### Scenario: Create plan
- **WHEN** a trainer creates a plan with a title
- **THEN** a training plan owned by that trainer is stored as `kind=template` and listed in their own plans

#### Scenario: Update own plan
- **WHEN** the owner updates title, notes, goal, tags, or exercises
- **THEN** the stored plan reflects the new values

#### Scenario: Non-owner cannot update
- **WHEN** another user attempts to update the plan
- **THEN** the system rejects the request
