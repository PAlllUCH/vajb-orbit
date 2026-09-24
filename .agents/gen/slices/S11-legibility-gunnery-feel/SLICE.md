---
slice: S11
lane: code
title: Station inspector, credits in flight, near-infinite gunnery, one-vector inertia
status: open
opened: 2026-09-24
gate_baseline: "775/0 (S10 close, 396b8f3)"
pin: docs/CONTRACTS.md §23 (docs-first, v0.22)
---

# S11 — station legibility, space gunnery, one-vector inertia (coder item 18)

## Goal

Answer four owner asks measured in one pass: the station always shows the hovered item's
full description; the flight HUD shows current credits; every kinetic weapon and every beam
reaches across the sector instead of fizzling in the dark; and a released hull decays as one
velocity vector instead of two independent ones.

## In scope

- **B1** — the station inspector: an `inspect_requested` signal on all eight panes, emitted
  by the six item panes on hover and on selection, rendered by a new shell block above the
  status strip; `StationCatalog.describe` + `group_int`.
- **B2** — the 35 `MODULES` descriptions (data, verbatim from §23.2) **and** the flight
  HUD's `CreditsBlock`.
- **B3** — `NEAR_INFINITE_RANGE := 30000.0` on laser/plasma/cannon/railgun.
- **B4** — one-vector inertia: `_lateral_damp()` → `_linear_damp()`, `LATERAL_DAMP_MULT`
  retired in place, `COAST_TIME_MULT` 2.5, new `ANGULAR_DAMP_MULT` 0.5, plus the 5°-direction
  acceptance suite.
- **R1** — the mandatory review, the §9/§10 rows and the LOW rows.

## Out of scope

- **T3** (`STRAFE_RATE_MULT`) — held: §22's row contradicts itself. A notice is with the
  owner; nothing implements it.
- Any typography, palette or layout change to the panes' **existing** text — that is the
  graphics lane's (D12-A0's audit → the D11/D12 designer session). S11 touches only the new
  inspector block's own nodes.
- `docs/gameplay/18_engine_spec.md` (owner-locked), `game/sector.gd`,
  `game/station_scene.gd`, `assets/env/**`, `staging/**`, `asset-library/**` — D11's sets.
- `slices/D11-station-scene/**`, `dispatch_designer.md`, `staging/mockup/**`.

## Acceptance criteria

- [ ] AC1 (B1) — hovering any item row in `armory`, `shipyard`, `exchange`, `auction`,
      `refinery` or `fitting` puts that row's catalogue description in the shell's inspector
      block; unhover clears it; a press leaves the existing status strip's wording intact.
- [ ] AC2 (B1) — `describe` is base-id resolved, returns `""` for a row with no description
      (never invented text), and appends a `mod_*` instance's affix perks.
- [ ] AC3 (B2) — all 35 `MODULES` rows carry their §23.2 description verbatim; no other key
      moved.
- [ ] AC4 (B2) — the flight HUD shows the profile's credits, updates on
      `profile_changed(&"credits")`, and never writes the profile.
- [ ] AC5 (B3) — the four families' `range` is `30000.0`; rocket `900.0` and mine `0.0`
      unmoved; `range_of` reads it.
- [ ] AC6 (B4) — released from a commanded forward+strafe at cruise, the velocity direction
      holds within 5° of its release bearing while speed falls to 0.1× of release; the
      three flight suites' numeric rows are re-derived to T1/T2, never weakened.
- [ ] AC7 — the gate is `775 + the new rows`, twice, on fresh scratch stores; live store
      untouched; `verify --baseline s11_start` clean; D11's rows (if it lands mid-wave) are
      attributed, never fixed.
- [ ] AC8 (R1) — every pinned literal in §23 re-measured on the shipped tree; the 35
      descriptions spot-checked against §23.2; §9/§10 sequenced after any D11 row.
- [ ] AC9 — owner ticks: see `S11_BRIEF.md` §Owner ticks.

## Worker file sets

| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S11-B1 | `ui/station/{armory,shipyard,exchange,auction,refinery,fitting,repairs,launch}_panel.gd`, `ui/screens/station.gd`, `ui/screens/station.tscn`, `game/station_catalog.gd`, `tests/test_s11_inspector.gd` | `S11_BRIEF.md` |
| S11-B2 | `game/module_catalog.gd`, `ui/hud/hud.gd`, `ui/hud/hud.tscn`, `tests/test_s11_inspector.gd` (credits half only) | `S11_BRIEF.md` |
| S11-B3 | `game/weapons.gd`, `tests/` (range rows only) | `S11_BRIEF.md` |
| S11-B4 | `game/ship_fit.gd`, `game/player_ship.gd`, `tests/test_s2_6_flight.gd`, `tests/test_flight_feel_g1.gd`, `tests/test_engine_c3_flight_decay.gd`, `tests/test_s11_flight_stop.gd` | `S11_BRIEF.md` |
| S11-R1 | `tests/`, `docs/CONTRACTS.md`, `_state/LOW_BACKLOG.md`, the slice folder | `S11_R1_BRIEF.md` (written at review-prep) |

Run order (file-collision law): **B1 ∥ B3 ∥ B4** (disjoint sets) → **B2** (needs B1's
`group_int`, and owns the two files B1 does not) → **R1**. A fixer only if R1 leaves HIGH or
MED.

## References

- `docs/CONTRACTS.md` **§23** (this wave's pin) + **§22** (the flight levers) + **§14**
  (amended) + **§9** (the gate) + **§7** (the HUD's frozen API)
- `docs/design/UI_SPEC.md` (tokens, the station's block language), `docs/design/STATION_HUB.md`
  **§5.1/§5.11**, `docs/design/STYLE_BIBLE.md` (the palette the contrast rows come from)
- Owner's ask verbatim: §23's header. Readability half: `slices/D12-ui-readability/`
- `AGENTS.md` — the test gate, the worker-discipline rules, the parallel-lane rules

## Carries forward

- LOW ids and the changelog row are read from the files at close-out (never reserved in
  advance — D11 and the D12 lane are live).
