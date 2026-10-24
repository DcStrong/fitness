## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Trainer cards and public profiles list gyms
Discovery items and the public trainer profile SHALL include the trainer's gyms (id, name, address, city, district). Gyms SHALL be exposed only for published trainers, under the same visibility rules as the portfolio.

#### Scenario: Published trainer shows gyms
- **WHEN** a student opens a published trainer with attached gyms
- **THEN** the profile and the discovery card list those gyms

#### Scenario: Hidden trainer exposes no gyms
- **WHEN** a trainer is not discoverable
- **THEN** no discovery item or public profile reveals their gyms
