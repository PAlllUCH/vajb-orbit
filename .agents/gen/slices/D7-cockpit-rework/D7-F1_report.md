---
slice: D7
worker: D7-F1
model: "claude-sonnet-4.5 (fix session); Godot 4.7.2-stable headless; Python 3 + Pillow (no numpy)"
status: actionable
gate: "727/0 twice on fresh XDG scratch stores (identical row sets, exit 0); 711 was D7-R1's count before the parallel S7 lane added `tests/test_s7_affixes.gd` (15 rows) and this fix added one D6 row"
verdict: "R1's HIGH-1 fixed + its blind spot closed (both branches, the class now caught by the suite); R1's MED-1 code side landed; no LOW item touched"
---

# D7-F1 report — the cockpit wave's HIGH-1 and MED-1 cures

## Result

- **HIGH-1 (the status modal's render box never took its aspect-fit size).** `_place_render_box`
  now lowers `custom_minimum_size` **before** writing `size` (the `Control.size` setter clamps up
  to the minimum, so the old order left the D6 320×320 box in force), and `_build_left_well` no
  longer owns the stale 320 minimum at all. Measured with the reviewer's own instrument
  (`tools/d7r1_probe.tscn`): `box_size` **320×320 → 244×132.42**, `box_right` **360 → 284** (the
  left well's right edge is 300), `render_size` 320×320 → 244×132.42.
- **The blind spot is closed and the guard is proven sensitive.** `tests/test_d6_status.gd`'s
  helper now reads the **laid-out `Control.size`, never `custom_minimum_size`**, on both the
  intact and the damaged branch, and asserts the drawn sprite box sits inside the left well
  `(24,60)-(300,428)`; `tests/test_d7_status.gd` (C3's own evidence) reads the same way. One new
  D6 row stages the class where it is visible (a screen whose **first** render refresh lands on a
  hull it did not have at build): with the pre-fix code restored it fails
  `the drawn box (320.0, 320.0) is the sprite's own aspect fit (244.0, 132.4208)`; with the fix it
  passes.
- **MED-1 code side landed** per `UI_SPEC.md` §3.10 **Amendment 2**: the armory canvas is
  `Vector2(436, 478)` (drawn 872×956), the ammunition well's comment names the ruled 136/68, the
  console block is the style's **ruled canvas**, and the console plate mounts at its own
  `master / art_scale` box — **never fill-stretched**. The corrected master
  (`ui_armory_console` 1744×1912) landed from the parallel **D7-A2** run under the same filename
  while this run was in flight (asset mtime 12:41:59, import 12:42:46), so the mount now
  coincides with the block exactly: `plate.size == BLOCK == 872×956`,
  `plate.size * art_scale == master`. The 1.0529 vertical fill is gone.
- **No LOW item was touched** (L158–L162 stay open for the owner; the LOW rows are R1's, not mine).

## Finding-by-finding disposition

| R1 finding | Tier | Disposition |
|---|---|---|
| HIGH-1 — the render box keeps the stale 320×320 clamp, so the sprite draws past the left well and the markers land in the wrong space | HIGH | **Fixed.** `vajb-orbit/ui/hud/ship_status_screen.gd:279` (stale minimum removed) + `:379-385` (minimum written before size); the guard re-aimed onto the drawn box on both branches, plus one new D6 row that fails on the pre-fix code |
| MED-1 — the armory console is not 2× the pane's measured content rect and the plate is fill-stretched 5.29 % vertically | MED | **Code side fixed** exactly as the ruling orders: `armory_style.gd:38` canvas 436×454 → **436×478**, `:45` ammo-well comment → the ruled 136 drawn (68 logical), `:113` `block_size()` doc → 872×956, and `armory_panel.gd`'s `_apply_style`/`_lay_groups` → the plate mounts at `master / art_scale` (`_mount_plate`) with the block **floored at the style's ruled canvas**. The `1744×1912` master is D7-A2's deliverable and has landed (measured below) |
| LOW-1..LOW-5 (L158–L162) | LOW | **Untouched**, as scoped |

## What changed, and why the shape is what it is

1. **`ui/hud/ship_status_screen.gd` — `_build_left_well` + `_place_render_box`.**
   `Control.size`'s setter clamps up to `custom_minimum_size` (the reviewer's own
   `R1_status_render_diag.clamp_demo` measures it: set `(244,132.42)` under a 320 minimum and the
   size reads back `(320,320)` even after the minimum is lowered). So the minimum is now written
   **first** and the 320 minimum is gone from the build path entirely; `_place_render_box` owns
   both. The `RENDER_MISSING_SIZE` fallback for a hull with no renderable cut is unchanged in
   behaviour (it still yields the 320 box when there is no sprite to fit).
2. **`tests/test_d6_status.gd` — the yardstick.** `_assert_markers_on_the_drawn_sprite` reads
   `box.size` (not `box.custom_minimum_size`) and asserts `RENDER_WELL.encloses(Rect2(box.position,
   box.size))` on both branches; the dead `RENDER_WIDTH := 320.0` constant (the superseded D6 pin,
   unreferenced) became `RENDER_WELL := Rect2(24, 60, 276, 368)`. A new helper
   `_assert_render_box_takes_the_well(screen, state)` asserts the drawn box **is** the sprite's own
   aspect fit into the style's render area *and* sits inside the well; it is called before
   `set_open` on both branches. The damaged row now reports its damage **before** the hull push so
   the read measures the damaged branch at its first refresh. One new row
   (`test_a_screen_whose_first_hull_arrives_after_build_keeps_the_box_in_the_well`) mounts a bare
   screen the way `hud.gd` does, pushes exactly one hull, and reads the box — that is the only
   place in the suite where the class is observable (the fixture HUD refreshes once at its own
   build and a second refresh heals the stale box, which is why a read taken off it cannot see it).
3. **`tests/test_d7_status.gd` (C3's own evidence).** Same re-aim: `box.size`, plus the
   `WELL_LEFT` containment leg. No row moved; no assertion was weakened.
4. **`ui/station/armory_style.gd`.** `canvas` → the ruled 872×956 (436×478 logical);
   `ammo_well` keeps its 68 logical / 136 drawn height (Amendment 2) and its doc comment now says
   so, with Mockup A's illustrative "44" retired; the header/`console_path`/`block_size` docs
   carry the 872×956 / 1744×1912 pair.
5. **`ui/station/armory_panel.gd`.** `_mount_plate` mounts the console plate at its own
   `master / art_scale` box (anchors top-left, origin zero) — the mount is unstretched **by
   construction**, not by luck of the master's aspect. `_lay_groups` floors the block at the
   style's ruled canvas (`maxf(ruled.y, bottom + block_foot)`), so a grown group still extends the
   block while the shipped geometry is exactly the ruled canvas.
6. **`tests/test_d7_armory.gd` (C2's own suite).** `CANVAS` → `(436, 478)`, `CONSOLE_MASTER` →
   `(1744, 1912)`, and the mount leg became two rules: `plate.size * art_scale == master` (the
   master's own 2× box, never stretched) and `plate.size == BLOCK` (the mount **is** the ruled
   canvas, so the plate covers every well). Nothing else in the suite moved.

## Evidence

**Gate, twice, fresh scratch stores, identical row sets, exit 0** (`XDG_DATA_HOME` per run):

```
XDG_DATA_HOME=/tmp/d7f1_final3 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
        res://tests/headless_runner.tscn --quit-after 1200      # [SUMMARY] passed=727 failed=0
XDG_DATA_HOME=/tmp/d7f1_final4 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
        res://tests/headless_runner.tscn --quit-after 1200      # [SUMMARY] passed=727 failed=0
```

`diff` of the two runs' PASS/FAIL rows is empty. The only `SCRIPT ERROR` in either log is the
pre-existing `test_weapon_fx_f4.gd:178` row (`test_a_held_beam_reads_one_hit_per_contact_interval`),
which still PASSes — the same row D7-R1 recorded. The **live profile is untouched by both runs**
(`md5` identical immediately before and after; the gate's store is redirected into
`$XDG_DATA_HOME`, whose app dir holds only the gate's own `_gate_scratch`/`logs`).

Count arithmetic: 711 (R1) + 15 = the parallel S7 lane's new `tests/test_s7_affixes.gd`; +1 = this
fix's new D6 row → **727**. When R1 ran, HEAD was `d1accaa`; HEAD is now `8d592bc` (S7's commit,
12:45:20). `test_d6_status.gd` 16 → **17** rows; every other moving suite keeps its row count.

**HIGH-1, the reviewer's own instrument, before → after** (`tools/d7r1_probe.tscn`, scratch store):

```
before: box_size [320.0,320.0]  box_right 360.0  render_size [320.0,320.0]   (pre-fix)
after:  box_size [244.0,132.420837402344]  box_right 284.0
        box_min [244.0,132.420837402344]  box_pos [40.0,177.789581298828]
        render_size [244.0,132.420837402344]  area [40.0,76.0,244.0,336.0]
        well_left_right 300.0  well_right_left 316.0
        marker0 {kind thruster mode rear pos [27.7041702270508,37.8962516784668]}
        clamp_demo {size_set_to_244 [320,320], after_min_lowered [320,320]}   (the class)
```

The probe writes and deletes `res://ui/hud/cockpit_style_user.tres` in-run; verified absent
afterwards.

**The guard's sensitivity (negative run, pre-fix code restored, then reverted):**

```
[FAIL] test_d6_status.gd.test_a_screen_whose_first_hull_arrives_after_build_keeps_the_box_in_the_well:
       first push: the drawn box (320.0, 320.0) is the sprite's own aspect fit (244.0, 132.4208)
[SUMMARY] passed=16 failed=1
```

With the fix in place the same focused runs read:

```
--suite=test_d6_status                     # passed=17 failed=0
--suite=test_d6_status,test_d7_status,test_d7_armory                      # passed=36 failed=0
--suite=test_d7_armory,test_d6_status,test_d7_status,test_p2b1_outfitting_panel,test_s5_batteries
                                           # passed=48 failed=0
```

**MED-1, the shipped bytes and the mount:**

```
vajb-orbit/assets/ui/ui_armory_console.png   1744x1912 RGBA   (shipped 12:41:59, import 12:42:46)
style.canvas                    (436.0, 478.0)      -> block_size() (872.0, 956.0)
panel.block_size()              (872.0, 956.0)
%ConsolePlate.size              (872.0, 956.0)      == BLOCK
%ConsolePlate.size * 2          (1744.0, 1912.0)   == the master, unstretched
```

`ArmoryStyle.ammo_well` (15,398,406,68) logical → the drawn well `(30,796,812,136)`; the
ammunition group's six packs measure `rows_height(2, 32) == 68` exactly, so `growth(2, 68) == 0.0`
(the pinned well needs no growth) and the block's height comes from the ruled canvas, not from a
content overrun.

**Frozen sets and other lanes.** No `project.godot`, `docs/`, `addons/`, theme or `ui/theme/` byte
was touched by this run; the only files this run changed are the six listed below (mtime-verified,
all inside the F1 file set). The working tree also carries the parallel S7 lane's `game/**`,
`autoload/` and `tests/test_s7_affixes.gd` edits — attributed, not mine. The live
`profile.cfg` moved once at **12:54:49**, after S7's commit and while S7 was writing `game/*.gd`;
both of this report's gate pairs measured the store before/after and it is identical across them.

## Files touched

- `vajb-orbit/ui/hud/ship_status_screen.gd` — the stale 320 minimum removed from
  `_build_left_well`; `_place_render_box` lowers the minimum before writing the size (HIGH-1)
- `vajb-orbit/tests/test_d6_status.gd` — the drawn box read from `Control.size` + well
  containment on both branches; `RENDER_WELL` replaces the dead `RENDER_WIDTH`; the new
  first-push staging row; the damaged row reports its damage before the push
- `vajb-orbit/tests/test_d7_status.gd` — the same re-aim in C3's own helper (`WELL_LEFT`)
- `vajb-orbit/ui/station/armory_style.gd` — ruled canvas 436×478, the ammo-well comment, the
  872×956 / 1744×1912 docs
- `vajb-orbit/ui/station/armory_panel.gd` — `_mount_plate` (unstretched mount at
  `master / art_scale`) and the block floored at the ruled canvas
- `vajb-orbit/tests/test_d7_armory.gd` — `CANVAS`/`CONSOLE_MASTER` to the ruled pair; the mount
  proven as "the master's own 2× box" **and** "the ruled canvas"

## Deviations from the brief / the ruling (each reversible)

1. **(bucket 1) The unstretched mount is wired in code, not left to the master's aspect.**
   `_mount_plate` sizes the plate to `texture.get_size() / art_scale` and pins its origin, so a
   re-render can never be fill-stretched again — the ruling's property is now structural. Reversal:
   drop `_mount_plate` and let the full-rect anchors fill-fit the block (the pre-fix behaviour).
2. **(bucket 1) The block is the ruled canvas with a content-growth floor** (`maxf`), rather than
   the content-derived height alone. For the shipped geometry the two are identical (956), but the
   ruled canvas is now the floor, which is what makes the mount coincide with the block.
   Reversal: return `bottom + block_foot` alone.
3. **(bucket 1) One new row in `test_d6_status.gd`.** The brief pinned that suite "untouched"; the
   orchestrator's scope ordered its blind spot fixed, and the class is only observable on a screen
   whose first refresh lands after build, which the fixture HUD cannot produce. The row is additive
   (16 → 17) and touches no existing expectation. Reversal: delete the row and the
   `StatusScreenScript` preload.
4. **(bucket 1) The damaged D6 row now reports its damage before the hull push** (same final state,
   same assertions) so its box read measures the damaged branch at its first refresh. Reversal:
   restore the call order.
5. **(bucket 1) `RENDER_WIDTH := 320.0` (dead, unreferenced) was replaced by `RENDER_WELL`.**
   Reversal: restore the constant and its new comment.
6. **(bucket 2, attribution) The armory master's 1744×1912 bytes are D7-A2's**, not this run's;
   this report only wires the code and the pins that consume them.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| Nothing owed by this run: HIGH-1 and MED-1 are closed, LOW-1..LOW-5 are the owner's, and the armory master is D7-A2's landed deliverable | — | — |

The low-backlog rows R1 raised (L158–L162) are untouched, as the orchestrator scoped; the
`D7-C3_report.md` `PROBE_RENDER` line's `box:` reading is `custom_minimum_size` (the intended
geometry) and is superseded for the drawn geometry by the probe line in this report — the C3 report
itself was left as its worker wrote it.
