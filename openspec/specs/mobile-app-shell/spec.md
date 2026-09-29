# mobile-app-shell Specification

## Purpose
TBD - created by archiving change mvp-mobile-auth-shell. Update Purpose after archive.
## Requirements
### Requirement: App boots with router and auth gate
The Flutter app SHALL start with `MaterialApp.router` using `go_router` and SHALL redirect based on authentication session state.

#### Scenario: Cold start without tokens
- **WHEN** the app starts and no access token is stored
- **THEN** the user is shown the login route (or equivalent unauthenticated entry)

#### Scenario: Cold start with valid session
- **WHEN** the app starts with a stored access token and `/users/me` succeeds
- **THEN** the user is taken to the home route without seeing login

### Requirement: Home shows signed-in profile stub
The authenticated Home route SHALL present a role-aware daily workspace instead of a signed-in profile stub. Trainer Home SHALL prioritize today's sessions and operational destinations; authenticated profile details and logout SHALL remain available through the existing Profile destination.

#### Scenario: Trainer reaches Home after login
- **WHEN** an authenticated trainer is redirected to `/home`
- **THEN** the daily schedule dashboard is shown within the authenticated shell

#### Scenario: Profile and logout remain available
- **WHEN** Home no longer displays the signed-in profile stub
- **THEN** the authenticated user can still access profile details and logout through the Profile destination

#### Scenario: Student completes login
- **WHEN** an authenticated student completes login
- **THEN** the existing student initial destination remains unchanged and the change does not force the student onto `/home`

### Requirement: Router exposes invitation routes
The Flutter app shell SHALL register routes for trainer invite UI and student accept/invite handling (for example `/invite` and `/invite/accept`), integrated with existing auth redirects so unauthenticated users cannot use trainer invite creation.

#### Scenario: Trainer can open invite route when authenticated
- **WHEN** an authenticated trainer navigates to the invite route
- **THEN** the invite screen is shown

#### Scenario: Unauthenticated blocked from trainer invite
- **WHEN** an unauthenticated user attempts the trainer invite route
- **THEN** the router redirects to login

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

### Requirement: Router exposes session history route
The Flutter app shell SHALL register an authenticated route for session history (e.g. `/sessions/:id/history`) gated by the existing auth redirect rules.

#### Scenario: Authenticated user opens history route
- **WHEN** a logged-in participant navigates to the session history route
- **THEN** the history screen is shown

#### Scenario: Unauthenticated redirected from history
- **WHEN** a logged-out user hits the session history route
- **THEN** the router redirects to login

### Requirement: Router exposes plans and tags routes
The Flutter app shell SHALL register authenticated routes for trainer tag/plan management and student visible plans (e.g. `/tags`, `/plans`, `/plans/:id`), gated by existing auth redirect rules.

#### Scenario: Authenticated user opens plans route
- **WHEN** a logged-in user navigates to the plans route
- **THEN** the plans screen is shown

#### Scenario: Unauthenticated redirected from plans or tags
- **WHEN** a logged-out user hits plans or tags routes
- **THEN** the router redirects to login

### Requirement: Workout library uses existing plans routes
The Flutter app shell SHALL present the trainer template library on authenticated `/plans` routes. The trainer indexed bottom navigation SHALL include a «Тренировки» destination (dumbbell / `Icons.fitness_center`) that opens `/plans`. The student «Тренировки» destination SHALL remain `/sessions`. Unauthenticated access to plans routes SHALL redirect to login.

#### Scenario: Trainer opens planning from bottom nav
- **WHEN** an authenticated trainer selects «Тренировки» in the bottom navigation
- **THEN** the app shows the workout template library at `/plans`

#### Scenario: Unauthenticated redirected from plans
- **WHEN** a logged-out user hits plans routes
- **THEN** the router redirects to login

#### Scenario: Student bottom nav unchanged
- **WHEN** an authenticated student views the bottom navigation
- **THEN** «Тренировки» still opens `/sessions` and there is no extra plans tab

