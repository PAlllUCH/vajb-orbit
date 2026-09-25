---
slice: S17
phase: P2
lane: code
status: active
gate_baseline: "866/0"
---

# S17 — Jump gates to sector edges

## Goal
Every jump gate stands at the sector's border on its link's bearing (the
mouth of that link's corridor) instead of on a 900 u ring around the station —
same gates, spawn placement only (owner go 2026-09-25, `11_galactic_map.md` §6).

## In scope
- `vajb-orbit/game/sector.gd` — `_add_gate`'s placement + the retired
  `GATE_RING_RADIUS` (owner-locked doc: `docs/gameplay/11_galactic_map.md` §6,
  applied by the planner on the owner's go)
- `vajb-orbit/tests/test_s17_gate_edges.gd` — new suite, AC1–AC6

## Out of scope
- `gate.gd` (ring art, `TRIGGER_RADIUS`, fee law — untouched; forbidden file)
- `sector_registry.gd` (corridor bands, spine — untouched; forbidden file)
- Corridor hold-course behaviour, POI density/beacon count, minimap kinds
- Any fee, cap or tuning number (owner-locked §13 stays)

## Acceptance criteria
- [ ] AC1 — placement: for every registry sector populated with a fixed seed,
      each gate stands on its link's bearing ray from the arena centre at the
      border inset `FIELD_EDGE_MARGIN` (800 u); today's cardinal bearings put
      every gate at ±4200 u on its link's axis (re-derived independently in
      the suite, not by calling the field's helper).
- [ ] AC2 — clearance: no gate's 200 u `TRIGGER_RADIUS` circle enters any
      corridor band's interior (tangent to the inner edge allowed:
      `CORRIDOR_DEPTH` 600 + 200 = the 800 inset), and every gate sits inside
      the arena.
- [ ] AC3 — beacons follow: one beacon per gate at the byte-identical formula
      (`gate.position + gate.position.normalized() * BEACON_GATE_OFFSET`),
      inside the arena; for an edge gate the beacon lands inside its link's
      corridor band.
- [ ] AC4 — same gates: per sector, gate count == `gate_links` size, names and
      destinations unchanged across all seven registry rows; the fee law's own
      suites stay green (no existing row moves).
- [ ] AC5 — minimap: the wiring blip row stays green — one `friendly` blip per
      gate at its new position (`sector.gd:282-284` is position-agnostic).
- [ ] AC6 — summary: `GATE_RING_RADIUS` is gone from `sector.gd`;
      `FIELD_EDGE_MARGIN` 800 / `BEACON_GATE_OFFSET` 300 unchanged;
      `gate.gd` and `sector_registry.gd` byte-identical.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S17-B1 | `vajb-orbit/game/sector.gd, vajb-orbit/tests/, .agents/gen/slices/S17-gate-edges/S17-B1_report.md` | `S17_BRIEF.md` |
| S17-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S17-gate-edges/S17-R1_review.md` | `S17_BRIEF.md` |
| S17-F1 | `vajb-orbit/game/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S17-gate-edges/` | `S17_BRIEF.md` |

## References
- `docs/gameplay/11_galactic_map.md` §2.1/§2.2/§5/§6 (§6 is this wave's pin)
- `docs/CONTRACTS.md` §19 (S6 travel + RPG P3 — the reviewer updates it)
- `docs/gameplay/18_engine_spec.md` §7/§8/§13 (read-only; no edit needed)

## Carries forward
- None. No LOW row is absorbed; `GATE_RING_RADIUS`'s retirement is recorded in
  11 §6's reversal, not the backlog.
