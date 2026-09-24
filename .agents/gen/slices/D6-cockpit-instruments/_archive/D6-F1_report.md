---
slice: D6
worker: D6-F1
model: "crush session (orchestrator-dispatched fixer)"
status: actionable
gate: "607/0 → 608/0 (two scratch stores, identical pass lists, exit 0)"
---

# D6-F1 report — fixer, R1-MED-1 only

## Result

`R1-MED-1` is closed. The status screen's render box no longer takes the row's
height: `ui/hud/ship_status_screen.gd:230` now gives it `SIZE_SHRINK_CENTER`, so
the box is exactly the aspect-fit sprite's rect and the 11 hardpoint markers are
laid out in the on-hull space they were always computed for. The blind suite is
replaced by an assertion against the sprite's drawn rect, on **both** branches
(intact 320×173.667 and damaged 320×311.867). Gate **608/0 twice** on scratch
stores (was 607/0; +1 test method, zero failures).

## Findings, finding by finding

| Finding | Bucket | Disposition |
|---|---|---|
| `R1-MED-1` markers drawn in a space the render box is not | 1 (no pin moves) | **Fixed.** `size_flags_vertical: SIZE_EXPAND_FILL → SIZE_SHRINK_CENTER` at `ship_status_screen.gd:230`; the blind assertion at `test_d6_status.gd:533-552` is replaced by `_assert_markers_on_the_drawn_sprite` (`:562-594`) and a new damaged-branch test (`:544-555`). |
| `R1-MED-2` pinned content wider/taller than the frame interior | 2 (fixing it moves a pin) | **Not touched**, per the orchestrator ruling and the review. No `docs/` change, no box/band/bay number moved. |
| `L141`–`L149` (nine LOW) | — | **Not touched**, per the scope, with one exception below. |
| `L142` (marker assertions compare against the old render size) | LOW, but the review ties it to `R1-MED-1` (`D6-R1_review.md:113`) | **Symptom closed as part of the MED fix**: the suite now derives the drawn rect from the render box's own rect and the texture's native size, and asserts the box cannot expand. The `L142` row is now stale and should be retired by the developer at slice close. |

## The fix, and why this route

The review offered two routes; this is its first, chosen because the gate has no
frame:

- The headless runner calls each test method synchronously and never awaits a
  frame (`tests/headless_runner.gd:159-164`), so a read-back that depends on the
  box's *laid-out* rect (the review's explicit-derivation route) would read a
  zero-sized box in the gate and at every assertion. Route one is
  layout-independent by construction: with `SIZE_SHRINK_CENTER` and
  `custom_minimum_size = _render_size` (`ship_status_screen.gd:408`), the box's
  rect **is** its minimum, which is the aspect-fit sprite's rect.
- The sprite does not move: an aspect-fit sprite centred in a taller box and a box
  that hugs the sprite and is itself centred in that taller box put the sprite at
  the same y. So this is a marker-space fix, not a visual reflow.
- Only the vertical axis was wrong (the box width was already 320, the sprite
  width); the change is vertical-only, matching the cluster's own idiom for bays
  that must hug a pinned box (`cockpit_cluster.gd:141,150,168`).

The marker read-back (`:419` `set_markers(anchors, _render_size)`, `:433` centre,
`:242` the markers node a FULL_RECT child, `:816` draws the raw position) is
unchanged: it was always correct *relative to the sprite*, and the box is now that
same space.

## The new assertion

`_assert_markers_on_the_drawn_sprite` (`test_d6_status.gd:562-594`) re-derives the
sprite's drawn rect the way `STRETCH_KEEP_ASPECT_CENTERED` draws it
(`fit = min(box/native)`, `drawn = native*fit`, centre `(box−drawn)/2 + drawn/2`),
never from the screen's own render-size field, then asserts every marker hits
`drawn_centre + anchor*fit` for all four thruster modes and the mounts. It also
asserts the two properties that make box-local coordinates on-hull: the box has no
`SIZE_EXPAND` flag and the aspect-fit sprite fills the box. The damage swap is
covered by a second test because the vanguard's damaged cut changes the aspect
(960×521 → 1023×997), which is exactly what made the old offset state-dependent.

## Evidence

```
# negative control: reverted :230 to EXPAND_FILL, ran the focused suite
[FAIL] test_d6_status.gd.test_the_hardpoint_markers_follow_the_hulls_own_map:
       intact: the render box takes the sprite's aspect, never the row's height
[FAIL] test_d6_status.gd.test_the_markers_stay_on_the_sprite_when_the_damaged_cut_is_drawn:
       damaged: the render box takes the sprite's aspect, never the row's height
[SUMMARY] passed=14 failed=2        # the guard sees the defect on both branches
# ... restored :230 to SIZE_SHRINK_CENTER
[SUMMARY] passed=16 failed=0        # focused d6_status suite (was 15 methods)

# the wave gate, twice on scratch stores
XDG_DATA_HOME=/tmp/d6f1_g1 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=608 failed=0       # exit=0
XDG_DATA_HOME=/tmp/d6f1_g2 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=608 failed=0       # exit=0
diff <(grep '^\[PASS\]' gate1.log) <(grep '^\[PASS\]' gate2.log)   # IDENTICAL

# frozen and adjacent surfaces
git diff 49df633 HEAD -- vajb-orbit/tests/test_engine2_hud.gd       # empty
# d6_status 15 → 16 methods; d6_cluster 14 unchanged; every other suite's line unchanged
```

Both logs carry one non-fatal `ERROR: Parameter "data.tree" is null` from
`test_combat_repair_c5` (`game/weapons.gd:2050` via a detached fixture): it is
pre-existing, unrelated to this wave (no `game/` file is touched) and does not
become a failure. No new debug-ledger rows were introduced.

## Files touched

- `vajb-orbit/ui/hud/ship_status_screen.gd:230` — vertical size flag
  `SIZE_EXPAND_FILL → SIZE_SHRINK_CENTER` (one line).
- `vajb-orbit/tests/test_d6_status.gd:533-594` — the marker assertion replaced by
  `_assert_markers_on_the_drawn_sprite`, plus the damaged-branch test.

Nothing else: no `docs/`, no `game/`, no `autoload/`, no `project.godot`, no
theme, no asset, no other test file.

## Deviations from the brief / review

- None. The route is the review's own first option; no pinned number, file set or
  test-mechanics item was changed. The only judgment call is `SIZE_SHRINK_CENTER`
  over `SIZE_SHRINK_BEGIN`, which keeps the rendered sprite exactly where it was,
  zero-visual-change.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| `L142` is closed by this fix; retire the now-stale row | backlog hygiene | `.agents/gen/_state/LOW_BACKLOG.md` |
| `R1-MED-2` and owner ticks 2/6 (box, band or sanctioned overlap) | owner decision (bucket 2) | carried by `D6-R1_review.md` §Owner ticks |
