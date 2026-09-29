## ADDED Requirements

### Requirement: Day mode animates selected-date changes
In trainer calendar **day** mode, when the selected local date changes (via date strip, period controls, or equivalent), the day body content SHALL transition with a short AnimatedSwitcher-style fade/slide. Changing calendar mode (day/week/month) MUST NOT be required to use the same animation. Reduced-motion settings MUST suppress or minimize the transition. Event projection and tap targets MUST remain unchanged.

#### Scenario: Trainer picks another day
- **WHEN** the trainer selects a different local date while remaining in day mode
- **THEN** the day timeline/body updates with a brief fade and/or slide and still shows the correct events for that date

#### Scenario: Mode change is not forced through day animation
- **WHEN** the trainer switches from day to week mode
- **THEN** the calendar still switches modes correctly without requiring the day-date animation contract
