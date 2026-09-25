# dispatch_designer.md — the graphics lane's queue of record

Rebuilt 2026-09-22 (owner ruling: two-designer split), reorganised 2026-09-24
(open items only — closed work lives in the Done pointer below and
`_state/WAVEBOARD.md` §Closed). Execute one item per order; briefs/prompts live
in the slice folders (**items without a slice folder get their five-piece at
dispatch-prep — say the item and it lands**); the owner pastes only the handoff
block at the bottom. **Model: `opencode-go/mimo-v2.6-pro` for every design
worker** on `--reasoning-effort low` (owner standing rule 2026-09-25: design
runs on 2.6 Pro only — supersedes the 2026-09-24 deepseek/mimo-flash lines;
measured that day, `medium` stalls on long worker loops while `low` is fast).

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
- SVG source rule: flat shapes, `viewBox="0 0 96 96"` (the 96 grid,
  `D2_SPLIT.md` §6), 8–14 flat shapes, fills only (no strokes below 2 units),
  at most two tones (Steel `#565C63` family + ember `#C8461B`/`#E8703A` where
  the icon carries danger/warn meaning). kie.ai cannot generate SVG — the SVG
  set is hand-authored; a resistant pictogram may be rendered once clean-flat
  and traced (Inkscape), then simplified.
- **Tint boundary:** a remade glyph's tint variants die with it; depictive
  icons' tint stencils stay until item 2b. Nothing else touches the tint
  pipeline.

## Open queue

| D-slice | Item | What | Gate |
|---|---|---|---|
| D8 | 9 | **Station composition pass** (QA): the right-third dead zones — Armory's ~520 px void + clipped third row, Fitting's grid-left void, Repairs/Launch 440 px spacers | OWNER MOCKUP GATE first; brief at dispatch-prep |
| D8 | 10 | **In-flight HUD visibility** (QA): empty top-left while all state sits bottom-left; minimap legend + unreadable 1080p glyphs | PICKS 2026-09-24: top-left content + minimap legend + 1080p glyphs | **IN FLIGHT 2026-09-25** — brief at `slices/D8-hud-visibility/`; B1 → R1 → F1 on HIGH/MED; runs parallel with coder items 21/22 on disjoint sets (`ui/hud/` only) |
| D9 | 11 | **Player-hull visibility** (QA): dark hull ~40 px at flight zoom — rim light / brighter tint / scale bump | PICK 2026-09-24: scale bump only (target ~56 px proposed); brief at dispatch-prep |
| D10 | 12 | **Polish batch** (QA): the status close-X, the launch arm countdown (M6), auction hull thumbnails, mining-beam visibility | PICKS 2026-09-24: all four in; brief at dispatch-prep |
| D3 | 1 | **Chrome re-cut** — button/slot plate family (the 1041×1087-cell-stretched defect class) | VERDICT 2026-09-24 GO on `staging/phase_f/_preview/review_slots.png`; brief at dispatch-prep |
| D3 | 2a | **Painted-only station rail icons** (owner 2026-09-23) — swap the left-rail/`MODULES` icons to painted raster masters; SVGs stay for in-list glyphs; one review sheet at 48/96 px | READY; brief at dispatch-prep |
| D3 | 2b | **Tint rework** + the **540**-file import-settings cleanup left from D2 | READY; brief at dispatch-prep |
| D4 | 3 | **4K 2× backdrop cuts** (R8) | READY; brief at dispatch-prep |
| D4 | 4 | **B2-1 hover look** — flicker / directional glow / ember | PICKS 2026-09-24: all three combined; brief at dispatch-prep |
| — | 5 | MMO/faction liveries, six boss hulls, `ship_vanguard_damaged` | BLOCKED on the naming overhaul |
| — | 6 | Component icons ×18 (`comp_*`) | verify against `D2_SPLIT.md` |

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). Across lanes only with provably disjoint
write sets (the S5∥D6 precedent); editor reimports in quiet windows between the
other lane's gate runs; one live session. **No live parallel pair** as of D11's
close-out (2026-09-25).

## Done

**D11 space-station scene rework (item 13)** — DONE 2026-09-25 (gate 807 →
**812/0**; 0 HIGH / 2 MED cured (F1's value grade + the designer session's
`ASSET_NAMING_SPEC` §13 rows) / 7 LOW L184–L190; hero 2.2003×, 6 static + 3
moving kinds, 19 elements, $0.85 spent; two owner ticks recorded in the
WAVEBOARD; brief/reports at `slices/D11-station-scene/`).

**D7 cockpit rework + battery window (item 8)** — DONE 2026-09-24 (gate
674 → **727/0**; 1 HIGH + 1 MED cured by F1/A2; mockup loop v5/v6/v7 +
Mockup A/C; `CockpitStyle`; brief/reports at `slices/D7-cockpit-rework/_archive/`).
**D6 cockpit instruments (item 7)** — DONE 2026-09-24 (578 → **608/0**; 18
masters, cluster + status modal; `slices/D6-cockpit-instruments/_archive/`).
**D2 icon unification** — DONE 2026-09-22 (135 SVG + 164 raster masters, gate
457 through the re-points; job spec archived under its `_archive/`).

## Pipeline law (read before any run — AGENTS.md "Asset Generation" + "Phase G lane")

Panel order: render → find objects (`panels.py --detect`) → cut each → key each
→ trim. A 2×2 sheet's fourth cell is often a second front (IoU > 0.80 = refuse).
`flare` never returns native alpha — `--post-only`. FX stay RGB except the four
§0.1 names. 2K run = 10 credits = $0.05. Delivery order: generate → stage →
**review sheet → owner approval** → ship → reimport → `validate_names.py
--library` (host-deferred where noted). Generation logs beside every shipped
family.

## Handoff (live — paste as one block)

**D8 item 10 (in-flight HUD visibility) is live 2026-09-25** (`slices/D8-hud-visibility/`),
running beside coder items 21/22 on disjoint sets. Candidates still
open: D8 item 9 (blocked on its
mockup gate), D9 item 11 / D10 item 12 (both wait on the coder waves' `game/`
and `ui/station/` sets), the **D12 graphics fix wave** (waits on S15's armory
set), D3 item 1 (GO on `review_slots.png`), D3 2a/2b, D4 3/4. Say the item and
its five-piece lands at dispatch-prep.
