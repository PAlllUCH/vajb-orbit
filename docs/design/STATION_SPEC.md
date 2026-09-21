# Vajb Orbit - Station Spec (PlayerProfile + StationCatalog)

**Status:** written 2026-09-18 (D2) before the code, per the workspace rule (docs, then code, then tests).
**Contract sources:** `docs/design/IMPLEMENTATION_PLAN.md` sections 3.5, 3.6, 3.9 and 7.
**Implements:** `vajb-orbit/autoload/player_profile.gd`, `vajb-orbit/game/station_catalog.gd`.
**Consumes (future):** the station screen. That screen is not written yet; this file is its frozen contract.

## 1. Why `PlayerProfile` is an autoload and `PlayerState` is not

`PlayerState` (`game/player_state.gd`) is **scene-local**: it is created at runtime by `game.gd`, holds live combat values (hull, shield, ammo counters, cargo fill), and dies with the scene. It answers "what is true about this ship right now".

`PlayerProfile` (`autoload/player_profile.gd`) is **persistent**: it holds the account-level facts that must survive a scene change, a return to the menu and a process restart (credits, owned ships, installed upgrades, cargo manifest). It answers "what does the player own".

The split matters:

- Purchases happen at a station, which is a different scene from the one that flies the ship. A scene-local owner would lose the purchase on the next route change.
- Exactly one writer must own `user://profile.cfg`. Two writers (one per scene) would race on the debounced save. As an autoload there is one instance for the whole process, which is what the debounce and `flush()` contract assume.
- `PlayerState` keeps its own `ammo`/`ammo_max` arrays as the **runtime HUD** reading; `PlayerProfile` keeps the **owned** loadout. `game.gd` is the only place the two are joined, by seeding `PlayerState` from the profile at scene start. Neither file imports the other.

Phase C style rules apply unchanged (IMPLEMENTATION_PLAN section 7): typed GDScript, signals up, calls down, no hex literals, no `print()`.

## 2. `PlayerProfile` public API (frozen)

`class_name PlayerProfile extends Node`. Registered as an autoload by the orchestrator (`PlayerProfile` -> `res://autoload/player_profile.gd`). The script itself references no other autoload by bare identifier; anything it needs at runtime is looked up by node name, as `router.gd` does.

### 2.1 Signals

```gdscript
signal profile_changed(key: StringName)          # a piece of the profile changed
signal purchase_failed(reason: StringName, id: StringName)   # a buy/install/activate was refused
```

`profile_changed` keys are exactly: `&"credits"`, `&"ammo"`, `&"ships"`, `&"upgrades"`, `&"cargo"`.

`purchase_failed` reasons are exactly: `&"insufficient_credits"`, `&"already_owned"`, `&"unknown_id"`.

A mutation that changes nothing emits nothing. `purchase_failed` is emitted by every failing `buy_ammo`, `buy_ship`, `install_upgrade` and `set_active_ship` call, and that call returns `false`.

A successful purchase that charges credits emits two keys, in this order: `&"credits"` (the balance changed) and then the family key (`&"ammo"`, `&"ships"` or `&"upgrades"`). A free purchase (`cost` 0) emits only the family key.

### 2.2 Credits

```gdscript
func credits() -> int
func add_credits(amount: int) -> void
func can_afford(amount: int) -> bool
func spend(amount: int) -> bool
```

- `credits()` returns the balance. Never negative.
- `add_credits(amount)`: a non-zero `amount` adds to the balance and clamps the result at 0 (a negative `amount` is a penalty/refund path, not the purchase path). Emits `profile_changed(&"credits")` when the balance actually changed; `add_credits(0)` emits nothing.
- `can_afford(amount)` is `amount <= balance` for `amount >= 0`, and `true` for `amount <= 0`.
- `spend(amount)`: returns `false` and changes nothing when `amount` exceeds the balance. Otherwise subtracts and emits `profile_changed(&"credits")`. `amount <= 0` returns `true` without emitting (nothing changed).

### 2.3 Ammo

```gdscript
func ammo_of(weapon_id: StringName) -> int
func ammo_max(weapon_id: StringName) -> int
func buy_ammo(weapon_id: StringName, rounds: int, cost: int) -> bool
```

