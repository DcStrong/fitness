## Context

Phase 5 delivered session lifecycle + history. Phase 6 adds **TrainingPlan** content and **Tag** labeling so coaches can organize students/plans and students can see matching plans — per [docs/domain/tags.md](../../../docs/domain/tags.md) and [docs/domain/entities.md](../../../docs/domain/entities.md).

Delivery: **backend → Flutter**; web out of scope. Domain types live under `src/<domain>/interface/`.

Existing primitives to reuse: JWT + permissions, `coach_student_links`, Flutter feature folders + `go_router` + Russian UI.

## Goals / Non-Goals

**Goals:**
- Trainer-owned tags with uniqueness `(creatorId, name)`.
- Assign trainer tags to **linked** students; attach tags to own plans.
- Trainer CRUD for simple training plans (`title` + `body` text / line items as plain text MVP).
- Student visibility: plans of a linked coach where tag intersection (student tags ∩ plan tags) is non-empty.
- Permissions + thin Flutter screens.

**Non-Goals:**
- Exercise library, structured sets/reps schema, media.
- Tag hierarchy / global tags / cross-trainer tag merge.
- `session.planId`, home “today’s plan”, PlanAssignment entity (explicit assignment table deferred — visibility is tag-based).
- Soft-delete / versioning / web.

## Decisions

### 1. Modules
- Nest modules: `tags` + `plans` (separate folders, shared junction entities under `database/entity`).
- Rejected: single `content` mega-module (harder permissions and specs).

### 2. TrainingPlan content shape (MVP)
- Columns: `id`, `ownerCoachId`, `title`, `body` (text, markdown-or-plain; no rich editor required), `createdAt`, `updatedAt`.
- Rejected: JSON `items[]` with typed exercises — YAGNI until workout builder phase.
- UI: multiline «содержание» field.

### 3. Visibility rule (MVP)
Student `GET /plans/visible` (or `/plans?scope=visible`) returns plans where:
1. `ownerCoachId` is a linked coach of the student, AND
2. ∃ tag on both the plan and the student (`UserTag` ∩ `TrainingPlanTag`).

Plans with **zero tags** are **not** visible to students (trainer still sees own).  
Rejected: “all linked coach plans always visible” — breaks tag purpose from Miro.

### 4. Tag assign to people
- Only tag **creator** may assign their tag.
- Target user MUST be an active linked student of that coach (or self — optional; MVP: linked students only, not self-tagging required).
- UI label for assigned tag: `#Name` for own; `#Name#creatorEmail` when showing someone else’s assignment context (simple string on client).

### 5. API sketch
**Tags**
- `POST /tags` `{ name }`
- `GET /tags` (own created)
- `DELETE /tags/:id` (own; cascades junctions or blocks if in use — prefer cascade remove junctions)
- `POST /tags/:id/users` `{ userId }` — assign
- `DELETE /tags/:id/users/:userId` — unassign
- `GET /tags/:id/users` — list assignees (own tag)

**Plans**
- `POST /plans` `{ title, body, tagIds? }`
- `GET /plans` (own, trainer)
- `GET /plans/visible` (student)
- `GET /plans/:id` (owner or visible student)
- `PATCH /plans/:id` `{ title?, body?, tagIds? }`
- `DELETE /plans/:id`
- Tag set replace via `tagIds` on create/patch OR dedicated `PUT /plans/:id/tags` — prefer **replace list on PATCH** for fewer endpoints.

### 6. Permissions (seed)
| Code | trainer | student |
|------|---------|---------|
| `tags:create` | ✓ | |
| `tags:read_own` | ✓ | ✓ (see tags assigned to me + own if any) |
| `tags:delete_own` | ✓ | |
| `tags:assign` | ✓ | |
| `plans:create` | ✓ | |
| `plans:read_own` | ✓ | |
| `plans:read_visible` | | ✓ |
| `plans:update_own` | ✓ | |
| `plans:delete_own` | ✓ | |

Student `tags:read_own` = list tags currently assigned to them (for UI chips), not create.

### 7. Mobile
- Trainer: `/tags`, `/plans`, plan editor; pick tags + linked students.
- Student: `/plans` visible list + detail.
- Avoid ListTile + wide FilledButton trailing (known Flutter web pitfall).
- Repository via existing `ApiClient` / dio.

### 8. Domain interfaces
- Types/params/returns under `tags/interface/`, `plans/interface/`; entities `import type` only.

## Risks / Trade-offs

- [Empty-tag plans invisible to students] → Mitigation: document; trainer must attach ≥1 shared tag.
- [Delete tag orphans] → Mitigation: delete junctions in same transaction; plans remain.
- [Name collisions across coaches] → Accepted: uniqueness per creator only.
- [Student sees coach email in #Tag#Login] → Use email until displayName exists.
- [OR in visibility SQL] → Use EXISTS subqueries; index junction tables `(user_id, tag_id)`, `(plan_id, tag_id)`.

## Migration Plan

1. Migration: `tags`, `user_tags`, `training_plans`, `training_plan_tags` + uniques/indexes.
2. Seed permissions + role maps.
3. API → Postman → Flutter.
4. Rollback: drop tables (no production data assumed).

## Open Questions

None blocking — PlanAssignment deferred; body as text confirmed for MVP.
