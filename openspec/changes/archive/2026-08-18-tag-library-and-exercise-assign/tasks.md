## 1. Persistence and permissions

- [x] 1.1 Migration: `exercise_tags` (`exercise_id`, `tag_id`) unique pair, FKs CASCADE, indexes
- [x] 1.2 Migration: `student_exercises` (`coach_id`, `student_id`, `exercise_id`) unique triple, FKs, indexes
- [x] 1.3 Seed `exercises:read_visible` on student role; entities, repositories, domain interfaces
- [x] 1.4 Flutter: create-tag dialog owns `TextEditingController`; `/tags` back pops to library (not Home)

## 2. Tag hub and list filters

- [x] 2.1 `GET /tags/:id` hub for creator: users, own templates, tagged exercises
- [x] 2.2 `GET /plans?tagId=` own templates filter; `GET /exercises?tagId=` trainer exercise filter
- [x] 2.3 Unit tests: hub contents, foreign tag 403, empty sections

## 3. Exercise tags, visibility, assign

- [x] 3.1 Create/update own exercise accepts `tagIds`; `PUT /exercises/:id/tags` for catalog without mutating name/kind
- [x] 3.2 `GET /exercises/visible` (`exercises:read_visible`): linked coach ∩ shared tags ∪ explicit `student_exercises`
- [x] 3.3 `POST /exercises/assign` `{ exerciseIds, studentIds?, tagIds? }`: linked union, idempotent, 400 empty, 403 unlinked; unassign endpoint
- [x] 3.4 Unit tests: tag catalog, visible via tag, visible via assign without tag, unlinked 403

## 4. Batch plan assign

- [x] 4.1 `POST /plans/assign-batch` `{ studentId, planIds[] }`: transactional copies, empty/unlinked/foreign rejected
- [x] 4.2 Unit tests: two templates one student, unlinked rolls back

## 5. Flutter tag hub

- [x] 5.1 Route `/tags/:id`; repository hub fetch; Cubit
- [x] 5.2 Hub UI (Russian): students, workouts, exercises; tap opens existing detail
- [x] 5.3 Tags list opens hub; assign sheets filter students by own-tag chips

## 6. Flutter exercise library

- [x] 6.1 `/plans` third mode «Упражнения»: search, tag chips, catalog vs own distinguishable
- [x] 6.2 Tag exercises (including catalog); assign N exercises sheet (students ∪ tags)
- [x] 6.3 Student visible view: workouts and exercises as separate sections; read-only

## 7. Flutter multi-workout assign

- [x] 7.1 Multi-select on «Мои» → one student → `assign-batch`
- [x] 7.2 Cubit/widget tests: two templates assigned; exercise assign; hub lists tagged content

## 8. Verification

- [x] 8.1 Nest tests for hub, visible exercises, assign exercises, assign-batch
- [x] 8.2 Flutter tests for dialog dismiss (no crash path), hub, library exercise mode
- [x] 8.3 Manual smoke: tag «ноги» on student + workout + 5 exercises → student sees all; assign two templates to one student; Esc on create-tag; filter library by chip
