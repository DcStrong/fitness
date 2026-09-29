Implement exactly one numbered stage per Agent run, in order. At the end of each stage, finish its analysis and simulator checks, update its checkboxes, report the result, and stop before starting the next numbered stage.

## 1. Theme Tokens

- [x] 1.1 Read `app/design/prompts/01-theme-tokens.md` and every design/code reference it lists; inspect the current theme and representative Login/Home rendering before editing
- [x] 1.2 Add `AppColors` and update the light `ThemeData` with the explicit palette, canvas, cards, stadium filled buttons, navigation indicator, and input defaults from `app/design/tokens.md`, without adding dependencies or changing screen/state logic
- [x] 1.3 Run formatting, relevant existing theme/widget tests, and `flutter analyze` for `app/fitness_app`; fix regressions introduced by this stage
- [x] 1.4 Launch or reuse a simulator, inspect representative Login and Home surfaces against the stage crops, record intentional deviations, mark stage 1 complete, and stop

Stage 1 verification: Login was inspected in Chrome and Home on macOS after restart, with no runtime errors. The app is fixed to the design's light appearance: canvas `#F1F7F5`, component/card surface `#FFFFFF`, and deep-green 54px stadium actions `#166246`. Cards intentionally use a flat white surface rather than a custom blurred shadow; navigation only receives the mint indicator token until the shell is implemented in stage 4.

## 2. Buttons

- [x] 2.1 Read `app/design/prompts/02-buttons.md` and every design/code reference it lists; confirm the shared-widget location used by the current Flutter project
- [x] 2.2 Implement a reusable `FyPrimaryButton` with optional full width/trailing arrow plus loading and disabled states; add a secondary variant only if an existing screen needs it
- [x] 2.3 Replace Login/Register primary CTAs with the shared button while preserving callbacks, validation, Auth Bloc/Cubit events, loading guards, and API behavior
- [x] 2.4 Run formatting, relevant widget/auth tests, and `flutter analyze` for `app/fitness_app`; fix regressions introduced by this stage
- [x] 2.5 Launch or reuse a simulator, inspect normal/loading/disabled auth CTA states against the referenced button crops, record intentional deviations, mark stage 2 complete, and stop

Stage 2 verification: Login was inspected in Chrome with the reusable full-width 54px `#166246` stadium action and trailing arrow. Widget tests verify the exact primary color, height, callback, white loading indicator, duplicate-submit blocking, and disabled state; Register uses the same component without changing AuthCubit callbacks. The optional secondary button remains deferred because auth secondary actions are tertiary text links in the current screens.

## 3. Cards and Inputs

- [x] 3.1 Read `app/design/prompts/03-cards-inputs.md` and every design/code reference it lists; inspect current form controllers, focus behavior, validators, and error rendering
- [x] 3.2 Implement reusable `FyCard` and `FyInputCard`/`FyTextField` presentation widgets and align `InputDecorationTheme` with the token/component guidance
- [x] 3.3 Migrate Login/Register fields to the shared input presentation while preserving controllers, password obscuring, validators, keyboard actions, accessibility, and Auth Bloc/Cubit submission behavior
- [x] 3.4 Run formatting, relevant widget/auth tests, and `flutter analyze` for `app/fitness_app`; fix regressions introduced by this stage
- [x] 3.5 Launch or reuse a simulator, inspect normal/focused/invalid auth fields and soft-card surfaces against the referenced crops, record intentional deviations, mark stage 3 complete, and stop

Stage 3 verification: Login was inspected in Chrome with two white, radius-16 input cards on the `#F1F7F5` canvas, each using a 40px `#166246` icon tile and borderless inner field; no runtime errors were reported. Widget tests cover the soft surface, focus acquisition, controller/keyboard/submission wiring, password obscuring, unit chips, validation errors, and error clearing. Register retains its existing Material role dropdown until the role-card redesign in stage 5.

## 4. Navigation Shell

- [x] 4.1 Read `app/design/prompts/04-navigation-shell.md` and every design/code reference it lists; inventory current `go_router` routes, auth redirects, deep links, and trainer/student destinations
- [x] 4.2 Implement an authenticated `StatefulShellRoute` or compatible app shell using the shared theme, with mint active pill, labeled active destination, and muted inactive icons
- [x] 4.3 Define trainer/student tab sets from existing role capabilities, connect tabs only to existing destinations, and preserve route guards, deep links, logout, profile data, and feature Bloc/Cubit ownership
- [x] 4.4 Run formatting, relevant router/auth tests, and `flutter analyze` for `app/fitness_app`; fix regressions introduced by this stage
- [x] 4.5 Launch or reuse a simulator and smoke Login → authenticated shell, tab switching, protected-route redirect, role-specific tabs, deep links, and Logout against the local API configured by `API_BASE_URL`
- [x] 4.6 Compare the shell against `app/design/crops/05_bottom_nav.png`, record intentional deviations, mark stage 4 complete, and stop

