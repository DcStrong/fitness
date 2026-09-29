## ADDED Requirements

### Requirement: Alternate-time picker shows monthly occupancy calendar
When a trainer chooses «Другое время» / alternate resolution for a pending booking request, the date/time selection UI SHALL present a month grid of the trainer's calendar occupancy (same event types as calendar «Месяц»: trainings, free slots, pending requests), allow selecting a day to inspect that day's occupancy, then confirm a local time. The flow MUST NOT rely on a bare date-only picker without occupancy context. Data MUST come from existing calendar/schedule sources without a new backend endpoint.

#### Scenario: Trainer opens alternate date picker
- **WHEN** a trainer starts choosing an alternate date and time for a pending request
- **THEN** the app shows a monthly occupancy calendar rather than only a plain calendar date picker without busy markers

#### Scenario: Trainer inspects a day's occupancy
- **WHEN** the trainer selects a day on the month grid
- **THEN** the app shows that day's occupied intervals so the trainer can pick a free time knowingly

#### Scenario: Trainer confirms alternate local datetime
- **WHEN** the trainer selects a day, chooses a local time, and confirms
- **THEN** the alternate flow receives that local DateTime for submission through the existing alternate API
