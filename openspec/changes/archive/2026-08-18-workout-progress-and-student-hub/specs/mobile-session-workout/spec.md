## ADDED Requirements

### Requirement: Coach confirms performed sets before marking complete
When a session has an attached plan, the mobile session page SHALL let the coach review and adjust prefilled set values before confirming «Проведена», then submit complete with those logs. The coach MAY confirm as prescribed (no adjustments). Sessions without a plan SHALL complete without a log editor.

#### Scenario: Confirm prescribed weights
- **WHEN** a coach confirms complete without changing prefilled sets
- **THEN** the app completes the session (logs omitted or equal to prescription) and shows `completed`

#### Scenario: Adjust weight then complete
- **WHEN** a coach increases a set weight on the confirm step and confirms
- **THEN** the complete request includes the adjusted logs
