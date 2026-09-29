## Context

Day timeline lives in `calendar_day_timeline.dart`. Today every displayed hour is a fixed `_hourHeight = 72`. Card height is `durationMinutes/60 * 72`, floored by `_minCardHeight = 68`. Offset is `index * 72 + minute/60 * 72`.

For a booking **12:10–13:10** on hours `[…, 12, 13, 14, …]`:
- top ≈ `index(12)*72 + 10/60*72`;
- height ≈ 68–72;
- bottom crosses the `13:00` dashed line into the visual band of the next hour row.

Working-hours ∪ out-of-band hour selection (from `polish-schedule-calendar-ux`) stays as-is. This change only affects **vertical scale and placement math** inside those hours.

## Goals / Non-Goals

**Goals:**
- Keep clock-monotonic placement (start time maps to vertical position within the hour band).
- Expand hour-row height so a readable card for a ~60‑minute session that starts mid-hour does not visually “steal” the next hour’s band.
- Keep empty working hours visible at a stable baseline when they have no events.
- Optional phase 2: `HH:30` labels only on hours that have an event with a half-hour boundary.

**Non-Goals:**
- Changing which hours appear (working + out-of-band).
- Week/month layouts, API, availability generation.
- Continuous minute grid or 15‑minute ticks in v1.
- Per-hour arbitrary deformation that makes empty hours look different from occupied ones without a clear rule (prefer one day-wide scale first).

## Decisions

### D1 — Day-wide `pxPerMinute` (phase 1)

**Choice:** Compute one scale for the selected day:

```text
basePxPerMinute = _hourHeight / 60          // 72/60 = 1.2
needed = max over events of (_minCardHeight / max(durationMinutes, 1))
pxPerMinute = max(basePxPerMinute, needed)
hourHeight = 60 * pxPerMinute
```

Then:
- `offset(time) = sum(hourHeights before time.hour) + time.minute * pxPerMinute`
- `cardHeight = durationMinutes * pxPerMinute` (still respect `_minCardHeight` only if duration is short; with the formula above, ≥60‑min cards already meet the floor)

**Why over per-hour local stretch:**
- Uniform scale keeps dashed hour lines equally spaced and easier to reason about in tests.
- Fixes both “min card taller than clock duration” and “mid-hour start crosses next label” in one place.
- Simpler than computing independent heights per hour when an event spans 12→13.

**Alternative considered:** Stretch only hours that an event intersects, each to `max(base, required slice)`. Rejected for v1 as more complex (labels at uneven gaps, harder stacking) — keep as fallback if day becomes too tall after smoke.

**Alternative considered:** Keep fixed 72 and clip/stack cards inside the start hour. Rejected — breaks clock meaning (12:10–13:10 would not look like one hour).

### D2 — Placement and stacking

Reuse existing overlap stacking (`previous.top + previous.height + 6`), but feed it offsets/heights from the new scale. Empty-hour `InkWell` rows and left labels use the same `hourHeight` (or per-index height if we later switch to D1 fallback).

### D3 — Half-hour labels (phase 2, optional)

If any event on that hour has `start.minute == 30` or `end.minute == 30` (or start/end minute in `{30}`), render a secondary muted `HH:30` inside that hour’s label column, below `HH:00`. Do not add `:30` for empty hours. Skip if phase 1 smoke shows label crowding — mark task optional.

### D4 — Test surface

Extend `@visibleForTesting` helpers: expose hour heights and/or tops for `12:10–13:10` vs `12:00–13:00`. Assert:
- for 12:10 start, top is strictly below the 12:00 row top by `10 * pxPerMinute`;
- card bottom for a 60‑min mid-hour event does not require a larger height than the scaled span covering start→end;
- with only hour-aligned events of ≥60 min, `pxPerMinute == base` (no unnecessary zoom).

## Risks / Trade-offs

- **[Risk] Tall day when many short events force a high `pxPerMinute`** → Mitigation: scale from max over events of `minCard/duration`; short 15‑min events inflate scale. Cap `pxPerMinute` (e.g. max 2× base) or exclude events shorter than 30 min from the scale driver; document in implementation.
- **[Risk] Overlap stacking still pushes cards below clock end** → Mitigation: same as today; clock alignment is best-effort for overlaps; tests cover non-overlap mid-hour case first.
- **[Risk] Phase 2 labels clutter narrow phones** → Mitigation: optional; smaller muted style; only when `:30` present.

## Migration Plan

1. Implement scale + placement in `calendar_day_timeline.dart`.
2. Update unit tests; run focused Flutter tests.
3. Manual smoke: 12:10–13:10, 12:00–13:00, late 23:00 out-of-band, empty working hours.
4. Optionally add `:30` labels.
5. No data migration; rollback = revert widget file.

## Open Questions

- After smoke: if day height feels excessive with many short bookings, switch to “scale only hours touched by non-`:00` events” (fallback in D1).
- Confirm whether phase 2 `:30` is wanted in the same apply pass or a follow-up.