- `ammo_of` returns 0 for an id the profile does not track.
- `ammo_max` returns the advisory hold capacity for the id, or 0 when unknown. Capacities: laser 300, cannon 300, rocket 100, mine 100, plasma 100.
- `buy_ammo` refuses with `&"unknown_id"` when `weapon_id` is not one of the five tracked weapons, or when `rounds <= 0` or `cost < 0` (the request does not identify a purchasable pack), and with `&"insufficient_credits"` when the cost exceeds the balance. On success it charges `cost`, adds `rounds`, emits `profile_changed(&"ammo")` and returns `true`.
- `ammo_max` is **advisory**: `buy_ammo` does not clamp to it. The documented default loadout (300 rounds for every weapon) already exceeds the 100 round capacity of rocket, mine and plasma, so clamping would either reject every purchase of those three or silently destroy paid rounds. The station screen uses `ammo_max` to display "300 / 100" style readouts; enforcing a cap is a gameplay decision for a later phase.

### 2.4 Ships

```gdscript
func owns_ship(ship_id: StringName) -> bool
func owned_ships() -> Array[StringName]
func active_ship() -> StringName
func buy_ship(ship_id: StringName, cost: int) -> bool
func set_active_ship(ship_id: StringName) -> bool
```

- `owns_ship` is a membership test on the owned list. `owned_ships()` returns a copy of it.
- `active_ship()` returns the id of the ship the player flies; it is always a member of `owned_ships()`.
- `buy_ship` refuses with `&"unknown_id"` when `ship_id` is not a `StationCatalog.SHIPS` id, with `&"already_owned"` when it is already owned, and with `&"insufficient_credits"` when the cost exceeds the balance. On success it charges `cost`, appends to the owned list, emits `profile_changed(&"ships")` and returns `true`. A newly bought ship does **not** become active; the screen calls `set_active_ship` for that.
- `set_active_ship` refuses with `&"already_owned"` when the ship is not owned (the reason vocabulary is closed and this is the "you do not have it" failure) and with `&"already_owned"` when it is already the active ship. On success it stores the id, emits `profile_changed(&"ships")` and returns `true`.

### 2.5 Upgrades

```gdscript
func has_upgrade(upgrade_id: StringName) -> bool
func installed_upgrades() -> Array[StringName]
func install_upgrade(upgrade_id: StringName, cost: int) -> bool
```

- `install_upgrade` refuses with `&"unknown_id"` when the id is not a `StationCatalog.UPGRADES` id, with `&"already_owned"` when it is already installed, and with `&"insufficient_credits"` when the cost exceeds the balance. On success it charges `cost`, appends to the installed list, emits `profile_changed(&"upgrades")` and returns `true`.
- Upgrades are permanent for v1 (no uninstall API). At most one upgrade per slot is enforced by the catalogue prices and content, not by the profile; a duplicate id is refused by `already_owned`.

### 2.6 Cargo

```gdscript
func cargo_qty(item_id: StringName) -> int
func cargo_items() -> Dictionary
func add_cargo(item_id: StringName, quantity: int) -> void
func remove_cargo(item_id: StringName, quantity: int) -> bool
```

- The cargo manifest is a `Dictionary` of `StringName` item id -> `int` quantity. Item ids are free-form here (a mining/loot spec owns the item catalogue); the profile only counts them.
- `cargo_qty` returns 0 for an unknown item. `cargo_items()` returns a copy, so callers cannot mutate the live manifest.
- `add_cargo(item_id, quantity)`: `quantity <= 0` or an empty id is ignored (no signal). Otherwise the quantity is added, a zero-quantity key is not created, and `profile_changed(&"cargo")` is emitted.
- `remove_cargo(item_id, quantity)`: returns `false` and changes nothing when the id is unknown or `quantity > cargo_qty(item_id)`. Removing the whole stack deletes the key. A success emits `profile_changed(&"cargo")`. It does not emit `purchase_failed` (a removal is not a purchase).

### 2.7 Persistence

```gdscript
func save() -> void             # write now, unconditionally, and cancel any pending write
func flush() -> void            # read by _notification: write only when there is a pending change
func reset_to_defaults() -> void
```

