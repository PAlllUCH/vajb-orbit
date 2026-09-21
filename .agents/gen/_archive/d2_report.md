# D2 report: PlayerProfile autoload + station catalogue

Worker: coder (D2, foundation A). Date: 2026-09-18.
Brief: `.agents/gen/d2_task.md`. Everything below is a measurement from this session, not an assertion.

## 1. Files created / edited

| Action | Path | Lines |
|---|---|---|
| created | `vajb-orbit/autoload/player_profile.gd` | 377 |
| created | `vajb-orbit/game/station_catalog.gd` | 201 |
| edited (one key) | `vajb-orbit/ui/paths.gd` | 41 (was 40) |
| created | `docs/design/STATION_SPEC.md` | 315 |
| created | `.agents/gen/d2_report.md` | this file |

`ui/paths.gd` change, exactly one line added inside `AUDIO_DIRS`:

```gdscript
	&"ambience": "res://assets/audio/ambience/",
```

No other file was touched. `project.godot`, `addons/`, `autoload/audio_manager.gd`, `autoload/router.gd`, `tools/build_theme.gd`, `tools/derive_icon_tints.gd`, `ui/theme/vajb_theme.tres`, `ui/screens/*`, `ui/hud/*` and `game/game.gd` were not modified.

### 1.1 Explicit scope statements

- I did **not** register the `PlayerProfile` autoload. `project.godot` still lists only
  `_mcp_game_helper`, `SettingsManager`, `AudioManager`, `Router`, `DialogManager` under `[autoload]`.
- I did **not** add a station route. `UIPaths.ROUTES` is unchanged; the only `paths.gd` edit is the `ambience` audio directory key.

## 2. Documents first

`docs/design/STATION_SPEC.md` was written before either script and covers: the profile/state split, the full public API and semantics, the save file (`user://profile.cfg`, `ConfigFile`, `[profile]`, `save_version` 1, missing / corrupt / unknown-version behaviour), the catalogue entry shapes, the stub price tables, and the station screen consumer contract (signals listened to, methods called, never writes the ConfigFile).

## 3. One design correction the probe caught

The first probe run failed 11 assertions and showed exactly why: `buy_ammo` takes a **weapon** id, but I had given the ammo packs ids like `pack_laser`. The brief is explicit that the ammo pack `id` "must be one of the five `PlayerState.WEAPONS`", so the packs are now keyed `&"laser"`, `&"cannon"`, `&"rocket"`, `&"mine"`, `&"plasma"`, in `PlayerState.WEAPONS` order, and `STATION_SPEC.md` section 5 and 5.1 were corrected to match. Before the fix: `bought ammo=false`, `spent = 12800 expected = 12920`, 6 refusal reasons with a leading `unknown_id`. After the fix all of those pass.

Two smaller fixes made after the first green run, both re-verified:

- `add_credits` now returns early when the clamped result equals the current balance, so a no-op penalty no longer emits `profile_changed` (the spec says a mutation that changes nothing emits nothing).
- The spec's H1 contained one em dash; it is now a hyphen. `player_profile.gd`, `station_catalog.gd` and `STATION_SPEC.md` contain no em dash (checked by codepoint 8212 scan).

## 4. Verification

### 4.1 Probe

Throwaway probe at `res://tools/_probe.gd` (`extends SceneTree`, `quit()` in `_finish()`), deleted with `rm -f` afterwards. It covers all seven required steps: instantiate and add to `root`, print defaults, purchase and credit-delta assertions, save and read back with a fresh `ConfigFile`, reset and save and compare against the documented defaults, catalogue path and id assertions, quit.

