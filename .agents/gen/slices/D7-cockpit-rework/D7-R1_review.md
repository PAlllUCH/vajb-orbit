---
slice: D7
worker: D7-R1
model: "claude-sonnet-4.5 (review session); Godot 4.7.2-stable headless; Python 3 + Pillow 12.1.1 (no numpy/scipy on this host)"
status: review complete
gate: "711/0 twice on fresh XDG scratch stores (identical); 711/0 again inside the wave verifier"
verdict: "HIGH 1, MED 1, LOW 5, plus 3 escalations/tick notes"
---

# D7-R1 review — cockpit rework + battery window (the analog instrument pass)

Reviewed the working tree against the law, not the brief's superseded pins:
`docs/design/UI_SPEC.md` §3.1/§3.1b/§3.6/§3.7 (incl. the Mockup v5 block and the
**Mockup v7** block)/§3.8 (the **Mockup C** block)/§3.9 (rule 5)/§3.10, and
`docs/design/UI_CHROME_ASSETS_SPEC.md` §11/§12 (incl. **Amendment 2** and the
post-mockup glyph-only amendment). Every number below was re-measured by this pass.

**Verdict: the wave is not clean.** Everything the owner asked for is present and the
retirements/feeds/geometry check out, but the §3.8 status modal's hull render box never
takes the aspect-fit size its code computes — the render and its hardpoint markers are
mis-sized and mis-placed on every hull (HIGH-1), and the armory console's rect is not the
`2×` content rect §3.10 pins, with the plate fill-stretched 5.3 % vertically as a
consequence (MED-1). C3's report measured the *intended* render geometry
(`custom_minimum_size`), which is why the defect shipped green; `test_d6_status.gd`'s guard
reads the same property, so the yardstick cannot see it either.

## What I ran (bounded, no fixes)

```
XDG_DATA_HOME=/tmp/d7r1_g1|g2 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
        res://tests/headless_runner.tscn --quit-after 1200        # 711/0, 711/0
XDG_DATA_HOME=/tmp/d7r1_verify python3 staging/verify_wave.py verify \
        --baseline d7_start --forbidden vajb-orbit/project.godot \
        docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md \
        docs/CONTRACTS.md --tests --expect-reports <D7-A0/C1/C2/C3 reports>
python3 vajb-orbit/tools/d7r1_ac5_seg.py            # independent AC5 (Pillow, reimplemented)
XDG_DATA_HOME=/tmp/d7r1_probe_home $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
        res://tools/d7r1_probe.tscn                 # independent geometry/behaviour probe
```

Evidence files this pass leaves behind (review tools, same idiom as `tools/r1_p2b1_*`):
`vajb-orbit/tools/d7r1_ac5_seg.py`, `vajb-orbit/tools/d7r1_probe.gd|.tscn`. Probe log:
`/tmp/d7r1_probe_final.log` (transient). The probe writes and deletes
`res://ui/hud/cockpit_style_user.tres` inside its own run; the file is gone afterwards
(verified, `FileAccess.file_exists` false in-run and `ls` after).

## HIGH-1 — the status modal's hull render box never shrinks to its aspect-fit size, so the render and its hardpoint markers are wrong on every hull

- **Where:** `vajb-orbit/ui/hud/ship_status_screen.gd:379-385` (`_place_render_box`),
  called from `:351` (`_apply_style`) and `:521` (`_refresh_render`).
- **Cause (measured):** the box sets `size` **before** lowering `custom_minimum_size`:
  `:383 _render_box.size = _render_size`, `:385 _render_box.custom_minimum_size = _render_size`.
  Godot's `Control.size` setter clamps up to `custom_minimum_size`, and `_build_left_well`
  (`:279`) left the minimum at `RENDER_MISSING_SIZE` = **320×320**. So the `size` write is
  clamped to 320×320, and the later minimum write to 244×132.42 cannot shrink it back.
  Re-measured in the probe on a bare Control: `custom_minimum_size=(320,320)` then
  `size=(244,132.42)` yields `size=(320,320)`; lowering the minimum afterwards leaves it
  320×320 (`R1_status_render_diag.clamp_demo`).
