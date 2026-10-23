---
name: rule-openapi-contracts
description: OpenAPI contracts and codegen workflow
---
<!-- pipil-sync: из .cursor/rules/openapi-contracts.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# OpenAPI и контракты

1. Источник: `spec/openapi.yaml` (или аналог в project).
2. Генерация типов — скрипт из `project-overview.mdc` (напр. `generate-client-contracts`).
3. `src/contract/*` — **не редактировать вручную**.

DTO `implements ContractNamespace.Route.RequestBody`. Поля — snake_case как в API.

При изменении API: spec → regenerate → адаптировать DTO/mapper/service.
