# D6 report: defringe the insignia sprite edges

Worker: coder. Date: 2026-09-18. Interpreter: `py -3.14` (python.org 3.14, Pillow 12, numpy, scipy).
No image API was called, no alpha value was recomputed, no file outside the four targets was modified.

## 1. Reproduction of the defect (before writing anything)

`py -3.14 staging/phase_d/cleanup_fringe.py ui` (dry run) confirms the existing pass does not see these files:

```
 edgeW  peeled  file
DRY RUN: 0 files
```

Baseline measured with Pillow from the pristine originals (later re-measured from the backups and byte-identical):

| file | size | band px | band mean L | band max L | band frac > 175 | band px > 175 | opaque px | opaque mean L | opaque px > 175 | alpha == 0 | alpha == 255 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| ui_insignia_neutral.png | 780x894 | 10466 | 168.139 | 255.0 | 0.614657 | 6433 | 494439 | 38.128 | 3073 | 192415 | 493567 |
| ui_insignia_mic.png | 776x889 | 10497 | 170.541 | 255.0 | 0.624369 | 6554 | 490320 | 50.795 | 12169 | 189047 | 489449 |
| ui_insignia_ven.png | 783x894 | 10471 | 167.921 | 255.0 | 0.617897 | 6470 | 495574 | 44.721 | 7597 | 193957 | 494705 |
| ui_insignia_mmo.png | 779x891 | 10826 | 168.610 | 255.0 | 0.610290 | 6607 | 492474 | 47.111 | 8085 | 190789 | 491479 |

Definitions used throughout: band = `1 <= alpha <= 249`, opaque = `alpha >= 250`, luminance = ITU-R 601-2 `0.299R + 0.587G + 0.114B` (the weights Pillow uses for `L`). The brief's numbers reproduce: band RGB is near white (mean 168 to 171 of 255, 61 to 62 percent of band pixels above 175) while the interior is dark (opaque mean 38 to 51).

## 2. The tool

Created `staging/phase_d/defringe_edges.py`. For each pixel with `0 < alpha < 250` it replaces RGB with the RGB of the nearest fully opaque pixel, located by `scipy.ndimage.distance_transform_edt` over the matte (`return_indices`), so the replacement colour follows the local interior. Alpha is never written. Pixels with `alpha == 0` and `alpha == 255` are copied through untouched. Files with no band or no opaque pixel are skipped. A file whose band would not change is not rewritten at all, which makes the pass byte-level idempotent. Backups go to `staging/phase_d/_fringe_backup/<filename>` and are written only when the destination does not already exist. CLI: `py -3.14 staging/phase_d/defringe_edges.py [--apply] [paths ...]`, dry run by default, default targets are the four insignia.

## 3. Dry run

`py -3.14 staging/phase_d/defringe_edges.py`

```
  band  lumBef  lumAft  changed  file
 10466   168.1    17.8    10427  ui_insignia_neutral.png
 10497   170.5    18.5    10462  ui_insignia_mic.png
 10471   167.9    16.5    10451  ui_insignia_ven.png
 10826   168.6    25.5    10782  ui_insignia_mmo.png
DRY RUN: 4 files, 42122 edge pixels would change, 0 missing
```

Nothing was written by the dry run: `staging/phase_d/_fringe_backup/` contained no `ui_insignia_*` entry afterwards, and all four files still hashed to their baseline values (see section 5).

## 4. Apply and idempotence

Run 1, `py -3.14 staging/phase_d/defringe_edges.py --apply <the four paths>`:

```
  band  lumBef  lumAft  changed  file
 10466   168.1    17.8    10427  ui_insignia_neutral.png
 10497   170.5    18.5    10462  ui_insignia_mic.png
 10471   167.9    16.5    10451  ui_insignia_ven.png
 10826   168.6    25.5    10782  ui_insignia_mmo.png
APPLIED: 4 files, 42122 edge pixels changed, 0 missing
```

Run 2, same command:

```
  band  lumBef  lumAft  changed  file
 10466    17.8    17.8        0  ui_insignia_neutral.png
 10497    18.5    18.5        0  ui_insignia_mic.png
 10471    16.5    16.5        0  ui_insignia_ven.png
 10826    25.5    25.5        0  ui_insignia_mmo.png
APPLIED: 4 files, 0 edge pixels changed, 0 missing
```

