---
name: rule-auth-and-authority
description: JWT middleware + guard + Authority (platform default)
---
<!-- pipil-sync: из .cursor/rules/auth-and-authority.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Auth и Authority

Схема: `platform/examples/auth/middleware-guard-flow.md`

1. Middleware — парсит JWT → `request.authority`.
2. `JwtAuthGuard` — на public controllers (class-level).
3. `@Authority()` — `AuthorityModel` в handler.

Internal/incoming controllers — без guard; зафиксировать в `project/`.

Эталон guard: `examples/controller/class-level-guard.ts`.
