---
name: rule-nestjs-services
description: Services — routeXxx, DI, transactions, logging
---
<!-- pipil-sync: из .cursor/rules/nestjs-services.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# NestJS Services

Эталон: `platform/examples/service/route-method.ts`

- Публичные сценарии: `routeXxx(params, authority?)`.
- Input: `RouteXxxParams` (camelCase), output: `RouteXxxReturns`.
- `@Transactional()` на multi-step writes.
- Side effects: `commandBus.execute(...)` после commit при необходимости.
- Логи: structured logger (`.addDetail().flushError()`).

Ошибки — HTTP exceptions из `#exception` или project layer. Policy — `project/rules/permissions.mdc` если есть.

Типы и PATCH/null: `service-types-and-null.mdc`.
