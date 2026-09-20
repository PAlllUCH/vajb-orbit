# D4c report - main menu v2 mockup, final revision (scale + emblem)

Date: 2026-09-18. Worker: designer (medium: a live Godot 4.7 UI scene).
Brief: `.agents/gen/d4c_task.md`. Predecessors: `.agents/gen/d4b_report.md`,
`.agents/gen/d4_report.md`. Spec: `docs/design/MAIN_MENU_V2.md` (sections 12 and 15 are new).

---

## 1. What was built and what changed

| Action | Path | Size |
|---|---|---|
| edited in place | `vajb-orbit/ui/screens/_mockup_main_menu.tscn` | 10390 bytes, 352 lines (was 10325 / 350) |
| edited in place | `vajb-orbit/ui/screens/_mockup_main_menu.gd` | 12425 bytes, 334 lines (was 10948 / 307) |
| updated | `docs/design/MAIN_MENU_V2.md` | 61133 bytes, 799 lines (new sections 12.1 and 15) |
| created | `.agents/gen/previews/d4c_menu_v2_1920x1080.png` | 3143884 bytes, frame 59 of the `ui_scale` 1.0 movie |
| created | `.agents/gen/previews/d4c_menu_v2_1920x1080_uiscale120.png` | 3146190 bytes, frame 59 of the `ui_scale` 1.2 movie |
| created | `.agents/gen/previews/d4c_menu_v2_1920x1080_uiscale140.png` | 3149623 bytes, frame 59 of the `ui_scale` 1.4 movie |
| created | `.agents/gen/previews/d4c_menu_v2_1600x900.png` | 2915380 bytes, window client capture at 1600 x 900 |
| created | `.agents/gen/previews/d4c_menu_v2_1920x1080_preview.jpg` | 165595 bytes, 1152 x 648 downscale for eyeballing |
| created | `.agents/gen/previews/d4c_tools.py` | 15139 bytes, settings + measurement tool (method record) |
| created | `.agents/gen/previews/d4c_probe_rects.gd` | 5194 bytes, engine rect-dump probe (method record) |
| created | `.agents/gen/previews/d4c_paths.py` | 3975 bytes, `res://` path check + static audit |
| created | `.agents/gen/previews/d4c_crop.py`, `d4c_art.py` | 572 / 2368 bytes, crop and art-inspection helpers |
| created | `.agents/gen/d4c_report.md` | this file |

Changed in the scene, in full (four values):

1. `PlayButton`, `OptionsButton`, `ExitButton` `custom_minimum_size`: `(280, 56)` -> `(350, 70)`.
2. `InsigniaBadge` `custom_minimum_size`: `(40, 46)` -> `(50, 58)`, plus
   `unique_name_in_owner = true` so the script can reach it.
3. `PlayTick`, `OptionsTick`, `ExitTick` `custom_minimum_size`: `(6, 48)` -> `(6, 60)`.
4. `FocusReadout` gained `theme_type_variation = &"HudReadout"` (the 18 px readout item).

No node, container, separation, anchor, offset, colour, texture or `load_steps` changed. The
scene still has 11 load steps and the same node tree.

Changed in the script, in full (six items):

1. Two constants: `EMBLEM_BRIGHTEN = 2.0`, `PLATE_MIN_HEIGHT = 70.0`.
2. `@onready var _badge: TextureRect = %InsigniaBadge`.
3. `_ready()` applies `_badge.modulate = Color(EMBLEM_BRIGHTEN, EMBLEM_BRIGHTEN, EMBLEM_BRIGHTEN, 1.0)`
   and calls `_sync_plate_minimum()` after `_verbs` is filled.
4. New `_notification(what)`: on `NOTIFICATION_THEME_CHANGED` (guarded by `not _verbs.is_empty()`)
   it re-derives the plate minimum, deferred.
5. New `_sync_plate_minimum()`: sets each plate's `custom_minimum_size.y` to
   `maxf(PLATE_MIN_HEIGHT, inner_button.get_minimum_size().y)`.
6. The file header comment now lists four runtime-built things instead of three.

Not touched: the theme, `tools/build_theme.gd`, `router.gd`, `project.godot`, `addons/`,
`menu_button.tscn`, `main_menu.tscn`, `main_menu.gd`, the parallel designer's `_mockup_station.*`.
`Router.FONT_SIZE_ITEMS` is still 27 and the theme's item count is unchanged: the read-out's
growth is an item *selection* (`Label` -> `HudReadout`), not a new item and not an override.

