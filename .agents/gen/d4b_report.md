# D4b report - main menu v2 mockup, revision pass

Date: 2026-09-18. Worker: designer (medium: a live Godot 4.7 UI scene).
Brief: `.agents/gen/d4b_task.md`. Predecessor: `.agents/gen/d4_report.md`.

---

## 1. What was built and what changed

| Action | Path | Size |
|---|---|---|
| edited in place | `vajb-orbit/ui/screens/_mockup_main_menu.tscn` | 10325 bytes, 350 lines (was 12180 / 396) |
| edited in place | `vajb-orbit/ui/screens/_mockup_main_menu.gd` | 10948 bytes, 307 lines (was 10483 / 301) |
| updated | `docs/design/MAIN_MENU_V2.md` | 47992 bytes, 625 lines (section 14 is now "Resolved decisions") |
| created | `.agents/gen/previews/d4b_menu_v2_rev_1920x1080.png` | 3144114 bytes, frame 59 of the 1920x1080 movie |
| created | `.agents/gen/previews/d4b_menu_v2_rev_1600x900.png` | 2901750 bytes, window client capture at 1600x900 |
| created | `.agents/gen/previews/d4b_menu_v2_rev_1920x1080_uiscale140.png` | 3148956 bytes, frame 59 of the `ui_scale` 1.4 movie |
| created | `.agents/gen/previews/d4b_menu_v2_rev_1920x1080_preview.jpg` | 138073 bytes, 1152x648 downscale for eyeballing |
| created | `.agents/gen/previews/d4b_tools.py` | 15423 bytes, measurement/settings tool (method record) |
| created | `.agents/gen/previews/d4b_probe.py` | 3088 bytes, windowed client-area capture tool |
| created | `.agents/gen/d4b_report.md` | this file |

Changed in the scene, in full:

1. **The housing is gone.** Removed `RailPanel` (`PanelContainer` with a
   `StyleBoxEmpty` override), `RailFrame` (`NinePatchRect` over
   `res://assets/ui/ui_panel_frame.png`), `RailContent` (28 px padding), `RailStack`,
   `RailHeader`, the `StyleBoxEmpty_rail` sub-resource, the `ui_panel_frame.png`
   `ext_resource`, and the three 6 px `*Tail` spacers that existed only to centre the
   plates inside the 380 px housing. `load_steps` 13 -> 11. Nothing was added in their
   place: the plates float on the scrimmed vista.
2. **New header group.** `CommandColumn` (VBoxContainer, separation 16) now holds
   `CommandHeader` (HBoxContainer, separation 16, `%CommandHeader`) with `HeaderGutter`
   (a 6 x 0 `Control`) and `InsigniaBadge` (40 x 46), then `VerbStack`. The gutter occupies
   the same column as the focus ticks, so the emblem's left edge is x 118, exactly the
   plate column's left edge.
3. **The `COMMAND` caption was dropped** (the brief left this to judgement; reasoning in
   section 3.6).
4. **Version stamp** text set to `VAJB ORBIT v0.2` exactly.
5. No other node, size, colour, container or timing changed. `menu_button.tscn`, the
   theme, every autoload, `project.godot`, `addons/` and the parallel designer's
   `_mockup_station.*` were not touched.

Changed in the script, in full:

1. `RAIL_DELAY/RAIL_FADE/RAIL_POP/RAIL_SCALE` renamed to
   `HEADER_DELAY/HEADER_FADE/HEADER_POP/HEADER_SCALE` (same values: 0.10 / 0.30 / 0.45 /
   0.99), and the entrance tweens now drive `%CommandHeader` instead of the removed
   `%RailPanel`.
2. `TOKEN_TEXT_PRIMARY` added, and `_ready()` now applies the stamp's colour:
   `_stamp.add_theme_color_override(&"font_color", _token(TOKEN_TEXT_PRIMARY))`. The
   palette is still read from the theme; no colour literal was introduced.
3. The file header comment now lists the stamp override as the third runtime-built thing.
   This comment edit is the only change made after the renders, and the headless check was
   re-run afterwards (section 2.1).

