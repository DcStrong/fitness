# mobile-session-workout Specification

## Purpose
Flutter session workout page (`/sessions/:id`) showing attached plan content and lifecycle actions, plus attaching an assigned copy to the session (Russian copy).

## Requirements

### Requirement: Session page shows workout content and lifecycle actions
The mobile app SHALL open `/sessions/:id` for a booked (and terminal) session with Russian copy showing time interval, counterpart, mode, goal and tags when a plan is attached, compact exercise rows, and package remaining when available. The coach SHALL get lifecycle actions complete / cancel / no-show (when permitted) and history on this page, with complete as the single primary CTA and the rest quiet or in ⋯ as specified by the one-primary-CTA requirement. The student SHALL see the same content read-only except cancel when permitted (quiet or overflow). If no plan is attached, the coach SHALL see «Выбрать тренировку» and «Упражнения из списка» as text or a single primary choose-workout action. If a plan is attached, the coach SHALL see «Сменить тренировку» and, when the session is booked, «Добавить упражнения» or «Изменить состав» as text links.

#### Scenario: Coach opens booked session
- **WHEN** a coach opens a booked session that has an assigned copy
- **THEN** the page shows time, student, goal, tags, compact exercises, and complete as the primary action with cancel/no-show available without matching that visual weight

#### Scenario: Session without plan
- **WHEN** a coach opens a booked session with no `studentPlanId`
- **THEN** the page offers «Выбрать тренировку», «Упражнения из списка», and still allows lifecycle actions

#### Scenario: Student opens session
- **WHEN** the student of the session opens the page
- **THEN** they see the workout content and cannot complete or mark no-show

### Requirement: Coach can attach an assigned workout to a session
The mobile app SHALL let the session coach pick an existing assigned copy for that student or a template that is assigned (creating a copy if needed) and attach it to the session.

#### Scenario: Attach existing copy
- **WHEN** the coach selects an assigned copy of the session's student
- **THEN** the session page shows that workout's exercises

#### Scenario: Attach from template
- **WHEN** the coach selects a template that has no copy yet for that student
- **THEN** the app assigns a copy and attaches it to the session

### Requirement: Coach can change or compose the session workout
The mobile app SHALL let the session coach change the attached program after it is selected, detach it from the session, and compose exercises from the library with set parameters on the attached `student_copy`. If no program is attached, «Упражнения из списка» SHALL create a student copy, attach it, and open the exercise editor.

#### Scenario: Change attached workout
- **WHEN** a coach has already attached a program
- **THEN** the page offers «Сменить тренировку» and can attach another copy or template

#### Scenario: Detach workout
- **WHEN** the coach removes the program from the session
- **THEN** the session has no attached plan

#### Scenario: Compose exercises without a template
- **WHEN** the coach chooses «Упражнения из списка» on a session without a plan
- **THEN** the app creates a student copy, attaches it, and opens the exercise editor

#### Scenario: Edit parameters of attached copy
- **WHEN** the coach chooses «Изменить состав» or «Добавить упражнения»
- **THEN** they can add exercises from the list and set sets, reps, and weight for this copy

### Requirement: Coach confirms performed sets before marking complete
When a session has an attached plan, the mobile session page SHALL let the coach review and adjust prefilled set values before confirming «Проведена», then submit complete with those logs. The coach MAY confirm as prescribed (no adjustments). Sessions without a plan SHALL complete without a log editor.

#### Scenario: Confirm prescribed weights
- **WHEN** a coach confirms complete without changing prefilled sets
- **THEN** the app completes the session (logs omitted or equal to prescription) and shows `completed`

#### Scenario: Adjust weight then complete
- **WHEN** a coach increases a set weight on the confirm step and confirms
- **THEN** the complete request includes the adjusted logs

### Requirement: Session page can show and attach multiple workouts
The mobile session page SHALL list attached workouts in order (title + compact exercises from the session snapshot). The coach SHALL be able to add another assigned copy or template (assign if needed), reorder is not required in v1, and remove one workout without detaching the others. Empty state copy remains «Выбрать тренировку» and MAY add a second workout after the first is attached. A coach edit of snapshot weights on this page MUST mark the session overridden so the series program will not overwrite it on the next apply.

#### Scenario: Two workouts on one session
- **WHEN** the coach attaches «Силовая» and then «Кор»
- **THEN** the page shows both sections and the student sees both read-only

#### Scenario: Remove one of two
- **WHEN** the coach removes «Кор» and leaves «Силовая»
- **THEN** the session still shows «Силовая»

#### Scenario: Override is sticky
- **WHEN** the coach changes bench to 82.5 kg on this session and a later program apply runs without force
- **THEN** that session still shows 82.5 kg

### Requirement: Session page uses one primary CTA and quiet composition links
On `/sessions/:id` for a booked session the coach can complete, the mobile app SHALL keep workout content (titles, compact exercise rows, loads) as the dominant scroll content and SHALL show exactly one primary call-to-action: «Проведена», implemented with the shared `FyButton` primary variant (or its thin wrapper). Composition and program-change actions («Изменить состав», «Сменить», «Выбрать тренировку», «Добавить тренировку», «Убрать эту тренировку», «Упражнения из списка») SHALL be text links or overflow items, not a stack of full-width secondary buttons competing with complete. Navigation such as «Программа на неделю» MUST be a text link or overflow item and MUST NOT use a button variant that masquerades as a CTA. No-show, cancel, and history SHALL be quiet text under the primary or behind an app-bar ⋯ menu. Meaning of `app/design/generated/mock-session-a-one-cta.png` SHALL be followed; extra mock controls MUST NOT be copied. Empty-plan state MAY use «Выбрать тренировку» as the single primary until a workout is attached.

#### Scenario: Coach opens booked session with a workout
- **WHEN** a coach opens a booked session that has attached workout content
- **THEN** exercise rows occupy the main area and the only filled primary button is «Проведена»

#### Scenario: Composition is a text link
- **WHEN** the coach can edit the attached copy
- **THEN** «Изменить состав» and «Сменить» appear as text links, not as equal-weight filled buttons beside «Проведена»

#### Scenario: Destructive and history are quiet
- **WHEN** the coach can mark no-show, cancel, or open history
- **THEN** those actions are not full-width outlined buttons in the same band as «Проведена»; they are quiet text or ⋯ items and still reach the existing confirm flows

#### Scenario: Program navigation is not a CTA
- **WHEN** the session belongs to a recurring series
- **THEN** opening the program is a text link or overflow action, not a secondary stadium button above the workout
