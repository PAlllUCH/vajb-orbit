# Fix Wave 1 — W2 report (station readability, alignment, refinery buttons)

Worker: W2 (station). Brief: `.agents/gen/fix_wave1_task.md` section W2, rulings in
`docs/design/IMPLEMENTATION_PLAN.md` §9.8 items 3 (and item 5's file list). Scope held to the
three named files; no doc, theme, asset, scene-file or other script was touched.

| Item | File | Change |
|---|---|---|
| 1 | `vajb-orbit/ui/screens/station.gd` | `BACKDROP_DIM_ALPHA` 0.72 → 0.84 |
| 2 | `vajb-orbit/ui/station/outfitting_panel.gd` | header row fitted to the rows' own column grid |
| 3 | `vajb-orbit/ui/station/refinery_panel.gd` | the three action buttons share one height |

## 0. Files changed (before → after)

| File | Bytes | Lines | Note |
|---|---|---|---|
| `ui/screens/station.gd` | 21 516 → 21 516 | 618 → 618 | one constant value, same width; no byte delta |
| `ui/station/outfitting_panel.gd` | 15 627 → 19 725 | 467 → 559 | +4 098 bytes |
| `ui/station/refinery_panel.gd` | 24 124 → 24 814 | 709 → 721 | +690 bytes |

The "before" figures are reconstructed, not remembered: a helper outside the project deleted
exactly the line ranges this report added and measured the remainder, and the reconstruction was
checked by line number against the pre-edit reads (`_apply_tokens` back at 121,
`_connect_scroll` back at 324, the `_ready` body back to five lines) and by search (zero
occurrences of `GRID_CELLS`, `HEADER_FIT_RETRIES`, `_header_fit`, `_connect_layout`,
`_connect_cells`, `_queue_header_fit`, `ACTION_MIN_HEIGHT`, `_fit_action_buttons` remain in the
reconstructions). Helper: `C:/Users/Kamil/AppData/Local/Temp/w2_reconstruct.py` (outside the
project), originals at `C:/Users/Kamil/AppData/Local/Temp/w2_original/`.

## 1. Backdrop contrast — `BACKDROP_DIM_ALPHA` 0.72 → 0.84 — DONE

`station.gd:102` (was `0.72`). Grain constants untouched: `GRAIN_IDLE_ALPHA` 0.06,
`GRAIN_PEAK_ALPHA` 0.11, `GRAIN_SECONDS` 5.0 still read out of the live script's constant map,
and the live `Grain.modulate.a` was 0.0668 mid-pulse.

Rendered measurement: the probe drove the entry tween to completion
(`Tween.custom_step(1.0)` on the shell's tweens) and read the settled dim: **0.83999997** (the
float32 round-trip of 0.84). Before the change the same read settled at 0.72.

Readability of the captions over the backdrop area, measured with Pillow over the real
`assets/ui/ui_backdrop_hangar.png` (2048×1152 = 2 359 296 pixels), composited per channel with
`void_base` `#07090d` at each alpha (Godot's 2D canvas composites in sRGB space) and scored with
WCAG relative luminance:

| Ink | alpha | min | p50 | mean | max |
|---|---|---|---|---|---|
| `text_dim` `#6b7484` | 0.72 (before) | **1.80:1** | 4.20:1 | 4.14:1 | 4.30:1 |
| `text_dim` | 0.84 (after) | **2.81:1** | 4.21:1 | 4.18:1 | 4.26:1 |
| `text_primary` `#c9d1dc` | 0.72 | **5.51:1** | 12.86:1 | 12.67:1 | 13.16:1 |
| `text_primary` | 0.84 | **8.59:1** | 12.87:1 | 12.80:1 | 13.02:1 |

That is the owner's finding exactly: the median barely moves (most of the art is already dark),
but the **worst** area improves 1.80:1 → 2.81:1 for `text_dim` and 5.51:1 → 8.59:1 for
`text_primary` (+56 % both), because the brightest composited backdrop pixel falls from
(76, 77, 74) to (47, 48, 48). Script: `C:/Users/Kamil/AppData/Local/Temp/w2_contrast.py`.

## 2. OUTFITTING header alignment — DONE

### What was actually wrong (measured, not assumed)

Baseline probe (`res://tools/_probe_w2.gd`, deleted), shipping `station.tscn` in a forced
1920×1080 root, OUTFITTING active, real `PlayerProfile` (300/300 Laser Cells):

```
PROBE pane width 1440.0, scroll width 1440.0 | panel box margins L -1.0 T -1.0 R -1.0 B -1.0 | vscrollbar width 10.0 visible false
PROBE header margin (1440.0, 33.0) | header x 440.0 w 1416.0
PROBE row button x 429.0 w 1438.0 | row inner x 441.0 w 1414.0
PROBE col TitleBox  header PACK       x   492.0 | row Laser Cells x   493.0 | delta   +1.0
PROBE col Held      header HELD / MAX x  1432.0 | row 300 / 300 x  1431.0 | delta   -1.0
PROBE col Price     header PRICE      x  1574.0 | row 120       x  1573.0 | delta   -1.0
PROBE col Status    header STATUS     x  1696.0 | row AT CAP    x  1695.0 | delta   -1.0
```

Two corrections to the brief's diagnosis, and one drift the brief did not name:

1. **The scroll's `panel` stylebox carries no 5 px content margin.** Measured:
   `content_margin_left/right = -1.0`, i.e. *unset*, so the effective inset is the stylebox
   border: the rows start **1 px** inside the scroll, not 5 (`row button x 429` against a pane
   left edge of 428). `SCROLL_CONTENT_MARGIN 5.0` (`build_theme.gd:29`) is used by
   `_scroll_box()` (`:397-401`) which `_register_scroll_chrome` applies to the **VScrollBar**
   `scroll`/`grabber` boxes, not to `ScrollContainer/panel`. So the shipping-state drift was
   ±1 px (the header box is 2 px wider than the rows' box: 1416 vs 1414, which pushes the
   expand column 1 px left and the right-anchored columns 1 px right), not ~5 px.
2. **The visible drift is the HELD cell outgrowing its declared column.** With the longest
   caption (`META_ADVISORY`, "CAPACITY IS ADVISORY", reachable the moment a purchase pushes the
   hold over `ammo_max` — §5.6 "a purchase is never clamped") the HELD cell grows 130 → 143 px
   and takes the growth out of the expand column, so the HELD caption sits **14 px** right of
   its value while PRICE and STATUS stay put:

```
PROBE col Held      header HELD / MAX x  1432.0 | row 300 / 300 x  1418.0 | delta  -14.0 | cell w  143.0
```

3. A visible scrollbar (short window, or any `ui_scale` that makes 12 rows overflow) takes its
   10 px off the rows' grid, not off the header — post-fix that state measures
   `header margin box (1440.0, 33.0) L 13 R 23` against `grid x 441.0 w 1404.0`.

### Fix

`outfitting_panel.gd` now **fits the header row to the rows' own grid** instead of trusting the
declared widths (brief option 1, "give the header the same inset", taken from the live rows so it
also tracks the scrollbar and the caption growth; no theme box was touched, so W5's generator is
untouched by W2):

- `_connect_layout()` (`:341`) re-queues a fit on `_scroll.resized`, `_rows.resized`,
  `VScrollBar.visibility_changed` and `_header.resized`;
- `_connect_cells()` (`:411`, called per row from `_build_row`) re-queues it whenever a row cell
  changes shape, so a caption written by `_refresh_row` is covered too;
- `_refresh_rows()` and `NOTIFICATION_THEME_CHANGED` re-queue as well;
- `_fit_header()` (`:363`) reads the first row's grid box and sets the header's `HeaderMargin`
  left/right from the grid's own offset inside the panel (`L 13 R 13` = the 1 px scroll border
  plus `RowInner`'s 12), then sets each header cell's `custom_minimum_size.x` from the matching
  row cell's `get_combined_minimum_size().x` — the *minimum*, not the laid-out width, so the fit
  cannot read a grid that is halfway through its own re-sort. `GRID_CELLS` (`:36`) is the
  one-to-one map of `_header_cells()` onto a row grid. The fit is idempotent (bounded by
  `HEADER_FIT_RETRIES`, `:38`) and the declared widths remain the floor through the row cells'
  own `custom_minimum_size`.

### Acceptance — the four columns, measured after the fix

Same probe, same scene, forced 1920×1080 (deleted afterwards):

```
PROBE ALIGNMENT [as built (pass 1)]
PROBE pane 1440.0 | header margin box (1440.0, 33.0) L 13 R 13 | header x 441.0 w 1414.0 | scroll 1440.0 box margins L -1.0 R -1.0 | bar 10.0 visible false
PROBE row button x 429.0 w 1438.0 | row grid x 441.0 w 1414.0
PROBE col TitleBox  header PACK       x   493.0 w  926.0 min  145.0 | row Laser Cells x   493.0 | delta   +0.0
PROBE col Held      header HELD / MAX x  1431.0 w  130.0 min  130.0 | row 300 / 300 x  1431.0 | delta   +0.0
PROBE col Price     header PRICE      x  1573.0 w  110.0 min  110.0 | row 120       x  1573.0 | delta   +0.0
PROBE col Status    header STATUS     x  1695.0 w  160.0 min  160.0 | row AT CAP    x  1695.0 | delta   +0.0
```

All four columns are **+0.0** in every state the probe could reach, at 1920×1080:

| State | Deltas (PACK / HELD / PRICE / STATUS) |
|---|---|
| as built, pass 1 | 0.0 / 0.0 / 0.0 / 0.0 |
| as built, pass 2 (stability, 4 frames later) | 0.0 / 0.0 / 0.0 / 0.0 |
| longest HELD caption "CAPACITY IS ADVISORY" (HELD cell 130 → 143) | 0.0 / 0.0 / 0.0 / 0.0 |
| caption restored (HELD back to 130, no sticky width) | 0.0 / 0.0 / 0.0 / 0.0 |
| scrollbar forced visible (bar 10 px, grid 1414 → 1404, margin R 13 → 23) | 0.0 / 0.0 / 0.0 / 0.0 |
| scrollbar hidden again (grid back to 1414) | 0.0 / 0.0 / 0.0 / 0.0 |

The caption-growth and scrollbar states are the two the declared-inset fix alone could not hold
(1 px and 10 px/14 px respectively); the fit holds both, and it reverts exactly when the row does
(no accumulated width).

### Probe

`res://tools/_probe_w2.gd` (`extends SceneTree`, `quit()`-terminated) loaded
`res://ui/screens/station.tscn` into a forced 1920×1080 root, drove the entry tweens to settle,
then printed the backdrop constants/settled alpha, the scroll box margins and scrollbar, the
header/row geometry and the four column pairs in six states, then the REFINERY rects. **Deleted
with its `.uid`**; `tools/` holds `build_theme.gd` and `derive_icon_tints.gd` (+ their `.uid`)
again. (`tools/_probe_w3.gd` is the parallel W3 worker's probe, not this one's.)

## 3. REFINERY action buttons — DONE

Baseline (same probe, REFINERY selected): widths were already shared (all three are children of
`RefineBox`, a 360 px `VBoxContainer`), the defect was the height:

```
PROBE RefineBox x 1508.0 w 360.0, column (360.0, 0.0)
PROBE RefineButton    size (360.0, 88.0)
PROBE RefineAllButton size (360.0, 56.0)
PROBE CancelButton    size (360.0, 56.0)
```

After the fix (`refinery_panel.gd`):

```
PROBE RefineButton    text REFINE 1      global x 1508.0 y 676.0 size (360.0, 88.0) min (92.0, 88.0)
PROBE RefineAllButton text REFINERY ALL  global x 1508.0 y 776.0 size (360.0, 88.0) min (145.0, 88.0)
PROBE CancelButton    text CANCEL        global x 1508.0 y 876.0 size (360.0, 88.0) min (84.0, 88.0)
```

Same `size.x = 360.0` (full width of the control column) and same `size.y = 88.0` for all three,
on the same axis (`global x 1508.0`), 100 px apart (88 + the 12 px `RefineBox` separation). The
shared height is applied in code — `ACTION_MIN_HEIGHT := 88.0` (`:57`) and `_fit_action_buttons()`
(`:189`, called from `_ready`) — because the scene file is not in this wave's file list. No
styling, text, disable logic or handler changed: the emphasis ruling ("primary plates vs CANCEL")
is kept as it is, the size mismatch is what moved. 88 px is the primary height STATION_HUB §5.7
gives `REFINE N` ("the LaunchButton height"), so the two secondary plates were raised to the
primary rather than the primary being shrunk.

## 4. Verification runs

Changed scripts, the brief's parse check (run per file):

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://ui/screens/station.gd
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://ui/station/outfitting_panel.gd
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://ui/station/refinery_panel.gd
```

All three exit 1 with **no parse errors** — the message is `Compile Error: Identifier not found:
Router` / `AudioManager` (station.gd:167, outfitting_panel.gd:422, refinery_panel.gd:460), which
is `--check-only`'s known inability to resolve autoload singletons, not a defect in these files.
Control run in the same invocation, on a file this wave did not touch:

```
--check-only --script res://ui/station/exchange_panel.gd
SCRIPT ERROR: Compile Error: Identifier not found: AudioManager
   at: GDScript::reload (res://ui/station/exchange_panel.gd:583)
```

So the check discriminates parse errors only; the compile evidence is the two runs below.

Whole station, 180 frames, autoloads live (the shell instantiates and builds every panel,
`station.gd` + both changed panels included):

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after 180 res://ui/screens/station.tscn
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
exit 0
```

No `SCRIPT ERROR`, `push_error` or `push_warning` line; exit 0.

P1 regression suite (the 53-test headless suite the docs treat as the project's gate):

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn
[SUMMARY] passed=53 failed=0
```

## 5. Deviations and open points

1. **The brief's 5 px inset is 1 px in the shipped theme** (scroll `panel` box content margins
   are `-1.0`; the 5 px `SCROLL_CONTENT_MARGIN` belongs to the VScrollBar boxes). Measured, not
   argued; the fix targets the real numbers.
2. **The fix is the brief's option 1 taken from the live rows, not a hardcoded number and not a
   stylebox override.** A fixed inset (the brief's other option) can only match one of the three
   geometries: the 1 px border, the visible scrollbar, and a row cell that outgrows its column.
   No budget was spent on the theme box, so §9.8's "do not change the global theme box" holds by
   construction rather than by promise. If a reviewer prefers the literal stylebox override, note
   that it removes only the 1 px and leaves the 14 px caption drift this report measured.
3. **STATION_HUB §5.7 now contradicts the shipping panel where it says `REFINERY ALL` (56 px)
   and `CANCEL` (56 px)**; §9.8 item 3 ("share one size") is the later ruling and wins, but the
   doc text should be amended by its owner — this wave may not edit `docs/`.
4. **Contrast is measured, not seen.** Headless has no renderer, so item 1's acceptance is the
   settled constant plus the composited contrast table over the real backdrop art (§1). No screen
   pixel was inspected, and the Godot editor was not launched or driven (a game may be running).
   The subjective "reads clearly" call belongs to the owner or W6.
5. `HEADER_FIT_RETRIES 8` is the only new tuning number: a panel whose host has not laid it out
   yet re-queues the fit for 8 frames and then relies on the layout signals, so an unlaid-out
   panel cannot queue a deferred call forever.
6. Nothing else changed in the three files: no strings, no colours, no hex literals, no
   per-node font sizes, no scroll/wiring behaviour, no `MenuButton`-style deletions, and the
   `AudioManager` cues, `status_requested` wording, fee math and profile writes are untouched.