No theme edit, no `build_theme.gd` edit, no `Router` edit: decision 2 was satisfied by an
existing token, so **no new theme item was added and the theme's item count is unchanged**.
`Router.FONT_SIZE_ITEMS` is untouched at its 27 entries.

---

## 2. Commands run, with their output

### 2.1 Mandated headless check (final state)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_main_menu.tscn --quit-after 300
```

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT=0
```

Run four times during the pass: after the housing removal, after the caption removal, and
once more after the final comment edit. Exit code 0 and the same two lines every time.

### 2.2 Control run, to attribute the second stdout line

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after 300
```

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
CONTROL_EXIT=0
```

The project's own main scene emits the same line, so it comes from the vendored
`addons/godot_ai/` autoload, not from the mockup. The scene prints nothing of its own.

### 2.3 1920x1080 render (deliverable)

`--write-movie` records the root viewport, so the movie is exactly the design target.

```
py -3.14 ".agents/gen/previews/d4b_tools.py" set 1920 1080 1.0
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --scene res://ui/screens/_mockup_main_menu.tscn --write-movie "C:/Users/Kamil/AppData/Local/Temp/vajb_d4b/f1920.png" --quit-after 60
```

```
Movie Maker mode enabled, recording movie in 1920×1080 @ 60 FPS...
Done recording movie at path: C:/Users/Kamil/AppData/Local/Temp/vajb_d4b/f1920.png
60 frames at 60 FPS (movie length: 00:00:01:00), recorded in 00:00:43 (2% of real-time speed).
EXIT=0
```

Frame 59 (`f192000000059.png`, 1920 x 1080) is the settled state (entrance ends at 0.86 s =
frame 52) and is the deliverable render.

### 2.4 1600x900 window, and the movie writer's limit

```
py -3.14 ".agents/gen/previews/d4b_tools.py" set 1600 900 1.0
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --scene res://ui/screens/_mockup_main_menu.tscn --write-movie "C:/Users/Kamil/AppData/Local/Temp/vajb_d4b/m1600.png" --quit-after 60
```

```
Movie Maker mode enabled, recording movie in 1920×1080 @ 60 FPS...
Done recording movie at path: C:/Users/Kamil/AppData/Local/Temp/vajb_d4b/m1600.png
60 frames at 60 FPS (movie length: 00:00:01:00), recorded in 00:00:51 (1% of real-time speed).
EXIT=0
```

**The movie writer ignored the 1600x900 window and recorded 1920x1080** (verified: the
produced frames are `(1920, 1080)`), because under `canvas_items` stretch the root viewport
stays at the project's base resolution. A real 1600x900 frame therefore cannot come from
`--write-movie`; it was taken from the live window instead:

```
py -3.14 ".agents/gen/previews/d4b_probe.py" 1600 900 "C:/Users/Kamil/AppData/Local/Temp/vajb_d4b/f1600x900.png"
```

```
launch ...Godot_v4.7.2-stable_win64.exe --path .../vajb-orbit --position 60,60 --always-on-top --resolution 1600x900 res://ui/screens/_mockup_main_menu.tscn
client 60,60 1600x900
saved C:/Users/Kamil/AppData/Local/Temp/vajb_d4b/f1600x900.png bytes=2901750
```

The first attempt returned a minimised window (`client -32000,-32000 0x0`, `ScreenShotError`);
the probe was fixed to restore and raise the window before capture, which is what worked.

### 2.5 `ui_scale` 1.4 render

```
py -3.14 ".agents/gen/previews/d4b_tools.py" set 1920 1080 1.4
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --scene res://ui/screens/_mockup_main_menu.tscn --write-movie "C:/Users/Kamil/AppData/Local/Temp/vajb_d4b/f1920s14.png" --quit-after 60
```

```
Movie Maker mode enabled, recording movie in 1920×1080 @ 60 FPS...
Done recording movie at path: C:/Users/Kamil/AppData/Local/Temp/vajb_d4b/f1920s14.png
60 frames at 60 FPS (movie length: 00:00:01:00), recorded in 00:00:45 (2% of real-time speed).
EXIT=0
```

