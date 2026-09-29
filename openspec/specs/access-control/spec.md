# access-control Specification

## Purpose
TBD - created by archiving change mvp-backend-auth-permissions. Update Purpose after archive.
## Requirements
### Requirement: Authorization decisions use permissions
The system SHALL authorize protected actions by checking permissions, not by comparing role name strings in business logic. Effective permissions MUST be resolved from TypeORM-backed role/permission relations.

#### Scenario: Permission grants access
- **WHEN** an authenticated user has permission `users:read_self` and calls an endpoint that requires that permission
- **THEN** the system allows the request

#### Scenario: Missing permission denies access
- **WHEN** an authenticated user lacks the required permission for an endpoint
- **THEN** the system rejects the request as forbidden

### Requirement: Roles are permission bundles
The system SHALL model roles as named sets of permissions that can be assigned to users. Seeded roles MUST include at least `trainer`, `student`, and `admin`.

#### Scenario: Seeded roles exist after migrate/seed
- **WHEN** database seed runs on a fresh environment
- **THEN** roles `trainer`, `student`, and `admin` exist with their configured permission sets

#### Scenario: Effective permissions are union of role permissions
- **WHEN** a user is assigned one or more roles
- **THEN** `/me` (or equivalent) returns the union of permissions from those roles without duplicates

### Requirement: Initial registration assigns a non-admin role bundle
The system SHALL allow registration to request either `trainer` or `student` as the initial role. The system MUST NOT allow self-registration into `admin`.

#### Scenario: Register as trainer
- **WHEN** a client registers requesting role `trainer`
- **THEN** the user receives the `trainer` permission bundle

#### Scenario: Register as student
- **WHEN** a client registers requesting role `student`
- **THEN** the user receives the `student` permission bundle

#### Scenario: Self-register as admin rejected
- **WHEN** a client attempts to register requesting role `admin`
- **THEN** the system rejects the request

### Requirement: Permission catalog is extensible
The system SHALL store permissions as stable string codes (for example `sessions:create`) so new permissions can be added later without changing the authorization mechanism.

#### Scenario: New permission can be seeded
- **WHEN** a new permission code is added to seed data and linked to a role
- **THEN** users with that role receive the new permission on subsequent authentication/profile reads without code changes to the guard mechanism

### Requirement: Invitation and relationship permissions exist in catalog
The system SHALL include permission codes for invitation and relationship flows, for example `invitations:create`, `invitations:read_own`, `invitations:revoke`, `invitations:accept`, and `relationships:read_own`, and assign them to the appropriate seeded roles (`trainer` and/or `student`).

#### Scenario: Trainer role receives create/list/revoke
- **WHEN** seed runs on a fresh database
- **THEN** role `trainer` includes permissions to create, read own, and revoke invitations plus read own relationships

#### Scenario: Student role receives accept
- **WHEN** seed runs on a fresh database
- **THEN** role `student` includes permission to accept invitations and read own relationships

#### Scenario: Authorization still permission-based
- **WHEN** invitation endpoints are protected
- **THEN** guards check permission codes, not role name string equality

### Requirement: Schedule and session permissions exist in catalog
The system SHALL include permission codes `schedules:create`, `schedules:read_own`, `schedules:delete_own`, `schedules:read_linked`, `sessions:book_for_student`, and `sessions:read_own`, and assign them to seeded trainer/student roles appropriately. Student direct `sessions:book_self` SHALL no longer authorize Session creation.

#### Scenario: Trainer seed permissions
- **WHEN** seed runs
- **THEN** trainer includes schedule manage, book_for_student, and sessions read_own

#### Scenario: Student seed permissions
- **WHEN** seed runs
- **THEN** student includes schedules read_linked and sessions read_own but cannot create a Session directly

#### Scenario: Old token contains book_self
- **WHEN** a student with a stale token containing `sessions:book_self` calls direct Session booking
- **THEN** resource policy rejects the action independently of that permission

#### Scenario: Guards remain permission-based
- **WHEN** schedule/session endpoints are protected
- **THEN** authorization checks permission codes plus actor/resource policy, not role name equality

### Requirement: Session lifecycle and history permissions exist in catalog
The system SHALL include permission codes `sessions:complete`, `sessions:cancel`, `sessions:mark_no_show`, and `sessions:read_history`, assigned to seeded roles: trainer gets all four; student gets `sessions:cancel` and `sessions:read_history`.

#### Scenario: Trainer seed includes lifecycle permissions
- **WHEN** seed runs
- **THEN** role `trainer` includes complete, cancel, mark_no_show, and read_history

#### Scenario: Student seed includes cancel and read_history
- **WHEN** seed runs
- **THEN** role `student` includes cancel and read_history but not complete or mark_no_show

#### Scenario: Guards remain permission-based for lifecycle
- **WHEN** lifecycle endpoints are protected
- **THEN** authorization checks permission codes, not role name equality