- **Measured consequence** (`ship_vanguard`, native side cut 960×521, style render area
  `(40,76,244,336)`; probe `R1_status_render_diag`):

  | property | measured | intended (§3.8 Mockup C) |
  |---|---|---|
  | `HullRenderBox.custom_minimum_size` | (244, 132.42) | (244, 132.42) |
  | `HullRenderBox.size` | **(320, 320)** | (244, 132.42) |
  | `HullRenderBox.position` | (40, 177.79) | (40, 177.79) |

  `HullRender` is a full-rect `TextureRect` with `STRETCH_KEEP_ASPECT_CENTERED`, so inside
  the 320×320 box the 960×521 cut is drawn **320×173.67**, centred at box-local
  (0, 73.17)-(320, 246.84), i.e. body-space **(40, 250.96)-(360, 424.63)**. The left well is
  `(24,60,276,368)` → x 24..300; the sprite runs **60 px past the well's right edge and
  44 px into the right well** (which starts at x 316). The intended rect was
  (40,177.79)-(284.42,310.21), fully inside the well.
- **The markers are off too:** `_collect_markers` (`:547`) computes positions in the
  `_render_size` (244×132) space (`centre = _render_size * 0.5`, `pos = centre + anchor *
  _render_scale`) and `HardpointMarkers` is a full-rect child of the same oversized box, so
  the 11 dots (3 mounts, 8 thrusters; probe `R1_status_markers`) are drawn in the box's
  top-left region while the sprite sits centred 73 px lower — marker 0 at (27.70, 37.90) is
  ~35 px above the sprite's top edge. The bone-ringed ember read itself is correct
  (`HardpointMarkers._draw` at `:1075-1079`; measured ring `#C9CDD2`, fill `#C8471F`,
  radius 5, width 1).
- **Why every existing gate missed it:** the only place `size` is set is
  `_place_render_box`; `D7-C3_report.md` reports `box: (244, 132.42)` and `pos: (40, 177.79)`
  — those are `custom_minimum_size` and the (correct) intended position, never the laid-out
  `size`; and `tests/test_d6_status.gd:574` guards on `box.custom_minimum_size` (`:569-581`),
  so the clamp class is invisible to the suite.
- **Reversal / fix (one line):** set `custom_minimum_size` before `size` in
  `_place_render_box`, e.g. lower the minimum first, then assign `size` (and/or
  `reset_size()`); add a `box.size` leg to the D6 guard so the class cannot ship again.
- **Tier: HIGH** — a pinned acceptance of §3.8's Mockup C block ("the hull side render
  aspect-fit into the well" + "hardpoint markers … over the render") fails visibly on every
  hull, and the report's evidence measures the intended, not the actual, geometry.

## MED-1 — the armory console is not `2×` the pane's measured content rect, and the plate is fill-stretched 5.29 % vertically

- **Where:** `vajb-orbit/ui/station/armory_style.gd:38,45,113` (`canvas` 436×454,
  `ammo_well` height 68, `block_size = canvas * art_scale`) and
  `vajb-orbit/ui/station/armory_panel.gd:737-738` (`_body.custom_minimum_size = (block.x,
  bottom + block_foot)`).
- **Pin:** `UI_SPEC.md` §3.10 — "The pane mounts as a painted metal console
  `ui_armory_console` (2× the pane's own measured content rect; the rect is measured in code
  and reported — nothing is invented)".
- **Measured (probe `R1_armory`):** the shipping pane is 1392×756 (station shell, C2's own
  measurement), the console master is 1744×1816 and the drawn block/plate is **872×956**
  (body size and `ConsolePlate` size, `stretch_mode = SCALE`). So the plate is 0.63× the
  pane's width, and its drawn box (872×956) is **not** the master's logical half (872×908):
  vertical fill **956/908 = 1.0529** (+5.29 %), horizontal 1.000.
