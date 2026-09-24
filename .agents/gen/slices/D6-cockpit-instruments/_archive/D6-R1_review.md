---
slice: D6
worker: D6-R1
model: "deepseek/deepseek-v4-flash (crush session, orchestrator-dispatched review)"
status: med            # 1 MED code finding (R1-MED-1) + 1 MED docs/pin finding (R1-MED-2); no HIGH
gate: "607/0 (three runs: two scratch stores + the verify_wave --tests run) — of which 14 are test_d6_cluster.gd's and 15 test_d6_status.gd's own methods"
---

# D6-R1 review — cockpit instruments (cluster + ship status screen)

Diffed against **`docs/design/UI_SPEC.md` §3.7/§3.8 as amended 2026-09-24** and
`docs/CONTRACTS.md` §18 (never against the brief), with the owner's mid-wave SPD
amendment applied by D6-M1b. Every number below was re-measured by this reviewer on
the shipped tree; the builder reports were read for claims, not for evidence.

## Verdict

**No HIGH. Two MED** (`R1-MED-1` a wrong drawing on the shipped screen; `R1-MED-2` a
docs pin pair whose two numbers cannot both hold) **and nine LOW** (backlog rows
`L141`–`L149`). Every pinned acceptance reads as the docs state it: the cluster box,
the byte-identical §3.6 dial contract, the digit semantics incl. the 4-cell SPD
amendment, every danger-row rule, the overdrive strict boundary, the compass, the
modal's box/chrome/guards, the grid refs and module names, the power reuse, the
damaged-side both branches and the no-write proof all measure green. The wave is fit
to close once `R1-MED-1` is fixed (bucket 1 — no pin moves) and `R1-MED-2` is
dispositioned by the developer/owner (bucket 2 — fixing it *is* moving a pin, so no
fixer action is legitimate).

| Tier | Count | IDs |
|---|---|---|
| HIGH | 0 | — |
| MED | 2 | `R1-MED-1` the status screen's hardpoint markers are drawn in a space the render box is not; `R1-MED-2` the cluster's pinned content is wider and taller than the frame's pinned interior |
| LOW | 9 | `L141`–`L149` in `.agents/gen/_state/LOW_BACKLOG.md` |

## Method (what the reviewer ran itself)

```
# the gate, twice on scratch stores (identical), plus the debug ledger run
XDG_DATA_HOME=/tmp/d6r1_g1 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
XDG_DATA_HOME=/tmp/d6r1_g2 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
XDG_DATA_HOME=/tmp/d6r1_g3 $GODOT_CONSOLE --headless --debug --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
# the frozen gauge suite's own file, byte-diffed against the pre-wave commit
git diff 49df633 HEAD -- vajb-orbit/tests/test_engine2_hud.gd          # (empty)
# the wave-state baseline + the forbidden list (run again with --tests at the end)
python3 staging/verify_wave.py verify --baseline d6_start \
  --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md \
             docs/gameplay/08_ship_slots_modules.md docs/CONTRACTS.md
# AC5 re-run on the SHIPPED masters (the exact tool, uv supplies numpy/scipy)
uv run --quiet --with numpy --with pillow --with scipy python3 staging/phase_g/qc_seg_digits.py \
  --dir vajb-orbit/assets/ui --json /tmp/d6r1_qc.json
# the reviewer's own 36-check probe (35 PASS / 1 FAIL — the FAIL is R1-MED-1), deleted after the run
XDG_DATA_HOME=/tmp/d6r1_probe_store $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/probe_d6_r1.tscn
# an offline composite of the two chrome surfaces at the measured rects (no editor, no renderer)
python3 <PIL nine-slice + aspect-fit composite>            # 2 images
```

Evidence kept in `.agents/gen/slices/D6-cockpit-instruments/_review_probes/`:
`probe_d6_r1.gd.txt` + `probe_d6_r1.log`, `gate_scratch1.log`, `gate_scratch2.log`,
`gate_debug_ledger.log`, `verify_wave_tests.log` (the baseline verify **with** `--tests`:
the same `passed=607 failed=0`, and the one `problems` entry the S6 lane's
`docs/CONTRACTS.md` touch), `qc_seg_digits_rerun.json`, `cluster_composite.png`,
`status_markers_composite.png`.

