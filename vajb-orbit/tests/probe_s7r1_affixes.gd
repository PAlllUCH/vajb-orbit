extends Node
## S7-R1 reviewer probe B: the affix summary and every section 20 prefix row,
## re-measured off shipped data (never off the builders' suites).
##
## Prints the summary's aggregate, its flags and its instance rows; one worked row
## per applied prefix with the expectation derived from the catalogue on the spot;
## the band maxima against 09 section 5's three clamps; the empty-argument
## byte-identity proof; and the staged five's no-op. Read-only: every fixture is a
## throwaway profile on a scratch path, no scene is instantiated, no store outside
## `user://probe_s7r1_affixes.cfg` is written.
##
## Run: godot --headless --path vajb-orbit res://tests/probe_s7r1_affixes.tscn --quit-after 600

const ProfileScript := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const AffixesScript := preload("res://game/affixes.gd")

const PROFILE_PATH := "user://probe_s7r1_affixes.cfg"

const FIELDS: Array[StringName] = [
	&"max_speed", &"accel_time", &"coast_time", &"turn_rate", &"turn_spinup",
	&"hull_mass", &"hull_max", &"shield_max", &"shield_regen", &"damage_mult",
	&"lock_range", &"scan_range", &"tractor_range", &"tractor_speed",
	&"tractor_streams", &"cargo_max", &"energy_max", &"energy_regen", &"fuel_max",
	&"boosters", &"booster_cooldown_mult",
]

var _profile: Node = null
var _fail := 0


func _ready() -> void:
	print("[S7R1-B] begin")
	_delete(PROFILE_PATH)
	_profile = ProfileScript.new()
	_profile.save_path = PROFILE_PATH
	add_child(_profile)

	_capacities()
	_summary_off_stored_records()
	_sturdy()
	_vigilant()
	_wideband()
	_surefire()
	_tempered()
	_lightened()
	_deep_hold()
	_spry()
	_whale()
	_clamps()
	_empty_identity()
	_staged_noop()
	_bare_id_inert()
	_negative_and_positive_mixed()
	_multi_same_base_alignment()

	print("[S7R1-B] done failures=%d" % [_fail])
	get_tree().quit(0)


## ------------------------------------------------------------------ helpers


