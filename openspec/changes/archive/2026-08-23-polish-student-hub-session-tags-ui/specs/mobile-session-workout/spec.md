## ADDED Requirements

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

## MODIFIED Requirements

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
