# Unit test — good / bad

## ❌ Тавтология мока

```typescript
expect(repo.save).toHaveBeenCalledWith(input);
```

## ✅ Наблюдаемый результат

```typescript
await expect(service.routeGet({ id: 1 }, authority))
  .rejects.toBeInstanceOf(NoAccessHttpException);
```

## ❌ Smoke-only

```typescript
expect(service).toBeDefined();
```
