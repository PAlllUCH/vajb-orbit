# dispatch_designer.md — the graphics lane's queue of record

Rebuilt 2026-09-22 after the purge; re-cut 2026-09-22 (owner ruling) for a
two-designer split; reorganised 2026-09-24 (this file carries **open items only** —
the finished D2 job spec + handoff are archived at
`slices/D2-icon-unification/_archive/D2_dispatch_block.md`, detail in
`_state/WAVEBOARD.md` §Closed). Execute one item per order; briefs and prompts
live in the slice folders; the owner pastes only the short handoff paragraph.

## The standing ruling (owner, 2026-09-22) — lane law, applies to every item

- Glyph-type icons are **remade as SVG masters** (slot glyphs, equipment-slot
  symbols, `icon_contract_*`, service glyphs, chevrons/pips — the flat symbol
  side; example: `icon_contract_escort` → SVG).
- Depictive icons **keep one raster master only** (example: `icon_equip_drone`
  stays raster). The five-size families (`_48`/`_96`/`_192`/`@2x`) die — Godot
  scales from the one master ("we will scale it").
- **Delete all non-master rasters** — **project-side only**: `vajb-orbit/assets/`
  loses every variant and duplicate; `asset-library/` keeps every cut untouched
  (provenance law + the rollback).
- SVG source rule (this lane's standing style): flat shapes, `viewBox="0 0 48 48"`,
  designed on the 48 grid so the smallest target is pixel-clean; fills only (no
  strokes below 2 units), at most two tones (Steel `#565C63` family + the ember
  accent `#C8461B`/`#E8703A` where the icon carries danger/warn meaning).
  kie.ai cannot generate SVG (image-generator skill: "No native SVG") — the SVG
  set is **hand-authored** here; a pictogram that resists authoring may be
  generated once as a clean-flat raster ("no gradients, no grain") and traced
  (Inkscape), then simplified. **Amended 2026-09-22 (D2_SPLIT §6):** the 96 grid
  (`viewBox="0 0 96 96"`, 8–14 flat shapes) supersedes 48 for icon work.
- **Tint boundary:** a remade glyph's tint variants die with it (fills replace
  tint stencils); depictive icons' tint stencils stay until the tint-rework item
  below. Nothing else touches the tint pipeline.

## Open queue (designer #2's lane)

| D-slice | Item | What | Gate |
|---|---|---|---|
| D6 | 7 | **Cockpit instruments** — bottom-left cluster (sprite speed gauge + sprite compass + five 7-seg readout rows SPD/HULL/SHLD/FUEL %/ENRG %) + the `ship_status` ship layout screen (owner 2026-09-23, the NMS-style ask). Docs-first landed: UI_SPEC §3.7/§3.8, UI_CHROME §11, ASSET_NAMING §11, CONTRACTS §18 | **IN FLIGHT 2026-09-24** — brief `slices/D6-cockpit-instruments/D6_BRIEF.md`, prompts `D6_prompts.md`; write set disjoint from S5's (S5 closed 2026-09-24); run order M0a → owner sheet approval → M0b → M1 → M2 → R1 → F1 only on HIGH/MED |
| D3 | 1 | **Chrome re-cut** — button/slot plate family (the 1041×1087-cell-stretched defect class: plates, bezel band, bar caps, panel frame) | OWNER-GATED on `staging/phase_f/_preview/review_slots.png` |
| D3 | 2a | **Painted-only station rail icons** (owner 2026-09-23: "in space station the icons on 'MODULES' left menu should have only painted icons so no svg") — swap the station's left-rail/`MODULES` menu icons to **painted raster masters** (generate if no painted master exists for a symbol); SVGs stay for the in-list glyph work elsewhere. One review sheet of the rail at 48/96 px | READY |
| D3 | 2b | **Tint rework** (the depictive remainder): replace or repair the tint-stencil system for raster icons (shader tint or scoped stencils) + the **540**-file import-settings cleanup left over from D2 (the 1 080 figure predates D2's split — `D2_SPLIT.md` §4's formula) | READY |
| D4 | 3 | **4K 2× backdrop cuts** (R8; display target: 4K) | READY |
| D4 | 4 | **B2-1 hover look** — flicker / directional glow / ember | **OWNER PICK NEEDED** first |
| — | 5 | MMO/faction liveries, six boss hulls, `ship_vanguard_damaged` | BLOCKED on the owner's naming overhaul |
| — | 6 | Component icons ×18 (`comp_*`) — if not already covered by D2's split as depictive masters | verify against `D2_SPLIT.md` |

**File-collision law (both lanes):** two waves may never hold one file at once
(nor the same `test_*` prefix, nor one `staging/` driver). Across lanes, run in
parallel only with provably disjoint write sets (the S5∥D6 precedent); editor
reimports only in quiet windows between the other lane's gate runs; one editor
session.

**Done:** **D2 icon unification (designer #1's only job)** — DONE 2026-09-22
(commit `7c1ae06`; 135 SVG + 164 raster masters + 540 tint stencils = 839 files,
2 478 → 839, `asset_path_fallout` 0 unresolvable / 367 refs, gate 457/0 through
the re-points; owner amendments `D2_SPLIT.md` §6). Job spec + handoff archived at
`slices/D2-icon-unification/_archive/D2_dispatch_block.md`.

## Pipeline law (read before any run — AGENTS.md "Asset Generation" + "Phase G lane")

Panel order: render → find objects (`panels.py --detect`) → cut each → key each →
trim. A 2×2 sheet's fourth cell is often a second front (IoU > 0.80 = refuse).
`flare` never returns native alpha — `--post-only`. FX stay RGB except the four
§0.1 names. 2K run = 10 credits = $0.05. Delivery order: generate → stage →
**review sheet → owner approval** → ship → reimport → `validate_names.py
--library`. Generation logs beside every shipped family.

## Handoff template (one per dispatched item)

```text
Read .agents/gen/dispatch_designer.md and execute queue item <N> only — <wave name>. Brief: <brief path>. Prompts: <prompts path>. Snapshot + commit before the first dispatch, run <builder> → <reviewer>, and the fixer only if the review leaves HIGH or MED. Stop before item <N+1>. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline <tag>, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```

The live D6 handoff block is the one below (item 7, already dispatched 2026-09-24).

```text
Read .agents/gen/dispatch_designer.md and execute queue item 7 only — D6, the cockpit instruments cluster and ship status screen. Brief: .agents/gen/slices/D6-cockpit-instruments/D6_BRIEF.md. Prompts: .agents/gen/slices/D6-cockpit-instruments/D6_prompts.md. Snapshot + commit before the first dispatch, run M0a and STOP at the review sheet for my approval, then M0b, M1, M2, R1, and the fixer only if the review leaves HIGH or MED. This runs parallel with coder item 11: stay inside the D6 write set (ui/hud, assets/ui, assets/icons provenance, staging, asset-library, tests/test_d6_*), never touch project.godot, game/, autoload/ or the theme, and take editor reimports only in quiet windows. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline d6_start, CONTRACTS §9/§10 notes + the ship_status input row after S5-R1's pass, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the digit QC table, the reviewer's findings by tier, and the owner ticks.
```
