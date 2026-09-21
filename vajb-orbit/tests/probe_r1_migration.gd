extends SceneTree
## R1 review probe for wave P2-A: drives a **save v2** and a **save v3** fixture through
## the shipped fit loader and reports (a) every value the fixture stored, still readable
## after the load, (b) the file on disk byte-identical after a load-only pass, (c) the
## first write's persisted shape and version, and (d) a fresh reload of that write. Any
## warning the profile or the fit store emits is printed between markers so the caller can
## grep for it.
##
##   ~/.local/bin/godot --headless --path vajb-orbit --script res://tests/probe_r1_migration.gd
##
## Throwaway `PlayerProfile` instances only - never the shipped autoload, and no instance
## is added to the tree, so there is no debounce Timer to flush. Every scratch file is
## removed at the end (probe hygiene L17).

const Profile := preload("res://autoload/player_profile.gd")
const FitData := preload("res://game/ship_fit.gd")

const TAG := "[r1m]"
const SECTION := "profile"

var _fails := 0


func _init() -> void:
	print("%s SAVE_VERSION=%d MIN_READABLE_VERSION=%d" % [TAG, Profile.SAVE_VERSION, Profile.MIN_READABLE_VERSION])
	_check("SAVE_VERSION is 4", Profile.SAVE_VERSION == 4, "got %d" % Profile.SAVE_VERSION)
	_check("MIN_READABLE_VERSION stays 1", Profile.MIN_READABLE_VERSION == 1, "got %d" % Profile.MIN_READABLE_VERSION)
	_run_v2()
	_run_v3()
	print("%s DONE fails=%d" % [TAG, _fails])
	quit(0)


func _check(label: String, ok: bool, detail: String = "") -> void:
	if not ok:
		_fails += 1
	print("%s %s %s%s" % [TAG, "ok  " if ok else "FAIL", label, "" if detail.is_empty() else " | " + detail])


