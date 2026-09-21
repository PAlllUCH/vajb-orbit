# Batch-2 playtest report (B2-1 hover, B2-2 backdrops, B2-3 minimap zoom)

Worker: batch-2 playtest lane, dispatched 2026-09-21. Brief: `.agents/gen/batch2_task.md`
(items from `docs/gameplay/19_testing_notes.md`, 2026-09-18). No editor was opened; every
run was headless and bounded. `vajb-orbit/assets`, `project.godot`, the theme, `addons/`
and `docs/` were read only, never written.

**Headline.** B2-3 was a real code defect inside the declared file set and is fixed and
measured. B2-1 and B2-2 are *not* button-code or texture-filter defects: the shipped
`vajb-orbit/assets/ui` chrome art and the scene-side crops that consume it were replaced on
**2026-09-21 00:17-00:18** by whole sheet-cell cuts (the `staging/cut` redesign + pull), and
the theme and the scenes still carry the geometry of the 2026-09-18 cuts. The menu plates,
the menu wordmark, the minimap bezel and the bar-bar caps are all measurably broken by that
mismatch. Those files are outside this worker's declared set (`assets` is read-only), so
B2-1 and B2-2 are reported as measured defects with the fix recipe, not as edits.

---

## 1. Files changed

| File | Bytes | What |
|---|---|---|
| `vajb-orbit/ui/hud/hud.gd` | 31 649 → **32 096** (+447) | B2-3: the two zoom deltas renamed to the direction they mean and the two `pressed` bindings swapped, with the sign and its reason documented above the constants |
| `.agents/gen/batch2_report.md` | this file | report |
| `.agents/gen/batch2_evidence/hover_simulation.png` | 1106×1620 | B2-1 evidence: a **re-implementation** of the engine draw (plate + 6 px halo + 1 px border), tight-crop art vs shipped art (not a screenshot) |
| `.agents/gen/batch2_evidence/atlas_region_proof.png` | 317×178 | the two `ui_bar_caps.png` AtlasTexture regions drawn over the current 317×178 file |
| `.agents/gen/batch2_evidence/logo_crop_proof.png` | 723×364 | the menu's frozen wordmark crop rectangle over the current 2170×823 `logo_vajb_orbit.png` |

Created and deleted inside this dispatch: `vajb-orbit/tools/_probe_b2_star.gd`
(11 229 bytes; Godot never wrote a `.gd.uid` for it because no editor scanned it, and both
paths were removed). `vajb-orbit/tools/` now holds only `build_theme.gd` (+`.uid`),
`derive_icon_tints.gd` (+`.uid`) and `desktop.ini`.

**Final file set actually used.** Written: `vajb-orbit/ui/hud/hud.gd`, the probe (deleted),
and the two `.agents/gen/batch2*` report paths. Read only: `vajb-orbit/ui/hud/{hud.tscn,minimap.gd,target_reticle.gd}`,
`vajb-orbit/ui/screens/{main_menu.gd,main_menu.tscn,loading.tscn,station.tscn}`,
`vajb-orbit/ui/components/{menu_button.gd,menu_button.tscn,glow_underlay.gd}`,
`vajb-orbit/ui/theme/vajb_theme.tres`, `vajb-orbit/tools/build_theme.gd`,
`vajb-orbit/game/{game.tscn,game.gd,sector_registry.gd}`, `vajb-orbit/project.godot`,
`vajb-orbit/assets/**` (survey), `asset-library/_library.json`,
`staging/phase_f/plates_report.json`, `staging/cut/_deleted_by_redesign.json`. Nothing was
written outside that set; `git status` shows exactly one modified project file
(`vajb-orbit/ui/hud/hud.gd`, `git diff --stat` = 14 changed lines).

---

## 2. Commands, and what they printed

### 2.1 B2-3 probe (the only in-set code change)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" \
  --script res://tools/_probe_b2_star.gd --quit-after 600 \
  > "$TEMP/vajb_b2/probe.log" 2>&1          # rc=0, then probe_after.log after the edit
