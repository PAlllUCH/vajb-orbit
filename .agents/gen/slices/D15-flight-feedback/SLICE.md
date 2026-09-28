---
slice: D15
phase: P3
lane: design
status: draft
gate_baseline: "n/a (design only)"
---

# D15 — Flight feel & feedback design

## Goal
One owner-ticked feel sheet ends the "report, never guess" pile for flight and
feedback: seeker fuse, NPC brake/skid asymmetry, lateral release shape, muzzle
anchor, arc interval, ammo label, bolt aspect — each a ruled row with its
reversal. Plus the FX/AUDIO spec rows the feedback wave needs (mine cue, chip
sparks, anti-flam wiring note) and the composition of the new HUD feedback
(quadrant feed + hit marker language).

## In scope
- The feel tick sheet (T-feel-1..7 in `slices/S22-feel-and-juice/S22_BRIEF.md`
  §11 + S19's T1–T7 + CONTRACTS §22's T3 + L25/L39/L103/L182/L57) — analysed,
  proposed values with reversals, brought to the owner for ticking
- `docs/design/FX_SPEC.md` amendment block: §1.6 chip sparks (the 3-object
  master correction), §7.1 the low-hull arc interval row, L59/L64's unstated
  rates/sizes pinned as rows, L57's bolt/slug aspect disposition
- `docs/design/AUDIO_SPEC.md` amendment block: §8's missing deployable
  (`mine_drop`) row, §4.1's anti-flam wiring note (what the code will enforce)
- Feedback composition: the quadrant readout's HUD feed + the hit-marker
  language, sketched under UI_SPEC §3.10 A5.2 (containers/anchors, chrome as
  stylebox/sibling, marks inside their own child rect)
- Mockups where words are not enough (`staging/mockup/`)

## Out of scope
- Any code (the coder lane's S22 wave implements); `docs/gameplay/*` and
  `18_engine_spec.md` (owner-locked / developer-owned — this slice's rows reach
  them through the developer's tick pass); CONTRACTS §22/§23 (R1 lands values)
- New art (owner 2026-09-27): composition uses existing sprites/chrome

## Acceptance criteria
See `D15_BRIEF.md` §6 (A1–A4).

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D15-A1 | `docs/design/, staging/mockup/, .agents/gen/slices/D15-flight-feedback/` | `D15_BRIEF.md` |
| D15-R1 | `docs/design/, .agents/gen/slices/D15-flight-feedback/D15-R1_review.md` | `D15_BRIEF.md` |

## References
- `docs/gameplay/18_engine_spec.md` §3.1/§3.2/§3.4/§4.5 (read-only, owner-locked)
- `docs/design/FX_SPEC.md` §1.1/§1.6/§7.1/§7.3 · `AUDIO_SPEC.md` §4.1/§8
- `docs/design/UI_SPEC.md` §3.10 Amendment 5 (A5.1–A5.3) — the composition law
- `.agents/gen/_state/LOW_BACKLOG.md` rows L25/L39/L51/L55/L57/L59/L64/L70/
  L103/L182 (the evidence)

## Carries forward
- Ticked rows travel to S22 (implementation) and to the developer's docs tick
  pass (18/CONTRACTS rows); L49's audio-trim item joins this sheet's AUDIO
  pass.
