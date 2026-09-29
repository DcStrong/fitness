## Context

Заявка ученика живёт по правилу `min(createdAt + 12h, slotStartsAt − 2h)`. Если этот момент уже не позже `createdAt`, `create` кидает `ConflictException('Booking request decision window has already closed')`. Список «Свободные слоты» на `StudentBookScreen` берёт `GET` linked-coach slots с `from = now` и репозиторий режет по `ends_at > from`, поэтому слот 15:00–16:00 в 15:05 и слот 16:00–17:00 в 15:05 оба видны, а создать заявку нельзя. Flutter мапит `decision window` в общее «время истекло».

Константа cutoff уже есть: `BOOKING_REQUEST_SLOT_CUTOFF_HOURS = 2`.

## Goals / Non-Goals

**Goals:**

- Ученик видит в списке только слоты, на которые `POST /booking-requests` ещё может пройти по окну решения.
- Понятный русский текст: правило «за 2 часа», а не «время истекло» для закрытого окна создания.
- Один источник cutoff на бэкенде; тренерский `findForCoach` не менять.

**Non-Goals:**

- Менять 12h/2h политику или схему БД.
- Клиентский «второй фильтр» как единственную защиту (без API).
- Timezone-конвертацию instants (слоты уже UTC).

## Decisions

1. **Нижняя граница списка = `now + 2h`, сравнение по `starts_at`.**  
   Хелпер `earliestRequestableSlotStart(now)` рядом с `calculateBookingRequestExpiry`. `listOpenForLinkedCoach` задаёт `from = max(query.from ?? cutoff, cutoff)`. `findRequestableForCoach` для `from` использует `slot.starts_at > :from`, не `ends_at`.  
   Альтернатива: фильтровать после `getMany` — хуже по объёму и оставляет семантику overlap у requestable-листа.

2. **`findForCoach` без изменений.** Тренерский календарь по-прежнему показывает идущие `open` слоты. Requestable — отдельный метод.

3. **Копирайт на клиенте.**  
   - Подзаголовок экрана: кратко про 2 часа.  
   - Пустой список: «Нет слотов, на которые ещё можно подать заявку. Запись закрывается за 2 часа до начала.»  
   - Маппинг `decision window has already closed` и `slot is not requestable` → «Записаться можно не позже чем за 2 часа до начала тренировки».  
   Сообщения тренера про прошедший deadline ответа (`deadline has passed`) не переписывать этим текстом.

4. **Тесты.** Unit на хелпер/expiry уже есть — добавить кейс `startsAt == now + 2h` (reject) и `startsAt > now + 2h` (ok). Flutter: обновить repository test для closed-window create. Спеку `schedules-api` синхронизировать: не «future/current», а «decision window still open».

## Risks / Trade-offs

- [Пустой список днём, хотя слоты «сегодня вечером» ещё `open`] → это корректное поведение cutoff; empty copy объясняет правило.
- [Клиент со старым API кэшем] → create по-прежнему 409; новый маппинг честно говорит про 2 часа.
- [query.from в прошлом] → всё равно применяем cutoff, чтобы не отдавать не-requestable слоты.

## Migration Plan

Нет миграций. Выкат: API + Flutter вместе предпочтительно; API-only уже чинит кнопку «Отправить заявку». Откат: revert.

## Open Questions

_(нет)_