func _delete(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _fitted(base_id: StringName, prefixes: Array = [], suffixes: Array = []) -> StringName:
	var id: StringName = _profile.add_instance(base_id, &"rare", prefixes, suffixes)
	_profile.take_instance(id)
	return id


func _fit(hull: StringName, fit: Dictionary) -> void:
	_profile.set_fit(hull, fit)


func _resolve(hull: StringName) -> ShipStats:
	var fit: Dictionary = _profile.base_fit(_profile.resolved_fit(hull))
	return FitData.resolve(hull, fit, _profile.affix_summary(hull))


func _summary(hull: StringName) -> Dictionary:
	return AffixesScript.summary(_profile, hull)


func _snapshot(stats: ShipStats) -> Dictionary:
	var out: Dictionary = {}
	for field: StringName in FIELDS:
		out[String(field)] = stats.get(field)
	return out


func _check(ok: bool, label: String, detail: String) -> void:
	if not ok:
		_fail += 1
	print("[S7R1-B] %s %s %s" % ["OK " if ok else "BAD", label, detail])


func _close(a: float, b: float) -> bool:
	return is_equal_approx(a, b)


func _hull_with(slot_key: StringName, capacity: int) -> StringName:
	for hull: StringName in FitData.HULLS.keys():
		if FitData.slot_capacity(hull, slot_key) >= capacity:
			return hull
	return &""


func _capacities() -> void:
	for hull: StringName in FitData.HULLS.keys():
		var counts := FitData.grid_counts(hull)
		var parts := PackedStringArray()
		for key: StringName in FitData.FIT_SLOT_KEYS:
			parts.append("%s=%d" % [key, int(counts.get(key, 0))])
		print(
			"[S7R1-B] capacity hull=%s hull=%d shield=%d cargo=%d %s"
			% [
				hull,
				int(FitData.HULLS[hull][&"hull"]),
				int(FitData.HULLS[hull][&"shield"]),
				int(FitData.HULLS[hull][&"cargo"]),
				" ".join(parts),
			]
		)


## ------------------------------------------------------------------ the summary


func _summary_off_stored_records() -> void:
	var hull := _hull_with(&"shields", 1)
	var engine := _fitted(&"e_ion", [{"id": "tempered", "value": 0.12}])
	var laser := _fitted(&"w_laser", [{"id": "keen", "value": 0.08}], ["leeches"])
	var shield := _fitted(&"s_light", [{"id": "sturdy", "value": 0.15}], ["whale"])
	var plate := _fitted(&"h_plate_light", [{"id": "lightened", "value": -0.06}], ["whale"])
	var reactor := _fitted(&"p_mk2", [{"id": "overflowing", "value": 2.0}])
	_fit(hull, {
		&"engines": [engine],
		&"power": reactor,
		&"weapons": [laser],
		&"shields": [shield],
		&"armour": [plate],
	})
	var summary := _summary(hull)
	var keys := PackedStringArray()
	for key: Variant in summary.keys():
		keys.append("%s=%s" % [key, _repr(summary[key])])
	print("[S7R1-B] summary hull=%s %s" % [hull, " | ".join(keys)])
	_check(_close(float(summary.get(&"tempered", 0.0)), 0.12), "summary.tempered", "stored 0.12")
	_check(_close(float(summary.get(&"keen", 0.0)), 0.08), "summary.keen", "stored 0.08")
	_check(_close(float(summary.get(&"sturdy", 0.0)), 0.15), "summary.sturdy", "stored 0.15")
	_check(_close(float(summary.get(&"lightened", 0.0)), -0.06), "summary.lightened", "stored -0.06 (negative)")
	_check(_close(float(summary.get(&"overflowing", 0.0)), 2.0), "summary.overflowing", "staged but aggregated 2.0")
	_check(
		_names(summary.get(&"suffixes", [])).size() == 2
		and _names(summary.get(&"suffixes", [])).has("leeches")
		and _names(summary.get(&"suffixes", [])).has("whale"),
		"summary.suffixes",
		"once-per-perk: %s" % [_names(summary.get(&"suffixes", []))]
	)
	_check(AffixesScript.has_suffix(summary, &"whale"), "has_suffix whale", "true")
	_check(not AffixesScript.has_suffix(summary, &"embers"), "has_suffix embers", "false")
	_check(not AffixesScript.has_suffix({}, &"whale"), "has_suffix empty", "false")
	var rows: Array = summary.get(&"instances", [])
	_check(rows.size() == 5, "summary rows", "%d rows (one per fitted instance)" % [rows.size()])
	for row: Variant in rows:
		print(
			"[S7R1-B] row slot=%s index=%d base=%s prefixes=%s suffixes=%s"
			% [
				str((row as Dictionary).get(&"slot")),
				int((row as Dictionary).get(&"index")),
				str((row as Dictionary).get(&"base_id")),
				_repr((row as Dictionary).get(&"prefixes")),
				_repr((row as Dictionary).get(&"suffixes")),
			]
		)
	# A hull with no stored fit still resolves the standard fit: a real (empty) summary.
	var standard := _summary(&"ship_miner")
	print(
		"[S7R1-B] summary-no-fit keys=%d suffixes=%s rows=%d"
		% [
			standard.size(),
			_repr(standard.get(&"suffixes", [])),
			(standard.get(&"instances", []) as Array).size(),
		]
	)
	_check(AffixesScript.summary(null, hull) == {}, "summary(null)", "{}")
	_check(AffixesScript.summary(_profile, &"ship_not_a_hull") == {}, "summary(unknown hull)", "{}")


## ------------------------------------------------------------------ prefixes


func _sturdy() -> void:
	var hull := _hull_with(&"shields", 2)
	var base := float(FitData.HULLS[hull][&"shield"])
	var light := _fitted(&"s_light", [{"id": "sturdy", "value": 0.15}])
	var heavy := _fitted(&"s_heavy", [{"id": "sturdy", "value": 0.10}])
	_fit(hull, {
		&"engines": [&"e_std"], &"power": &"p_std", &"shields": [light, heavy],
	})
	var stats := _resolve(hull)
	var want := base + 200.0 + 400.0 + (200.0 * 0.15 + 400.0 * 0.10)
	var summed := base + 200.0 + 400.0 + (0.25 * 600.0)
	print(
		"[S7R1-B] sturdy hull=%s base=%.1f got=%.6f per_instance=%.6f summed_magnitude=%.6f"
		% [hull, base, stats.shield_max, want, summed]
	)
	_check(_close(stats.shield_max, want), "sturdy per-instance", "%.6f" % [stats.shield_max])
	_check(not _close(stats.shield_max, summed), "sturdy not summed-magnitude", "%.6f" % [summed])


func _vigilant() -> void:
	var hull := _hull_with(&"shields", 2)
	var ion := _fitted(&"s_ion", [])
	var light := _fitted(&"s_light", [{"id": "vigilant", "value": 0.35}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"shields": [ion, light]})
	var first := _resolve(hull).shield_regen
	_check(_close(first, 2.0 + 9.0), "vigilant best instance", "regen=%.6f" % [first])

	var ion_b := _fitted(&"s_ion", [{"id": "vigilant", "value": 0.25}])
	var light_b := _fitted(&"s_light", [{"id": "vigilant", "value": 0.15}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"shields": [ion_b, light_b]})
	var second := _resolve(hull).shield_regen
	print("[S7R1-B] vigilant best=%.6f aggregate=%.6f want=%.6f" % [first, second, 2.0 + 9.0 * 1.40])
	_check(_close(second, 2.0 + 9.0 * 1.40), "vigilant aggregate scales own", "regen=%.6f" % [second])


func _wideband() -> void:
	var hull := _hull_with(&"computers", 2)
	var nexus := _fitted(&"c_nexus", [])
	var scanner := _fitted(&"c_scanner", [{"id": "wideband", "value": 0.25}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"computers": [nexus, scanner]})
	var stats := _resolve(hull)
	var want := 900.0 * (1.0 + 0.25 * 1.25)
	print(
		"[S7R1-B] wideband hull=%s scan=%.6f want=%.6f lock=%.6f"
		% [hull, stats.scan_range, want, stats.lock_range]
	)
	_check(_close(stats.scan_range, want), "wideband best x aggregate", "%.6f" % [stats.scan_range])
	_check(_close(stats.lock_range, stats.scan_range), "lock_range follows", "%.6f" % [stats.lock_range])


func _surefire() -> void:
	var hull := _hull_with(&"computers", 2)
	var target := _fitted(&"c_target", [{"id": "surefire", "value": 0.10}])
	var twin := _fitted(&"c_twin", [{"id": "surefire", "value": 0.05}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"computers": [target, twin]})
	var stats := _resolve(hull)
	var want := 1.0 + 0.15 * 1.15 + 0.15 * 1.15
	print("[S7R1-B] surefire hull=%s mult=%.6f want=%.6f" % [hull, stats.damage_mult, want])
	_check(_close(stats.damage_mult, want), "surefire own x (1+sum), summed", "%.6f" % [stats.damage_mult])

	var plain := _fitted(&"c_target", [])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"computers": [plain]})
	var baseline := _resolve(hull).damage_mult
	print("[S7R1-B] surefire plain mult=%.6f (0.15 computer)" % [baseline])
	_check(_close(baseline, 1.15), "no suffix, computers still sum", "%.6f" % [baseline])