`ui_scale` reaches the scene because `Router._bind_entry_scene()` assigns `live_theme()` to
whatever scene is the current scene, including one launched with `--scene`. The scaled theme
is built by `Router._scale_font_sizes()`; the settings file was patched to
`ui_scale=1.4` for this run and restored afterwards (section 5).

### 2.6 Engine rect dump (ground truth for the geometry)

A scratch probe was written to `user://d4b_probe_rects.gd` (outside the project tree),
instantiated the mockup at 1920 x 1080, printed every relevant `Control` rect at `ui_scale`
1.0, then re-assigned a theme scaled exactly the way `Router` scales it and printed them
again at 1.4. Output (abridged to the load-bearing rows):

```
window size (1920, 1080) viewport (1920.0, 1080.0)
== ui_scale 1.0 ==
  MiddleBand       pos (0.0, 176.0)   size (1728.0, 772.0)
  CommandColumn    pos (0.0, 257.0)   size (302.0, 258.0)  global [P: (96.0, 497.0), S: (302.0, 258.0)]
  CommandHeader    pos (0.0, 0.0)     size (302.0, 46.0)   min (62.0, 46.0)
  InsigniaBadge    pos (22.0, 0.0)    size (40.0, 46.0)    global [P: (118.0, 497.0), S: (40.0, 46.0)]
  VerbStack        pos (0.0, 62.0)    size (302.0, 196.0)  global [P: (96.0, 559.0), S: (302.0, 196.0)]
  PlayRow          pos (0.0, 0.0)     size (302.0, 56.0)   global [P: (96.0, 559.0), S: (302.0, 56.0)]
  PlayTick         pos (0.0, 4.0)     size (6.0, 48.0)     global [P: (96.0, 563.0), S: (6.0, 48.0)]
  PlayButton       pos (22.0, 0.0)    size (280.0, 56.0)   global [P: (118.0, 559.0), S: (280.0, 56.0)]
    Button          pos (0.0, 0.0)     size (280.0, 56.0)   min (82.0, 47.0)  font 34
  OptionsRow       pos (0.0, 70.0)    size (302.0, 56.0)   global [P: (96.0, 629.0), S: (302.0, 56.0)]
  ExitRow          pos (0.0, 140.0)   size (302.0, 56.0)   global [P: (96.0, 699.0), S: (302.0, 56.0)]
  FooterBand       pos (0.0, 948.0)   size (1728.0, 20.0)  global [P: (96.0, 1012.0), S: (1728.0, 20.0)]
  FocusReadout     pos (0.0, 0.0)     size (1604.0, 20.0)
  VersionLabel     pos (1628.0, 1.0)  size (100.0, 18.0)   global [P: (1724.0, 1013.0), S: (100.0, 18.0)]
  MenuButtonPlate font 34 SectionHeader 16 Label 14 Version 13
== ui_scale 1.4 (Router equivalent) ==
  MiddleBand       pos (0.0, 176.0)   size (1728.0, 764.0)
  CommandColumn    pos (0.0, 253.0)   size (302.0, 258.0)  global [P: (96.0, 493.0), S: (302.0, 258.0)]
  InsigniaBadge    pos (22.0, 0.0)    size (40.0, 46.0)    global [P: (118.0, 493.0), S: (40.0, 46.0)]
  VerbStack        pos (0.0, 62.0)    size (302.0, 196.0)  global [P: (96.0, 555.0), S: (302.0, 196.0)]
  PlayRow          pos (0.0, 0.0)     size (302.0, 56.0)   global [P: (96.0, 555.0), S: (302.0, 56.0)]
  PlayTick         pos (0.0, 4.0)     size (6.0, 48.0)     global [P: (96.0, 559.0), S: (6.0, 48.0)]
  PlayButton       pos (22.0, 0.0)    size (280.0, 56.0)   global [P: (118.0, 555.0), S: (280.0, 56.0)]
    Button          pos (0.0, -5.5)   size (280.0, 67.0)   min (116.0, 67.0) font 48
  OptionsRow       pos (0.0, 70.0)    size (302.0, 56.0)   global [P: (96.0, 625.0), S: (302.0, 56.0)]
  ExitRow          pos (0.0, 140.0)   size (302.0, 56.0)   global [P: (96.0, 695.0), S: (302.0, 56.0)]
  FooterBand       pos (0.0, 940.0)   size (1728.0, 28.0)  global [P: (96.0, 1004.0), S: (1728.0, 28.0)]
  VersionLabel     pos (1589.0, 1.0)  size (139.0, 26.0)   global [P: (1685.0, 1005.0), S: (139.0, 26.0)]
  MenuButtonPlate font 48 SectionHeader 22 Label 20 Version 18
```

