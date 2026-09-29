## MODIFIED Requirements

### Requirement: Catalog seed is gym-only strength work
The system SHALL seed catalog exercises and `kind=catalog_seed` templates with gym strength movements only (barbell/dumbbell/machine/bodyweight gym work such as bench press, squat, pull-ups, rows, presses). Catalog MUST NOT include running, cycling, elliptical, or other outdoor/cardio-machine work. Re-seed MUST be idempotent: retired catalog names (e.g. bicycle) SHALL be renamed or left unused rather than breaking plans that already reference their ids.

#### Scenario: Catalog list has no cycling or running
- **WHEN** a trainer lists catalog exercises after seed
- **THEN** names do not include велосипед, бег, or equivalent cardio-outside-gym movements

#### Scenario: Hypertrophy/fat-loss catalog templates stay gym
- **WHEN** a trainer opens a catalog fat-loss template
- **THEN** its exercises are gym movements (higher-rep strength), not bike/run intervals