---

## 2. Commands run, with their output

### 2.1 Mandated headless check (final state, after the last constant change)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_main_menu.tscn --quit-after 300
```

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT=0
```

Run twice: once after the first round of edits and once after `EMBLEM_BRIGHTEN` was settled at
2.0. Exit code 0 and the same two lines both times. The second line is the vendored
`addons/godot_ai/` autoload, which every scene in this project emits (the D4b control run
attributed it); the mockup prints nothing of its own and the script contains no `print`.

### 2.2 Renders

`--write-movie` records the root viewport, so the three movies are exactly the design target.

```
py -3.14 ".agents/gen/previews/d4c_tools.py" set 1920 1080 1.0
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --scene res://ui/screens/_mockup_main_menu.tscn --write-movie "C:/Users/Kamil/AppData/Local/Temp/vajb_d4c/t20.png" --quit-after 60
```

```
Movie Maker mode enabled, recording movie in 1920×1080 @ 60 FPS...
Done recording movie at path: C:/Users/Kamil/AppData/Local/Temp/vajb_d4c/t20.png
60 frames at 60 FPS (movie length: 00:00:01:00), recorded in 00:00:43 (2% of real-time speed).
EXIT=0
```

The same command produced `s12.png` (`ui_scale` 1.2) and `s14.png` (`ui_scale` 1.4), 60 frames
each, 43 s each, exit 0. Frame 59 of each movie is the settled state (the entrance ends at
0.86 s = frame 52) and is the deliverable frame.

Four 1920 x 1080 movies were rendered in total: `f1920.png` at `EMBLEM_BRIGHTEN` 1.35 (the
middle column of section 4.3, not a deliverable), `t20.png` at 2.0 (the chosen value, and the
source of `d4c_menu_v2_1920x1080.png`), `s12.png` and `s14.png` at `ui_scale` 1.2 and 1.4.

1600 x 900: the movie writer always records the root viewport (1920 x 1080 under `canvas_items`
stretch, verified in D4b), so the geometry capture is a live window instead:

```
py -3.14 ".agents/gen/previews/d4c_tools.py" set 1600 900 1.0
py -3.14 ".agents/gen/previews/d4b_probe.py" 1600 900 "C:/Users/Kamil/AppData/Local/Temp/vajb_d4c/w1600x900.png"
```

```
launch ...Godot_v4.7.2-stable_win64.exe --path .../vajb-orbit --position 60,60 --always-on-top --resolution 1600x900 res://ui/screens/_mockup_main_menu.tscn
client 60,60 1600x900
saved C:/Users/Kamil/AppData/Local/Temp/vajb_d4c/w1600x900.png bytes=2915380
```

### 2.3 Engine rect dump (ground truth for the geometry)

A scratch probe was written to `user://d4c_probe_rects.gd` (outside the project tree), run with:

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script user://d4c_probe_rects.gd
EXIT=0
```

It instantiates the mockup at 1920 x 1080 and prints every relevant `Control` rect four times,
re-assigning a theme scaled exactly the way `Router._scale_font_sizes()` scales it
(`roundi(base * scale)` over the eight items this screen uses, `default_font_size` included).
Re-assigning the theme also fires `NOTIFICATION_THEME_CHANGED`, so the mockup's own
`_sync_plate_minimum()` runs between the dumps: the numbers below are the shipping behaviour,
not a static reading. The probe file was deleted after the run.

### 2.4 Measurements

Every number in sections 3 to 5 comes from these five commands, run against the four saved
frames (`elements`, `plates`, `border`, `emblem`, `offscreen`), plus one ad-hoc window for the
verb labels. `py -3.14` with Pillow and NumPy; contrast is WCAG relative luminance
`(L1 + 0.05) / (L2 + 0.05)` computed from rendered pixels, and "luma" is the weighted sRGB mean
(0..255) used as a brightness locator.

Note on the shell rules: no command used unquoted parentheses, backticks, `&&`, `>` or `<`. The
only parentheses in any command are inside double-quoted `py -3.14 -c "..."` snippets, which the
shell passes through literally; the longer helpers were written to files in
`.agents/gen/previews/` and run as scripts instead.

---

## 3. Geometry, engine-verified

Abridged rect dump (`.agents/gen/previews/d4c_probe_rects.gd`, `user://`, deleted after use):