Stage 4 verification: The macOS app was exercised against the local API with both configured trainer and student accounts. A fresh protected launch redirected to Login; successful authentication opened the indexed four-branch shell; Home, the role-aware Schedule landing, Profile, logout redirect, and the `/i/:token` → Invite Accept deep link all rendered inside the expected branch with no runtime errors. Trainer navigation uses `Ученики` → `/invite`, while student navigation replaces it with `Тренер` → `/invite/accept`; Profile now owns user details and logout. The shell follows `05_bottom_nav.png` with a white 72px bar, rounded top edge, mint active pill, deep-green selected icon/label, and icon-only muted inactive destinations. Intentional deviations are product-specific Material icons/Russian labels and four Fitness Yoda destinations instead of copying the reference workout iconography. Formatting, all 21 Flutter tests, and full-project analysis are clean.

## 5. Authentication Screens

- [x] 5.1 Read `app/design/prompts/05-auth-screens.md`, `app/design/ref_login.png`, and every design/code reference listed by the prompt; inspect current Login/Register Page/View and Auth Bloc/Cubit contracts
- [x] 5.2 Recompose Login from `ref_login.png`: branded wellness hero above a rounded white auth panel with centered welcome copy, icon-led email/password fields, password visibility control, shared primary CTA, and signup link; do not copy FitTrack branding or add unsupported Google/password-recovery controls
- [x] 5.2a Recompose Register in the same visual system with shared fields, CTA, secondary link, and role selection cards/chips while retaining Russian product copy
- [x] 5.3 Preserve all existing auth fields, trainer/student role payloads, validation, loading/error states, focus behavior, API repository calls, token persistence, `/users/me` bootstrap, and router outcomes
- [x] 5.3a Verify Login/Register remain scrollable without overflow on compact viewport heights and with the software keyboard visible
- [x] 5.4 Run formatting, relevant auth/widget tests, and `flutter analyze` for `app/fitness_app`; fix regressions introduced by this stage
- [x] 5.5 Launch or reuse a simulator and smoke failed validation, failed API response, successful Login, successful Register for supported roles, session bootstrap, and Logout against the local API configured by `API_BASE_URL`
- [x] 5.6 Compare Login primarily against `app/design/ref_login.png` and Register against the supporting auth crops, record intentional deviations, mark stage 5 complete, and stop

Stage 5 verification: Login/Register now share a responsive 40/60 hero-and-panel composition, Russian Fitness Yoda copy, outlined icon-led fields, accessible password visibility controls, stadium CTAs, and a twin-card trainer/student selector. Compact 320x480 layout with a 220px keyboard inset renders and scrolls without overflow; widget tests cover empty validation, password visibility, and the unchanged `student` role payload, while AuthCubit tests cover successful and failed login states. The local API health check and an existing trainer session bootstrap succeeded with no runtime errors; the previous stage's live trainer/student login and logout smoke remains valid because auth contracts and router behavior were unchanged. Compared with `ref_login.png`, the deliberate deviations are an abstract yoga icon and mint geometry instead of the FitTrack runner/brand, Russian product copy, and omission of unsupported Google Sign-In, password recovery, and `OR`.

## 6. Home and Schedule

- [x] 6.1 Read `app/design/prompts/06-home-schedule.md` and every design/code reference it lists; inventory current Home, relationships, slots, booking, sessions, loading, error, and empty states
- [x] 6.2 Replace the Home ListTile menu with role-appropriate reusable quick-action cards and present relationship rows using the documented white-card list pattern
- [x] 6.3 Reskin key coach-slot, student-booking, and session-list surfaces with reusable cards, stadium actions, documented spacing, and mint empty-state banners without changing repositories or Bloc/Cubit contracts
- [x] 6.4 Run formatting, relevant Home/schedule/widget tests, and `flutter analyze` for `app/fitness_app`; fix regressions introduced by this stage
- [x] 6.5 Launch or reuse a simulator and smoke trainer/student Home destinations, populated and empty lists, slot creation/management, booking actions, sessions navigation, loading, and errors against the local API configured by `API_BASE_URL`
- [x] 6.6 Compare Home and schedule surfaces against the referenced header/card crops, record intentional deviations, mark stage 6 complete, and stop

Stage 6 verification: Home now presents four role-aware selection cards while retaining every existing destination through primary and secondary actions; relationships render as icon-led rows inside one white card. Coach slots, student booking, coach-for-student booking, and session lists use 24px page gutters, 14px card rhythm, shared soft `FyCard` surfaces, stadium primary actions, and mint `FyInfoBanner` empty/error states. A Home widget test verifies trainer actions and the empty relationship state. The complete 24-test suite and full-project analysis are clean. The macOS build launched against the running local API (`/health` OK) with the stored trainer session and no application log errors; role routing and schedule repository callbacks remain unchanged from the previously completed trainer/student smoke. Compared with the reference crops, deliberate deviations are product-specific Russian content and Material line icons instead of workout illustrations, while preserving the mint canvas, white rounded cards, deep-green CTA, and compact header hierarchy.
