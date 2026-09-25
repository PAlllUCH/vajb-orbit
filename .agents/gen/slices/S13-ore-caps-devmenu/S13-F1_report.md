---
slice: S13
worker: S13-F1
model: "deepseek-flash"
status: informational
gate: "834/0 → 834/0"
---

# S13-F1 report

## Result
The two F1-owned MEDs are fixed at their named lines and nothing else moved: the
field's `_ore_credit` is cleared with the rocks at every cycle start
(`asteroid_field.gd:158,182`), and the devmenu suite runs entirely inside the
runner's `user://_gate_scratch` dir, never the pinned `user://dev_tuning.cfg`
(`test_s13_devmenu.gd:20-24,53,63,207-232,352`). The AC2 row in `test_s13_caps.gd`
now proves the cycle boundary in-gate. Gate **834/0** twice on fresh scratch stores;
a pinned-path sentinel survived gate 1 byte-identical.

## Findings — disposition

| ID | Tier | Disposition |
|---|---|---|
| S13-B1/F1 | MED | **Fixed.** `game/asteroid_field.gd:158` (in `setup()`, right after `_clear_rocks()`) and `:182` (same place in `respawn()`); the `_ore_credit` doc at `:122-126` now states the per-cycle scope. Those two sites are the only paths that free the rocks, so one cycle's leftover credit can no longer pay against the next cycle's roll. Regression proof added in-gate: `test_s13_caps.gd:206-213` respawns the fully consumed AC2 family and asserts the credit is 0 — with the two lines removed the row fails at **1.000 leftover** (mutation run below), so the new assertion is not vacuous. No row count changed and no measured figure moved. |
| S13-B2/F2 | MED | **Fixed.** `tests/test_s13_devmenu.gd`: the pinned path is now `PINNED_CONFIG_PATH` (`:20`) and the suite's own file is `user://_gate_scratch/dev_tuning.cfg` (`:24`); every mounted overlay gets `config_path` pointed at it (`:63`, `:219`) and the dir is created by the suite (`:352`, `ERR_ALREADY_EXISTS` tolerated because the runner seeds the same dir). `suite_setup` records whether the pinned file existed (`:53`) and the AC4 guard proves the run neither created nor deleted it (`:212`, `:231`); the pinned default is asserted separately, and a fresh overlay's `config_path` default is asserted to be the pinned one (`:207,216`). Row count unchanged: 8. |
| S13-B2/F1 | MED | **Left, not F1 (bucket 2).** Re-verified unreachable: `rg dev_tuning` outside `ui/dev/` and its suite reaches only `ore_tuning.gd`'s comments, so nothing mounts the overlay. The fix is a mount point in a shipped scene/autoload — outside B2's and F1's `VAJB_WORKER_FILES` (and `project.godot` is forbidden), i.e. a pin change. Escalated as the review scoped it: developer / next wave. |
| S13-B1/F2, B1/F3, B1/F4, B2/F3 | LOW | Untouched by instruction, as R1 left them (`L198`–`L201`). |

## Deviations from SLICE.md
None. No pinned number, doc, row count or forbidden file changed; no `OreTuning`
default moved. One assertion was added inside an existing listed row (F1's own fix
changes what the cycle boundary proves); the row's verdict and figures are unchanged.

## Evidence

```bash
# gate 1 — fresh store, seeded with a divergent file at the PINNED path
mkdir -p "/tmp/s13_f1_final1/godot/app_userdata/Vajb Orbit" && printf '[ore_tuning]\nvalues={}\n' \
  > "/tmp/s13_f1_final1/godot/app_userdata/Vajb Orbit/dev_tuning.cfg"
md5sum ".../dev_tuning.cfg"   # cf8fea2e019daf9006f7015f3de53bbd  (before)
XDG_DATA_HOME=/tmp/s13_f1_final1 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
# [SUMMARY] passed=834 failed=0   (exit 0)
md5sum ".../dev_tuning.cfg"   # cf8fea2e019daf9006f7015f3de53bbd  (after — unchanged, F2's proof)

# gate 2 — clean fresh store
XDG_DATA_HOME=/tmp/s13_f1_final2 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
# [SUMMARY] passed=834 failed=0   (exit 0)

# counterfactual for B1/F1: the two reset lines removed, caps suite only
XDG_DATA_HOME=/tmp/s13_f1_mut $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_s13_caps
# [FAIL] test_s13_caps.gd.test_a_fully_mined_family_realises_the_root_bore:
#   a respawn clears the cycle's leftover credit (1.000 before)
# [SUMMARY] passed=9 failed=1     (lines restored immediately after)
```

- Gate 1 log `/tmp/s13_f1_final1.log`: 834 `[PASS]` lines, no failure line,
  `test_s13_devmenu.gd` rows unchanged (8). Its store's `_gate_scratch/` holds only
  the runner's `profile.cfg` and `economy_log.txt`: the suite's own file was created
  and deleted there (so its delete path did run) while the pinned sentinel above
  stayed byte-identical — the direct F2 proof.
- Gate 2 log `/tmp/s13_f1_final2.log`: same summary, exit 0.
- Field-lifecycle probes re-run on a scratch store (`XDG_DATA_HOME=/tmp/s13_f1_probe`),
  all exit 0, so the two added lines moved no measured row:
  - `probe_s12_field_budget.gd` → `[S12K0] done failures=0`
  - `probe_s12_rock_rate.gd` → `[S12K1] done failures=0`
  - `probe_rock_cleave_a2.tscn --quit-after 600` → `[A2] done failures=0`
- `git diff --stat -- project.godot docs/gameplay/18_engine_spec.md` → empty.
- `find vajb-orbit docs -newermt '-25 minutes'` → only the three files below (plus
  R1's pre-existing `docs/CONTRACTS.md` / `tools/r1_s13_ac3_replay.gd` edits).
- `rg dev_tuning` outside `ui/dev/` → only `ore_tuning.gd`'s comments: B2/F1 stands.

## Files touched
- `vajb-orbit/game/asteroid_field.gd` — `_ore_credit = 0.0` at both cycle starts; the
  credit's doc states its per-cycle scope.
- `vajb-orbit/tests/test_s13_devmenu.gd` — scratch config path + pinned-default and
  pinned-untouched assertions; 8 rows, unchanged.
- `vajb-orbit/tests/test_s13_caps.gd` — one added assertion inside the AC2 row
  (respawn clears the leftover credit); 10 rows, unchanged.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Mount the F1 overlay in a shipped scene/autoload (near-invisible in game today) | feature | S13-B2/F1, bucket 2 — developer/next wave |
| R1's proposed `18_engine_spec.md` §6/§13 wording | docs | owner-locked, per R1's review |