```
== ui_scale 1.0 == viewport (1920.0, 1080.0)
  fonts: MenuButtonPlate 34 HudReadout 18 Label 14 Version 13
  MiddleBand       pos (0.0, 176.0)   size (1728.0, 766.0)
  CommandColumn    pos (0.0, 227.0)   size (372.0, 312.0)  global [P: (96.0, 467.0), S: (372.0, 312.0)]
  CommandHeader    pos (0.0, 0.0)     size (372.0, 58.0)   min (72.0, 58.0)
  InsigniaBadge    pos (22.0, 0.0)    size (50.0, 58.0)    global [P: (118.0, 467.0), S: (50.0, 58.0)]
  VerbStack        pos (0.0, 74.0)    size (372.0, 238.0)  global [P: (96.0, 541.0), S: (372.0, 238.0)]
  PlayRow          pos (0.0, 0.0)     size (372.0, 70.0)   global [P: (96.0, 541.0), S: (372.0, 70.0)]
  PlayTick         pos (0.0, 5.0)     size (6.0, 60.0)     global [P: (96.0, 546.0), S: (6.0, 60.0)]
  PlayButton       pos (22.0, 0.0)    size (350.0, 70.0)   global [P: (118.0, 541.0), S: (350.0, 70.0)]
    Button         pos (0.0, 0.0)     size (350.0, 70.0)   min (82.0, 47.0)  font 34
  OptionsRow       pos (0.0, 84.0)    size (372.0, 70.0)   global [P: (96.0, 625.0), S: (372.0, 70.0)]
  ExitRow          pos (0.0, 168.0)   size (372.0, 70.0)   global [P: (96.0, 709.0), S: (372.0, 70.0)]
  FooterBand       pos (0.0, 942.0)   size (1728.0, 26.0)  global [P: (96.0, 1006.0), S: (1728.0, 26.0)]
  FocusReadout     pos (0.0, 0.0)     size (1604.0, 26.0)  min (219.0, 26.0)
  VersionLabel     pos (1628.0, 4.0)  size (100.0, 18.0)   global [P: (1724.0, 1010.0), S: (100.0, 18.0)]
  rows tops 541.0 / 625.0 / 709.0, row heights 70.0 70.0 70.0
  stack pitch 84.0 and 84.0, visible gap 14.0 and 14.0
  plate min (350.0, 70.0), inner Button font-driven min (82.0, 47.0), inner Button rect pos (0.0, 0.0) size (350.0, 70.0)
== ui_scale 1.2 == fonts: MenuButtonPlate 41 HudReadout 22 Label 17 Version 16
  CommandColumn global [P: (96.0, 464.0), S: (372.0, 312.0)]
  rows tops 538.0 / 622.0 / 706.0, row heights 70.0 70.0 70.0, visible gap 14.0 and 14.0
  FooterBand global [P: (96.0, 1001.0), S: (1728.0, 31.0)]
  inner Button font-driven min (99.0, 57.0), inner Button rect pos (0.0, 0.0) size (350.0, 70.0)
== ui_scale 1.4 == fonts: MenuButtonPlate 48 HudReadout 25 Label 20 Version 18
  CommandColumn global [P: (96.0, 462.0), S: (372.0, 312.0)]
  rows tops 536.0 / 620.0 / 704.0, row heights 70.0 70.0 70.0, visible gap 14.0 and 14.0
  FooterBand global [P: (96.0, 997.0), S: (1728.0, 35.0)]
  inner Button font-driven min (116.0, 67.0), inner Button rect pos (0.0, 0.0) size (350.0, 70.0)
== ui_scale 2.0 == fonts: MenuButtonPlate 68 HudReadout 36 Label 28 Version 26
  rows tops 494.0 / 601.0 / 708.0, row heights 93.0 93.0 93.0, visible gap 14.0 and 14.0
  plate min (350.0, 93.0), inner Button font-driven min (164.0, 93.0)
```

### 3.1 The row-height rule, proved

