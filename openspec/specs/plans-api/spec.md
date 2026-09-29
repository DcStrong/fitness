# plans-api Specification

## Purpose
HTTP API for trainer-owned training plan templates (`kind`, `goal`, `notes` / legacy `body`, nested exercises/sets) with tag attachment and tag-filtered listing, catalog seed listing/clone, student visibility via coach link ∩ shared tags, listing assigned `kind=student_copy` plans separately from templates, and batch assign of templates to one student.

## Requirements

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

### Requirement: Coach can create an ad-hoc student copy
The system SHALL allow a user with `plans:create` to create a `kind=student_copy` assigned to a linked student by sending `assignedStudentId`. The student MUST be linked to the coach. Omitting `assignedStudentId` MUST create `kind=template`.

#### Scenario: Create copy for linked student
- **WHEN** a trainer creates a plan with `assignedStudentId` of a linked student
- **THEN** the stored plan is `kind=student_copy` assigned to that student

#### Scenario: Unlinked student rejected
- **WHEN** a trainer creates a plan with `assignedStudentId` of a user who is not linked
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

### Requirement: Trainer can list assigned student copies separately from templates
The system SHALL NOT include `kind=student_copy` rows in the default trainer own-templates list. When assigned scope with a linked `studentId` is requested, the system SHALL return that trainer's copies for the student.

#### Scenario: Default list omits copies
- **WHEN** a trainer lists own plans with default template scope
- **THEN** `kind=student_copy` plans are not returned

#### Scenario: Assigned scope for student
- **WHEN** a trainer lists assigned plans for a linked student
- **THEN** that student's copies are returned

### Requirement: Trainer can filter own templates by tag
The system SHALL allow a user with `plans:read_own` to list own `kind=template` plans filtered by a tag they created. Plans that do not include the tag MUST be omitted.

#### Scenario: Filter own templates by tag
- **WHEN** a trainer lists own plans with a tag they own
- **THEN** only templates that include that tag are returned

### Requirement: Trainer can assign multiple templates to one student in one request
The system SHALL allow the template owner with `plans:create` to assign many own `kind=template` plans to one linked student in a single request. For each plan the system MUST reuse or create a `kind=student_copy` as in single-template assign. The request MUST be transactional: if any plan is foreign or the student is unlinked, no copies are written. An empty `planIds` list MUST be rejected.

#### Scenario: Assign two templates to one student
- **WHEN** a trainer assigns two own templates to a linked student
- **THEN** a `kind=student_copy` exists for each template for that student and the templates are unchanged

#### Scenario: Batch with unlinked student rejected
- **WHEN** a trainer includes a user who is not a linked student
- **THEN** the system rejects the request and creates no copies

### Requirement: Trainer can bulk-update working weights on a plan without replacing the exercise list
The system SHALL allow the owning coach with `plans:update_own` to PATCH working weights on a `kind=template` or `kind=student_copy` plan by `exerciseId`. Each listed `weight_reps` exercise MUST receive the given `weightKg` on all of its sets. The exercise order, reps, rest, and duration fields MUST remain unchanged. Unknown `exerciseId` values or foreign plans MUST be rejected. Catalog seed plans MUST NOT accept this PATCH.

#### Scenario: Update bench weight on template
- **WHEN** the owner PATCHes loads with bench press 80 kg on their template
- **THEN** every set of that exercise on the template stores 80 kg and other exercises are unchanged

#### Scenario: Student copy loads do not change template
- **WHEN** the owner PATCHes loads on a student copy
- **THEN** the parent template weights stay the same

#### Scenario: Catalog loads rejected
- **WHEN** a user PATCHes loads on a `kind=catalog_seed` plan
- **THEN** the system rejects the request
