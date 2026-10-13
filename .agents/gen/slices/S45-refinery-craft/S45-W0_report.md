---
slice: S45
worker: S45-W0
model: hyper/glm-5.3-flash
status: actionable
gate: "1369/0 → 1379/0"
---

# S45-W0 report

## Result
P52's CRAFT tab is live: the four-recipe table `game/crafting_catalog.gd` (C2/C4/C5/C6/C8
verbatim), the AUCTION-idiom list over it (RECIPE · INPUTS · FEE · STATE band, `Button`
rows, `<n>× <name>` runs with the 24 px glyph, fee value + `CR LABOUR` caption, READY /
MISSING chips off `cargo_qty`, C3 `CRAFT` commit chips), the N28 bill sheet on the row
press, and the A4 door (8) confirm through the S25 seam feeding the catalog's
all-or-nothing `craft`. Gate: dispatch's baseline `[SUMMARY] passed=1369 failed=0`;
after, `[GATE] run 1: ok - [SUMMARY] passed=1379 failed=0`. Suite shaped per V0's
discipline (one mount, silent field writes, `profile_changed` disconnected, 64 MB cap).

## Acceptance list answers
1 — `game/crafting_catalog.gd:37-72`: the `RECIPES` const array (id, name, inputs
id→count, fee, output {module, effect}, description); fees exactly 2500/3000/2800/4000
(catalog :50/:58/:64/:70) and `MIN_FEE` 2000 pinned at :74; inputs exactly §6.2's ids and
counts; no price, fee or effect computed in the panel (every figure is a catalog read) —
pinned by `tests/test_s45_craft.gd:158-194`.
2 — the list: header band `_craft_header_cells` (`refinery_panel.gd:1382-1390`) filled at
:299, rows `_build_craft_row` (:1420-1457) — title + stat line (:1460-1476, N45 trim),
runs :1479-1506 with the 24 px glyph at its own cut (:1703-1720), fee :1509-1522, state
chip :1528-1546 (the strip chip's own flat box), C3 chip :1548-1561; rows are `Button` +
container children wearing C4 `ui_row_strip`; pinned by `tests:401-461`.
3 — the row press emits the sheet through the shipped `sheet_requested` seam
(:1575-1578 → :1606-1610), payload `{name, stats}` carrying the full bill
(:1613-1623); shell side untouched (`station.gd:1283-1284` auto-connect); pinned by
`tests:463-486` (exact bill string; N35's no-price/no-owned row).
4 — the chip press emits `confirm_requested` (:1628-1643) with title CONFIRM PURCHASE and
body `ARE YOU SURE YOU WANT TO CRAFT REACTOR MK3 FOR 2× GENERATOR BLOCK · 1× CAPACITOR
BANK · 6× COBALT INGOT + 2 500 CR LABOUR?` (A6's craft wording, `<BILL>` the run idiom);
`confirm_action` (:1308-1312) routes OK to `_run_craft` (:1645) — pinned by `tests:311-371`
incl. the still-refusing confirmed press.
5 — the transaction `CraftingCatalog.craft` (`crafting_catalog.gd:137-167`): verify
everything → spend → take every input → grant via `add_module` (the armory buys' own
seam, `player_profile.gd:735`) → one `CRAFT` log line; restore-and-refuse on a mid-take
failure; refusal names the missing input; pinned by `tests:222-283` (consumed/paid/
granted, all-or-nothing, no log on refusal).
6 — `scrap_value` at `crafting_catalog.gd:112-117` (50 % of `materials_value`, round
down; `materials_value` :102-110 reads the live 02/03 baselines); pinned by `tests:196-220`
against §6.3's own derivations (1 078/1 876/830/3 740 → 539/938/415/1 870). No UI door.
7 — the hint stays the reserved cell's CRAFT content (V0's `_refresh_footer`, word at
`refinery_panel.gd:132`); the empty state: `%CraftEmpty` renders when the table is
unreachable via the `_build_craft_from` seam (:1399-1410), pinned by `tests:373-399`.
8 — the suite `tests/test_s45_craft.gd` (10 rows) pins items 1–7; the fee and scrap rows
read the live catalog; this report answers every item above.

## Deviations from SLICE.md
- **The four output module ids are this wave's mint** (C6 leaves the 09 §3.x rows to the
  module-catalogue wave): `p_core_mk3` (the power ladder's own naming, carrying `p_core`'s
  +4 — C6's flag), `s_lattice`, `c_rail_refit`, `c_deep_scanner`. The grant works today:
  `add_module` records a base-id bag record with no `ModuleData` row yet. Reversal: other
  id shapes; rows land with the catalogue wave.
- **The confirm body's item names come from the catalogues** (`_craft_item_name`
  :1681-1693, the exchange `_item_name` idiom: GENERATOR BLOCK / CAPACITOR BANK / COBALT
  INGOT); A6's craft worked example prints generic family words (MECHANICAL COMPONENTS /
  POWER CELL). A6's own law binds `<NAME>`/`<BILL>` to the owning catalogue, so the
  catalogue names win — the example's words are stale on this point. Reported, not
  changed (bucket 2); see Follow-ups.