## MED findings

### R1-MED-1 — the status screen's hardpoint markers are drawn in a space the render box is not

`ShipFit.HARDPOINTS`' anchors are mapped into `_render_size * 0.5 + anchor * scale`
(`ui/hud/ship_status_screen.gd:433`) and the markers node is stretched over the whole
render box, but the render box is **taller** than `_render_size` and the sprite inside
it is aspect-fit and centred:

- `ui/hud/ship_status_screen.gd:230` — `_render_box.size_flags_vertical =
  SIZE_EXPAND_FILL`, so the box takes the row's full height (441 px measured) while
  `custom_minimum_size` only carries the aspect (`:406-408`).
- `ui/hud/ship_status_screen.gd:236` — the `TextureRect` is
  `STRETCH_KEEP_ASPECT_CENTERED`, so the drawn sprite is centred inside that taller box.
- `ui/hud/ship_status_screen.gd:797-800` — the markers node is a FULL_RECT child of the
  box, and `:816` draws each anchor at the raw `pos`, i.e. in box-local coordinates.

Measured (probe, modal open and laid out; body 720×520 at `(600,280)`):

| State | render box | marker space (`_render_size`) | sprite drawn | sprite centre | marker-space centre | offset |
|---|---|---|---|---|---|---|
| intact vanguard | 320×441 | 320×173.667 | 320×173.667 | box-local (160, **220.5**) | box-local (160, **86.83**) | **133.67 px up** |
| damaged vanguard | 320×441 | 320×311.867 | 320×311.867 | box-local (160, **220.5**) | box-local (160, **155.93**) | **64.57 px up** |

Every one of the 11 markers is displaced by that constant vertical offset — 77 % of the
intact sprite's height. On the intact state most anchors do not even land on the sprite:
the first rear thruster draws at box-local `(36.33, 49.7)` while the sprite occupies
box-local y `133.66 … 307.33`, i.e. the marker floats 84 px above the hull's top edge
(the measurements are in `probe_d6_r1.log`; the visual is
`status_markers_composite.png`, markers drawn at the reported positions over the sprite
as `KEEP_ASPECT_CENTERED` draws it). The offset is uniform and state-dependent, so it
also *moves* when hull damage swaps the cut (`R1-MED-2`'s aspect difference is what
makes the two offsets differ).

**The shipped suite cannot see this**: `test_d6_status.gd:533-552` recomputes the
expected position from the same `_render_size` the screen uses, so it is a
self-consistency check (`markers[0].pos == centre + anchor*scale`), not a
"markers sit on the sprite" check — the same shape of gap S5-R1's `R1-MED-2` recorded.

**Tier MED** because it is the wrong drawing of a pinned §3.8 element ("**Overlaid**
hardpoint markers … when `ShipFit.HARDPOINTS` carries the hull") on the shipped screen,
and it is fixable inside the pinned acceptance: the box's vertical expansion, the
sprite's fit and the marker space are all bucket 1 (no doc number pins any of them).
Route options for the fixer: give the render box the sprite's own aspect
(`size_flags_vertical = SIZE_SHRINK_CENTER`/`SIZE_FILL` with
`custom_minimum_size = _render_size` and no growth), or keep the box expanding and
derive the drawn rect explicitly (`fit_scale = min(box.x/native.x, box.y/native.y)`,
`drawn_centre = (box - native*fit_scale)*0.5 + native*fit_scale*0.5`) and hand the
markers *that* space. Whichever route, the new assertion must compare a marker against
the sprite's drawn rect, not against `_render_size` (see `L142`).

### R1-MED-2 — the cluster's pinned content is wider and taller than the frame's pinned interior

UI_SPEC §3.7 pins the cluster box at **404×216** and the frame at "one master,
nine-slice, **64 px band on a 192×192 master**" (drawn at half scale per §10/§11, i.e.
a **32 px logical band**, 28.5 px of it painted ink measured by M0). §11 pins the bays:
gauge 120, compass 96, glass 136. At a 32 px band the interior is **340×152**, and the
pinned content is **396 wide** (120 + 20 + 100 + 20 + 136) and **190 tall** — the two
pinned numbers cannot both hold.

