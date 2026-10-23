---
name: response-dto-contract-mapper
description: Response DTO implementing API contract with constructor mapping. Use when adding/updating response DTOs.
---
<!-- pipil-sync: из .cursor/skills/response-dto-contract-mapper/SKILL.md. Правьте источник — копию обновит «Синхронизировать правила». -->

# Response DTO Contract Mapper

1. `class XxxResponseDto implements Api.Route.ResponseBody`
2. Поля snake_case как в контракте.
3. `constructor(data: RouteXxxReturns)` — явный маппинг.
4. Вложенные блоки — `mapMeta()` / отдельные DTO.
5. Controller: `return new XxxResponseDto(serviceResult)`.

Эталон: `platform/examples/dto/response-constructor.ts`

## Examples

[examples.md](examples.md)
