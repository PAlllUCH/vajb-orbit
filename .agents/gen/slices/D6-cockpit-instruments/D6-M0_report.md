---
slice: D6
worker: D6-M0
model: "gpt-image-2-5-flare-text-to-image (flare) 2K + recraft/remove-background + authored SVG"
status: actionable
gate: "not run — no code or test file touched (art-only deliverable); the wave gate is measured at D6's code waves. M0b (reconcile + import) also ran no gate, same reason"
---

# D6-M0 report — cockpit instrument masters

## Result

All **18 masters** ship in `vajb-orbit/assets/ui/` at UI_CHROME_ASSETS_SPEC §11's boxes, plus the
**4 panel renders** as `panel_*` provenance in `vajb-orbit/assets/icons/`. AC5's digit QC **passes**
(containment 100.00 % on all 12 cells; `blank` 0.0000 < `1` 0.1329 smallest of the digits, `8`
0.3671 largest, no by-segment inversion).

The generator delivered **10 of the 18 masters** as plain render cuts. Eight are not plain cuts
because the render could not deliver them after three attempts each — reported in full under
*Deviations*; `AGENTS.md`'s escalation ladder puts every one of those in bucket 2 (a pinned number,
a pinned wording, or a `docs/` text would have to move to do it the generator's way), so they are
reported here and left untouched.

**STOPPED at the review sheet for owner approval.** No code work started; `ui/hud/**`,
`tests/**`, `project.godot`, `ui/theme/**` and all of `game/`/`autoload/` are untouched.

**Phase b (2026-09-24):** the owner approved the sheet, all 18 masters reconciled byte-for-byte
against §11's table, and the 22 new files unified on the family import quartet and imported by the
editor session. Details in **§M0b** below; no art byte and no code line changed.

Review sheet: `staging/phase_g/_review/d6_masters.png` (full size) /
`staging/phase_g/_review/d6_masters.jpg` (viewer copy, 173 KB) — all 18 masters drawn at their
logical box and at 2×, labelled.

## Deviations from SLICE.md / the brief