The probe file was deleted after the run.

---

## 3. Measurements

All numbers below are measured on the frames above. Ratios are WCAG relative luminance
`(L1+0.05)/(L2+0.05)` computed from rendered pixels; "ink" is the mean of the brightest 2 %
of pixels in the region and "peak" is the brightest pixel, both against the median of the
region's non-text pixels. Luma values are the weighted sRGB mean (0..255) used as a
brightness locator.

### 3.1 Decision 1: the housing is absent

The region the rail occupied (`x 96..476, y 469..783`) was probed at the four places the old
frame drew a border, with the same probes run against the render the owner reviewed
(`menu_v2_mockup_1920x1080.jpg`, 1280 x 720, so its coordinates are scaled by 2/3):

| Probe | Old render (mean luma, median rgb) | New frame (mean luma, median rgb) |
|---|---|---|
| Left border, x 94..104 at y 700..780 | 42.37, `#2b2e31` | **18.95, `#101318`** |
| Right border, x 466..478 at y 700..780 | 39.39, `#232528` | **19.88, `#10141a`** |
| Top border, x 200..300 at y 466..478 | 42.19, `#2a2e31` | **20.51, `#11151b`** |
| Bottom border, x 200..300 at y 774..786 | 35.53, `#202328` | **19.25, `#101319`** |
| Backdrop reference, x 700..900 at y 500..700 | 21.90, `#11161d` | 21.76, `#11161d` |
| Old interior fill, x 430..466 at y 500..750 | 15.68, `#0b0d11` (the frame's opaque fill, darker than the vista) | 20.29, `#10151b` (the vista itself) |

Every old border band now measures the backdrop reference within 1.4 luma and matches its
median rgb. Edge detection over the same positions:

```
old frame: columns x 60..73 in y 467..521, threshold 32  -> run (64, 70)      (the rail's left border)
new frame: columns x 90..109 in y 700..782, threshold 32 -> runs []           
old frame: rows y 133..212 in x 303..325, threshold 32   -> run (312, 317)    (the rail's top border)
new frame: rows y 200..319 in x 460..489, threshold 32   -> runs []           
```

Pixel counts in the rail region: pixels within 6 of `metal_mid` fell 695 -> 691 and of
`metal_light` 18 -> 27 across the two frames, but those residuals sit inside the plate art
(x 118..398 lies inside the probe region), not on a border: the count of pixels within 6 of
`metal_dark` is 11151 in the new frame, all of it plate art and vista, and the region's
leftmost 6 px column band (x 96..101) is the accent tick's own column.

### 3.2 Elements at 1920x1080 (frame 59), engine rect against measured ink

| Element | Engine rect (`get_global_rect`) | Measured ink box | Verdict |
|---|---|---|---|
| Logo | 560 x 176 at (96, 64) | x 100..651, y 61..235 (threshold 120) | the ink is the art inside the atlas crop; 551 x 174 |
| Emblem | 40 x 46 at (118, 497) | x 119..153, y 498..541 (threshold 90) | 1 px inset from the node rect, as the art is drawn `KEEP_ASPECT_CENTERED` |
| Plate row 1 | 280 x 56 at (118, 559) | accent focus ring (exact token pixels, tolerance 4): x 118..398, y 559..615 | exact; the ring's outer rows are the button rect's first and last rows |
| Tick 1 | 6 x 48 at (96, 563) | exact token pixels: x 96..101, y 563..610 (a threshold box reads x 96..102, y 563..611 with the anti-aliased column) | exact, 6 x 48 of `accent_danger_bright` |
| Plate rows 2, 3 | at (118, 629) and (118, 699) | row bands 629..685 and 701..752 | consistent (row 3's band is the label ink, the plate's own bottom edge is dimmer) |
| PLAY label | centred in the row | x 220..299, y 575..600 | 79 x 25, centred on the plate |
| Read-out | 1604 x 20 at (96, 1012) | x 97..265, y 1017..1027 | exact |
| Version stamp | 100 x 18 at (1724, 1013) | x 1724..1823, y 1018..1029 | exact; 99 px wide for "VAJB ORBIT v0.2" |

The `COMMAND` region is now empty: the probe region (174..400, y 505..535) returns `ink box
None, px 0` at thresholds 60 and 45, with a peak luma of 37.0 (grain, not text).

### 3.3 Decision 2: the version stamp

| | First pass (`text_dim`) | This pass (`text_primary`) |
|---|---|---|
| String | VAJB ORBIT v0.1 | **VAJB ORBIT v0.2** (scene and spec agree) |
| Ink box | x 1724..1820, y 1018..1028 | x 1724..1823, y 1018..1029 |
| Ink peak | 115.2 (= `#6b7484`) | 208.1 (= `#c9d1dc`) |
| Local background (median, text excluded) | 20.6, `#12151a` | 20.3, `#111519` |
| **Measured contrast** | **3.88:1** | **11.91:1 peak / 11.67:1 ink mean** |

The floor is 4.5:1, so the fix clears it with 7.4 points of headroom. The colour comes from
the existing `Tokens/text_primary`; `Version/font_size` is still 13 and the theme is
unmodified, so `Router.FONT_SIZE_ITEMS` still reaches it (verified at 1.4: `Version` font 18,
stamp ink x 1685..1823, i.e. 139 px wide against 100 at 1.0).

### 3.4 The remaining text, and the caption that is no longer there

| Text | Ink box | Ink peak | Local background | Contrast (peak / mean) |
|---|---|---|---|---|
| Read-out (14 px `text_primary`) | x 97..265, y 1017..1027 | 208.1 | 18.9, `#111317` | 12.08:1 / 11.84:1 |
| Version stamp (13 px, `text_primary` override) | x 1724..1823, y 1018..1029 | 208.1 | 20.3, `#111519` | 11.91:1 / 11.67:1 |
| Verb labels (34 px `text_primary`) | PLAY x 220..299, y 575..600 | 208.1 (217.0 over a wider window) | 51.9, `#333435` (plate metal) | 8.10:1 / 8.66:1 |
| Emblem art (graphic) | x 119..153, y 498..541 | 204.0 | 24.5, `#15191d` | 11.00:1 on the highlights |
| Wordmark art (graphic) | x 100..651, y 61..235 | 246.0 | 25.4, `#151a20` | 16.23:1 on the highlights |
| Caption region (removed) | `None`, 0 px above threshold | 37.0 | 17.4, `#0d1218` | 1.23:1 (nothing there) |

For reference, the removed `COMMAND` caption measured **3.86:1** in the frame rendered before
it was dropped (ink x 175..260, y 514..526, peak 115.2, background 21.4) - below the 4.0:1
floor `UI_SPEC.md` section 1 documents for `text_dim` and below the 4.5:1 the owner set for
the stamp.

### 3.5 Decision 3: the three footer read-outs

`READOUT` in the mockup is unchanged, character for character:
`ENTER THE STATION HUB`, `OPEN SYSTEM AND INTERFACE SETTINGS`, `END THE SESSION`. The
rendered line at frame 59 is the first of the three, matching the default focus (PLAY), and
its ink box and contrast are in section 3.4.

### 3.6 The caption decision (the brief's judgement call)

**The caption was dropped; the emblem stayed.** Reasoning, from the render and the numbers:

1. Looking at the render with the housing gone, `COMMAND` labels a console that is no longer
   on the screen. The three verbs are the whole console now, and the word adds no
   information: it was a section header for a container that no longer exists.
2. It measured 3.86:1, which is below the 4.0:1 floor `UI_SPEC.md` documents for 16 px
   `text_dim` and far below the 4.5:1 the owner required of the version stamp in the very
   same pass. Keeping it would ship the only sub-floor text on the screen; fixing it would
   mean a second theme/token change the owner did not ask for.
3. The emblem does not need the caption's support: at 40 x 46 its highlights measure 11.00:1
   against the scrimmed vista, and it is the only brand statement on the screen. The audit
   lists the insignia as a role worth spending, which is exactly what it now does alone.
4. Composition does not suffer: the header row is still 46 px tall (the emblem fixes it), the
   column is still 258 px, the verb rows keep their exact y (559 / 629 / 699), so dropping
   the caption changed one region of the frame and nothing else.

The alternative (keeping it) is recorded in `MAIN_MENU_V2.md` section 14, open question 3,
with the price of reversal: a brighter token for the caption.

### 3.7 Decision 4: `ui_scale` 1.0 and 1.4

Font items, read back from the live theme (engine dump, section 2.6):

| Item | 1.0 | 1.4 | Present in `Router.FONT_SIZE_ITEMS` |
|---|---|---|---|
| `MenuButtonPlate/font_size` | 34 | 48 | yes |
| `Label/font_size` | 14 | 20 | yes |
| `Version/font_size` | 13 | 18 | yes |
| `SectionHeader/font_size` | 16 | 22 (item kept, caption removed) | yes |

Effects, measured:

| Measure | 1.0 | 1.4 | Ratio |
|---|---|---|---|
| Read-out rendered ink height | 10 px (y 1017..1027) | 14 px (y 1012..1026) | 1.40 |
| Stamp rendered ink width | 99 px (x 1724..1823) | 139 px (x 1685..1823) | 1.40 |
| Plate's inner `Button` rect | 280 x 56 at y 559 | 280 x 67 at y 549.5 | 1.196 (vertical only) |
| Focus ring bbox (exact token pixels) | x 118..398, y 559..614 | x 118..398, y 550..616 | 1.196 |
| Stack pitch (row tops) | 70 px (559 / 629 / 699) | 70 px (555 / 625 / 695) | 1.00 |
| Visible gap between plate 1 and plate 2 | 14 px of backdrop (y 615..628) | 5 px of backdrop (y 617..621) | 0.36 |
| Tick | 6 x 48 at y 563 | 6 x 48 at y 559, still centred in its row | 1.00 |
| Middle band height | 772 | 764 | 0.99 |
| Footer band height | 20 | 28 | 1.40 |

**The plate's vertical stretch measures 1.196 (about 20 percent), not the 14 percent the
first pass estimated.** The cause is exact and engine-verified: `MenuButtonPlate` font 34 ->
48 makes the plate `Button`'s minimum height 47 -> 67 px, and because a `menu_button.tscn`
instance is a plain `Control` whose own minimum is the frozen 56 px, the row stays 56 px tall
and the `Button` overflows it by 5.5 px top and bottom (`pos (0.0, -5.5)`, `size (280.0,
67.0)`). The 280 x 56 art is therefore drawn into a 280 x 67 rect, and the visible 14 px gap
between plates closes to 3 px (5 px of measurable dark rows, the rest being the anti-aliased
plate edge). Nothing overlaps and nothing clips: plates span y 549.5..616.5, 619.5..686.5 and
689.5..756.5, inside a middle band of 493..1004.

The owner accepted this behaviour (decision 4); the spec records it in section 12 with the
measured magnitude and the reason (a second plate asset at 1.4 x type is not budgeted).

### 3.8 Composition at 1600x900

The window client capture is 1600 x 900 and every ink box is the 1920 x 1080 box multiplied
by 0.8333:

| Element | 1920 x 1080 ink box | 1600 x 900 ink box | Ratio (x, y) |
|---|---|---|---|
| Read-out | x 97..265, y 1017..1027 | x 81..222, y 847..856 | 0.84, 0.90 (1 px quantisation on a 10 px box) |
| Version stamp | x 1724..1823, y 1018..1029 | x 1437..1520, y 848..858 | 0.84, 0.91 |
| Plate row 1 band | x 118..398 | x 98..332 | 0.83 |
| Tick 1 | x 96..102, y 563..611 | x 80..85, y 469..509 | 0.83 |
| Emblem | x 119..153, y 498..541 | x 98..147, y 415..467 (threshold 60) | 0.83 |

Composition holds: all three plates are present and complete, the emblem and wordmark are
present, both footer texts are inside the frame with their safe margins intact (the stamp's
right edge at 1520 leaves 80 px = 96 x 0.8333), the left safe margin measures 80 px, and no
element is clipped or on top of another. Frame edges measure mean luma 20.9 / 18.8 / 20.8 /
21.6 (top / bottom / left / right), i.e. the vista, not content.

**One caveat, measured:** the window capture's absolute luminance is not the engine's. Bright
ink in the capture reads higher than in the movie (read-out peak 253.1 vs 208.1, plate art
250.8 vs 221.0) while the dark backdrop matches (19.9 vs 20.6). The 1600x900 frame was
therefore used for geometry, not for contrast; all contrast numbers in this report come from
the 1920x1080 movie frames, which are the deterministic engine output.

---

## 4. Asset verification

Every `res://` path in the scene and in `MAIN_MENU_V2.md`, resolved on disk:

```
OK   res://assets/env/env_menu_bg.png            2819956
OK   res://assets/fx/fx_ember_pulse.png          2637004
OK   res://assets/ui/logo_vajb_orbit.png         2711747
OK   res://assets/ui/ui_insignia_neutral.png     1115179
OK   res://ui/components/menu_button.tscn            923
OK   res://ui/screens/_mockup_main_menu.gd         10948
OK   res://ui/theme/grain.tres                       284
OK   res://ui/theme/vajb_theme.tres                24314
```

The spec's un-prefixed art paths also resolve:

```
OK   assets/ui/ui_button_plate_normal.png  29377     OK   assets/audio/ui/ui_hover.ogg        5461
OK   assets/ui/ui_button_plate_hover.png   30794     OK   assets/audio/ui/ui_click.ogg        4869
OK   assets/ui/ui_button_plate_pressed.png 27947     OK   assets/audio/ui/ui_confirm_01.ogg   8359
OK   assets/ui/ui_button_plate_disabled.png 29438    OK   assets/audio/ui/ui_scroll_01.ogg    8441
OK   assets/audio/music/mus_menu_theme_01.ogg 2221109
OK   assets/ui/ui_panel_frame.png   11571            OK   assets/ui/ui_backdrop_login.png   3497181
OK   assets/ui/ui_backdrop_hangar.png 2998657
```

`ui_panel_frame.png` still exists on disk (11571 bytes) but is deliberately no longer
referenced by this screen. Nothing was invented: every path is from `ASSET_AUDIT.md`
section E.1 or section F.

---

## 5. `user://settings.cfg` round trip

Patched for the renders (windowed mode, three resolutions, two `ui_scale` values) from a byte
copy, then restored:

```
backup  sha256 edb17b3fcf9c3b29   (display_mode=1, resolution=Vector2i(2560, 1440), ui_scale=1.0)
during  sha256 961fb6e05126e58b   (display_mode=0, 1600x900 / 1920x1080, ui_scale=1.0 / 1.4)
restored sha256 edb17b3fcf9c3b29
```

The file is app state, not a project file, and it is byte-identical to how it was found. The
scratch rect probe (`user://d4b_probe_rects.gd`) was deleted after its run.

---

## 6. Static audit of the two edited files

```
tscn: 350 lines, 10325 bytes        gd: 307 lines, 10948 bytes
leftovers of the removed housing: RailPanel 0, RailFrame 0, RailContent 0, RailStack 0,
  RailHeader 0, Tail 0, CommandCaption 0, panel_frame 0, NinePatchRect 0, StyleBoxEmpty 0
hex literals anywhere (scene + script): []
color literals in the scene: Color(1,1,1,0.25), Color(1,1,1,0.08), Color(1,1,1,0) x3
  (white-with-alpha for opacity only, the same pattern the Phase C menu uses for the ember
  and the grain)
func _process in the script: False
per-node font-size overrides: none (theme_override_font_sizes appears 0 times)
theme_type_variation in the scene: &"Version" (stamp), &"DialogTitle" (stand-in dialog)
unique_name_in_owner nodes: 18; %refs in the script: 18, all of them existing
autoload / Router / class_name references in the script: only the words in the header comment
```

---

## 7. What could not be verified, and what limits the evidence

1. **The 1600x900 frame is not a movie frame.** `--write-movie` refuses to produce one
   (section 2.4), so the deliverable is a desktop capture of the window's client area. Its
   geometry is exact (section 3.8) but its luminance is not the engine's, so its contrast
   numbers are not comparable with the movie's and are not reported as such.
2. **Only one plate's rect is directly measurable at 1.4.** The focus ring draws the focused
   `Button`'s rect exactly, and only PLAY is focused. The other two plates are inferred from
   the identical component (same font item, same row height) plus the measured stack pitch
   (70 px) and the 5 px gap, which agree with a 67 px plate. The engine rect dump confirms
   the mechanism (`Button` 280 x 67 at -5.5, rows still 56) for the one plate it prints.
3. **4:3 (extra height) is still reasoned, not rendered.** The 21:9 case was rendered in the
   first pass and the container structure is unchanged, so the section 3.2 rule stands; the
   extra height lands only in `MiddleBand`, and the console stays centred in it. The 4:3 crop
   of the vista is horizontal, which is the case the ember formula was only computed for.
4. **Motion is unchanged and not re-measured frame by frame.** The entrance timings, the
   drift and the ember pulse are the first pass's values, with the rail's tweens retargeted
   to `%CommandHeader` (same durations and curves). The renders are the settled state
   (frame 59, entrance ends at frame 52); no mid-entrance frame was inspected this pass.
5. **Focus traversal, hover, press and the Esc stand-in were not driven.** The movie writer
   cannot inject input and no interaction was scripted; those paths are code-reviewed against
   the first pass's tables, not measured.
6. **The insignia's C3 white matte fringe is still there** (visible as a light rim on the hex
   in the render). The defringe pass has not run; the emblem's highlight contrast (11.00:1)
   is measured on the fringe as it currently is.