- Every mutation marks the profile dirty and (re)starts a 0.5 s one-shot `Timer` whose timeout writes the file, the same debounce shape as `settings_manager.gd`. Mutations are frequent during a shopping session, so the debounce exists to keep the disk write count at one per session of edits.
- `save()` writes immediately and clears the dirty flag. `reset_to_defaults()` is the one caller in the code base that pairs a reset with an explicit write.
- `flush()` is called from `_notification()` on `NOTIFICATION_WM_CLOSE_REQUEST` and `NOTIFICATION_EXIT_TREE`; it stops the debounce timer and writes only when a change is pending, so a clean session never touches the file.
- `reset_to_defaults()` restores every documented default, emits `profile_changed` once per key (`credits`, `ammo`, `ships`, `upgrades`, `cargo`), marks the profile dirty and lets the debounce write it.

### 2.8 Defaults

| Field | Default |
|---|---|
| credits | 10000 |
| owned ships | `[&"ship_vanguard"]` |
| active ship | `&"ship_vanguard"` |
| upgrades | empty |
| cargo | empty |
| ammo | 300 each for `&"laser"`, `&"cannon"`, `&"rocket"`, `&"mine"`, `&"plasma"` |
| ammo capacity (advisory) | 300 for laser and cannon, 100 for rocket, mine and plasma |

`&"ship_vanguard"` is the default id in both this spec and `StationCatalog.SHIPS`.

## 3. The save file

| Item | Value |
|---|---|
| Path | `user://profile.cfg` |
| Format | Godot `ConfigFile` (INI) |
| Section | `[profile]` |
| Version key | `save_version` = `1` |

Keys, all inside `[profile]`:

| Key | Type | Meaning |
|---|---|---|
| `save_version` | int | Format version. Only `1` is understood. |
| `credits` | int | Balance. |
| `owned_ships` | Array of String | Owned ship ids, in acquisition order. |
| `active_ship` | String | Active ship id. |
| `upgrades` | Array of String | Installed upgrade ids. |
| `cargo` | Dictionary (String -> int) | Item id -> quantity. |
| `ammo` | Dictionary (String -> int) | Weapon id -> rounds. |

Load outcomes:

| Case | Behaviour |
|---|---|
| File missing (`ERR_FILE_NOT_FOUND`) | Normal first run. Load the defaults, no warning, no write until the next real change. |
| File unreadable or unparsable (any other non-`OK` error) | `push_warning`, load the defaults, leave the file untouched until the next real change. |
| Loads, but `save_version` is absent or not `1` | `push_warning`, load the defaults, leave the file untouched until the next real change. |
| Loads, `save_version == 1` | Every key is read independently; a missing key falls back to its default and a key of the wrong type is ignored (with `push_warning`). A partially written file therefore degrades to defaults per field instead of resetting the account. |
| `active_ship` unset or not a member of `owned_ships` | Coerced to the default ship id. |

The file is only written by the debounce timer, by `save()`, or by `flush()` with a pending change. A corrupt or version-mismatched file is never silently overwritten at boot.

## 4. `StationCatalog` data model

`class_name StationCatalog extends RefCounted`. Read-only data plus `static` lookups: no nodes, no autoload, no `_ready`, no mutation API. `autoload/player_profile.gd` loads the script (`load("res://game/station_catalog.gd")`) and reads its id lists to validate purchases; the station screen reads the const arrays directly. Nothing writes to them.

### 4.1 Ammo packs, `const AMMO_PACKS: Array[Dictionary]`

| Field | Type | Meaning |
|---|---|---|
| `id` | StringName | One of the five `PlayerState.WEAPONS` ids. |
| `name` | String | Display name. |
| `rounds` | int | Rounds granted per pack. |
| `cost` | int | Price in credits. |
| `icon` | String | `res://` path to the 48 px ammo or weapon icon. |
| `description` | String | One-line flavour text. |

