# W1 report — D3 slot-plate guard (UI-chrome wave)

Worker: **W1**, coder, defect **D3** only. Declared file set:
`vajb-orbit/ui/components/`, `vajb-orbit/ui/station/shipyard_panel.gd`,
`vajb-orbit/ui/station/launch_panel.gd`, `vajb-orbit/ui/hud/hud.gd`, `vajb-orbit/tests/`.
Host: Linux (`~/VajbOrbit`), Godot 4.7.2-stable at `~/.local/bin/godot`, 2026-09-21.

## Verdict

The layout no longer depends on the art. `ignore_texture_size = true` is set at **every plate
site** — the component scene, `configure()`, both station panels' `_make_plate()` and both HUD
builders — with the documented 48 px weapon and 40 px cargo cells untouched. **Six one-line
insertions across five files**, plus one new headless suite (7 tests). Gate re-run:
`[SUMMARY] passed=226 failed=0`, exit 0.

**Measured, with the 880×876 / 873×864 art still on disk:**

| reading | before | after |
|---|---|---|
| shipyard hardpoint strip (7 cells) | **6184 × 876** | **360 × 48** |
| shipyard stats column (the strip's own column) | **6184 × 1224** | **360 × 396** |
| shipyard panel root minimum | **7084 × 1740** | **1260 × 1740** |
| launch cargo strip (5 cells) | **4389 × 864** | **224 × 40** |
| launch panel root minimum | **4781 × 2809** | **952 × 1985** |
| LaunchButton minimum | 71 × 88 | 71 × 88 (unchanged) |
| shipyard panel root minimum with 4096² plate art | 29596 × 4497 | 1260 × 1740 (unchanged) |
| launch panel root minimum with 4096² plate art | 20896 × 6041 | 952 × 1985 (unchanged) |
| slot component cell, weapon art 880 × 876 | 880 × 876 | 48 × 48 |
| slot component cell, cargo art 873 × 864 | 873 × 864 | 40 × 40 |
| HUD weapon cells (5) | 880 × 876 each | 48 × 48 each |
| HUD cargo cells (40) | 873 × 864 each | 40 × 40 each |

Viewport read from `project.godot` (`display/window/size/viewport_width/height`): **1920 × 1080**.
Both panels now demand 1260 and 952 px of width, so the ship list and the LAUNCH button can no
longer be pushed off the frame.

## The edits (line numbers after the edit)

| file | line | change |
|---|---|---|
| `vajb-orbit/ui/components/slot_button.tscn` | 7 | `ignore_texture_size = true` on the `TextureButton` root (keeps `custom_minimum_size = Vector2(48, 48)`) |
| `vajb-orbit/ui/components/slot_button.gd` | 61 | `ignore_texture_size = true` at the top of `configure()`, ahead of the existing `custom_minimum_size` line |
| `vajb-orbit/ui/station/shipyard_panel.gd` | 328 | `plate.ignore_texture_size = true` in `_make_plate()` (Hardpoint01–07) |
| `vajb-orbit/ui/station/launch_panel.gd` | 253 | `plate.ignore_texture_size = true` in `_make_plate()` (CargoSlot01–05) |
| `vajb-orbit/ui/hud/hud.gd` | 608 | `slot.ignore_texture_size = true` in `_build_weapon_slots()` |
| `vajb-orbit/ui/hud/hud.gd` | 701 | `cell.ignore_texture_size = true` in `_ensure_cargo_cells()` |

No other line in those five files changed. `configure()` still sets `custom_minimum_size` to
`CELL_SIZE_WEAPON` (48) or `CELL_SIZE_CARGO` (40) exactly as before, so a caller's own
`custom_minimum_size` behaviour is preserved — the guard adds an upper bound on the *texture's*
contribution, nothing else. Nothing else was touched: no asset, no theme, no
`tools/build_theme.gd`, no `project.godot`, no addon, no doc.

## The new suite — `vajb-orbit/tests/test_ui_slot_layout.gd` (suite `ui_slot_layout`, 7 tests)

1. `test_every_plate_site_sets_ignore_texture_size` — reads the five shipped files and asserts
   each carries the literal `ignore_texture_size = true`, so a future edit cannot drop the
   guard at one site and leave the others green.
2. `test_the_slot_component_keeps_its_cell_whatever_the_plate_art_is` — instantiates the
   component with the live theme, asserts the scene default, then `configure(weapon)` → 48 and
   `configure(cargo)` → 40 measured through `get_combined_minimum_size()`, with the theme plate
   art attached (so the 48 is not a vacuous pass).
3. `test_the_hardpoint_strip_is_seven_48px_cells` — 7 plates, each `ignore_texture_size`,
   `custom_minimum_size` 48, combined minimum 48; strip = 7 × 48 + 6 × 4 = 360; **shipyard panel
   minimum ≤ the 1920 viewport**.
4. `test_oversized_plate_art_cannot_grow_the_shipyard_panel` — swaps every plate's four state
   textures for a 4096 × 4096 `PlaceholderTexture2D`, re-measures: strip still 360, panel
   minimum byte-identical to the pre-swap reading.
5. `test_the_cargo_strip_is_five_40px_cells` — 5 plates, each 40; strip = 5 × 40 + 4 × 6 = 224;
   **launch panel minimum ≤ 1920**, and the LAUNCH button's own minimum inside the frame.
6. `test_oversized_plate_art_cannot_grow_the_launch_panel` — the same 4096² proof for LAUNCH.
7. `test_the_hud_slot_cells_keep_their_cell_sizes` — the shipped `hud.tscn` with the live theme:
   5 weapon cells at 48 and, after `_ensure_cargo_cells(40)`, 40 cargo cells at 40, every one of
   them `ignore_texture_size` and measuring its cell while carrying the oversized plate.

**How the panel size is measured (not by eye).** The tests instantiate the shipped scene under
a themed 1920 × 1080 host and read `get_combined_minimum_size()` off the panel root — the exact
quantity the station shell sizes a panel from, and the one the playtest overflowed. The suite
deliberately **awaits nothing**: the headless runner calls each `test_*` synchronously and reads
its verdict immediately, so a coroutine would report PASS before its assertions ran (that is why
the oversized-art proof uses a runtime 4096² texture plus `update_minimum_size()` instead of a
laid-out frame). The same probe shape was validated in both directions — see the pre-fix run
below, where all 7 tests fail with the oversized numbers printed.

## Reconciliation with the playtest's figures (`playtest_fullloop_20260921.md` D1/D3)

- **6184** = the hardpoint strip exactly: 7 × 880 + 6 × 4 = 6184. Measured, matches to the pixel.
- **4781** = the LAUNCH panel root exactly: the 4389 px cargo strip (5 × 873 + 4 × 6) sets the
  brief column, + 16 separation + 360 deck-control column + the 16 px expand spacer = 4781.
  Measured, matches to the pixel.
- **x = −2393** for the ship list: (2298 − 7084) / 2 = −2393, i.e. the station host centring a
  panel whose minimum is **7084** in 2298 px of room. That the arithmetic closes on 7084 rather
  than 6184 is why this report carries 7084 as the shipyard panel root minimum and 6184 as the
  strip.
- The playtest's "6184 × 1224" pair is **the shipyard stats column**, not the panel root:
  measured with the guard off, that column reports exactly `6184 × 1224` (guard on: `360 × 396`),
  while the panel root reports `7084 × 1740` in both states. The defect and its cure are the same
  either way, and the suite asserts on the strip, the panel root and every cell.
- Both numbers are now 360 / 224 at the strip and 1260 / 952 at the panel root — inside 1920.

## Gate

```text
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=226 failed=0        (exit 0)
```

Before this wave the same command measured `passed=219 failed=0` (W4 re-measured it this session
and archived that log at `.agents/gen/ui_chrome_w4_gate.log`); 219 + this suite's 7 = 226, so the
count grew and nothing was lost. No `SCRIPT ERROR`, no RID-leak line. The only WARNING is
`test_p1_clock_log.gd`'s own deliberate unwritable-path probe.

The scoped run used while developing the guard, both directions:

```text
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_ui_slot_layout
  before the fix:  [SUMMARY] passed=0 failed=7      (every failure prints the measured size)
  after the fix:   [SUMMARY] passed=7 failed=0      (exit 0)
```

Evidence logs, both kept raw:

- `.agents/gen/ui_chrome_w1_suite_before.log` — 7/7 fail with 6184 / 7084 / 4389 / 4781 printed.
- `.agents/gen/ui_chrome_w1_suite_after.log` — 7/7 pass with 360 / 1260 / 224 / 952 printed.
- `.agents/gen/ui_chrome_w1_gate.log` — the full-gate 226, taken after the throwaway probes
  were removed (the tree at that moment holds only the shipped suite).
- `.agents/gen/ui_chrome_w1_prefix_probe.log` — a throwaway suite (since deleted) that measured
  the panels in **both** states in one run by putting the guard back off at the real art sizes,
  so the before column of the table above is a reading of the shipped scenes and not arithmetic:
  strip `360 × 48` → `6184 × 876`, stats column `360 × 396` → `6184 × 1224`, shipyard panel root
  `1260 × 1740` → `7084 × 1740` (height unchanged — the preview column dominates it), launch strip
  `224 × 40` → `4389 × 864`, launch panel root `952 × 1985` → `4781 × 2809`.
- `.agents/gen/ui_chrome_w1_cell_probe.log` — a throwaway `--script` probe (since deleted) that
  measured the component cell with the guard switched off and on in one run, so the per-cell
  before/after is a measurement and not an inference: weapon art 880 × 876 → 880 × 876 / 48 × 48,
  cargo art 873 × 864 → 873 × 864 / 40 × 40. Two notes for whoever re-runs it: the reading has to
  happen in `_process`, because in `_initialize` the root window is not yet in the tree,
  `update_minimum_size()` early-returns and every reading is the first cached minimum; and a
  `--script` run loads **no autoloads**, so it cannot even load the two panel scripts
  (`Identifier not found: AudioManager`) — any probe of project UI has to go through the runner,
  which is why the two-state panel probe above is written as a throwaway suite rather than a
  script.

## Observed in my own files but outside D3 (not changed)

**The panels' *vertical* minimum is still driven by art aspect.** Shipyard panel root minimum is
`1260 × 1740` and launch `952 × 1985` — both taller than the 1080 window. D3 did not create this
and did not leave it worse (the fix took the launch height from 2809 to 1985 and left the shipyard
height at 1740); the driver is the preview image, whose `custom_minimum_size` is set from the hull
render's native size (`shipyard_panel.gd:416-426` `_update_preview_size()`, `launch_panel.gd`
`_update_preview_size()`), so a differently-proportioned hull render moves it. That is the same
class of coupling D3 just removed on the horizontal axis, but on a different site (the
`TextureRect` preview, not a slot plate) and outside this defect's evidence — recorded for the
waveboard / a future slice, not fixed here.

