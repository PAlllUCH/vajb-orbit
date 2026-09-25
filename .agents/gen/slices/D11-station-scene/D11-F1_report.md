---
slice: D11
worker: D11-F1 (fixer)
status: complete
gate: "812/0 twice on fresh scratch stores (identical counts; S8's rows inside the 812 attributed, never fixed); live profile.cfg md5 f8a95c7c8985f5ce09b823df3f82b8d2 byte-identical before/after"
---

# D11-F1 report — HIGH/MED fixes only

Scope honoured: HIGH **none**; MED-1 fixed by local value grade; MED-2 **not F1's
file set** (routed on, bucket 2); LOW L184–L190 untouched; no refactors, no S8
files, no pinned literal or invariant touched; no re-render (layout pins kept).

## MED-1 — environment brighter than ships (§1.1/§1.3 inversion) → **FIXED**

Finding named `vajb-orbit/assets/env/poi/env_station_*.png` (15 files). Fix: a
local value grade, no re-render, RGB only — `staging/phase_g/grade_d11_values.py`
(`uv run --with numpy --with scipy --with pillow python … --apply`). Per file it
rescales every non-ember pixel so the mean max-channel/255 over opaque pixels
(alpha > 0) lands at **0.160**; ember-hot pixels (`r>170 & r-b>80`, A1/R1's own
hot definition) are left byte-identical so §6's one-emissive row, the QC hot
numbers and the ember hue window survive untouched. Originals + md5 manifest
copied first to `staging/phase_g/_d11_pregrade/` (reversal: copy back, then
`--update-rows`).