| Measure | 1.0 | 1.2 | 1.4 | 2.0 |
|---|---|---|---|---|
| inner `Button` font-driven minimum height | 47 | 57 | 67 | 93 |
| plate minimum height (`max(70, ...)`) | 70 | 70 | 70 | 93 |
| row height | 70 | 70 | 70 | 93 |
| stack pitch | 84 | 84 | 84 | 107 |
| visible gap between plates | 14 | 14 | 14 | 14 |
| inner `Button` rect (pos, size) | (0, 0), 350 x 70 | (0, 0), 350 x 70 | (0, 0), 350 x 70 | (0, 0), 350 x 93 |

At 1.0, 1.2 and 1.4 the font-driven minimum is below the 70 px floor, so the plate is 70 px and
the `Button` fills it at offset 0: the D4b defect (a 280 x 67 `Button` at offset -5.5 inside a
56 px row) is gone. At 2.0 the font's minimum (93) overtakes the floor, the row grows to 93 and
the separation is still 14 px: the row height follows the font, not a constant. `ui_scale` 2.0
is outside the brief's required range and is included only as that proof.

### 3.2 What moved and what stayed

- Stayed: safe margins (96 / 64 / 96 / 48), row separation 14, row-internal separation 16,
  console separation 16, footer separation 24, gutter (6, 0), plate width 350, tick (6, 60),
  emblem (50, 58), logo (560, 176).
- Moved: the column 5 px up (467 -> 464 -> 462) because the footer band grows with the
  read-out's item (26 -> 31 -> 35 px), and the middle band shrinks to match (766 -> 761 -> 757).
- The column's centre stays on the middle band's centre at every scale, which is the placement
  rule the brief asked to preserve; the verb rows sit 18 px higher than in D4b because the
  column is 54 px taller (58 + 16 + 238 against 46 + 16 + 196) and still centres.

---

## 4. Measurements on the rendered frames

### 4.1 Each plate's box, and the border run

The focus ring is the only exact 1 px border on a plate. Measured by exact token match
(`accent_danger_bright`, tolerance 6) on the three movie frames:

| Scale | Plate 1 box (from the ring) | Ring runs, column at mid-plate x | Ring runs, row at mid-plate y |
|---|---|---|---|
| 1.0 | x 118..467, y 541..610 (350 x 70) | `[(541, 541), (610, 610)]` | `[(118, 118), (467, 467)]` |
| 1.2 | x 118..467, y 538..607 (350 x 70) | `[(538, 538), (607, 607)]` | `[(118, 118), (467, 467)]` |
| 1.4 | x 118..467, y 536..605 (350 x 70) | `[(536, 536), (605, 605)]` | `[(118, 118), (467, 467)]` |

Every run is exactly one pixel on all four sides at all three scales, and the ring's neighbours
measure backdrop (luma 12 to 27) or plate art, i.e. the ring is not a two-pixel smear. Full
profiles are in the tool output (`.agents/gen/previews/d4c_tools.py border`).

**The brief's premise about the nine-patch does not hold for the plate, and this is worth
knowing before the shipping scene is built.** The theme's plate `StyleBoxTexture`s
(`vajb_theme.tres` sub-resources `StyleBoxTexture_2hfjh` / `_4vp6j` / `_ryiqy` / `_k1wit`) carry
`texture` only: no `texture_margin_*`, so the art is drawn as one stretched quad, not a
nine-patch. The theme's only nine-patch is the panel frame (`StyleBoxTexture_0g3d5`, 8 px
margins), which this screen does not use. Consequence, measured: the art's painted bevel band
is 5 rows in the 280 x 56 source and 7 rows at 350 x 70 (mean luminance profile across the top
edge at mid-width: 42.8 / 82.8 / 93.0 / 82.6 / 92.1 / 95.8 / 81.6 / 49.5 at 1.0, identical at
1.4). If the painted bevel is ever required to keep its authored thickness, the fix is patch
margins on the theme's plate styleboxes or a plate art re-authored at 350 x 70; the mockup does
not fake it with a runtime stylebox override, because that would make the mockup's plates
differ from the theme's.

### 4.2 The separation at 1.0 / 1.2 / 1.4

Row-mean luminance profile of the console column (x 104..479, threshold 35) on each frame. Each
plate appears as four bands (focus ring 1 row, art 56 rows, lower bevel 5 rows, focus ring
1 row); the backdrop rows between two plates are the separation:

