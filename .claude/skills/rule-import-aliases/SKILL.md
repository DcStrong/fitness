---
name: rule-import-aliases
description: Path aliases — использовать вместо относительных импортов
---
<!-- pipil-sync: из .cursor/rules/import-aliases.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Import Aliases

## Канон

Импорты через алиасы из `tsconfig` paths (`#common/*`, `#module/*`, `#config/*`, `#contract/*`, `#db/*`, `#exception/*`).

Список алиасов — в `project/rules/project-overview.mdc` целевого репо.

## ✅ / ❌

```typescript
// ✅ import { UserPolicyService } from '#module/permission/policy/spw';
// ✅ import { Nullable } from '#common/type';
// ❌ import { UserPolicyService } from '../../../permission/policy/spw';
// ❌ import { parseTime } from '../../common/util';
```

Относительные импорты внутри модуля (`../dto/`, `../mappers/`) — допустимы, но предпочитай алиасы для `#common`, `#config`, `#module` других фич.

## Не путать

Это **path aliases** (импорты), не TypeScript `as` для приведения типов — см. `typescript-typing.mdc`.