```

The probe (`extends SceneTree`, so autoloads exist, exactly like `headless_runner.tscn`)
instantiates the real scenes, prints the resolved numbers, presses `%ZoomPlus` / `%ZoomMinus`
through `pressed.emit()` and applies the gameplay side's own arithmetic
(`game.gd::_on_minimap_zoom_changed`: `radius + delta * 800`, clamped 800-6400).

Before (probe.log):

```
[b2] ZoomPlus emits minimap_zoom_changed([1])
[b2] ZoomMinus emits minimap_zoom_changed([-1])
```

After (probe_after.log):

```
[b2] ZoomPlus emits minimap_zoom_changed([-1]) -> world radius 3200 -> 2400 = zoom in (less world)
[b2] ZoomMinus emits minimap_zoom_changed([1]) -> world radius 3200 -> 4000 = zoom out (more world)
```

### 2.2 Universal test gate (after the edit)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" \
  res://tests/headless_runner.tscn --quit-after 1200 > "$TEMP/vajb_b2/gate.log" 2>&1
```

`rc=0`, `[SUMMARY] passed=78 failed=0`. (AGENTS.md records `passed=53` for this gate; the
suite has grown since that line was written. No failure, no skip, no script error in the log.)

### 2.3 Asset and scene measurements (read-only, run under `py -3.14`)

* `hashlib.md5` over the shipped plates vs the library cut: `ui_button_plate_hover.png`
  `5817741faf8d229ff3ed90473dca148c` and `f4636629a0e0371440e1b9427b688e99` for `_normal`
  == the `md5` in `asset-library/_library.json` for `cut/ui/ui_button_plate_*.png`
  (byte-identical, so the project files *are* the redesign cuts).
* `Image.getbbox()` on the alpha channel: `ui_button_plate_hover.png` = 1041×1087 with its
  only ink at `(93, 477, 947, 610)`; `logo_vajb_orbit.png` = 2170×823 with ink rows
  130-693; `ui_minimap_bezel.png` = 1063×1065 with ink `(62,62,999,1000)`;
  `ui_bar_caps.png` = 317×178 with ink `(1,1,316,178)`; the three backdrops and the three
  star tiles = 2048×1152 / 2048×2048 with ink over the whole frame (no crop defect there).
* File mtimes: the twelve UI chrome PNGs were rewritten `2026-09-21 00:17-00:18`
  (plates 00:18:02, logo 00:17:15, bezel 00:17:16); `ui/theme/vajb_theme.tres` is
  `2026-09-18 18:42:55` and `ui/components/menu_button.gd` `2026-09-18 14:24:27`, i.e. both
  predate the art by 2.5 days. The backdrops and tiles landed `2026-09-20 21:56-21:57`.
* `staging/phase_f/plates_report.json` (mtime `2026-09-21 00:47:03`) still records
  `"applied": true` with `box_1x [280,56]`, `box_2x [560,112]`; neither box is on disk any
  more: no file under `vajb-orbit/` or `asset-library/` matches `*@2x*` any more, and
  `staging/cut/_deleted_by_redesign.json` lists all 19 `@2x` `.import` sidecars as deleted.
