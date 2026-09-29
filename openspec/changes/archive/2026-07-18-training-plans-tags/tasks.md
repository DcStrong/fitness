## 1. Data & permissions

- [x] 1.1 Add Tag / UserTag / TrainingPlan / TrainingPlanTag entities + types under `tags/interface/` and `plans/interface/` (entities only `import type`)
- [x] 1.2 Migration: tables + unique `(creator_id, name)` on tags + indexes on junction tables
- [x] 1.3 Extend permission constants + seed (tags:* and plans:* per design)
- [x] 1.4 Run migration + seed on local DB

## 2. Backend tags API

- [x] 2.1 Tags module: create / list own / delete own
- [x] 2.2 Assign / unassign tag to linked student; list assignees; enforce link + ownership
- [x] 2.3 Wire permissions guards; update Postman for tags

## 3. Backend plans API

- [x] 3.1 Plans module: CRUD own plans (title, body) + set own tagIds on create/update
- [x] 3.2 `GET /plans/visible` (and get-by-id) for students with tag ∩ link rule; empty-tag plans not visible
- [x] 3.3 Wire permissions; update Postman for plans
- [x] 3.4 API smoke: create tag → assign student → create tagged plan → student sees / unlinked or no-tag hidden; foreign tag rejected

## 4. Mobile UI

- [x] 4.1 API client methods for tags + plans
- [x] 4.2 Trainer screens: tags list/create/assign; plans list/create/edit (RU)
- [x] 4.3 Student screens: visible plans list + detail
- [x] 4.4 go_router routes + home entry points; avoid ListTile+wide trailing pitfalls

## 5. Docs & verification

- [x] 5.1 Brief note in `docs/domain/tags.md` or entities if MVP decisions differ (visibility / body text)
- [x] 5.2 Manual smoke mobile trainer + student against local API
- [x] 5.3 Optional unit/service test for visibility intersection helper
