## MODIFIED Requirements

### Requirement: User manages an own profile
The system SHALL allow an authenticated user with `profiles:update_own` to read and update only their own validated profile fields, including optional phone, Telegram username, and preferred contact channels. A phone MUST be a Russian E.164 number `+7XXXXXXXXXX`; any other format MUST be rejected with 400. Trainer specialties MUST contain at most 8 tags of at most 30 characters each. A trainer's own profile response SHALL include their gyms. Missing legacy profiles SHALL remain valid and be created on first successful update.

#### Scenario: User saves contact preferences
- **WHEN** a user submits a valid `+7XXXXXXXXXX` phone, Telegram username, and preferred channels whose values are present
- **THEN** the profile stores them and returns the normalized values

#### Scenario: Non-Russian or unformatted phone is rejected
- **WHEN** a user submits `89991234567`, `+380991234567`, or `+7 (999) 123-45-67`
- **THEN** the request is rejected with 400

#### Scenario: Too many or too long specialties
- **WHEN** a trainer submits more than 8 specialties or one longer than 30 characters
- **THEN** the request is rejected with 400