* `.import` survey: `mipmaps/generate=false` on every backdrop and tile; on the icon families
  270 of `assets/icons/*/*_96.png` carry `mipmaps/generate=true` (the F.1 setting) while all
  1 080 `assets/icons/tint/*` stencils (16/48/96/192) carry `false` and
  `detect_3d/compress_to=1` — contradicting ICONS_SPEC §9.8 stage 4 ("278 icon quartet cuts,
  278 tint stencils ... set to `mipmaps/generate=true`").

### 2.4 What the probe printed for the two blocking items

```
[b2] project default_texture_filter = 2
[b2] stretch mode = canvas_items aspect = expand      [b2] root content_scale_size = (1920, 1080)
[b2] MenuBackdrop node_size = (2016.0, 1176.0) texture = …env_menu_bg.png (2048.0, 1152.0) mips=false
[b2] MenuBackdrop covered_scale = 1.0208 (x 0.9844, y 1.0208); needs (2090.667, 1176.0) of a (2048.0, 1152.0) source
[b2] StationBackdrop node_size = (1920.0, 1080.0) … (2048.0, 1152.0) mips=false
[b2] StationBackdrop covered_scale = 0.9375 (x 0.9375, y 0.9375)
[b2] LoadingBackdrop covered_scale = 0.9375 ; modulate=(1,1,1,0.4)
[b2] PlayButton rect = … S: (339.5, 67.9)   inner Button rect = … S: (350.0, 70.0)
[b2] Glow rect = [P: (-6.0, -6.0), S: (362.0, 82.0)] visible = false
[b2] plate art res://assets/ui/ui_button_plate_hover.png used_rect = [P: (93, 477), S: (854, 133)] of (1041.0, 1087.0)
[b2] plate art draws into [P: (31.27, 30.72), S: (287.13, 8.56)] of a (350.0, 70.0) plate rect; invisible share = 0.900
[b2] plate has_focus = true is_hovered = false draw_mode = 0
[b2] after _on_mouse_entered: Glow.visible = true plate draw_mode = 0
[b2] Bezel rect = … S: (200.0, 200.0) texture = …ui_minimap_bezel.png (1063.0, 1065.0) mips=false
[b2] Bezel patch margins = 16/16/16/16 … nine-patch scale = (0.188147, 0.187793)
[b2] bezel patch band drawn = 3.01/3.00/3.01/3.00 node px
[b2] ZoomPlus box = (28.0, 28.0) texture = …icon_zoom_plus_96.png (96.0, 96.0) mips=false texels_per_px = (3.43, 3.43)
[b2] CargoToggle box = (48.0, 48.0) texture = …icon_cargo_container_48.png (48.0, 48.0) mips=false texels_per_px = (1.0, 1.0)
```

One probe limitation, stated plainly: the dummy display server made the injected
`InputEventMouseMotion` produce no hover (`Glow.visible` stayed `false`), so the hover state
was entered through the component's own `_on_mouse_entered()`; the *state* path is therefore
verified, the *pointer* path cannot be in a headless run. Second correction to my own output:
the probe annotated `default_texture_filter = 2` with the *CanvasItem* filter enum, which is
the wrong table - the project setting's enum is `Nearest, Linear, Linear Mipmap, Nearest
Mipmap`, so `2` is **Linear Mipmap**, which is also what AGENTS.md records for the
2026-09-18 project-settings route. The value, not the annotation, is the evidence.

---

## 3. Item by item

### B2-3 — minimap zoom was inverted — **fixed, measured**

Defect: `ui/hud/hud.gd` bound `%ZoomPlus` to `ZOOM_DELTA_PLUS (+1)` and emitted that as
`minimap_zoom_changed`, which `game.gd::_on_minimap_zoom_changed` adds to the map's world
radius (`delta * MINIMAP_RADIUS_STEP = 800`, clamp 800-6400). A *larger* world radius means
*more world* in the same 200×200 map, i.e. zoom **out**, so `+` zoomed out and `-` zoomed in.
The signal contract in `docs/design/IMPLEMENTATION_PLAN.md` §3.10 fixes the name and the
`delta: int` shape but not the sign, so the HUD owns it.

Fix (one file, no contract change in shape): the constants now state what they mean and the
bindings are swapped - `ZOOM_DELTA_IN = -1` on `%ZoomPlus`, `ZOOM_DELTA_OUT = +1` on
`%ZoomMinus`, with a comment naming `game.gd` and the clamp. Acceptance measurement: after the
fix `%ZoomPlus` emits `-1` (3200 → 2400 = closer in, less world) and `%ZoomMinus` emits `+1`
(3200 → 4000 = further out). The wheel-zoom camera is untouched: `game.gd`'s
`_unhandled_input` → `_set_camera_zoom` (0.70-1.50) has its own sign, and `git diff` shows
only `hud.gd` touched.

Docs still to tick (docs are read-only here): `docs/gameplay/19_testing_notes.md` B2-3, and
the IMPLEMENTATION_PLAN §9.8 follow-up line it asks for.

### B2-1 — the menu hover look — **defect found and measured, NOT fixed, NOT approved**

**The defect is not the halo's code path and not a colour choice: it is the baked hover plate
art, which is today a whole 2×2 sheet cell rather than the plate.** Measured, engine-side:

* `assets/ui/ui_button_plate_hover.png` is 1041×1087 whose only ink is `(93,477,854,133)`.
  The theme's `MenuButtonPlate` styleboxes are bare `StyleBoxTexture`s with
  `texture_margin_* = 0` (`ui/theme/vajb_theme.tres`), so the engine stretches the **whole
  canvas** into the 350×70 plate: the painted plate renders as **287.1 × 8.6 px** and
  **90.0 % of the plate area is transparent** (`invisible share = 0.900`).
* The docs record the intended art: `MAIN_MENU_V2.md` §15.4 measured "its painted bevel band,
  5 rows in the **280 x 56** source, measures 7 rows at 350 x 70"; §7 lists the plates as
  "350 x 70, drawn from the 280 x 56 art". `staging/phase_f/plates_report.json` still claims
  `box_1x [280,56]` / `box_2x [560,112]`, `applied: true`, written 2026-09-21 00:47.
* The art on disk is dated **2026-09-21 00:17-00:18** and matches
  `asset-library/_library.json`'s `cut/ui/ui_button_plate_*` byte for byte (md5), whose
  `cut_from` is `raw/icons/panel_button_plates.png` panel 1-4 of a 2×2 grid with
  `source_box` 863-925 × 789-931 and `pieces: 9-11` - i.e. the cut is the panel canvas, not
  the plate box. The theme (`2026-09-18 18:42`) and `menu_button.tscn`/`menu_button.gd` are
  older, so they still describe the 280×56 art.
* What the hover state therefore renders: `glow_underlay.gd` draws a `StyleBoxFlat` with
  bg = `Tokens/menu_glow` (`#e8703a`, alpha 0.60) and `expand_margin_* = 6` around the plate -
  measured live as a `Glow` rect of `(-6,-6,362,82)` around the 350×70 plate, shown on hover -
  and it is a **flat, hard-cornered (radius 0) 6 px band**, not the "6 px **soft** outer halo"
  `UI_SPEC.md` §2.2 and `UI_CHROME_ASSETS_SPEC.md` §1.5 require; on top of it
  `menu_button.gd::_draw()` strokes a 1 px `text_primary` rectangle on the plate rect. With no
  plate paint under either of them, hover *is* two concentric rectangles - exactly the owner's
  "static square border as glow".
* Adjacent facts measured on the same screen, same root cause: `logo_vajb_orbit.png` is now
  **2170×823** (ink rows 130-693) while `main_menu.tscn` still crops
  `AtlasTexture Rect2(44, 707, 1961, 615)` - that region contains **zero ink pixels**
  (max alpha 0), so the wordmark cannot be drawing; the HUD bezel (1063×1065 in a 200×200
  nine-patch, 16 px margins) draws its frame band at **3.0 px** instead of 16; the two
  `ui_bar_caps.png` AtlasTexture regions `(0,0,20,14)` / `(22,0,20,14)` crop a 317×178 file
  (ink shares 0.46 / 0.87, not the designed 20×14 caps); the slot plates are the same kind of
  cell (e.g. `ui_slot_weapon_normal.png` 880×876, ink `(175,287,531,303)`) in 48×48 cells.
* `ui_insignia_neutral.png` (865×976, ink 807×918) is the one survivor, because its box is
  `KEEP_ASPECT_CENTERED`: it draws 47×53 of a 50×58 box.

**Why no edit here.** Every file that could fix this is outside the declared set:
`vajb-orbit/assets/**` is read-only, the theme and `ui/components/**` are out of the set and
excluded by the dispatch rules ("never edit … the theme"), and my brief says do not restyle.
Two candidate fixes, for the owner/art lane to choose:

1. **Correct fix (art lane, reversible).** Re-cut the four plates tight - `staging/phase_f/plates_cut.py`
   already does exactly that (`box_1x 280×56`, `box_2x 560×112`), or fix the crop rule in
   `staging/cut/cut_sheets.py` so `cut/ui/ui_button_plate_*.png` is the plate box instead of
   the cell (it currently keeps the whole cell, `pieces: 11`), then re-pull
   (`staging/cut/pull.py`) and re-import. The same re-cut is needed for the bezel, the four
   slot families, the panel frame and the wordmark crop.
2. **Stopgap (theme lane, needs a doc amendment).** Set `region_rect` on the four plate
   `StyleBoxTexture`s to the art's `used_rect`, in `tools/build_theme.gd`, and rebuild the
   theme. Note that nine-slice `texture_margin_*` **cannot** fix this art: the vertical
   letterbox margins would be 477/477 px against a 70 px plate rect, so the engine clamps them
   and the plate still collapses - the transparent bands have to be cropped, not sliced. Both
   options contradict `MAIN_MENU_V2.md` §15.4's "the theme's plate `StyleBoxTexture`s carry
   **no** patch margins".

I therefore claim no fix for B2-1, and nothing here should be read as approval of the look:
the defect above is measurable, the *look* is the owner's call (`19_testing_notes.md` B2-1
still needs the direction pick - animated flicker, directional glow, or ember carried by the
tick band).

