# D2 — Foundation A: PlayerProfile autoload + station catalogue

You are a **coder** worker. You create two new files, make one small edit, and write two docs. Everything is listed below with exact paths and exact names. Do not invent names.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (your cwd). Godot project: `vajb-orbit/`.
- Godot 4.7.2. **An editor is open on this project (PID 9048). Never run `--headless --editor`.** Never touch `project.godot` or `addons/`.
- Headless runs: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" <target>`
- Kill a hung Godot after 60 s: `powershell -Command "Get-Process Godot* | Stop-Process"` (only if YOUR process hangs; never kill the editor PID 9048).
- Do **not** use bare `python`; if you need Python use `py -3.14`.

## Read first

`AGENTS.md`, `docs/design/IMPLEMENTATION_PLAN.md` (the frozen contract — read the whole file, it defines style, naming, and the Layer Cake rule: signals travel UP, calls travel DOWN), `vajb-orbit/autoload/settings_manager.gd` (copy its persistence shape, do NOT copy its sections), `vajb-orbit/ui/paths.gd`, `vajb-orbit/game/player_state.gd`.

## Files you own (touch nothing else)

| Action | Path |
|---|---|
| create | `vajb-orbit/autoload/player_profile.gd` |
| create | `vajb-orbit/game/station_catalog.gd` |
| edit (one line) | `vajb-orbit/ui/paths.gd` |
| create | `docs/design/STATION_SPEC.md` |
| create | `.agents/gen/d2_report.md` |

Do **not** edit: `project.godot`, `addons/`, `autoload/audio_manager.gd`, `autoload/router.gd`, `tools/build_theme.gd`, `ui/theme/vajb_theme.tres`, `ui/screens/*`, `game/game.gd`. A parallel worker owns the theme and audio; the orchestrator owns the autoload registration and the route entry.

## Step 1 — write `docs/design/STATION_SPEC.md` BEFORE the code

Document exactly the contract below (docs first, then code — workspace rule). Required content:

- The purpose of `PlayerProfile` and why it is an autoload while `PlayerState` stays scene-local.
- The full public API with signatures and semantics (below).
- The save file: path `user://profile.cfg`, `ConfigFile` format, section `[profile]`, `save_version` key with value `1`, what happens on a missing file, a corrupt file, and an unknown version.
- The catalogue data model: `StationCatalog` entry shapes for ammo, ships, upgrades, with field names and types.
- The consumer contract for the future station screen: which signals it listens to, which methods it calls, and the rule that the screen never writes the ConfigFile directly.

## Step 2 — `autoload/player_profile.gd`

`class_name PlayerProfile extends Node`. Signal-driven, no other autoload referenced by bare identifier at parse time (look services up by name if you ever need them, as `router.gd` does).

Required public API — implement these exact names and signatures:

```gdscript
signal profile_changed(key: StringName)
signal purchase_failed(reason: StringName, id: StringName)

func credits() -> int
func add_credits(amount: int) -> void
func can_afford(amount: int) -> bool
func spend(amount: int) -> bool

func ammo_of(weapon_id: StringName) -> int
func ammo_max(weapon_id: StringName) -> int
func buy_ammo(weapon_id: StringName, rounds: int, cost: int) -> bool

func owns_ship(ship_id: StringName) -> bool
func owned_ships() -> Array[StringName]
func active_ship() -> StringName
func buy_ship(ship_id: StringName, cost: int) -> bool
func set_active_ship(ship_id: StringName) -> bool

func has_upgrade(upgrade_id: StringName) -> bool
func installed_upgrades() -> Array[StringName]
func install_upgrade(upgrade_id: StringName, cost: int) -> bool

func cargo_qty(item_id: StringName) -> int
func cargo_items() -> Dictionary
func add_cargo(item_id: StringName, quantity: int) -> void
func remove_cargo(item_id: StringName, quantity: int) -> bool

func save() -> void
func reset_to_defaults() -> void
```

Semantics:

- `purchase_failed` reasons are exactly: `&"insufficient_credits"`, `&"already_owned"`, `&"unknown_id"`. Emit it whenever a `buy_*` / `install_upgrade` / `set_active_ship` call fails, and return `false`.
- `buy_ship` on an already-owned ship fails with `already_owned`. `set_active_ship` on a ship you do not own fails with `already_owned`.
- A successful purchase must never leave credits negative. `spend` returns `false` and changes nothing if `amount` exceeds the balance.
- Defaults: credits 10000, owned ships `[&"ship_vanguard"]`, active ship `&"ship_vanguard"`, no upgrades, cargo empty, ammo 300 for each of `&"laser"`, `&"cannon"`, `&"rocket"`, `&"mine"`, `&"plasma"` with ammo max 300 for laser/cannon and 100 for rocket/mine/plasma.
- Persistence: debounced write 0.5 s after a change (same shape as `settings_manager.gd`), plus a `flush()` called from `_notification` on `NOTIFICATION_WM_CLOSE_REQUEST` and `NOTIFICATION_EXIT_TREE`. Corrupt or unreadable file, or `save_version` other than 1, means: log with `push_warning`, load defaults, and do not overwrite the file until the next real change.
- Every mutation emits `profile_changed(&"<key>")` with a stable key: `&"credits"`, `&"ammo"`, `&"ships"`, `&"upgrades"`, `&"cargo"`.
- No `print()`. Use `push_warning` / `push_error` only on real failures.
- Contract style: typed GDScript everywhere (`var x: int`, `-> void`), no `get_node` in loops, constants in `SCREAMING_CASE` at the top.

