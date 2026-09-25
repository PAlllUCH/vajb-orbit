# D8-H4 report — hide the top-left hull/shield (wave D8 item 10)

**Files:** `ui/hud/hud.gd`, `tests/test_d8_hud_visibility.gd` | **Gate:** `[SUMMARY] passed=858 failed=0`

Owner 2026-09-25, verbatim: "hide shield and hull in top left corner." The cockpit
cluster already owns SPD/HULL/SHLD/AMMO and FUEL/ENRG, so the HUD may not repeat
them.

- `HullBlock`/`ShieldBlock` are back on `retired_widgets()` (`hud.gd:1409`) and hidden
  by `_retire_old_column` at runtime; they stay in the scene, still fed by the
  `PlayerState` signals but invisible, so no state path is lost.
- `EnergyBlock`/`FuelBlock` were already hidden by `_retire_pool_blocks()`
  (`hud.gd:1284`, section 3.1b) and stay hidden, so they do **not** render the
  cluster's FUEL/ENRG data top-left.
- `CreditsBlock` is untouched (not a cluster readout; pinned by CONTRACTS 23.3),
  so the quadrant is empty of cockpit state. `hud.tscn` untouched.

Row 1 was rewritten to `test_the_top_left_state_blocks_are_not_visible_at_runtime`
(HullBlock/ShieldBlock/EnergyBlock/FuelBlock `not is_visible_in_tree()`, crest rows
on `retired_widgets()`); rows 2-6 unchanged. This also clears H1's bucket-2 finding:
`test_d7_cockpit.gd:393` expects `retired_widgets().size() == 5` and is green again.

Gate (own XDG_DATA_HOME scratch store, bounded):

`XDG_DATA_HOME=<scratch> $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200` -> `[SUMMARY] passed=858 failed=0`
