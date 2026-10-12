---
slice: S43
worker: S43-V0
role: coder
status: ready
tier: paid
---

# S43-V0 — the armory EQUIPPED list (P49) + its buy doors (UI_SPEC §17 A4–A6)

## Context (read in this order, by range)
1. `docs/design/STATION_HUB.md` §23.4 (lines ~2139–2143, verbatim below) and
   §21.1 P38 (the two-sector FIT CELLS law your block extends); §15.1 U2.
2. `docs/design/UI_SPEC.md` §17 (lines ~1903–1920) — A4/A5/A6 verbatim below —
   and §16.1 (the ink law).
3. `vajb-orbit/ui/station/armory_panel.gd` — by grep then range: `MODE_FIT`
   (`:131`), the `FitLeft` structure in `armory_panel.tscn:113-165`
   (`FitLeftBox` → `FitLeftInset` → `FitLeftStack` → `GridBlock`, then
   `CellInfoBlock`), `_build_slot_grid`/`_cells` (`:3263`, `:3409`,
   `select_cell` `:3424`, `selected_cell` `:3446`), `_refresh_cell_info`
   (`:2103`), the browser's buy seam (`_on_buy_pressed` — grep it), the ammo
   buy path (`buy_ammo` at `:1929`), `_module_name` (`:3082`).
