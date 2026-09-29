---
name: refactor-service-to-platform
description: Migrate existing NestJS service to platform rules — discovery, gap analysis, incremental refactor. Use when onboarding a repo to .cursor/platform.
---

# Refactor Service to Platform

## Фаза 1 — Discovery

1. Прочитать `platform/rules/` и `platform/examples/`.
2. Сканировать репо: modules, auth, API flow, repository, tests.
3. Записать `project/docs/live-references.md` — **единственное** место с путями `src/...`.
4. Таблица gap: паттерн | есть? | canonical file | legacy?.

## Фаза 2 — Приоритет рефактора

1. Module boundaries (CQRS, cross-imports).
2. Repository pure persistence.
3. Controller flow (mapper, ResponseDto, guards).
4. OpenAPI/DTO alignment.
5. Tests (unit + e2e contract).

## Фаза 3 — Project overlay

- `project/rules/project-overview.mdc` — команды, алиасы, стек.
- `project/rules/permissions.mdc` — domain policy (если есть).
- `./.cursor/activate.sh`

## Ограничения

- Не менять публичный API без явного запроса.
- Не копировать SPW-имена в чужой репо — использовать `examples/` как канон.
- Legacy помечать в live-references, не в platform rules.

## Reference

[reference.md](reference.md)
