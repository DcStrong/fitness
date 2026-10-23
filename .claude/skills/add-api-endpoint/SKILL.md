---
name: add-api-endpoint
description: Add HTTP endpoint — OpenAPI, DTO, mapper, controller, service, tests. Use when adding a new API route in a NestJS service.
---
<!-- pipil-sync: из .cursor/skills/add-api-endpoint/SKILL.md. Правьте источник — копию обновит «Синхронизировать правила». -->

# Add API Endpoint

## Workflow

1. OpenAPI → regenerate contracts (`openapi-contracts.mdc`).
2. Request DTO — `examples/dto/request-nested.ts`.
3. Mapper (commands) — `examples/mapper/snake-to-camel.ts`.
4. Service `routeXxx` — `examples/service/route-method.ts`.
5. Response DTO — `examples/dto/response-constructor.ts`.
6. Controller — `examples/controller/command-handler.ts` or `list-handler.ts`.
7. Tests — skills `write-unit-test`, `write-e2e-test`.

## Rules

`nestjs-controllers.mdc`, `controller-api-flow.mdc`, `nestjs-dto-validation.mdc`

## Live code

После реализации — обновить `project/docs/live-references.md` в целевом репо.
