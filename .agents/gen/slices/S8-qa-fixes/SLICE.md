---
slice: S8
phase: n/a (QA playtest fixes — the independent reviewer's 2 HIGH / 6 MED / copy bundle)
lane: code
status: prepared (queued as dispatch_coder.md item 14; READY)
gate_baseline: "753/0 (S7 close, verified twice by the developer session 2026-09-24; D11 may ride parallel — its rows are cross-lane, attribute never fix)"
---

# S8 — QA playtest fixes (the independent review's findings)

## Goal
The independent QA playtest's two HIGHs and six MEDs are cured at their seams,
the copy/naming bundle is corrected, and the warning ledger shrinks — every
fix measured, none regressing the 753-row gate.

## In scope
- **H1** launch-ammo seeding (briefing / flight slots / HUD / store packs agree)
- **H2** ship-status W-cell payload vs FITTING (per-cell families, no dup, no
  armour in W rows — L148's warning class)
- **M4** resolved-figure denominators in the status footer and Repairs
- **M1** deferred fragment shape state (zero engine errors per ram)
- **M2/M3** exchange display-name path + honored confirm quote (05 §9)
- **O1/O2 (owner, conditional on Q0's disposition):** the FITTING drag /
  weapon-group findings — ARMORY-drag reproduced headlessly; the UX call
  (port / point / unify) is the owner's, a genuine break is this wave's
- **O3 (owner):** the player→NPC ram reduction — measured before/after, one
  proposed factor, owner tick, reversal 1.0
- Copy/naming: catalogue spelling everywhere (`Cannon MkI`), range copy in `u`,
  `1 CONVERSION` singular (proposed)
- Warning ledger: L163 ×5, `module_catalog` intdiv ×3, `projectile` shadows ×3
- Two new suites `tests/test_s8_launch_ammo.gd`, `tests/test_s8_qa_fixes.gd`

## Out of scope
- **Everything in `dispatch_designer.md` items 9–13** (M5 close-X, M6 arming
  countdown, station dead zones, HUD top-left/minimap, player-hull visibility,
  mining-beam visibility, auction thumbnails, and **O6 the station scene**) —
  the designer lane owns `ui/` taste work and those rows are queued there with
  owner gates
- **O4/O5 (flight feel: torque/slow-down, strafe/inertia) — coder item 15**,
  owner-gated (owner-locked 18 §13 + ruling 23 + the open §13 column ticks);
  this wave's workers do not touch flight numbers
- The Refinery's hide-behaviour (owner tick — `test_p1_refinery.gd:192` pins it)
- `REFINERY ALL` wording (docs-pinned: 04 §5 + STATION_HUB §12.3)
- The QA tooling appendix's live-profile disclosure (owner note: restore if wanted)
- Any new gameplay system, any `docs/` write beyond K0's disposition pass and
  R1's §9/§10 notes, `project.godot`, `18_engine_spec.md`

## Acceptance criteria
- [ ] AC1 — H1: one launch on QA's own fit shape → briefing total = Σ flight
      slots = store figure after the leg; a stocked family fires (probe: real
      launch, `_seed_ammo` vs `PlayerState.ammo` vs packs, projectiles appear)
- [ ] AC2 — H2: status pane and FITTING agree cell-for-cell (family per cell,
      battery grouping never fabricates a second weapon, armour cells only in
      armour rows) on at least three fits incl. a hole-y one
- [ ] AC3 — M4: no pane shows current > max; both denominators equal
      `ShipFit.resolve` (plated hull reads 1250/1250-class rows, never base)
- [ ] AC4 — M1: ram → cleave logs **0** engine errors; the fragment's shape is
      active on the next physics step (probe: deferred + collide)
- [ ] AC5 — M2: confirm strip + `SOLD` line print `CHROMIUM ORE`-class names;
      no raw id in any sale copy
- [ ] AC6 — M3: preview → market re-roll → press credits exactly the shown
      `YOU GET` (probe mutates demand between preview and sell)
- [ ] AC7 — copy: `Cannon MkI` spelling through catalogue resolver everywhere;
      target range in `u`; `1 CONVERSION`; no pinned literal moved
- [ ] AC8 — warnings: the three named ledgers drop by 5/3/3 rows; zero behaviour
      change (renames + `intdiv` only)
- [ ] AC9 — gate `753 + the two new suites, 0 failed`, twice on scratch stores;
      live store untouched; `verify --baseline s8_start` clean; Q0's
      dispositions recorded in §21 before Q1
- [ ] AC10 — O1/O2: the ARMORY drag reproduces headlessly and commits racks
      through `set_battery_groups` (or Q0's measured break is fixed); the
      FITTING-side UX call is dispositioned to the owner, never guessed
- [ ] AC11 — O3: a representative player→NPC ram measured before and after the
      proposed factor (both numbers in the report), the factor in §21's
      disposition table, owner tick recorded, reversal = factor 1.0

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S8-Q0 | `vajb-orbit/tests/` (reproduce + attribute; report only — orchestrator applies dispositions to §21) | `S8_BRIEF.md` |
| S8-Q1 | `vajb-orbit/game/game.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/ui/hud/ship_status_screen.gd,vajb-orbit/ui/hud/hud.gd,vajb-orbit/ui/station/repairs_panel.gd,vajb-orbit/game/weapons.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/impact.gd,vajb-orbit/tests/` | `S8_BRIEF.md` |
| S8-Q2 | `vajb-orbit/game/asteroid.gd,vajb-orbit/game/asteroid_field.gd,vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/game/exchange.gd,vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/game/projectile.gd,vajb-orbit/tests/` | `S8_BRIEF.md` |
| S8-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S8_BRIEF.md` |
| S8-F1 | union of Q1–Q2 sets + `docs/CONTRACTS.md` | `S8_BRIEF.md` |

Q0 names the exact files for any finding whose site differs from the table
(the target panel's `m` format line in particular); the orchestrator grows the
set before dispatch if a file is missing (the S5 J2/J3 precedent).

## References
- `docs/CONTRACTS.md` §21 (this wave's pin), §17/§15/§16 (the base pins the
  findings regress against), §9 (the gate)
- `docs/gameplay/05_exchange.md` §9 (M2/M3), `04_refinery.md` §5 +
  `docs/design/STATION_HUB.md` §12.3 (`REFINERY ALL` is pinned — read-only),
  `09_ship_slots_modules.md` §5 (resolved stats for M4)
- The QA review itself: `.agents/gen/slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md`
  (read it end to end — it is the wave's input; its LOW/composition sections
  are dispositioned in §21)

## Carries forward
- L150–L167 ride the fixer if cheap (L163 by name is already folded into AC8);
  next free LOW id **L168**, next free ticket **T-94**
- QA-derived owner ticks (hide-behaviour, `REFINE ALL` preference, quote policy)
  are listed in the brief §Owner ticks
