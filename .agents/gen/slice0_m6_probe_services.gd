extends SceneTree
## slice-0 M6 re-review probe B: owner ruling 1 -- "refuel and recharge are FREE and
## instant station services; no CR rate may exist anywhere" -- measured on the shipped
## code, with a repair control proving the probe can see a charge when one exists.
##
## It also re-checks the two slice-0 persistence facts the services ride on (save v3
## and the filed tank) and the SERVICES row shape (no price field).
##
## The live `user://profile.cfg` is never written: `save_path` is repointed at a scratch
## file for every call and restored (then the real file is reloaded) before exit, and the
## scratch file is deleted. M4's review leaked one `fuel` key into the live record by
## letting the 0.5 s debounce fire after the restore (its D3); this probe flushes while
## the scratch path is live, restores, reloads, and only then deletes.
##
## Archived copy. To re-run it, copy to `vajb-orbit/tools/` and:
##   "..._console.exe" --headless --path <proj> --script res://tools/_probe_s0m6_services.gd --quit-after 600

const RepairsScript := preload("res://game/repairs.gd")
const CatalogScript := preload("res://game/station_catalog.gd")
const FitScript := preload("res://game/ship_fit.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const SCRATCH_PROFILE := "user://_probe_s0m6_profile.cfg"
const SHIP_ID: StringName = &"ship_vanguard"

var _ok := 0
var _failed := 0
var _profile: Node = null


func _init() -> void:
	print("=== slice0 M6 probe B: free services, no CR rate, filed tank ===")
	await process_frame
	_profile = root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		_check("setup: the PlayerProfile autoload resolves", false, "not found")
		_finish()
		return
	_check("setup: the PlayerProfile autoload resolves", true, "%s" % _profile)
	var original := str(_profile.get(&"save_path"))
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_check("setup: the probe runs against a scratch save file, not the live record",
		str(_profile.get(&"save_path")) == SCRATCH_PROFILE,
		"save_path %s -> %s (live file %s untouched)" % [original, SCRATCH_PROFILE, original])

	_report_service_rows()
	_report_refuel()
	_report_recharge()
	_report_repair_control()

	_profile.call(&"flush")
	_profile.set(&"save_path", original)
	_profile.call(&"reload")
	await process_frame
	await create_timer(0.8).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
	_check("teardown: the live profile was reloaded from its own file",
		str(_profile.get(&"save_path")) == original, "save_path restored to %s" % original)
	_finish()


func _finish() -> void:
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _failed])
	quit(1 if _failed > 0 else 0)


func _check(label: String, passed: bool, detail: String) -> void:
	if passed:
		_ok += 1
		print("[OK]   %s | %s" % [label, detail])
	else:
		_failed += 1
		print("[FAIL] %s | %s" % [label, detail])


func _price_keys(row: Dictionary) -> Array:
	var found: Array = []
	for key: Variant in row.keys():
		var name := str(key).to_lower()
		## Whole-name matches only: "description" contains "cr" and must not trip this.
		if (
			name in ["cost", "price", "rate", "credits", "fee"]
			or name.begins_with("cost_")
			or name.begins_with("price_")
			or name.begins_with("rate_")
			or name.ends_with("_cost")
			or name.ends_with("_price")
			or name.ends_with("_rate")
		):
			found.append(key)
	return found


func _report_service_rows() -> void:
	var ids: Array[StringName] = CatalogScript.service_ids()
	_check("services a: the catalogue carries the refuel and recharge rows",
		ids.has(CatalogScript.SERVICE_REFUEL) and ids.has(CatalogScript.SERVICE_RECHARGE),
		"service_ids = %s" % [ids])
	var bad: Array = []
	for id: StringName in ids:
		var row: Dictionary = CatalogScript.service(id)
		if not bool(row.get(&"free", false)) or not bool(row.get(&"instant", false)):
			bad.append(id)
		var priced := _price_keys(row)
		if not priced.is_empty():
			bad.append("%s:%s" % [id, priced])
	_check("services b: every service row is free+instant and carries no price field",
		bad.is_empty(), "offending rows = %s" % [bad])
	var rate_names: Array = []
	var repairs_script: Script = load("res://game/repairs.gd")
	for constant: String in repairs_script.get_script_constant_map().keys():
		var name := constant.to_upper()
		if name.contains("FUEL") and (name.contains("CR") or name.contains("RATE")):
			rate_names.append(constant)
	_check("services c: Repairs owns no CR/rate constant for fuel (ruling 1)",
		rate_names.is_empty(),
		"fuel CR/rate constants = %s (FREE_FEE = %s, repair rates are hull/shield only)"
		% [rate_names, RepairsScript.FREE_FEE])