7. **The `godot-ai` MCP was not used at all.** The editor (PID 9048) was never driven, no
   scene was opened in it, and every run was a separate engine instance or a `--script` run
   with the scratch probe outside the project tree. The parallel designer's `_mockup_station.*`
   files were not read, written or renamed.

---

## 8. Notes for whoever approves this

- **The five decisions are all applied**, and none of them needed a theme or autoload change:
  no new theme item, no `build_theme.gd` run, `Router.FONT_SIZE_ITEMS` untouched at 27.
- **One number in the brief is corrected by measurement:** the plate stretch at `ui_scale`
  1.4 is 1.196 (about 20 percent), not 14 percent: the plate's inner `Button` is 67 px tall
  inside a 56 px row. The accepted behaviour is the same (the art stretches instead of a
  second asset being authored), but the magnitude and the tighter 3 px gap between plates are
  now recorded in `MAIN_MENU_V2.md` section 12 and offered as open question 4.
- **The `COMMAND` caption was dropped** rather than brightened (section 3.6), because it
  measured 3.86:1 and labelled a housing that no longer exists. Reversal costs one token
  change; it is open question 3 in the spec.
- **The housing's retirement has a side effect outside this screen:** the audit's "chrome"
  role is now unused on the main menu by the owner's decision, and the anomaly C1 trap
  ("`PanelRaised` bakes 32 px patch margins on a 7 px frame") no longer applies here, though
  it still applies to the station hub's panels until brief G3 regenerates the file.
- **The stamp's brightness lives in the mockup script**, not in the theme. That is legal (the
  colour is read from `Tokens/text_primary`, no literal) and it keeps the theme's promise to
  other screens intact, but if the owner prefers a declarative item, the spec's open
  question 2 lists the exact price: a 13 px stamp variation in `build_theme.gd`, a regenerated
  `vajb_theme.tres`, and one new `Router.FONT_SIZE_ITEMS` entry (27 -> 28).
