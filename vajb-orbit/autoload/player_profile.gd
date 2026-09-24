extends Node
## Persistent account state: credits, owned ships, modules, cargo, ammo.
## No class_name: the autoload is named PlayerProfile, and Godot rejects a
## global class that hides an autoload singleton (parse error at registration).
## Contract: docs/design/STATION_SPEC.md.
## P1 save v2: keys added by docs/gameplay/17_coder_handoff.md section 3
## (modules, fits, market, heat, standing, contracts, vaults, insured,
## mercy_used) plus the vitals extension approved for the 01 section 6
## repairs panel. Slice-0 save v3 adds the tank to a vitals entry
## (18_engine_spec section 12 item 13: Fuel persists across a launch, Energy
## recomputes) and the `profile_changed` key &"fuel". P2-A save v4 turns `fits`
## into the per-cell arrays of 09 section 4.5 / CONTRACTS section 11: a v1-v3
## single id per slot type is read as a one-element array padded to the hull's
## capacity and is never rewritten at load, while a write persists the array
## shape. Version 1 to 3 files still load; a key they never wrote comes up at
## its default, with no warning, and writes always persist save_version 4.
## P2-B proper save v5 retires the pre-module `upgrades` record (09 section 4
## item 13, CONTRACTS section 13): a file below v5 has its installed upgrades
## converted to one inventory module each by `retire_legacy_upgrades`, called
## from the load path right after the record is read, and the key goes; a v5
## file carries no `upgrades` key at all and a v1-v3 file never had one. The
## same save adds the two composed fitting transactions of the FITTING panel's
## per-cell install and remove, `fit_module_at` and `clear_fit_slot`.
## S3 save v6 turns `modules` into an `instance_id -> record` dictionary of 15
## section 6/8's module instances (CONTRACTS section 15): the record is
## `{instance_id, base_id, rarity, prefixes, suffixes, count}`, `count` is 1 in the
## bag and 0 while the module is fitted, and a fitted record is **never erased** --
## that is how REMOVE/SWAP hand the same instance back. A v5 `{base_id, count}`
## record becomes `count` Common instances through `migrate_module_instances`,
## called from the load path for a file below v6 (the P2-B flag-day pattern). The
## same save adds the two new top-level keys -- `instance_counter`, the `mod_%04d`
## mint, and `auction`, the shelf -- and a fit cell now holds an instance id, so
## every fit judgement goes through `base_fit`.
## S4 adds the two bulk wrappers over those transactions, `fit_battery` and
## `clear_battery` (CONTRACTS section 16 rules 7-8): a battery's cells filled or
## emptied in one batch that pairs `instances_of` into ascending cells and is
## atomic over the fit **and** the bag, so a refused batch leaves the account
## where it started.
## S5 save v7 makes a battery a **player-composed mixed group** (09 section 11,
## CONTRACTS section 17) and persists it: the `batteries` key holds
## `{ship_id: Array[Array[cell_ref]]}`, one hull's **racks** in order, each rack the
## W-cell layout indices of the barrels that fire together. The fit is untouched --
## one instance per W cell -- and the rack record says which trigger fires which
## barrel, so a rack may mix kinds and `weapon_1..7` addresses a rack, not a family.
## A v6 file has no such key: `migrate_batteries` groups each hull's fitted weapons
## by `base_id`, cells ascending (called from the load path when the file's version
## is below 7, idempotent). The same save adds the three composed transactions the
## ARMORY pane's drags call -- `fit_into_rack`, `clear_rack_cell` and
## `move_rack_cell` -- each one atomic over the fit, the bag and the record.
## Test and support hooks, present for the P1 suites and migration fixtures
## only: save_path (defaults to SAVE_FILE) and reload().

signal profile_changed(key: StringName)
signal purchase_failed(reason: StringName, id: StringName)

const Catalog := preload("res://game/station_catalog.gd")
## The hull and slot-grid authority behind the fit store: the eight slot types
## and their order, each hull's per-type capacity, and the nine player hulls
## (09 section 4.5, CONTRACTS section 11).
const FitData := preload("res://game/ship_fit.gd")
## The module catalogue (CONTRACTS section 11): `buy_module` verifies an id
## against it, so an id the game does not ship is never sold. Its `cost` is the
## row 09 section 3 prices, and the panel passes that number in.
const ModuleData := preload("res://game/module_catalog.gd")
## The weapon family table and the rack ceiling (save v7, CONTRACTS section 17): the
## racks a hull may compose are `GROUPS_MAX` (`game/weapons.gd`, the same one the HUD
## and the input map read) and a rack reference is only followed for a cell whose
## module is a weapon **family**, so `w_mining` never enters one. One shared source,
## never a second 7.
const WeaponData := preload("res://game/weapons.gd")
## The sell price's one owner (CONTRACTS section 20): `sell_instance` pays through
## `Auction.sell_price`, the same function the pane's row and the transaction's quote
## read, so the payout and the displayed price can never drift -- in particular the
## 15 section 4 Ledger term. Preloaded by path, like every other dependency here.
const AuctionData := preload("res://game/auction.gd")
## The economy transaction log (01 section 7): one line per purchase.
const Log := preload("res://game/economy_log.gd")

const SAVE_FILE := "user://profile.cfg"
const SECTION := "profile"
const SAVE_VERSION := 7
const MIN_READABLE_VERSION := 1
const SAVE_DEBOUNCE_SECONDS := 0.5

const KEY_CREDITS: StringName = &"credits"
const KEY_AMMO: StringName = &"ammo"
const KEY_SHIPS: StringName = &"ships"
const KEY_CARGO: StringName = &"cargo"

## The retired `upgrades` key (save v5): every id in the record is converted to
## one inventory module and the key is dropped. No live writer or reader of it
## survives the migration, and `_write_profile` no longer persists it.
const KEY_RETIRED_UPGRADES: String = "upgrades"

## Signal keys added by P1 (17 section 3). Every other new key persists silently.
const KEY_MODULES: StringName = &"modules"
const KEY_FITS: StringName = &"fits"
const KEY_STANDING: StringName = &"standing"

## Signal key added by engine slice 0 (18_engine_spec section 12 item 13): the filed
## tank moved. A vitals write is otherwise silent (17 section 3); fuel is the one
## exception, so a station-side refuel can tell the flight side.
const KEY_FUEL: StringName = &"fuel"

## `set_vitals`'s "this caller is not filing a tank" sentinel. Fuel is stored in
## whole points, so a negative value can never collide with a real reading, and the
## entry stays sticky: a caller that passes no fuel leaves the filed one alone.
const FUEL_UNFILED := -1

## The one scalar slot type: 09 section 4.5 rule 1 fits one module id per POWER
## cell, so a fit stores `power` as an id and the other seven types as arrays.
const POWER_SLOT: StringName = &"power"
## The engine set (v4) and its pre-v4 spelling, which a migrated file still
## carries (CONTRACTS section 11 rule 2; `engines` wins when both are present).
const ENGINE_SLOT: StringName = &"engines"
const LEGACY_ENGINE_SLOT: StringName = &"engine"
## The weapon set: the one slot type the S4 bulk wrappers address, because a
## battery is a group of fitted weapons (09 section 10, CONTRACTS section 16).
const WEAPON_SLOT: StringName = &"weapons"

## Market sub-keys, present in every normalised market dictionary.
const MARKET_KEYS: Array[String] = ["demand", "stock", "queue", "trend"]

## 15 section 8's instance mint (CONTRACTS section 15): one per-profile counter,
## `instance_counter` in the save, formats every module instance id. Every roll
## takes the next number -- inventory, drop and the AUCTION shelf's listings -- and
## the counter never rewinds, not even when an unbought listing is discarded at
## restock.
const INSTANCE_ID_FORMAT := "mod_%04d"

## The six keys of one v6 inventory record (CONTRACTS section 15, 17 section 3).
## Written and read as Strings, which is what a `ConfigFile` gives back, so a live
## record and a loaded one are the same dictionary.
const KEY_INSTANCE_ID := "instance_id"
const KEY_BASE_ID := "base_id"
const KEY_RARITY := "rarity"
const KEY_PREFIXES := "prefixes"
const KEY_SUFFIXES := "suffixes"
const KEY_COUNT := "count"

## The AUCTION shelf's home (CONTRACTS section 15): a **top-level** key, not a
## `market` sub-key, because `_normalise_market` rebuilds that dictionary from
## `MARKET_KEYS` and would drop a stranger on load.
const KEY_AUCTION := "auction"
const KEY_INSTANCE_COUNTER := "instance_counter"

## The composed batteries' home (save v7, CONTRACTS section 17): `{ship_id:
## Array[Array[int]]}`, one hull's racks in order, each entry the W-cell layout
## indices (09 section 4.5) of the barrels that fire together. A top-level key like
## `auction`, for the same reason. It is also the signal key a rack write emits,
## which is what redraws the ARMORY pane's drop zones.
const KEY_BATTERIES: StringName = &"batteries"

## The weapon module id prefix, for the pane's own reading of a rack entry: a rack
## holds W cells, and `game/weapons.gd`'s GROUPS_MAX is the rack ceiling (7).
const WEAPON_MODULE_PREFIX := "w_"

## The shelf state's four members, in the pin's own order: the restock band, the
## listed hull ids, the rolled module listings and the one discounted listing id.
const AUCTION_KEYS: Array[String] = ["last_band", "hulls", "modules", "hot"]

const REASON_INSUFFICIENT: StringName = &"insufficient_credits"
const REASON_ALREADY_OWNED: StringName = &"already_owned"
const REASON_UNKNOWN: StringName = &"unknown_id"

## 01 section 7 log vocabulary, plus the P2-B1 module purchase (CONTRACTS
## section 12): one line per module bought into the inventory, and the P2-B
## fitting transactions (CONTRACTS section 13): one line per installed or
## removed cell.
const EVENT_BUY_MODULE := "BUY_MODULE"
const EVENT_FIT_MODULE := "FIT_MODULE"
## Buying ammunition into the hold (10 section 6.1). One line per purchase, the way
## `BUY_MODULE` carries a module purchase: the event word is this file's own addition to
## 01 section 7's vocabulary (the log is append-only and debug-only), and the line's item
## field carries the `ammo_*` cargo id while `qty` is the units bought.
const EVENT_BUY_AMMO := "BUY_AMMO"
## Selling a module instance (15 section 6/8). The word is the exchange's own
## `SELL` -- the nearest shipped event id, which CONTRACTS section 12 rule 1
## licenses -- and the line's item field carries the instance's **base** id, so a
## replay aggregates by item while the price delta carries the rarity.
const EVENT_SELL_MODULE := "SELL"
## Doc 13 section 2's redemption path, wired by wave S6 (CONTRACTS section 19): one line
## per bounty paid, the cleared heat in the quantity field and the fine as the credits
## delta, so a replay reads what was owed and what it cost.
const EVENT_BOUNTY := "BOUNTY"
## Doc 13 section 2's fine rate, verbatim: `fine = heat x 25 CR` (so 40 heat costs
## 1 000 CR). One home; the LAUNCH row prints `bounty_fine`'s answer, never its own.
const BOUNTY_CR_PER_HEAT := 25
## Doc 13 section 2's per-faction heat bound and the floor the reduction and the decay
## both stop at. The **gain** clamp lives in `game.gd`'s `_apply_heat`, the one writer of
## a positive delta; `heat_of` bounds every read the same way.
const HEAT_MIN := 0
const HEAT_MAX := 100

## The save v5 retirement table (CONTRACTS section 13), 09 section 4 item 13's
## one-way door: each of the six retired `StationCatalog.UPGRADES` rows names the
## module that carries its effect, per 09's own lineage rows and 10 section 5.
## `retire_legacy_upgrades` is its one reader.
const LEGACY_UPGRADE_MODULES: Dictionary = {
	&"upgrade_generator": &"p_mk2",   &"upgrade_shield": &"s_heavy",
	&"upgrade_engine":    &"e_ion",   &"upgrade_module": &"c_scanner",
	&"upgrade_extra":     &"u_cargo", &"upgrade_drone":  &"u_drones",
}

const DEFAULT_CREDITS := 10000
const DEFAULT_SHIP: StringName = &"ship_vanguard"
const DEFAULT_AMMO := 300

## Weapon id -> the family's magazine ceiling, in rounds. Since S5 it is the auto-load's
## fill ceiling (`load_ammo_from_hold` fills the pack *up to* this figure and never above
## it) and remains advisory in the hold sense: a purchase is never clamped to it, and a
## pack already above it is never lowered.
## **S5 (2026-09-23, CONTRACTS section 17):** the railgun is the sixth family with its own
## pack (owner ruling: rounds 150, cost 360, `ammo_max` 150 -- twice the cannon pack's cost,
## half its rounds and half its `AMMO_MAX`). It is also the auto-load's ceiling in
## `load_ammo_from_hold`: a family's pack is filled *up to* this figure and never above it.
const AMMO_MAX: Dictionary = {
	&"laser": 300,
	&"cannon": 300,
	&"rocket": 100,
	&"mine": 100,
	&"plasma": 100,
	&"railgun": 150,
}

## Test/support hook: the P1 suites and migration fixtures repoint this at a
## throwaway file. Production keeps the SAVE_FILE default.
var save_path: String = SAVE_FILE

