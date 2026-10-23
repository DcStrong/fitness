---
name: rule-typescript-typing
description: Стратегия исправления ошибок TypeScript — типы сначала, as в крайнем случае
---
<!-- pipil-sync: из .cursor/rules/typescript-typing.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# TypeScript Typing

## Порядок при ошибке типизации

1. **Правильный тип** — interface/type, уточнение generic, guard, overload; без смены архитектуры и без патчей библиотек.
2. **Локальный адаптер** — тонкий helper/interface на границе (внешний SDK, ORM, JSON).
3. **Крайний случай** — `value as ConcreteType` с кратким комментарием *почему* безопасно.

## ✅ Предпочитать

```typescript
interface ExternalPayload { id: number; name: string; }
function isExternalPayload(v: unknown): v is ExternalPayload { ... }

const params: UpdateItemParams = { id, name: dto.name ?? null };
```

## ⚠️ Допустимо в крайнем случае

```typescript
// boundary cast — библиотека отдаёт unknown, контракт проверен выше
const row = raw as ItemRow;
```

## ❌ Избегать без причины

```typescript
as unknown as SomeType   // двойной cast — почти всегда можно interface/adapter
as any                   // запрещено
@ts-ignore               // только с обоснованием в комментарии
```

Не менять структуру модуля ради одного cast. Если cast размножается — вернуться к п.1–2.
