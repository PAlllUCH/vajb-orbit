extends Node
## Slice 0, M3 probe A (throwaway; its source is archived under .agents/gen/ after the
## run and can be dropped back into res://tools/ to re-measure).
## Scene run, not a --script run: the profile autoload and the theme only exist in a
## real tree.
##
## Measures M3's acceptance from the slice-0 brief: the free refuel and recharge
## services (owner ruling 2026-09-21 — fee 0, no rate invented), the
## `profile_changed` &"fuel" channel, and the save v3 round trip of the tank.
## The probe repoints the singleton's save_path at a scratch file before it writes
## anything and puts it back afterwards, so the player's own profile.cfg is never
## touched. A [FAIL] line means the acceptance did not land.

const ProfileScript := preload("res://autoload/player_profile.gd")
const Catalog := preload("res://game/station_catalog.gd")
const Services := preload("res://game/repairs.gd")
const Fit := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const HULL: StringName = &"ship_vanguard"
const SCRATCH_PROFILE := "user://_probe_s0m3_profile.cfg"
const SCRATCH_MIGRATED := "user://_probe_s0m3_migrated.cfg"
const SCRATCH_LOG := "user://_probe_s0m3_economy.txt"

const DAMAGED_HULL := 200
const DAMAGED_SHIELD := 300
const START_FUEL := 55
const RECHECK_FUEL := 42
const TANK := 200
const CELLS := 100

var _ok := 0
var _fail := 0
var _fuel_events := 0
var _keys: Array[StringName] = []
var _profile: Node = null


func _ready() -> void:
	_watch()
	_run()


func _watch() -> void:
	await get_tree().create_timer(60.0).timeout
	print("WATCHDOG: probe A did not finish in 60 s")
	get_tree().quit(2)


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_ok += 1
	else:
		_fail += 1
	print("%s %s | %s" % ["[OK]  " if ok else "[FAIL]", label, detail])


func _on_profile_changed(key: StringName) -> void:
	_keys.append(key)
	if key == &"fuel":
		_fuel_events += 1


func _run() -> void:
	print("=== slice0 M3 probe A: refuel / recharge / save v3 ===")
	_profile = get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		_check("profile autoload is reachable", false, "no /root/PlayerProfile")
		_finish()
		return
	_profile.save_path = SCRATCH_PROFILE
	Log.log_path = SCRATCH_LOG
	_profile.connect(&"profile_changed", _on_profile_changed)
	_catalog_rows()
	_refuel()
	_recharge()
	_signal()
	_round_trip()
	_migration()
	_finish()


func _catalog_rows() -> void:
	var refuel_row := Catalog.service(Catalog.SERVICE_REFUEL)
	var recharge_row := Catalog.service(Catalog.SERVICE_RECHARGE)
	_check(
		"catalog a: the refuel row is the catalog's own id",
		refuel_row.get(&"id", &"") == &"refuel" and String(refuel_row.get(&"name", "")) == "REFUEL",
		"%s / %s" % [refuel_row.get(&"id", &""), refuel_row.get(&"name", "")],
	)
	_check(
		"catalog b: every station, free and instant (14 section 1 as amended)",
		String(refuel_row.get(&"availability", "")) == "all"
			and bool(refuel_row.get(&"free", false))
			and bool(refuel_row.get(&"instant", false))
			and String(recharge_row.get(&"availability", "")) == "all",
		"availability=%s free=%s instant=%s" % [
			refuel_row.get(&"availability", ""),
			refuel_row.get(&"free", false),
			refuel_row.get(&"instant", false),
		],
	)
	_check(
		"catalog c: no price field exists anywhere in the two rows",
		not refuel_row.has(&"cost") and not refuel_row.has(&"fee") and not refuel_row.has("price")
			and not recharge_row.has(&"cost") and not recharge_row.has(&"fee"),
		"keys %s" % [refuel_row.keys()],
	)
	_check(
		"catalog d: service_ids lists both rows in order",
		Catalog.service_ids() == [&"refuel", &"recharge"],
		str(Catalog.service_ids()),
	)
	_check(
		"catalog e: an unknown id resolves to nothing",
		Catalog.service(&"nope").is_empty(),
		str(Catalog.service(&"nope")),
	)


