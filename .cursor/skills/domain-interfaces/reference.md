# Domain Interfaces — reference

## Layout (Fitness API)

Модули лежат плоско: `backend/api/src/<domain>/`, не `src/module/<name>/`.

```text
src/
  schedules/
    interface/
      schedule-slot.types.ts
      create-slot.params.ts
      list-slots.params.ts
      schedule-slot.returns.ts
    schedules.service.ts
    schedules.controller.ts
    dto/
  sessions/
    interface/
      session.types.ts
      ...
  auth/
    interface/
      auth-user-payload.interface.ts
      auth-tokens.interface.ts
      ...
  database/
    entity/          # только классы Entity + импорт типов из домена
    repository/
```

`database/` — инфраструктура. Доменные union/models принадлежат feature-домену (`schedules`, `sessions`, …).

## Пример: вынести типы из entity

**Было** (`schedule-slot.entity.ts`):

```ts
export type ScheduleSlotStatus = 'open' | 'booked' | 'blocked';
export type ScheduleSlotMode = 'online' | 'offline';
```

**Стало** (`schedules/interface/schedule-slot.types.ts`):

```ts
export type ScheduleSlotStatus = 'open' | 'booked' | 'blocked';
export type ScheduleSlotMode = 'online' | 'offline';
```

**Entity:**

```ts
import type {
  ScheduleSlotMode,
  ScheduleSlotStatus,
} from '../../schedules/interface/schedule-slot.types';
```

Цикла нет: `interface/` не импортирует entity/repository.

## Пример: Params / Returns сервиса

```ts
// schedules/interface/create-slot.params.ts
import type { ScheduleSlotMode } from './schedule-slot.types';

export interface CreateSlotParams {
  coachId: string;
  startsAt: string;
  endsAt: string;
  mode?: ScheduleSlotMode;
}

// schedules/interface/schedule-slot.returns.ts
import type { ScheduleSlotMode, ScheduleSlotStatus } from './schedule-slot.types';

export interface ScheduleSlotReturns {
  id: string;
  coachId: string;
  startsAt: string;
  endsAt: string;
  mode: ScheduleSlotMode;
  status: ScheduleSlotStatus;
  capacity: number;
  seriesId: string | null;
  gymId: string | null;
  createdAt: string;
}
```

```ts
async createSlot(params: CreateSlotParams): Promise<ScheduleSlotReturns> { ... }
```

Вместо инлайна `input: { startsAt: string; ... }` и нетипизированного `toPublic`.

## Constants → type

Если есть `as const` объект/массив — type-alias в `interface/`:

```ts
// access-control/interface/permission-code.type.ts
import { PERMISSIONS } from '../constants';

export type PermissionCode = (typeof PERMISSIONS)[keyof typeof PERMISSIONS];
```

Либо оставить type рядом с const только если файл тонкий и это единственный экспорт типа; предпочтение — `interface/`.

## Shared literals

`SessionMode` и `ScheduleSlotMode` оба `'online' | 'offline'`:

1. Один владелец (например `schedules` или тонкий shared в домене-источнике).
2. Либо общий primitive в модуле-владельце календаря, если появится.
3. Не копипастить два независимых union без причины — при расхождении сломается согласованность.

## DTO vs interface

| Слой | Роль |
|------|------|
| `dto/` | HTTP validation / OpenAPI class |
| `interface/` | внутренние Params/Returns/models |
| mapper | DTO → Params, Returns → ResponseDto |

Не подменять interface классами DTO внутри сервиса.

## Импорты

Предпочтительно `import type { ... }` для type-only связей (entity → interface).