- **Second, independent cause of the mismatch:** `ammo_well` is `Rect2(15,398,406,68)` —
  68 logical — while its own doc comment (`armory_style.gd:43-45`) names Mockup A's
  `(30,796)-(842,884)` = 44 logical, and its own mockup canvas (454) is drawn for the 44
  well (`block_foot` 12 after y 442). The 68 well (C2's Deviation 3, six ammunition packs
  in 2 rows) pushes the block 24 logical past the canvas, which is exactly where the 5.3 %
  stretch comes from.
- **Notes:** C2's Deviation 4 reports the fixed-block choice and A0 pinned the rect from
  Mockup A's canvas; the plate is flat (Amendment 2), so the stretch only scales brush grain
  and bolts. But §3.10's pin is unmet and the approved Mockup A proportions (0.96 master)
  are not what ships (0.912).
- **Escalation, not a fixer item:** choosing between "stretch the plate to the pane" (the D3
  painted-plate defect class §3.7/§3.10 forbid) and "keep a fixed block" (the §3.10 pin) is
  a bucket-2/3 design call the developer/owner must make. Reversal paths are already in
  C2's report (`ArmoryStyle.canvas`, or a wider re-rendered master).
- **Tier: MED** — a pinned number is not met; the deviation is reported but unreconciled.

## LOW findings (rows appended to `_state/LOW_BACKLOG.md`)

1. **L158 — the old-column retirement's own comment is stale.** `hud.gd:1098-1099` still
   says "The pool blocks (section 3.1b) are **not** retired - section 3.7's list names
   section 3.1's crest bars only". C4 retired them; probe `R1_retired_pool_blocks` reads
   `["EnergyBlock","FuelBlock"]` both `visible=false`, and `_retire_pool_blocks` (`:993`)/
   `retired_pool_blocks` (`:1002`) are the truth. The banner's own comment and the C4
   report are correct; only this block's doc is wrong.
2. **L159 — a dropped `cockpit_style_user.tres` cannot be un-dropped in-session.** Measured
   (`R1_style_drop_reverted`): after `ResourceSaver.save(..., USER_PATH)` and a cluster
   load, deleting the file leaves `ResourceLoader.exists(USER_PATH) == true` and a fresh
   cluster still reads the user style (`box` 600×300 instead of 464×256) — the resource
   cache answers for the deleted path. The drop-in itself works (LOW-1's probe: box, bays,
   pitch, drum, label colour and dial centre all move; `R1_style_drop`), and a restart
   reverts; C1's "the override is not a one-way door" holds only across a restart.
3. **L160 — `CockpitStyle` does not carry the value dial's drawing detail** (§3.9 rule 5's
   "every layout metric"): `cockpit_cluster.gd:688-689` hardcode the wedge band
   (`radius-4`/`radius-9`), `:712` the needle length (`radius-12`) and `:608` the name label's
   vertical placement. The ruled fields (palette / box, band, bays, gutters, row pitch,
   label zone, drum cell, dial radii, lamp size / panel & face & plate paths) are all
   present. Also `armory_panel.gd:1538` uses `Color(0,0,0,0)` for the hidden S5 ink — a
   non-token colour, fully transparent.
4. **L161 — the D6 masters' staging copies moved out of `_masters/`, contradicting A1b's
   own note.** `D7-A0_report.md` §A1b Deviation 4 says "The plate-composited D6 masters stay
   in `_masters/` as the D6 record", but the wave verifier's `deleted` list carries 17 files
   (`_masters/ui_seg_*.png`, `ui_cockpit_frame`, `ui_compass_*`, `ui_gauge_needle`,
   `ui_readout_glass`) and `_masters/` now holds only the six D7 masters. Copies survive
   (`_masters_pass1/`, `_masters_r2tmp/`, `_a1b_backup/`), so nothing is lost; it is a
   staging/report-accuracy note, and it is the reason a future `ship_d6`/`ship_d7` run must
   not assume `_masters/` is the D6 record.
