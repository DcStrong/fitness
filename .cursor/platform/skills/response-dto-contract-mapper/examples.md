# Response DTO examples

## Constructor pattern

```typescript
export class GetItemResponseDto implements Api.GetItem.ResponseBody {
  id!: number;
  created_at!: number;

  constructor(data: RouteGetItemReturns) {
    this.id = data.id;
    this.created_at = toUnix(data.createdAt);
  }
}
```

## Правило

Отдельный ResponseDto на endpoint; наследование только при полном совпадении контрактов.

## List

`return new GetItemListResponseDto(list)` — не spread полей DTO.