func _refuel() -> void:
	_profile.call(&"set_vitals", HULL, DAMAGED_HULL, DAMAGED_SHIELD, START_FUEL)
	var credits_before := int(_profile.call(&"credits"))
	var result: Dictionary = Services.refuel(_profile, HULL)
	var record: Dictionary = _profile.call(&"vitals_of", HULL)
	var stats: ShipStats = Fit.resolve(HULL, Fit.STANDARD_FIT)
	_check(
		"refuel a: ok, fee 0, and the tank is the launch snapshot's fuel_max",
		bool(result.get(&"ok", false))
			and int(result.get(&"fee", -1)) == 0
			and int(result.get(&"fuel_max", 0)) == TANK
			and int(result.get(&"fuel_max", 0)) == int(round(stats.fuel_max)),
		"%s vs section 13 base %s" % [result, stats.fuel_max],
	)
	_check(
		"refuel b: the record's tank is full and hull/shield are untouched",
		int(record.get("fuel", -1)) == TANK
			and int(record.get("hull", 0)) == DAMAGED_HULL
			and int(record.get("shield", 0)) == DAMAGED_SHIELD,
		str(record),
	)
	_check(
		"refuel c: free — credits do not move",
		credits_before == int(_profile.call(&"credits")),
		"%d -> %d" % [credits_before, int(_profile.call(&"credits"))],
	)
	var again: Dictionary = Services.refuel(_profile, HULL)
	_check(
		"refuel d: a full tank refuses",
		not bool(again.get(&"ok", true)) and again.get(&"reason", &"") == Services.REASON_FUEL_FULL,
		str(again),
	)
	var unknown := Services.refuel(_profile, &"ship_bogus")
	_check(
		"refuel e: a ship with no filed report refuses",
		not bool(unknown.get(&"ok", true))
			and unknown.get(&"reason", &"") == Services.REASON_NO_DAMAGE_REPORT,
		str(unknown),
	)
	_profile.call(&"set_vitals", &"ship_ghost", 1, 1, 1)
	var unbuildable := Services.refuel(_profile, &"ship_ghost")
	_check(
		"refuel f: a report for a hull ShipFit cannot build refuses",
		not bool(unbuildable.get(&"ok", true))
			and unbuildable.get(&"reason", &"") == Services.REASON_NO_DAMAGE_REPORT,
		str(unbuildable),
	)
	var text := FileAccess.get_file_as_string(SCRATCH_LOG)
	_check(
		"refuel g: the economy log carries the free rate and the units filled",
		text.contains("REFUEL, ship_vanguard, 145, +0, "),
		text.strip_edges().split("\n")[-1],
	)


func _recharge() -> void:
	var result: Dictionary = Services.recharge(_profile, HULL)
	_check(
		"recharge a: ok, fee 0, and the buffer figure is the section 13 base",
		bool(result.get(&"ok", false))
			and int(result.get(&"fee", -1)) == 0
			and int(result.get(&"energy_max", 0)) == CELLS,
		str(result),
	)
	var record: Dictionary = _profile.call(&"vitals_of", HULL)
	_check(
		"recharge b: Energy is not persisted (18 section 12 item 13 recomputes it)",
		not record.has("energy") and not record.has(&"energy"),
		str(record),
	)
	var unknown := Services.recharge(_profile, &"ship_bogus")
	_check(
		"recharge c: a ship with no report refuses",
		not bool(unknown.get(&"ok", true))
			and unknown.get(&"reason", &"") == Services.REASON_NO_DAMAGE_REPORT,
		str(unknown),
	)
	var text := FileAccess.get_file_as_string(SCRATCH_LOG)
	_check(
		"recharge d: the economy log records the service at the free rate",
		text.contains("RECHARGE, ship_vanguard, 0, +0, "),
		text.strip_edges().split("\n")[-1],
	)