var _config := ConfigFile.new()
var _save_timer: Timer
var _dirty := false

var _credits := DEFAULT_CREDITS
var _owned_ships: Array[StringName] = []
var _active_ship: StringName = DEFAULT_SHIP
var _cargo: Dictionary = {}
var _ammo: Dictionary = {}
var _known_ships: Dictionary = {}

var _modules: Dictionary = {}
var _fits: Dictionary = {}
var _market: Dictionary = {"demand": {}, "stock": {}, "queue": {}, "trend": {}, "last_band": 0}
var _heat: Dictionary = {}
var _standing: Dictionary = {}
## The faction whose station the account is docked at (doc 13 section 7's bounty row and
## doc 14 section 7's "any faction station with heat > 0"). `game.gd` writes it as it
## routes to the station and `ui/station/launch_panel.gd` reads it. **Transient**: a
## station is only ever reached from flight, so it is not a save key and `_apply_defaults`
## clears it rather than persisting it (CONTRACTS section 19's report).
var _docked_faction: StringName = &""
var _contracts: Array = []
var _vaults: Dictionary = {}
var _insured := false
var _mercy_used := false
var _vitals: Dictionary = {}
var _instance_counter := 0
var _auction: Dictionary = {"last_band": 0, "hulls": [], "modules": {}, "hot": &""}
## Save v7's racks: `{ship_id: Array[Array[int]]}` in the order the racks fire,
## each one a list of W-cell layout indices (CONTRACTS section 17). Empty for a
## v6 file until `migrate_batteries` has grouped its fitted weapons.
var _batteries: Dictionary = {}


func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.name = &"SaveDebounce"
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DEBOUNCE_SECONDS
	_save_timer.timeout.connect(_write_profile)
	add_child(_save_timer)

	_load_catalog()
	_load_profile()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		flush()


func credits() -> int:
	return _credits


func add_credits(amount: int) -> void:
	if amount == 0:
		return
	var updated := maxi(0, _credits + amount)
	if updated == _credits:
		return
	_credits = updated
	_touch(KEY_CREDITS)


func can_afford(amount: int) -> bool:
	return amount <= 0 or _credits >= amount


func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if amount > _credits:
		return false
	_credits -= amount
	_touch(KEY_CREDITS)
	return true


func ammo_of(weapon_id: StringName) -> int:
	return int(_ammo.get(weapon_id, 0))


func ammo_max(weapon_id: StringName) -> int:
	return int(AMMO_MAX.get(weapon_id, 0))


## The cargo id one ammo family is held under (`&"laser"` -> `&"ammo_laser"`), or `&""`
## for an id outside the six packs (CONTRACTS section 17's prefix rule, in
## `Catalog.ammo_item_id`).
func ammo_item_id(weapon_id: StringName) -> StringName:
	if not AMMO_MAX.has(weapon_id):
		return &""
	return Catalog.ammo_item_id(weapon_id)


## How many cargo **units** of one ammo family the hold carries (10 section 6.1:
## `ROUNDS_PER_CARGO_UNIT` rounds apiece), 0 for a family the catalogue does not ship.
## This is the reading the ARMORY pane's rows show and the figure the auto-load spends.
func ammo_units(weapon_id: StringName) -> int:
	var item_id := ammo_item_id(weapon_id)
	if item_id == &"":
		return 0
	return cargo_qty(item_id)


## Buy ammunition **into the hold** (10 section 6.1 / CONTRACTS section 17): `rounds` of
## the family is delivered as `units = rounds / ROUNDS_PER_CARGO_UNIT` of its `ammo_*`
## cargo item, and `cost` is the pack's own price -- the caller passes it exactly as
## `buy_module`/`buy_ship` take theirs (17 section 5 item 4 keeps the price in the
## catalogue and out of the UI). The pack store is **not** written: the ship's packs are
## loaded from the hold at launch (`load_ammo_from_hold`), never bought into.
## 17 section 5's transaction law, all-or-nothing: verify (an id outside `AMMO_MAX`, a
## non-positive rounds or a negative cost is `unknown_id`), charge
## (`insufficient_credits` when the balance is short), give (one `add_cargo`), emit
## (`&"credits"` then `&"cargo"` from the add) and log -- exactly one line, and a refused
## purchase writes no credits, no cargo and no line.
func buy_ammo(weapon_id: StringName, rounds: int, cost: int) -> bool:
	if not AMMO_MAX.has(weapon_id) or rounds <= 0 or cost < 0:
		return _refuse(REASON_UNKNOWN, weapon_id)
	var units := _ammo_units_for(rounds)
	if units <= 0:
		return _refuse(REASON_UNKNOWN, weapon_id)
	if not _charge(cost):
		return _refuse(REASON_INSUFFICIENT, weapon_id)
	add_cargo(Catalog.ammo_item_id(weapon_id), units)
	Log.append(EVENT_BUY_AMMO, Catalog.ammo_item_id(weapon_id), units, -cost, _credits)
	return true


## The auto-load (10 section 6.1 / CONTRACTS section 17): top the family's pack up to its
## `ammo_max` from the hold's cargo units, drawing whole units only, and answer the rounds
## the pack now holds. Called **once at launch** and never in flight; a pack already at or
## over its ceiling draws nothing and is never lowered, so a magazine filled last flight
## keeps its rounds and a pack that emptied in flight stays empty until the next launch.
##
## The draw is `min(units_needed, units_held)` where `units_needed` is
## `ceil((ammo_max - pack) / ROUNDS_PER_CARGO_UNIT)`: a unit is indivisible, so the last
## unit can overshoot the ceiling by up to `ROUNDS_PER_CARGO_UNIT - 1` rounds and the pack
## is clamped at `ammo_max` (the overshoot's rounds are gone with the unit -- the measured
## cost of the pinned granularity). A family the catalogue does not ship, or one with
## nothing to fill, writes nothing and answers the pack as it stands.
func load_ammo_from_hold(weapon_id: StringName) -> int:
	if not AMMO_MAX.has(weapon_id):
		return 0
	var pack := ammo_of(weapon_id)
	var ceiling := ammo_max(weapon_id)
	var shortfall := ceiling - pack
	if shortfall <= 0:
		return pack
	var needed := _ammo_units_for(shortfall)
	var held := ammo_units(weapon_id)
	var drawn := mini(needed, held)
	if drawn <= 0:
		return pack
	if not remove_cargo(Catalog.ammo_item_id(weapon_id), drawn):
		return pack
	var loaded := mini(ceiling, pack + drawn * Catalog.ROUNDS_PER_CARGO_UNIT)
	set_ammo(weapon_id, loaded)
	return loaded


## Rounds -> cargo units (`ROUNDS_PER_CARGO_UNIT` apiece), rounded up because a unit is
## indivisible. 0 for a non-positive figure.
func _ammo_units_for(rounds: int) -> int:
	if rounds <= 0:
		return 0
	return ceili(float(rounds) / float(Catalog.ROUNDS_PER_CARGO_UNIT))


## The absolute writer the dock's pack report needs (18_engine_spec section 4.3 /
## 01 section 6): the launch writes the pack it loaded from the hold (`load_ammo_from_hold`)
## and the *fired deltas* come back on dock, so the filing negates its own delta and needs
## a setter. `rounds` is the pack's new holding, clamped at zero; an id outside `AMMO_MAX`
## is refused silently, so a typo cannot open a pack the catalogue does not ship. A write
## that changes nothing neither dirties the file nor emits `profile_changed`, which keeps
## the every-dock report from signalling when nothing was fired.
func set_ammo(weapon_id: StringName, rounds: int) -> void:
	if not AMMO_MAX.has(weapon_id):
		return
	var holding := maxi(0, rounds)
	if int(_ammo.get(weapon_id, 0)) == holding:
		return
	_ammo[weapon_id] = holding
	_touch(KEY_AMMO)


func owns_ship(ship_id: StringName) -> bool:
	return _owned_ships.has(ship_id)


func owned_ships() -> Array[StringName]:
	var ships: Array[StringName] = []
	ships.append_array(_owned_ships)
	return ships


func active_ship() -> StringName:
	return _active_ship


func buy_ship(ship_id: StringName, cost: int) -> bool:
	if not _known_ships.has(ship_id) or cost < 0:
		return _refuse(REASON_UNKNOWN, ship_id)
	if _owned_ships.has(ship_id):
		return _refuse(REASON_ALREADY_OWNED, ship_id)
	if not _charge(cost):
		return _refuse(REASON_INSUFFICIENT, ship_id)
	_owned_ships.append(ship_id)
	_touch(KEY_SHIPS)
	return true


func set_active_ship(ship_id: StringName) -> bool:
	if not _owned_ships.has(ship_id) or _active_ship == ship_id:
		return _refuse(REASON_ALREADY_OWNED, ship_id)
	_active_ship = ship_id
	_touch(KEY_SHIPS)
	return true


func cargo_qty(item_id: StringName) -> int:
	return int(_cargo.get(item_id, 0))


func cargo_items() -> Dictionary:
	return _cargo.duplicate()


func add_cargo(item_id: StringName, quantity: int) -> void:
	if item_id == &"" or quantity <= 0:
		return
	_cargo[item_id] = int(_cargo.get(item_id, 0)) + quantity
	_touch(KEY_CARGO)


func remove_cargo(item_id: StringName, quantity: int) -> bool:
	if quantity <= 0:
		return false
	var held := int(_cargo.get(item_id, 0))
	if held < quantity:
		return false
	if held == quantity:
		_cargo.erase(item_id)
	else:
		_cargo[item_id] = held - quantity
	_touch(KEY_CARGO)
	return true


func modules() -> Dictionary:
	return _modules.duplicate(true)


## Replace the whole bag. Normalised first -- keys as Strings, every record 15
## section 6/8's six-key shape -- so a fixture that hands in a short record (a
## `{base_id, count}` pair, or a bare `{count: n}`) is read canonically and a second
## identical set stays silent.
func set_modules(value: Dictionary) -> void:
	var candidate := _normalise_instances(_to_plain(value))
	if candidate == _modules:
		return
	_modules = candidate
	_touch(KEY_MODULES)


## The base catalogue id of one inventory entry (15 section 6): a fit stores a
## module *instance* id and `ShipFit` reads base ids, so this is the one bridge
## between the two. An entry the inventory does not carry is returned unchanged,
## which is what keeps a base id (`w_laser`) and every fixture that stores base
## ids directly working exactly as they did before save v4.
func base_module_id(entry: StringName) -> StringName:
	if entry == &"":
		return &""
	var record := _module_record(entry)
	if record.is_empty():
		return entry
	var base := StringName(str(record.get("base_id", "")))
	return base if base != &"" else entry


## How many of one inventory entry the account holds (15 section 6's `count`), 0
## for an id the inventory does not carry. The id is the record's own key, so an
## instance (`mod_0007`) and a plain base id answer alike; a record written
## before the count existed reads as 0.
func module_count(module_id: StringName) -> int:
	var record := _module_record(module_id)
	if record.is_empty():
		return 0
	return maxi(0, int(record.get("count", 0)))


## Add `count` of one inventory entry, creating the record when the account does
## not carry it yet. Since save v6 the record is 15 section 6/8's own shape -- the
## six keys of CONTRACTS section 15 -- with the entry's id as both `instance_id` and
## `base_id` and `rarity` Common, because this is the *count* half of the inventory
## and not 15 section 6's affix roll: a record already carrying `rarity`/
## `prefixes`/`suffixes` keeps them untouched, and one created here carries the
## Common defaults and no affix rows. A short record handed in (a v5-shaped
## fixture) is read in that canonical shape first.
func add_module(module_id: StringName, count: int = 1) -> void:
	if module_id == &"" or count <= 0:
		return
	var key := String(module_id)
	var record := _normalise_instance(key, _module_record(module_id))
	record[KEY_COUNT] = int(record.get(KEY_COUNT, 0)) + count
	_modules[key] = record
	_touch(KEY_MODULES)


## Take `count` of one inventory entry out of the account (a module sold, or
## moved into a hull). Refuses, and writes nothing, when the account holds fewer;
## the record is erased once its count reaches zero, exactly as `remove_cargo`
## drops an emptied item.
func take_module(module_id: StringName, count: int = 1) -> bool:
	if module_id == &"" or count <= 0:
		return false
	var held := module_count(module_id)
	if held < count:
		return false
	var key := String(module_id)
	if held == count:
		_modules.erase(key)
	else:
		var record := _module_record(module_id)
		record["count"] = held - count
		_modules[key] = record
	_touch(KEY_MODULES)
	return true


## Buy one module into the inventory (CONTRACTS section 12, P2-B1). `cost` is the
## catalogue's own price, passed by the caller exactly as `buy_ammo` and
## `buy_ship` take theirs (17 section 5 item 4 keeps the price in the
## catalogue and out of the UI, so the one caller that reads it passes it in).
## 17 section 5's transaction law, all-or-nothing: verify (an id the catalogue
## does not ship, or a negative cost, is `unknown_id`), charge
## (`insufficient_credits` when the balance is short), give (`add_module` once),
## emit (`&"credits"` when the charge moved credits, then `&"modules"` from the
## add) and log — exactly one `economy_log` line, and a refused purchase writes
## no credits, no inventory and no line.
func buy_module(module_id: StringName, cost: int) -> bool:
	if ModuleData.module(module_id).is_empty() or cost < 0:
		return _refuse(REASON_UNKNOWN, module_id)
	if not _charge(cost):
		return _refuse(REASON_INSUFFICIENT, module_id)
	add_module(module_id, 1)
	Log.append(EVENT_BUY_MODULE, module_id, 1, -cost, _credits)
	return true