## Findings outside my file set (not edited, for W5 / the waveboard)

1. **LOW — the deleted-in-progress mockup still has the defect.** `ui/screens/_mockup_station.gd`
   builds its hardpoint and cargo plates through its own `_make_slot_plate()` (lines 644, 658,
   693) with `custom_minimum_size` only and no `ignore_texture_size`. It is outside W1's set and
   `AGENTS.md` already schedules `_mockup_station.tscn` for deletion at its close-out, so it is
   recorded rather than fixed. If the mockup survives the close-out, it needs the same line.
2. **LOW — `assets/ui/ui_slot_inventory_*.png` (882 × 870) has no consumer.** No `.gd`, `.tscn`
   or `.tres` in the project references the inventory plate family (the theme's slot items are
   cargo + weapon only), so the D1 re-cut of that family is art with no site to protect. Flagged
   for the graphics lane, not a code defect.

## Environment note (host-level, same one W4 hit)

`file_path` has to be **workspace-relative** in this session:
`.crush/hooks/enforce_worker_files.py` normalizes only the Windows workspace root, so on Linux an
absolute `/home/...` path normalizes to itself and is denied even when it is inside the declared
set. My first write was denied on the absolute path and landed unchanged as
`vajb-orbit/tests/test_ui_slot_layout.gd`. Same hook, same one-line cure (add the Linux root to
`_norm`); worth folding into the same pass as the `--tests` host-aware patch the close-out notes.