func _signal() -> void:
	_fuel_events = 0
	_keys.clear()
	_profile.call(&"set_vitals", HULL, DAMAGED_HULL, DAMAGED_SHIELD, RECHECK_FUEL)
	_check(
		"signal a: a moved tank emits profile_changed &\"fuel\"",
		_fuel_events == 1 and _keys == [&"fuel"],
		"events=%d keys=%s" % [_fuel_events, _keys],
	)
	_profile.call(&"set_vitals", HULL, 400, 400)
	var record: Dictionary = _profile.call(&"vitals_of", HULL)
	_check(
		"signal b: a repairs-style write is silent and keeps the tank",
		_fuel_events == 1 and int(record.get("fuel", -1)) == RECHECK_FUEL,
		"events=%d record=%s" % [_fuel_events, record],
	)
	_profile.call(&"set_vitals", HULL, 500, 500, 0)
	_check(
		"signal c: filing an empty tank is a tank move, so the key fires",
		_fuel_events == 2 and int(_profile.call(&"vitals_of", HULL).get("fuel", -1)) == 0,
		"events=%d record=%s" % [_fuel_events, _profile.call(&"vitals_of", HULL)],
	)


func _round_trip() -> void:
	_profile.call(&"set_vitals", HULL, DAMAGED_HULL, DAMAGED_SHIELD, RECHECK_FUEL)
	_profile.call(&"flush")
	var on_disk := ConfigFile.new()
	_check("save a: the scratch file is readable", on_disk.load(SCRATCH_PROFILE) == OK, SCRATCH_PROFILE)
	_check(
		"save b: writes persist save_version 3",
		int(on_disk.get_value("profile", "save_version", 0)) == 3,
		"version=%d" % int(on_disk.get_value("profile", "save_version", 0)),
	)
	var second: Node = ProfileScript.new()
	second.save_path = SCRATCH_PROFILE
	second.call(&"reload")
	var record: Dictionary = second.call(&"vitals_of", HULL)
	_check(
		"save c: the tank round-trips beside hull and shield",
		int(record.get("hull", 0)) == DAMAGED_HULL
			and int(record.get("shield", 0)) == DAMAGED_SHIELD
			and int(record.get("fuel", -1)) == RECHECK_FUEL,
		str(record),
	)
	second.free()


func _migration() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value("profile", "save_version", 2)
	fixture.set_value("profile", "credits", 1234)
	fixture.set_value("profile", "vitals", {String(HULL): {"hull": 812, "shield": 455}})
	_check("migration a: the v2 fixture is written", fixture.save(SCRATCH_MIGRATED) == OK, SCRATCH_MIGRATED)
	var migrated: Node = ProfileScript.new()
	migrated.save_path = SCRATCH_MIGRATED
	migrated.call(&"reload")
	var record: Dictionary = migrated.call(&"vitals_of", HULL)
	_check(
		"migration b: a v2 report carries no tank, so the launch keeps its own",
		int(record.get("hull", 0)) == 812 and not record.has("fuel"),
		str(record),
	)
	_check(
		"migration c: a v2 file still loads its own keys",
		int(migrated.call(&"credits")) == 1234,
		"credits=%d" % int(migrated.call(&"credits")),
	)
	var filled: Dictionary = Services.refuel(migrated, HULL)
	var after: Dictionary = migrated.call(&"vitals_of", HULL)
	_check(
		"migration d: the free refuel fills a migrated report without moving hull/shield",
		bool(filled.get(&"ok", false))
			and int(after.get("fuel", -1)) == TANK
			and int(after.get("hull", 0)) == 812,
		"%s record=%s" % [filled, after],
	)
	migrated.free()


func _finish() -> void:
	if _profile != null and is_instance_valid(_profile):
		_profile.call(&"flush")
		_profile.save_path = ProfileScript.SAVE_FILE
		_profile.call(&"reload")
	for path: String in [SCRATCH_PROFILE, SCRATCH_MIGRATED, SCRATCH_LOG]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Log.log_path = Log.DEFAULT_PATH
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