Everything below is a bucket-2 finding (it needs a pinned number or wording, a doc's text, or the
generator's own prompt to change). Nothing was silently reinterpreted.

1. **Nine renders were spent, not four.** `UI_CHROME §11`'s four fixes budgeted 4 × 2K = 40 credits
   ≈ $0.20; the wave actually cost **9 × 2K + 16 recraft keys = 106 credits ≈ $0.53**.
   | Attempt | `panel_instruments` | `panel_frame_glass` | `panel_sevenseg_a` | `panel_sevenseg_b` |
   |---|---|---|---|---|
   | 1 | `fcadff98fbf0fc2e1cb4f887e9dc181f` | `e29c22b49d7221d2237e46f07f90806d` | `02e4ad4ed437cd125cd6b42d4838e2e4` | `95295864fca94f31496c6b9aa0495d27` |
   | 2 | `f72d6e47978ec40d0b47c4fa27c6777e` | `8f5907f621569071726f9b1fbab5a7c2` | — (used) | `8db70812ec7b4ce05b1ff3f8424b4ab3` |
   | 3 | `001cb6bb71a54edaa53668cada1433c0` | `942c2af13ce5d54ec611b28e938891d2` | — | — |
   Reversal: none — the retries are what distinguishes "mangles twice" from a first-pass defect.
2. **The needle is always painted ONTO the dial face.** All three instrument renders return the
   same three objects: face (carrying a needle, against §11's own "no numbers, no needle"), rose,
   lubber triangle. No render ever yields a `ui_gauge_needle` object. Route taken: the face is
   cleaned by `staging/phase_g/gauge_clean.py` (the needle is found as the only long straight bar
   running out of the hub — a bearing search plus the face's own rotation median as detector and
   fill; first pass by rotation-median difference alone flagged 27 % of the canvas, measured) and
   `ui_gauge_needle` is **authored SVG**, rasterised by `ui_authored.py` — §11's own fallback route
   ("hand-authored … rasterised into the same file names"), the D2 route precedent.
   Wipe evidence: inside the mask the face's max luminance falls 236.4 → 66.4.
3. **The frame and the glass are always fused into one object.** All three frame renders return one
   bezel-and-screen (a landscape monitor, interior aspect ≈ 1.55) — no separate `ui_readout_glass`,
   and a landscape interior cannot fill a 272×380 portrait plate. Route: `ui_cockpit_frame` is the
   render's bezel rebuilt as a nine-slice by `ui_authored.py` (via `staging/phase_f/reband_frame.py`,
   the F.2 C1 recipe, 192 px at a 64 px band, centre filled flat panel black `#15181D` per §2);
   `ui_readout_glass` is **authored SVG** at 272×380.
4. **The two digit panels render in two different styles, so the family cannot mix them.** Measured
   on the same 48×88 box: `panel_sevenseg_a` (prompt "glowing bone-white segments with the unlit
   segments dark grey") draws the lit segments as **hollow bone outlines**, lit-ink share
   0.045–0.087; `panel_sevenseg_b` (prompt wording has no colour or weight clause) draws them as
   **solid filled bars**, 0.17–0.22, and its second attempt drew them **ember-lit** (a §1.3/§1.5
   palette violation) before settling on bone. Attempt 2's `%` cell is a diagonal slash with two
   dots, not seven-segment strokes, drawn large enough that 9.7 % of its lit ink sits outside
   `ui_seg_blank`'s ghost boxes.
5. **AC5's ink-share ordering is impossible as literally worded.** A seven-segment font's lit
   segment counts run 1→2, 2→5, 3→5, 4→4, 5→5, 6→6, 7→3, 8→7, so digit `4` (4 segments) sits
   between `3` and `5`: a strict `1 < 2 < … < 8` monotone sequence can never hold. `qc_seg_digits.py`
   enforces the reading the intent requires — `blank` smallest of all, `1` smallest of the digits,
   `8` largest, and no case of fewer lit segments carrying more ink — and prints the literal
   monotone result (`does not hold`) beside it. **This is the one item that may want a §11 wording
   amendment**; it is reported, not rewritten.
6. **The cells ship as the authored SVG route, all twelve of them.** Given 4 and 5, the family
   cannot be reconciled from two independently rendered panels, and §11 gates the ship step on AC5.
   `staging/phase_g/seg_svg_digits.py` authors the segment layer once (one lattice for all twelve,
   lit segments Bone `#C9CDD2`, unlit Panel Steel `#2A2E35`, plate faces flattened from the render's
   own plate so the family keeps one painted plate). Reversal: regenerate the two panels if §11's
   prompt #4 gains prompt #3's colour/weight clause.
7. **§11's seg master box is not 2× the logical box.** The table pins 20×36 logical and 48×88
   master; 2× of 20×36 is 40×72. The table won (it is the more specific number): the cells ship
   48×88, and `ui_seg_*` are plain `fill` fits to that box.
8. **§11 says the digit panels are 3×2; both renders came back one row of six (6×1).** Read off the
   render by `panels.py --detect` (6 objects on a single horizontal band), per `AGENTS.md` Phase G
   lane ("the arrangement is read from the render … the cell count and the names come from the
   spec"). `cells` in `wave_g.py` is 6×1 for both.
9. **Provenance names for the two unnamed panels.** §11 names only `panel_sevenseg_a/b`. The other
   two renders ship as `panel_instruments` and `panel_frame_glass`, derived from §11's own panel
   wording (`one 2×2 instrument panel`, `one 2-cell panel`) under `ASSET_NAMING_SPEC` §1's grammar
   and §2's `panel_` family. Reversal: drop or rename on the owner's word.
10. **The bezel's painted band is uneven** (measured 262.2 px, 20.2 % of the span; edges top 351,
    bottom 229, left 237, right 232 — spread 46.5 %). The §2 recipe requires one uniform band, so
   the rebuild uses the mean: the drawn band lands **64 px vertical / 57 px horizontal against the
    64 px margin**. Same class of defect F.2 recorded and cured locally; reported so D6-R1 can
    re-measure it.
11. **Ship timing vs the brief's run-order line.** The brief says `M0a (generate → stage → digit QC
    → review sheet) → STOP → M0b (ship → editor reimport)`; this dispatch says "pass AC5 … before
    shipping anything" and M0b's own prompt says it "reconcile[s] the shipped masters". The files
    are shipped (AC5 gated them); M0b is reimport + reconcile only.
12. **Shipped but not yet imported.** No `.import` sidecars exist for the 18 new PNGs; the reimport
    is M0b's step per the brief. **Closed by M0b** — the 22 sidecars landed and the editor
    reimported them; see §M0b.

## Evidence

Renders (2K, `--aspect 1:1`, opaque on white, style-block preamble verbatim + §11 framing + §11
per-run prompt + §8 negative list), task ids in Deviation 1.

Cut/key order is the Phase G lane law, per panel: `panels.py --detect` → `refit_panels.py` (cut each
object's own box, key it on its own, verify ink box vs alpha box, trim and centre). Never keyed a
panel whole. Ink→alpha verification passed on every cut, e.g.
`ui_gauge_face: ink 974x972 -> alpha 976x974 PASS`, `ui_cockpit_frame: ink 1851x1292 -> alpha
1857x1297 PASS`, all 12 seg cells `PASS`. 16 billed recraft calls, 16 keyed, 0 failures.

Per-file numbers (`staging/phase_g/ui/ship_report.json`):

| File | Box | Ink | Transparent | Bytes | md5 | Route |
|---|---|---|---|---|---|---|
| `ui_cockpit_frame` | 192×192 | 95.94 % | 3.56 % | 69716 | cfc4e234 | nine-slice rebuild (`ui_authored.py`) |
| `ui_gauge_face` | 240×240 | 79.03 % | 20.96 % | 96023 | b4645a61 | needle wiped (`gauge_clean.py`) |
| `ui_gauge_needle` | 16×192 | 49.58 % | 37.70 % | 3060 | 87e66a2c | authored SVG (`ui_authored.py`) |
| `ui_compass_rose` | 192×192 | 67.64 % | 32.35 % | 60749 | 56f2f9ff | render cut, contain fit |
| `ui_compass_lubber` | 32×24 | 36.59 % | 63.41 % | 1290 | 84a0babc | render cut, contain fit |
| `ui_readout_glass` | 272×380 | 99.87 % | 0.10 % | 2403 | 17f25834 | authored SVG (`ui_authored.py`) |
| `ui_seg_0`…`ui_seg_9`, `_pct`, `_blank` | 48×88 | 89.77 % | 6.34 % | 6666–6979 | per file | authored SVG segments (`seg_svg_digits.py`) |

Frame rebuild (`staging/phase_g/ui/authored_report.json`): measured band 262.25 px (20.22 % of the
span), edges `{top 351, bottom 229, left 237, right 232}`, rebuilt band 64 px, drawn band vertical
64 / horizontal 57 against the 64 px margin, centre flat `#15181D`.

AC5 digit QC (`staging/phase_g/qc_seg_digits.json`, run on the shipped 48×88 masters). Reference:
`ui_seg_blank`'s ghost ink gives **7 segment boxes** `[[13,4,34,19],[30,19,46,44],[30,43,46,69],
[13,68,34,84],[2,43,14,69],[2,19,14,44],[13,36,34,52]]` (face 25.1, unlit 45.6, threshold 35.35;
ghost pixels are counted on the cell face only, so a rivet catch cannot read as a lit segment).

| Cell | Lit segments | Plate px | Lit px | Ink share | Containment | Verdict |
|---|---|---|---|---|---|---|
| `ui_seg_0` | 6 | 3792 | 1200 | 0.3165 | 100.00 % | PASS |
| `ui_seg_1` | 2 | 3792 | 504 | 0.1329 | 100.00 % | PASS |
| `ui_seg_2` | 5 | 3792 | 972 | 0.2563 | 100.00 % | PASS |
| `ui_seg_3` | 5 | 3792 | 1056 | 0.2785 | 100.00 % | PASS |
| `ui_seg_4` | 4 | 3792 | 864 | 0.2278 | 100.00 % | PASS |
| `ui_seg_5` | 5 | 3792 | 972 | 0.2563 | 100.00 % | PASS |
| `ui_seg_6` | 6 | 3792 | 1140 | 0.3006 | 100.00 % | PASS |
| `ui_seg_7` | 3 | 3792 | 688 | 0.1814 | 100.00 % | PASS |
| `ui_seg_8` | 7 | 3792 | 1392 | 0.3671 | 100.00 % | PASS |
| `ui_seg_9` | 6 | 3792 | 1224 | 0.3228 | 100.00 % | PASS |
| `ui_seg_pct` | 5 | 3792 | 612 | 0.1614 | 100.00 % | PASS |
| `ui_seg_blank` | — | 3792 | 0 | 0.0000 | 100.00 % | PASS |

Ordering: `blank` smallest (0.0000 < 0.1329) ✔, `1` smallest of the digits ✔, `8` largest
(0.3671 = max) ✔, no by-segment inversion ✔. Literal `1 ≤ 2 ≤ … ≤ 8` — **does not hold**
(Deviation 5). **AC5 verdict: PASS.**

Commands (host-neutral, run from `$VAJB_WORKSPACE`):

```
uv run --with numpy --with pillow --with scipy python3 staging/phase_g/wave_g.py <run-id> [...]
uv run --with numpy --with pillow --with scipy python3 staging/phase_g/panels.py --detect <render> --grid CxR
uv run --with numpy --with pillow --with scipy python3 staging/phase_g/refit_panels.py <run-id> [...]
uv run --with pillow --with numpy --with scipy --with cairosvg python3 staging/phase_g/seg_svg_digits.py
uv run --with pillow --with numpy --with scipy python3 staging/phase_g/gauge_clean.py
uv run --with pillow --with numpy --with scipy --with cairosvg python3 staging/phase_g/ui_authored.py
uv run --with numpy --with pillow --with scipy python3 staging/phase_g/qc_seg_digits.py --json staging/phase_g/ui/qc_seg_digits.json
uv run --with numpy --with pillow --with scipy python3 staging/phase_g/ship_d6.py
uv run --with numpy --with pillow --with scipy python3 staging/phase_g/build_review_d6.py
```

No gate run: this deliverable touches no `.gd`, no `tres`, no `project.godot`. The wave's gate
figure moves only with D6-M1/M2.

## Files touched

- `vajb-orbit/assets/ui/` — **18 new masters** (`ui_cockpit_frame`, `ui_gauge_face`,
  `ui_gauge_needle`, `ui_compass_rose`, `ui_compass_lubber`, `ui_readout_glass`, `ui_seg_0…9`,
  `ui_seg_pct`, `ui_seg_blank`) + `generation_log_d6.md`
- `vajb-orbit/assets/icons/` — **4 provenance panels** (`panel_instruments`, `panel_frame_glass`,
  `panel_sevenseg_a`, `panel_sevenseg_b`)
- `staging/phase_g/wave_g.py` — a `panel` mode + the four D6 run specs (grids, cells, boxes)
- `staging/phase_g/panels.py` — grid-generic grouping (`cols`×`rows` instead of the hardcoded 2×2),
  alpha-aware `cut_object`, `--grid`
- `staging/phase_g/refit_panels.py` — grid-generic cell mapping, opt-in duplicate check
- `staging/phase_g/seg_geometry.py` — new: the one segment lattice both authoring and QC use
- `staging/phase_g/seg_svg_digits.py` — new: the AC5 SVG fallback route for the twelve cells
- `staging/phase_g/qc_seg_digits.py` — new: AC5 (ghost-box containment + ink-share ordering)
- `staging/phase_g/gauge_clean.py` — new: needle measurement and wipe on the dial face
- `staging/phase_g/ui_authored.py` — new: authored needle + glass, nine-slice frame rebuild
- `staging/phase_g/ship_d6.py` — new: box fitting, project copy, panel provenance, generation log
- `staging/phase_g/build_review_d6.py` — new: the 18-master review sheet (logical + 2×)
- `staging/phase_g/ui/**` — renders, `_cells/`, `_masters/`, `_svg/`, QC/ship/authored JSON, previews

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| §11 prompt #4 has no colour/weight clause (the cause of the split family); §11's master box for the seg cells is 48×88 against 40×72 at 2×; §11's "3×2" wording vs the render's 6×1; AC5's literal ink-share monotone is geometrically impossible | docs finding (bucket 2 — pinned numbers/wording) | `docs/design/UI_CHROME_ASSETS_SPEC.md` §11 |
| `panel_instruments` / `panel_frame_glass` provenance names are derived, not spec-named | naming ruling | `docs/design/ASSET_NAMING_SPEC.md` §11 |
| Bezel drawn band 57 px horizontal against the 64 px margin (render's band uneven, spread 46.5 %) | art (MED if the owner sees a seam at 720 px) | `vajb-orbit/assets/ui/ui_cockpit_frame.png` |
| Dial face carries a faint diagonal texture trace from the needle wipe | art (LOW) | `vajb-orbit/assets/ui/ui_gauge_face.png` |

## M0b — reconciliation + import (phase b, 2026-09-24)

The owner approved the review sheet. Phase b is reconcile + import only: **no master was
regenerated, resampled, re-keyed or otherwise touched, and no code was written.** The only files
this phase creates are the 22 `.import` sidecars; `.godot/imported/**` (gitignored build artifacts)
is all that changed beneath them.

### 1. Reconcile — all 18 masters vs UI_CHROME_ASSETS_SPEC §11's table

Measured with Pillow on the shipped bytes; names compared to §11's table verbatim:

| File | §11 logical box | §11 master | shipped | match | PNG md5 (8) |
|---|---|---|---|---|---|
| `ui_cockpit_frame` | nine-slice | 192×192, 64 px band | 192×192 | YES | `cfc4e234` |
| `ui_gauge_face` | 120×120 | 240×240 | 240×240 | YES | `b4645a61` |
| `ui_gauge_needle` | 8×96 | 16×192 | 16×192 | YES | `87e66a2c` |
| `ui_compass_rose` | 96×96 | 192×192 | 192×192 | YES | `56f2f9ff` |
| `ui_compass_lubber` | 16×12 | 32×24 | 32×24 | YES | `84a0babc` |
| `ui_readout_glass` | 136×190 | 272×380 | 272×380 | YES | `17f25834` |
| `ui_seg_0` … `ui_seg_9`, `ui_seg_pct`, `ui_seg_blank` (12 files) | 20×36 each | 48×88 each | 48×88 each | YES (12/12) | `7a884ea0` … `f9c2f26f` |

**18/18 present, named byte-exact, boxed exactly as §11's Master column.** No drift was found
between the shipped tree and the table.

One open doc conflict, unchanged and still bucket 2 (phase-a Deviation 7): §11's prose pins "one
master per sprite at **2× its logical box**", which for the table's own logical 20×36 is 40×72,
while the table's Master column says 48×88. The shipped 12 cells follow the table, and
`staging/phase_g/seg_geometry.py:13` (`BOX = (48, 88)`) is the one authored lattice both the cells
and AC5 are built on. Phase b did **not** resample them — choosing the prose over the table is a
pinned-number decision (bucket 2), not a worker's. Reversal for the designer/owner: set
`BOX = (40, 72)`, re-run `seg_svg_digits.py` then `qc_seg_digits.py`, and reimport.

### 2. Import settings — unified on all 22 new files

Sidecars did not exist (phase-a Deviation 12), so the editor first imported the files with its own
defaults (`mipmaps/generate=false`, `detect_3d/compress_to=1`, `compress/mode=0`, i.e. no mip
chain and 3D detection live). They were then brought onto the family quartet with the standing D2
master-unification tool — no new tooling was written:

```
python3 staging/d2/apply_master_import_settings.py            # dry run
→ 22 .import files want patching of 321 targets
python3 staging/d2/apply_master_import_settings.py --apply
→ 22 .import files patched of 321 targets
```

The 22 are exactly this wave's files (18 `assets/ui/` masters + the 4 `assets/icons/` provenance
panels); the dry run is the proof that no other family member was rewritten. After the pass
**321/321 `.import` files under `assets/icons` + `assets/ui` carry the quartet — 0 off-spec**:

```
mipmaps/generate=true     # scaled icons get a mip chain, no aliasing
compress/mode=0           # lossless
detect_3d/compress_to=0   # 3D auto-detection off
```

The 4 provenance panels are 2048×2048 RGB sheets no runtime code loads; they are imported like the
rest of `assets/icons/` rather than held as an exception (cost: their `.ctex` files are ~3.5–3.7 MB
each, gitignored build artifacts).

### 3. Reimport — quiet window, one editor session

Editor `vajb-orbit@86fd6072c72f957c` (Godot 4.7.2-stable, `readiness: ready`,
`play_state: stopped`, pid 12670) with no headless gate process running → quiet window. Route per
the task (editor open ⇒ `filesystem_manage`, not `--headless --import`, so a single writer holds
the import cache):

1. `filesystem_manage(op="scan")` → `scan_completed: true`; the 22 new PNGs discovered and
   first-imported with defaults.
2. the settings unification above.
3. `filesystem_manage(op="reimport")` over the 22 `res://` paths →
   `reimported_count: 22, skipped_non_imported: 0, not_found: 0`.

**The reimport is asynchronous.** Immediately after the call every `.ctex` still carried the
scan's 07:48:59 mtime and it read as a no-op; re-measuring ~5 s later showed all 22 rewritten at
07:49:41–42. The first reading was a false negative, not a failed import — a reviewer must not
judge this step from an immediate `ls`.

Audit (`.godot/imported/*.md5`, rewritten with each `.ctex`):

| Check | Result |
|---|---|
| `source_md5` before vs after the reimport | identical for 22/22 |
| `source_md5` vs the md5 of the shipped PNG on disk | matches for 22/22 → the editor imported exactly the approved art |
| `dest_md5` before vs after | changed 22/22 → the new params produced new payloads |
| `.ctex` size vs the default-settings import | grew with the mip chain: `ui_gauge_face` 64698 → 91042 B, `ui_seg_blank` 4960 → 7830 B |
| header parity with shipped chrome | all 22 carry the same `GST2` format/flags word as `ui_panel_frame`, `ui_slot_weapon_normal`, `ui_minimap_bezel` (all mipmapped) |
| editor load | `resource_manage(op="load", res://assets/ui/ui_gauge_face.png)` → `CompressedTexture2D`, `load_path` = the regenerated `.ctex` |

### 4. Final state — box + import, all 22 new files

The three import columns are uniform (`mipmaps` on, `compress/mode=0` lossless,
`detect_3d/compress_to=0`) on every row; `§11` = the shipped box matches §11's Master column.
`.ctex` bytes are the post-reimport sizes.

| File | Box | §11 | PNG md5 (8) | `.ctex` B |
|---|---|---|---|---|
| `assets/ui/ui_cockpit_frame` | 192×192 | YES | `cfc4e234` | 66698 |
| `assets/ui/ui_gauge_face` | 240×240 | YES | `b4645a61` | 91042 |
| `assets/ui/ui_gauge_needle` | 16×192 | YES | `87e66a2c` | 5798 |
| `assets/ui/ui_compass_rose` | 192×192 | YES | `56f2f9ff` | 58592 |
| `assets/ui/ui_compass_lubber` | 32×24 | YES | `84a0babc` | 2138 |
| `assets/ui/ui_readout_glass` | 272×380 | YES | `17f25834` | 2640 |
| `assets/ui/ui_seg_0` | 48×88 | YES | `7a884ea0` | 7866 |
| `assets/ui/ui_seg_1` | 48×88 | YES | `357ef3fa` | 7810 |
| `assets/ui/ui_seg_2` | 48×88 | YES | `be0ef507` | 7906 |
| `assets/ui/ui_seg_3` | 48×88 | YES | `f570fd9b` | 7902 |
| `assets/ui/ui_seg_4` | 48×88 | YES | `2956fba0` | 7902 |
| `assets/ui/ui_seg_5` | 48×88 | YES | `ea95b9f6` | 7922 |
| `assets/ui/ui_seg_6` | 48×88 | YES | `381d4785` | 7918 |
| `assets/ui/ui_seg_7` | 48×88 | YES | `bb6f91ba` | 7884 |
| `assets/ui/ui_seg_8` | 48×88 | YES | `60ea0ba5` | 7890 |
| `assets/ui/ui_seg_9` | 48×88 | YES | `3a200a94` | 7898 |
| `assets/ui/ui_seg_pct` | 48×88 | YES | `b0e17a4f` | 7900 |
| `assets/ui/ui_seg_blank` | 48×88 | YES | `f9c2f26f` | 7830 |
| `assets/icons/panel_instruments` | 2048×2048 | n/a (provenance) | `e03436c1` | 3727792 |
| `assets/icons/panel_frame_glass` | 2048×2048 | n/a (provenance) | `cd052abb` | 3709090 |
| `assets/icons/panel_sevenseg_a` | 2048×2048 | n/a (provenance) | `ac855197` | 2523364 |
| `assets/icons/panel_sevenseg_b` | 2048×2048 | n/a (provenance) | `0c1f2b0b` | 2852248 |

### 5. Files touched (phase b)

- `vajb-orbit/assets/ui/*.png.import` — **18 new** sidecars, one per master
- `vajb-orbit/assets/icons/panel_*.png.import` — **4 new** sidecars (provenance panels)
- `vajb-orbit/.godot/imported/**` — regenerated `.ctex`/`.md5` (gitignored, never committed)
- `staging/` — untouched in phase b: the D2 unification tool already existed
- no `.gd`, `.tres`, `.tscn`, `project.godot`, `docs/` file and **no art byte** changed

### 6. Not done here

- **No gate run.** Art-only phase; the wave's gate figure moves with D6-M1/M2 (front matter).
- No art regenerated, resampled or re-keyed — the owner-approved bytes are the shipped bytes
  (`source_md5` above proves it).
- The §11 prose-vs-table seg box conflict stays open (bucket 2, §1 above).
- Unrelated, not touched: the editor's error buffer carries GDScript parse errors from the
  parallel coder lane (`game/player_ship.gd:1378`, `sync_thruster_trails()` arity), outside this
  wave's file set.