## ---------------------------------------------------------------- instances
##
## A module instance is 15 section 6/8's record, keyed by its own minted id in
## `_modules`:
##
##     mod_0007 -> {instance_id: "mod_0007", base_id: "s_heavy", rarity: "magic",
##                  prefixes: [{id, value}], suffixes: [id], count: 1}
##
## `count` is 1 while the instance sits in the bag and 0 while it is fitted, and a
## fitted record is **never erased** (CONTRACTS section 15): `instance` still
## answers its affixes and REMOVE/SWAP hand the *same* instance back. A `count`-0
## record is invisible to `instances_of`, to every `OWNED x<n>` aggregate and to
## `sell_instance`.
##
## A record keyed by its own base id -- every pre-instance inventory entry, and
## every `add_module` -- is that same shape with `instance_id` and `base_id` both
## the base, so an account that never bought a rolled module reads exactly as it
## always did (CONTRACTS section 11's own tolerance), and a fit that stores base
## ids is still a fit the launch, the panels and every judgement understand.


## Mint one instance of `base_id` into the bag at `count` 1: 15 section 8's
## creation entry point for anything that already knows the rarity (a seeded test,
## a future drop table, the shipyard's always-Common build). `rarity` is one of
## 15 section 1's three ids; `prefixes` and `suffixes` are 15 section 3/4's rows in
## the shape the record keeps (`[{id, value}]` and `[id]`), and a plain id is
## accepted and kept. Answers the minted id, or `&""` -- writing nothing -- for a
## blank base id or a rarity outside 15 section 1's three.
func add_instance(
	base_id: StringName, rarity: StringName, prefixes: Array, suffixes: Array
) -> StringName:
	if base_id == &"" or not ModuleData.RARITY_ORDER.has(String(rarity)):
		return &""
	var id := _mint_instance_id()
	_modules[id] = _instance_record(id, String(base_id), String(rarity), prefixes, suffixes, 1)
	_touch(KEY_MODULES)
	return StringName(id)


## One inventory record (15 section 6), `{}` for an id the bag does not carry, as a
## deep copy so a caller cannot reach into account state. A **fitted** instance
## (`count` 0) is still answered: the record survives its fitting, which is what
## lets a panel show the rolled name of the module in a cell.
func instance(id: StringName) -> Dictionary:
	var record := _module_record(id)
	if record.is_empty():
		return {}
	return record.duplicate(true)