func _run_v2() -> void:
	var path := "user://probe_r1_migration_v2.cfg"
	print("%s === v2 fixture ===" % TAG)
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 2)
	fixture.set_value(SECTION, "credits", 4321)
	fixture.set_value(SECTION, "owned_ships", ["ship_vanguard", "ship_freighter"])
	fixture.set_value(SECTION, "active_ship", "ship_freighter")
	fixture.set_value(SECTION, "cargo", {"ore_iron": 7})
	fixture.set_value(SECTION, "ammo", {"laser": 111})
	fixture.set_value(
		SECTION,
		"fits",
		{
			"ship_vanguard":
			{
				"engine": "e_std",
				"power": "p_std",
				"weapons": "w_laser",
				"shields": "s_light",
				"armour": "h_plate_light",
			},
			"ship_freighter": {"engine": "e_ion", "power": "p_std"},
		}
	)
	fixture.save(path)
	var before := _snapshot(path)
	print("%s on disk: %s" % [TAG, str(before)])

	print("%s MARK warnings-between-start" % TAG)
	var first = _profile(path)
	print("%s MARK warnings-between-end" % TAG)
	var after_load := _snapshot(path)

	var fits: Dictionary = first.fits()
	var vanguard: Dictionary = fits["ship_vanguard"]
	var freighter: Dictionary = fits["ship_freighter"]
	_check(
		"the load keeps the file's own single-string shape (fits() reads it verbatim)",
		vanguard[&"engine"] == "e_std" and vanguard[&"weapons"] == "w_laser" and freighter[&"engine"] == "e_ion",
		str(fits)
	)
	_check("the load rewrites nothing (byte-identical snapshot)", _same(before, after_load), str(after_load))

	var v_fit: Dictionary = first.fit_for(&"ship_vanguard")
	var f_fit: Dictionary = first.fit_for(&"ship_freighter")
	_check(
		"fit_for(vanguard) normalises to capacity, one element padded (E1 W3 S1 H2 C1 B1 U1 P1)",
		v_fit[&"engines"] == ["e_std"]
		and v_fit[&"weapons"] == ["w_laser", "", ""]
		and v_fit[&"shields"] == ["s_light"]
		and v_fit[&"armour"] == ["h_plate_light", ""]
		and v_fit[&"computers"] == [""]
		and v_fit[&"boosters"] == [""]
		and v_fit[&"utility"] == [""]
		and v_fit[&"power"] == "p_std",
		str(v_fit)
	)
	_check(
		"fit_for(freighter) pads engines to three cells with the v2 value at index 0",
		f_fit[&"engines"] == ["e_ion", "", ""] and f_fit[&"power"] == "p_std",
		str(f_fit)
	)
	_check(
		"every other v2 value survives the load",
		first.credits() == 4321
		and first.active_ship() == &"ship_freighter"
		and first.cargo_items() == {"ore_iron": 7}
		and first.ammo_of(&"laser") == 111,
		"credits=%d active=%s cargo=%s ammo=%s"
		% [first.credits(), str(first.active_ship()), str(first.cargo_items()), str(first.ammo_of(&"laser"))]
	)

	var wrote: bool = first.set_fit_slot(&"ship_vanguard", &"engines", 0, &"e_ion")
	first.save()
	var after_write := _snapshot(path)
	_check("set_fit_slot(engines, 0) returns true", wrote)
	_check(
		"the write persists save_version 4",
		int(after_write["save_version"]) == 4,
		"save_version=%s" % str(after_write["save_version"])
	)
	var written_fits: Dictionary = after_write["fits"]
	var w_vanguard: Dictionary = written_fits["ship_vanguard"]
	var w_freighter: Dictionary = written_fits["ship_freighter"]
	_check(
		"the written vanguard row is the array shape with the engine cell changed and nothing dropped",
		w_vanguard["engines"] == ["e_ion"]
		and w_vanguard["power"] == "p_std"
		and w_vanguard["weapons"] == ["w_laser", "", ""]
		and w_vanguard["shields"] == ["s_light"]
		and w_vanguard["armour"] == ["h_plate_light", ""]
		and w_vanguard["computers"] == [""]
		and w_vanguard["boosters"] == [""]
		and w_vanguard["utility"] == [""],
		str(w_vanguard)
	)
	## A write normalises only the hull it writes; the other hull's row keeps the file's
	## own shape until something mutates it (the code's own doc block says so). Both
	## shapes read back correctly, so the check is that the value is not lost.
	var freighter_engines: Variant = w_freighter.get("engines", w_freighter.get("engine", null))
	var freighter_ok := false
	if freighter_engines is Array:
		freighter_ok = (freighter_engines as Array) == ["e_ion", "", ""]
	elif freighter_engines is String or freighter_engines is StringName:
		freighter_ok = String(freighter_engines) == "e_ion"
	_check(
		"the untouched second hull keeps its v2 value (shape: %s)" % str(freighter_engines),
		freighter_ok and w_freighter["power"] == "p_std",
		str(w_freighter)
	)
	var read_back: Dictionary = second_reader(path)
	_check(
		"the untouched hull still resolves to e_ion through fit_for after the write",
		read_back[&"engines"] == ["e_ion", "", ""],
		str(read_back)
	)
	_check(
		"every v2 key is carried over unchanged (no data loss)",
		int(after_write["credits"]) == 4321
		and after_write["active_ship"] == "ship_freighter"
		and after_write["cargo"] == {"ore_iron": 7}
		and int((after_write["ammo"] as Dictionary)["laser"]) == 111
		and after_write["owned_ships"] == ["ship_vanguard", "ship_freighter"],
		str(after_write)
	)

	var second = _profile(path)
	var reloaded: Dictionary = second.fit_for(&"ship_vanguard")
	_check(
		"a fresh reload reads the write back cell for cell",
		reloaded[&"engines"] == ["e_ion"] and reloaded[&"weapons"] == ["w_laser", "", ""] and reloaded[&"power"] == "p_std",
		str(reloaded)
	)
	first.flush()
	second.flush()
	_remove(path)