func _tempered() -> void:
	var hull := _hull_with(&"engines", 3)
	var std := _fitted(&"e_std", [])
	var ion := _fitted(&"e_ion", [{"id": "tempered", "value": 0.12}])
	var vector := _fitted(&"e_vector", [])
	_fit(hull, {&"engines": [std, ion, vector], &"power": &"p_std"})
	var capped := _resolve(hull)
	var hull_handling: Dictionary = FitData.HANDLING.get(hull, {})
	var hull_speed := float(hull_handling.get(&"max_speed", 0.0))
	var want_sum := 0.0 + 0.15 * 1.12 + 0.25
	print(
		"[S7R1-B] tempered hull=%s sum=%.6f unclamped=%.6f ceiling=%.6f got=%.6f"
		% [hull, 1.0 + want_sum, hull_speed * (1.0 + want_sum), hull_speed * 1.40, capped.max_speed]
	)
	_check(_close(capped.max_speed, hull_speed * 1.40), "tempered inside the ceiling", "%.6f" % [capped.max_speed])
	_check(not _close(capped.max_speed, hull_speed * (1.0 + want_sum)), "the ceiling actually bites", "%.6f" % [hull_speed * (1.0 + want_sum)])

	var single_hull := _hull_with(&"engines", 1)
	var solo := _fitted(&"e_ion", [{"id": "tempered", "value": 0.12}])
	_fit(single_hull, {&"engines": [solo], &"power": &"p_std"})
	var solo_stats := _resolve(single_hull)
	var solo_handling: Dictionary = FitData.HANDLING.get(single_hull, {})
	var solo_base := float(solo_handling.get(&"max_speed", 0.0))
	var want := 1.0 + 0.15 * 1.12
	print("[S7R1-B] tempered solo hull=%s got=%.6f want=%.6f" % [single_hull, solo_stats.max_speed, solo_base * want])
	_check(_close(solo_stats.max_speed, solo_base * want), "tempered solo", "%.6f" % [solo_stats.max_speed])