## Step 3 — `game/station_catalog.gd`

`class_name StationCatalog extends RefCounted`, or `extends Object` with only `const` dictionaries and `static func` helpers if you prefer — but it must be loadable as a script and must be read-only data. No nodes, no autoload.

Entry shapes (documented in `STATION_SPEC.md`, then implemented):

- Ammo pack: `id` (StringName, must be one of the five `PlayerState.WEAPONS`), `name`, `rounds`, `cost`, `icon` (res:// path), `description`.
- Ship: `id`, `name`, `cost`, `preview` (side-view sprite path), `hull`, `shield`, `cargo`, `hardpoints`, `description`.
- Upgrade: `id`, `name`, `cost`, `icon`, `slot` (`&"generator"`, `&"shield"`, `&"engine"`, `&"module"`, `&"extra"`, `&"drone"`), `effect` (Dictionary of stat deltas), `description`.

Content: 5 ammo packs (one per weapon), 4 ships, 6 upgrades. Use ONLY these existing art paths, verified on disk before you write them:

- Ships: `res://assets/ships/ship_fighter_side.png`, `res://assets/ships/ship_vanguard_side.png`, `res://assets/ships/ship_gunship_side.png`, `res://assets/ships/ship_destroyer_side.png`. Default `ship_vanguard` must match `PlayerProfile`'s default id.
- Ammo icons: `res://assets/icons/icon_ammo_laser_48.png` and `res://assets/icons/icon_ammo_rocket_48.png` exist; for cannon/mine/plasma use `res://assets/icons/icon_weapon_cannon_48.png`, `res://assets/icons/icon_weapon_mine_48.png`, `res://assets/icons/icon_weapon_plasma_48.png`.
- Upgrade icons: `res://assets/icons/icon_equip_generator_48.png`, `icon_equip_shield_gen_48.png`, `icon_equip_engine_48.png`, `icon_equip_module_48.png`, `icon_equip_extra_48.png`, `icon_equip_drone_48.png` (all under `res://assets/icons/`).

Prices are stub balance, but must be sensible and consistent: a starter ship cheaper than the mid tier, the destroyer the most expensive; ammo packs cheap; upgrades between the two. State the numbers in a table in `STATION_SPEC.md`.

## Step 4 — `ui/paths.gd`

Add exactly one key to `AUDIO_DIRS`: `&"ambience": "res://assets/audio/ambience/"`. Change nothing else in that file. Do not add a station route — the orchestrator adds it when the station scene exists.

## Step 5 — verify with measurements

Write a throwaway probe at `res://tools/_probe.gd` (`extends SceneTree`, must call `quit()`), run it headless, and delete the probe **and** its `.uid` sidecar afterwards. The probe must:

1. Load `res://autoload/player_profile.gd`, instantiate it, add it to `root`, await a frame.
2. Print the defaults: credits, owned ships, active ship, ammo for all five weapons, cargo size, upgrade count.
3. Set credits, buy a ship, buy ammo, install an upgrade, add cargo, then assert credits decreased by exactly the sum of the costs and the owned/installed lists grew.
4. Save, then read `user://profile.cfg` back with a fresh `ConfigFile` and print every stored value; assert they match the in-memory state.
5. Restore defaults, save again, and confirm the file matches the documented default state.
6. Instantiate `res://game/station_catalog.gd` and assert every `icon`, `preview` and `id` path in it resolves (`ResourceLoader.exists`) and every ammo `id` is present in `PlayerState.WEAPONS`.
7. `quit()`.

Also run: `..._console.exe --headless --path <proj> res://ui/screens/main_menu.tscn --quit-after 300` and confirm exit 0 with no new errors or warnings (your changes must not break an existing screen).

**Delete `res://tools/_probe.gd` and `res://tools/_probe.gd.uid` when done.** `tools/` must end up holding only `build_theme.gd` and `derive_icon_tints.gd` plus their `.uid` files. Confirm with a directory listing in your report.

**Important:** the probe writes to the real `user://profile.cfg`. Before you run it, record the sha256 of that file if it exists (it should not exist yet; `user://settings.cfg` is the one that does — never touch it), and leave the profile file in the documented default state at the end.

## Step 6 — `.agents/gen/d2_report.md`

Report with: files created/edited (with line counts), the exact probe output, the exit codes of the headless runs, the final `tools/` listing, the sha256 of `user://profile.cfg` after your run, and anything you could not verify. Measurements, not assertions. State explicitly that you did not register the autoload and did not add the station route (the orchestrator does both).

## Rules

- Shell-safe: no parentheses, backticks, `&&`, `>` or `<` inside commands you run through the shell; prefer separate calls.
- No em dashes in code; use commas, periods, parentheses or semicolons.
- Never edit a file you have not read in this session.
- If you find a contradiction between this brief and the frozen contract, follow this brief and say so in your report.
