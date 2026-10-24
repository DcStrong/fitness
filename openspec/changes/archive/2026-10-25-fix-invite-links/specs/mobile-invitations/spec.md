## MODIFIED Requirements

### Requirement: Student can accept invitation from deep link or manual token
The app (web and mobile) SHALL open the route `/i/<token>` for the invite HTTPS URL (path URL strategy on web; Caddy serves `index.html` for it) and, on mobile, for incoming Android App Links, iOS Universal Links and `fitnessyoda://invite/<token>`. When the user is authenticated, the app MUST call accept automatically and on success navigate to home with relationship context. If unauthenticated, the app MUST retain the pending token, continue to login/register, and accept it automatically after sign-in. A token rejected by the server (4xx) MUST be discarded from pending storage.

#### Scenario: Authenticated student opens invite link
- **WHEN** a logged-in student opens `/i/<valid token>`
- **THEN** the app calls accept and on success navigates to home showing the linked coach context

#### Scenario: Unauthenticated user opens invite link
- **WHEN** a logged-out user opens `/i/<token>`
- **THEN** the app stores the pending token, shows the login screen, and after login/register accepts the invitation

#### Scenario: Accept failure surfaces error
- **WHEN** accept fails (expired, revoked, invalid)
- **THEN** the app shows a Russian error message, does not claim a link, and drops the pending token
