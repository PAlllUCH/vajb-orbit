---
slice: D6
worker: D6-M1b
model: "deepseek/deepseek-v4-flash (crush run, per D6_prompts.md)"
status: informational
gate: "607/0 (full gate, scratch store, twice, identical) — of which 14 are test_d6_cluster.gd's own methods"
---

# D6-M1b report — SPD becomes 4 cells (owner amendment 2026-09-24)

## Result

Applied the owner's mid-wave ruling to the D6-M1 cluster: the `SPD` readout row is
now **4 digit cells** with leading `ui_seg_blank` blanks, and SPD clamps `0..9999`
instead of `0..999`, matching `int(round(prograde.length()))` per UI_SPEC §3.7's
2026-09-24 Digit semantics amendment. Two lines of code moved
(`cockpit_cluster.gd`: `SPD_MAX` 999 → 9999, the SPD row's cell count 3 → 4); the
row now measures 122×36, identical to `HULL`/`SHLD`/`FUEL`/`ENRG`, so every
readout row is the same width.

The pinned **404×216 cluster box is unchanged** and the 4th cell fits the pinned
geometry with margin to spare — **no overflow** (measured below). `hud.gd` needed
no change: it already delegates the SPD derivation to the cluster and carries no
SPD constant of its own. No other test moved.

## Deviations from UI_SPEC §3.7 / the brief

None. The spec's own text fixes every number: SPD 4 cells, clamp 0..9999, leading
blanks; FUEL/ENRG stay 3 digits + the `%` cell and HDG stays 3 cells as the same
§3.7 rows pin them. The only judgment calls are test-shape ones inside the
"adjust only `test_d6_cluster.gd`'s SPD clamp/padding rows" acceptance (bucket 1):

1. The old clamp row drove `5000 u/s` to prove the `999` cap; with the cap now
   9999 that input reads `5000`, so the row was re-pointed at `20000 u/s` for the
   9999 boundary and a `5000 → 5000` assertion was added so the test proves the
   old 3-cell clip is gone, not merely that a new cap exists. Both are the
   allowed SPD clamp/padding rows.
2. No pinned number, no `game/`/`autoload/`/`project.godot`/theme write, and no
   other test file was touched.

## Evidence

Commands (from `$VAJB_WORKSPACE`, scratch stores, no editor session, no
background job):

```
XDG_DATA_HOME=/tmp/d6m1bgate  godot --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_d6_cluster
XDG_DATA_HOME=/tmp/d6m1bgate1 godot --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
XDG_DATA_HOME=/tmp/d6m1bgate2 godot --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
XDG_DATA_HOME=/tmp/d6m1bgate1 godot --headless --path "$VAJB_PROJ" --script res://tests/_d6m1b_probe.gd   # temporary probe, deleted
```

Decisive outputs:

```
[SUMMARY] passed=14 failed=0      # test_d6_cluster.gd, all 14 PASS
[SUMMARY] passed=607 failed=0     # full gate run 1
[SUMMARY] passed=607 failed=0     # full gate run 2 (identical)
```

Changed rows in `test_d6_cluster.gd` (nothing else in the file changed):

| Test | Before | After |
|---|---|---|
| `test_the_digit_cells_pad_with_blanks_never_leading_zeros` | `_cells(SPD) == [-1,-1,5]` ("3 cells") | `[-1,-1,-1,5]` ("4 cells") |
| `test_the_readouts_clamp_at_their_cell_maxima` | `5000 u/s` → SPD `999`, cells `[9,9,9]` | `5000 u/s` → SPD `5000`, cells `[5,0,0,0]`; **new** `20000 u/s` → SPD `9999`, cells `[9,9,9,9]` |
| `test_the_readouts_are_the_clamped_ints_the_digits_show` | SPD 50 (3-4-5) | unchanged (passes; 50 < both caps) |

Measured layout (temporary probe, global rects on the 1152×648 canvas; deleted
after the run — only `test_d6_cluster.gd` and `cockpit_cluster.gd` remain in
`git status`):

```
cluster      size=(404.0, 216.0)          # pinned box, unchanged
readoutbay   size=(136.0, 190.0)          # ui_readout_glass logical box
rows         size=(136.0, 190.0)
row spd      pos=(7.0,   1.0)  size=(122.0, 36.0)   # was 100 wide as 3 cells
row hull     pos=(7.0,  39.0)  size=(122.0, 36.0)
row shld     pos=(7.0,  77.0)  size=(122.0, 36.0)
row fuel     pos=(7.0, 115.0)  size=(122.0, 36.0)
row enrg     pos=(7.0, 153.0)  size=(122.0, 36.0)
midbay       size=(100.0, 134.0)
gaugebay     size=(120.0, 120.0)
```

**Overflow numbers: none.** The 4-cell SPD row is 122 px wide inside the 136 px
readout bay (7 px clearance each side: `7 + 122 = 129 ≤ 136`), exactly the box the
four other rows already occupy — so the bays row's requested width is unchanged
(356 px content + 2×20 separation = 396 ≤ 404) and the cluster's
`custom_minimum_size` assertion (404×216) still holds. The pinned box was left
alone as instructed.

Live profile untouched: every gate/probe ran under `XDG_DATA_HOME=/tmp/d6m1b*`;
`~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg` mtime is
`2026-09-24 08:12:35`, before this dispatch (probes ran ~08:21). `git status`
shows only the two intended files modified; `project.godot`, `theme/`, `game/`,
`autoload/`, `addons/` and all frozen docs untouched.

## Files touched

- `vajb-orbit/ui/hud/cockpit_cluster.gd` — `SPD_MAX` 999 → 9999 (+ the one-line
  amendment comment); the SPD row's `_add_row(..., 4, false)`.
- `vajb-orbit/tests/test_d6_cluster.gd` — the SPD padding row and the SPD
  clamp/readouts-map rows only (+2 assertions).

## Follow-ups

None. UI_SPEC §3.7 already carries the 2026-09-24 amendment text; M1's open
frame-band/box finding (`D6-M1_report.md` follow-up 1) is a separate bucket-2
docs finding and is unaffected by this change.