Command (run three times in total, twice after the catalogue fix and once after the `add_credits` fix):

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe.gd
```

Exit code of the final run: `PROBE_EXIT=0`. First run exited 1 (the 11 failures listed above). Exact final output:

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

== D2 probe: PlayerProfile ==
  PASS  player_profile.gd loads as a script
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
-- documented defaults --
credits       = 10000
owned_ships   = [&"ship_vanguard"]
active_ship   = ship_vanguard
ammo laser = 300 / max 300
ammo cannon = 300 / max 300
ammo rocket = 300 / max 100
ammo mine = 300 / max 100
ammo plasma = 300 / max 100
cargo items   = {  } size 0
upgrade count = 0
  PASS  default credits
  PASS  default owned ships
  PASS  default active ship
  PASS  default ammo for laser
  PASS  default ammo for cannon
  PASS  default ammo for rocket
  PASS  default ammo for mine
  PASS  default ammo for plasma
  PASS  laser ammo max 300
  PASS  cannon ammo max 300
  PASS  ammo max 100 for rocket
  PASS  ammo max 100 for mine
  PASS  ammo max 100 for plasma
  PASS  default cargo empty
  PASS  default upgrades empty
-- purchases --
bought ship=true ammo=true upgrade=true
spent = 12920 expected = 12920
  PASS  all three purchases succeeded
  PASS  credits decreased by exactly the sum of the costs
  PASS  owned ships grew by one
  PASS  installed upgrades grew by one
  PASS  laser ammo grew by the pack
  PASS  cargo holds 12 ore
  PASS  cargo holds one item kind
  PASS  the bought ship can become active
  PASS  active ship is the bought ship
-- refusals --
  PASS  re-buying an owned ship fails
  PASS  activating an unowned ship fails
  PASS  an unknown ammo id fails
  PASS  re-installing an upgrade fails
  PASS  spend drains the balance to zero
  PASS  spend beyond the balance fails
  PASS  buying without credits fails
refusal reasons = [&"already_owned", &"already_owned", &"unknown_id", &"already_owned", &"insufficient_credits"]
  PASS  refusal reasons and order
  PASS  profile_changed fired for credits
  PASS  profile_changed fired for ammo
  PASS  profile_changed fired for ships
  PASS  profile_changed fired for upgrades
  PASS  profile_changed fired for cargo
-- save and read back --
  PASS  user://profile.cfg loads with a fresh ConfigFile
save_version = 1
credits      = 0
owned_ships  = ["ship_vanguard", "ship_fighter"]
active_ship  = ship_fighter
upgrades     = ["upgrade_engine"]
cargo        = { "ore": 12 }
ammo         = { "cannon": 300, "laser": 600, "mine": 300, "plasma": 300, "rocket": 300 }
  PASS  save_version is 1
  PASS  stored credits match memory
  PASS  stored active ship matches memory
  PASS  stored ship list matches memory
  PASS  stored upgrade list matches memory
  PASS  stored cargo matches memory
  PASS  stored ammo matches memory
-- reset to defaults --
  PASS  reset restores credits
  PASS  reset restores the owned ships
  PASS  reset restores the active ship
  PASS  reset clears upgrades
  PASS  reset clears cargo
  PASS  the file reloads after the reset
  PASS  file credits are the default
  PASS  file ship list is the default
  PASS  file active ship is the default
  PASS  file upgrade list is empty
  PASS  file cargo is empty
default file ammo = { "cannon": 300, "laser": 300, "mine": 300, "plasma": 300, "rocket": 300 }
  PASS  file ammo is 300 for laser
  PASS  file ammo is 300 for cannon
  PASS  file ammo is 300 for rocket
  PASS  file ammo is 300 for mine
  PASS  file ammo is 300 for plasma
-- station catalogue --
  PASS  station_catalog.gd loads as a script
  PASS  station_catalog.gd instantiates as a RefCounted
  PASS  the instance exposes the ship id list
  PASS  catalogue holds 5 ammo packs
  PASS  catalogue holds 4 ships
  PASS  catalogue holds 6 upgrades
  PASS  ship ids are unique
  PASS  upgrade ids are unique
  PASS  ammo pack ids are unique
  PASS  the profile default ship is in the catalogue
  PASS  ammo ids equal PlayerState.WEAPONS
  PASS  an ammo pack has an id
  PASS  ammo id in PlayerState.WEAPONS: laser
  PASS  rounds > 0 for laser
  PASS  cost > 0 for laser
  PASS  name for laser
  PASS  description for laser
  PASS  icon resolves for laser: res://assets/icons/icon_ammo_laser_48.png
  PASS  an ammo pack has an id
  PASS  ammo id in PlayerState.WEAPONS: cannon
  PASS  rounds > 0 for cannon
  PASS  cost > 0 for cannon
  PASS  name for cannon
  PASS  description for cannon
  PASS  icon resolves for cannon: res://assets/icons/icon_weapon_cannon_48.png
  PASS  an ammo pack has an id
  PASS  ammo id in PlayerState.WEAPONS: rocket
  PASS  rounds > 0 for rocket
  PASS  cost > 0 for rocket
  PASS  name for rocket
  PASS  description for rocket
  PASS  icon resolves for rocket: res://assets/icons/icon_ammo_rocket_48.png
  PASS  an ammo pack has an id
  PASS  ammo id in PlayerState.WEAPONS: mine
  PASS  rounds > 0 for mine
  PASS  cost > 0 for mine
  PASS  name for mine
  PASS  description for mine
  PASS  icon resolves for mine: res://assets/icons/icon_weapon_mine_48.png
  PASS  an ammo pack has an id
  PASS  ammo id in PlayerState.WEAPONS: plasma
  PASS  rounds > 0 for plasma
  PASS  cost > 0 for plasma
  PASS  name for plasma
  PASS  description for plasma
  PASS  icon resolves for plasma: res://assets/icons/icon_weapon_plasma_48.png
  PASS  a ship has an id
  PASS  ship id resolves through ship(): ship_fighter
  PASS  cost > 0 for ship_fighter
  PASS  hull > 0 for ship_fighter
  PASS  shield > 0 for ship_fighter
  PASS  cargo > 0 for ship_fighter
  PASS  hardpoints > 0 for ship_fighter
  PASS  description for ship_fighter
  PASS  preview resolves for ship_fighter: res://assets/ships/ship_fighter_side.png
  PASS  a ship has an id
  PASS  ship id resolves through ship(): ship_vanguard
  PASS  cost > 0 for ship_vanguard
  PASS  hull > 0 for ship_vanguard
  PASS  shield > 0 for ship_vanguard
  PASS  cargo > 0 for ship_vanguard
  PASS  hardpoints > 0 for ship_vanguard
  PASS  description for ship_vanguard
  PASS  preview resolves for ship_vanguard: res://assets/ships/ship_vanguard_side.png
  PASS  a ship has an id
  PASS  ship id resolves through ship(): ship_gunship
  PASS  cost > 0 for ship_gunship
  PASS  hull > 0 for ship_gunship
  PASS  shield > 0 for ship_gunship
  PASS  cargo > 0 for ship_gunship
  PASS  hardpoints > 0 for ship_gunship
  PASS  description for ship_gunship
  PASS  preview resolves for ship_gunship: res://assets/ships/ship_gunship_side.png
  PASS  a ship has an id
  PASS  ship id resolves through ship(): ship_destroyer
  PASS  cost > 0 for ship_destroyer
  PASS  hull > 0 for ship_destroyer
  PASS  shield > 0 for ship_destroyer
  PASS  cargo > 0 for ship_destroyer
  PASS  hardpoints > 0 for ship_destroyer
  PASS  description for ship_destroyer
  PASS  preview resolves for ship_destroyer: res://assets/ships/ship_destroyer_side.png
  PASS  an upgrade has an id
  PASS  upgrade id resolves through upgrade(): upgrade_generator
  PASS  cost > 0 for upgrade_generator
  PASS  slot is documented for upgrade_generator: generator
  PASS  effect is non-empty for upgrade_generator
  PASS  effect delta is non-zero for upgrade_generator.shield_regen
  PASS  effect delta is non-zero for upgrade_generator.energy_regen
  PASS  description for upgrade_generator
  PASS  icon resolves for upgrade_generator: res://assets/icons/icon_equip_generator_48.png
  PASS  an upgrade has an id
  PASS  upgrade id resolves through upgrade(): upgrade_shield
  PASS  cost > 0 for upgrade_shield
  PASS  slot is documented for upgrade_shield: shield
  PASS  effect is non-empty for upgrade_shield
  PASS  effect delta is non-zero for upgrade_shield.shield_max
  PASS  description for upgrade_shield
  PASS  icon resolves for upgrade_shield: res://assets/icons/icon_equip_shield_gen_48.png
  PASS  an upgrade has an id
  PASS  upgrade id resolves through upgrade(): upgrade_engine
  PASS  cost > 0 for upgrade_engine
  PASS  slot is documented for upgrade_engine: engine
  PASS  effect is non-empty for upgrade_engine
  PASS  effect delta is non-zero for upgrade_engine.speed
  PASS  description for upgrade_engine
  PASS  icon resolves for upgrade_engine: res://assets/icons/icon_equip_engine_48.png
  PASS  an upgrade has an id
  PASS  upgrade id resolves through upgrade(): upgrade_module
  PASS  cost > 0 for upgrade_module
  PASS  slot is documented for upgrade_module: module
  PASS  effect is non-empty for upgrade_module
  PASS  effect delta is non-zero for upgrade_module.scanner_range
  PASS  description for upgrade_module
  PASS  icon resolves for upgrade_module: res://assets/icons/icon_equip_module_48.png
  PASS  an upgrade has an id
  PASS  upgrade id resolves through upgrade(): upgrade_extra
  PASS  cost > 0 for upgrade_extra
  PASS  slot is documented for upgrade_extra: extra
  PASS  effect is non-empty for upgrade_extra
  PASS  effect delta is non-zero for upgrade_extra.cargo_max
  PASS  description for upgrade_extra
  PASS  icon resolves for upgrade_extra: res://assets/icons/icon_equip_extra_48.png
  PASS  an upgrade has an id
  PASS  upgrade id resolves through upgrade(): upgrade_drone
  PASS  cost > 0 for upgrade_drone
  PASS  slot is documented for upgrade_drone: drone
  PASS  effect is non-empty for upgrade_drone
  PASS  effect delta is non-zero for upgrade_drone.hull_repair_rate
  PASS  description for upgrade_drone
  PASS  icon resolves for upgrade_drone: res://assets/icons/icon_equip_drone_48.png
price ladder: pack max 320 upgrade max 6800 ship min/max 9000/72000
  PASS  ammo is cheaper than every upgrade tier
  PASS  upgrades are cheaper than the cheapest ship
  PASS  the destroyer is the most expensive ship
  PASS  the vanguard is the mid tier
  PASS  the starter ship is cheaper than the mid tier
== D2 probe result: OK ==
```

