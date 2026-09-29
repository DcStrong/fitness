## MODIFIED Requirements

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

## ADDED Requirements

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