func _lightened() -> void:
	var hull := _hull_with(&"armour", 1)
	var hull_handling: Dictionary = FitData.HANDLING.get(hull, {})
	var base_speed := float(hull_handling.get(&"max_speed", 0.0))
	var plain := _fitted(&"h_plate_light", [])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": [plain]})
	var plain_stats := _resolve(hull)
	var lightened := _fitted(&"h_plate_light", [{"id": "lightened", "value": -0.08}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": [lightened]})
	var lifted := _resolve(hull)
	print(
		"[S7R1-B] lightened hull=%s base=%.6f plain=%.6f lifted=%.6f (penalty -0.05 + abs(-0.08) -> clamp 0)"
		% [hull, base_speed, plain_stats.max_speed, lifted.max_speed]
	)
	_check(_close(lifted.max_speed, base_speed), "lightened clamps at 0, never a bonus", "%.6f" % [lifted.max_speed])
	_check(lifted.max_speed > plain_stats.max_speed, "lightened lifts the plate", "%.6f > %.6f" % [lifted.max_speed, plain_stats.max_speed])
	# The mass term follows the adjusted penalty.
	print(
		"[S7R1-B] lightened accel plain=%.6f lifted=%.6f coast plain=%.6f lifted=%.6f"
		% [plain_stats.accel_time, lifted.accel_time, plain_stats.coast_time, lifted.coast_time]
	)

	# A heavy plate: -0.12 + 0.04 = -0.08, still a penalty.
	var heavy_hull := _hull_with(&"armour", 1)
	var heavy := _fitted(&"h_plate_heavy", [{"id": "lightened", "value": -0.04}])
	_fit(heavy_hull, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": [heavy]})
	var heavy_stats := _resolve(heavy_hull)
	var heavy_handling: Dictionary = FitData.HANDLING.get(heavy_hull, {})
	var heavy_base := float(heavy_handling.get(&"max_speed", 0.0))
	print(
		"[S7R1-B] lightened heavy hull=%s got=%.6f want=%.6f (-0.12 + 0.04)"
		% [heavy_hull, heavy_stats.max_speed, heavy_base * 0.92]
	)
	_check(_close(heavy_stats.max_speed, heavy_base * 0.92), "lightened partial lift", "%.6f" % [heavy_stats.max_speed])


func _deep_hold() -> void:
	var hull := _hull_with(&"utility", 1)
	var base := int(FitData.HULLS[hull][&"cargo"])
	var cargo := _fitted(&"u_cargo", [{"id": "deep_hold", "value": 12.0}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"utility": [cargo]})
	var stats := _resolve(hull)
	print("[S7R1-B] deep_hold hull=%s cargo=%d want=%d" % [hull, stats.cargo_max, base + 15 + 12])
	_check(stats.cargo_max == base + 15 + 12, "deep_hold adds its units", "%d" % [stats.cargo_max])


func _spry() -> void:
	var hull := _hull_with(&"boosters", 1)
	var plain := _fitted(&"b_afterburner", [])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"boosters": [plain]})
	var plain_stats := _resolve(hull)
	var spry := _fitted(&"b_afterburner", [{"id": "spry", "value": -0.15}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"boosters": [spry]})
	var spry_stats := _resolve(hull)
	print(
		"[S7R1-B] spry hull=%s plain=%.6f spry=%.6f" % [hull, plain_stats.booster_cooldown_mult, spry_stats.booster_cooldown_mult]
	)
	_check(_close(plain_stats.booster_cooldown_mult, 1.0), "no spry, no multiplier", "%.6f" % [plain_stats.booster_cooldown_mult])
	_check(_close(spry_stats.booster_cooldown_mult, 0.85), "spry aggregate", "%.6f" % [spry_stats.booster_cooldown_mult])
	_check(
		_close(float(ModuleData.module(&"b_afterburner")[&"effects"][&"cooldown"]) * spry_stats.booster_cooldown_mult, 6.8),
		"spry 8.0 -> 6.8",
		"%.6f" % [float(ModuleData.module(&"b_afterburner")[&"effects"][&"cooldown"]) * spry_stats.booster_cooldown_mult]
	)


func _whale() -> void:
	var hull := _hull_with(&"armour", 1)
	var base := float(FitData.HULLS[hull][&"hull"])
	var plain := _fitted(&"h_plate_light", [])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": [plain]})
	var plain_stats := _resolve(hull)
	var whale := _fitted(&"h_plate_light", [], ["whale"])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": [whale]})
	var whale_stats := _resolve(hull)
	print(
		"[S7R1-B] whale hull=%s base=%.1f plain=%.6f whale=%.6f"
		% [hull, base, plain_stats.hull_max, whale_stats.hull_max]
	)
	_check(_close(whale_stats.hull_max, plain_stats.hull_max + 50.0), "whale +50 flat", "%.6f" % [whale_stats.hull_max])
	# One instance carrying it twice is still one flag.
	var twice := _fitted(&"h_plate_light", [], ["whale", "whale"])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": [twice]})
	var twice_stats := _resolve(hull)
	print("[S7R1-B] whale twice hull=%s hull_max=%.6f" % [hull, twice_stats.hull_max])
	_check(_close(twice_stats.hull_max, plain_stats.hull_max + 50.0), "whale once per instance", "%.6f" % [twice_stats.hull_max])
	# Two instances each carrying it is still one flag (the once-per-perk rule).
	var hull2 := _hull_with(&"armour", 2)
	var whale_a := _fitted(&"h_plate_light", [], ["whale"])
	var whale_b := _fitted(&"h_plate_heavy", [], ["whale"])
	_fit(hull2, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": [whale_a, whale_b]})
	var two_stats := _resolve(hull2)
	var two_plain := _fitted(&"h_plate_light", [])
	var two_plain_b := _fitted(&"h_plate_heavy", [])
	_fit(hull2, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": [two_plain, two_plain_b]})
	var two_base := _resolve(hull2).hull_max
	print(
		"[S7R1-B] whale two instances hull=%s plain=%.6f carried=%.6f (flags=%s)"
		% [hull2, two_base, two_stats.hull_max, _repr(_summary(hull2).get(&"suffixes", []))]
	)
	_check(_close(two_stats.hull_max, two_base + 50.0), "two carriers are one flag", "%.6f" % [two_stats.hull_max])


## ------------------------------------------------------------------ clamps


func _clamps() -> void:
	# 09 section 5 step 4: speed >= 40 % of hull base, pools <= 3x hull base, engine sum <= 1.40.
	var hull := _hull_with(&"armour", 1)
	var handling_speed := float(FitData.HANDLING[hull][&"max_speed"])
	var plates: Array = []
	for index: int in range(10):
		plates.append(&"h_composite")
	var floored: ShipStats = FitData.resolve(
		hull, {&"engines": [&"e_std"], &"power": &"p_std", &"armour": plates}
	)
	print(
		"[S7R1-B] clamp speed hull=%s raw=%.6f floor=%.6f got=%.6f"
		% [hull, handling_speed * pow(0.9, 10.0), handling_speed * 0.4, floored.max_speed]
	)
	_check(_close(floored.max_speed, handling_speed * 0.4), "speed floor 40%", "%.6f" % [floored.max_speed])

	# Sturdy at the band maximum on an over-capacity fixture: 900 + 5 x 350 x 1.20 = 3000
	# before the clamp, exactly 3x 900 after it. Without the affix it is 2650.
	var destroyer: StringName = &"ship_destroyer"
	var base_shield := float(FitData.HULLS[destroyer][&"shield"])
	var rows: Array = []
	var cells: Array = []
	for index: int in range(5):
		cells.append(&"s_ion")
		rows.append({
			&"slot": &"shields",
			&"index": index,
			&"base_id": &"s_ion",
			&"prefixes": [{"id": "sturdy", "value": 0.20}],
			&"suffixes": [],
		})
	var capped: ShipStats = FitData.resolve(
		destroyer,
		{&"engines": [&"e_std"], &"power": &"p_std", &"shields": cells},
		_hand_summary(rows, [])
	)
	var plain: ShipStats = FitData.resolve(
		destroyer, {&"engines": [&"e_std"], &"power": &"p_std", &"shields": cells}
	)
	print(
		"[S7R1-B] clamp shield base=%.1f ceiling=%.1f raw_with_sturdy=%.1f plain=%.6f capped=%.6f"
		% [base_shield, base_shield * 3.0, base_shield + 5.0 * 350.0 * 1.20, plain.shield_max, capped.shield_max]
	)
	_check(_close(capped.shield_max, base_shield * 3.0), "pool ceiling 3x after the affix", "%.6f" % [capped.shield_max])
	_check(plain.shield_max < base_shield * 3.0, "the plain fixture is under the ceiling", "%.6f" % [plain.shield_max])

	# Whale's +50 in an over-capacity fixture: 2200 + 5 x 1000 + 50 -> ceiling 6600.
	var whale_rows: Array = []
	var whale_cells: Array = []
	for index: int in range(5):
		whale_cells.append(&"h_composite")
		whale_rows.append({
			&"slot": &"armour",
			&"index": index,
			&"base_id": &"h_composite",
			&"prefixes": [],
			&"suffixes": [&"whale"],
		})
	var whale_stats: ShipStats = FitData.resolve(
		destroyer,
		{&"engines": [&"e_std"], &"power": &"p_std", &"armour": whale_cells},
		_hand_summary(whale_rows, [&"whale"])
	)
	print(
		"[S7R1-B] clamp hull base=%.1f ceiling=%.1f raw=%.1f got=%.6f"
		% [float(FitData.HULLS[destroyer][&"hull"]), float(FitData.HULLS[destroyer][&"hull"]) * 3.0, 2200.0 + 5000.0 + 50.0, whale_stats.hull_max]
	)
	_check(
		_close(whale_stats.hull_max, float(FitData.HULLS[destroyer][&"hull"]) * 3.0),
		"hull ceiling 3x with Whale",
		"%.6f" % [whale_stats.hull_max]
	)


## ------------------------------------------------------------------ identity


func _empty_identity() -> void:
	var empty_profile := ProfileScript.new()
	empty_profile.save_path = PROFILE_PATH + ".empty"
	add_child(empty_profile)
	var mismatches := 0
	for hull: StringName in FitData.HULLS.keys():
		var fit: Dictionary = FitData.standard_fit(hull)
		var plain: ShipStats = FitData.resolve(hull, fit)
		var empty: ShipStats = FitData.resolve(hull, fit, {})
		var bridged: ShipStats = FitData.resolve(hull, fit, empty_profile.affix_summary(hull))
		if not _deep_eq(_snapshot(empty), _snapshot(plain)):
			mismatches += 1
			print("[S7R1-B] BAD {} differs hull=%s %s vs %s" % [hull, _repr(_snapshot(empty)), _repr(_snapshot(plain))])
		if not _deep_eq(_snapshot(bridged), _snapshot(plain)):
			mismatches += 1
			print("[S7R1-B] BAD empty-summary differs hull=%s" % [hull])
	print("[S7R1-B] empty identity: nine hulls, mismatches=%d" % [mismatches])
	_check(mismatches == 0, "{} and no-third-argument byte-identical", "nine hulls")

	# The pre-S7 Vanguard fixture, re-derived here.
	var vanguard: ShipStats = FitData.resolve(&"ship_vanguard", FitData.STANDARD_FIT)
	print(
		"[S7R1-B] vanguard fixture hull=%.1f shield=%.1f regen=%.1f speed=%.1f accel=%.2f coast=%.2f turn=%.2f mult=%.2f cargo=%d"
		% [
			vanguard.hull_max, vanguard.shield_max, vanguard.shield_regen, vanguard.max_speed,
			vanguard.accel_time, vanguard.coast_time, vanguard.turn_rate, vanguard.damage_mult,
			vanguard.cargo_max,
		]
	)
	_check(
		_close(vanguard.hull_max, 1250.0) and _close(vanguard.shield_max, 800.0)
		and _close(vanguard.shield_regen, 6.0) and _close(vanguard.max_speed, 406.6)
		and _close(vanguard.accel_time, 5.04) and _close(vanguard.coast_time, 2.1)
		and _close(vanguard.turn_rate, 1.5) and _close(vanguard.damage_mult, 1.0)
		and vanguard.cargo_max == 40,
		"pre-S7 Vanguard fixture",
		"hull 1250 / shield 800 / regen 6 / speed 406.6 / accel 5.04 / coast 2.1 / turn 1.5"
	)


func _staged_noop() -> void:
	var hull := _hull_with(&"shields", 1)
	var plain := _fitted(&"s_light", [])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"shields": [plain]})
	var before := _snapshot(_resolve(hull))
	var staged := _fitted(
		&"s_light", [], ["silence", "vault", "choir", "concord", "ports"]
	)
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"shields": [staged]})
	var after := _snapshot(_resolve(hull))
	print(
		"[S7R1-B] staged five flags=%s identical=%s"
		% [_repr(_summary(hull).get(&"suffixes", [])), str(_deep_eq(after, before))]
	)
	_check(_deep_eq(after, before), "staged five resolve no-op", "byte-identical")


