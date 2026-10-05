---
slice: D21
phase: P3
lane: design
status: draft
gate_baseline: ""     # design-only: gate n/a (no row moved)
---

> Filled from `_templates/SLICE.md` at the owner's 2026-10-05 ruling.

# D21 — The one true-aspect UI chrome family

## Goal
Every UI surface in the game wears one regenerated chrome family, each plate
drawn at its surface's true aspect so nothing is ever stretched; the station
panels gain a few unique backgrounds. The stretched-square fault the owner
diagnosed dies everywhere at once.

## In scope
- The chrome surface census (every styled surface + its aspect class) and the
  family spec + nine-slice margins law — `docs/design/UI_SPEC.md` §15.
- The regeneration prompt set (one prompt per surface class at true aspect,
  the owner's style anchors) + the unique station backgrounds —
  `docs/design/UI_CHROME_ASSETS_SPEC.md`'s 2026-10-05 amendment.
- Wireframe/aspect mockup only if the spec needs one (`staging/mockup/`).

## Out of scope
- Actually generating art (the orchestrator runs `$KIE_GENERATE` after the
  owner approves the prompt set + spend).
- Wiring/re-skinning code — wave **S35** after the owner's review-sheet pick.
- Layout changes: S33 (armory two-sector, exchange sell) and S34 (refinery)
  own those; this family lands over whatever layout ships.

## Acceptance criteria
- [ ] AC1 — every surface in the census carries a named aspect class and a
  true-aspect target size; the table is complete against a `StyleBox` /
  `theme_override` / `*_plate` grep census
- [ ] AC2 — the prompt set has one shell-safe kie.ai prompt per class at the
  class's aspect, all citing the owner's style anchors, with per-run credit
  cost summed
- [ ] AC3 — the margins law states, per class, where nine-slice stretch is
  allowed and that caps never stretch ("respected always")
- [ ] AC4 — the unique station backgrounds are specified (count, which
  panels, aspect) as PROPOSED values with reversals + tick T-131

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D21-A1 | `docs/design/,staging/mockup/` | `D21-A1_BRIEF.md` |
| D21-R1 | `vajb-orbit/tests/,.agents/gen/slices/D21-chrome-family/` | `D21-R1_BRIEF.md` |

## References
- `docs/design/UI_SPEC.md` §5 (nine-patch panels), §8 (P1/P2 buttons),
  §13.1 (N42–N47), §14 (the superseded N50/N51 + the fault record)
- `docs/design/UI_CHROME_ASSETS_SPEC.md`, `ASSET_CATALOG.md`, `ASSET_NAMING_SPEC.md`
- `docs/design/STYLE_BIBLE.md` (palette), `STATION_HUB.md` §19.2 (tiles),
  §21 (the S33/S34 layouts this family lands over)
- `.agents/gen/slices/S33-shell-v3/button_candidates.md` (the search record +
  anchor resolution)

## Carries forward
- Tick **T-131** (unique station backgrounds: count + panel assignment).
- The owner's style anchors verbatim (D21_BRIEF §0) — the family must read as
  their sibling, not a new style.
