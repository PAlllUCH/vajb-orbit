extends Node
## Persistent account state: credits, owned ships, upgrades, cargo, ammo.
## No class_name: the autoload is named PlayerProfile, and Godot rejects a
## global class that hides an autoload singleton (parse error at registration).
## Contract: docs/design/STATION_SPEC.md.
## P1 save v2: keys added by docs/gameplay/17_coder_handoff.md section 3
## (modules, fits, market, heat, standing, contracts, vaults, insured,
## mercy_used) plus the vitals extension approved for the 01 section 6
## repairs panel. Slice-0 save v3 adds the tank to a vitals entry
## (18_engine_spec section 12 item 13: Fuel persists across a launch, Energy
## recomputes) and the `profile_changed` key &"fuel". Version 1 and 2 files
## still load; a key they never wrote comes up at its default, with no warning,
## and writes always persist save_version 3.
## Test and support hooks, present for the P1 suites and migration fixtures
## only: save_path (defaults to SAVE_FILE) and reload().

signal profile_changed(key: StringName)
signal purchase_failed(reason: StringName, id: StringName)

const Catalog := preload("res://game/station_catalog.gd")

const SAVE_FILE := "user://profile.cfg"
const SECTION := "profile"
const SAVE_VERSION := 3
const MIN_READABLE_VERSION := 1
const SAVE_DEBOUNCE_SECONDS := 0.5

const KEY_CREDITS: StringName = &"credits"
const KEY_AMMO: StringName = &"ammo"
const KEY_SHIPS: StringName = &"ships"
const KEY_UPGRADES: StringName = &"upgrades"
const KEY_CARGO: StringName = &"cargo"

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

## Market sub-keys, present in every normalised market dictionary.
const MARKET_KEYS: Array[String] = ["demand", "stock", "queue", "trend"]

const REASON_INSUFFICIENT: StringName = &"insufficient_credits"
const REASON_ALREADY_OWNED: StringName = &"already_owned"
const REASON_UNKNOWN: StringName = &"unknown_id"

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
var _upgrades: Array[StringName] = []
var _cargo: Dictionary = {}
var _ammo: Dictionary = {}
var _known_ships: Dictionary = {}
var _known_upgrades: Dictionary = {}

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


func has_upgrade(upgrade_id: StringName) -> bool:
	return _upgrades.has(upgrade_id)


func installed_upgrades() -> Array[StringName]:
	var upgrades: Array[StringName] = []
	upgrades.append_array(_upgrades)
	return upgrades


func install_upgrade(upgrade_id: StringName, cost: int) -> bool:
	if not _known_upgrades.has(upgrade_id) or cost < 0:
		return _refuse(REASON_UNKNOWN, upgrade_id)
	if _upgrades.has(upgrade_id):
		return _refuse(REASON_ALREADY_OWNED, upgrade_id)
	if not _charge(cost):
		return _refuse(REASON_INSUFFICIENT, upgrade_id)
	_upgrades.append(upgrade_id)
	_touch(KEY_UPGRADES)
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


func fits() -> Dictionary:
	return _fits.duplicate(true)


func set_fits(value: Dictionary) -> void:
	var candidate: Dictionary = _to_plain(value)
	if candidate == _fits:
		return
	_fits = candidate
	_touch(KEY_FITS)


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
	_touch(KEY_UPGRADES)
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
	_known_upgrades.clear()
	for entry: Dictionary in Catalog.SHIPS:
		var ship_id: StringName = entry.get(&"id", &"")
		if ship_id != &"":
			_known_ships[ship_id] = true
	for entry: Dictionary in Catalog.UPGRADES:
		var upgrade_id: StringName = entry.get(&"id", &"")
		if upgrade_id != &"":
			_known_upgrades[upgrade_id] = true


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


func _apply_defaults() -> void:
	_credits = DEFAULT_CREDITS
	_owned_ships.clear()
	_owned_ships.append(DEFAULT_SHIP)
	_active_ship = DEFAULT_SHIP
	_upgrades.clear()
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
	_upgrades.clear()
	_upgrades.append_array(_read_names("upgrades"))
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
		var name := StringName(str(value))
		if name != &"":
			names.append(name)
	return names


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
	_config.set_value(SECTION, "upgrades", _names_to_strings(_upgrades))
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
	for name: StringName in names:
		out.append(String(name))
	return out


func _keys_to_strings(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in source:
		out[String(StringName(str(key)))] = int(source[key])
	return out