| Scale | Row tops | Row height | Pitch | Rows of backdrop between plate 1 and 2 | Between 2 and 3 |
|---|---|---|---|---|---|
| 1.0 | 541 / 625 / 709 | 70 | 84 | 14 (y 611..624) | 14 (y 695..708) |
| 1.2 | 538 / 622 / 706 | 70 | 84 | 14 (y 608..621) | 14 (y 692..705) |
| 1.4 | 536 / 620 / 704 | 70 | 84 | 14 (y 606..619) | 14 (y 690..703) |

The separation is visually constant at 14 px at all three scales, which is the requirement. In
D4b the same measurement read 14 px at 1.0 and 5 px at 1.4.

The tick: 6 x 60 at x 96..101, y 546..605 at 1.0, y 543..602 at 1.2, y 541..600 at 1.4, i.e.
centred in its 70 px row at every scale (`v = 4`).

### 4.3 The emblem, before and after

Source art `ui_insignia_neutral.png` (780 x 894): ink (alpha > 40) median luminance 34.5, mean
37.9, mean rgb `#252525`. The art is dark; that is the cause of the "dark blob".

Measured against the actual backdrop-plus-grain behind the badge (median of the region's
non-ink pixels, luminance 23.6 at 1.0), badge at 50 x 58:

| Measure | Before (D4b frame, 40 x 46, no multiplier) | Test at `EMBLEM_BRIGHTEN` 1.35 | Chosen at 2.0 |
|---|---|---|---|
| Peak highlight luminance | 204.0 | 255.0 (clipped) | 255.0 (clipped) |
| Peak contrast | 11.21:1 | 17.82:1 | **17.81:1** |
| p90 ink contrast | 9.15:1 | 10.77:1 | **8.86:1** |
| Footprint median luminance | 26.4 | 43.4 | **63.6** |
| Footprint median contrast | 1.05:1 | 1.27:1 | **1.76:1** |
| Ink pixels clearing 4.5:1 | 18 of 99 (18.2 %) | 52 of 434 (12.0 %) | 132 of 1411 (9.4 %) |

Reading of that table:

1. **The gate the brief set is met, and it was already met before.** The emblem's highlights
   measure 17.81:1 peak and 8.86:1 at the p90 ink against the real backdrop-plus-grain, well
   above 4.5:1. The D4b frame's own measurement was 11.21:1 peak, so "its highlights clear
   4.5:1" was never the failing part.
2. **What fails is the body, and no multiplier fixes it.** The art's rendered body is dark
   (footprint median 26.4 luma before, 63.6 after: a 2.4x lift). 4.5:1 against this backdrop
   needs 127.8 luma, i.e. a further 4.2x on top of the 2.0 already applied (about 8.4x in
   total) for the footprint median, and about 19x more for the darker half of the art (about
   38x in total). At either the highlights and mid-tones clip to white and the stamp flattens
   into a white shape. The multiplier is a linear multiply, so it cannot lift the body without
   lifting the highlights by the same factor.
3. **2.0 is the chosen value** because it is the largest tested value that still reads as a
   stamp rather than a white shape: at 2.0 the hexagon's facets and the grain inside it are
   still visible in the crop (`.agents/gen/previews/` has the 1920 x 1080 frame; the 5x crops
   used for the judgement are in the D4c temp dir). At 1.35 the rim brightens but the body
   stays at 43 luma, which is close to the D4b look the owner rejected.
4. **No theme token reaches the target.** Every `Tokens` colour is a dimmer: `text_primary` is
   (0.79, 0.82, 0.86), `text_dim` (0.42, 0.45, 0.52), `void_base` (0.03, 0.04, 0.05). Using any
   of them as a `modulate` darkens the art instead of brightening it, so the value used is a
   documented multiplier on white (`EMBLEM_BRIGHTEN = 2.0`), which introduces no colour. No
   panel, frame, glow or second texture was added behind the stamp.
5. **The shortfall, stated plainly.** The emblem's highlights clear the floor with 13.3 points
   of headroom at the peak and 4.4 at the p90; its footprint median is 1.76:1 and cannot be
   brought to 4.5:1 by any `modulate` (it would need about 8.4x in total, and the darker half
   of the art about 38x, at which point the stamp is a white shape). The real fix is an art
   pass on the insignia (a brighter asset, plus the C3 defringe pass in audit recommendation
   4). The multiplier also clips the C3 white matte fringe to 255, which is harmless while the
   fringe is an artifact but must not be mistaken for a highlight once the asset is defringed.
