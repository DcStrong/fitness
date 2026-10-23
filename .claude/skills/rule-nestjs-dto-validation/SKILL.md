---
name: rule-nestjs-dto-validation
description: DTO naming, validators, response constructors
---
<!-- pipil-sync: из .cursor/rules/nestjs-dto-validation.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# DTO и Validation

Эталоны: `platform/examples/dto/`

- Request: `implements Api.SomeRoute.RequestBody`, snake_case поля.
- Nested: `@ValidateNested()` + `@Type(() => NestedDto)` — `request-nested.ts`.
- Response: constructor от `*Returns` — `response-constructor.ts`.

Глобальный `ValidationPipe` → 422 RFC 7807. Свой pipe в контроллере не создавать.

OpenAPI workflow: `openapi-contracts.mdc`. Response skill: `response-dto-contract-mapper`.