## Files written

Shipped code (the D3 guard, one line each):

- `vajb-orbit/ui/components/slot_button.tscn` (guard, line 7)
- `vajb-orbit/ui/components/slot_button.gd` (guard, line 61)
- `vajb-orbit/ui/station/shipyard_panel.gd` (guard, line 328)
- `vajb-orbit/ui/station/launch_panel.gd` (guard, line 253)
- `vajb-orbit/ui/hud/hud.gd` (guard, lines 608 and 701)
- `vajb-orbit/tests/test_ui_slot_layout.gd` (new suite, 7 tests) + the engine's own `.gd.uid`
  sidecar for it

Evidence (all under `.agents/gen/`):

- `ui_chrome_w1_report.md` (this report)
- `ui_chrome_w1_suite_before.log` — the scoped suite, 7/7 fail
- `ui_chrome_w1_suite_after.log` — the scoped suite, 7/7 pass
- `ui_chrome_w1_gate.log` — the full gate, `passed=226 failed=0`
- `ui_chrome_w1_prefix_probe.log` — the two-state panel seam probe
- `ui_chrome_w1_cell_probe.log` — the per-cell guard on/off probe

Three throwaway probe files were created under `vajb-orbit/tests/` and deleted again
(`_w1_cell_probe.gd`, `_w1_prefix_probe.gd`, `test_w1_prefix_probe.gd`); `git status` over
`vajb-orbit/tests/` shows `test_ui_slot_layout.gd` as my only new file.
