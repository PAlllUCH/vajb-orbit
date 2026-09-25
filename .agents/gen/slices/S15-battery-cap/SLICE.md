---
slice: S15
phase: P4
lane: code
status: active
gate_baseline: "834/0"
---

# S15 — Battery hardcap 5x4, armory B1-B5

## Goal
A ship composes at most five batteries of at most four guns each, and the
armory shows exactly the B1-B5 racks the cockpit's five-lamp band names.

## In scope
- `GROUPS_MAX` 7 → 5 and a per-battery cap of 4 W cells (any W cell: guns and
  mining lasers alike) — 09 §12's dated amendment is the pin
- Profile clamp (≤ 5 groups × ≤ 4 cells; old saves clamp on load)
- ARMORY: five bays flowing 4+1, labels B1-B5 aligned 1:1 with the cockpit
  lamps, and the rack-plate fit corrected to the plate's own ink (playthrough
  finding F1)
- `weapon_6`/`weapon_7` become inert (no `project.godot` edit — that stays the
  owner's pass)

## Out of scope
- Hull W-cell counts (the 7-cell Obliterator composes as B1(4)+B2(3))
- The cockpit itself (its five-lamp band is already the truth), the FITTING-drag
  UX call (S8's O1/O2), the ARMORY dead-column/below-fold rework (D12-A0's
  remaining findings — separate wave), prices and ammo economics

## Acceptance criteria
- [ ] AC1 — `GROUPS_MAX == 5`; composing a 6th battery or a 5th cell in one
      refuses and writes nothing (the §13 transaction rule)
- [ ] AC2 — the 7-cell hull composes 4+3; launch and ammo read-back match; the
      hull's W-cell count is unchanged
- [ ] AC3 — profile clamp: a save carrying 6-7 groups loads clamped to 5×4,
      cell order preserved; the gate is byte-identical on such a store
- [ ] AC4 — the armory draws 5 bays (4+1), labels B1..B5; every bay's slots and
      drums sit on the rack plate's ink (ink rows 49..132, ~34.5 px slot pitch
      ±2) — F1's plate-fit defect is gone
- [ ] AC5 — armory rack i ↔ cockpit lamp i 1:1; the (i) key selection lights
      lamp i; `test_d7_cockpit`'s rows stay green untouched
- [ ] AC6 — gate grows only by `test_s15_*` rows + the listed moved rows, twice
      on scratch stores; `verify --baseline s15_start` clean

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S15-B1 | `vajb-orbit/game/,vajb-orbit/autoload/,vajb-orbit/ui/station/,vajb-orbit/tests/` | `S15_BRIEF.md` |
| S15-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S15_BRIEF.md` |
| S15-F1 | union of B1 + `docs/CONTRACTS.md` | `S15_BRIEF.md` |

## References
- `docs/gameplay/09_ship_slots_modules.md` §12 (this wave's pin) + §10/§11
  (the battery model as built)
- `docs/design/STATION_HUB.md` §5.11's 2026-09-25 amendment (the armory layout)
- `.agents/gen/session_2026-09-25_findings.md` §2 F1 (the plate-fit numbers)

## Carries forward
- LOW ids and gate counts read from the files at write time; the parallel S14
  lane's rows are attributed, never fixed
