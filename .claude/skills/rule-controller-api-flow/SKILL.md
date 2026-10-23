---
name: rule-controller-api-flow
description: Controller → mapper → service → ResponseDto
---
<!-- pipil-sync: из .cursor/rules/controller-api-flow.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Controller API Flow

```
RequestDto → mapXxxDtoToParams → RouteXxxParams → service.routeXxx() → new XxxResponseDto(result)
```

Эталоны:
- `examples/controller/command-handler.ts`
- `examples/mapper/snake-to-camel.ts`
- `examples/dto/response-constructor.ts`

**GET list:** query DTO в сервис как есть (snake_case до repo), mapper не нужен — `list-handler.ts`.

Один mapper — один command-сценарий.
