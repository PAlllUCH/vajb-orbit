---
slice: S17
worker: S17-B1
model: "deepseek-flash"
status: informational
gate: "866/0 → 877/0"
---

# S17-B1 report

## Result
Gates now spawn at the sector border on their link's bearing: `_add_gate` places at
`centre + bearing * _edge_reach(bearing)`, a new private helper deriving the reach from
the arena half-extent minus `FIELD_EDGE_MARGIN`. `GATE_RING_RADIUS` (900 u) and its
comment are deleted. New suite `tests/test_s17_gate_edges.gd` proves AC1–AC6; gate
`[SUMMARY] passed=866 failed=0` → `passed=877 failed=0` (the 11 new rows only).

## Deviations from SLICE.md
- **AC6 byte-identity implemented as pinned MD5.** The suite pins
  `gate.gd`/`sector_registry.gd` hashes (`test_s17_gate_edges.gd` `GATE_MD5`/`REGISTRY_MD5`).
  Reversal: drop the two asserts if a later wave legitimately edits either file.
- **The suite prints one `[S17]` line per AC1/AC2/AC3** so the measured values are readable
  in the gate log. Informational only; no assert depends on the print.
- **`BEACON_GATE_OFFSET`'s comment still reads "outside the ring"** (`sector.gd:97`).
  Brief §2 rule 3 forbids touching it, so it is reported, not edited. Meaning is stale
  (the ring is retired), no code effect.
- **`--suite=` did not filter** on this host (the runner printed no `[RUN] suites=`); every
  measurement is from full gate runs.

## Pre-grep table (§3's candidate rows, route and verdict; none moved)
| Row (`file:line`) | Route | Verdict |
|---|---|---|
| `test_engine2_wiring.gd:211-221` blip count | counts via `gates()`; position-agnostic | unchanged |
| `test_s6_travel.gd:109-126` registry spine | row data only | unchanged |
| `test_s6_travel.gd:169-220` fee/distance/name | bare `_gate` fixtures, no field placement | unchanged |
| `test_s6_travel.gd:301` `gate.position = Vector2(900,0)` | manually placed fixture | unchanged |
| `test_s6_travel.gd:398` ship at `gate.global_position` | reads a position, asserts no distance | unchanged |
| `test_s6_heat.gd:485` ship at gate | same pattern | unchanged |
| `test_s2_6_gate_hygiene.gd` | the runner's own hygiene, no jump gates | unchanged |
| `test_s2_6_flight.gd`/`test_s2_6_blur.gd`/`probe_s2_6_flight.gd` "gate" | W-gate input naming and the runner | unchanged |
| `probe_f4_weapon_fx.gd` "ring" | FX rings, no jump gates | unchanged |

Extra, outside §3: `staging/mockup/station_mockup.py:284,369` still labels "GATE 900 u";
stale mockup text, no suite and no game code reads it (Follow-ups).

## Per-AC measured values (seeded registry sectors, seed 170925)
- **AC1** — 12 gates across the seven rows, every one on its link's bearing ray at
  `EDGE_INSET` 4200.0 u; cardinal spine measured
  `s1->2 (4200,0) s2->1 (-4200,0) s2->3 (4200,0) s3->2 (-4200,0) s3->4 (4200,0)
  s4->3 (-4200,0) s4->5 (4200,0) s5->4 (-4200,0) s5->6 (4200,0) s6->5 (-4200,0)
  s6->7 (4200,0) s7->6 (-4200,0)`. Expected re-derived in the suite from `HALF` minus
  `EDGE_MARGIN` over the component, never by calling `_edge_reach`.
- **AC2** — own-link tangency exactly 200.00 u for all 12 gates (600 + 200 = 800);
  min gate-to-any-band distance 200.00 u (nothing enters an interior). Every gate
  `|x| = 4200 < 5000`.
- **AC3** — beacon counts per sector (gates + corridors): `s1 1+1, s2 2+2, s3 2+2,
  s4 2+2, s5 2+2, s6 2+2, s7 1+1`; each gate exactly one beacon at the byte-identical
  formula `position + position.normalized() * 300` (east gate → (4500,0), west →
  (-4500,0)), inside the arena and inside the link's corridor band.
- **AC4** — per row `gates().size() == gate_links.size()`; names `Gate<dest>`; origins
  equal the sector; destination sets equal `gate_links` on all seven rows. No fee row
  moved (per-suite diff below).
- **AC5** — each gate has exactly one `friendly` blip at its new position; the wiring row
  `test_engine2_wiring.gd:211-221` stayed green.
- **AC6** — `sector.gd` source no longer contains `GATE_RING_RADIUS`; `FIELD_EDGE_MARGIN`
  800.0, `BEACON_GATE_OFFSET` 300.0, `CORRIDOR_DEPTH` 600.0 stand; `gate.gd`
  `c13574f6af658c1fcd4728c34901caf3`, `sector_registry.gd`
  `584d206c15c1ab7541e6bcebfb368101` (unchanged from before the edit).

## Evidence
- Baseline (fresh `XDG_DATA_HOME`, `--quit-after 1200`): `[SUMMARY] passed=866 failed=0`.
- After, run 1: `[SUMMARY] passed=877 failed=0`. After, run 2 (fresh store):
  `[SUMMARY] passed=877 failed=0`; `[FAIL]` count 0 in both.
- Per-suite count diff baseline → after: a single added line `11 test_s17_gate_edges`;
  no existing suite's count changed.
- `md5sum vajb-orbit/game/gate.gd vajb-orbit/game/sector_registry.gd` before and after the
  edit: identical (values above).
- Command:
  `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200`

## Files touched
- `vajb-orbit/game/sector.gd` — deleted `GATE_RING_RADIUS`+comment (`:95-99`); `_add_gate`
  placement line now `bearing * _edge_reach(bearing)` (`:584-585`); new `_edge_reach`
  helper (`:670`). `_gate_bearing`, the beacon block (`:608-612`), `_spawn_pois`,
  `gates()`, the minimap mapping and `populate` byte-identical.
- `vajb-orbit/tests/test_s17_gate_edges.gd` — new suite, 11 rows, AC1–AC6.
- `.agents/gen/slices/S17-gate-edges/S17-B1_report.md` — this file.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Stale "GATE 900 u" label in the station mockup | LOW | `staging/mockup/station_mockup.py:284,369` |
| `BEACON_GATE_OFFSET` comment says "outside the ring" | LOW | `vajb-orbit/game/sector.gd:97` |