func _bare_id_inert() -> void:
	var hull := _hull_with(&"computers", 1)
	var scanner := _fitted(&"c_scanner", ["wideband"])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"computers": [scanner]})
	var summary := _summary(hull)
	var stats := _resolve(hull)
	print(
		"[S7R1-B] bare id wideband stored=%.6f scan=%.6f band_value=%.6f"
		% [
			float(summary.get(&"wideband", -1.0)),
			stats.scan_range,
			float(ModuleData.prefix_value(&"wideband", 1)),
		]
	)
	_check(_close(float(summary.get(&"wideband", -1.0)), 0.0), "bare id stores 0.0", "inert")
	_check(_close(stats.scan_range, 900.0 * 1.25), "stored 0.0 is not re-derived", "%.6f" % [stats.scan_range])
	_check(not _close(stats.scan_range, 900.0 * (1.0 + 0.25 * 1.15)), "not the band reading", "%.6f" % [900.0 * (1.0 + 0.25 * 1.15)])


func _negative_and_positive_mixed() -> void:
	# Two instances of one prefix in one slot: the aggregate is the sum, each rule
	# reads its own row.
	var hull := _hull_with(&"shields", 2)
	var a := _fitted(&"s_light", [{"id": "sturdy", "value": 0.10}])
	var b := _fitted(&"s_heavy", [{"id": "sturdy", "value": 0.15}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"shields": [a, b]})
	var summary := _summary(hull)
	var stats := _resolve(hull)
	var base := float(FitData.HULLS[hull][&"shield"])
	print(
		"[S7R1-B] sturdy two-instance hull=%s aggregate=%.6f shield=%.6f want=%.6f"
		% [hull, float(summary.get(&"sturdy", -1.0)), stats.shield_max, base + 200.0 + 400.0 + (200.0 * 0.10 + 400.0 * 0.15)]
	)
	_check(_close(float(summary.get(&"sturdy", -1.0)), 0.25), "aggregate sums both", "0.25")
	_check(
		_close(stats.shield_max, base + 200.0 + 400.0 + 80.0),
		"K0 F1 counter-example +80",
		"%.6f" % [stats.shield_max]
	)


