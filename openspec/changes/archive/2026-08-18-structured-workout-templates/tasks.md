## 1. Schema and domain types

- [x] 1.1 Add TypeORM entities `Exercise`, `PlanExercise`, `PlanSet` and extend `TrainingPlan` with `kind`, `goal`, `parentTemplateId`, `assignedStudentId` (nullable; unused writes in this change) under `backend/api/src/database/entity/`
- [x] 1.2 Add repositories (persist only); register entities in module / entities index
- [x] 1.3 Migration: tables, FKs, indexes, unique `(owner_coach_id, lower(name))` for exercises, CHECK/kind+goal values including reserved `student_copy`
- [x] 1.4 Domain interfaces under `src/exercises/interface/` and extend `src/plans/interface/` (`kind`, `goal`, nested exercises/sets, `notes`)
- [x] 1.5 Seed permissions `exercises:manage_own` and `exercises:read_own`; map trainer manage+read, student read

## 2. Exercises API

- [x] 2.1 Nest module `exercises` wired into AppModule (controller/service/DTOs)
- [x] 2.2 `GET /exercises` returns own + catalog with a source discriminator
- [x] 2.3 `POST /exercises` `{ name, kind }`; `PATCH`/`DELETE` own only; reject catalog mutation; 409 if exercise is referenced
- [x] 2.4 Unit tests: create, unique name per owner, catalog mutate rejected, referenced delete 409, ownership isolation

## 3. Plans API structured content

- [x] 3.1 Extend create/update DTOs: `goal`, `notes` (alias `body`), nested `exercises[]` with sets; reject writes to `parentTemplateId`/`assignedStudentId`/`kind=student_copy`
- [x] 3.2 Create template persists nested plan_exercises/plan_sets; PATCH replaces the list when `exercises` is sent
- [x] 3.3 Default own `GET /plans` returns only caller's `kind=template`; catalog scope lists `kind=catalog_seed` only
- [x] 3.4 Reject PATCH/DELETE of `kind=catalog_seed`; keep tag attach/visibility rules unchanged for templates
- [x] 3.5 `POST /plans/:id/clone` from catalog → new own template copying goal/notes/exercises/sets; catalog row unchanged
- [x] 3.6 GET plan response includes `kind`, `goal`, `notes`, `body` alias, nested exercises; legacy body-only plans remain readable
- [x] 3.7 Unit tests: nested create/update, catalog isolation, clone, non-owner 403, tags still work
- [x] 3.8 E2E: trainer creates structured plan with tags; student `GET /plans/visible` still matches on shared tags

## 4. Catalog seed

- [x] 4.1 Seed catalog exercises (Russian names, mixed kinds) with stable UUIDs
- [x] 4.2 Seed ~10 `catalog_seed` templates: верх/низ/фулбоди × hypertrophy/fat_loss plus two general; no gender forks
- [x] 4.3 Idempotent seed (migration or `seed.ts` upsert) so re-run does not duplicate

## 5. Flutter data layer

- [x] 5.1 Extend `TrainingPlanItem` with `kind`, `goal`, `notes`, nested exercises/sets; keep `body` fallback
- [x] 5.2 Add exercise models + `PlansRepository` methods: list exercises, create exercise, list templates vs catalog, clone, save nested plan
- [x] 5.3 Map API errors to Russian messages (empty title, catalog mutate, referenced exercise)
- [x] 5.4 Cubits for library (Мои/База, search, tag chips) and editor; Bloc only

## 6. Flutter trainer library UX

- [x] 6.1 Replace plans list with segmented «Мои | База», search, own-tag chips, compact cards (title, goal chip, ≤2 tags, exercise count)
- [x] 6.2 FAB on «Мои» only opens editor; «База» card/detail has «Добавить к себе» (clone)
- [x] 6.3 Plan detail shows goal, tags, compact `N×reps` rows (notes if no exercises)
- [x] 6.4 Single-screen editor: title*, goal pills, tags, notes, exercise list without per-set accordion; add via search/create; identical sets summarized as `3×12`
- [x] 6.5 Apply goal defaults when adding an exercise (hypertrophy 3×10/90s, fat_loss 3×15/45s, general 3×12/60s)
- [x] 6.6 Student visible list/detail shows compact exercises when present; keep `/plans?visible=1`

## 7. Docs and verification

- [x] 7.1 Update `docs/domain/entities.md` and `docs/domain/tags.md` (plan content is structured; body/notes remains)
- [x] 7.2 Focused Nest unit + e2e for exercises/plans
- [x] 7.3 Focused Flutter tests: library modes, clone, editor compact row, empty title
- [x] 7.4 Manual smoke: trainer creates tagged template, clones catalog, student still sees tagged visible plan
