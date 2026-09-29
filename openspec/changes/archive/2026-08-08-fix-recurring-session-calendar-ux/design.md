# Design: fix-recurring-session-calendar-ux

## Decisions

1. **Create already syncs** — detail receives `RecurringSyncSummary` via route `extra`; banner «нажмите Синхронизировать» only when no summary and series is active.
2. **«Готово»** — primary exit; from post-create flow uses `go('/schedule')` when `from=calendar`, else `pop`.
3. **Horizon sync** — secondary button «Обновить горизонт» + info banner explaining series is already active.
4. **Cancel frees slots** — `lifecycle.cancel(..., releaseSlot: true)` sets `ScheduleSlot.status = open` inside the same transition transaction.
5. **Hard delete** — only `cancelled` series; cascades overrides via DB or explicit delete.
6. **List filter** — `GET /recurring-bookings?status=active|cancelled|all`, default `active`.
7. **No restore** in this change.
8. **Session manage** — bottom sheet from calendar; reuses existing session APIs. No reschedule API.
9. **Calendar map** — skip `cancelled` sessions so released open slots appear.

## Risks

- Manual cancel of a single session still leaves slot booked (unchanged MVP policy).
- Completed/no_show remain on calendar.
