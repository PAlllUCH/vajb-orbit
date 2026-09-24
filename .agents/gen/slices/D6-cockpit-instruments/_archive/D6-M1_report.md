---
slice: D6
worker: D6-M1
model: "deepseek/deepseek-v4-flash (crush run, per D6_prompts.md)"
status: actionable
gate: "592/0 (full gate, scratch store, twice, identical) — of which 14 are test_d6_cluster.gd's own methods"
---

# D6-M1 report — cockpit instrument cluster

## Result

The UI_SPEC §3.7 cluster is built in code and wired: `ui/hud/cockpit_cluster.gd`
(`class_name CockpitCluster`) sits in `CanvasLayer/BottomLeft/Blocks` at 404×216
with the gauge / compass / readout bays, and `hud.gd` builds it in the §7
inner-widget idiom — `hud.tscn` is byte-untouched. The §3.6 dial contract is
unchanged (120×120, `SEGMENTS` 10, `SWEEP` 1.5π, `OVERDRIVE` 0.9,
`filled_segments()`/`overdrive_segment()`/`needle_colour()` identical); only its
`_draw` surface gained the painted `ui_gauge_face`/`ui_gauge_needle` sprites under
the code-drawn marks. Zero new feeds: everything derives from `set_speedometer`,
`set_pool` and the hull/shield handlers. All 18 spec'd masters (M0b) are used.

Measured: full gate **`[SUMMARY] passed=592 failed=0`**, twice on a scratch store
(`XDG_DATA_HOME=/tmp/d6gate`), identical both times. New suite
`test_d6_cluster.gd` = **14 tests, 0 failures**. `test_engine2_hud.gd` (incl. the
five §3.6 rows at 188–237), `test_engine2_wiring.gd` and `test_slice2_5_feel.gd`
re-run together: **49 passed, 0 failed**, and `git diff --stat` shows **zero**
lines changed in any of the three.

## Deviations from UI_SPEC §3.7 / the brief

Everything below is a choice inside the pinned acceptance (bucket 1) or a
measured inconsistency reported, not fixed (bucket 2). No pinned number moved.

1. **The frame is drawn at half scale (64 px master band → 32 px logical).**
   UI_CHROME §11 ships one master per sprite at 2× its logical box and §10's law
   is "display size stays logical … renders it at half scale"; `ui_cockpit_frame`
   is 192×192 with a 64 px band, i.e. the `ui_panel_frame@2x` geometry (96×96,
   32 px band) made primary. The nine-slice node therefore carries the master's
   64 px patch margins and is scaled 0.5 (node 808×432 → visual 404×216,
   measured: `size=(808.0,432.0)`, global `404.0×216.0`). Reversal: drop the
   scale and set `patch_margin_*` = 64 for a 64 px band.
2. **The pinned content is wider and taller than the frame's interior at that
   band, so the bays mount over the bezel.** Computed from the pinned numbers
   (measured layout, probe lines below): interior at a 32 px band = 340×152; the
   bay row is 120 + 20 + 100 + 20 + 136 = 396 wide (margins 4) and the glass is
   190 tall (margins 13). So the gauge overlaps the left band by 28 px and the
   glass overlaps the right band by 28 px and the top/bottom bands by 19 px each;
   the gauge and the compass clear the *vertical* bands (gauge y 48–168, mid bay
   y 41–175, band 0–32 / 184–216). §3.8's "720×520 … `ui_cockpit_frame`
   nine-slice **body**" reads the frame as filling the box, which is what this
   does. Reversal if the owner wants a fully visible bezel: grow the box to
   468×280 (content 404×216 inset 32) or sanction a thinner band — both change a
   pinned number, so they are the owner's, not a worker's.
3. **Route choices (bucket 1).** The cluster is its own file (not an inner class
   of `hud.gd`) because the HUD must not be referenced back from it: `hud.gd`
   owns the `Speedometer` (its contract is pinned byte-identical) and hands the
   instance to `cluster.gauge_bay()`. Row labels use a 12 px
   `add_theme_font_size_override` (§3.7's new §6 row pins 12 px; the theme is a
   forbidden file, so the override is the only route). The compass is a `Control`
   with `_draw` (`draw_set_transform`) rather than a rotated child, so the pivot
   is the canvas centre and the rotation is exact at any laid-out size.
4. **`cockpit()`/`compass()`/`compass_heading()`/`readouts()` are read-backs on
   both the HUD and the cluster.** §18's comment block heads with
   `cockpit_cluster.gd` while the probe precedent (`speedometer()`) is HUD-level,
   so both answer the same seam (the HUD delegates). `CockpitCluster.cockpit()`
   returns `self`.
5. **The danger rule needs raw pools the clamped ints cannot carry.** The cluster
   keeps `_hull_current/_hull_max` and `_fuel_current/_fuel_max` for the row
   treatments; `set_shield` stores its pair but has no rule of its own (§3.7
   gives shield no danger read). A zero-capacity tank is **not** treated as an
   empty one (`maximum > 0` gates the bright frame), the same guard
   `hud.gd::_hull_is_critical()` already uses; otherwise a fresh, unpushed HUD
   would frame FUEL immediately.
6. **No public `set_hull`/`set_shield` were added** (§18: "no new setters"). The
   test drives the existing handlers `_on_hull_changed` / `_on_shield_changed`,
   which is what the brief's "the hull/shield handlers" names.