Run 3, same command, re-measured afterwards: also `0 edge pixels changed`, and the four sha256 values were identical to the values measured after run 2 (`3685cbd5...`, `02a82d99...`, `98bffc15...`, `5b9d1dc7...`). Because the script only writes when the changed count is above zero, run 2 and run 3 wrote nothing, so the second application is byte-identical by construction and by hash. A post-apply dry run also reports `DRY RUN: 4 files, 0 edge pixels would change, 0 missing`.

## 5. Verification

Band and interior after the pass (measured from the current files, after runs 2 and 3):

| file | size | band px | band mean L | band max L | band frac > 175 | band px > 175 | opaque px | opaque mean L | alpha == 0 | alpha == 255 |
|---|---|---|---|---|---|---|---|---|---|---|
| ui_insignia_neutral.png | 780x894 | 10466 | 17.784 | 201.88 | 0.002293 | 24 | 494439 | 38.128 | 192415 | 493567 |
| ui_insignia_mic.png | 776x889 | 10497 | 18.546 | 255.0 | 0.005716 | 60 | 490320 | 50.795 | 189047 | 489449 |
| ui_insignia_ven.png | 783x894 | 10471 | 16.450 | 146.05 | 0.0 | 0 | 495574 | 44.721 | 193957 | 494705 |
| ui_insignia_mmo.png | 779x891 | 10826 | 25.499 | 255.0 | 0.011731 | 127 | 492474 | 47.111 | 190789 | 491479 |

Before to after: band mean luminance 168.1 to 17.8, 170.5 to 18.5, 167.9 to 16.5, 168.6 to 25.5. Band pixel count, opaque pixel count, `alpha == 0` count and `alpha == 255` count are unchanged, and opaque mean luminance is unchanged to three decimals, which is expected only if no opaque pixel was touched.

Pixel-level before/after comparison against the pristine backups:

| file | dims identical | alpha array identical | RGB changed | changed where alpha == 0 | changed where alpha == 255 | changed in band | band px |
|---|---|---|---|---|---|---|---|
| ui_insignia_neutral.png | true | true | 10427 | 0 | 0 | 10427 | 10466 |
| ui_insignia_mic.png | true | true | 10462 | 0 | 0 | 10462 | 10497 |
| ui_insignia_ven.png | true | true | 10451 | 0 | 0 | 10451 | 10471 |
| ui_insignia_mmo.png | true | true | 10782 | 0 | 0 | 10782 | 10826 |

The changed counts equal the changed counts the dry run and the apply predicted (42122 in total), all of them inside the band. 0 pixels with `alpha == 0` and 0 pixels with `alpha == 255` changed RGB, as required.

Whole-alpha-channel sha256, before versus after, identical for all four:

```
neutral 95dbe2fb1a9df3045835b00b2a9d3f51c80021bf65eb40b3760d9dca947a51e6  same after
mic     c37b747c8f7b975d31687f3a0a0030bd5c7fdd78f45e7ed14fcd9cbc752adaf7  same after
ven     cf1ffe3176febf5017ac106dec03d50325fb26b96043c9586450c11c39e1dea0  same after
mmo     69186d4c50f8e5d2b25901eec82e98b8a0fd32e3fa5917e4a474a82384ca1d5a  same after
```

File sha256, before versus after:

| file | before | after |
|---|---|---|
| ui_insignia_neutral.png | 8bca23f864923f234574bb94ff7a7251956bbae40f2d86426f11192223c90db7 | 3685cbd5d361edd78998400543a6d8feced39df1efd1987f3259949679508625 |
| ui_insignia_mic.png | 0afc0faf5a4add2ae63b0e6b2ec63964d002cfaff819d61438fc611e768e7d8c | 02a82d99650cc3a13f8f57b5f326744ba9b8d8404b6ae0dc1899ef1fcdd5568e |
| ui_insignia_ven.png | 888920082088701c5d3c80f121cf009a0989c8128e769ac258fb2de2b536f5f2 | 98bffc15b9712714db84bdae7d728814b1946edbe15c0fbb84750683add82b6f |
| ui_insignia_mmo.png | acaa862d7c9993b3273b29471d7cbde746af27c1ae74ce2c2035a0d779dec7c3 | 5b9d1dc798b122fa5a93c582a56acedd13d8a8d73c9a6e9e2fc47c0bc47f2122 |

