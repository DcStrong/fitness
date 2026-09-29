# tags-api Specification

## Purpose
HTTP API for trainer-owned tags: create/list/delete, assign to linked students, student read of assigned tags, and a creator hub of members plus tagged plans and exercises.
## Requirements
### Requirement: Trainer can create and list own tags
The system SHALL allow a user with `tags:create` to create a tag with a non-empty name owned by themselves. Tags MUST be unique per creator `(creatorId, name)` (case-sensitive or normalized as implemented, but consistently). Users with `tags:read_own` who created tags SHALL list their own tags.

#### Scenario: Create tag
- **WHEN** a trainer creates a tag with a new name
- **THEN** the tag is stored with `creatorId` equal to the trainer and appears in their tag list

#### Scenario: Duplicate name for same creator rejected
- **WHEN** a trainer creates a tag with a name they already own
- **THEN** the system rejects the request

### Requirement: Trainer can delete own tags
The system SHALL allow a user with `tags:delete_own` to delete a tag they created. Deletion MUST remove related user and plan tag assignments for that tag.

#### Scenario: Delete own tag
- **WHEN** the creator deletes their tag
- **THEN** the tag and its assignments are removed

#### Scenario: Delete foreign tag rejected
- **WHEN** a user attempts to delete a tag they did not create
- **THEN** the system rejects the request as forbidden or not found

### Requirement: Trainer can assign own tags to linked students
The system SHALL allow a user with `tags:assign` to assign a tag they created to a student only if an active coach–student link exists between them. The system SHALL support unassigning that pairing.

#### Scenario: Assign tag to linked student
- **WHEN** a coach assigns their tag to a linked student
- **THEN** the student–tag assignment exists

#### Scenario: Assign to unlinked user rejected
- **WHEN** a coach assigns their tag to a user without an active link
- **THEN** the system rejects the request

### Requirement: Users can read tags relevant to them
The system SHALL allow a student with `tags:read_own` to list tags currently assigned to them. A trainer with `tags:read_own` SHALL list tags they created (and MAY list assignees via a dedicated endpoint for their tags).

#### Scenario: Student lists assigned tags
- **WHEN** a student lists their tags
- **THEN** only tags assigned to that student are returned

### Requirement: Trainer can open a tag hub of members and tagged content
The system SHALL let a user with `tags:read_own` who created the tag read a hub payload for that tag: linked students currently assigned the tag (including display name when a profile exists), own `kind=template` and `kind=student_copy` plans that include the tag, and exercises that include the tag (including catalog exercises tagged by that trainer). Foreign tags MUST be rejected.

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
