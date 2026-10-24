# trainer-discovery Specification

## Purpose
Define authenticated, privacy-safe trainer discovery and direct public trainer profile access.

## Requirements

### Requirement: Authenticated users discover only published trainers
The system SHALL expose a paginated trainer discovery list to users with `profiles:read_public`. Only trainer-role users with `isDiscoverable=true` and a valid public display name SHALL appear.

#### Scenario: Published trainer appears
- **WHEN** an authenticated user requests the first discovery page
- **THEN** the response contains matching published trainers with stable pagination metadata

#### Scenario: Hidden trainer is excluded
- **WHEN** a trainer has discoverability disabled
- **THEN** that trainer does not appear on any discovery page

### Requirement: Discovery supports bounded filters
The system SHALL support bounded page/limit pagination plus optional plain-text query, specialty, `online|offline` mode, city, gym (`gymId`), district, and gym text (`gymQuery`, a substring of the gym name or address) filters. City SHALL match the trainer's profile city or the city of any of their gyms. Gym, district, and gym text conditions SHALL be evaluated against the same gym of the trainer. Limit MUST NOT exceed the server maximum.

#### Scenario: Student filters online trainers
- **WHEN** a student requests trainers with mode `online`
- **THEN** every returned item advertises online training and the result remains paginated

#### Scenario: Oversized page is rejected or capped
- **WHEN** a caller requests a limit above the server maximum
- **THEN** the API rejects the request or applies the documented maximum without returning an unbounded result

#### Scenario: Student filters by gym
- **WHEN** a student requests trainers with a `gymId`
- **THEN** only published trainers attached to that gym are returned, each once

#### Scenario: Student searches by district and address text
- **WHEN** a student requests trainers with `district` or `gymQuery`
- **THEN** only published trainers having a gym whose district, name, or address contains the text are returned

### Requirement: Direct trainer profile respects visibility
The system SHALL return a trainer's social public profile only while it is discoverable. A hidden, non-trainer, or missing target SHALL produce indistinguishable not-found behavior for non-owners.

#### Scenario: Hidden profile cannot be enumerated
- **WHEN** a non-owner requests a hidden trainer by UUID
- **THEN** the system returns not found without revealing whether the account exists

### Requirement: Discovery preserves invitation-first relationships
Trainer discovery SHALL NOT create a coach-student link, expose open slots, or permit booking an unlinked trainer. For an authenticated student, the response MAY include only whether that same student is already linked.

#### Scenario: Unlinked student opens trainer profile
- **WHEN** a student views a discoverable trainer with no existing link
- **THEN** the profile indicates that an invitation is required and exposes no booking action or slot data

#### Scenario: Linked status is viewer-scoped
- **WHEN** a student views a discoverable trainer
- **THEN** any relationship flag describes only the current student and reveals no other students

### Requirement: Trainer cards and public profiles list gyms
Discovery items and the public trainer profile SHALL include the trainer's gyms (id, name, address, city, district). Gyms SHALL be exposed only for published trainers, under the same visibility rules as the portfolio.

#### Scenario: Published trainer shows gyms
- **WHEN** a student opens a published trainer with attached gyms
- **THEN** the profile and the discovery card list those gyms

#### Scenario: Hidden trainer exposes no gyms
- **WHEN** a trainer is not discoverable
- **THEN** no discovery item or public profile reveals their gyms
