---
slice: D24
phase: P4
lane: design
status: active
gate_baseline: "1330/0"
---

# D24 — The station-overhaul design round

## Goal
Every P4 owner ask (the nine items in `phases/P4-station-overhaul/PHASE.md`,
recorded with their measured current state in `docs/design/STATION_HUB.md` §22)
becomes a pinned design: the owning docs carry the actual numbers, each with
its reversal, before any implementation worker is dispatched.

## In scope
- The OVERVIEW 3×3 grid of nine module buttons (owner ruling; closes the S41
  fold tradeoff) + T-184's glyph cure
- The buy-confirmation law (DialogManager routing, wording, the door list)
- The C-key Cargo overlay (station + flight)
- The launch sequence and its audio cues
- The armory equipped-items list
- The refinery: LOAD ALL, the machine-state idiom, the button layout, the
  CRAFT tab (with `07_crafting.md` specced for real)
- The exchange bulk-sell model
- The shipyard build-segment rework (house style, categories, materials bill)
- The T-174/T-175/T-176 owner-approved cures folded into the sections D24
  touches

## Out of scope
- Any code, scene, theme or asset change — docs only; the gate's rows cannot
  move (1330/0 ×2 byte-identical at close-out)
- The owner-locked `18_engine_spec.md`; CONTRACTS.md (review waves own it)
- B2-1 (menu hover look) and B2-2 (backdrop art resolution) — direction picks
  that stay the owner's
- The Pyre cascade (T-179, postponed)

## Acceptance criteria
The brief's numbered list (`D24_BRIEF.md` §Acceptance) — one item per owner
ask, each answered by the amendment that owns it.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D24-A1 | `docs/design/STATION_HUB.md, docs/design/UI_SPEC.md, docs/design/AUDIO_SPEC.md, docs/gameplay/04_refinery.md, docs/gameplay/07_crafting.md, docs/gameplay/03_components.md, docs/gameplay/10_ship_acquisition.md` | `D24_BRIEF.md` |
| D24-R1 | same set (read-own grading; may cure a one-line doc slip in review, disclosed) | `D24_BRIEF.md` §Review |

## Reports
- `D24-A1_report.md` — answers the acceptance list item by item, cite per item
- `D24-R1_review.md` — grades the list, findings tiered HIGH/MED/LOW