### B2-2 — soft backdrops — **defect found and measured, NOT fixed (art-side)**

**The filter/mip/scale hypothesis is wrong for the backdrops, and the real defect is source
resolution against the project's own physical-scale law.** Measured:

* Sampling path is correct: `MenuBackdrop` draws 2048×1152 into a 2016×1176 rect
  (`covered_scale 1.0208`, x 0.9844 / y 1.0208 - the y axis is above 1:1 by design, because
  the drift slack adds 96 px); `StationBackdrop` and `LoadingBackdrop` draw 2048×1152 into
  1920×1080 (`0.9375`). All three set `texture_filter = 0` (PARENT_NODE, so the project's
  `default_texture_filter = 2` applies) and all three ship `mipmaps/generate=false`, so no mip
  chain exists to blend and no filter choice can blur them: at 1080p they are at or below
  native. Their `used_rect` is the whole frame, so they are *not* victims of the cell-cut
  regression.
* The resolution law: `ICONS_SPEC.md` §9.1 (48 px icon: 1080p 1.0× "native - fine", 1440p
  1.33× "upscaled - soft", 4K 2.0× "visibly soft") and §9.2 (worst supported case 2.5×
  physical). The backdrops are 1.0667× the 1920×1080 design canvas, so the effective texel
  ratio is *physical scale × drawn scale*: 1080p → 0.9375/1.0208 (fine); 1440p → **1.250**
  (station, loading) and **1.361** (menu); 4K → **1.875 / 2.042**. Only above 1080p do they
  go soft, and they are the only large element without a higher-resolution variant: icons ship
  the `_16/_48/_96/_192` quartet, chrome was supposed to ship `@2x` cuts
  (`UI_CHROME_ASSETS_SPEC.md` §10) and **none exist any more** - measured 0 files matching
  `*@2x*` under `vajb-orbit/`, 0 records in `asset-library/_library.json`, and
  `staging/cut/_deleted_by_redesign.json` lists all 19 `@2x` `.import` sidecars as deleted.
  The in-game "sector" backdrop is the same story: `env_stars_layer{1,2,3}.png` are 2048×2048
  tiles drawn 1:1 in world space (`game.tscn`), with no mips and no 2× variant.
