---
slice: S18
worker: S18-B1
model: "deepseek-flash (session model, builder)"
status: actionable
gate: "877/0 → 886/0"
---

# S18-B1 report — the ARMORY rebuilt as D13's approach B

## Result
The ARMORY pane renders D13's design of record: the landscape **1360×516** console at the
pinned host (P6: every rect derived from the host rect), five **2×2-cell** bays `B1..B5`
across one band, one wells band with the barrel inventory left and the six ammunition pack
cards right, `DROP HERE` on empty cells, per-bay salvo ledges, a `READY`/`▲ OVER CAP` chip on
each bay head, and the worded **`HELD 300 ROUNDS - HOLD 30 UNITS`** pack line. Ink is 13 px
everywhere with **zero `font_size` overrides**; captions clear 4.5:1 by measurement. The
console master is scripted (`staging/mockup/render_console_master.py`, md5
`b1241913488d4d566e4f670d33d9ca53` twice, 2720×1032); the rack and row plates retire.
Gate **877/0 → 886/0** (85 assertions added, none lost).

## Moved test numbers (old → new)
- `test_s15_armory_layout.gd`: host 1920×1080 → **1392×610** (the pinned host, so the drawn
  numbers are the design's). The plate-ink law (`INK Rect2(7,49,180,84)`, `INK_ROWS (49,132)`,
  `SLOT_PITCH 34.5`, `FIRST_SLOT_CENTRE 45`, master 194×182) **retires with the rack plate**;
  re-pinned to: console 1360×516, master 2720×1032, patches 64, bays 260×192 on a 7 gap,
  cells 117×52 at (10,34)/(133,34)/(10,92)/(133,92), ledge 240×34 at (10,150), drums 18×32 on
  a 20 pitch. Bay flow **4+1 (2 rows, tail full-width) → five across one band**.
- `test_d7_armory.gd`: same host change; `CANVAS 436×478 → 680×258`, `BLOCK 872×956 →
  1360×516`, `CONSOLE_MASTER 1744×1912 → 2720×1032`, `RACK_MASTER`/`ROW_MASTER` retired; three
  wells (`RACKS/INVENTORY/AMMO`) → **two halves** (16,286,648,220) and (696,286,648,220) in
  console space; `BAY 194×182` grid origin (44,136) gap 8 cols 4 → 260×192 band origin (16,38)
  gap 7 cols 5; slots 34×40 @ (28,62) pitch 34.5 → cells 117×52 @ (10,34) gap 6; drums 34×20 @
  (28,113) → 18×32 @ y+1 pitch 20; caption (133,113) → (74,11); rows 64/44 tall → items 320×68;
  the `SALVO %s` head line → the read-back's `salvo` field + the chip tooltip (the ledge digits
  on screen); `HELD 60 / 30` → `HELD %d ROUNDS - HOLD %d UNITS`; price `120` → `120 CR`;
  `DROP A WEAPON FROM THE INVENTORY HERE` (one head hint) → `DROP HERE` per empty cell.
- `test_p2b1_outfitting_panel.gd`: `%ArmoryRows`/`%InventoryRows` casts `VBoxContainer →
  Control` (the scroll grids are plain Controls); the retired `RacksCaption` path → the well
  captions (`BARREL INVENTORY - 0 OWNED`, `AMMUNITION - 6 PACKS`); the head `Hint` node → the
  per-cell cues; the footer caption (retired, T5) → the over-cap card's own state line.
- `test_s10_armory_input.gd`: host 1920×1080 → 1392×610; the chip's S15 34×40 slot → the P3
  **117×52** cell; +1 test (right-click pulls the barrel).
