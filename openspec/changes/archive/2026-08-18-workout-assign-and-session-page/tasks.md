## 1. Persistence

- [x] 1.1 Migration: `sessions.student_plan_id` nullable FK to `training_plans`, ON DELETE SET NULL; index
- [x] 1.2 Partial unique index on `training_plans (parent_template_id, assigned_student_id)` where `kind=student_copy`
- [x] 1.3 Extend session + plan domain interfaces with `studentPlanId` and copy fields

## 2. Assign API

- [x] 2.1 `POST /plans/:id/assign` `{ studentIds?, tagIds? }`: resolve linked union, 400 if empty, 403 if not owner/unlinked
- [x] 2.2 Deep copy template → `student_copy` (title, goal, notes, tags, exercises/sets); skip if copy exists (return existing)
- [x] 2.3 PATCH student_copy by owner only; never writes through to parent; student PATCH 403
- [x] 2.4 `GET /plans?kind=assigned` trainer+studentId or student self; default trainer list still templates only
- [x] 2.5 Unit tests: assign one, tag bulk, idempotent, unlinked 403, copy edit isolation

## 3. Session attach API

- [x] 3.1 GET session includes `studentPlanId` and optional plan summary (title, goal, tags, exercises)
- [x] 3.2 PATCH session `{ studentPlanId }` coach-only; validate copy belongs to session student+coach; null detaches
- [x] 3.3 Unit + e2e: attach, wrong student 400, student cannot attach, detach

## 4. Flutter session page

- [x] 4.1 Route `/sessions/:id` + repository get/patch session plan; Cubit
- [x] 4.2 Page: time, counterpart, mode, goal/tags, compact exercises, package remaining chip, lifecycle actions, history
- [x] 4.3 «Выбрать тренировку»: list assigned copies for student, or templates (assign then attach)
- [x] 4.4 Student view read-only except cancel; Russian copy

## 5. Calendar, library, shell

- [x] 5.1 Calendar booked/terminal session tap pushes `/sessions/:id` instead of `SessionActionsSheet`
- [x] 5.2 Sessions list / Home row use the same page
- [x] 5.3 Template detail «Назначить» sheet: students + own tags; success snackbar
- [x] 5.4 Trainer bottom nav: «Тренировки» (`Icons.fitness_center`) → `/plans`; highlight `/plans` and `/tags`; student tabs unchanged
- [x] 5.5 Plans library app bar opens `/tags`; editor empty-tags CTA navigates to tag management
- [x] 5.6 Widget/Cubit tests: tap navigates to page; assign from detail; attach copy; trainer shell includes plans tab

## 6. Gym catalog seed

- [x] 6.1 Rewrite catalog seed: gym strength only (жим лёжа, присед, подтягивания, тяги, жимы…); no running/cycling/elliptical
- [x] 6.2 Idempotent: rename retired catalog rows (e.g. «Велосипед») instead of hard-delete if referenced; rebuild catalog templates

## 7. Verification

- [x] 7.1 Focused Nest tests for assign + session patch
- [x] 7.2 Focused Flutter tests for calendar navigation, session page actions, and trainer destinations
- [x] 7.3 Manual smoke: assign via tag to two students, customize one copy, attach to a booked slot, complete from page; open `/plans` from bottom bar; manage a tag; catalog has no bike/run