File sizes moved from 1115179 to 1101649, 1137407 to 1123832, 1137761 to 1123918 and 1153663 to 1141622 bytes, consistent with the near-white noise in the band compressing differently. The originals carried no ancillary PNG chunks (`im.info` was empty), so no metadata was dropped by the rewrite.

Scope check: a sweep of `vajb-orbit/assets/` for files modified in the last six hours lists exactly the four target PNGs and nothing else. No other family, no `.import` sidecar, no `project.godot`, no `addons/` file was touched.

## 6. Residual bright band pixels

After the pass, 24 of 10466 (neutral), 60 of 10497 (mic), 0 of 10471 (ven) and 127 of 10826 (mmo) band pixels remain above luminance 175. These are not residual background key: each band pixel now carries exactly the RGB of its nearest opaque pixel, and those four files contain 3073, 12169, 7597 and 8085 opaque pixels that are themselves above 175 (bright interior detail such as plate highlights). A band pixel adjacent to such detail legitimately inherits a bright colour. The 0-change second run is the proof that every band pixel already equals its nearest opaque neighbour, so no further gain is available from this approach without changing alpha or blurring interior detail.

## 7. Intact pre-change originals

`staging/phase_d/_fringe_backup/ui_insignia_neutral.png`, `..._mic.png`, `..._ven.png`, `..._mmo.png`. Sizes 1115179, 1137407, 1137761, 1153663 bytes. Their sha256 values are exactly the `before` column in section 5, so they are the pristine, pre-change art. They are written only when absent, so re-running the tool never overwrites them. Note this directory is shared with the existing `cleanup_fringe.py` backups; the insignia filenames did not exist there before this task.

## 8. Documentation

Appended one paragraph to the derived-art section of `docs/ASSETS.md` (line 60, directly after the icon-tint entry, same voice): the pass, the tool path, the four files, the light-background keying reason, the fact that `cleanup_fringe.py` misses them, the invariance guarantees, the idempotence, the backup directory, and the reimport note. The rest of the document was not modified.

## 9. Editor state

The four PNGs are rewritten on disk but not reimported. **The editor will need to reimport these four files before the change is visible in the engine**; the orchestrator does that step. A running game would also need a restart since the textures are already loaded.

## 10. What I could not verify

- No engine-side or editor-side check was performed, per the brief's boundary: no reimport, no `project_run`, no screenshot comparison inside Godot.
- The only visual check was a local composite over a dark backdrop (`#0d1117`) written to `.agents/gen/previews/d6_insignia_fringe.jpg` by the scratch helper `.agents/gen/d6_preview.py`. At thumbnail scale the before column shows the pale rim around the plate and emblem and the after column does not, but this is a sanity check, not a measurement in the engine. In that sheet the mmo plate shows a small orange patch at its top left in both the before and the after image, i.e. art carried over from the pristine file and untouched by this pass.
- Nothing about how the insignia actually look at their in-game scale, or on a light UI panel. The pass darkens the band, which is correct for dark panels; on a light panel the emblem boundary will now be slightly darker than before.
- No test suite covers `staging/phase_d/`. Verification is the measurements above, plus the byte-level idempotence of runs 2 and 3.
- Scratch helpers created for measurement are `.agents/gen/d6_measure.py` and `.agents/gen/d6_preview.py`. They are not deliverables and touch nothing under `vajb-orbit/`.

## 11. Deliverables

| Action | Path | State |
|---|---|---|
| create | `staging/phase_d/defringe_edges.py` | done |
| modify pixels | `vajb-orbit/assets/ui/ui_insignia_neutral.png` | done, 10427 RGB pixels in the band |
| modify pixels | `vajb-orbit/assets/ui/ui_insignia_mic.png` | done, 10462 RGB pixels in the band |
| modify pixels | `vajb-orbit/assets/ui/ui_insignia_ven.png` | done, 10451 RGB pixels in the band |
| modify pixels | `vajb-orbit/assets/ui/ui_insignia_mmo.png` | done, 10782 RGB pixels in the band |
| create backups | `staging/phase_d/_fringe_backup/ui_insignia_{neutral,mic,ven,mmo}.png` | done, pristine |
| edit | `docs/ASSETS.md` | done, derived-art entry only |
| create | `.agents/gen/d6_report.md` | this file |