Measured (probe, global rects on the mounted HUD; `cluster=[12,852] 404×216`,
`frame_global=[12,852] 404×216`, `band=32.0`, `interior=[44,884] 340×152`):

| Bay | rect | overhang past the interior |
|---|---|---|
| gauge (left) | 120×120 at `(16,900)` | **28 px** past the left band |
| middle (compass + HDG) | 100×134 at `(156,893)` | none (clears the top/bottom bands) |
| readout bay (glass) | 136×190 at `(276,865)` | **28 px** past the right band, **19 px** past the top and bottom bands |

The frame is added first, so the bays draw over the painted bezel: the readout glass
(an essentially opaque 272×380 plate, 99.87 % ink) runs to **4 px from the frame's
right edge** and eats the top/bottom bezel down to a 13 px strip.
`cluster_composite.png` is that overlay rendered offline from the shipped textures at
these exact rects.

**Tier MED, disposition bucket 2 — no fixer action.** Every number involved is a pin
(the box, the band, the bay boxes), so choosing between them is the developer/owner's:
(a) grow the box to **≥ 460×254** (content 396×190 + 2×32; **≥ 453 wide** if measured
against the *painted* 28.5 px horizontal band), (b) thin the band (a §11 amendment), or
(c) sanction the overlap in §3.7. The brief's own reversal **340×184 cannot hold the
pinned bays at all** (396×190 of content), which is material to the owner's tick 2 —
see "Owner ticks" below. The same pin pair repeats in the modal at a milder scale: the
content column starts **24 px** in (§3.8's `MODAL_MARGIN`) against the same 32 px band,
so every side of the status modal overlaps the bezel by **8 px** (measured
`column=[624,304] 672×472` vs `interior=[632,312] 656×456`). Fixing that one is a
one-line margin change, but it is the same pinned pair, so it travels with this finding
rather than as a separate row.

## Findings adjudicated (the builder-reported items this review was asked to settle)

1. **D6-M1's bucket-2 frame-interior overflow note — upheld, tiered MED as `R1-MED-2`.**
   Its numbers reproduce exactly (28 px gauge/left, 28 px readout/right, 19 px
   top/bottom; content 396×190 vs interior 340×152), including the frame's corner
   geometry (the nine-slice's 64 px patch margins at scale 0.5 are correct — the
   texture's flat centre is exactly the 64…128 patch, measured on the shipped PNG).
   Its "reversal if the owner wants a fully visible bezel" pair is right in spirit and
   its 468×280 suggestion is ~8 px too small: the painted bezel needs 460×254 (patch
   margins) or 453×254 (painted ink). M1's route choices (own file, `_draw` compass,
   read-backs on both HUD and cluster) are bucket 1 and all measure as described.
2. **D6-M2's damaged-cut aspect note — upheld and promoted into `R1-MED-1`'s root
   cause.** Re-measured: `ship_vanguard_side.png` 960×521 (h/w 0.543) vs
   `ship_vanguard_damaged_side.png` 1023×997 (h/w **0.975**). M2's "every intact side
   render is ~2:1" is loose: the nine player hulls' intact sides run h/w 0.24 (corvette)
   to 0.66 (gunship) — vanguard 0.543, fighter 0.463 — while the `*_mmo_*` and faction
   livery variants are ~1.0, so the *Vanguard's* own damaged cut is the outlier that
   matters for the hull the fixture seeds (a 1.8× height change across its two states).
   The screen's "320 px wide, height = aspect" rule is literal to §3.8 and is not itself
   the defect; what it breaks is the marker space, because the box's height comes from
   `EXPAND_FILL`, not from the aspect. The docs/asset half (two left-column heights
   across damage states) remains a bucket-2 note; no doc pins the render's height.
3. **D6-M2's report of 6 `--debug` ledger rows in `ui/hud/cockpit_cluster.gd` — upheld,
   LOW (`L141`).** Re-measured on the `--debug` gate: 86 `GDScript::reload` rows in the
   tree, **6 from `cockpit_cluster.gd`** (`:196`, `:326`, `:333`×2, `:346`, `:426` after
   M1b's one-line shift; M2's numbers are the pre-M1b lines), **0 from
   `ship_status_screen.gd`, `hud.gd` and both `test_d6_*.gd`** — exactly as reported.
   The texts: `row`/`cells` shadowing the `row()`/`cells()` methods (4 rows, the
   codebase's endemic pattern — `target_reticle.gd:86` carries the same) and 2
   `Narrowing conversion` rows in `_map_heading`. Not a functional defect; hygiene. The
   probe's own 36 checks and both suites run clean on those same files.
4. **D6-M2's bucket-1 notes, adjudicated:** the full-rect screen with a STOP-only body
   (a hidden modal cannot eat a HUD click) is correct; `_unhandled_input` on the HUD
   behind `InputMap.has_action` reads as §3.8 pins it; the `set_docked`/`docked` seam is
   never called in production because the dock route replaces the scene, so §3.8's
   "hidden while docked" holds structurally and the seam only makes it testable — no
   finding; the `preload` route for the screen class is the headless-parse-safe choice;
   the `SELECTION_FORMAT` prefix + rack grammar is the fitting pane's own; the marker
   tokens (`text_dim`/`metal_light`) are within §3.8's "names both tokens without
   splitting them"; the render-box-follows-aspect route is where `R1-MED-1` lives.
5. **D6-M0's deviations, adjudicated:** the twelve seg cells, the needle, the glass and
   the frame are authored/rebuild routes. §11 sanctions only the **digits'** SVG fallback
   in so many words (`UI_CHROME_ASSETS_SPEC.md:259-261`), so M0's citation of "§11's own
   fallback route" for the needle/glass is a **mis-citation** (LOW, `L146`) — but the
   *scope* question is closed by the process: the 18 masters were put in front of the
   owner as a review sheet and explicitly approved (M0 §M0b), so the route is an
   owner-approved outcome, not a silent reinterpretation. The AC5-containment reading,
   the two 6×1 digit panels, the derived `panel_instruments`/`panel_frame_glass`
   provenance names and the 9-render spend are all disclosed with their reversals.

## AC-by-AC (against the pins)

| Pin (UI_SPEC §3.7/§3.8, UI_CHROME §11, CONTRACTS §18) | Measured | Verdict |
|---|---|---|
| Cluster 404×216, bottom-left, `ui_cockpit_frame` nine-slice | `custom_minimum_size=(404,216)`, global `[12,852] 404×216` in `CanvasLayer/BottomLeft/Blocks` (the probe's HUD), frame = the same rect at scale 0.5 | PASS |
| §3.6 dial byte-identical inside the left bay | `test_engine2_hud.gd` (`:188-237`) zero diff vs `49df633`; the only deletions in `hud.gd` are the moved `_build_speedometer` body + comments; SEGMENTS 10 / SWEEP 1.5π / OVERDRIVE 0.9 / 120×120 / `filled_segments` map / `overdrive_segment` −1 at exactly 0.9 / `needle_colour` all green in my probe | PASS |
| Middle bay 96×96 rose + 3-cell HDG | compass `custom_minimum_size=(96,96)`; HDG row 100×36, 3 cells | PASS |
| SPD 4 cells clamp 0..9999 (2026-09-24 amendment), blanks never zeros | 0→`[-,-,-,0]`, 5→`[-,-,-,5]`, 999→`[-,9,9,9]`, 1000→`[1,0,0,0]`, 5000→`[5,0,0,0]`, 9999→`[9,9,9,9]`, 12345/20000→`[9,9,9,9]` | PASS |
| HULL/SHLD = `int(round(current))` points, 4 cells, clamp 9999 | 812.6→813, 812.4→812; 20000→9999; 12345→9999 | PASS |
| FUEL/ENRG = `int(round(100·v/max))`, clamp 0..100, 3 cells + `%`, `maximum == 0` reads 0 | 12/200→6, 7/100→7, 1/200→1, 1/300→0, 250/100→100, 0/0→0, 50/0→0; `%` lit on FUEL/ENRG only, the `ui_seg_pct` cut | PASS |
| All five right-bay rows the same width after the amendment | SPD/HULL/SHLD/FUEL/ENRG all **122×36**; label column 34 px, font 12 px (SPD and HDG), cell 20×36, separation 2 px | PASS |
| hull < 25 % → `accent_danger_bright` label + `accent_danger` frame | 25 %: no frame, `text_dim`; 24.9 %: frame `accent_danger` + label `accent_danger_bright`; 0/0: no frame | PASS |
| fuel ≤ 15 % → `accent_danger` label + frame; fuel 0 → `accent_danger_bright` frame | 16 %: none; 15 %: both `accent_danger`; 0/100: bright frame + `accent_danger` label; 0/0: none | PASS |
| overdrive `ratio > 0.9` strict; needle `accent_danger_bright`; SPD label stays dim | 0.9: no frame; 0.90001: `accent_danger` frame, label `text_dim`; `_needle_overdrive` = theme `accent_danger_bright` (0.910,0.384,0.165) | PASS |
| digits never recolour | every SPD/HULL/FUEL cell `Color.WHITE` under all three danger reads | PASS |
| Compass rose rotates `-heading.angle()`, lubber fixed; HDG mapped 0..359 | +90°→rose −π/2, −90°→+π/2; HDG 0/45/90/180/270 → `[-,-,0]/[-,4,5]/[-,9,0]/[1,8,0]/[2,7,0]`; 359.6°→0 | PASS |
| Modal 720×520 centred, frame nine-slice, `icon_close`, hidden by default | `modal_size=(720,520)`, body min 720×520, patch 64 / scale 0.5, close = `icon_close.svg` 16×16 FOCUS_NONE, `visible=false` | PASS |
| Toggle behind `InputMap.has_action`; row absent ⇒ inert | row absent: press leaves it closed; seeded row: press opens, press closes; close button closes | PASS |
| Esc stays Pause-only; hidden while docked | nothing in the wave reads Esc; docked latch refuses `set_open(true)` and the action | PASS |
| Left = side render 320 px, damaged swap = the repairs pane's rule | vanguard 500/1000 → `ship_vanguard_damaged_side.png` (== `RepairsPanelScript.hull_render(vanguard,500)`, and the texture path matches); 1000/1000 → `ship_vanguard_side.png`; fighter 500/1000 → `ship_fighter_side.png` with no damaged cut on disk | PASS |
| Hardpoint markers overlaid when `HARDPOINTS` carries the hull | 11 markers (8 thrusters + 3 mounts), `ShipFit.is_mapped` guard, anchors == centre + table px × scale — **but the space is not the drawn sprite's** | **FAIL → R1-MED-1** |
| Right = the shipyard's slot grid cell for cell + module glyph + cell ref | columns 4 = matrix width, 16 children = 11 slots + 5 gaps, refs `W1,W2,H1,S1,W3,E1,P1` in the grid's row-major order, names off `ModuleCatalog`, plates `Slot<token><nn>` paired with rows `Row<token><nn>`, empty cells draw `icon_slot_*.svg` | PASS |
| Footer = HULL/SHLD `cur / max` (18 px) + POWER from the fitting panel's arithmetic | `HULL 1000 / 1000`, `SHLD 0 / 0`, `PWR 5 / 8`; the pane's own `_power_of(profile, vanguard, resolved_fit)` called directly returns draw 5 / out 8, and `ShipFit.fit_legal(vanguard, base_fit(fit))[power]` agrees cell for cell; the wording is `fitting_panel.gd:143`'s `METER_IDLE` verbatim | PASS |
| Writes nothing | scratch profile bytes identical (704 == 704) through the whole lifecycle, `_dirty` false, `fit_for`/`modules`/`credits` unchanged | PASS |
| No new feed; `hud.tscn` untouched; frozen files untouched | `hud.tscn`, `project.godot`, the theme, all of `game/`+`autoload/`, both frozen gameplay docs: zero diff; `hud.gd`'s additions are pushes from the existing §7 feeds | PASS |
| §11 asset boxes, names and import quartet | 18 masters + 4 panels measured at §11's Master column, md5s identical to M0's table; 22/22 `.import` carry mipmaps on / lossless / 3D-detect off; 45 files under `assets/` touched today, all D6 | PASS |
| AC5 digit QC (containment ≥ 95 %, ink-share ordering) | re-run on the **shipped** masters: containment **1.0000 on all 12 cells**; `blank` 0.0000 smallest; `1` 0.1329 smallest digit; `8` 0.3671 largest; no by-segment inversion; literal `1≤…≤8` does not hold (reported, not enforced) | PASS |
| §11 lit/unlit tones | lit ink averages `#C7CBD0` (spec Bone `#C9CDD2`), ghost/unlit `#30302F` (spec Panel Steel `#2A2E35`) | PASS |

Independent extra check: each of the ten digit cells was verified against its
seven-segment set by measuring per-ghost-box lit coverage — `0=abcdef`, `1=bc`,
`2=abdeg`, `3=abcdg`, `4=bcfg`, `5=acdfg`, `6=acdefg`, `7=abc`, `8=abcdefg`,
`9=abcdfg`, all matching `seg_geometry.DIGIT_SEGMENTS`, and `ui_seg_blank` is
fully unlit. `ui_seg_pct` measures **`c,f,g`** — which is `seg_geometry.PCT_SEGMENTS`
and contradicts the QC table's own `SEGMENTS["ui_seg_pct"] = 5` (LOW, `L143`).

## No frozen file, no balance number

`git diff 49df633 HEAD` over `vajb-orbit/` is `ui/hud/hud.gd` (modified) plus the new
files (`cockpit_cluster.gd`, `ship_status_screen.gd` and their `.uid` sidecars, the two
`test_d6_*.gd` and their sidecars). `project.godot`,
`ui/theme/vajb_theme.tres`, `ui/hud/hud.tscn`, every file under `game/` and
`autoload/`, `docs/gameplay/18_engine_spec.md` and `docs/gameplay/08_ship_slots_modules.md`
are byte-identical; `docs/CONTRACTS.md`'s only change since the baseline is the
parallel S6 lane's §19 (verify's one `problems` entry blames it — recorded here, not
D6's). No balance number moved: the new constants are UI boxes, insets, seams, clamp
maxima, the two danger fractions and the 0.9 overdrive line, all of them the docs' own
or a UI reading of them; no hex literal was added to code (the one
`Color("#6fb8c4")` is in `test_d6_cluster.gd`, mirroring `test_engine2_hud.gd`'s own
fallback). **The live account during this review:** `profile.cfg` md5
`95ea422a5c55dee5a28e1690cd4351cf` (mtime 08:12:35) before the first run and identical
after the two XDG-scratched gate runs, the `--debug` run and every probe run — each wrote
into its own `/tmp/d6r1_*` store, never `user://`. The final `verify_wave.py --tests`
command ran **without** an `XDG_DATA_HOME` (as the close-out spells it) and wrote only the
runner's own sandbox inside the real user dir (`_gate_scratch/profile.cfg` 08:36:46,
`_gate_scratch/economy_log.txt` 08:36:50 — the sandbox working as designed). The **live**
`profile.cfg` (08:36:53) and `economy_log.txt` (08:36:52) were rewritten by a concurrent
editor-attached **Vulkan game session** (`logs/godot.log` 08:36:51,
`debugger active=true`, MINE/AMMO economy lines) belonging to another lane, not by any
headless run of this review; its content is organic play state (credits 5125, three
hulls, minerals in the hold), not a test fixture. Recorded because the account is not
byte-stable while other lanes play, and because the close-out's own verify command
carries no scratch store (`L149`).

Two `verify_wave` deltas are **not** D6's and are recorded so a later close-out does
not read them as wave artifacts: `docs/CONTRACTS.md` (§19, S6) and the `deleted`
`PROMPTS.md` (renamed into `.agents/gen/slices/S5-playtest-fixes/_archive/` by the
orchestrator's own commit `0070215`).

## LOW rows written (next free ids)

`L141`–`L149` in `.agents/gen/_state/LOW_BACKLOG.md`:

| # | Item |
|---|---|
| L141 | the 6 `--debug` ledger rows in `cockpit_cluster.gd` (shadowing `row`/`cells`, 2 narrowing) |
| L142 | `test_d6_status.gd`'s marker assertions compare against `_render_size`, so they cannot catch `R1-MED-1`'s class of error |
| L143 | the QC table's `SEGMENTS["ui_seg_pct"] = 5` contradicts `PCT_SEGMENTS = "f,g,c"` (3 measured) |
| L144 | UI_CHROME §11's seg master box: prose "2× its logical box" (40×72) vs the table (48×88) |
| L145 | AC5's literal `1 ≤ 2 ≤ … ≤ 8` ink-share wording is impossible for a seven-segment font (M0's amendment candidate) |
| L146 | `generation_log_d6.md`'s "Six files are not a plain cut" vs its own table (15 of 18 authored/rebuilt) and M0's citation of §11's digit-only SVG fallback as a general route |
| L147 | the D6 family has no `asset-library/cut/ui/` copy and no `_library.json`/INDEX records, so `validate_names --library` cannot see it |
| L148 | `set_hull_slots` keys the pushed cells by layout index alone; the payload's `slot` field is ignored (a non-weapon push at the same index would read as a W cell) |
| L149 | the close-out's `verify_wave.py --tests` command carries no scratch store, so it writes the real `user://_gate_scratch/`; with a parallel lane playing, the live account cannot be shown byte-stable by that run alone |

## Owner ticks owed (unchanged from the brief, plus what this review measured)

1. **NMS palette reading** — unchanged: shipped on the STYLE_BIBLE palette, one ember
   accent, digits palette-neutral.
2. **Cluster placement + size** — `R1-MED-2` is now a measured constraint on this tick:
   with the pinned 32 px band the pinned bays need **≥ 460×254** (or **≥ 453 wide**
   against the painted 28.5 px band) for the bezel to stay fully visible; **404×216
   overlaps it by 28 px left/right and 19 px top/bottom**, and the brief's compact
   reversal **340×184 cannot hold 396×190 of pinned content at all**.
3. **HULL/SHLD as points** — shipped as points, as worded.
4. **`ship_status` key = U** — the row is orchestrator-applied; the guard's absent branch
   is the shipped state and the suite covers both.
5. **Per-module damage model** — still staged; the screen lists modules and their
   fitted/powered presence only, honest to the sim.
6. **New, from this review:** `R1-MED-2`'s pin pair needs a decision (grow the box, thin
   the band, or sanction the overlap) — and whether the modal's 24 px margin should
   become 32 px to clear the same band.

## Close-out (orchestrator)

1. Gate twice on scratch stores — **measured 607/0, identical** (evidence in
   `_review_probes/`); the third run is the `--tests` half of the baseline verify.
2. `python3 staging/verify_wave.py verify --baseline d6_start --forbidden
   vajb-orbit/project.godot docs/gameplay/18_engine_spec.md
   docs/gameplay/08_ship_slots_modules.md docs/CONTRACTS.md --tests --expect-reports …`
   — run for this review: gate `passed=607 failed=0`, the four expected reports present,
   the only `problems` entry the S6-lane `docs/CONTRACTS.md` touch recorded above. Add an
   `XDG_DATA_HOME` scratch store to the command (`L149`).
3. `R1-MED-1` → **D6-F1** (bucket 1: no pin moves). `R1-MED-2` → the developer/owner
   (bucket 2: fixing it means moving a pin), no fixer action.
4. `docs/CONTRACTS.md` §9/§10 measured notes + the `ship_status` row (after S5-R1's own
   §9/§10 pass), `_state/WAVEBOARD.md` closed, LOW rows `L141`–`L149` already written
   (next free ticket remains `T-94`), then the wave-boundary commit.