### Requirement: Router exposes authenticated finance routes
The Flutter app shell SHALL register authenticated routes for trainer finance summary/settings/ledger and Session charge details. Existing auth redirects MUST protect these routes.

#### Scenario: Trainer opens wallet
- **WHEN** an authenticated trainer navigates to the finance route
- **THEN** the trainer finance screen is shown

#### Scenario: Unauthenticated finance route access
- **WHEN** a logged-out user opens a finance route
- **THEN** the app redirects to login

### Requirement: Authenticated routes use role-aware bottom navigation
The Flutter app shell SHALL provide a Fitness Yoda bottom navigation experience for authenticated primary destinations, preserve existing `go_router` route protection and deep-link behavior, and expose only destinations appropriate to the authenticated trainer or student.

#### Scenario: Authenticated user enters the app shell
- **WHEN** a logged-in user opens a primary authenticated destination
- **THEN** the bottom navigation is visible with the current destination represented by a mint active pill, primary icon, and label

#### Scenario: User changes primary destination
- **WHEN** the user selects an available inactive navigation item
- **THEN** the router displays the corresponding existing feature destination and updates the active navigation state

#### Scenario: Trainer and student have different destinations
- **WHEN** the authenticated user's role does not support a navigation destination
- **THEN** that destination is hidden or replaced by the role-appropriate destination without bypassing route permissions

#### Scenario: User opens an unauthenticated route
- **WHEN** Login or Register is displayed
- **THEN** the authenticated bottom navigation shell is not visible

#### Scenario: Unauthenticated user opens a protected shell destination
- **WHEN** a logged-out user attempts to open a protected navigation destination
- **THEN** the existing authentication redirect sends the user to Login

### Requirement: Router exposes authenticated social routes
The Flutter app shell SHALL register authenticated routes for trainer discovery/public profile, own profile/privacy, review eligibility, and review editing.

#### Scenario: Authenticated student opens discovery
- **WHEN** a signed-in student navigates to the trainers route
- **THEN** the discovery screen is shown

#### Scenario: Logged-out user opens social route
- **WHEN** a logged-out user opens any social/profile/review route
- **THEN** existing auth redirects send the user to login

### Requirement: Student shell exposes social navigation
The authenticated student shell SHALL provide clear navigation among trainers, training Sessions, and own profile without exposing trainer-only management routes.

#### Scenario: Student sees primary destinations
- **WHEN** a student reaches the authenticated shell
- **THEN** «Тренеры», «Тренировки», and «Профиль» destinations are available

### Requirement: Authenticated shell uses the shared custom top bar
Authenticated destinations presented inside the app shell SHALL use the shared Fitness Yoda top bar (title and optional subtitle) instead of an unstyled default Material AppBar appearance, except where a screen deliberately opts into a documented full-bleed or modal presentation. Nested authenticated routes that show a leading back control MUST still use the shared top bar styling.

#### Scenario: Trainer opens Home
- **WHEN** an authenticated trainer lands on Home inside the shell
- **THEN** the screen chrome uses the shared top bar title treatment rather than an unrelated default Material AppBar look

#### Scenario: Nested authenticated route
- **WHEN** the user opens a nested authenticated route that shows a back affordance
- **THEN** the top chrome remains visually consistent with the shared top bar (including leading back) and does not introduce a notification bell

### Requirement: Shell tab changes use fade and slide motion
When the user switches among primary shell tabs (IndexedStack / StatefulShell branches), the shell SHALL animate the incoming branch with a short fade and slight slide. Reduced-motion settings MUST suppress or minimize the transition.

#### Scenario: User switches bottom tab
- **WHEN** an authenticated user selects a different primary bottom-navigation destination
- **THEN** the newly visible branch appears with a brief fade and slide rather than an instantaneous hard cut

#### Scenario: Tab switch with reduced motion
- **WHEN** reduce-motion is enabled and the user switches tabs
- **THEN** the destination still changes without a long decorative animation
