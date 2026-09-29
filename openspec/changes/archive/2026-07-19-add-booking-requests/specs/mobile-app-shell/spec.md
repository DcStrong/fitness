## MODIFIED Requirements

### Requirement: Router exposes schedule and session routes
The Flutter app shell SHALL register authenticated routes for trainer schedule management, student request creation/tracking, trainer BookingRequest inbox/details, direct trainer book-for-student, and Sessions list (for example `/schedule/slots`, `/schedule/book`, `/booking-requests/mine`, `/booking-requests/inbox`, `/booking-requests/:id`, `/schedule/book-for-student`, `/sessions`). Route presentation SHALL be role-aware while backend permissions remain authoritative.

#### Scenario: Authenticated user opens sessions
- **WHEN** a logged-in user navigates to the sessions route
- **THEN** the sessions screen is shown

#### Scenario: Student opens own requests
- **WHEN** an authenticated student navigates to the own-requests route
- **THEN** the student BookingRequest list is shown without trainer decision actions

#### Scenario: Trainer opens request inbox
- **WHEN** an authenticated trainer navigates to the inbox route
- **THEN** the trainer request-management screen is shown

#### Scenario: Role-inappropriate request destination
- **WHEN** the authenticated role opens a request route intended only for the other role
- **THEN** role-aware routing hides/replaces the destination and backend authorization still prevents access

#### Scenario: Unauthenticated redirected
- **WHEN** a logged-out user hits schedule, request, or sessions routes
- **THEN** the router redirects to login
