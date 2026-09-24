---
slice: D6
phase: n/a (graphics lane, parallel with coder item 11)
lane: design
status: draft
gate_baseline: "524/0 at prep; S5 closes first and moves it — the brief records S5's close as this wave's working baseline"
---

# D6 — Cockpit instruments (cluster + ship status screen)

## Goal
In flight, the bottom-left of the HUD carries a framed cockpit instrument cluster —
a sprite speed gauge, a sprite compass, and five seven-segment readout rows (SPD,
HULL, SHLD, FUEL %, ENRG %) — plus a toggleable ship status screen showing the
current ship layout and fitted modules. The game can show the pilot every number
the sim already computes, in painted instrument form, without a single new sim feed.

## In scope
- 18 painted sprite masters (UI_CHROME_ASSETS_SPEC §11): `ui_cockpit_frame`,
  `ui_gauge_face`, `ui_gauge_needle`, `ui_compass_rose`, `ui_compass_lubber`,
  `ui_readout_glass`, `ui_seg_0..9`, `ui_seg_pct`, `ui_seg_blank` (+ panel provenance)
- The instrument cluster (UI_SPEC §3.7) inside the existing bottom-left HUD column
- The ship status screen (UI_SPEC §3.8), `ship_status`-toggled, HUD-internal modal
- Two new test suites; nothing else moves (the §3.6 contract survives byte-identical)

## Out of scope
- **Any `game/` or `autoload/` change** — the cluster derives everything from feeds
  HUD already receives (`set_speedometer`, `set_pool`, the hull/shield handlers,
  `set_hull_slots`). Zero new sim plumbing is the wave's core constraint.
- Per-module damage modelling (no sim model exists; staged, owner tick 5)
- NMS-style holographic teal palette (STYLE_BIBLE one-accent law wins; owner tick 1)
- Cardinal letters on the compass rose (staged — no baked text law)
- `docs/CONTRACTS.md` edits by workers (§18 is landed docs-first by the developer
  session; §9/§10 measured notes ride the orchestrator at close-out)

## Acceptance criteria
- [ ] AC1 — the cluster renders at bottom-left with gauge + compass + five readout
      rows; `readouts()` returns the exact clamped ints for a probed state
- [ ] AC2 — every §3.6 test row stays green UNMODIFIED (120×120 gauge, SEGMENTS 10,
      SWEEP 1.5π, OVERDRIVE 0.9, filled/overdrive segment maps, `needle_colour`)
- [ ] AC3 — digits follow UI_SPEC §3.7 semantics exactly (spd = prograde length,
      hull/shield = points, fuel/energy = %, hdg = 0..359) incl. the danger rules
- [ ] AC4 — the status screen toggles behind `InputMap.has_action(&"ship_status")`,
      lists the resolved fit + slot grid + power arithmetic, swaps the damaged side
      render per the repairs-panel rule, and writes nothing to the profile
- [ ] AC5 — digit QC: lit-ink containment ≥ 95 % inside `ui_seg_blank`'s ghost boxes
      and ink-share ordering `blank < 1 … 8` (UI_CHROME §11)

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D6-M0 | `staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/` | `D6_BRIEF.md` |
| D6-M1 | `vajb-orbit/ui/hud/,vajb-orbit/tests/` | `D6_BRIEF.md` |
| D6-M2 | `vajb-orbit/ui/hud/,vajb-orbit/tests/` | `D6_BRIEF.md` |
| D6-R1 | `vajb-orbit/tests/,vajb-orbit/tools/` | `D6_BRIEF.md` |
| D6-F1 | union of M0–M2 sets | `D6_BRIEF.md` |

## References
- `docs/design/UI_SPEC.md` §3.7/§3.8 (the wave's pins) + §3.1/§3.1b/§3.6 (the rules
  the cluster reuses verbatim) + §1 (colour tokens)
- `docs/design/UI_CHROME_ASSETS_SPEC.md` §11 (asset list, per-run prompts, digit QC)
- `docs/design/ASSET_NAMING_SPEC.md` §11 (the `ui_seg_*` family ruling)
- `docs/CONTRACTS.md` §18 (seams) + §7 (the frozen HUD API this wave is additive to)
- `docs/design/STYLE_BIBLE.md` §2.4/§7.3 (panel look) — palette law beats the NMS mood

## Carries forward
- The bottom-left placement question HUD itself reported (`hud.gd`'s dial comment) —
  resolved here as bottom-left (owner's word), owner tick 2
- S5's `ShipFit.HARDPOINTS` (09 §11) — consumed read-only behind a `.has()` guard
