# Designer report - cache-orphan recovery and the R7 chrome batch

- Batch: the **cache-orphan route** the owner approved on 2026-09-21, plus the **R7 chrome
  re-cut** that follows the slot plates.
- Spend: **0 kie.ai runs.** Everything came out of Godot's import cache.
- Status: **staged and integrity-checked, awaiting the owner review sheet.** Nothing shipped.
- Review sheet: `staging/phase_f/_preview/review_chrome.png`; QC:
  `staging/phase_f/_preview/qc_chrome.png` + `qc_chrome_table.txt` + `qc_chrome.json`
  (**15 of 15 pass**); numbers: `recut_chrome_report.json`.
- Ship order respected: the slots ship first (`designer_slots_report.md`), this batch after.

## The orphan inventory

`.godot/imported/*.ctex` is a `GST2` blob holding the imported image as lossless WebP, so
the pixels come back exactly - not a re-render. Audited all **3698** cached textures:

| | count | bytes |
|---|---|---|
| cached with the source still on disk | 3412 | - |
| **orphans (source gone)** | **286** | **489.5 MB** |

By kind: 269 PNG, 16 JPG (staging probes: `check.jpg`, `preview_*`, `crop_compare.jpg`), 1
SVG (`icon.svg`, 128x128). By family: 139 "other" sheets (icon/FX/panel sheets), 58
chrome/sheet, 37 ships, 20 env, 16 icons, 16 probe JPG.

The 286 include the **entire raw 2K corpus** of the pre-09-21 passes - ships, enemies,
asteroids, moons, stations, FX and icon sheets - not just chrome. This batch recovers the
chrome set (28 files) and files the rest by lane below. Disk cost is why it is not all
recovered at once: the 2048x2048 sheets run 2-5 MB each.

## What was recovered and how each band is cut

Recovered into `staging/phase_f/_recover/ui_chrome/` (19 cut artefacts + 11 sheets) and
`_sheets/` + `_plates/`, each with a `provenance.json` entry carrying the ctex path, the
ctex hash, Godot's own `source_md5` from its sidecar, and the decoded md5.

Every route is justified by a number, never by taste:

| item | file | route | the number |
|---|---|---|---|
| menu button plates | `ui_button_plate_{normal,hover,pressed,disabled}` 280x56 / 560x112 | `@2x` verbatim from the cache, 1x = that `@2x` halved | F.2's own `plates_report.json` measured the pair **0.21 / 0.25 / 0.44 / 0.21** levels apart. The F.1 recipe was re-tested from the recovered cell and is **dead** (mean 27.7-37.9, max 255), which is the same failure `chrome_2x.py` recorded. |
| minimap bezel | `ui_minimap_bezel` 200x200 / 400x400 | as above | F.1 nine-patch, 16 px band at 200 and 32 px at 400. Cross-check: the F.1 recipe re-run from the recovered cell agrees with the halved `@2x` to **mean 0.2019 / max 16 levels** on the 1x, and to mean 0.0193 on the `@2x`. |
| bar caps | `ui_bar_caps` 42x14 / 84x28 | as above | the `@2x` is exactly 2x the 1x (two 40x28 caps, 4 px gap vs two 20x14 caps, 2 px gap) and `hud.tscn`'s `AtlasTexture_bar_cap_{left,right}` crop `Rect2(0,0,20,14)` / `Rect2(22,0,20,14)` - which now land on one cap each. |
| panel frame | `ui_panel_frame` 96x96 / 192x192 | as above | F.2 rebuilt it as 3x3 tiles of exactly size/3 (32 px band at 96, 64 at 192), so halving maps tile to tile; F.2 measured the drawn band 30 of 32 px (was 12). |
| wordmark | `logo_vajb_orbit` 2048x2048 | `logo` - keyed from the recovered raw render and normalised onto the frozen imprint | 13 of 293 bright components survive the area filter (the letters and their shadow); the starfield specks and the nebula do not. Scale 1.1081 x 1.1322; the staged ink box is **(56,719,1993,1310)**, exactly `IMPLEMENTATION_PLAN.md` line 46's imprint. |
| backdrop plates | 6x 2048x1152 | recovered as **candidates only** | queue item 4; nothing staged or shipped. `background-body-plate`, `docking-bay-interior-backdrop`, `starmap-backdrop`, `station-interior-wall-backdrop`, `wide-cinematic-top-down-orthographic`, `darker-tighter-recentered-crop`. |

The wordmark deserves the note: the cache holds the raw 2048x2048 render (wordmark on a
starfield, with a faint nebula) and its soft matte, which keeps the haze. A plain alpha or
luminance threshold keeps stray stars; an area filter alone keeps the nebula. The rule that
works is *bright and large*: `lum >= 90` AND `alpha >= 32`, labelled at 1/4 scale, keep
components of 12 cells or more, dilate 8 px to bring the soft edges and the near shadow
back, then gate the matte's own alpha with that mask. That is
`recut_chrome.py:key_wordmark()`.

## The vision check

Measure - 15 of 15 pass (`qc_chrome_table.txt`):

| item | canvas | ink box | alpha mean | clear |
|---|---|---|---|---|
| button plates 1x / @2x | 280x56 / 560x112 | the full box, all 4 states | 189.0-241.9 | 0.2-13.3 % |
| bezel 1x / @2x | 200x200 / 400x400 | the full box | 254.7 | 0.0 % |
| panel frame 1x / @2x | 96x96 / 192x192 | the full box | 249.9 | 0.5 / 0.8 % |
| bar caps 1x / @2x | 42x14 / 84x28 | the full box | 222.4 / 222.5 | 3.9 / 8.7 % |
| wordmark | 2048x2048 | (56,719,1993,1310) | 26.8 (the canvas) | 87.7 % |