## The ids of the instances of `base_id` that are **in the bag** (`count` 1), in
## creation order: the mint order for a live profile, the file's own order for a
## loaded one. A fitted instance is out of the bag and does not appear.
func instances_of(base_id: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	if base_id == &"":
		return ids
	for key: Variant in _modules:
		var record: Variant = _modules[key]
		if not record is Dictionary:
			continue
		var entry: Dictionary = record
		if int(entry.get(KEY_COUNT, 0)) <= 0:
			continue
		if StringName(str(entry.get(KEY_BASE_ID, key))) == base_id:
			ids.append(StringName(str(key)))
	return ids


## Roll one instance of `base_id` from `source`'s 15 section 2 table and put it in
## the bag: the creation path for a drop, a derelict, an arena reward or a crafted
## module (15 section 8: "a roll happens when an instance is created"). Reads the
## **global** RNG -- tests seed it first -- and answers the minted id, or `&""`
## writing nothing when the catalogue does not ship the base id or the source is not
## one of `ModuleCatalog.SOURCE_ROLLS`' rows. The outcome persists in the record
## and is never re-rolled (15 section 6).
func roll_instance(base_id: StringName, source: StringName) -> StringName:
	if ModuleData.module(base_id).is_empty():
		return &""
	var rarity := ModuleData.roll_rarity(source, base_id)
	if rarity == "":
		return &""
	var affixes := ModuleData.roll_affixes(base_id, rarity)
	return add_instance(base_id, StringName(rarity), affixes["prefixes"], affixes["suffixes"])


## The AUCTION shelf's restock draw (15 section 8: "auction modules when the shelf
## is drawn at restock"): the same roll as `roll_instance`, but the record is handed
## back **instead of entering the bag**, because a listing is not owned until it is
## bought. It does take the next `mod_%04d` -- CONTRACTS section 15: "every roll --
## inventory, drop, shelf listing -- takes the next number" -- so the counter moves
## even if the listing is later discarded at restock (it never rewinds). The caller
## keeps the record on the shelf through `set_auction`; `{}` for the two refusals
## `roll_instance` has, and for those the counter does not move either.
func roll_listing(base_id: StringName, source: StringName) -> Dictionary:
	if ModuleData.module(base_id).is_empty():
		return {}
	var rarity := ModuleData.roll_rarity(source, base_id)
	if rarity == "":
		return {}
	var affixes := ModuleData.roll_affixes(base_id, rarity)
	var id := _mint_instance_id()
	_mark_dirty()
	return _instance_record(id, String(base_id), rarity, affixes["prefixes"], affixes["suffixes"], 1)


## Buy one listing off the shelf, at the price the row shows (CONTRACTS section 15):
## charges `cost` and **moves** the record from the shelf into the bag at `count` 1.
## 17 section 5's transaction law, all-or-nothing: verify (an id the shelf does not
## list, or a negative cost, is `unknown_id`), charge (`insufficient_credits` when
## the balance is short), give, emit and log. A refusal writes no credits, moves no
## record and logs nothing. The price is the caller's arithmetic -- 09 list x 15
## section 1's rarity multiplier, 10 section 2.1's hot slot applied after
## (`ModuleCatalog.list_price` / `hot_price`) -- taken here as the number the row
## shows, exactly as `buy_module` takes its catalogue price.
func buy_instance(id: StringName, cost: int) -> bool:
	var listing := _listing_record(id)
	if listing.is_empty() or cost < 0:
		return _refuse(REASON_UNKNOWN, id)
	if not _charge(cost):
		return _refuse(REASON_INSUFFICIENT, id)
	var key := String(id)
	_remove_listing(key)
	listing[KEY_COUNT] = 1
	_modules[key] = listing
	_touch(KEY_MODULES)
	var base := StringName(str(listing.get(KEY_BASE_ID, key)))
	Log.append(EVENT_BUY_MODULE, base, 1, -cost, _credits)
	return true


## Sell one instance out of the bag for 15 section 6's `base x rarity multiplier x
## 60 %` (`Auction.sell_price`, CONTRACTS section 20: the same function the sell row
## and the transaction quote read, so the payout carries 15 section 4's Ledger term
## exactly when the displayed price does), paid immediately, the record erased -- the
## counter never rewinds, so the next mint still moves forward. Refuses, writing
## nothing and paying nothing, for an id the bag does not carry, for a **fitted**
## instance (`count` 0 is invisible to a sale, CONTRACTS section 15; the reason is
## the nearest shipped one, `unknown_id`, since CONTRACTS section 12 rule 1 forbids
## a new wording) and for a base id the catalogue cannot price. A stacked entry (a
## base-keyed record with `count > 1`) sells one unit, exactly as `take_module`
## takes one.
func sell_instance(id: StringName) -> bool:
	var record := _module_record(id)
	var held := maxi(0, int(record.get(KEY_COUNT, 0)))
	if record.is_empty() or held <= 0:
		return _refuse(REASON_UNKNOWN, id)
	var base := StringName(str(record.get(KEY_BASE_ID, "")))
	var price := AuctionData.sell_price(
		base,
		StringName(str(record.get(KEY_RARITY, ""))),
		_affix_names(record.get(KEY_SUFFIXES, []))
	)
	if price <= 0:
		return _refuse(REASON_UNKNOWN, id)
	var key := String(id)
	if held <= 1:
		_modules.erase(key)
	else:
		record[KEY_COUNT] = held - 1
		_modules[key] = record
	_touch(KEY_MODULES)
	add_credits(price)
	Log.append(EVENT_SELL_MODULE, base, 1, price, _credits)
	return true


## 1 -> 0: take one instance out of the bag and into a fit (CONTRACTS section 15).
## The **record survives** at `count` 0, so the fitted instance keeps its affixes
## and `restore_instance` can hand the same one back. False, writing nothing, for an
## id the bag does not carry or one that is already out of it; a stacked entry gives
## up one unit, like `take_module`.
func take_instance(id: StringName) -> bool:
	var record := _module_record(id)
	var held := maxi(0, int(record.get(KEY_COUNT, 0)))
	if record.is_empty() or held <= 0:
		return false
	record[KEY_COUNT] = held - 1
	_modules[String(id)] = record
	_touch(KEY_MODULES)
	return true


## 0 -> 1: the fitted instance comes back into the bag, the *same* instance (15
## section 8's "REMOVE/SWAP hands the same instance back", L80's cure): same id,
## same rarity, same affixes, never a fresh mint. False, writing nothing, for an id
## the bag does not carry or one that is already in it (`count` is not 0).
func restore_instance(id: StringName) -> bool:
	var record := _module_record(id)
	if record.is_empty() or int(record.get(KEY_COUNT, 0)) != 0:
		return false
	record[KEY_COUNT] = 1
	_modules[String(id)] = record
	_touch(KEY_MODULES)
	return true


## The same fit with every cell exchanged for the base catalogue id behind it, in
## `fit_for`'s own cell shape and the input's own key spelling. A fit cell holds an
## **instance** id (15 section 8) while `ShipFit` reads base ids, so this is the
## translation every fit judgement goes through: the two composed transactions
## below and the three panels that preview a fit (CONTRACTS section 15) -- without
## it `fit_legal` scores an instance as draw 0, and two instances of a
## duplicate-guarded module would read as two different modules. An entry the bag
## does not carry (a plain base id, a delivered module) comes back unchanged, so a
## fit of base ids translates to itself and a pre-instance fixture keeps working.
func base_fit(fit: Dictionary) -> Dictionary:
	var translated: Dictionary = {}
	for key: Variant in fit:
		var value: Variant = fit[key]
		if value is Array:
			var cells: Array = []
			for entry: Variant in (value as Array):
				cells.append(String(base_module_id(StringName(str(entry)))))
			translated[key] = cells
		elif value is String or value is StringName:
			translated[key] = String(base_module_id(StringName(value)))
		else:
			translated[key] = value
	return translated


## The AUCTION shelf's state (CONTRACTS section 15): `{last_band: int,
## hulls: Array[String], modules: Dictionary, hot: StringName}`, a deep copy, so a
## caller cannot reach into the store. `modules` holds the shelf's rolled listings
## keyed by their minted instance id, each an ordinary instance record, and `hot`
## names the one listing 10 section 2.1 discounts. The four keys are always present,
## at their defaults for an account that has never restocked.
func auction() -> Dictionary:
	return _auction.duplicate(true)


## Replace the shelf: normalised to the four pinned members and their types, with
## every listing an instance record. Silent when the write changes nothing, like
## every other store setter here. The shelf is written by the restock and read by
## the pane through `auction`'s copy -- never mutated through that copy.
func set_auction(state: Dictionary) -> void:
	var candidate := _normalise_auction(_to_plain(state))
	if candidate == _auction:
		return
	_auction = candidate
	_mark_dirty()


## The save v6 migration and its one-way door (15 section 8, CONTRACTS section 15):
## every v5 `{base_id, count}` record in the bag becomes `count` **Common**
## instances -- v5 stock was never rolled, so Common with no affixes is the honest
## default -- each with its own minted id, and the old key goes with them. Answers
## how many instances were created: 0 for a bag whose records all carry an
## `instance_id` (every v6 file), 0 for an empty bag, and 0 again on a second call,
## which is the idempotence the pin asks for. `_load_profile` is its only production
## caller, for a file whose save_version is below 6, after the v5 retirement has
## run (whose own `add_module` calls already write v6 records, so they are skipped).
func migrate_module_instances() -> int:
	var migrated := 0
	var changed := false
	for raw_key: Variant in _modules.keys():
		var key := String(raw_key)
		var stored: Variant = _modules.get(key, null)
		if not stored is Dictionary:
			continue
		var record: Dictionary = stored
		if record.has(KEY_INSTANCE_ID):
			continue
		var base := StringName(str(record.get(KEY_BASE_ID, key)))
		if base == &"":
			continue
		var count := maxi(0, int(record.get(KEY_COUNT, 0)))
		_modules.erase(key)
		changed = true
		for _index: int in count:
			add_instance(base, ModuleData.RARITY_COMMON, [], [])
			migrated += 1
	if changed:
		_mark_dirty()
	return migrated


func fits() -> Dictionary:
	return _fits.duplicate(true)


func set_fits(value: Dictionary) -> void:
	var candidate: Dictionary = _to_plain(value)
	if candidate == _fits:
		return
	_fits = candidate
	_touch(KEY_FITS)


## One hull's fit in the addressing shape of 09 section 4.5 (CONTRACTS section
## 11): every list type is an Array[String] exactly `ShipFit.slot_capacity` long
## (`""` = an empty cell, the tail padded) and `power` is one module id, because
## POWER is one slot and not a set. The index is the layout index: the cells of
## one type numbered row-major from the grid's top-left. The keys are the
## `ShipFit.FIT_SLOT_KEYS` StringNames, and either spelling reads them, because
## String and StringName are interchangeable as Dictionary keys.
##
## A v1-v3 file stores one id per slot type: it is read as a one-element array
## and padded to capacity, `engine` is read as `engines` (CONTRACTS section 11
## rule 2), and nothing is written back - the file keeps the shape it was saved
## with until something mutates the fit. A hull the account holds no fit for
## answers the all-empty shape, so the caller decides whether to fall back to
## `ShipFit.standard_fit` (09 section 9); {} comes back only for a hull id that
## is not one of the nine player hulls - an NPC hull fits nothing (CONTRACTS
## section 11 rule 6).
func fit_for(ship_id: StringName) -> Dictionary:
	if not FitData.HULLS.has(ship_id):
		return {}
	var stored := _fit_entry(ship_id)
	return _normalise_fit(ship_id, stored, stored, true)


## The fit this hull would launch with, in `fit_for`'s own shape: the account's
## stored fit when it holds any module at all, and 09 section 9's
## `ShipFit.standard_fit` otherwise. That is the launch's own fallback - the
## launch resolves the hull's stored fit and hands the empty one to
## `ShipFit.standard_fit` (`game.gd:_launch_fit_for`) - so a caller that previews
## against this accessor previews against the fit the launch flies, and the two
## composed transactions below compose their candidate from the same shape.
## `{}` still comes back for a hull outside the nine, exactly as `fit_for`
## answers it (an NPC hull fits nothing).
func resolved_fit(ship_id: StringName) -> Dictionary:
	var stored := fit_for(ship_id)
	if _holds_a_module(stored):
		return stored
	return FitData.standard_fit(ship_id)


## The affixes this hull's fitted instances carry, summed per prefix, with one row
## per fitted instance (CONTRACTS section 20): the bridge `game.gd`'s launch hands
## to `ShipFit.resolve`'s optional `affixes` parameter. `game/affixes.gd` owns the
## walk -- this is the autoload's own spelling of it, so the launch reads the
## summary off the profile the way it reads the fit.
func affix_summary(ship_id: StringName) -> Dictionary:
	return Affixes.summary(self, ship_id)


## Replace one hull's whole fit. Every type is normalised to the hull's own
## shape - a type the caller omits comes back empty, a longer tail is cut at
## capacity - and the write persists the array shape of save v4. An unknown hull
## id (an NPC, or a typo) is refused without writing.
##
## Legality is not checked here: 09 section 4's capacity, power-budget and
## duplicate rules are `ShipFit.fit_legal`'s, and the fitting panel (P2-B) is
## the layer that refuses an overload, so the store keeps what it is handed at
## the hull's shape rather than silently dropping a module.
func set_fit(ship_id: StringName, fit: Dictionary) -> bool:
	if not FitData.HULLS.has(ship_id):
		return false
	var stored := _fit_entry(ship_id)
	var normalised := _normalise_fit(ship_id, fit, stored)
	if stored == normalised:
		return true
	_fits[String(ship_id)] = normalised
	_touch(KEY_FITS)
	return true


## Write one cell, addressed by 09 section 4.5's layout index. Refused, without
## writing, for an unknown hull, for a slot type the hull has no cell of, and for
## an index outside 0 .. capacity-1 - a cell's index is its position among the
## cells of its own type, so a gap in the middle of the grid never takes one.
## `&""` empties the cell.
##
## The module id is not validated: a fit stores an instance id (15 section 6)
## whose base id `base_module_id` resolves, so only the caller knows the
## catalogue that id came from.
func set_fit_slot(
	ship_id: StringName, slot_key: StringName, index: int, module_id: StringName
) -> bool:
	if not FitData.HULLS.has(ship_id) or not FitData.FIT_SLOT_KEYS.has(slot_key):
		return false
	if index < 0 or index >= FitData.slot_capacity(ship_id, slot_key):
		return false
	var stored := _fit_entry(ship_id)
	var normalised := _normalise_fit(ship_id, stored, stored)
	var key: Variant = _key_for(stored, slot_key)
	if slot_key == POWER_SLOT:
		normalised[key] = String(module_id)
	else:
		var cells: Array = normalised[key]
		cells[index] = String(module_id)
		normalised[key] = cells
	if stored == normalised:
		return true
	_fits[String(ship_id)] = normalised
	_touch(KEY_FITS)
	return true


## Drop one hull's stored fit; the hull stays owned. A launch for that hull then
## falls back to `ShipFit.standard_fit` (09 section 9). Silent when the account
## held no fit for the hull, like every other no-op setter.
func clear_fit(ship_id: StringName) -> void:
	var key := String(ship_id)
	if not _fits.has(key):
		return
	_fits.erase(key)
	_touch(KEY_FITS)


## The composed install behind the FITTING panel's ACTION (09 section 4 item 9,
## CONTRACTS section 13): one cell of one hull, filled out of the module
## inventory, in one transaction. Refused, with nothing written, when the hull is
## not one of the nine, the slot key is not in `FitData.FIT_SLOT_KEYS`, the index
## is outside 0 .. `slot_capacity`-1, the account holds no `module_id`, or the
## candidate fit fails `FitData.fit_legal` - the candidate being
## `resolved_fit(ship_id)` (the launch's own fallback, see above) with that one
## cell set to `module_id`, so the panel's preview of the same cell is judged on
## exactly the fit this call writes.
##
## A cell holds the *entry* the caller names - an instance id from the bag, or a
## base id - and the legality judgement reads every cell through `base_fit`
## (CONTRACTS section 15). So an instance of a module fits exactly as its base
## does, two instances of a duplicate-guarded module are still a duplicate, and the
## launch's own fit (which resolves base ids itself) is the fit the panel
## previewed.
##
## On success, in this order: the displaced entry, when the cell was not empty,
## returns to the inventory through `_bank_entry` (an instance taken for fitting
## comes back as the *same* instance; anything else enters through `add_module`),
## so a swap can never lose it; `take_instance` takes the incoming one; the
## candidate is written whole with
## `set_fit` - the launch's fit with that one cell set, which is the same write
## `set_fit_slot` makes once that fit is the stored one, and a hull with no stored
## fit keeps the launch's mandatory cells instead of being left a one-module fit
## that would fly lacking them; one `EVENT_FIT_MODULE` line goes to the economy
## log; and the fit and the inventory both signal. Every refusal precedes every
## write, so a refused transaction leaves the credits, the inventory and the fit
## exactly as they were.
func fit_module_at(
	ship_id: StringName, slot_key: StringName, index: int, module_id: StringName
) -> bool:
	if not _fit_cell_exists(ship_id, slot_key, index):
		return false
	if module_count(module_id) == 0:
		return false
	var base := resolved_fit(ship_id)
	var candidate := _with_cell(base, slot_key, index, module_id)
	# The candidate is judged on its **base ids** (CONTRACTS section 15): the cell
	# holds an instance id, so `fit_legal` would score it as draw 0 and would miss
	# two instances of one duplicate-guarded module. The write below keeps the
	# instance ids.
	if not bool(FitData.fit_legal(ship_id, base_fit(candidate))[&"legal"]):
		return false
	var stored := _fit_entry(ship_id)
	var displaced := StringName(_cell_id(fit_for(ship_id), slot_key, index))
	if displaced != &"":
		_bank_entry(displaced)
	take_instance(module_id)
	set_fit(ship_id, candidate)
	_announce_fit(ship_id, stored)
	Log.append(EVENT_FIT_MODULE, module_id, 1, 0, _credits)
	return true


## The composed remove behind the FITTING panel's per-cell ACTION (09 section 4
## item 10, CONTRACTS section 13): the cell's module goes back to the inventory
## through `_bank_entry` and the cell is written `&""`. The hull, slot-key and
## index guards are `fit_module_at`'s, plus the mandatory set: a key in
## `FitData.MANDATORY_SLOT_KEYS` is refused before anything else, so the engines
## and the reactor of a delivered hull can be swapped but never emptied (09
## section 4.1). A cell that holds nothing is refused too - there is no module to
## return, and the log line the success path owes would be a phantom one.
##
## The cell's own module is read from the stored fit (`fit_for`), not from the
## launch's: only a module the stored fit holds goes back to the inventory, so
## this call can never hand over a delivered module the account has not got. The
## candidate the write persists is composed from `resolved_fit(ship_id)` instead
## - the launch's own fallback, `fit_module_at`'s own read - so both transactions
## judge the shape the panel previews. Anywhere the read above succeeds the stored
## fit holds a module, so the two reads are the same fit and this write is the
## `set_fit_slot` write, whole.
##
## On success: the same instance back (or the same base-keyed entry), the cell
## empty, one `EVENT_FIT_MODULE` line (the
## module id, qty 1, delta 0 - the log's own shape; the panel's footer carries
## the words), and both keys signal.
func clear_fit_slot(ship_id: StringName, slot_key: StringName, index: int) -> bool:
	if not _fit_cell_exists(ship_id, slot_key, index):
		return false
	if FitData.MANDATORY_SLOT_KEYS.has(slot_key):
		return false
	var module_id := StringName(_cell_id(fit_for(ship_id), slot_key, index))
	if module_id == &"":
		return false
	var candidate := _with_cell(resolved_fit(ship_id), slot_key, index, &"")
	# Judged on base ids, exactly as `fit_module_at` judges its candidate.
	if not bool(FitData.fit_legal(ship_id, base_fit(candidate))[&"legal"]):
		return false
	var stored := _fit_entry(ship_id)
	_bank_entry(module_id)
	set_fit(ship_id, candidate)
	_announce_fit(ship_id, stored)
	Log.append(EVENT_FIT_MODULE, module_id, 1, 0, _credits)
	return true


## The S4 bulk wrappers (CONTRACTS section 16 rules 7-8): the batch behind the
## OUTFITTING strip's `FIT ALL` / `SWAP ALL` and its `REMOVE ALL`. Both loop the
## two composed transactions above, one call per cell, so every per-cell guard,
## every log line and both `profile_changed` keys are the composed calls' own.
##
## **The batch is atomic over the fit *and* the bag.** `fit_for` and `modules()`
## are snapshotted before the first cell and, on any refusal, both are restored
## through the public `set_fit` and `set_modules`, so a half-filled battery is
## never left behind and no instance is ever stranded at `count` 0 (the L80
## class, CONTRACTS section 15).
##
## The guards answer `false` writing nothing: a hull outside the nine or a
## W-less hull (0 capacity), an index outside `0 .. slot_capacity-1`, a repeated
## index (a cell is one barrel), an empty index list, and a bag that carries
## fewer instances than there are cells. A cell whose own `fit_module_at`
## refuses after earlier cells were fitted rolls the whole batch back.
##
## `instances_of(base_id)` is the pairing source (CONTRACTS section 16 rule 7):
## the base's in-bag instances in creation order, one per cell taken in ascending
## order. A fitted instance is out of the bag, which is what makes `SWAP ALL` a
## re-seat rather than a duplicate.
func fit_battery(ship_id: StringName, base_id: StringName, indices: Array) -> bool:
	if base_id == &"" or indices.is_empty():
		return false
	var capacity := FitData.slot_capacity(ship_id, WEAPON_SLOT)
	if capacity <= 0:
		return false
	var cells: Array[int] = []
	for raw: Variant in indices:
		var index := int(raw)
		if index < 0 or index >= capacity or cells.has(index):
			return false
		cells.append(index)
	cells.sort()
	var bag := instances_of(base_id)
	if bag.size() < cells.size():
		return false
	var fit_before := fit_for(ship_id)
	var bag_before := modules()
	var had_fit := fits().has(String(ship_id))
	for position in cells.size():
		if not fit_module_at(ship_id, WEAPON_SLOT, cells[position], bag[position]):
			_restore_fit_and_bag(ship_id, fit_before, bag_before, had_fit)
			return false
	return true


## The bulk remove (CONTRACTS section 16 rule 8): empties exactly the cells of
## this hull whose **stored** entry resolves through `base_module_id` to
## `base_id`, one `clear_fit_slot` per cell, ascending. A hull that holds no such
## cell - and any hull outside the nine - answers `false` writing nothing, so the
## pane renders a refusal rather than a silent success; a refused cell rolls the
## whole batch back, so a battery is never half-banked.
##
## The cells are read from `fit_for`, not from `resolved_fit`: only a module the
## stored fit holds goes back to the inventory, which is the same read
## `clear_fit_slot` makes per cell.
func clear_battery(ship_id: StringName, base_id: StringName) -> bool:
	if base_id == &"":
		return false
	var capacity := FitData.slot_capacity(ship_id, WEAPON_SLOT)
	if capacity <= 0:
		return false
	var fit_before := fit_for(ship_id)
	var cells: Array[int] = []
	for index in capacity:
		var entry := StringName(_cell_id(fit_before, WEAPON_SLOT, index))
		if entry != &"" and base_module_id(entry) == base_id:
			cells.append(index)
	if cells.is_empty():
		return false
	var bag_before := modules()
	var had_fit := fits().has(String(ship_id))
	for index in cells:
		if not clear_fit_slot(ship_id, WEAPON_SLOT, index):
			_restore_fit_and_bag(ship_id, fit_before, bag_before, had_fit)
			return false
	return true


## The batch rollback both wrappers share: the fit whole through `set_fit` and
## the bag whole through `set_modules` (CONTRACTS section 16 rules 7-8, the two
## public writers), so a refused batch leaves the account exactly where it
## started. A hull that held no stored fit before the batch has that fit dropped
## again through `clear_fit` instead of being written back empty, so the restore
## is exact rather than merely equivalent.
func _restore_fit_and_bag(
	ship_id: StringName, fit_before: Dictionary, bag_before: Dictionary, had_fit: bool
) -> void:
	if had_fit:
		set_fit(ship_id, fit_before)
	else:
		clear_fit(ship_id)
	set_modules(bag_before)


## ------------------------------------------------------------- batteries (v7)
##
## A **battery** is a player-composed rack of W cells (09 section 11, CONTRACTS
## section 17): `weapon_1..7` addresses a rack, a rack may hold mixed weapon kinds,
## and the salvo gate is its slowest member's cycle. The record is
## `{ship_id: Array[Array[cell_ref]]}` -- a hull's racks in order, each one the
## layout indices (09 section 4.5) of the barrels that fire together -- and the fit
## stays the authority on what each cell holds, so a rack entry is a *reference* and
## never a second copy of the fit.


## Every hull's racks, a deep copy: `{ship_id: Array[Array[int]]}`, keys as Strings
## (what a `ConfigFile` gives back). Empty until save v7's migration has run.
func batteries() -> Dictionary:
	return _batteries.duplicate(true)


## Replace the whole record. Normalised first -- keys as Strings, every index an int
## inside its hull's W cells, no cell twice, no trailing empty rack -- so a fixture
## that hands in a stranger (`{&"ship_vanguard": [[0, 1]]}`, a hull the nine do not
## carry) is read in the canonical shape and a second identical set stays silent, the
## same contract `set_modules` and `set_fits` keep.
func set_batteries(value: Dictionary) -> void:
	var candidate := _normalise_batteries(_to_plain(value))
	if candidate == _batteries:
		return
	_batteries = candidate
	_touch(KEY_BATTERIES)


## One hull's racks as the pane, the launch and the HUD read them: the stored racks
## in their stored order, each one **restricted to the cells the hull's fit really
## holds a weapon in**, followed by one trailing rack holding every fitted weapon the
## record does not mention. The two rules together are what keeps the invariant the
## trigger needs -- every fitted weapon fires from exactly one rack, so a weapon can
## never be unfireable -- and they are also why this reads the fit: a cell the
## FITTING pane filled after the racks were composed joins a rack the moment it is
## read, without a write (`fit_for`'s own "never rewritten at load" rule). `[]` for a
## hull outside the nine and for a W-less hull.
func battery_groups(ship_id: StringName) -> Array:
	var capacity := FitData.slot_capacity(ship_id, WEAPON_SLOT)
	if capacity <= 0:
		return []
	var fitted: Array = resolved_fit(ship_id).get(WEAPON_SLOT, [])
	var covered: Dictionary = {}
	var groups: Array = []
	for stored: Variant in _stored_groups(ship_id):
		if not stored is Array:
			continue
		var rack: Array = []
		for raw_index: Variant in (stored as Array):
			var index := int(raw_index)
			if index < 0 or index >= capacity or covered.has(index):
				continue
			if not _cell_holds_weapon(fitted, index):
				continue
			covered[index] = true
			rack.append(index)
		groups.append(rack)
	var unassigned: Array = []
	for index in capacity:
		if not covered.has(index) and _cell_holds_weapon(fitted, index):
			unassigned.append(index)
	if not unassigned.is_empty():
		groups.append(unassigned)
	return groups


## Replace one hull's racks. Refused, writing nothing, when the hull is not one of
## the nine, when the record carries more racks than `GROUPS_MAX` (the input map's
## own ceiling, `game/weapons.gd`), or when any index is outside the hull's W cells
## or repeated across racks -- a cell is one barrel and fires from one rack. An empty
## rack inside the list is kept (it is a drop zone the player emptied), a trailing
## empty rack is dropped (it carries no identity). The record is `_to_plain`-keyed
## like every other store here.
func set_battery_groups(ship_id: StringName, groups: Array) -> bool:
	if not FitData.HULLS.has(ship_id):
		return false
	if groups.size() > WeaponData.GROUPS_MAX:
		return false
	var capacity := FitData.slot_capacity(ship_id, WEAPON_SLOT)
	var racks: Array = []
	var seen: Dictionary = {}
	for raw_rack: Variant in groups:
		if not raw_rack is Array:
			return false
		var rack: Array = []
		for raw_index: Variant in (raw_rack as Array):
			var index := int(raw_index)
			if index < 0 or index >= capacity or seen.has(index):
				return false
			seen[index] = true
			rack.append(index)
		racks.append(rack)
	while not racks.is_empty() and (racks[racks.size() - 1] as Array).is_empty():
		racks.remove_at(racks.size() - 1)
	var candidate := _batteries.duplicate(true)
	if racks.is_empty():
		candidate.erase(String(ship_id))
	else:
		candidate[String(ship_id)] = racks
	if candidate == _batteries:
		return true
	_batteries = candidate
	_touch(KEY_BATTERIES)
	return true


## The next free W cell of a hull: the lowest layout index whose cell holds nothing,
## or -1 when every W cell carries a weapon (or the hull has no W cell). Read off
## `resolved_fit` -- the fit the launch flies -- so a hull the account holds no
## stored fit for reserves the cells its delivered fit fills instead of re-issuing
## them, which is exactly the shape the ARMORY pane draws.
func free_weapon_cell(ship_id: StringName) -> int:
	var capacity := FitData.slot_capacity(ship_id, WEAPON_SLOT)
	if capacity <= 0:
		return -1
	var fitted: Array = resolved_fit(ship_id).get(WEAPON_SLOT, [])
	for index in capacity:
		if not _cell_holds_weapon(fitted, index):
			return index
	return -1


## The drag's install (09 section 11, CONTRACTS section 17): one weapon into one free
## W cell of one hull, recorded in that rack. `module_id` is a base id or a bag
## instance id (`base_module_id` resolves it) and the instance that lands in the cell
## is the next in-bag instance of that base, paired by `fit_battery` -- the one route
## that pairs `instances_of` into cells and is atomic over the fit and the bag
## (CONTRACTS section 16 rule 7).
##
## Refused, writing nothing, when the hull is not one of the nine, the rack is outside
## `0 .. GROUPS_MAX-1`, the cell is outside the hull's W cells or already holds a
## weapon (a drag onto a barrel is a **swap**, `move_rack_cell`), the base is not a
## weapon module, the bag holds none of it, or the candidate fit fails
## `FitData.fit_legal` -- the mandatory set and the power budget are `fit_battery`'s
## own guards, checked before its first write. A refusal anywhere after the batch's
## first cell restores the fit **and** the bag **and** the record, so a refused drag
## leaves the account exactly where it was.
func fit_into_rack(
	ship_id: StringName, rack: int, index: int, module_id: StringName
) -> bool:
	if not FitData.HULLS.has(ship_id) or not _fit_cell_exists(ship_id, WEAPON_SLOT, index):
		return false
	## The mandatory set is checked before anything else, as 09 section 4.10 requires of
	## every panel-driven write. It is **unreachable for a W cell** (measured:
	## `FitData.MANDATORY_SLOT_KEYS` is `[engines, power]`), and it is here so the guard
	## lives in the transaction rather than in the caller that cannot express it.
	if FitData.MANDATORY_SLOT_KEYS.has(WEAPON_SLOT):
		return false
	if rack < 0 or rack >= WeaponData.GROUPS_MAX:
		return false
	var base := base_module_id(module_id)
	if not _is_weapon_base(base):
		return false
	if _cell_holds_weapon(resolved_fit(ship_id).get(WEAPON_SLOT, []), index):
		return false
	var fit_before := fit_for(ship_id)
	var bag_before := modules()
	var had_fit := fits().has(String(ship_id))
	var groups_before := batteries()
	if not fit_battery(ship_id, base, [index]):
		return false
	var groups := battery_groups(ship_id)
	while groups.size() <= rack:
		groups.append([])
	for position in groups.size():
		var rack_cells: Array = groups[position]
		rack_cells.erase(index)
		groups[position] = rack_cells
	var target: Array = groups[rack]
	target.append(index)
	groups[rack] = target
	if set_battery_groups(ship_id, groups):
		return true
	_restore_fit_and_bag(ship_id, fit_before, bag_before, had_fit)
	set_batteries(groups_before)
	return false


## The ✕ (09 section 11): the barrel leaves its rack and its cell returns to the bag.
## One `clear_fit_slot` -- the composed per-cell remove, so the same guards, the same
## instance handed back and the same log line -- plus the record update, atomic over
## both. Refused, writing nothing, when the hull is not one of the nine, the cell is
## outside the hull's W cells, the cell is empty, or the cell's key were mandatory
## (unreachable for a W cell, measured: `FitData.MANDATORY_SLOT_KEYS` is
## `[engines, power]`, and kept because 09 section 4.10 makes the mandatory set
## inviolable from a panel).
func clear_rack_cell(ship_id: StringName, index: int) -> bool:
	if not _fit_cell_exists(ship_id, WEAPON_SLOT, index):
		return false
	if FitData.MANDATORY_SLOT_KEYS.has(WEAPON_SLOT):
		return false
	if _cell_id(fit_for(ship_id), WEAPON_SLOT, index) == "":
		return false
	var fit_before := fit_for(ship_id)
	var bag_before := modules()
	var had_fit := fits().has(String(ship_id))
	var groups_before := batteries()
	if not clear_fit_slot(ship_id, WEAPON_SLOT, index):
		return false
	var groups := battery_groups(ship_id)
	for position in groups.size():
		var rack: Array = groups[position]
		rack.erase(index)
		groups[position] = rack
	if set_battery_groups(ship_id, groups):
		return true
	_restore_fit_and_bag(ship_id, fit_before, bag_before, had_fit)
	set_batteries(groups_before)
	return false


## The within/between-rack drag (09 section 11: "re-orders and swaps"). Pure record
## surgery -- the cell keeps its barrel and gains a different trigger, so no fit and
## no bag write happens here. A move inside one rack re-orders it; a move between
## racks inserts the barrel at the target position and, when that position was taken,
## the displaced barrel takes the dragged one's old place (the swap). A target
## position past the end of the rack appends.
##
## Refused, writing nothing, when the hull is not one of the nine, the source address
## holds no barrel, the target rack is outside `0 .. GROUPS_MAX-1`, the target
## position is negative, or the two addresses are the same.
func move_rack_cell(
	ship_id: StringName, from_rack: int, from_position: int, to_rack: int, to_position: int
) -> bool:
	if not FitData.HULLS.has(ship_id):
		return false
	if to_rack < 0 or to_rack >= WeaponData.GROUPS_MAX or to_position < 0:
		return false
	if from_rack == to_rack and from_position == to_position:
		return false
	var groups := battery_groups(ship_id)
	if from_rack < 0 or from_rack >= groups.size():
		return false
	var source: Array = groups[from_rack]
	if from_position < 0 or from_position >= source.size():
		return false
	var moved: int = source[from_position]
	source.remove_at(from_position)
	while groups.size() <= to_rack:
		groups.append([])
	var target: Array = groups[to_rack]
	if from_rack == to_rack:
		target.insert(clampi(to_position, 0, target.size()), moved)
	else:
		if to_position >= target.size():
			target.append(moved)
		else:
			var displaced: int = target[to_position]
			target[to_position] = moved
			source.insert(clampi(from_position, 0, source.size()), displaced)
	groups[from_rack] = source
	groups[to_rack] = target
	return set_battery_groups(ship_id, groups)


## The save v7 migration (09 section 11, CONTRACTS section 17): every hull the account
## holds a **stored** fit for gets its fitted weapons grouped by base id, cells
## ascending -- S4's strip grouping, now persisted as racks, which is the shape a v6
## file's play already had. Idempotent: a hull whose record already accounts for every
## fitted weapon is left alone, so a second call changes nothing and neither does one
## on a file that already carries the key. Answers how many hulls were grouped.
##
## **Memory only: the file is not rewritten here** (17 section 3's "never rewritten at
## load", the rule the v4 fitting arrays keep). The record the migration builds is
## persisted by the next write - which every rack mutation makes immediately - so a v6
## file's racks live in memory the moment it loads and on disk the moment anything is
## banked. The alternative, the v5/v6 flag days' immediate write, would rewrite a file
## whose fit shape the wave does not change; the grouping is derived data, so the
## lazier door is the honest one. **Reversal:** `_mark_dirty()` when `migrated > 0`.
##
## A hull the account holds no stored fit for is not touched: it has no fitted weapons
## of its own to group, and `battery_groups` derives its racks from the delivered fit
## on read. `_load_profile` is the only production caller, for a file below v7, and it
## runs after the v5 and v6 migrations so a base id already resolves through the
## canonical instance records.
func migrate_batteries() -> int:
	var migrated := 0
	for key: Variant in _fits.keys():
		var ship_id := StringName(str(key))
		var groups := _grouped_by_base(ship_id)
		if groups == _stored_groups(ship_id):
			continue
		_batteries[String(ship_id)] = groups
		migrated += 1
	return migrated


## One hull's fitted weapons grouped by base id, cells ascending: the migration's own
## grouping and nothing else's. The base is read through `base_module_id`, so an
## instance and its base group together, and the walk is the **stored** fit's (the
## file's own data), not the launch's fallback.
func _grouped_by_base(ship_id: StringName) -> Array:
	var capacity := FitData.slot_capacity(ship_id, WEAPON_SLOT)
	var fit := fit_for(ship_id)
	var order: Array = []
	var by_base: Dictionary = {}
	for index in capacity:
		var entry := StringName(_cell_id(fit, WEAPON_SLOT, index))
		if entry == &"":
			continue
		var base := base_module_id(entry)
		if not by_base.has(base):
			by_base[base] = []
			order.append(base)
		var rack: Array = by_base[base]
		rack.append(index)
		by_base[base] = rack
	var groups: Array = []
	for base: Variant in order:
		groups.append(by_base[base])
	return groups


## One hull's stored racks, raw: the record's own list, no fit filtering and no
## normalising, so `set_battery_groups` can compare a candidate against exactly what
## the file holds. `[]` for a hull the record does not mention.
func _stored_groups(ship_id: StringName) -> Array:
	var stored: Variant = _batteries.get(String(ship_id), null)
	if stored is Array:
		return stored
	return []


## Whether one cell of a fit holds a module at all: a W cell is a W cell whatever is in
## it, so a family-less module (`w_mining`, 09 section 4 item 7 - a tool, no firing
## family) composes into a rack like any other. Only the **component's** spec drops it
## (its barrel list has no entry for a family-less cell, §16 rule 3), and `game.gd`
## resolves that on the way in.
static func _cell_holds_weapon(fitted: Array, index: int) -> bool:
	if index < 0 or index >= fitted.size():
		return false
	return String(fitted[index]) != ""


## Whether a base id is a weapon module (the rack record's own domain): the migration
## and the pane's drag both refuse anything else, so a utility module can never enter
## a rack by accident. The one spelling is `w_` (09 section 3.1's module ids).
static func _is_weapon_base(base: StringName) -> bool:
	return String(base).begins_with(WEAPON_MODULE_PREFIX)


## The record in its canonical shape: keys as Strings, values Array[Array[int]] with
## every index inside that hull's W cells and no cell twice, racks in their stored
## order, trailing empty racks dropped, hulls outside the nine dropped. A forgiven
## reader -- a hand-edited file is read defensively the way `_read_qty` and
## `_read_vitals` read theirs -- while the writer above refuses instead.
func _normalise_batteries(source: Dictionary) -> Dictionary:
	var record: Dictionary = {}
	for key: Variant in source:
		var ship_id := StringName(str(key))
		if not FitData.HULLS.has(ship_id):
			continue
		var raw_racks: Variant = source[key]
		if not raw_racks is Array:
			continue
		var capacity := FitData.slot_capacity(ship_id, WEAPON_SLOT)
		var racks: Array = []
		var seen: Dictionary = {}
		for raw_rack: Variant in (raw_racks as Array):
			if not raw_rack is Array:
				continue
			var rack: Array = []
			for raw_index: Variant in (raw_rack as Array):
				var index := int(raw_index)
				if index < 0 or index >= capacity or seen.has(index):
					continue
				seen[index] = true
				rack.append(index)
			racks.append(rack)
		while not racks.is_empty() and (racks[racks.size() - 1] as Array).is_empty():
			racks.remove_at(racks.size() - 1)
		if not racks.is_empty():
			record[String(ship_id)] = racks
	return record


## The save v5 migration and its one-way door (09 section 4 item 13, CONTRACTS
## section 13 rule 2). Every pre-module upgrade the loaded file still records
## becomes one inventory module through `LEGACY_UPGRADE_MODULES`, and the retired
## key is dropped from the loaded file as well, so the next write cannot put it
## back. Answers how many were migrated: 0 for a file that carries no record
## (every v5 file, and a v1-v3 file, which never had the key), and 0 again on a
## second call - which is the idempotence the pin asks for. `_load_profile` is
## its only caller, for a file whose save_version is below 5.
func retire_legacy_upgrades() -> int:
	var migrated := 0
	for upgrade_id: StringName in _legacy_upgrade_ids():
		var module_id: StringName = LEGACY_UPGRADE_MODULES.get(upgrade_id, &"")
		if module_id == &"":
			continue
		add_module(module_id, 1)
		migrated += 1
	if _config.has_section_key(SECTION, KEY_RETIRED_UPGRADES):
		_config.erase_section_key(SECTION, KEY_RETIRED_UPGRADES)
		_mark_dirty()
	return migrated


func standing() -> Dictionary:
	return _standing.duplicate(true)


func set_standing(value: Dictionary) -> void:
	var candidate: Dictionary = _to_plain(value)
	if candidate == _standing:
		return
	_standing = candidate
	_touch(KEY_STANDING)


func market() -> Dictionary:
	return _market.duplicate(true)


func set_market(value: Dictionary) -> void:
	var candidate := _normalise_market(value)
	if candidate == _market:
		return
	_market = candidate
	_mark_dirty()


func heat() -> Dictionary:
	return _heat.duplicate(true)


func set_heat(value: Dictionary) -> void:
	var candidate: Dictionary = _to_plain(value)
	if candidate == _heat:
		return
	_heat = candidate
	_mark_dirty()


## One faction's heat, bounded by doc 13 section 2's 0-100 on the way out as well as on the
## way in, so a file written by an older build cannot hand a caller a value outside the
## band. A faction the record does not mention reads 0.
func heat_of(faction_id: StringName) -> int:
	return clampi(int(_heat.get(String(faction_id), 0)), HEAT_MIN, HEAT_MAX)


## One faction's standing (doc 12 section 4's -100..+100, per faction). Read by the dock
## refusal, which asks only whether it is at or below doc 12 section 4.1's Outlaw floor.
func standing_of(faction_id: StringName) -> int:
	return int(_standing.get(String(faction_id), 0))


## Doc 13 section 2's fine for one faction's heat: `heat x 25 CR`, 0 when there is nothing
## owed. The one home of the rate; the LAUNCH row prints this answer.
func bounty_fine(faction_id: StringName) -> int:
	return heat_of(faction_id) * BOUNTY_CR_PER_HEAT


## Doc 13 section 2's redemption path: pay the fine and zero that faction's heat.
##
## 17 section 5's transaction law, all-or-nothing, with the refund of every refusal: a
## zero heat (nothing to clear) or a balance short of the fine returns `false` having
## written **nothing** -- no credits, no heat, no log line. On success exactly one
## `BOUNTY` line goes to the economy log, that faction's heat reads 0 (the key stays, the
## same shape `game.gd:_apply_heat` and `_decay_heat` leave a floored faction in, so a
## record has one spelling of "clean" and every reader -- `heat_of`,
## `NpcShip._read_heat_tier` -- answers 0 for it) and the fine leaves the balance. Outlaws
## never reach this: they cannot dock to pay (12 section 4.1).
func pay_bounty(faction_id: StringName) -> bool:
	var fine := bounty_fine(faction_id)
	if fine <= 0:
		return false
	if not _charge(fine):
		return _refuse(REASON_INSUFFICIENT, faction_id)
	var cleared := heat_of(faction_id)
	var paid_off := _heat.duplicate(true)
	paid_off[String(faction_id)] = 0
	set_heat(paid_off)
	Log.append(EVENT_BOUNTY, faction_id, cleared, -fine, _credits)
	return true


## The faction whose station the account is docked at, or `&""` when it is not docked.
func docked_faction() -> StringName:
	return _docked_faction


## Set by the docking route (`game.gd:_request_dock`) so the station's LAUNCH pane can show
## the docked faction's own bounty row (doc 13 section 7). Not persisted.
func set_docked_faction(faction_id: StringName) -> void:
	_docked_faction = faction_id


func contracts() -> Array:
	return _contracts.duplicate(true)


func set_contracts(value: Array) -> void:
	var candidate: Array = _to_plain(value)
	if candidate == _contracts:
		return
	_contracts = candidate
	_mark_dirty()


func vaults() -> Dictionary:
	return _vaults.duplicate(true)


func set_vaults(value: Dictionary) -> void:
	var candidate: Dictionary = _to_plain(value)
	if candidate == _vaults:
		return
	_vaults = candidate
	_mark_dirty()


func insured() -> bool:
	return _insured


func set_insured(value: bool) -> void:
	if value == _insured:
		return
	_insured = value
	_mark_dirty()


func mercy_used() -> bool:
	return _mercy_used


func set_mercy_used(value: bool) -> void:
	if value == _mercy_used:
		return
	_mercy_used = value
	_mark_dirty()


## The stored report for one hull: {hull, shield} plus `fuel` once a launch or a
## station has filed a tank (18_engine_spec section 12 item 13). A record written
## before save v3 simply carries no fuel entry, which the launch handshake reads as
## "nothing filed" rather than as an empty tank, so a migrated profile never starts
## in Emergency Flight Mode. Deep-copied: a caller cannot mutate account state.
func vitals_of(ship_id: StringName) -> Dictionary:
	var entry: Variant = _vitals.get(String(ship_id), null)
	if entry is Dictionary:
		var stored: Dictionary = entry
		return stored.duplicate(true)
	return {}


## Files hull, shield and (save v3) the tank for one hull. Silent, like every other
## vitals write (17 section 3), except for the one channel 18_engine_spec section 12
## item 13 names: a tank reading that actually moved emits `profile_changed` with
## &"fuel". `fuel` is optional and sticky — a caller that passes none (the REPAIRS
## restore) keeps the filed tank, and a report that never carried fuel still carries
## none.
func set_vitals(ship_id: StringName, hull: int, shield: int, fuel: int = FUEL_UNFILED) -> void:
	if ship_id == &"":
		return
	var key := String(ship_id)
	var stored: Variant = _vitals.get(key, null)
	var filed := _filed_fuel(stored)
	var tank := filed if fuel < 0 else maxi(0, fuel)
	var entry: Dictionary = {
		"hull": maxi(0, hull),
		"shield": maxi(0, shield),
	}
	if tank >= 0:
		entry["fuel"] = tank
	if stored != null and stored == entry:
		return
	_vitals[key] = entry
	if tank == filed:
		_mark_dirty()
	else:
		_touch(KEY_FUEL)


func save() -> void:
	if _save_timer != null:
		_save_timer.stop()
	_dirty = true
	_write_profile()


func flush() -> void:
	if _save_timer != null:
		_save_timer.stop()
	_write_profile()


## Test/support hook: re-read the file through the current save_path.
func reload() -> void:
	_config = ConfigFile.new()
	_load_profile()


func reset_to_defaults() -> void:
	_apply_defaults()
	_touch(KEY_CREDITS)
	_touch(KEY_AMMO)
	_touch(KEY_SHIPS)
	_touch(KEY_CARGO)


func _touch(key: StringName) -> void:
	_dirty = true
	if _save_timer != null:
		_save_timer.start()
	else:
		_write_profile()
	profile_changed.emit(key)


## Dirty + debounce + write, without the signal. Used by the silent setters.
func _mark_dirty() -> void:
	_dirty = true
	if _save_timer != null:
		_save_timer.start()
	else:
		_write_profile()


func _refuse(reason: StringName, id: StringName) -> bool:
	purchase_failed.emit(reason, id)
	return false


func _charge(cost: int) -> bool:
	if cost <= 0:
		return true
	if cost > _credits:
		return false
	_credits -= cost
	_touch(KEY_CREDITS)
	return true


func _load_catalog() -> void:
	_known_ships.clear()
	for entry: Dictionary in Catalog.SHIPS:
		var ship_id: StringName = entry.get(&"id", &"")
		if ship_id != &"":
			_known_ships[ship_id] = true


func _load_profile() -> void:
	_config = ConfigFile.new()
	var err := _config.load(save_path)
	if err == ERR_FILE_NOT_FOUND:
		_apply_defaults()
		return
	if err != OK:
		push_warning("PlayerProfile: %s is unreadable (error %d); using defaults" % [save_path, err])
		_config = ConfigFile.new()
		_apply_defaults()
		return
	var version := int(_config.get_value(SECTION, "save_version", 0))
	if version < MIN_READABLE_VERSION or version > SAVE_VERSION:
		push_warning(
			"PlayerProfile: %s has save_version %d, expected %d to %d; using defaults"
			% [save_path, version, MIN_READABLE_VERSION, SAVE_VERSION]
		)
		_config = ConfigFile.new()
		_apply_defaults()
		return
	# Version 1 is a migration read: keys it never wrote fall back to their
	# defaults silently. Writes always persist SAVE_VERSION.
	_read_values()
	# Save v5's flag day (CONTRACTS section 13): the retired `upgrades` record a
	# v1-v4 file carries is converted to inventory modules right after it was
	# read, and the key goes with it. 5 is the pin's own threshold; a file that
	# already is v5 has no record to convert and the call answers 0.
	if version < 5:
		retire_legacy_upgrades()
	# Save v6's flag day (CONTRACTS section 15): the v5 `{base_id, count}` records
	# a file below v6 carries become Common instances, and the records every path
	# writes are canonical six-key ones. The retirement above runs first, and it
	# writes v6 records of its own, so the migration finds nothing to convert
	# there.
	if version < 6:
		migrate_module_instances()
	# Save v7's flag day (CONTRACTS section 17): a v6 file's racks do not exist, so
	# every hull it holds a stored fit for has its fitted weapons grouped by base id,
	# cells ascending -- S4's grouping, now persisted. It runs last of the three
	# migrations so a base id already resolves through the canonical v6 records.
	if version < 7:
		migrate_batteries()
	# Memory only: a record the file spelled short reads in the canonical shape,
	# and the file is not rewritten for it (17 section 3's "never rewritten at
	# load", the same rule the fitting arrays keep).
	_modules = _normalise_instances(_modules)


func _apply_defaults() -> void:
	_credits = DEFAULT_CREDITS
	_owned_ships.clear()
	_owned_ships.append(DEFAULT_SHIP)
	_active_ship = DEFAULT_SHIP
	_cargo.clear()
	_ammo.clear()
	for weapon: StringName in AMMO_MAX:
		_ammo[weapon] = DEFAULT_AMMO
	_modules.clear()
	_fits.clear()
	_market = _market_default()
	_heat.clear()
	_standing.clear()
	_docked_faction = &""
	_contracts.clear()
	_vaults.clear()
	_insured = false
	_mercy_used = false
	_vitals.clear()
	_instance_counter = 0
	_auction = _auction_default()
	_batteries.clear()


func _read_values() -> void:
	_credits = maxi(0, _read_int("credits", DEFAULT_CREDITS))
	_owned_ships.clear()
	_owned_ships.append_array(_read_names("owned_ships"))
	if _owned_ships.is_empty():
		_owned_ships.append(DEFAULT_SHIP)
	_active_ship = StringName(str(_config.get_value(SECTION, "active_ship", DEFAULT_SHIP)))
	if not _owned_ships.has(_active_ship):
		_active_ship = _owned_ships[0]
	_cargo = _read_qty("cargo")
	_ammo = _read_qty("ammo")
	for weapon: StringName in AMMO_MAX:
		if not _ammo.has(weapon):
			_ammo[weapon] = DEFAULT_AMMO
	_modules = _read_plain_dict("modules")
	_fits = _read_plain_dict("fits")
	_market = _normalise_market(_read_plain_dict("market"))
	_heat = _read_plain_dict("heat")
	_standing = _read_plain_dict("standing")
	_contracts = _read_plain_array("contracts")
	_vaults = _read_plain_dict("vaults")
	_insured = _read_bool("insured", false)
	_mercy_used = _read_bool("mercy_used", false)
	_vitals = _read_vitals()
	_instance_counter = maxi(0, _read_int(KEY_INSTANCE_COUNTER, 0))
	_auction = _normalise_auction(_read_plain_dict(KEY_AUCTION))
	_batteries = _normalise_batteries(_read_plain_dict(KEY_BATTERIES))


func _read_int(key: String, fallback: int) -> int:
	var raw: Variant = _config.get_value(SECTION, key, fallback)
	if raw is int or raw is float:
		return int(raw)
	if raw != null:
		push_warning("PlayerProfile: %s.%s is not a number; using %d" % [SECTION, key, fallback])
	return fallback


func _read_names(key: String) -> Array[StringName]:
	var names: Array[StringName] = []
	var raw: Variant = _config.get_value(SECTION, key, [])
	if not raw is Array:
		push_warning("PlayerProfile: %s.%s is not an array; ignored" % [SECTION, key])
		return names
	for value: Variant in raw:
		var entry_name := StringName(str(value))
		if entry_name != &"":
			names.append(entry_name)
	return names


## The installed upgrades a pre-v5 file still records, for `retire_legacy_upgrades`
## (CONTRACTS section 13). The shipped shape is the Array of ids `_write_profile`
## used to persist; a record written as a dictionary of flags reads as its truthy
## keys, so the migration's own wording ("every id whose value is true") covers
## both spellings of a hand-built fixture.
func _legacy_upgrade_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if not _config.has_section_key(SECTION, KEY_RETIRED_UPGRADES):
		return ids
	var raw: Variant = _config.get_value(SECTION, KEY_RETIRED_UPGRADES)
	if raw is Dictionary:
		var record: Dictionary = raw
		for key: Variant in record:
			if bool(record[key]):
				var flagged := StringName(str(key))
				if flagged != &"":
					ids.append(flagged)
	elif raw is Array:
		for value: Variant in raw:
			var listed := StringName(str(value))
			if listed != &"":
				ids.append(listed)
	return ids


func _read_qty(key: String) -> Dictionary:
	var quantities: Dictionary = {}
	var raw: Variant = _config.get_value(SECTION, key, {})
	if not raw is Dictionary:
		push_warning("PlayerProfile: %s.%s is not a dictionary; ignored" % [SECTION, key])
		return quantities
	var source: Dictionary = raw
	for item: Variant in source:
		var item_id := StringName(str(item))
		if item_id != &"":
			quantities[item_id] = maxi(0, int(source[item]))
	return quantities


func _read_plain_dict(key: String) -> Dictionary:
	if not _config.has_section_key(SECTION, key):
		return {}
	var raw: Variant = _config.get_value(SECTION, key, {})
	if not raw is Dictionary:
		push_warning("PlayerProfile: %s.%s is not a dictionary; ignored" % [SECTION, key])
		return {}
	var plain: Dictionary = _to_plain(raw)
	return plain


func _read_plain_array(key: String) -> Array:
	if not _config.has_section_key(SECTION, key):
		return []
	var raw: Variant = _config.get_value(SECTION, key, [])
	if not raw is Array:
		push_warning("PlayerProfile: %s.%s is not an array; ignored" % [SECTION, key])
		return []
	var plain: Array = _to_plain(raw)
	return plain


func _read_bool(key: String, fallback: bool) -> bool:
	var raw: Variant = _config.get_value(SECTION, key, fallback)
	if raw is bool:
		return raw
	if raw != null:
		push_warning("PlayerProfile: %s.%s is not a boolean; using %s" % [SECTION, key, str(fallback)])
	return fallback


func _read_vitals() -> Dictionary:
	var parsed: Dictionary = {}
	var source := _read_plain_dict("vitals")
	for ship_id: Variant in source:
		var entry: Variant = source[ship_id]
		if not entry is Dictionary:
			push_warning("PlayerProfile: vitals.%s is not a dictionary; ignored" % String(ship_id))
			continue
		var record: Dictionary = entry
		var parsed_entry: Dictionary = {
			"hull": _vital_number(record, "hull"),
			"shield": _vital_number(record, "shield"),
		}
		## Save v3 key, read only when the file carries it: an older report keeps the
		## shape it was written with, so "never filed" stays distinguishable from
		## "filed empty" (the game seeds a launch tank only from a filed reading).
		if record.has("fuel"):
			parsed_entry["fuel"] = _vital_number(record, "fuel")
		parsed[String(ship_id)] = parsed_entry
	return parsed


func _vital_number(entry: Dictionary, key: String) -> int:
	var raw: Variant = entry.get(key, 0)
	if raw is int or raw is float:
		return maxi(0, int(raw))
	push_warning("PlayerProfile: vitals entry %s is not a number; using 0" % key)
	return 0


## The tank a stored report carries, or FUEL_UNFILED when it never carried one.
func _filed_fuel(stored: Variant) -> int:
	if not stored is Dictionary:
		return FUEL_UNFILED
	var record: Dictionary = stored
	if not record.has("fuel"):
		return FUEL_UNFILED
	return int(record["fuel"])


## The hull/slot/index half of the two composed transactions' guards (CONTRACTS
## section 13): a hull that is not one of the nine, a slot key outside
## `FitData.FIT_SLOT_KEYS`, and an index outside 0 .. `slot_capacity`-1 are all
## refusals, named once so the install and the remove cannot drift apart. A gap
## in the grid is not a cell of any type, so it never takes an index.
func _fit_cell_exists(ship_id: StringName, slot_key: StringName, index: int) -> bool:
	if not FitData.HULLS.has(ship_id) or not FitData.FIT_SLOT_KEYS.has(slot_key):
		return false
	return index >= 0 and index < FitData.slot_capacity(ship_id, slot_key)


## One cell's module id out of a fit in `fit_for`'s shape: the id at the cell's
## layout index, `""` for an empty cell. POWER is the one scalar slot type (09
## section 4.5 rule 1), so its one id is the whole answer.
static func _cell_id(fit: Dictionary, slot_key: StringName, index: int) -> String:
	if slot_key == POWER_SLOT:
		return String(fit.get(slot_key, ""))
	var cells: Array = fit.get(slot_key, [])
	if index < 0 or index >= cells.size():
		return ""
	return String(cells[index])


## `resolved_fit`'s answer with one cell set - the candidate `fit_module_at` and
## `clear_fit_slot` hand to `FitData.fit_legal` and then write whole. Deep-copied,
## so the caller's fit is never touched by the preview. The cell's own type grows
## to its layout index when the fit does not carry that many cells yet, which is
## the shape a launch-fallback fit arrives in: 09 section 9's
## `ShipFit.standard_fit` names only the types the hull is delivered with, so a
## cell of a type it leaves out is composed here rather than read. POWER is the
## one scalar slot type (09 section 4.5 rule 1), so it is one id, not a cell.
static func _with_cell(
	fit: Dictionary, slot_key: StringName, index: int, module_id: StringName
) -> Dictionary:
	var candidate := fit.duplicate(true)
	if slot_key == POWER_SLOT:
		candidate[slot_key] = String(module_id)
		return candidate
	var cells: Array = candidate.get(slot_key, candidate.get(String(slot_key), []))
	while cells.size() <= index:
		cells.append("")
	cells[index] = String(module_id)
	candidate[slot_key] = cells
	return candidate


## Whether a fit holds any module at all, either key spelling, in `fit_for`'s own
## shape: the launch's own test, so an all-empty stored fit resolves to the
## standard fit on both sides. `resolved_fit` is its only caller.
static func _holds_a_module(fit: Dictionary) -> bool:
	for key: StringName in FitData.FIT_SLOT_KEYS:
		var raw: Variant = fit.get(key, fit.get(String(key), null))
		if raw is Array:
			for entry: Variant in raw as Array:
				if String(entry) != "":
					return true
		elif raw is String or raw is StringName:
			if String(raw) != "":
				return true
	return false


## `set_fit` is silent when the write changes nothing - the no-op contract every
## setter here keeps - so a composed transaction announces the fits key itself in
## that one case; `before` is the stored fit taken ahead of the write. The normal
## path signals exactly once, from the candidate that transaction writes whole,
## and never twice.
func _announce_fit(ship_id: StringName, before: Dictionary) -> void:
	if _fit_entry(ship_id) == before:
		profile_changed.emit(KEY_FITS)


## One inventory record (15 section 6), or an empty dictionary for an id the
## account does not carry. Both key spellings are read: a loaded ConfigFile gives
## String, a hand-built fixture may give StringName.
func _module_record(module_id: StringName) -> Dictionary:
	var record: Variant = _modules.get(module_id, null)
	if not record is Dictionary:
		record = _modules.get(String(module_id), null)
	if record is Dictionary:
		return record
	return {}


## The bag in its canonical shape: every key a String, every record 15 section 6's
## six keys. The loader and `set_modules` run this, so a live record and a loaded
## one are the same dictionary whatever shape the file or the caller had, and the
## migration's own shape test stays meaningful.
func _normalise_instances(source: Dictionary) -> Dictionary:
	var bag: Dictionary = {}
	for key: Variant in source:
		var entry: Variant = source[key]
		if not entry is Dictionary:
			continue
		bag[String(key)] = _normalise_instance(String(key), entry)
	return bag


## One record in its canonical six-key shape (CONTRACTS section 15). A missing
## `instance_id` or `base_id` defaults to the record's own key, which is how a v5
## `{base_id, count}` record reads (`base_id` kept) and a bare `{count: n}` fixture
## reads (`base_id` = the key, the pre-v6 tolerance `base_module_id` has always
## had); a missing or illegal `rarity` is Common, 15 section 1's floor for a record
## that was never rolled; `count` is clamped at zero. Affixes keep the shipped
## `[{id, value}]` / `[id]` rows with junk entries dropped.
static func _normalise_instance(key: String, raw: Dictionary) -> Dictionary:
	var instance_id := str(raw.get(KEY_INSTANCE_ID, key))
	var base := str(raw.get(KEY_BASE_ID, key))
	# `str()` and not the `String()` constructor: the constructor has no int
	# overload, so a fixture whose `rarity` is a bare number (every pre-instance
	# one, `rarity: 2`) aborted the whole normalise and left an empty record.
	var rarity := str(raw.get(KEY_RARITY, ModuleData.RARITY_COMMON))
	if not ModuleData.RARITY_ORDER.has(rarity):
		rarity = ModuleData.RARITY_COMMON
	return _instance_record(
		instance_id if instance_id != "" else key,
		base if base != "" else key,
		rarity,
		raw.get(KEY_PREFIXES, []),
		raw.get(KEY_SUFFIXES, []),
		maxi(0, int(raw.get(KEY_COUNT, 0)))
	)


## One instance record, canonical: CONTRACTS section 15's six keys, ids as Strings
## (what a ConfigFile gives back, so a live record and a loaded one compare equal),
## the affixes as 15 section 3's `{id: String, value: float}` rows and section 4's
## suffix ids, and `count` as an int.
static func _instance_record(
	id: String, base: String, rarity: String, prefixes: Variant, suffixes: Variant, count: int
) -> Dictionary:
	return {
		KEY_INSTANCE_ID: id,
		KEY_BASE_ID: base,
		KEY_RARITY: rarity,
		KEY_PREFIXES: _affix_rows(prefixes),
		KEY_SUFFIXES: _affix_names(suffixes),
		KEY_COUNT: count,
	}


## 15 section 3's prefix rows as a record stores them: the catalogue id plus the
## value the band column gave it at the module's tier. A plain id (a hand-built
## fixture) is kept with value 0.0 and a junk entry is dropped, so the shape is
## stable whatever the caller passed.
static func _affix_rows(raw: Variant) -> Array:
	var rows: Array = []
	if not raw is Array:
		return rows
	for entry: Variant in (raw as Array):
		if entry is Dictionary:
			var row: Dictionary = entry
			var id := str(row.get("id", ""))
			if id != "":
				rows.append({"id": id, "value": float(row.get("value", 0.0))})
		elif entry is String or entry is StringName:
			var named := String(entry)
			if named != "":
				rows.append({"id": named, "value": 0.0})
	return rows


## 15 section 4's suffix ids as a record stores them: one String each.
static func _affix_names(raw: Variant) -> Array:
	var names: Array = []
	if not raw is Array:
		return names
	for entry: Variant in (raw as Array):
		var suffix_id := ""
		if entry is Dictionary:
			suffix_id = str((entry as Dictionary).get("id", ""))
		elif entry is String or entry is StringName:
			suffix_id = String(entry)
		if suffix_id != "":
			names.append(suffix_id)
	return names


## The next free instance id (CONTRACTS section 15): the counter increments and its
## `mod_%04d` is taken unless the bag or the shelf already holds that id, in which
## case the next number is tried. The counter never rewinds, so a discarded listing
## spends its number for good.
func _mint_instance_id() -> String:
	var candidate := ""
	while candidate == "" or _modules.has(candidate) or _shelf_listings().has(candidate):
		_instance_counter += 1
		candidate = INSTANCE_ID_FORMAT % _instance_counter
	return candidate


## The shelf's listing dictionary, read in place: the restock and `buy_instance`
## both write through it, and it holds 10 section 2.1's rolled listings keyed by
## their minted instance id.
func _shelf_listings() -> Dictionary:
	var listings: Variant = _auction.get("modules", null)
	if listings is Dictionary:
		return listings
	return {}


## One shelf listing as a fresh canonical record, `{}` for an id the shelf does not
## list. Nothing here is in the bag: a listing is owned only once `buy_instance`
## moves it.
func _listing_record(id: StringName) -> Dictionary:
	var listing: Variant = _shelf_listings().get(String(id), null)
	if not listing is Dictionary:
		return {}
	return _normalise_instance(String(id), listing)


## Drop one listing from the shelf. `buy_instance`'s move and 10 section 2.1's
## restock discard both ride this; the state keeps its four members.
func _remove_listing(key: String) -> void:
	var state := _auction.duplicate(true)
	var listings: Dictionary = state.get("modules", {})
	listings.erase(key)
	state["modules"] = listings
	_auction = state
	_mark_dirty()


## The displaced-entry half of the two composed transactions (CONTRACTS section
## 13/15). An entry the bag still holds at `count` 0 -- an instance that was taken
## for fitting -- comes back as the **same** instance through `restore_instance`;
## anything else (a base-keyed entry, a delivered module the bag never held, an id
## with no record at all) enters through `add_module`, exactly as before save v6.
## One bag write either way, so a swap still emits one `&"modules"` signal per side.
func _bank_entry(entry: StringName) -> void:
	var record := _module_record(entry)
	if not record.is_empty() and int(record.get(KEY_COUNT, 0)) == 0:
		restore_instance(entry)
		return
	add_module(entry, 1)


## The empty shelf: the four pinned members at their defaults.
func _auction_default() -> Dictionary:
	return {"last_band": 0, "hulls": [], "modules": {}, "hot": &""}


## A shelf state in the pin's shape (CONTRACTS section 15): `last_band` as an int,
## `hulls` an Array[String] of ids, `modules` the listings keyed by their minted id
## and each one canonical, `hot` one StringName. The four keys are always present,
## whatever the caller passed, so `auction` can hand out the same shape to every
## reader; a key the state does not carry keeps its default.
func _normalise_auction(source: Dictionary) -> Dictionary:
	var normalised := _auction_default()
	var band: Variant = source.get("last_band", null)
	if band is int or band is float:
		normalised["last_band"] = int(band)
	var hulls: Variant = source.get("hulls", null)
	if hulls is Array:
		var ids: Array[String] = []
		for entry: Variant in (hulls as Array):
			var ship_id := String(entry)
			if ship_id != "":
				ids.append(ship_id)
		normalised["hulls"] = ids
	var listings: Variant = source.get("modules", null)
	if listings is Dictionary:
		var shelf: Dictionary = {}
		for key: Variant in (listings as Dictionary):
			var entry: Variant = listings[key]
			if entry is Dictionary:
				shelf[String(key)] = _normalise_instance(String(key), entry)
		normalised["modules"] = shelf
	var hot: Variant = source.get("hot", null)
	if hot is StringName or hot is String:
		normalised["hot"] = StringName(str(hot))
	return normalised


## The stored entry for one hull, or an empty dictionary. `_fits` is keyed by
## String(ship_id) and its per-slot values are whatever the file was saved with:
## one id per type before save v4, an array after it.
func _fit_entry(ship_id: StringName) -> Dictionary:
	var entry: Variant = _fits.get(String(ship_id), null)
	if entry is Dictionary:
		return entry
	return {}


## One hull's fit in the stored shape, from any entry: every list type an Array
## of String exactly `slot_capacity` long and `power` one id (`""` = empty).
## `spelling` is the entry whose key spelling the result mirrors - the stored
## entry, so a rewrite keeps the shape the file was saved with; a brand-new fit
## gets String, the spelling this profile writes. `typed` asks for the shape
## `fit_for` hands out: the Array[String] values a caller may assign, and the
## `FIT_SLOT_KEYS` StringName keys a caller may enumerate. The writers keep the
## plain array and the file's own spelling, which is what the file persists.
func _normalise_fit(
	ship_id: StringName, source: Dictionary, spelling: Dictionary, typed := false
) -> Dictionary:
	var fit: Dictionary = {}
	for slot_key: StringName in FitData.FIT_SLOT_KEYS:
		var key: Variant = slot_key if typed else _key_for(spelling, slot_key)
		if slot_key == POWER_SLOT:
			fit[key] = _single_id(source, slot_key)
			continue
		var cells := _padded_ids(source, slot_key, FitData.slot_capacity(ship_id, slot_key))
		fit[key] = _typed_ids(cells) if typed else cells
	return fit


## The module ids one slot type holds, in layout-index order and at the hull's
## own capacity: an Array keeps its order and its `""` holes, a single id (the
## v1-v3 shape) is a one-element array, a short entry is padded to capacity and a
## longer one is cut, so the index of a cell never depends on how much of the
## list was written.
func _padded_ids(source: Dictionary, slot_key: StringName, capacity: int) -> Array:
	var ids: Array = []
	for id: String in _ids_of(_slot_value(source, slot_key)):
		if ids.size() >= capacity:
			break
		ids.append(id)
	while ids.size() < capacity:
		ids.append("")
	return ids


## The one module id a scalar slot type holds (POWER, and the pre-v4 spelling of
## every type). An Array is read as its first non-empty id, so an entry that was
## normalised as an array still resolves to one cell.
static func _single_id(source: Dictionary, slot_key: StringName) -> String:
	for id: String in _ids_of(_slot_value(source, slot_key)):
		if id != "":
			return id
	return ""


## The raw value one slot type was stored with. `engines` also answers to the
## pre-v4 singular `engine`, which `engines` wins over when both are present
## (CONTRACTS section 11 rule 2).
static func _slot_value(source: Dictionary, slot_key: StringName) -> Variant:
	if source.has(slot_key):
		return source[slot_key]
	if slot_key == ENGINE_SLOT and source.has(LEGACY_ENGINE_SLOT):
		return source[LEGACY_ENGINE_SLOT]
	return null


## The ids a stored value holds, as Strings: an Array in its own order, a single
## id as a one-element array, anything else as nothing. A junk entry becomes the
## empty cell at its own index rather than shifting every cell after it.
static func _ids_of(raw: Variant) -> Array:
	var ids: Array = []
	if raw is Array:
		for entry: Variant in raw as Array:
			ids.append(String(entry) if entry is String or entry is StringName else "")
	elif raw is StringName or raw is String:
		ids.append(String(raw))
	return ids


## The typed Array[String] a caller reads out of `fit_for`, so
## `var ids: Array[String] = fit[&"weapons"]` is a valid assignment.
static func _typed_ids(ids: Array) -> Array[String]:
	var typed: Array[String] = []
	for id: Variant in ids:
		typed.append(String(id))
	return typed


## The slot-type key a write uses: the spelling the entry already carries, else
## String - the shape a ConfigFile loads and the one this profile writes - so
## "write the same spelling the file already used" (CONTRACTS section 11) holds
## and a rewrite cannot churn the shape. The key itself is matched rather than
## looked up, because a Dictionary lookup crosses String and StringName (they are
## interchangeable there) and so cannot tell the two spellings apart.
static func _key_for(source: Dictionary, slot_key: StringName) -> Variant:
	for key: Variant in source:
		if String(key) == String(slot_key):
			return key
	return String(slot_key)


func _market_default() -> Dictionary:
	return {"demand": {}, "stock": {}, "queue": {}, "trend": {}, "last_band": 0}


func _normalise_market(source: Dictionary) -> Dictionary:
	var normalised := _market_default()
	for key: String in MARKET_KEYS:
		if not source.has(key):
			continue
		var raw: Variant = source[key]
		if not raw is Dictionary:
			push_warning("PlayerProfile: market.%s is not a dictionary; using an empty one" % key)
			continue
		var bucket: Dictionary = _to_plain(raw)
		normalised[key] = bucket
	if source.has("last_band"):
		var band: Variant = source["last_band"]
		if band is int or band is float:
			normalised["last_band"] = int(band)
		else:
			push_warning("PlayerProfile: market.last_band is not a number; using 0")
	return normalised


## Deep copy that also flattens every dictionary key in the new state to String.
func _to_plain(value: Variant) -> Variant:
	if value is Dictionary:
		var plain: Dictionary = {}
		for key: Variant in value:
			plain[String(key)] = _to_plain(value[key])
		return plain
	if value is Array:
		var plain_array: Array = []
		for item: Variant in value:
			plain_array.append(_to_plain(item))
		return plain_array
	return value


func _write_profile() -> void:
	if not _dirty:
		return
	_config.set_value(SECTION, "save_version", SAVE_VERSION)
	_config.set_value(SECTION, "credits", _credits)
	_config.set_value(SECTION, "owned_ships", _names_to_strings(_owned_ships))
	_config.set_value(SECTION, "active_ship", String(_active_ship))
	_config.set_value(SECTION, "cargo", _keys_to_strings(_cargo))
	_config.set_value(SECTION, "ammo", _keys_to_strings(_ammo))
	_config.set_value(SECTION, "modules", _modules)
	_config.set_value(SECTION, "instance_counter", _instance_counter)
	_config.set_value(SECTION, "auction", _auction)
	_config.set_value(SECTION, "batteries", _batteries)
	_config.set_value(SECTION, "fits", _fits)
	_config.set_value(SECTION, "market", _market)
	_config.set_value(SECTION, "heat", _heat)
	_config.set_value(SECTION, "standing", _standing)
	_config.set_value(SECTION, "contracts", _contracts)
	_config.set_value(SECTION, "vaults", _vaults)
	_config.set_value(SECTION, "insured", _insured)
	_config.set_value(SECTION, "mercy_used", _mercy_used)
	_config.set_value(SECTION, "vitals", _vitals)
	var err := _config.save(save_path)
	if err != OK:
		push_warning("PlayerProfile: could not write %s (error %d)" % [save_path, err])
		return
	_dirty = false


func _names_to_strings(names: Array[StringName]) -> Array:
	var out: Array = []
	for entry_name: StringName in names:
		out.append(String(entry_name))
	return out


func _keys_to_strings(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in source:
		out[String(StringName(str(key)))] = int(source[key])
	return out