One pack per weapon, five in total. The pack `id` **is** the weapon id (`&"laser"`, `&"cannon"`, `&"rocket"`, `&"mine"`, `&"plasma"`), so `buy_ammo(pack.id, pack.rounds, pack.cost)` is the whole call the screen makes: there is no separate pack id to translate. The pack lists are ordered to match `PlayerState.WEAPONS` — which stays the **default** list, the five families a `PlayerState` built without a fit still runs on; the **live** list is the launched fit's own weapon ids (`PlayerState.weapons`, CONTRACTS §11), so a hull with two fitted lasers draws both of its W slots from the `laser` pack (ammo stays per family, never per slot).

### 4.2 Ships, `const SHIPS: Array[Dictionary]`

| Field | Type | Meaning |
|---|---|---|
| `id` | StringName | Ship id, unique. `&"ship_vanguard"` is the profile default. |
| `name` | String | Display name. |
| `cost` | int | Price in credits. |
| `preview` | String | `res://` path to the side-view sprite. |
| `hull` | int | Maximum hull, matching the `PlayerState` role of that ship. |
| `shield` | int | Maximum shield. |
| `cargo` | int | Maximum cargo units. |
| `hardpoints` | int | Weapon hardpoint count. |
| `description` | String | One-line flavour text. |

Nine ships, one per 08 §2 class and in that document's ladder order: fighter (`ship_fighter`), vanguard (`ship_vanguard`), miner (`ship_miner`), trader (`ship_trader`), corvette (`ship_corvette`), freighter (`ship_freighter`, the Hauler), gunship (`ship_gunship`), patrol (`ship_patrol`, the Frigate), destroyer (`ship_destroyer`). The four this line used to list — fighter, vanguard, gunship, destroyer — are four of the nine, and their §5.2 costs stay frozen.

### 4.3 Upgrades, `const UPGRADES: Array[Dictionary]`

| Field | Type | Meaning |
|---|---|---|
| `id` | StringName | Upgrade id, unique. |
| `name` | String | Display name. |
| `cost` | int | Price in credits. |
| `icon` | String | `res://` path to the 48 px equipment icon. |
| `slot` | StringName | One of `&"generator"`, `&"shield"`, `&"engine"`, `&"module"`, `&"extra"`, `&"drone"`. |
| `effect` | Dictionary (String -> float) | Stat deltas. Every value is a **fraction** applied to the matching stat (0.25 = +25 %). |
| `description` | String | One-line flavour text. |

Six upgrades, one per slot.

### 4.4 Static helpers

```gdscript
static func ammo_pack(id: StringName) -> Dictionary     # {} when unknown
static func ship(id: StringName) -> Dictionary          # {} when unknown
static func upgrade(id: StringName) -> Dictionary       # {} when unknown
static func ammo_ids() -> Array[StringName]
static func ship_ids() -> Array[StringName]
static func upgrade_ids() -> Array[StringName]
```

The returned dictionaries are the live const entries; callers must treat them as read-only and copy before mutating.

## 5. Stub prices (frozen for v1 balance)

Price ladder: ammo packs are the cheapest tier, upgrades sit in the middle, ships are the most expensive, with the starter ship below the mid tier and the destroyer at the top.

| Family | Id | Name | Cost |
|---|---|---|---|
| ammo | `laser` | Laser Cells | 120 |
| ammo | `cannon` | Cannon Shells | 180 |
| ammo | `rocket` | Rocket Pod | 240 |
| ammo | `mine` | Mine Rack | 200 |
| ammo | `plasma` | Plasma Cells | 320 |
| ship | `ship_fighter` | Lancer | 9000 |
| ship | `ship_vanguard` | Vanguard | 18000 |
| ship | `ship_gunship` | Bulwark | 36000 |
| ship | `ship_destroyer` | Obliterator | 72000 |
| upgrade | `upgrade_extra_cargo` | Cargo Expansion | 3000 |
| upgrade | `upgrade_engine` | Ion Drive | 3800 |
| upgrade | `upgrade_generator` | Reactor Mk2 | 4200 |
| upgrade | `upgrade_shield` | Shield Amplifier | 5200 |
| upgrade | `upgrade_module` | Deep Scanner | 4600 |
| upgrade | `upgrade_drone` | Repair Drone Bay | 6800 |

Ship cost ladder is a clean x2 step (9000 / 18000 / 36000 / 72000). Ammo packs are all under 400 credits. Upgrades are all inside 3000 to 6800 credits, above every ammo pack and below every ship.