func _multi_same_base_alignment() -> void:
	# Two instances of the same base in one slot, only the second carrying the prefix:
	# the rows align by cell order, so the second cell's own value must land.
	var hull := _hull_with(&"shields", 2)
	var plain := _fitted(&"s_ion", [])
	var carrying := _fitted(&"s_ion", [{"id": "sturdy", "value": 0.20}])
	_fit(hull, {&"engines": [&"e_std"], &"power": &"p_std", &"shields": [plain, carrying]})
	var stats := _resolve(hull)
	var base := float(FitData.HULLS[hull][&"shield"])
	var rows: Array = _summary(hull).get(&"instances", [])
	var order := PackedStringArray()
	for row: Variant in rows:
		order.append("%s@%d:%s" % [str((row as Dictionary).get(&"base_id")), int((row as Dictionary).get(&"index")), _repr((row as Dictionary).get(&"prefixes"))])
	print(
		"[S7R1-B] same-base pair hull=%s shield=%.6f want=%.6f rows=%s"
		% [hull, stats.shield_max, base + 350.0 + 350.0 + 350.0 * 0.20, " ".join(order)]
	)
	_check(_close(stats.shield_max, base + 350.0 + 350.0 + 350.0 * 0.20), "same-base alignment", "%.6f" % [stats.shield_max])