The `pressed` plate is the dimmest (alpha mean 189, 12.5 % clear) because its art is the
inset darkened state - it is the F.2 cut, not a keying loss.

Look (`qc_chrome.png`): the button plates fill their box edge to edge with a rivet at each
end and the ladder reads (hover lighter with the ember under-light on the bevel, pressed
darker and inset, disabled dimmed); the bar caps show one riveted cap end filling 42x14 and
both engine windows land on a cap; the bezel and the panel frame are nine-patches whose
centre is painted (not transparent - that is how the F.1/F.2 art was authored, and the map
is drawn by the `MinimapView` child over it); the wordmark sits on the checkerboard with
its ink exactly on the frozen imprint.

Look (`review_chrome.png`, four sections): **(A)** the shipped column is a 9 px sliver
inside the theme's 350x70 plate, the staged columns are the whole plate; **(B)** the
engine's bar-cap window shows a scaled fragment of a sheet cell before and a riveted cap
after, and the two nine-patches draw a thin band before and the proper band after;
**(C)** the frozen `Rect2(44,707,1961,615)` crop is **empty** on the file in `assets/` today
and shows the full lockup on the staged file - the "Logo slot renders empty" report,
reproduced and fixed; **(D)** the six backdrop plate candidates.

## What is staged

`staging/phase_f/ui/`: **15 chrome files** (4 button plates x 1x/@2x, bar caps, bezel,
panel frame, wordmark) on top of the 24 slot files - 39 PNGs in the batch.

`staging/phase_f/_recover/_shipped_before/` holds the 12 slot restore points; this batch's
pre-images are the files the redesign pulled, all of which are still in `assets/` today
(nothing here has been overwritten yet, so shipping only needs a fresh snapshot at ship
time).

## Pairing: two of these need the coder lane

| item | engine side | state |
|---|---|---|
| button plates | theme stretches the texture into the plate - no change needed | ready to ship |
| bar caps | `hud.tscn` `AtlasTexture` regions `(0,0,20,14)` / `(22,0,20,14)` - no change needed | ready to ship |
| bezel | `NinePatchRect` 200x200 with `patch_margin_* = 16` - no change needed | ready to ship |
| wordmark | the frozen `AtlasTexture` region `Rect2(44,707,1961,615)` - no change needed | ready to ship |
| **panel frame** | **`build_theme.gd` `PANEL_FRAME_MARGIN` is 8.0 while the F.2 art's band is 32 px.** Shipping the art alone makes the drawn frame worse (the nine-patch would cut the corners at 8 px and stretch 4x of the band). The constant must go 8.0 -> 32.0 and the theme rebuild. `f2_report.json`'s "F.2 96" row already records 30 of 32 px as the pass. | **art staged, paired theme change owed** |

## Cache misses (nothing paid for)

One chrome item has no cache copy: the **4K `@2x` backdrop cuts** (`ui_backdrop_hangar`,
`ui_backdrop_login`, `ui_backdrop_starmap`). The cache holds each 2048x1152 source (the
project's own files, not orphans) and no `@2x`. Whether they are owed at all is B2-2's open
question - the display target (1080p only, or 1440p/4K) - so no run is proposed until the
owner rules on it. Everything else in R7 and in the slot batch is covered by the cache; the
`background-body-plate` and `station-interior-wall` plates recovered here are alternatives if
the owner would rather not regenerate.

## Left for the coder lane (not art)

- `PANEL_FRAME_MARGIN` 8.0 -> 32.0 (above).
- The B2-1 hover direction on the menu plates (the owner's pick: flicker, directional glow,
  or ember carried by the tick band).
- The HUD zoom buttons: switch `icon_zoom_{plus,minus}_96` to the `_48` cuts (the `_48`
  quartets exist in the project; this is a `hud.tscn` texture swap).
- `rc/mipmaps`: `apply_import_settings.py` still wants to rewrite **1080 of 1620** `.import`
  files and has no `--only`; running it is R8's, after the scoped flag lands.
- Module-rail icons and the OUTFITTING/REFINERY background alignment: the icon quartets are
  all present (no orphan), so if those read wrong it is rail-entry sizing or the panel
  frame's margin above, not missing art.

## Follow-ups

- The remaining **~258 orphans** (~470 MB) are other lanes' raw material: ships and enemy
  hulls (37), env and station sheets (20), FX and icon sheets, and the `panel_*` chrome
  sheets. `recover_ctex.py --list --orphans` prints them by name and size; recovering a
  lane's set is `--get` plus `--inventory` for the provenance record, at 0 cost.
- Eleven staging tools still hardcode the Windows workspace path (`phase_d/probe.py`,
  `phase_d/wave1.py`, `phase_e/wave_e.py`, and in `phase_f`: `aspect_probe.py`,
  `build_f1_review.py`, `legacy_probe.py`, `qc_f1.py`, `recut_quartet.py`, `rekey_halo.py`,
  `stage0_reconcile.py`, `wave_f.py`). Two of them - `chrome_2x.py` and
  `apply_import_settings.py` - were ported for this batch (`Path(__file__).resolve().parents[2]`,
  the pattern `ship_batch.py` and `qc_f2.py` already use).
- `qc_f2.py plates` audits only the four button plates and **overwrites**
  `staging/phase_f/f2_report.json` with just that section (it was clobbered once by me and
  restored from git). The batch numbers live in their own reports instead.
