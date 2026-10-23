## ADDED Requirements

### Requirement: Trainer chat list
The trainer «Чаты» tab SHALL list the trainer's conversations sorted by latest message, each row showing the student avatar and name, last message preview (prefixed «Вы:» for own messages), time, and an unread count badge when unread > 0. The list MUST support search by student name and refresh periodically while visible.

#### Scenario: New incoming message while list is open
- **WHEN** a student sends a message while the trainer's chat list is visible
- **THEN** within one polling interval the conversation moves to the top with an unread badge

### Requirement: Conversation thread
The thread screen SHALL show messages grouped by day with day dividers, own messages as filled primary bubbles on the right, the counterpart's as outlined bubbles on the left, and system messages as session cards with time tile and status chip. The composer MUST send optimistically and show a retry affordance on failure.

#### Scenario: Send fails offline
- **WHEN** the user sends a message without network
- **THEN** the bubble stays in the thread marked «Не отправлено» and tapping it retries with the same client id

#### Scenario: System card opens the session
- **WHEN** the user taps a system card that references a session
- **THEN** the app opens that session's screen

### Requirement: Student chat tab adapts to number of coaches
The student «Чат» tab SHALL open the thread directly when the student has exactly one coach, show the conversation list when there are several, and show an empty state explaining how a coach appears when there are none.

#### Scenario: Single coach
- **WHEN** a student with one linked coach opens the «Чат» tab
- **THEN** the thread with that coach is shown without a back button

### Requirement: Unread badge and entry points
The bottom navigation chat tab SHALL show the total unread count. The trainer's student card and the student's profile coach card SHALL offer «Написать», opening the pair's thread.

#### Scenario: Write from student card
- **WHEN** a trainer taps «Написать» on a student card
- **THEN** the app opens the thread with that student, creating the conversation if needed