5. **L162 (process) — `test_d6_cluster.gd` moved 10 of its 14 rows, beyond the brief's
   sanctioned "compass rows only".** `git diff 639df19 -- …/test_d6_cluster.gd` = 212 lines
   (4 unchanged, 4 renamed, 6 changed; plus doc-block edits); the brief pinned "only the
   compass rows". The re-aim is **honest** (I read the whole diff: every moved row asserts
   the v6/v7 surface — the 464×256 box, the two dials, the four-row stack, the retired `%`
   cell, the retired compass as stubs — and no assertion was weakened; the unchanged rows
   are the dial contract, hull danger, overdrive and digits-never-recolour), and UI_SPEC's
   v6/v7 block makes the old rows unassertable. But changing the tests-that-move list is the
   developer's ruling per the `AGENTS.md` ladder (bucket 2); C1 reported it and no one
   ratified it. Close-out should record the ratification (CONTRACTS §18 mirror / D7 note).

## Escalations (bucket 2/3 — no fixer can resolve these)

- **MED-1** above (armory console rect vs §3.10) — needs the developer/owner ruling.
- **The battery lamp band is five wide while the rack map reaches seven.**
  Measured: `CockpitStyle.lamp_count` 5, `lamp_rect` B1..B5; `set_active_rack(6|7)` lights
  nothing (`R1_lamp_feed` `[[1,1],[3,3],[5,5],[6,0],[7,0],[0,0]]`), and the armory exposes
  B1..B7. §3.7's Mockup v5 delta 2 pins **five** lamps, so this is per-spec, not a defect —
  but a player on rack 6/7 gets no lit lamp. Owner tick (C1 Deviation 11).