Measured (same method for before/after/anchors; R1's tool cross-check below):

| file | mean before → after | median before → after | k | hot px |
|---|---|---|---|---|
| env_station_hero | 0.2132 → 0.1598 | 0.1922 → 0.1451 | 0.749 | 2807 = |
| env_station_arm_a | 0.2771 → 0.1600 | 0.2510 → 0.1451 | 0.577 | 80 = |
| env_station_arm_b | 0.2732 → 0.1600 | 0.2471 → 0.1451 | 0.586 | 37 = |
| env_station_mast_a | 0.2424 → 0.1600 | 0.2157 → 0.1412 | 0.660 | 0 = |
| env_station_mast_b | 0.2647 → 0.1600 | 0.2235 → 0.1333 | 0.605 | 0 = |
| env_station_gantry_a | 0.2458 → 0.1600 | 0.2235 → 0.1451 | 0.651 | 0 = |
| env_station_gantry_b | 0.2417 → 0.1599 | 0.2118 → 0.1412 | 0.662 | 0 = |
| env_station_windows_a | 0.2314 → 0.1600 | 0.2157 → 0.1490 | 0.691 | 0 = |
| env_station_windows_b | 0.2150 → 0.1600 | 0.1922 → 0.1412 | 0.744 | 0 = |
| env_station_plate_a | 0.2395 → 0.1597 | 0.2118 → 0.1412 | 0.668 | 0 = |
| env_station_plate_b | 0.2327 → 0.1599 | 0.2196 → 0.1490 | 0.687 | 11 = |
| env_station_lamp_a | 0.2273 → 0.1600 | 0.1882 → 0.1294 | 0.691 | 6173 = |
| env_station_lamp_b | 0.2466 → 0.1600 | 0.2196 → 0.1412 | 0.646 | 1951 = |
| env_station_shuttle_a | 0.2401 → 0.1601 | 0.2157 → 0.1451 | 0.666 | 0 = |
| env_station_shuttle_b | 0.2449 → 0.1600 | 0.2157 → 0.1412 | 0.653 | 9 = |

Anchors, same script: old `env_station.png` **0.1645 / 0.1333**, player hull
`ship_vanguard_side` **0.1786 / 0.1804** — the whole family now sits below both
(the pre-grade family sat at 0.215–0.277, above both). Cross-mask check: worst
family mean is 0.1601 (alpha>0), 0.1657 (alpha>8), 0.2069 (alpha==255) — under
every mask below the vanguard's 0.1786 / 0.1786 / 0.2400 respectively, so the
"ship silhouettes always dominate" relationship holds regardless of mask choice.

Pins kept (re-measured, not trusted):
- Alpha bytes and canvas size byte-identical to ` _d11_pregrade/` for all 15;
  hero `alpha_bbox=(54,72,1993,1975)` unchanged → frame half **149.40 u =
  2.2003 × 67.9**, content half **141.45 u = 2.36 ×**, exactly R1's AC2 numbers
  (`r1_d11_pixels.py` re-run post-grade).
- Hot/accent/transparency: R1's probe reproduces cell-for-cell — hero hot
  0.00197, lamps 0.01060/0.00190, all other rows ≤ 0.00013 < 0.0005, accent ≤
  0.00065 < 0.001, transp 51.9–75.7 % > 10 %, ember-of-hot 86–100 %, mean hot
  hue 20–34° → §6 one-emissive and §9 negative list still pass.
- Fresh `wave_d11.final_checks` on every shipped file: **15 GREEN, 0 fail**
  (`wave_d11.py qc` → "15 files, 15 green, 0 fail"). Nine stored `accent_share`
  rows only *dropped* (darkening can clear the `mx>45` visibility line), all
  refreshed by the script's `--update-rows`; `transparent`, `hot_share`,
  `ink_px`, `hot_px` match the stored rows exactly.
- `.import` sidecars byte-identical (aggregate md5 `ae8e65608de793ee7707f104f9217d3e`);
  headless reimport ran (15 steps, editor closed) so the game draws the graded
  pixels.
- Generation log: dated grade entry with the reversal appended to
  `vajb-orbit/assets/env/generation_log_d11.md`.

## MED-2 — §11's ASSET_NAMING rows did not land → **NOT F1's file set (no action)**

The finding itself routes it: escalation bucket 2, "the developer session adds
the amendment (or the owner amends §11) … Not F1's file set." Brief and
`SLICE.md` both forbid D11 workers `docs/` writes beyond §11's ticks and R1's
§9/§10. Disposition: **routed to the developer session, unchanged by F1.**

## Tests

Adjusted: **none.** Pre-grep of `vajb-orbit/tests/` for colour/value/pixel pins
in the wave's rows: `test_d11_station.gd` pins only `STATION_SCALE`, the
approved hero scale, group/DockZone invariants, motion constants and two-frame
motion — the fix changes pixel values only, so nothing the tests prove changed;
all five d11 rows ran green in both gate runs.

## Gate — twice, fresh scratch stores, S8 attributed

```
run 1: XDG_DATA_HOME=$(mktemp -d) godot --headless --path vajb-orbit \
         res://tests/headless_runner.tscn --quit-after 1200
       [SUMMARY] passed=812 failed=0
run 2: (second fresh mktemp -d store, same command)
       [SUMMARY] passed=812 failed=0
```

- Counts identical; the worktree's `func test_` total is **812**, so every row
  ran, including `test_d11_station`'s 5. The 812 carries S8's and S10/S11's
  closed-lane rows — **attributed to those lanes, never fixed here** (R1's
  attribution stands; no S8 file was touched: `git status` shows only D11's own
  staging/assets additions).
- Live store untouched: `profile.cfg` md5 `f8a95c7c8985f5ce09b823df3f82b8d2`
  before and after both runs (matches R1's recorded value).

## Files touched by F1

`staging/phase_g/grade_d11_values.py` (new), `staging/phase_g/_d11_pregrade/`
(new, 15 originals + `manifest.json`), the 15 `vajb-orbit/assets/env/poi/
env_station_*.png` (RGB grade), `staging/phase_g/env/d11/qc_results.json`
(accent rows refreshed), `vajb-orbit/assets/env/generation_log_d11.md`
(append), this report. Nothing else — no `game/`, no `tests/`, no `docs/`.