### Requirement: Tag and plan permissions exist in catalog
The system SHALL include permission codes `tags:create`, `tags:read_own`, `tags:delete_own`, `tags:assign`, `plans:create`, `plans:read_own`, `plans:read_visible`, `plans:update_own`, `plans:delete_own`, `exercises:manage_own`, `exercises:read_own`, and `exercises:read_visible`, assigned to seeded roles: trainer gets tag manage + plan manage + exercise manage; student gets `tags:read_own`, `plans:read_visible`, `exercises:read_own`, and `exercises:read_visible`.

#### Scenario: Trainer seed includes tag and plan manage
- **WHEN** seed runs
- **THEN** role `trainer` includes create/read/delete/assign tags, create/read/update/delete own plans, and manage/read own exercises

#### Scenario: Student seed includes read tags and visible plans
- **WHEN** seed runs
- **THEN** role `student` includes `tags:read_own`, `plans:read_visible`, `exercises:read_own`, and `exercises:read_visible` but not plan create/update/delete or exercise manage

#### Scenario: Guards remain permission-based for tags and plans
- **WHEN** tag, plan, or exercise endpoints are protected
- **THEN** authorization checks permission codes, not role name equality

### Requirement: Exercise visibility permission exists in catalog
The system SHALL include permission code `exercises:read_visible` and assign it to the seeded `student` role. The seeded `trainer` role MUST retain `exercises:manage_own` and `exercises:read_own` and MUST NOT require `exercises:read_visible` to manage tags or assignments.

#### Scenario: Student seed includes visible exercises
- **WHEN** seed runs
- **THEN** role `student` includes `exercises:read_visible` in addition to `exercises:read_own`

#### Scenario: Visible exercises guard is permission-based
- **WHEN** the visible-exercises endpoint is protected
- **THEN** authorization checks `exercises:read_visible`, not role name equality

### Requirement: Finance permissions exist in catalog
The system SHALL include permission codes `finance:manage_settings`, `finance:read_own`, `finance:mark_paid`, `finance:record_expense`, `finance:adjust_own`, and `finance:read_own_charge`. The trainer role SHALL receive all trainer finance permissions; the student role SHALL receive only `finance:read_own_charge`.

#### Scenario: Trainer seed includes finance management
- **WHEN** seed runs
- **THEN** role `trainer` can configure price, read own finances, mark paid, record expense, and adjust own ledger

#### Scenario: Student seed is read-only and scoped
- **WHEN** seed runs
- **THEN** role `student` can read only financial summaries for their own Session charges

#### Scenario: Finance guards remain permission-based
- **WHEN** finance endpoints are protected
- **THEN** authorization checks permission codes plus resource ownership, not role-name equality alone

### Requirement: Social and privacy permissions exist in catalog
The system SHALL include permission codes `profiles:read_public`, `profiles:update_own`, `profiles:manage_privacy`, `profiles:read_linked_contacts`, `portfolio:manage_own`, `reviews:read`, `reviews:create_own`, and `reviews:update_own`.

#### Scenario: Trainer permissions are seeded
- **WHEN** permission seed runs
- **THEN** trainer receives public profile read, own profile/privacy/portfolio management, linked-contact read, and review read permissions

#### Scenario: Student permissions are seeded
- **WHEN** permission seed runs
- **THEN** student receives public profile read, own profile/privacy management, linked-contact read, and own review read/create/update permissions without portfolio management

#### Scenario: Linked-contact permission lacks relationship
- **WHEN** a user with `profiles:read_linked_contacts` targets an unlinked user
- **THEN** resource policy still denies the contact response

### Requirement: Booking request permissions exist in catalog
The system SHALL include stable permission codes `booking_requests:create`, `booking_requests:read_own`, `booking_requests:read_inbox`, and `booking_requests:respond`. Student SHALL receive create/read-own; trainer SHALL receive read-inbox/respond; admin MAY receive all according to existing admin policy.

#### Scenario: Student request permissions are seeded
- **WHEN** seed runs
- **THEN** student can create, list, and withdraw own BookingRequests but cannot respond as trainer

#### Scenario: Trainer request permissions are seeded
- **WHEN** seed runs
- **THEN** trainer can list/count their inbox and respond to owned requests but cannot create a student request

#### Scenario: Permission without ownership is insufficient
- **WHEN** a trainer with respond permission targets another trainer's request
- **THEN** resource policy rejects the operation

### Requirement: Social authorization combines permission and resource policy
Every social write SHALL require the relevant permission plus owner, Session participant/status, or visibility checks. Role-name equality alone MUST NOT authorize a resource operation.

#### Scenario: Permission without ownership is insufficient
- **WHEN** a user with an own-resource permission targets another user's profile, portfolio, or review
- **THEN** the system rejects the operation