func _report_refuel() -> void:
	var tank_max := int(FitScript.resolve(SHIP_ID, FitScript.STANDARD_FIT).fuel_max)
	_profile.call(&"set_vitals", SHIP_ID, 800, 300, 50)
	var credits_before := int(_profile.call(&"credits"))
	var result: Dictionary = RepairsScript.refuel(_profile, SHIP_ID)
	var vitals: Dictionary = _profile.call(&"vitals_of", SHIP_ID)
	_check("refuel a: a partial tank is filled to the fit's fuel_max for fee 0",
		bool(result.get(&"ok", false)) and int(result.get(&"fee", -1)) == 0
		and int(vitals.get(&"fuel", -1)) == tank_max,
		"ok=%s fee=%s filed fuel=%s (tank %s)"
		% [result.get(&"ok"), result.get(&"fee"), vitals.get(&"fuel"), tank_max])
	_check("refuel b: refuel charges no credits (ruling 1)",
		int(_profile.call(&"credits")) == credits_before,
		"credits %s -> %s" % [credits_before, _profile.call(&"credits")])
	_check("refuel c: a refuel never moves hull or shield",
		int(vitals.get(&"hull", -1)) == 800 and int(vitals.get(&"shield", -1)) == 300,
		"hull=%s shield=%s (filed 800 / 300)"
		% [vitals.get(&"hull"), vitals.get(&"shield")])
	var again: Dictionary = RepairsScript.refuel(_profile, SHIP_ID)
	_check("refuel d: a full tank refuses with the fuel_full reason",
		not bool(again.get(&"ok", true)) and again.get(&"reason", &"") == RepairsScript.REASON_FUEL_FULL,
		"second call = %s" % [again])
	_profile.call(&"flush")
	var file := ConfigFile.new()
	var err := file.load(SCRATCH_PROFILE)
	var version := int(file.get_value(ProfileScript.SECTION, "save_version", 0))
	var stored: Dictionary = file.get_value(ProfileScript.SECTION, "vitals", {})
	var filed := int(stored.get(String(SHIP_ID), {}).get("fuel", -1))
	_check("refuel e: the tank is filed and persists at save v3 (section 12 item 13)",
		err == OK and version == ProfileScript.SAVE_VERSION and filed == tank_max,
		"load=%s save_version=%s filed fuel=%s (want %s / %s)"
		% [err, version, filed, ProfileScript.SAVE_VERSION, tank_max])


func _report_recharge() -> void:
	var credits_before := int(_profile.call(&"credits"))
	var before: Dictionary = _profile.call(&"vitals_of", SHIP_ID)
	var result: Dictionary = RepairsScript.recharge(_profile, SHIP_ID)
	var after: Dictionary = _profile.call(&"vitals_of", SHIP_ID)
	_check("recharge a: the Energy top-up reports fee 0 and the fit's energy_max",
		bool(result.get(&"ok", false)) and int(result.get(&"fee", -1)) == 0
		and int(result.get(&"energy_max", -1))
		== int(FitScript.resolve(SHIP_ID, FitScript.STANDARD_FIT).energy_max),
		"ok=%s fee=%s energy_max=%s" % [result.get(&"ok"), result.get(&"fee"), result.get(&"energy_max")])
	_check("recharge b: recharge charges no credits (ruling 1)",
		int(_profile.call(&"credits")) == credits_before,
		"credits %s -> %s" % [credits_before, _profile.call(&"credits")])
	_check("recharge c: recharge files nothing (Energy recomputes at launch, section 12 item 13)",
		int(before.get(&"hull", -1)) == int(after.get(&"hull", -1))
		and int(before.get(&"shield", -1)) == int(after.get(&"shield", -1))
		and int(before.get(&"fuel", -1)) == int(after.get(&"fuel", -1)),
		"vitals %s -> %s" % [before, after])


## The control: a charged service must visibly move credits, so "credits unchanged"
## above is a measurement and not a blind probe.
func _report_repair_control() -> void:
	_profile.call(&"set_vitals", SHIP_ID, 500, 300, 200)
	var credits_before := int(_profile.call(&"credits"))
	var cost := RepairsScript.fee(_profile, SHIP_ID)
	var result: Dictionary = RepairsScript.repair(_profile, SHIP_ID)
	var credits_after := int(_profile.call(&"credits"))
	_check("control: the repair fee is charged, so the free services' fee 0 is not a blind read",
		cost > 0 and bool(result.get(&"ok", false)) and credits_after == credits_before - cost,
		"repair fee %s, credits %s -> %s" % [cost, credits_before, credits_after])