## Evidence

Commands (from `$VAJB_WORKSPACE`, scratch store, no editor session left running):

```
XDG_DATA_HOME=/tmp/d6gate godot --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
XDG_DATA_HOME=/tmp/d6gate godot --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_d6_cluster
XDG_DATA_HOME=/tmp/d6gate godot --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_engine2_hud --suite=test_engine2_wiring --suite=test_slice2_5_feel
godot --headless --editor --path "$VAJB_PROJ" --quit   # register the new class_name, then quit (no session)
```

Decisive outputs:

```
[SUMMARY] passed=592 failed=0        # full gate, run twice, identical
[SUMMARY] passed=14 failed=0         # test_d6_cluster.gd (all 14 PASS)
[SUMMARY] passed=49 failed=0         # engine2_hud + engine2_wiring + slice2_5_feel
git diff --stat -- tests/test_engine2_hud.gd tests/test_engine2_wiring.gd tests/test_slice2_5_feel.gd  →  (empty)
```

Suite coverage (14 methods): cluster box 404×216 + compass 96×96 + the six rows
exist and the dial is a cluster descendant; the five §3.6 rows re-asserted
(constants, the `filled_segments` map {0.0→1, 0.05→1, 0.55→6, 0.95→10, 1.0→10},
`overdrive_segment` 9 at 0.95 / −1 at exactly 0.9, `needle_colour`); the readouts
map (spd from a 3-4-5 = 50, hull 812, shield 240, fuel 12/200 = 6 %, energy
40 %); blank padding (5→`[-1,-1,5]`, 0→`[-1,-1,-1,0]`, 1234→`[1,2,3,4]`); clamps
(5000 u/s→999→`[9,9,9]`, 20000→9999, 12345→9999, 250/100→100, 150/100→100);
`maximum 0`→0; the `%` cell only on FUEL/ENRG (and it is the `ui_seg_pct` cut);
hull 25 %→no frame, 24.9 %→`accent_danger` frame + `accent_danger_bright` label,
max 0→no frame; fuel 16 %→none, 15 %→`accent_danger` frame+label, 0/100→
`accent_danger_bright` frame, 0/0→none; overdrive 0.9→no frame, 0.9001→frame,
SPD label stays `text_dim`; digits keep `Color.WHITE` modulate under all three
danger reads; rose angle = −heading.angle() both directions; heading map
0/90/180/270 with HDG cells `[2,7,0]` at 270.

Laid-out geometry (temporary probe, deleted after the run; global rects on the
1152×648 canvas):

```
cluster      pos=(0,0)    size=(404.0,216.0)
frame        size=(808.0,432.0)  → global 404.0×216.0 (scale 0.5)
gauge_bay    pos=(4,48)   size=(120.0,120.0)
dial         pos=(0,0)    size=(120.0,120.0)
mid_bay      pos=(144,41) size=(100.0,134.0)   compass (2,0) size=(96.0,96.0)
readout_bay  pos=(264,13) size=(136.0,190.0)   glass/rows (0,0) size=(136.0,190.0)
row spd/hull pos y=1/39, size 100×36 / 122×36; fuel/enrg y=115/153
```

Live profile untouched: `~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg`
mtime 2026-09-24 06:47, before this dispatch; every gate/probe ran under
`XDG_DATA_HOME=/tmp/d6gate`. `git status` shows `hud.gd` as the only modified
project source; `project.godot`, `theme/`, `game/`, `autoload/`, `addons/` and
all frozen docs untouched.

## Files touched

- `vajb-orbit/ui/hud/cockpit_cluster.gd` — **new** (`class_name CockpitCluster`,
  532 lines): the 404×216 bezel, the three bays, the compass, the five readout
  rows + HDG, the digit/clamp/padding/percent logic and the danger-row rules.
- `vajb-orbit/ui/hud/cockpit_cluster.gd.uid` — new sidecar (Godot 4.7).
- `vajb-orbit/ui/hud/hud.gd` — +110/−14: `_build_cockpit`/`_build_speedometer`
  rewired onto the cluster, pushes in `set_speedometer`/`set_pool`/
  `_on_hull_changed`/`_on_shield_changed`, the four read-backs, and the
  `Speedometer._draw_surfaces` paint layer (+ face/needle consts,
  `_needle_overdrive` token).
- `vajb-orbit/tests/test_d6_cluster.gd` — **new**, 14 test methods.
- `vajb-orbit/tests/test_d6_cluster.gd.uid` — new sidecar.
- `vajb-orbit/.godot/global_script_class_cache.cfg` — local, gitignored; the
  headless editor pass registered `CockpitCluster` so the headless gate resolves
  the type.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| The cluster's pinned content exceeds the frame's interior at the 2×-primary frame's 32 px band (content 396×190 vs interior 340×152), so the bays overlap the bezel; §3.7/§11 need a consistent pair of numbers | docs finding (bucket 2 — pinned numbers) | `docs/design/UI_SPEC.md` §3.7, `docs/design/UI_CHROME_ASSETS_SPEC.md` §11 |
| Cardinal letters on the compass rose (staged out by the no-text law; engine `Label`s would be the route) | deferred, already staged | brief §Staged |
