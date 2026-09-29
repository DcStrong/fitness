---
name: project-orientation
description: >-
  Orient on Fitness Yoda monorepo and OpenSpec before coding. Use when starting a
  task, asking where something lives, touching API/Flutter/web domains, or
  consulting an archived OpenSpec change.
---

# Project orientation

## Steps

1. Read [`.cursor/project/docs/map.md`](../../docs/map.md) — domain → code → spec → archive index.
2. Open **one** baseline spec: `openspec/specs/<capability>/spec.md` from the map row for the task.
3. If behavior was introduced/changed earlier — open **one** archived `proposal.md` or `design.md` by folder name from the archive table (path: `openspec/changes/archive/<folder>/`).
4. Only then open code under the map paths (`backend/api/src/<domain>/`, `app/fitness_app/lib/features/<feature>/`, `web_app/`).

## Do not

- Glob/list entire `openspec/changes/archive/`
- Wide-grep the monorepo before reading the map
- Dump full specs or entity schemas into always-on context

## Related skills

- Nest workflows: `add-api-endpoint`, `add-feature-module`, …
- Flutter: `flutter-bloc-feature`, `flutter-api-client`, `flutter-auth-shell`
- OpenSpec commands: `/opsx-explore`, `/opsx-propose`, `/opsx-apply`, `/opsx-archive`
