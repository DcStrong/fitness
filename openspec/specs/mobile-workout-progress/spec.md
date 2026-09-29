# mobile-workout-progress Specification

## Purpose
Flutter progress numbers and a simple line chart for a student's completed set logs, with the plan goal selecting weight vs volume.

## Requirements

### Requirement: Progress is shown as numbers and a simple line chart
The mobile app SHALL show per-exercise progress as first value, current value, and delta, plus a line chart. For `hypertrophy` the primary series is working weight; for `fat_loss` it is volume; for `general` it is weight when present otherwise volume. Empty history MUST show a concise Russian empty state. Chart styling MUST use Fitness Yoda tokens, not a dark third-party theme.

#### Scenario: Hypertrophy exercise with two points
- **WHEN** the selected exercise is from a hypertrophy plan and two completed logs exist
- **THEN** the UI shows start weight, current weight, delta, and a line chart of weight

#### Scenario: Fat-loss exercise uses volume
- **WHEN** the selected exercise is from a fat_loss plan with logs
- **THEN** the primary numbers and chart use volume

#### Scenario: No logs yet
- **WHEN** the student has no completed logs for the selected exercise
- **THEN** the app explains that progress appears after a completed session with weights