### 5.1 Ammo pack rounds

| Pack | Rounds |
|---|---|
| `laser` | 300 |
| `cannon` | 300 |
| `rocket` | 60 |
| `mine` | 40 |
| `plasma` | 50 |

### 5.2 Ship stats

| Id | Hull | Shield | Cargo | Hardpoints |
|---|---|---|---|---|
| `ship_fighter` | 700 | 400 | 25 | 3 |
| `ship_vanguard` | 1000 | 600 | 40 | 4 |
| `ship_gunship` | 1400 | 650 | 50 | 5 |
| `ship_destroyer` | 2200 | 900 | 80 | 7 |

`ship_vanguard` matches the `PlayerState` defaults (`hull_max` 1000, `shield_max` 600, `cargo_max` 40), so the starting ship needs no stat translation.

### 5.3 Upgrade effects

| Id | Slot | Effect |
|---|---|---|
| `upgrade_generator` | `generator` | `{"shield_regen": 0.30, "energy_regen": 0.20}` |
| `upgrade_shield` | `shield` | `{"shield_max": 0.20}` |
| `upgrade_engine` | `engine` | `{"speed": 0.15}` |
| `upgrade_module` | `module` | `{"scanner_range": 0.25}` |
| `upgrade_extra_cargo` | `extra` | `{"cargo_max": 0.25}` |
| `upgrade_drone` | `drone` | `{"hull_repair_rate": 0.50}` |

## 6. Consumer contract: the future station screen

The station screen (`ui/screens/station.tscn`, future phase, not owned by D2) is a pure consumer of both modules.

**It connects to:**

| Signal | Use |
|---|---|
| `PlayerProfile.profile_changed(key)` | Refresh the credits readout and the affected list. `key` selects which panel to rebuild: `&"credits"`, `&"ammo"`, `&"ships"`, `&"upgrades"`, `&"cargo"`. |
| `PlayerProfile.purchase_failed(reason, id)` | Show the refusal as a message: `&"insufficient_credits"` -> "not enough credits", `&"already_owned"` -> "already owned / already active", `&"unknown_id"` -> "not for sale". The screen never pre-computes a refusal it can let the profile decide; it may grey a button out with `can_afford` and `owns_ship` for presentation only. |

**It calls:**

| Method | When |
|---|---|
| `credits()`, `can_afford(cost)` | Credits readout and affordability hints. |
| `ammo_of(id)`, `ammo_max(id)` | Ammo pack panel. |
| `buy_ammo(id, rounds, cost)` | Buy button, with the catalogue's `rounds` and `cost`. |
| `owns_ship(id)`, `owned_ships()`, `active_ship()` | Ship list state. |
| `buy_ship(id, cost)`, `set_active_ship(id)` | Ship "buy" and "set active" buttons. |
| `has_upgrade(id)`, `installed_upgrades()` | Upgrade list state. |
| `install_upgrade(id, cost)` | Upgrade "install" button. |
| `cargo_qty(id)`, `cargo_items()`, `add_cargo(id, n)`, `remove_cargo(id, n)` | Cargo hold panel (sell/deposit flows in a later phase). |
| `StationCatalog.SHIPS`, `AMMO_PACKS`, `UPGRADES`, and the `*_ids()` helpers | Stock listing. |

**Rules:**

1. The screen is a **consumer only**. It never reads or writes `user://profile.cfg` and never constructs a `ConfigFile`. `PlayerProfile` is the single writer of that file; a second writer would race the debounce.
2. Every purchase goes through a `PlayerProfile` method that returns `bool`; the screen reacts to the returned value and to `purchase_failed`, and never mutates credits or the owned lists itself.
3. The screen never mutates a `StationCatalog` entry (no `.duplicate()` needed for reading, but no writing either). Prices and content live in the catalogue; the profile only knows ids and costs that it is handed.
4. The screen routes and shows messages through the Phase C contract (`Screen` intent signals, `DialogManager`), it does not call `change_scene`.
5. `game.gd` (not the station screen) is the only place that seeds a `PlayerState` from the profile at scene start.