- **Unchanged and green**: `test_s11_describe.gd`, `test_s11_inspector.gd`,
  `test_s15_battery_cap.gd`, `test_s4_batteries.gd`, `test_s5_batteries_v2.gd`,
  `test_s8_qa_fixes.gd` (the last three outside this worker's file set — no edit was needed).

## PROPOSED values (with reversals)
- **T7's trigger**: the bay chip states `OVER CAP` when the battery holds the 4-cell hardcap
  (09 §12), `READY` otherwise. The tick names the chip and its shape, not its trigger.
  Reversal: the chip retires (the head goes label-only).
- **The `✕` stays a node** (13 px glyph, flat, top-right of the cell); only the *boxed chip*
  dies, because `test_s5_batteries_v2.gd` (outside my file set) presses it. The advertised
  right-click-to-pull is added beside it. Reversal: drop the node and re-point that suite.
- **The card carries four lines** (name+price / meta+state chip / the worded held line /
  state line + BUY): the mockup draws three, but §5.1's four state *lines* must stay visible
  (MED-4's lesson: a hidden line is the defect). Reversal: fold the state line into the
  inspector body.
- **The 24 px pack icon stays** (§5.1's icon column; the mockup omits it). Reversal: drop it.
- **The price's `CREDITS` caption becomes the `CR` unit word** (P5's own logic). Reversal: the
  two-line value/caption cell.

## Three-resolution verification (T1's condition)
`$GODOT_CONSOLE --path "$VAJB_PROJ" res://tests/probe_s18_resolutions.tscn --quit-after 800`
(a standalone run; the probe clears the project's window override and resizes the window):
1280×720 → canvas 1920×1080, pane host (452,204)+1392×606, console 1360×512.6, bays 260.0;
2560×1080 → canvas 2560×1080, host 1392→2032 wide, console 1985.3, bays **385.1**;
1280×1024 → canvas 1920×1536, host 606→1042 tall, console 881.4, bays 328.0 tall.
`canvas_encloses_pane=true`, `host_encloses_console=true`, every bay/well/cell `inside=true`
at all three. Raw log: `_evidence/resolutions_raw.log`.

## Deviations / judgment calls
- The mockup's console is drawn 1360×**536** (its `derive()`), while P1 and the tick sheet say
  1360×**516**: the tick wins, so the master is 2×516 = **2720×1032** (the brief's 2720×1072 is
  the 536-derived figure, reported not silently normalised).
- The mockup's own wells arithmetic draws the pack cards' second column off-canvas (measured:
  columns at x 1164 and 1844 in a console ending 1828) and the right barrel rows under them:
  the implementation gives **each half its own 2×3 grid** so all 6+6 items are visible
  (HIGH-4's "nothing hidden"), same card anatomy.
- The station's own host measures **1392×606** at 1920×1080 in the probe (the D13 capture
  reported 610): the pane's derivation absorbs it (512.6-tall console). Reported for the docs.
- The master reimport ran through `$GODOT_CONSOLE --headless --import` (this worker has no
  godot-ai MCP tools); the `.import` settings are untouched.
- Two bugs the gate could not see, found by the rendered capture and now regression-tested:
  the chips were addressed by their **W-cell index** instead of their grid slot (W5..W7 landed
  off the bay) and the chrome captions sat on the bay band; both fixed.

## Evidence
- Gate: `$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn
  --quit-after 1800` → `[SUMMARY] passed=886 failed=0` (run twice, identical).
- `python3 staging/verify_wave.py verify --baseline s18_start` → `"problems": []`, modified =
  the 7 files below, added = the 4 new files + the evidence log.
- Master: `python3 staging/mockup/render_console_master.py` twice → 2720×1032,
  md5 `b1241913488d4d566e4f670d33d9ca53` both runs.
- New suite: 8/8 (13 px floor + no overrides, ≥4.5:1 captions, P5 wording, P6 at the three
  proof canvases, T4/T7 states, the retirements, P4's two-line body, the W-index grid fix).
- Capture: `res://tests/probe_s18_capture.tscn` → `_evidence/armory_rebuilt_1920x1080.png`.

## Files touched
- `vajb-orbit/ui/station/armory_style.gd` — host-derived layout (P6), palette + roles, plates retired
- `vajb-orbit/ui/station/armory_panel.gd` — the approach-B console, cells, ledges, cards, states
- `vajb-orbit/ui/station/armory_panel.tscn` — the console tree, chrome above the plate, scroll grids
- `vajb-orbit/assets/ui/ui_armory_console.png` — the scripted 2720×1032 master (binary, gitignored)
- `staging/mockup/render_console_master.py` — the deterministic master renderer (new)
- `vajb-orbit/tests/test_s18_armory_rework.gd` (new), `probe_s18_resolutions.gd/.tscn`,
  `probe_s18_capture.gd/.tscn`
- the moved suites: `test_s15_armory_layout.gd`, `test_d7_armory.gd`,
  `test_p2b1_outfitting_panel.gd`, `test_s10_armory_input.gd`
- `docs/design/UI_SPEC.md` §3.10 **Amendment 3** (every value with its reversal),
  `docs/design/STATION_HUB.md` §5.11 amendment (lands the D13 ticks)

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| station host 1392×606 vs the docs' 610 — re-measure and amend | LOW | `docs/design/UI_SPEC.md` §3.10 A3 |
| `ArmoryStyle.drawn()/drawn_vector()/drawn_rect()` are unreferenced now | LOW | `armory_style.gd:152-162` |
| the chip plates sit ~1.2:1 on their bays (label+shape carry the state) | LOW | `armory_style.gd` chip_bg |
| the inventory half scrolls past 6 owned weapon ids (12 exist) — a scroll hint would help | LOW | `armory_panel.gd` `_lay_inventory` |