4. The stat-line idiom: `vajb-orbit/ui/station/fitting_panel.gd:1634`
   `stat_line()` and `:1584` `_base_stats_line()` (the shipped renderer of
   09 §3's effect column), and `game/module_catalog.gd`'s `effects` dicts.
5. `docs/gameplay/09_ship_slots_modules.md` §8 (lines ~487–512) — the matrix
   order your list's row order reads; §3 for the effect language.
6. The confirm seam contract (verbatim below): `contracts_panel.gd:426-435`
   (the payload) + `ui/screens/station.gd:568-599` (the shell's answer path).

## Spec extract (the pinned law, verbatim)

**STATION_HUB §23.4 P49** — "FIT CELLS' **left sector** (§21.1 P38) gains a
third block under CELL INFO: caption **`EQUIPPED — <n>/<slot count>`**
(`StationCaption`, A5.4-3), then **one row per fitted module/weapon in the SLOT
LAYOUT grid's own cell order** (09 §8's matrix order): cell id (`W3`/`S1`/`E2`,
`StationValue`), the module's name (`StationValue`), and **one stat line** — the
module's 09 §3 effect column verbatim (e.g. `+400 POOL · REGEN 5/S`), plus the
family glyph 24 at its own cut. Row idiom: the A5.3 inventory row (flat Tokens
box `item_bg` + 1 px `metal_mid`, inset 6); the list scrolls in its own
`ScrollContainer` when it outgrows the sector. **Pressing a row selects that
cell** (the same selection state as the grid — one selection, two views; CELL
INFO follows). Empty cells are not listed. BATTERY CONFIG shows no list (the
racks are the weapons' view, P34)."

**UI_SPEC §17 A4 (doors)** — "(2) **module buy** — the ARMORY browser's `BUY`
… (3) **ammo** — the OUTFITTING ammo pack purchase (§5.1, `buy_ammo`)".

**A5 (route)** — "every door goes through `DialogManager.confirm(id, title,
body, "OK", "CANCEL")` — never `message` … `dialog_confirmed(id)` runs the
existing transaction path unchanged (a confirmed press can still refuse);
`dialog_cancelled(id)` returns focus to the trigger (N39). The buttons carry
the existing dialog cue (§5.2's CLICK). Esc maps to CANCEL."

**A6 (wording)** — "title `CONFIRM PURCHASE`; body **`ARE YOU SURE YOU WANT TO
BUY <NAME> FOR <PRICE> CREDITS?`** — `<NAME>`/`<PRICE>` from the owning
catalogue (never hardcoded). Worked examples: module `…BUY S_ION FOR
5 600 CREDITS?` (09 §3.2); ammo `…BUY LASER CELLS (300 ROUNDS) FOR <PACK.COST>
CREDITS?`."

## The disclosed route reading (developer, bucket 1 — the reviewer grades it, the report discloses it)
A5's `DialogManager.confirm` names the §5.2 dialog *idiom*'s autoload sink.
The station screen has owned that idiom's implementation since S25
(`station.gd:494-520` — "the overlay belongs to the screen and not to a pane…
no pane ever owns a modal"): the pane emits
`confirm_requested({id, title, body, confirm_text, cancel_text, action})` and
the shell answers through `confirm_action(action, id)` (verbatim at
`contracts_panel.gd:426-435` and `station.gd:568-599`). **Route the doors
through that seam** — the shell overlay is the §5.2 sink this surface family
already has, and A5's own reversal ("a second bespoke dialog scene") forbids
building a competing one. Use `confirm_text: "OK"`, `cancel_text: "CANCEL"`,
title `CONFIRM PURCHASE`. The focus-return and ESC→CANCEL behaviour are the
seam's own (already shipped). If you find a reason this cannot hold, report it
and stop at that item.

## Measured facts (cite, do not re-derive)
- The left sector's block order is the `FitLeftStack`'s child order:
  `GridBlock` (`armory_panel.tscn:135`) then `CellInfoBlock` (`:161`). The
  EQUIPPED block builds under CELL INFO in that stack (a third block; the
  tscn or the script may own it — follow the file's own pattern).
- The cell payloads live in `_cells` (built for the hull's matrix, row-major —
  `ShipFit.grid_cells`), each `{type, token, index, …}`; the fitted module of a
  cell resolves through `_cell_module(fit, slot_key, index)` and
  `_base_id(profile, entry)` (`armory_panel.gd:2125-2129` region); the name is
  `_module_name(base)` (`:3082`).
- The grid's cell id format and the CELL INFO id line live at
  `CELL_INFO_ID` (`:143` region) — reuse the same id composition (`W3`, `S1`),
  never a second format.
- The list's row press must land in the same selection the grid's press uses:
  `select_cell(slot_key, index)` (`:3424`) — the one selection, two views.
- The module buy press is the browser row's `BUY` (grep `_on_buy_pressed`);
  the ammo press path is the `buy_ammo` profile call (`:1929`) — both run their
  existing refusal paths unchanged after a confirmed answer.
- Flat Tokens box row idiom exemplars: `exchange_panel.gd` inventory rows and
  `armory_panel.tscn`'s `FitLeftBox` (bg `item_bg`/`bay_bg` + 1 px `metal_mid`,
  inset 6). No new hex anywhere.
- The ammo pack name for the wording: the pack row's own name field
  (`Catalog.AMMO_PACKS`, `armory_panel.gd:1702-1729` region) — e.g.
  `LASER CELLS (300 ROUNDS)`; the price is `Catalog.ammo_pack_price(pack_id,
  station, standing)` (`:1718`) — the door's body quotes the price the press
  will actually charge, at press time (§5.8's clock law).
- Gate baseline 1330/0 (2026-10-12).

## Task
Build P49's EQUIPPED block in the FIT CELLS left sector and wire the two A4
doors (module buy, ammo buy) through the shell's confirm seam with A6's
wording. Add the new suite `tests/test_s43_armory_equipped.gd` pinning the
acceptance list.

## Acceptance list
1. FIT CELLS' left sector carries a third block under CELL INFO: the caption
   `EQUIPPED — <n>/<slot count>` (`StationCaption`), where `<slot count>` is
   the active hull's total slot cells.
2. One row per fitted module/weapon in the SLOT LAYOUT grid's own order (09 §8
   row-major); empty cells are not listed; each row carries the cell id
   (`W3`/`S1`/`E2`, `StationValue`), the module's name (`StationValue`), one
   stat line from the catalogue's `effects` (the `stat_line` idiom), and the
   family glyph 24 at its own cut.
3. The rows wear the flat Tokens box (`item_bg` + 1 px `metal_mid`, inset 6);
   the list scrolls in its own `ScrollContainer` when it outgrows the sector.
4. Pressing a row selects that cell — the same selection state as the grid
   (`select_cell`), CELL INFO follows; one selection, two views.
5. BATTERY CONFIG shows no list (the block exists only in `MODE_FIT`).
6. The browser's module `BUY` press opens the confirm dialog with title
   `CONFIRM PURCHASE` and body `ARE YOU SURE YOU WANT TO BUY <NAME> FOR
   <PRICE> CREDITS?` (name/price from the catalogue row at press time); OK
   runs the existing buy path unchanged (which can still refuse); CANCEL
   returns focus to the trigger.
7. The ammo pack buy press opens the same dialog with the pack's own name and
   price (`…BUY LASER CELLS (300 ROUNDS) FOR <PACK.COST> CREDITS?`); OK runs
   the existing `buy_ammo` path; the refusal strip still works.
8. New suite `tests/test_s43_armory_equipped.gd` pins items 1–7 (at least one
   row each); the report answers every item with a cite.

## Hard constraints
- File set: `vajb-orbit/ui/station/armory_panel.gd`,
  `vajb-orbit/ui/station/armory_panel.tscn`,
  `vajb-orbit/tests/test_s43_armory_equipped.gd`. **Do not touch**
  `station.gd` (the seam is shipped), the theme, other panels, docs, or
  `tests/test_s41_armory.gd` (if a row there goes red because your change
  moved a premise, report it — the developer re-cuts, you never edit a
  measuring suite you did not write).
- No new hex; no new tokens; A5.1–A5.5 composition (containers + anchors +
  `custom_minimum_size` + size flags; never `position`/`offset_*` on laid-out
  children; no `_draw` over content).
- A confirmed press that refuses keeps §5.6's strip wording (never a dialog).
- Shell edits forbidden; every Godot run bounded (`--quit-after`); probes
  self-quit; never leave a command in the background.
- Gate: `python3 staging/gate.py --times 1` for your own check; record
  before/after `[SUMMARY]`.

## Output contract
- Report: `.agents/gen/slices/S43-armory-equipped/S43-V0_report.md` (≤120
  lines, from `_templates/REPORT.md`).
- Deliverable: the three files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/ui/station/armory_panel.tscn,vajb-orbit/tests/test_s43_armory_equipped.gd" crush run "You are worker S43-V0. Read .agents/gen/slices/S43-armory-equipped/S43-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
