# UI chrome geometry regression — handover for the graphics lane + owner (2026-09-21)

Written by the coding orchestrator from the batch-2 playtest report
(`.agents/gen/batch2_report.md`, worker dispatched for `docs/gameplay/19_testing_notes.md`
B2-1/B2-2/B2-3). **No asset, scene or theme file was changed here.** The batch-2
worker's set was `vajb-orbit/ui/hud/`, `ui/screens/main_menu.gd` and
`vajb-orbit/tools/`, so it could fix only the in-set item (B2-3) and had to
report the rest.

## What happened

`vajb-orbit/assets/ui/*` and the icon families were re-cut and re-pulled on
**2026-09-21 00:17–00:18** by the cut redesign (`staging/cut/cut_sheets.py` +
`pull.py`), replacing the 2026-09-18 chrome. The new cuts keep a sheet **cell**
instead of the asset box, and the files that describe the old geometry
(`ui/theme/vajb_theme.tres`, 2026-09-18 18:42, and the `ui/components/` +
`ui/screens/` scenes) were not re-cut, re-margined or re-cropped to match. The
result is a measurable, visible regression on shipped screens.

## Measured defects (all engine-side, from batch-2's probe)

| Element | Measured | Consequence |
|---|---|---|
| `ui_button_plate_{normal,hover,pressed,disabled}.png` | 1041×1087 with ink only at `(93,477,947,610)` | the theme's bare `StyleBoxTexture` (no margins, no region) stretches the whole canvas into the 350×70 plate → the painted plate renders **287.1 × 8.6 px** and **90.0 % of the plate is transparent** |
| Hover affordance | flat `StyleBoxFlat` band, `corner_radius 0`, `menu_glow` alpha 0.60, + a 1 px `text_primary` rect | reads as two concentric rectangles, exactly the owner's B2-1 report; `UI_SPEC.md` §2.2 asks for a 6 px *soft* halo |
| `logo_vajb_orbit.png` | now 2170×823 (ink rows 130–693) | `main_menu.tscn` still crops `AtlasTexture Rect2(44, 707, 1961, 615)`, a region with **0 ink pixels** → the wordmark cannot be drawing |
| `ui_minimap_bezel.png` | 1063×1065 in a 200×200 nine-patch, 16 px margins | the frame band draws **3.0 px** instead of 16 |
| `ui_bar_caps.png` | 317×178 with ink `(1,1,316,178)`; the two `AtlasTexture` regions are `(0,0,20,14)` / `(22,0,20,14)` | both caps crop the wrong part of the cell (ink shares 0.46 / 0.87) |
| `ui_slot_weapon_*` etc. | e.g. 880×876, ink `(175,287,531,303)` | same cell-vs-box class of defect in 48×48 slots |
| Backdrops | 2048×1152 drawn at 0.9375 / 1.0208, `mipmaps/generate=false` | fine at 1080p; **1.250× at 1440p and 1.875× at 4K** because **every `@2x` cut is gone** (0 files in `vajb-orbit/`, 0 library records, 19 `.import` sidecars listed in `staging/cut/_deleted_by_redesign.json`) |
| Tint stencils | 1 080 files with `mipmaps/generate=false`, `detect_3d/compress_to=1` | lost the F.1/F.2 import settings that `ICONS_SPEC.md` §9.8 stage 4 specifies |
| HUD zoom buttons | `icon_zoom_{plus,minus}_96.png` in 28×28 boxes = **3.43 texels/px**, no mips | the one hard minification in the HUD; the `_48` cuts are the §9.2 fix |

## Fix routes (for the owner / art lane to choose — batch-2 claims none)

1. **Art lane, correct and reversible.** Re-cut the four plates tight with
   `staging/phase_f/plates_cut.py` (`box_1x 280×56`, `box_2x 560×112`), or fix the
   crop rule in `staging/cut/cut_sheets.py` so `cut/ui/ui_button_plate_*` is the
   plate box rather than the whole cell, then re-pull and re-import. The same
   re-cut is needed for the bezel, the four slot families, the panel frame, the
   bar caps and the wordmark crop.
2. **Theme lane, stopgap.** Set `region_rect` on the four plate
   `StyleBoxTexture`s to the art's `used_rect` in `tools/build_theme.gd` and
   rebuild. Note nine-slice margins **cannot** fix this art: a 477 px letterbox
   margin against a 70 px plate rect clamps and the plate still collapses. Both
   routes contradict `MAIN_MENU_V2.md` §15.4's "no patch margins", so the owner
   picks.
3. **B2-2's outstanding fact:** the display target to design for (1080p only, or
   1440p/4K) decides whether a 2× backdrop cut per family is owed at all.

## Owner gates still open

- **B2-1 is not approved and not fixed.** The owner must look at the main menu in
  a standalone 1920×1080 run and again at 2560×1440, captured at ≥1152 px, and
  then pick the hover direction from `19_testing_notes.md` B2-1 (flicker,
  directional glow, or ember carried by the tick band).
  `.agents/gen/batch2_evidence/hover_simulation.png` shows the predicted states
  (panels A–E) but is a re-implementation of the draw, not a screenshot.
- **B2-2's display-target question.**
- The tint-stencil import settings and the `_48` zoom-button swap are cheap
  follow-ups once the art route is chosen.

## Where the code stands

`ui/hud/hud.gd` carries the one code fix from this lane: the minimap zoom deltas
are renamed to the direction they mean and the two `pressed` bindings swapped
(measured: `%ZoomPlus` → −1 → radius 3200→2400, `%ZoomMinus` → +1 → 3200→4000).
The gate is green (78/78). `docs/gameplay/19_testing_notes.md` B2-3 and the
`IMPLEMENTATION_PLAN.md` §9.8 line it asks for still need ticking — the batch-2
worker's set excluded `docs/`.