## ------------------------------------------------------------------ misc


func _hand_summary(rows: Array, flags: Array) -> Dictionary:
	var totals: Dictionary = {}
	for raw: Variant in rows:
		var row: Dictionary = raw
		for entry: Variant in (row[&"prefixes"] as Array):
			var prefix: Dictionary = entry
			var id := StringName(str(prefix[&"id"]))
			totals[id] = float(totals.get(id, 0.0)) + float(prefix[&"value"])
	totals[&"suffixes"] = flags
	totals[&"instances"] = rows
	return totals


func _names(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if raw is Array:
		for entry: Variant in (raw as Array):
			out.append(String(entry))
	return out


func _repr(value: Variant) -> String:
	if value == null:
		return "<null>"
	if value is float:
		return "%.6f" % [value]
	if value is Dictionary:
		var parts := PackedStringArray()
		for key: Variant in (value as Dictionary).keys():
			parts.append("%s:%s" % [key, _repr((value as Dictionary)[key])])
		return "{%s}" % [", ".join(parts)]
	if value is Array:
		var items := PackedStringArray()
		for entry: Variant in (value as Array):
			items.append(_repr(entry))
		return "[%s]" % [", ".join(items)]
	return str(value)


func _deep_eq(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var left: Dictionary = a
		var right: Dictionary = b
		if left.size() != right.size():
			return false
		for key: Variant in left.keys():
			if not right.has(key):
				return false
			if not _deep_eq(left[key], right[key]):
				return false
		return true
	if a is Array and b is Array:
		var left_array: Array = a
		var right_array: Array = b
		if left_array.size() != right_array.size():
			return false
		for index: int in range(left_array.size()):
			if not _deep_eq(left_array[index], right_array[index]):
				return false
		return true
	if (a is float) or (b is float):
		return is_equal_approx(float(a), float(b))
	return a == b
