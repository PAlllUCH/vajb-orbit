---
slice: S41
worker: S41-B3
model: deepseek-v4.1-flash (hyper)
status: informational
gate: "1300/0 → 1327/0 ×2 (my two runs; +27 = shell 12 + panels_a 5 + armory 4 + panels_b 6)"
---

# S41-B3 report — the ARMORY (F2, F3, F4, F14 armory half)

## Result
The armory's left sector is roofed end to end (F2), the battery list's band reads
`STATE`/`HELD` over `FITTED`/`OWNED x n` rows (F3), the battery fold's two caption-only plates
hug their captions (F4), and the action pair rides the pane's own foot band at the same rect in
both modes (F14). Gate **1327/0** twice on fresh scratch stores (identical counts).

## Acceptance list answers
- **A1** — F2, F3, F4 and F14 (armory) fixed at their named sites; none NOT DONE:
  F2 `armory_panel.tscn:119-121`; F3 `armory_panel.gd:172, 1033-1037, 3924-3926, 3933-3934`;
  F4 `armory_panel.tscn:352-357` + `armory_panel.gd:1650-1660`; F14 `armory_panel.tscn:234-266`.
  The other 12 findings are B1/B2/B4's (brief §3).
- **A2** — no `position`/`offset_*` is written from code; the only offsets are declared in the
  scene (the two mode roots' `offset_bottom = 68`, `armory_panel.tscn:102, 279`). The one
  `size_flags_vertical = 3` I added is on **`FitLeftBox`** (`armory_panel.tscn:121`) — the left
  sector's full-height roofed surface, which is F2's own prescription (D23-R1 §A2 names this
  flag as the one working *against* the design at v=0).
- **A3** — no colour added or changed: `git diff --stat` shows only
  `ui/station/armory_panel.{gd,tscn}` + `tests/test_s41_armory.gd` (no `build_theme.gd`, no
  `vajb_theme.tres`).
- **A4** — not B3's (F1 is B2's; `tests/test_s41_panels_a.gd` is B2's proof).
- **A5** — proved: the pair is a child of `PaneFoot/ActionsRow`, both buttons 360×56, the band
  closes the pane and the primary is rightmost — the exchange's own anchor
  (`exchange_panel.tscn:177-218`). `test_s41_armory.gd:test_f14_…` measures the band's rect in
  both modes and asserts they are equal.
- **A6** — not B3's (T-177 is B1's, W1).
- **A7** — every row is load-bearing, proved by reverting each fix and re-running the suite:
  F2 → `F2: the box carries the sector's vertical slack` (and the layout gap assert);
  F3 → `F3: the battery band reads STATE / HELD (["MODULE", "STATE", "COST"])`;
  F4 → `F4: the empty-cell list is one empty-cell line tall`;
  F14 → `the pane's foot band ships with its action cluster` (`%PaneFoot` absent).
  The suite has **no `await`** and reads properties with `get()` and laid-out rects only — no
  `call()` on a name that could silently miss.
- **A8** — no gate row outside §6's list moved: my armory-related run (d7_armory,
  s18_armory_rework, s32_armory_modes, s29_station_panels, ui_slot_layout, p2b_fitting_panel,
  p2b1_outfitting_panel, s40_legibility, s5_ammo_cargo, s41_armory) = **141 rows / 0 failures**.

## Deviations from the pinned reading (every new value PROPOSED, with its reversal)
| New value | Where | Why | Reversal |
|---|---|---|---|
| `BAND_HELD = "HELD"` (a new band word) | `armory_panel.gd:172` | F3: the battery rows print `FITTED`/`OWNED ×n`, so `COST` mislabels its column | the browser's `BAND_COST` in both modes |
| `_band_captions()` + the band rebuilt on a mode switch | `armory_panel.gd:1033-1037, 3924-3926` | the band is one shared subtree, so its words are a content swap (N31) | the fixed `[BAND_STATE, BAND_COST]` build |
| `EmptyScroll` `custom_minimum_size.y = 22` + `size_flags_vertical = 0` | `armory_panel.tscn:352-357` | F4: the empty-cell plate hugs one `W<n> — EMPTY` line | the shipped `size_flags_vertical = 3` (a 70 px plate) |
| the drawn well plate capped at the half's content block | `armory_panel.gd:1650-1660` | F4: a caption-only half stops being a 92 px empty box | `_style.well_half_rect(half, console)` |
| `ModeHost` `MarginContainer` → `Control`, `clip_contents` dropped | `armory_panel.tscn:90-94` | F14: the mode roots' own anchors/offsets then rule (a MarginContainer re-fits every child) | the shipped `MarginContainer` + `clip_contents` |
| the two mode roots' `offset_bottom = 68` (the band 56 + the pane root's 12 px gutter) | `armory_panel.tscn:102, 279` | F14: the mode roots keep the pane's full height, so the band overlays their bottom instead of shrinking them — **test_d7_armory's 557/459/87/518 pins and test_s18_armory_rework's `block_size().y` are untouched** | drop the offsets (the mode host then loses 68 px and those rows move — a bucket-2 re-pin) |
| the reserved slots `FitFoot` / `EqFoot` (56 px `Control`s) | `armory_panel.tscn:267-270, 393-397` | F14: each mode's list stops above the band instead of scrolling in behind the pair | drop both (rows then run under the pair) |
| `_menu_sector.move_child(host, 0)` | `armory_panel.gd:1022-1024` | the reparent appends, and `EqFoot` must stay the sector's last child | the append order (the slot lands above the menu) |

No `docs/` text was edited and no `VAJB_WORKER_FILES` set changed.

## Evidence
- Gate ×2, fresh scratch stores: `XDG_DATA_HOME=$(mktemp -d) "$GODOT_CONSOLE" --headless --path
  "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 2400` →
  `[SUMMARY] passed=1327 failed=0` and `[SUMMARY] passed=1327 failed=0` (`/tmp/s41_b3_gate{1,2}.log`).
- The four rows this worker owns: `--suite=test_s41_armory` → `passed=4 failed=0`.
- The four revert proofs (one fix at a time): `failed=1` each, on the named assertion (above).
- Visual: `"$GODOT_CONSOLE" --path "$VAJB_PROJ" res://tests/probe_s40_panes.tscn --quit-after 3000`
  → `AUDIT deck=deck0_armory_battery labels=62 below_3=0% below_4.5=0%`; the battery render now
  shows the fold captions over caption-high plates and the pair in the pane's foot band, the FIT
  render shows the left sector roofed to the pane's bottom.

## Files touched
- `vajb-orbit/ui/station/armory_panel.tscn` — F2's flag, F4's empty-cell plate, the pane-level
  `PaneFoot` + `ActionsRow`, the mode roots' `offset_bottom`, the two reserved slots, `ModeHost`.
- `vajb-orbit/ui/station/armory_panel.gd` — `BAND_HELD`, `_band_captions()`, the band rebuild on
  a mode switch, `_well_plate_rect()`, the menu's child order, the F14 comment block.
- `vajb-orbit/tests/test_s41_armory.gd` — 4 rows (F2, F3, F4, F14), each revert-proved.

## Follow-ups
None from B3: the fixes are pins-green, so nothing is owed to a re-pin. `armory_style.gd` was
left untouched (its `wells_height` band arithmetic is unchanged; only the *drawn* plate's rect
moved into the panel).