6. **The "ink pixels clearing 4.5:1" row is not comparable across the three columns.** Its
   denominator is the set of pixels at or above 60 luma inside the ink box, and that box both
   grew (40 x 46 -> 50 x 58) and changed sampling (the art is now drawn at 50 x 58 from a
   780 x 894 source). The D4b number is also clipped by the measurement region at y 540. The
   peak, p90 and footprint-median rows are the comparable ones.

### 4.4 The read-out, the stamp and the verb labels

| Text | Ink box at 1.0 | Ink box at 1.2 | Ink box at 1.4 | Contrast at 1.0 / 1.2 / 1.4 |
|---|---|---|---|---|
| `FocusReadout` (18 px `HudReadout`) | (97, 1013, 314, 1026) | (98, 1009, 362, 1025) | (98, 1006, 398, 1024) | 12.08 / 12.08 / 12.07 : 1 |
| `VersionLabel` (13 px `Version`, `text_primary` override) | (1724, 1015, 1823, 1027) | (1701, 1011, 1823, 1026) | (1685, 1008, 1823, 1025) | 11.89 / 11.89 / 11.88 : 1 |
| Verb labels (34 px `text_primary`) | window x 210..330, y 545..600 | shifted with the row | shifted with the row | 7.85 / 7.85 / 7.85 : 1 |
| Wordmark art | (99, 61, 693, 235) | same | same | 16.08:1 at the highlights |
| Tick (exact token pixels) | x 96..101, y 546..605 | x 96..101, y 543..602 | x 96..101, y 541..600 | 5.47:1 against the backdrop |

The read-out grew 1.286x in width (169 -> 217 px) and 1.30x in height (10 -> 13 px) for a 1.286x
font item; its contrast is unchanged because `HudReadout`'s `font_color` is `text_primary`, the
same token the base `Label` item carried. The stamp's right edge stays on the safe margin at
1.4 (x 1822 against 1824). The verb labels cannot be isolated by a luminance threshold: the
plate art's rivet highlights are as bright as `text_primary` (a threshold-150 box fills the
whole window at every scale), so the label contrast is measured on a window whose ink is the
brightest 2 % (208.1 luma, exactly `#c9d1dc`) against the plate metal behind it (53.9 luma).
D4b measured the same label at 8.10:1 against a 51.9 background with the plate art at 1:1; the
small difference is the art's different sampling behind the glyphs, not a type change (the
`MenuButtonPlate` item is 34 px at 1.0 in both passes).

### 4.5 Composition at 1600 x 900 (geometry capture)

Every element is present, complete and inside the frame; the whole layout is the 1920 x 1080
layout multiplied by 0.8333:

| Element | 1920 x 1080 | 1600 x 900 (measured) | Ratio |
|---|---|---|---|
| Left safe margin | 96 | 80 | 0.833 |
| Emblem ink | (119, 468, 167, 522) | (99, 390, 139, 436) | 0.833 |
| Plate 1 band | x 118..467 | x 98..389 | 0.833 |
| Tick | (96, 546, 102, 606) | (80, 455, 85, 505) | 0.833 |
| Read-out ink | (97, 1013, 314, 1026) | (81, 845, 262, 855) | 0.833 |
| Stamp ink | (1724, 1015, 1823, 1027) | (1437, 845, 1520, 856) | 0.833 |

Off-screen check: the four frame edges measure mean luminance 20.9 / 19.0 / 20.8 / 21.9 (top /
bottom / left / right), i.e. the vista, not content. Pixels at or above 120 luma span rows
49..854 and columns 80..1585: the left extent is the safe margin (96 x 0.8333 = 80), the top
and bottom extents are the logo and the footer text, and the right extent is the backdrop's own
wreck highlights, not UI. No element is clipped, none overlaps another, and the stamp keeps its
right safe margin (1600 - 1520 = 80 px).

**Caveat, carried over from D4b and still true:** a window capture's absolute luminance is not
the engine's (bright ink reads higher there than in a movie frame), so this frame is used for
geometry only. Every contrast number in this report comes from the movie frames.

**Grain caveat, measured:** plate 1's threshold-60 ink box reaches y 535, six rows above the
plate, because the film grain has a one-pixel speckle at (351, 535) with luminance 69.5 in a row
whose mean is 20.7. It is grain, not content: the same rows measure 20.5 to 23.7 mean, and
plate 2's and plate 3's boxes start exactly on their plate edges.

