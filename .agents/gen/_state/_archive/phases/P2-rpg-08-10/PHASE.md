---
phase: P2
title: RPG docs 08/09/10
status: active
slices: [S3]
---

> Manifest and index only — work lives in `slices/`; this file never grows a
> work log. Created 2026-09-22 under the folder law (`_templates/README.md`).

# P2 — RPG docs 08/09/10

## Goal
The ship RPG layer: per-class slot frames, the weapon/fitting surface, module
instances with affixes, then the AUCTION as the one acquisition door. Driven
by the owner's docs 08/09/10 (frames, slots/modules, acquisition) plus 15
(affixes).

## Slices
| ID | Name | Folder | Status | Gate |
|---|---|---|---|---|
| S2.6 | truth-and-feel (repair + polish, queue item 8) | `slices/S2.6-truth-and-feel/` | draft | 437/0 sandboxed (L93) |
| S3 | item economy: instances + AUCTION (queue item 9) | `slices/S3-module-affixes/` | draft | S2.6's close figure |
| S4 | weapon batteries (queue item 10) | `slices/S4-weapon-batteries/` | draft | S3's close figure |

Earlier P2 waves (P2-A ship slot frames, P2-B1 weapon fit surface, P2-B
proper fitting panel) predate the folder law; their record is
`.agents/gen/session_2026-09-22_items_4_to_7_report.md` and
`.agents/gen/MASTER_REPORT.md`.

## Exit criteria
- [ ] Every slice `done` (findings tiered, briefs archived)
- [ ] `docs/CONTRACTS.md` updated by the closing review wave
- [ ] Phase summary: 1 page here — what shipped, what carries forward

## Carries forward
- `T-80` (L80) — instance-vs-base-id seam, resolved in S3
- `T-92` (L92) — bare hull's mandatory-cell `REMOVE` residual (W2's disclosed
  reading), rides the next wave that owns the fitting pane
- `T-93` (L93) — the gate is not hermetic (437/0 sandboxed, 433/4 on the live
  save); a test+harness repair that rides the next wave or its own micro-wave
- Owner requests 5–7 (recorded in `_state/WAVEBOARD.md`: rock fragments'
  outward motion, beam hit-FX scatter, beam termination nearer mid-object)
  — each needs its own docs-first brief before any code