- **`docs/design/UI_CHROME_ASSETS_SPEC.md:289`** (A1's own reported note): the status plate
  covers the well union 99.73 %, 2 px (1 logical px) short at the box's very bottom (the
  footer strip's last row). Reported by A1; no re-render chased it.

## Measured conformance (the wave's acceptance list, re-measured)

**(1) CockpitStyle is the single surface, and a dropped `.tres` restyles + relayouts with no
code edit.** `R1_style_drop`: `res://ui/hud/cockpit_style_user.tres` (box 600×300, `bay_left`
150, `row_pitch` 60, cell 24×40 on 26, `text_dim` green, `dial_top` (280,90)) loaded by a
fresh `CockpitCluster` with no argument gives `custom_minimum_size` 600×300, bay 150, pitch
60, drum 24×40, row 0 at (419,33,138,36), the SPD label colour **exactly** the file's green,
the FUEL dial at (244,54). All three surfaces load the default path
(`cockpit_cluster.gd:115`, `ship_status_screen.gd:201`, `armory_panel.gd:680`), each with its
own override path. Hardcoded-colour counts: `cockpit_style.gd` **11** `Color("#…")` (the
palette defaults — the one style file), `armory_style.gd` **0**, `cockpit_cluster.gd` **0**,
`ship_status_screen.gd` **0**, `armory_panel.gd` **0** (one `Color(0,0,0,0)`, L160),
`hud.gd` **2** — both byte-identical pre-D7 (`#565C63` in a comment at `:1557`, the
sanctioned §3.6 `accent_nav` fallback `#6fb8c4` at `:1666`).

**(2) Digit fit law.** All four rows, every cell: `Rect2(36/58/80/102, 0, 20, 36)` — size
exactly 20×36, pitch 22, **0 overlapping pairs** and **0 cells outside the 122×36 row**
(`R1_rows`), and every `digit_cells()` `modulate` is white (digits never recolour). The
row's cells are positioned at `style.cell_rect(i)` (`cockpit_cluster.gd:769-772`), never
container-laid-out.

**(3) The v7 layout.** `R1_style_defaults`/`R1_wells`/`R1_gauge_bay`: box 464×256, band 32,
interior (32,32,400,192), bays 126/104/156 with 7 px gutters; the five code-drawn wells at
(35,48.5,120,120), (32,185,126,36), (174,38,80,80), (174,141,80,80), (279,32,150,189.1);
dials r 36 with **rim clearance 23.0** (well r 40; centres (214,78)/(214,181); nodes at
(178,42)/(178,145), 72×72); rows SPD/HULL/SHLD/AMMO at y 33/83.7/134.4/185.1 on the
**50.7** pitch, bottoms 69/119.7/170.4/**221.1** = the foot band's 221 (band 185..221);
lamps B1..B5 22×22 on 25 px centres in the foot well, **exactly one lit** for the selected
rack, fed from the HUD (`select_battery(2)` → `active_rack` 2, `lit` 2, `R1_lamp_from_hud`).
The cluster lands at (12,812) 464×256 in `CanvasLayer/BottomLeft/Blocks` (`R1_cluster_box`).
The panel is a flat `TextureRect` master 928×512 → box 464×256 = exact 2× (no stretch).

**(4) Retirements.** `compass()` null, `compass_heading()` 0.0, `readouts()` = {spd, hull,
shield, ammo} with **no `hdg`** key (`R1_stubs`); the §3.6 dial has no heading member
(`has_heading_prop` false) and ignores the heading leg (`R1_speedometer`), and
`hud.gd`'s `Speedometer._draw` (`:1743-1775`) draws no tick. The old column is retired
hidden: `["HullBlock","ShieldBlock","AmmoPanel","CargoToggle","CargoPanel"]`, `visible`
false and not visible in tree (`R1_retired_old_column`). The §3.1b pool bars are retired:
`["EnergyBlock","FuelBlock"]` hidden (`R1_retired_pool_blocks`), `set_pool` feeds only the
cluster dials (fuel 12/200 = 6 % danger, ENRG 40/100 = 40 %, `R1_pools`). The `EMERGENCY
FLIGHT` banner is found in `Blocks`, text `EMERGENCY FLIGHT`, hidden until
`set_emergency(true)` → visible in `accent_danger_bright` (`R1_banner`, `R1_banner_lit`).

**(5) Armory.** Wells drawn (30,122,812,390)/(30,570,812,170)/(30,796,812,136) from the
pinned logical (15,61,406,195)/(15,285,406,85)/(15,398,406,68); bays 194×182 in Mockup A's
**4+3** grid at (44,136)+(col·202, row·190) (`R1_armory`). SALVO is **centiseconds**:
`_salvo_figure` 0.0→-1, 0.6→60, 0.73→**73**, 1.2→120, and a `SalvoStrip` fed 73 renders
cells `[0,7,3]` / text **"073"**, blank → `"---"`; the drum cell draws 40×72 at (64,104)
(`R1_salvo_figure`, `R1_salvo_strip`). Transactions are untouched and byte-behave:
`git diff 639df19 -- vajb-orbit/tests/test_p2b* test_s5_*` is **empty** (no such suite moved)
and the full gate is 711/0, so the refusal-writes-nothing / drag-order rows still pass.

**(6) Status modal.** Wells at Mockup C's rects (24,60,276,368)/(316,60,380,288)/(24,444,
672,50); plate `TextureRect` master 1440×1040 → box 720×520 = exact 2×; the retired D6
nine-slice frame node survives hidden (`ui_cockpit_frame`, `visible` false); title `SHIP
STATUS` at (30,22), close box (668,20,26,26); style cell 60×74 on 72×88 with
`status_cell_rect(0,0,5,3)` = (332,76,60,74), `(4,2,5,3)` = (620,252,60,74) and the whole
5×3 rect (332,76,348,250) inside the inner (332,76,348,256); the vanguard's live 4×4 grid
scales to 0.7574 with 11 refs (`W1…`), the ref Label at font 10 / variation `SlotNumber`;
hardpoint dots: 11 (3 mount, 8 thruster) as bone-ringed ember over `HullRenderBox`; the
footer's `PWR 3 / 8` equals `ShipFit.fit_legal(vanguard, base_fit)[power]` = draw 3 / out 8
(the fitting panel's own `_power_of`, `fitting_panel.gd:1239-1240`) (`R1_status_*`).
**Except:** the render box — HIGH-1.

**(7) The 12 `ui_seg_*`.** Independent AC5 (my own Pillow implementation of
`qc_seg_digits.py`'s verdict on the *shipped* bytes): every cell 48×88 RGBA, 64.06 %
transparent, opaque palette **exactly** `#C9CDD2`/`#2A2E35` with no plate face (e.g.
`ui_seg_0` 1150 lit / 160 unlit opaque px; `ui_seg_blank` 1310 unlit / 0 lit); containment
**1.0000 on all 12**; blank smallest (0.0000 vs 0.3465); `1` smallest digit (0.3465); `8`
largest (1.0000); no by-segment inversion; verdict **PASS** (`tools/d7r1_ac5_seg.py`). The
md5s match A1b's table. **23/23 masters** present with the exact §11/§12 boxes (all six
panels/frames, needle, rose, lubber, glass and the 12 cells; 0 mismatches), verified
independently of `reconcile_d7.py`. Import params unified
(`compress/mode=0`, `mipmaps/generate=true`, `detect_3d/compress_to=0`) on the panels, the
cells and the gauge face.

**(8) Tests.** `tests/test_engine2_hud.gd` vs `639df19`: 18 insertions / 7 deletions, all
inside the §3.1b row (renamed `test_the_pool_blocks_retire_to_the_cluster_dials`) plus its
section header comment — **exactly** what the §3.1b amendment names; no heading-tick
assertion exists in that file (`rg heading|tick` → none), so §3.6's amendment moves zero
rows there. `tests/test_d6_status.gd` is **byte-identical** and its 16 rows are green.
`test_p2b*`/`test_s5_*` untouched. `tests/test_d6_cluster.gd` moved (see L162).

## Gate, verifier and attribution

- **Gate twice, fresh scratch stores, identical:** `[SUMMARY] passed=711 failed=0` both
  (`/tmp/d7r1_g1.log`, `/tmp/d7r1_g2.log`), exit 0. The only `SCRIPT ERROR` is the
  pre-existing `test_weapon_fx_f4.gd:178` row, and that row still PASSes.
- **Live profile untouched:** `profile.cfg` md5 `b6dfd89df04bcf1923e8b31f3f58b66c` and mtime
  `2026-09-24 11:55:25`, `economy_log.txt` md5 `4182a16526c5afef556b21922f29768d` — identical
  before and after all four gate runs.
- **Wave verifier (`d7_start`, `--tests`, scratch store):** exit 1 with the **single**
  problem `forbidden files touched: docs/CONTRACTS.md`. That file's uncommitted delta
  (`+67/-15` vs `HEAD`) is **the parallel S7 affix lane's docs-first**, not D7: the diff
  content is S7 §20 (`Affixes.summary` `instances`, `damage_mult`, `sell_price` sites) and
  cites `S7_BRIEF.md`; `git diff` for `project.godot`,
  `docs/gameplay/18_engine_spec.md` and `docs/gameplay/08_ship_slots_modules.md` is empty.
  Same-lane other writers in the run: `docs/design/UI_SPEC.md` + `UI_CHROME_ASSETS_SPEC.md`
  (the designer lane's v6/v7 + Amendment 2 docs-first, landed after the 10:22 snapshot),
  `docs/gameplay/09|12|13|15` and `tests/test_s6_*`/`test_engine2_wiring` + `staging/**`
  (S6/S7). The four expected reports are present; C4's report exists too but is not in the
  brief's `--expect-reports` list (the v7 amendment added C4 after the brief was written).
  The verifier's `deleted` list (17 staging `_masters` files) is L161.
- **No frozen file moved, no balance number moved** beyond the attributed S7 `CONTRACTS.md`.

## Owner ticks to close the wave

- **HIGH-1** must be fixed (F1) before the wave closes; then a `box.size` guard belongs in
  `test_d6_status.gd`'s render helper so the class is visible to the suite.
- **MED-1**: rule the armory console's rect (fixed block vs the §3.10 `2×` pin) and whether
  the 5.3 % plate fill is acceptable; a re-render or a style `canvas` change reverses either
  way.
- Already-carried ticks, unchanged: the D6 carry-overs (NMS teal, HULL/SHLD %, key U,
  per-module damage), the armory's `OWNED ×n` / HELD-MAX copy rows, the five-lamp band vs
  seven racks, and the status plate's 2 px coverage note.