---

## 5. Asset verification

`py -3.14 .agents/gen/previews/d4c_paths.py` extracts every `res://` path (and every bare
`assets/...`, `ui/...`, `tools/...` path) from the spec, the scene and the script and resolves
each against `vajb-orbit/`:

```
== spec (MAIN_MENU_V2.md): 15 distinct paths, missing: 0
== scene (_mockup_main_menu.tscn): 8 distinct paths, missing: 0
== script (_mockup_main_menu.gd): 0 distinct paths, missing: 0
TOTAL MISSING: 0
```

The resolved set: `res://ui/theme/vajb_theme.tres`, `res://ui/theme/grain.tres`,
`res://ui/components/menu_button.tscn`, `res://ui/screens/_mockup_main_menu.tscn` (+ `.gd`),
`res://assets/env/env_menu_bg.png`, `res://assets/fx/fx_ember_pulse.png`,
`res://assets/ui/logo_vajb_orbit.png`, `res://assets/ui/ui_insignia_neutral.png`,
`res://assets/ui/ui_button_plate_{normal,hover,pressed,disabled}.png`,
`res://assets/ui/ui_backdrop_login.png`, `res://assets/audio/music/mus_menu_theme_01.ogg`,
`res://assets/audio/ui/ui_{hover,click,confirm_01,scroll_01}.ogg`, `res://tools/build_theme.gd`.
`ui_panel_frame.png` still exists on disk and is still deliberately unreferenced by this screen.

---

## 6. `user://settings.cfg` round trip

Patched for the renders (windowed mode, 1920 x 1080 and 1600 x 900, `ui_scale` 1.0 / 1.2 / 1.4)
from a byte copy taken before anything ran, then restored:

```
before   sha256 edb17b3fcf9c3b29720a7590dade2de3262cfbb78699bb78a239fcc9dd233617
         display_mode=1, resolution=Vector2i(2560, 1440), ui_scale=1.0
during   display_mode=0, resolution Vector2i(1920, 1080) / Vector2i(1600, 900),
         ui_scale 1.0 / 1.2 / 1.4 (the patched states are printed by the `set` command)
after    sha256 edb17b3fcf9c3b29720a7590dade2de3262cfbb78699bb78a239fcc9dd233617
```

The file is byte-identical to how it was found. The scratch probe was written to `user://` and
deleted after its run, together with the trivial `user://` script used to confirm that
`--script user://...` works; nothing else in the app data directory was touched.

---

## 7. Static audit of the two edited files

```
tscn: 352 lines, 10390 bytes, LF line endings (as found)
gd:   334 lines, 12425 bytes, CRLF line endings (as found; the rest of the project is LF)
hex literals anywhere (scene + script): []
Color() literals in the scene: Color(1,1,1,0.25), Color(1,1,1,0.08), Color(1,1,1,0) x3
  (white-with-alpha for opacity only, the same pattern the Phase C menu uses)
Color() literals in the script: Color(EMBLEM_BRIGHTEN, ...) and Color(token.r, token.g, token.b, alpha)
  (a white multiplier and a token alpha; no colour is introduced)
func _process in the script: False
add_theme_font_size_override in the script: False
add_theme_color_override calls: 1 (the stamp's font_color, read from Tokens/text_primary)
class_name / autoload / Router / get_node("/root/... in the script: none
  (the word "class_name" appears once, in the header comment saying there is none)
theme_type_variation in the scene: DialogTitle, HudReadout, Version
unique_name_in_owner nodes: 19; %refs in the script: 19, all of them existing
custom_minimum_size values in the scene: (350, 70), (50, 58), (6, 60), (6, 0), (560, 176), (420, 0)
separations in the scene: 0, 8, 12, 14, 16, 24 (unchanged set)
load_steps: 11
```

Line endings were checked because the two files differ: a scratch test confirmed that the edit
tool preserves a file's existing endings (a CRLF file edited stayed CRLF, the LF scene stayed
LF), so neither file's convention was changed by this pass. The script's CRLF is inherited from
the D4b pass and is worth normalising to LF when the mockup is replaced by the shipping screen.

---

## 8. What could not be verified, and what limits the evidence