* The mip half of the hypothesis *does* fire elsewhere, and is worth its own line: the tint
  stencil family lost the F.1/F.2 import settings (1 080 files, `mipmaps/generate=false`), and
  the HUD draws `icon_zoom_{plus,minus}_96.png` (96 px) inside 28×28 boxes = **3.43 texels per
  pixel** with no mip chain, the one place in the HUD that minifies hard. Pointing those two
  buttons at the `_48` cuts (1.71×, nearest at 1080p, 1.3× at 1440p) is the fix that matches
  `ICONS_SPEC.md` §9.2, and the HUD's own 48×48 cargo button already keeps 1:1
  (`icon_cargo_container_48.png`, measured `texels_per_px = 1.0`). I did not touch
  `hud.tscn`: it is a scale mismatch in a different element from the one B2-2 names, so it is
  reported rather than smuggled into this diff.

Fix recipe (art lane, per §10's "display size stays logical, the file is the 2× cut"):
a 2× backdrop cut per family and the scene pointed at it at half scale - ≥3840×2160 for the
station/loading rects and ≥4032×2352 for the menu, whose covered draw needs 2016×1176 before
the 2× is applied. No sampler change can add detail to an upscale, which is why
`texture_filter`/mip edits would not have closed this item.

---

## 4. Acceptance, as measurements

| Item | Acceptance measurement | Result |
|---|---|---|
| B2-3 | `%ZoomPlus` / `%ZoomMinus` emitted delta → world radius at 3200, clamp 800-6400, step 800 | **PASS**: `-1` → 2400 (zoom in), `+1` → 4000 (zoom out) |
| B2-3 | universal gate `res://tests/headless_runner.tscn --quit-after 1200` | **PASS**: `[SUMMARY] passed=78 failed=0`, rc 0 |
| B2-3 | project files modified | exactly `vajb-orbit/ui/hud/hud.gd` (+447 bytes) |
| B2-1 | plate art ink inside the drawn plate rect | **FAIL (defect)**: 287.1×8.6 px of 350×70, transparent share 0.900 |
| B2-1 | hover affordance vs `UI_SPEC.md` §2.2 "6 px **soft** halo" | **FAIL (defect)**: flat `StyleBoxFlat` band, `corner_radius 0`, alpha 0.60, plus a 1 px rect - two concentric rectangles, i.e. the owner's report |
| B2-1 | menu wordmark crop intersects the art | **FAIL (defect)**: region `(44,707,1961,615)` over a 2170×823 file, 0 ink pixels |
| B2-1 | live look at ≥1152 px | **NOT RUN** - visual, owner-owned (section 5) |
| B2-2 | backdrop draw scale vs its source | **PASS at/below native**: 0.9375 (station, loading), 1.0208 (menu) |
| B2-2 | backdrop source vs supported physical scale (§9.1/§9.2) | **FAIL (defect)**: 1.0667× the design canvas → 1.250× (1440p) / 1.875× (4K) upscale, no 2× variant ships |
| B2-2 | `@2x` cuts present | **FAIL (defect)**: 0 files in `vajb-orbit/`, 0 records in the library, 19 sidecars listed deleted |
| B2-2 | tint stencil import settings vs ICONS_SPEC §9.8 stage 4 | **FAIL (defect)**: 1 080 stencils `mipmaps/generate=false`; 270 non-tint `_96` keep `true` |

---

## 5. Owner verification still outstanding

1. **B2-1 cannot be approved by me** and is not claimed fixed. What the owner must look at:
   the main menu in a **standalone 1920×1080 run**, and again at **2560×1440**, at a captured
   width of **at least 1152 px** (per the project's godot-ai note, a 640 px capture loses the
   1 px rectangle; use `editor_screenshot` with `max_resolution` 0/1152, or better a
   standalone run so the editor's embedded view does not own the window). Three questions:
   (a) is the wordmark visible at all (prediction: no - empty crop region),
   (b) does the PLAY plate read as a plate or as a thin horizontal bar (prediction: an 8.6 px
   bar with 90 % of the plate empty, per §2.4),
   (c) on hover, is the affordance the 6 px flat ember band plus a 1 px bright rectangle
   around an empty plate (prediction: yes) - and then the direction pick from
   `19_testing_notes.md` B2-1 (flicker / directional / tick-carried) so the hover look can be
   specced and implemented deliberately.
   `.agents/gen/batch2_evidence/hover_simulation.png` shows panels A-E (tight-crop art vs
   shipped art, idle and hover, at 3×); it is a re-implementation of the draw, **not** a
   screenshot, and the owner's eye remains the acceptance instrument.
2. **B2-2 needs one fact from the owner before the art batch is estimated**: the display
   resolution and the window the game actually runs at. The arithmetic predicts softness only
   above 1080p; if the backdrops look soft at 1920×1080, then what is left is the art itself
   (the deliberately defocused hangar the 2026-09-18 notes already flagged) and the item is a
   regeneration, not a cut. They should also confirm the station scrim (raised to 0.84 in
   wave 1) is still the intended contrast device once the backdrop is sharpened.
3. **The cell-cut regression needs an art-lane disposition before anything else on the menu is
   verified**, because it decides whether the wordmark, the plates, the bezel and the bar caps
   are re-cut (option 1) or patched in the theme (option 2), and it also fixes the `@2x` gap
   B2-2 depends on. Evidence for that lane: the three images in
   `.agents/gen/batch2_evidence/`, the md5s and `used_rect` numbers above, and
   `staging/cut/_deleted_by_redesign.json`.
4. Docs to tick/amend once the above land (all read-only for this worker):
   `docs/gameplay/19_testing_notes.md` B2-1/B2-2/B2-3 dispositions, `MAIN_MENU_V2.md` §7/§15.4
   (plate art geometry and the "no patch margins" sentence), `ICONS_SPEC.md` §9.8 stage 4
   (the tint stencil import settings no longer hold) and §10 (`@2x` cuts no longer ship),
   `STATION_HUB.md` §… frame-band/margin note (the panel frame is now a 1782×1784 cell with
   ink `(104,104,1574,1576)` under a 32 px margin), and the IMPLEMENTATION_PLAN §9.8 follow-up
   for the zoom sign.
