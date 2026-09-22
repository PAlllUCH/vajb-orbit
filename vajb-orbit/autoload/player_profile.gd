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
## The economy transaction log (01 section 7): one line per purchase.
const Log := preload("res://game/economy_log.gd")

const SAVE_FILE := "user://profile.cfg"
const SECTION := "profile"
const SAVE_VERSION := 5
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

## Market sub-keys, present in every normalised market dictionary.
const MARKET_KEYS: Array[String] = ["demand", "stock", "queue", "trend"]

const REASON_INSUFFICIENT: StringName = &"insufficient_credits"
const REASON_ALREADY_OWNED: StringName = &"already_owned"
const REASON_UNKNOWN: StringName = &"unknown_id"

## 01 section 7 log vocabulary, plus the P2-B1 module purchase (CONTRACTS
## section 12): one line per module bought into the inventory, and the P2-B
## fitting transactions (CONTRACTS section 13): one line per installed or
## removed cell.
const EVENT_BUY_MODULE := "BUY_MODULE"
const EVENT_FIT_MODULE := "FIT_MODULE"

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

## Weapon id -> advisory hold capacity. Advisory only: buy_ammo never clamps to it.
const AMMO_MAX: Dictionary = {
	&"laser": 300,
	&"cannon": 300,
	&"rocket": 100,
	&"mine": 100,
	&"plasma": 100,
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
var _contracts: Array = []
var _vaults: Dictionary = {}
var _insured := false
var _mercy_used := false
var _vitals: Dictionary = {}


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


func buy_ammo(weapon_id: StringName, rounds: int, cost: int) -> bool:
	if not AMMO_MAX.has(weapon_id) or rounds <= 0 or cost < 0:
		return _refuse(REASON_UNKNOWN, weapon_id)
	if not _charge(cost):
		return _refuse(REASON_INSUFFICIENT, weapon_id)
	_ammo[weapon_id] = int(_ammo.get(weapon_id, 0)) + rounds
	_touch(KEY_AMMO)
	return true


## The absolute writer the dock's pack report needs (18_engine_spec section 4.3 /
## 01 section 6): a launch seeds `PlayerState` from this store and the *fired
## deltas* come back on dock, and `buy_ammo` can only ever add, so the filing
## negates its own delta and needs a setter. `rounds` is the pack's new holding,
## clamped at zero; an id outside `AMMO_MAX` is refused silently, exactly as
## `buy_ammo` refuses to sell one, so a typo cannot open a sixth pack. A write that
## changes nothing neither dirties the file nor emits `profile_changed`, which
## keeps the every-dock report from signalling when nothing was fired.
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


func set_modules(value: Dictionary) -> void:
	var candidate: Dictionary = _to_plain(value)
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
## not carry it yet. Only `count` (and a `base_id`, which for a common module is
## the entry itself) is written: 15 section 6 rolls affixes at *creation* (drop,
## purchase, build) and never re-rolls them, and this is the count half of the
## inventory, not that roll, so a record already carrying `rarity`/`prefixes`/
## `suffixes` keeps them untouched and one created here carries neither. The
## affix roll's own layer is the P2-B fitting/inventory work.
func add_module(module_id: StringName, count: int = 1) -> void:
	if module_id == &"" or count <= 0:
		return
	var key := String(module_id)
	var stored: Variant = _modules.get(key, null)
	var updated: Dictionary = stored.duplicate(true) if stored is Dictionary else {}
	if not updated.has("base_id"):
		updated["base_id"] = key
	updated["count"] = module_count(module_id) + count
	_modules[key] = updated
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
## On success, in this order: the displaced module, when the cell was not empty,
## returns to the inventory with `add_module` (so a swap can never lose it);
## `take_module` takes the incoming one; the candidate is written whole with
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
	if not bool(FitData.fit_legal(ship_id, candidate)[&"legal"]):
		return false
	var stored := _fit_entry(ship_id)
	var displaced := StringName(_cell_id(fit_for(ship_id), slot_key, index))
	if displaced != &"":
		add_module(displaced, 1)
	take_module(module_id, 1)
	set_fit(ship_id, candidate)
	_announce_fit(ship_id, stored)
	Log.append(EVENT_FIT_MODULE, module_id, 1, 0, _credits)
	return true


## The composed remove behind the FITTING panel's per-cell ACTION (09 section 4
## item 10, CONTRACTS section 13): the cell's module goes back to the inventory
## with `add_module` and the cell is written `&""`. The hull, slot-key and index
## guards are `fit_module_at`'s, plus the mandatory set: a key in
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
## On success: the module back, the cell empty, one `EVENT_FIT_MODULE` line (the
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
	if not bool(FitData.fit_legal(ship_id, candidate)[&"legal"]):
		return false
	var stored := _fit_entry(ship_id)
	add_module(module_id, 1)
	set_fit(ship_id, candidate)
	_announce_fit(ship_id, stored)
	Log.append(EVENT_FIT_MODULE, module_id, 1, 0, _credits)
	return true


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
	_contracts.clear()
	_vaults.clear()
	_insured = false
	_mercy_used = false
	_vitals.clear()


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
