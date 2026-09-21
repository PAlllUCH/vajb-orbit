# Designer report - slot-plate recovery and re-cut (dispatch_designer.md item 1)

- Batch: the **slot-plate re-cut**, the BLOCKER at the top of the graphics queue.
- Date: 2026-09-21. Spend: **0 kie.ai runs** - this batch is local recovery, not generation.
- Status: **staged and integrity-checked, awaiting the owner review sheet.** Nothing shipped.
- Review sheet: `staging/phase_f/_preview/review_slots.png` (+
  `review_slots_table.txt` for the numbers, `recut_slots_report.json` for the raw data).
- Integrity check (owner's rule, 2026-09-21): `staging/phase_f/_preview/qc_slots.png` +
  `qc_slots_table.txt` + `qc_slots.json` - **24 of 24 cuts pass** ink-box-vs-plate-box and
  opacity, and the sheet was looked at (the read is in "The vision check" below).

## What the shipped files actually are

Measured on all twelve, not inferred:

| family | shipped size | opaque | alpha ink box | what the alpha holds |
|---|---|---|---|---|
| `ui_slot_weapon_*` | 880x876 | 9.0 % | 528x300 | the pistol silhouette only |
| `ui_slot_cargo_*` | 873x864 | 7.1 % | 357x388 | the crate silhouette only |
| `ui_slot_inventory_*` | 882x870 | 7.2-22.6 % | 498x485 | the module silhouette only |

The brief called them "whole sheet cells"; the defect is worse. The plate is absent from
the alpha entirely: the paid matte kept the bright silhouette and keyed the dark slot
plate out along with the white sheet background (the documented "matte inverts on flat
icons" failure - the reason `key_flat.py` exists). The plate's pixels do survive in RGB
under `alpha == 0` (transparent region mean RGB (22,24,26) ~ gunmetal `#2B2F35` on
`cargo_normal`, one step brighter on `cargo_hover`, i.e. the prompt's state ladder).

Consequence for the brief's fix route: `plates_cut.py` route 1 cannot apply. The ink box
*is* the silhouette box, so a tight crop of the shipped files ships a floating pistol, not
a 48x48 slot plate. No crop rule recovers a plate that is not in the alpha.

## Where the originals were: Godot's import cache

`.godot/imported/<source>-<hash>.ctex` is a `GST2` blob whose payload is the imported
image as lossless WebP (VP8L), so the pixels come back exactly. Audited all 3698 cached
textures: **3412 still have their source on disk, 286 are orphans** - the pre-2026-09-21
art the redesign deleted.

For these three families the cache held everything, at full resolution:

- 3x raw 2048x2048 sheets (RGB) and 3x keyed alpha sheets (RGBA) - `_sheets/`;
- 12x per-state source cells, 797-806 px square - the cells F.1 cut from;
- 12x the F.1 `@2x` cuts themselves (96/80/112 px) - the artefacts the redesign deleted.

## What I built

| file | what it does |
|---|---|
| `staging/phase_f/recover_ctex.py` | GST2 -> PNG decoder. `--list`/`--orphans`/`--inventory`, `--get <names>`. Read-only on `.godot/`, refuses any output path inside `vajb-orbit/assets/`, writes a `provenance.json` (ctex path, ctex hash, Godot's own `source_md5`, decoded md5). |
| `staging/phase_f/recut_slots.py` | re-cuts the 12 states at 1x and `@2x` from the recovered cells, importing `chrome_2x.SIMPLE` and `chrome_2x.content_crop` so the recipe keeps one source of truth. `--backup` snapshots the shipped bytes first. |
| `staging/phase_f/build_slot_review.py` | the owner review sheet. |

Recovered to `staging/phase_f/_recover/ui_slots/` (12 cells + `_sheets/` + two
`provenance.json`), 35 MB, staging only - nothing entered `assets/` from the cache.

The recipe is the one F.1 already proved (`chrome_2x.py --check`: mean absolute channel
error 0.0 against the then-shipped files): alpha bounding box, no pad, then LANCZOS to the
box. Both bands come from the same cell by the same rule.

## The proof, and the numbers

`recut_slots.py` compares its derived `@2x` against the F.1 `@2x` recovered from the same
cache. That is what proves the recovered cell is the cell F.1 used, and therefore that the
1x cut from it is the F.1 1x.

- **12 of 12 proven** by `chrome_2x.proven()`'s own bar (byte-exact, or <= 4 levels worst
  and <= 0.1 mean). Byte-exact on `ui_slot_weapon_disabled`; mean <= 0.0023 with max 2-3
  levels on the other eleven.
- Every 1x cut **inks its full box** (`0,0..48,48` etc.), alpha mean 254.3-255.0, solid
  share 91-99.9 % - a plate at full opacity, not a 90 %-transparent cell.
- The files shipping today are **70-97 mean levels** away from the F.1 cut at the same
  box: the regression quantified.
- `1x` vs `@2x`-halved: mean 1.4-3.3 levels - the expected resampling difference for a
  detailed plate, recorded for the F.2-style same-art check.

Boxes are `UI_CHROME_ASSETS_SPEC` sections 4 and 5 plus section 10's `@2x` table: weapon
48x48 / 96x96, cargo 40x40 / 80x80, inventory 56x56 / 112x112. 24 files staged in
`staging/phase_f/ui/`.

## The vision check

`staging/phase_f/qc_cuts.py` is the tool the owner's rule asks for: it measures every cut
(canvas against the expected box, alpha>0 and alpha>=128 ink boxes, alpha mean, solid and
clear shares) and draws the same cuts on a mid-grey checkerboard at 3x with the expected
box outlined, so a missing border, a gutter, a neighbouring cell's ink or a clipped plate
is visible rather than asserted.

Measure - 24 of 24 pass:

| family | canvas | ink box | alpha mean | solid | clear |
|---|---|---|---|---|---|
| weapon 1x / @2x | 48x48 / 96x96 | the full box, all 4 states | 254.2-255.0 | 91.1-99.9 % | 0.0 % |
| cargo 1x / @2x | 40x40 / 80x80 | the full box, all 4 states | 254.3-254.9 | 92.9-98.5 % | 0.0 % |
| inventory 1x / @2x | 56x56 / 112x112 | the full box, all 4 states | 254.3-254.8 | 92.1-97.9 % | 0.0 % |

Look (the sheet, `qc_slots.png`): every tile's ink reaches the ember outline on all four
sides - no gutter, no neighbouring cell's ink, no clipped silhouette. Each family reads as
a dark gunmetal plate with its own thin border and film grain, with the state ladder
visible: normal flat, hover one step brighter on both plate and border, pressed darkened
with a deep inset frame, disabled flattened and desaturated with the silhouette at roughly
40 %. No tile is the shipped defect (a floating silhouette on transparency). The plates are
deliberately quiet - `UI_CHROME_ASSETS_SPEC` section 3's policy is that HUD slots never
glow - so a dark recessed read is the design, not a keying loss.

## Files touched

| file | note |
|---|---|
| `staging/phase_f/recover_ctex.py` | new: GST2 -> PNG decoder, `--list`/`--orphans`/`--inventory`/`--get`, writes `provenance.json` |
| `staging/phase_f/recut_slots.py` | new: the re-cut + the @2x-vs-cache proof + `--backup` |
| `staging/phase_f/qc_cuts.py` | new: the integrity check (measure + contact sheet) |
| `staging/phase_f/build_slot_review.py` | new: the owner review sheet |
| `staging/phase_f/chrome_2x.py` | portability only: `WORKSPACE` derived from `__file__` instead of the hardcoded Windows path |
| `staging/phase_f/apply_import_settings.py` | portability only, same one-line change |
| `staging/phase_f/ui/generation_log_phase_f.md` | the recovery provenance section (ships next to the family) |
| `staging/phase_f/ui/*.png` | 24 staged cuts |
| `staging/phase_f/_recover/ui_slots/` | 12 source cells + 6 raw 2K sheets + `provenance.json` |
| `staging/phase_f/_recover/_shipped_before/` | the restore point (12 shipped PNGs + their `.import`) |

## Exactly what happens on approval

1. `git show 65bc1cb^:<path>` for the twelve `*@2x.png.import` sidecars the redesign
   deleted - restores the F.1 uid and the `@2x` import settings (mipmaps on, lossless, 3D
   detection off) unchanged.
2. `py staging/phase_f/ship_batch.py ui --only <24 names>` - copies the staged PNGs into
   `vajb-orbit/assets/ui/` and the updated `generation_log_phase_f.md` beside them.
3. Reimport the 24 paths through the running editor (`filesystem_manage reimport`) - the
   editor session `vajb-orbit` is up and stopped; the game must not be playing.
4. Verify by reading each new `.ctex` header back: 48/40/56 and 96/80/112. That proves the
   import picked up the new bytes rather than recording mtimes only.
5. Screenshot the three consumers (shipyard hardpoints, launch-panel cargo slots, HUD slot
   row) and attach them to the close-out.

Reversal: the twelve shipped 1x files and their `.import` sidecars are already snapshotted
in `staging/phase_f/_recover/_shipped_before/` (first run wins; re-running cannot overwrite
the pre-recovery bytes); the `@2x` files did not exist in the project before this pass, so
deleting them and their restored `.import` returns the tree to today's state.

## Owner decisions at the gate

1. Ship the `@2x` band as well, or the 1x band only? Both are staged; nothing in code or
   theme references `@2x` today (it is the HD/4K band, and the redesign deleted every
   `@2x` cut - queue item 3, R8).
2. Ship `ui_slot_inventory_*`? No code or theme references it; `UI_CHROME_ASSETS_SPEC`
   section 5 and the F.1 pass both include it ("one slot class cannot ship two reads"), and
   the brief's item 1 forgot to name it.
3. Does the plate read approve? The state ladder is normal = flat plate with a thin border,
   hover = plate and border one step brighter, pressed = darkened with a visible inset
   frame, disabled = flattened and desaturated with the silhouette at ~40 %.

## Follow-ups (not done in this batch)

- **The cache still holds 235 more orphans**, i.e. most of R7/R8 can be recovered the same
  free way: `ui_button_plate_*@2x.png` (560x112, ten mip levels), `ui_minimap_bezel@2x`
  (400x400), `ui_panel_frame@2x` (192x192) and `ui_panel_frame_96`, `ui_bar_caps@2x`
  (84x28), the logo sheet and the 2048 backdrop plate. `plates_cut.py`'s F.2 record already
  marks the four button plates "needs regeneration, one run, $0.05" - that estimate can be
  retired if the recovered `@2x` is accepted.
- `apply_import_settings.py` reports **1080 of 1620** `.import` files still missing the
  F.1/F.2 quartet settings (mipmaps on, lossless, 3D detection off) - the R8 tint-stencil
  defect. It has no `--only` filter, so running it now would sweep that whole set; it needs
  to be part of the R8 batch, not this one.
- Eleven staging tools still hardcode the Windows workspace path
  (`staging/phase_d/probe.py`, `wave1.py`, `phase_e/wave_e.py`, and in `phase_f`:
  `aspect_probe.py`, `build_f1_review.py`, `legacy_probe.py`, `qc_f1.py`, `recut_quartet.py`,
  `rekey_halo.py`, `stage0_reconcile.py`, `wave_f.py`). I ported only the two this batch
  needed (`chrome_2x.py`, `apply_import_settings.py`) to `Path(__file__).resolve().parents[2]`,
  the pattern `ship_batch.py` and `qc_f2.py` already use.
- `qc_f2.py plates` audits only the four button plates and **overwrites**
  `staging/phase_f/f2_report.json` with just that section. I ran it once, clobbered the
  tracked F.2 record, and restored it from git; the slot numbers live in
  `recut_slots_report.json` instead.