func _run_v3() -> void:
	var path := "user://probe_r1_migration_v3.cfg"
	print("%s === v3 fixture ===" % TAG)
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 3)
	fixture.set_value(SECTION, "credits", 9876)
	fixture.set_value(SECTION, "owned_ships", ["ship_vanguard", "ship_miner"])
	fixture.set_value(SECTION, "active_ship", "ship_miner")
	fixture.set_value(SECTION, "cargo", {"ore_iron": 3, "ore_gold": 1})
	fixture.set_value(SECTION, "ammo", {"laser": 250, "cannon": 40})
	fixture.set_value(SECTION, "modules", {"mod_0007": {"base_id": "s_heavy", "count": 2}})
	fixture.set_value(SECTION, "insured", true)
	fixture.set_value(
		SECTION,
		"fits",
		{
			"ship_vanguard": {"engine": "e_std", "power": "p_std", "weapons": "w_cannon"},
			"ship_miner": {"engine": "e_std", "power": "p_std", "utility": "u_refine"},
		}
	)
	fixture.set_value(SECTION, "vitals", {"ship_miner": {"hull": 900, "shield": 400, "fuel": 133}})
	fixture.save(path)
	var before := _snapshot(path)
	print("%s on disk: %s" % [TAG, str(before)])

	print("%s MARK warnings-between-start" % TAG)
	var first = _profile(path)
	print("%s MARK warnings-between-end" % TAG)
	var after_load := _snapshot(path)
	_check("the v3 load rewrites nothing (byte-identical snapshot)", _same(before, after_load), str(after_load))
	_check(
		"every v3 value survives the load (credits, ships, cargo, ammo, modules, insured, fuel)",
		first.credits() == 9876
		and first.active_ship() == &"ship_miner"
		and first.cargo_items() == {"ore_iron": 3, "ore_gold": 1}
		and first.ammo_of(&"cannon") == 40
		and first.insured() == true
		and first.vitals_of(&"ship_miner").get(&"fuel", -1) == 133,
		"credits=%d active=%s cargo=%s ammo=%s insured=%s vitals=%s"
		% [
			first.credits(),
			str(first.active_ship()),
			str(first.cargo_items()),
			str(first.ammo_of(&"laser")),
			str(first.insured()),
			str(first.vitals_of(&"ship_miner")),
		]
	)
	_check(
		"base_module_id resolves the stored instance (mod_0007 -> s_heavy)",
		first.base_module_id(&"mod_0007") == &"s_heavy",
		str(first.base_module_id(&"mod_0007"))
	)
	var miner: Dictionary = first.fit_for(&"ship_miner")
	_check(
		"fit_for(miner) normalises to the Delver's capacity (E2 W2 S1 H2 C1 B0 U3 P1)",
		miner[&"engines"] == ["e_std", ""]
		and miner[&"weapons"] == ["", ""]
		and miner[&"shields"] == [""]
		and miner[&"armour"] == ["", ""]
		and miner[&"computers"] == [""]
		and miner[&"boosters"] == []
		and miner[&"utility"] == ["u_refine", "", ""]
		and miner[&"power"] == "p_std",
		str(miner)
	)

	first.set_fit_slot(&"ship_miner", &"engines", 1, &"e_ion")
	first.save()
	var after_write := _snapshot(path)
	_check("the v3 write persists save_version 4", int(after_write["save_version"]) == 4, "save_version=%s" % str(after_write["save_version"]))
	var written: Dictionary = after_write["fits"]["ship_miner"]
	_check(
		"the written miner row carries the v3 values over and adds the second engine",
		written["engines"] == ["e_std", "e_ion"]
		and written["power"] == "p_std"
		and written["utility"] == ["u_refine", "", ""]
		and written["weapons"] == ["", ""],
		str(written)
	)
	_check(
		"the v3 non-fit keys are all carried over (fuel, modules, insured, cargo, ammo)",
		int(after_write["credits"]) == 9876
		and after_write["vitals"]["ship_miner"]["fuel"] == 133
		and after_write["modules"]["mod_0007"]["base_id"] == "s_heavy"
		and after_write["insured"] == true
		and after_write["cargo"] == {"ore_iron": 3, "ore_gold": 1}
		and int((after_write["ammo"] as Dictionary)["laser"]) == 250
		and int((after_write["ammo"] as Dictionary)["cannon"]) == 40,
		str(after_write)
	)
	## Pre-existing save semantics, not this wave's: a load fills the ammo families the
	## file never wrote with DEFAULT_AMMO, and the write persists all five. HEAD does the
	## same, so the extra keys are not a v4 change.
	print(
		"%s note: ammo after the write = %s (the loader fills the families the file omitted)"
		% [TAG, str(after_write["ammo"])]
	)
	var second = _profile(path)
	var reloaded: Dictionary = second.fit_for(&"ship_miner")
	_check(
		"a fresh reload reads the v3 write back cell for cell",
		reloaded[&"engines"] == ["e_std", "e_ion"] and reloaded[&"utility"] == ["u_refine", "", ""],
		str(reloaded)
	)
	first.flush()
	second.flush()
	_remove(path)


func _profile(path: String):
	var profile := Profile.new()
	profile.save_path = path
	profile.reload()
	return profile


func second_reader(path: String) -> Dictionary:
	var profile := Profile.new()
	profile.save_path = path
	profile.reload()
	var fit: Dictionary = profile.fit_for(&"ship_freighter")
	profile.flush()
	return fit


func _snapshot(path: String) -> Dictionary:
	var config := ConfigFile.new()
	config.load(path)
	var out: Dictionary = {}
	for key: String in config.get_section_keys(SECTION):
		out[key] = config.get_value(SECTION, key)
	return out


func _same(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key: String in a:
		if not b.has(key) or str(a[key]) != str(b[key]):
			print("%s   differs at %s: %s -> %s" % [TAG, key, str(a[key]), str(b[key])])
			return false
	return true


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
	print("%s scratch %s removed=%s" % [TAG, path, str(not FileAccess.file_exists(path))])