1. **The 1600 x 900 frame is a window capture, not a movie frame.** `--write-movie` records the
   root viewport, which stays 1920 x 1080 under `canvas_items` stretch, so its geometry is
   exact but its luminance is not the engine's. Section 4.5 uses it for geometry only.
2. **Only plate 1's rect is directly measurable.** The focus ring draws only the focused
   `Button`, and only PLAY is focused in a render. Plates 2 and 3 are inferred from the
   identical component (same font item, same row) plus the measured pitch (84) and gap (14),
   which agree with a 70 px plate; the engine rect dump prints all three rows at 70 px.
3. **4:3 and 21:9 were not re-rendered.** The container structure is unchanged and the D4b
   reasoning in section 3.2 of the spec still holds; only the console column's width changed
   (372 instead of 302), which the extra-width case absorbs in `MiddleSpacer` exactly as before.
4. **Motion, focus traversal, hover, press and the Esc stand-in were not driven.** The movie
   writer cannot inject input and no interaction was scripted. The motion table is unchanged
   from D4b (same durations, curves and triggers), and the emblem's `modulate` is set once in
   `_ready()` so it does not interact with the entrance tween that animates `CommandHeader`'s
   `modulate:a`.
5. **The emblem's body cannot reach 4.5:1** by any `modulate` value, for the reason measured in
   section 4.3. This is a limitation of the asset, not of this pass.
6. **The C3 white matte fringe is still in the art** and the 2.0 multiplier clips it to 255.
   The emblem's highlight numbers are measured on the fringe as it currently is.
7. **The `godot-ai` MCP was not used at all.** The editor (PID 9048) was never driven, no scene
   was opened in it, and every run was a separate engine instance or a `--script` run with the
   probe outside the project tree. The parallel designer's `_mockup_station.*` files were not
   read, written or renamed.
8. **The painted bevel of the plate art scales with the plate** (section 4.1) because the
   theme's plate styleboxes are not nine-patches. That is a property of the theme, which this
   pass may not touch; the mockup shows it rather than hiding it.

---

## 9. Notes for whoever approves this

- **Both decisions are applied, and neither needed a theme change.** No new theme item, no
  `build_theme.gd` run, `Router.FONT_SIZE_ITEMS` untouched at 27. The read-out's growth is a
  variation selection (`HudReadout`, 18 px), the emblem's brightness is a documented `modulate`
  multiplier (`EMBLEM_BRIGHTEN = 2.0`), and the row height is derived from the font.
- **The row-height defect is fixed at the root**, not patched: the row takes the plate's
  minimum size, the plate's minimum height is `max(70, font-driven minimum)`, and it is
  re-derived on `NOTIFICATION_THEME_CHANGED`. The proof includes `ui_scale` 2.0, where the row
  grows to 93 px because the font demands it. The spec carries this as an implementation
  instruction (section 12.1) with the numbers.
- **One number in the brief is corrected by measurement:** the plate's 1 px border is not drawn
  from a nine-patch. The theme's plate `StyleBoxTexture`s carry no patch margins; the 1 px
  border on this screen is the component's own focus ring, and it measures exactly 1 px on all
  four sides at 1.0, 1.2 and 1.4. The art itself is a stretched quad, so its painted bevel band
  goes from 5 rows to 7 rows at the new size. Preserving that band is a theme patch-margin
  change or an art re-author, both outside this brief.
- **A second number in the brief is corrected:** the emblem's highlights already cleared 4.5:1
  before this pass (11.21:1 peak in the D4b frame). The brightening is real and measurable
  (peak 204 -> 255, footprint median 26.4 -> 63.6 luma) but the body remains dark because the
  asset is dark; the fix for the body is an art pass.
- **The stack moved 18 px up** (rows 559 / 629 / 699 -> 541 / 625 / 709) because the column is
  54 px taller and still centres in the middle band. The left alignment and the placement rule
  are unchanged, and nothing is positioned by an offset. If the owner wants the old tops held
  exactly, that needs a pinned offset, which this screen's design forbids; the alternative is a
  shorter emblem or a shorter read-out, both of which the same decision requires to grow.
- **The read-out grew 1.286x, not 1.25x**, because 17.5 px does not exist as a theme item and
  `HudReadout` (18 px) is the closest. Recorded as open question 5 in the spec.
- **The mockup's script keeps CRLF line endings** (inherited from D4b) while the rest of the
  project is LF; normalising it belongs with the shipping screen, not with this pass.