Notes on the probe run:

- The `[godot_ai game_helper]` line comes from the project's `_mcp_game_helper` autoload (the editor's MCP plugin), not from my code; it appears in every headless run of this project, including the main menu check.
- The probe's step 3 costs were the catalogue's own numbers: ship `ship_fighter` 9000, pack `laser` 120, upgrade `upgrade_engine` 3800. Sum 12920, measured delta 12920.
- Step 4 stored state deliberately differs from the defaults (credits 0, two ships, one upgrade, 12 ore, 600 laser rounds) so the read-back comparison is not trivially true.
- The probe preloads `res://game/station_catalog.gd` and `res://game/player_state.gd` as script constants to read their constants, and separately `load()`s and instantiates the catalogue (the brief's step 6 wording). Both paths agree.
- `user://` resolved to `C:/Users/Kamil/AppData/Roaming/Godot/app_userdata/Vajb Orbit/`.

### 4.2 Existing screen still boots

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/main_menu.tscn --quit-after 300
```

Output, final run (exit code `MENU_EXIT=0`):

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
MENU_EXIT=0
```

No new errors and no warnings. This was run after the last code change (`add_credits`), on the final file state.

### 4.3 `user://profile.cfg` before and after

- Before the first probe run the file did **not** exist (listing of the user data directory showed only `logs`, `objectdb_snapshots`, `settings.cfg`, `shader_cache`, `vulkan`), so there was no pre-existing hash to record. `user://settings.cfg` was never read or written by my code or runs.
- Final content, written by the probe's documented `reset_to_defaults()` + `save()`:

```ini
[profile]

save_version=1
credits=10000
owned_ships=["ship_vanguard"]
active_ship="ship_vanguard"
upgrades=[]
cargo={}
ammo={
"cannon": 300,
"laser": 300,
"mine": 300,
"plasma": 300,
"rocket": 300
}
```

- SHA256 after the run: `15025e5299ac9736e9aad9b4d06565ea7a4d11caca6baea719d7c4b86d35a4ca`
  (`certutil -hashfile "C:/Users/Kamil/AppData/Roaming/Godot/app_userdata/Vajb Orbit/profile.cfg" SHA256`)
- The hash is identical after the final probe run and after the main menu run that followed, so the menu boot did not rewrite the file and nothing wrote it after the reset.

### 4.4 Final `tools/` listing

```
G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\tools\build_theme.gd
G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\tools\build_theme.gd.uid
G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\tools\derive_icon_tints.gd
G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\tools\derive_icon_tints.gd.uid
```

`_probe.gd` is gone, and no `_probe.gd.uid` was ever created (the open editor never scanned it; the headless `--script` runner does not mint `.uid` sidecars). The directory holds exactly the two original tool scripts plus their two sidecars.

## 5. Could not verify / carried risks

1. **`class_name PlayerProfile` on an autoload.** The brief requires `class_name PlayerProfile extends Node`, so that is what the file declares. Every existing autoload in this project (`settings_manager.gd`, `audio_manager.gd`, `router.gd`, `dialog_manager.gd`) declares **no** `class_name`, and Godot refuses an autoload whose name collides with a global class name. I could not test it because registering the autoload is the orchestrator's job and `project.godot` is off limits to me. If `autoload_manage(op="add", name="PlayerProfile", path="res://autoload/player_profile.gd")` is rejected or logs a conflict, the fix is to drop the `class_name` line (nothing in my scripts depends on the global, the probe instantiated the script directly and the catalogue is reached by `preload`). Please confirm at registration time.
2. **Editor-side parse/class registration.** I did not run `--headless --editor` (the brief forbids it while the editor is open), so I have no editor-side diagnostics and no LSP confirmation. My parse evidence is that both scripts were `load()`ed and executed by the probe. No `.uid` sidecars exist yet for `autoload/player_profile.gd` or `game/station_catalog.gd`; the orchestrator's `filesystem_manage(op="scan")` will mint them.
3. **No live-editor or in-game check.** The station screen does not exist, so the consumer contract in `STATION_SPEC.md` section 6 is documentation only, untested against a real consumer.
4. **`ammo_max` is advisory by design.** The documented default loadout (300 rounds per weapon) exceeds the 100 round capacity of rocket, mine and plasma, so purchases are not clamped to `ammo_max`. This is stated in `STATION_SPEC.md` sections 2.3 and 2.8 rather than silently resolved; a later gameplay phase must decide whether those three weapons really start over capacity or whether the default loadout should be per weapon.
5. **A parallel worker owns the theme and audio; the orchestrator owns the autoload registration and the route entry.** Nothing in this change touches their files, and `AUDIO_DIRS` gained only the `ambience` key.
