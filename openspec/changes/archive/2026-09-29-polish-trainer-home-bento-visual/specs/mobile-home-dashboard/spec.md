## ADDED Requirements

### Requirement: Trainer Home header shows a date chip
The trainer Home header SHALL show a compact date chip for the current local calendar day, using a Russian label that identifies today (for example «Сегодня» plus the date). The chip MUST use existing theme tokens and MUST NOT require a new API call.

#### Scenario: Trainer opens Home
- **WHEN** an authenticated trainer opens Home
- **THEN** the header includes a date chip for the current local day

### Requirement: Trainer today list is a timeline with counterpart avatars
The trainer daily schedule on Home SHALL present session rows as a vertical timeline. Each row MUST show a circular counterpart avatar: a network image when an image URL is already present on the loaded session model, otherwise initials derived from the counterpart display name. The row MUST still show time and the training identity already available on the session.

#### Scenario: Session has no image URL
- **WHEN** a trainer views a today session whose counterpart has a name and no image URL
- **THEN** the timeline row shows initials from that name

#### Scenario: Today has no sessions
- **WHEN** the current-day request succeeds with an empty list
- **THEN** the schedule area shows the existing concise empty state

## MODIFIED Requirements

### Requirement: Home preserves the Fitness Yoda visual language
The Home dashboard SHALL use the existing Fitness Yoda theme tokens and reusable soft-card patterns. Trainer stat cards and bento tiles MUST use a white or canvas soft surface with mint as an accent, not a solid mint fill across the card. Layout references such as `mock-home-c-asymmetric-bento.png` define information hierarchy only, not pixel-perfect dimensions.

#### Scenario: Dashboard is rendered on a standard device
- **WHEN** populated trainer Home content is displayed
- **THEN** stat cards and bento tiles use soft light surfaces and mint accents rather than a solid mint card fill

#### Scenario: Dashboard is rendered on a narrow device
- **WHEN** the available width is phone-sized
- **THEN** student feature cards use two columns, trainer bento tiles reflow without horizontal overflow, and all content remains vertically scrollable

### Requirement: Trainer Home exposes compact stat chips for daily scan
The trainer Home dashboard SHALL show a row of stat cards near the top of the scroll content. Each card MUST show an icon, a short Russian label, and a numeric value. The row MUST include today's session count and, when pending request data loaded successfully, the pending booking request count with navigation to the trainer inbox when the count is greater than zero. A third card MUST show the loaded week's booked session count labeled «На неделе», unless a free-slot count is already present in loaded Home state without a new backend request, in which case that card MUST be labeled «Свободно» and show that count.

#### Scenario: Trainer has pending requests
- **WHEN** pending count loaded successfully and is greater than zero
- **THEN** a «Заявки» card shows an icon, the label, and the count, and navigates to the inbox on activation

#### Scenario: Pending count unavailable
- **WHEN** the pending-count request fails
- **THEN** Home does not show a misleading zero «Заявки» card

#### Scenario: Free slots are not in loaded state
- **WHEN** Home has a week session count and no free-slot count in loaded state
- **THEN** the third card is labeled «На неделе» and shows the booked week count

### Requirement: Trainer shortcuts use an asymmetric bento layout
The trainer «Всё необходимое» section SHALL use an asymmetric bento grid instead of a single-column stack of equal feature cards. The layout MUST include: a tall primary tile for «Расписание», stacked tiles for «Ученики» and «Планирование», and a full-width tile for «Регулярные тренировки». The «Расписание» tile MUST include a seven-day mini chart of booked session counts for the already loaded week. The «Расписание» and «Регулярные тренировки» tiles MUST show a «Перейти» action that routes to the same destination as the tile. Finance access, when permitted, MUST remain available without breaking the bento rhythm. All tiles MUST remain fully tappable and route to the same protected destinations as before. Tiles MUST use a light soft surface.

#### Scenario: Trainer with finance permission
- **WHEN** a trainer with `finance:read_own` views Home
- **THEN** finance remains reachable and the bento layout still presents «Расписание», «Ученики», «Планирование», and «Регулярные тренировки»

#### Scenario: Trainer activates a bento tile
- **WHEN** the trainer taps the «Ученики» tile
- **THEN** the router opens `/session-packages` as today

#### Scenario: Schedule tile shows the week chart
- **WHEN** the loaded week has booked sessions on some days
- **THEN** the «Расписание» tile shows a seven-day chart derived from those counts and a «Перейти» action to the schedule destination
