extends Node
## S7-R1 reviewer probe: the pre-S7 resolution A/B.
##
## Prints every field of `ShipFit.resolve` for the nine hulls' standard fits and a
## handful of hand-built fits (the speed floor, the engine ceiling, the legacy
## `engine` key), so the same file can run in a pre-wave worktree and in the wave's
## tree and the two outputs can be diffed line for line. Field reads go through
## `Object.get`, so a field that does not exist yet (`booster_cooldown_mult` before
## S7) prints as `<null>` instead of failing to compile.
##
## Run: godot --headless --path vajb-orbit res://tests/probe_s7r1_prestats.tscn --quit-after 600

const FitData := preload("res://game/ship_fit.gd")

const FIELDS: Array[StringName] = [
	&"max_speed",
	&"accel_time",
	&"coast_time",
	&"turn_rate",
	&"turn_spinup",
	&"hull_mass",
	&"hull_max",
	&"shield_max",
	&"shield_regen",
	&"damage_mult",
	&"lock_range",
	&"scan_range",
	&"tractor_range",
	&"tractor_speed",
	&"tractor_streams",
	&"cargo_max",
	&"energy_max",
	&"energy_regen",
	&"fuel_max",
	&"boosters",
	&"booster_cooldown_mult",
]


func _ready() -> void:
	print("[S7R1-PRE] begin")
	for hull: StringName in FitData.HULLS.keys():
		_line("standard", hull, FitData.standard_fit(hull))
	_line("ten_composite", &"ship_destroyer", {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"armour": [
			&"h_composite", &"h_composite", &"h_composite", &"h_composite", &"h_composite",
			&"h_composite", &"h_composite", &"h_composite", &"h_composite", &"h_composite",
		],
	})
	_line("three_engines", &"ship_destroyer", {
		&"engines": [&"e_std", &"e_ion", &"e_vector"],
		&"power": &"p_std",
	})
	_line("legacy_engine_key", &"ship_destroyer", {
		&"engine": &"e_ion",
		&"power": &"p_std",
	})
	_line("two_shields", &"ship_corvette", {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"shields": [&"s_light", &"s_heavy"],
	})
	_line("computers", &"ship_patrol", {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"computers": [&"c_target", &"c_twin"],
	})
	print("[S7R1-PRE] end")
	get_tree().quit(0)


func _line(tag: String, hull: StringName, fit: Dictionary) -> void:
	var stats: Variant = FitData.resolve(hull, fit)
	if stats == null:
		print("[S7R1-PRE] %s hull=%s resolve=null" % [tag, hull])
		return
	var parts := PackedStringArray()
	for field: StringName in FIELDS:
		var value: Variant = stats.get(field)
		parts.append("%s=%s" % [field, _repr(value)])
	print("[S7R1-PRE] %s hull=%s %s" % [tag, hull, " ".join(parts)])


func _repr(value: Variant) -> String:
	if value == null:
		return "<null>"
	if value is float:
		return "%.6f" % [value]
	if value is Array:
		var out := PackedStringArray()
		for entry: Variant in (value as Array):
			out.append(String(entry))
		return "[%s]" % [",".join(out)]
	return str(value)