- **`scrap_value` returns the CR figure** (floor of half the materials' baseline value) —
  the name says value; the hull idiom (`Shipyard.scrap_materials`) returns units. The
  staged door picks its presentation later (bucket 1).
- **`_build_craft_from`** (:1399) is the build's one seam over the table source so the
  suite can drive the empty branch (the const table can never be empty in production).
- **V0's `craft_body.get_child_count() == 1` row kept green by construction**: CraftEmpty
  moved inside the new CraftScroll (tscn :312-349), so CraftBody keeps exactly one child
  and `test_s45_refinery.gd` needed no edit (re-ran solo, 11/0).
- **`CRAFTED · <NAME>`** (:145) is this wave's own success wording (nothing pins it;
  §5.6's shape). Reversal: any other wording.
- `_make_inner` now names its HBox `RowBox` (the auction's own name) so the suite can
  path rows structurally; no other suite paths it.

## Evidence
- Solo: `timeout 280 $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn -- --suite=test_s45_craft --quit-after 1200` →
  `[SUMMARY] passed=10 failed=0` (exit 0).
- V0's suite solo after the tscn change: same command, `--suite=test_s45_refinery` →
  `[SUMMARY] passed=11 failed=0`.
- Full gate: `timeout 280 python3 staging/gate.py --times 1` →
  `[GATE] run 1: ok - [SUMMARY] passed=1379 failed=0` (exit 0; zero `SCRIPT ERROR` lines
  in the log).
- `timeout 120 python3 staging/check_wiring.py` → "1576 hard refs, 988 advisory refs;
  every hard reference resolves".
- Exit noise, disclosed: both solos end with the ObjectDB-leak warning; `--verbose` shows
  every leaked instance is a `ui_click.ogg` playback object (the audio pool's own exit
  noise — V0's baseline shows the same class, 4 there / 8 here, the count is this suite's
  own CLICK cues). No nodes leak.

## Files touched
- `vajb-orbit/game/crafting_catalog.gd` — the recipe table, `craft`, `scrap_value`,
  `materials_value`, `first_missing` (new).
- `vajb-orbit/ui/station/refinery_panel.gd` — the CRAFT list builders/handlers, the
  confirm route, the sheet payload, mode-aware focus/disarm/inspect, catalog preloads.
- `vajb-orbit/ui/station/refinery_panel.tscn` — CraftScroll/CraftList/CraftHeadMargin/
  CraftHeader/CraftRows under CraftBody; CraftEmpty re-seated inside the scroll.
- `vajb-orbit/tests/test_s45_craft.gd` — the 10-row suite (new).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| The four crafted module ids need their `ModuleData` rows (09 §3.x) at the module-catalogue wave; until then a crafted module's bag record keys the bare id and the fitting UI cannot list it. | ticket | module-catalogue wave |
| C8's scrap UI door is staged; it chooses between this catalog's CR `scrap_value` and the hull idiom's units shape (`Shipyard.scrap_materials`) when it lands. | ticket | the scrap wave |
| A6's craft worked example names (MECHANICAL COMPONENTS / POWER CELL) disagree with the catalogue names the house idiom resolves; owner may re-point the example or pin display-name overrides. | ticket | docs/design/UI_SPEC.md §17 A6 (owner) |
