## ADDED Requirements

### Requirement: Series detail offers program setup
The Russian recurring series detail SHALL include a primary or secondary action «Программа» that opens the workout program screen for that series when the series is active. After creating a series the app MAY prompt to set the program rather than leaving the trainer on an empty split.

#### Scenario: Open program from detail
- **WHEN** a trainer taps «Программа» on an active series
- **THEN** the program screen opens for that recurring booking id

#### Scenario: Cancelled series hides upsert
- **WHEN** the series is cancelled
- **THEN** the detail does not offer saving a new program
