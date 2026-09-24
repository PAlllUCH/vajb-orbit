---
slice: S11
worker: S11-B6
model: ""             # the orchestrator records the slug that actually ran
status: informational
gate: "806/1 (twice, fresh scratch stores; the one failure is S11-B2's, not this worker's)"
---

# S11-B6 report — the inspector's missing bodies and its identity line (CONTRACTS §23.1)

## Result

`StationCatalog.describe` now also reads `MineralCatalog` / `ComponentCatalog`, so a REFINERY
ore row and an EXCHANGE mineral/component hold row show the prose their own catalogue carries
(`game/station_catalog.gd:375-376`). The six item panes' inspector titles are now the row's
identity — its name plus its price phrase, joined by the pane's own `" · "`, with the leading
key-hint verb dropped — while each pane's `status_requested` line is byte-identical. New
`tests/test_s11_describe.gd` is `11/0`.

## The widened source list

`_description_of` sources, in order (`game/station_catalog.gd:364-377`): `ModuleCatalog.module`,
`ship`, `ammo_pack(id)`, `service`, `ammo_pack(ammo_family(id))`, **`MineralCatalog.entry_for_item(id)`**,
**`ComponentCatalog.component(id)`**. `entry_for_item` resolves a bare mineral id (`iron`), a
`mineral_*` ore id and an `ingot_*` id to the same mineral row, so all three of REFINERY's and
EXCHANGE's forms answer alike. Base-id resolution and the `ammo_*` pack mapping are B1's,
untouched; `""` still means "this row carries no prose".

## The title: one before/after per pane

| pane | before (B1, the hint verbatim) | after (identity) | status line (unmoved) |
|---|---|---|---|
| armory `_inspect_row` | `ENTER BUY · CANNON MKI · 1 200 CREDITS` | `CANNON MKI · 1 200 CREDITS` | `ENTER BUY · …` |
| refinery | `READY · IRON ORE · 2 CONVERSIONS · 120 FEE` | `IRON ORE · 2 CONVERSIONS · 120 FEE` | `READY · …` |
| exchange | `ENTER SELECT · IRON · <unit> CR EACH` | `IRON · <unit> CR EACH` | `ENTER SELECT · …` |
| auction | `ENTER VANGUARD · 5 000 · BUY CREDITS` | `VANGUARD · 5 000 CREDITS` | shipped order, unmoved |
| shipyard | `ENTER PREVIEWS · VANGUARD · CUTTER CLASS` | `VANGUARD · CUTTER CLASS` | `ENTER PREVIEWS · …` |
| fitting | `MAULER` (already identity) | `MAULER` (no change) | its own footer line |

Each pane carries the phrase as `INSPECT_TITLE_FORMAT` (`armory_panel.gd:123`,
`refinery_panel.gd:90`, `exchange_panel.gd:123`, `auction_panel.gd:145`,
`shipyard_panel.gd:141`) and a `_row_title` beside its `_row_hint`. ARMORY's other two
inspect surfaces (`_inspect_barrel`'s `BARREL_TEXT`, `_inspect_module`'s name) were already
identity and are untouched. No font size, colour or other string moved.

## Deviations (judgment calls, each with its reversal)

1. **AUCTION's shipped status line does not lead with its verb.** `STATUS_HINT` is
   `"ENTER %s · %s · %s CREDITS"` and `_row_hint` passes `[name, cost, action_word]`
   (`auction_panel.gd:140,1025-1030`), so the footer renders `ENTER VANGUARD · 5 000 · BUY
   CREDITS`. The pin keeps the status line byte-identical, so it is left exactly so and only
   the title is fixed; the title follows the pin's identity rule (`name · price`), which is
   what the line would yield if its args matched its format. If the planner wants the shipped
   order corrected it is a §23 status-wording change, not this worker's. Reversal: none owed.
2. **EXCHANGE already owns a `TITLE_FORMAT`** (`exchange_panel.gd:111`, `"%s · %d HELD"`), so
   all five new title consts are named `INSPECT_TITLE_FORMAT` for one uniform name.
   Reversal: rename each.
3. **REFINERY drops only the leading `READY`**, keeping the conversions phrase, not just the
   fee; dropping conversions would lose the row's own figure with no rule to justify it.
   Reversal: `INSPECT_TITLE_FORMAT := "%s · %s FEE"` with `[name, fee]`.
4. **FITTING carries no leading hint verb** — its rows print `FIT`/`SWAP` in the ACTION cell
   and its status line is its own footer line — so B1's name-only title already satisfies the
   pin and no code changed there. Reversal: n/a.

## Evidence

- Gate, run 1, fresh scratch store:
  `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=806 failed=1`.
- Gate, run 2, fresh scratch store: identical, `[SUMMARY] passed=806 failed=1`.
- The one failure is **S11-B2's**, not this worker's: `test_ship_grids.gd:808`
  (`test_module_catalog_carries_the_pinned_rows`) asserts `published.size() == 7`, and B2's
  in-tree `&"description"` key makes 8. §23.6 assigns that re-derivation to B2; this worker's
  file set excludes `tests/test_ship_grids.gd`.
- This worker's suite: `-- --suite=test_s11_describe` → `[SUMMARY] passed=11 failed=0`.
- Station-touching suites (inspector, describe, d7_armory, s10_armory_input, s3_auction,
  p2b1_panel, p2b_fitting) → `[SUMMARY] passed=56 failed=0`.

## Files touched

- `game/station_catalog.gd` — the two widened sources and their doc.
- `ui/station/armory_panel.gd`, `refinery_panel.gd`, `exchange_panel.gd`, `auction_panel.gd`,
  `shipyard_panel.gd` — `INSPECT_TITLE_FORMAT` + `_row_title`, and `_inspect_row` uses it.
- `ui/station/fitting_panel.gd` — read only; already conformant.
- `tests/test_s11_describe.gd` — new suite (11 tests).

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| AUCTION's footer renders `[name, cost, action]`, not the verb-led order its format reads as | pin question for R1/planner | `ui/station/auction_panel.gd:140,1025` |
| `test_ship_grids.gd:808` still pins 7 module keys; B2's `description` key is the 8th | B2's outstanding red (not this worker's) | `vajb-orbit/tests/test_ship_grids.gd:808` |
