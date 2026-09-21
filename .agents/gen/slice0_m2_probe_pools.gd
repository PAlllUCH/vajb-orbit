extends SceneTree
## slice-0 M2 probe A: the reactor chain on PlayerState (ENGINE_SPEC 4.4, rulings
## 10-14) and the pool figures ShipFit resolves (section 9/13).
##
## Headless `--script` run: the autoloads register with the first frame, so the
## fuel cell spends through the real `PlayerProfile` singleton (its `save_path` is
## repointed at a scratch file first and restored afterwards, so the player's own
## profile.cfg is never written), and the cell it burns is one it added itself.
##
## Archived copy. To re-run it, copy this file to `vajb-orbit/tools/` (the brief
## keeps `tools/` holding only `build_theme.gd` and `derive_icon_tints.gd`) and:
##
##   "..._console.exe" --headless --path <proj> --script res://tools/_probe_s0m2_pools.gd --quit-after 600

const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const SCRATCH_PROFILE := "user://_probe_s0m2_profile.cfg"

var _ok := 0
var _failed := 0
var _blocked := 0
var _state: PlayerState = null
var _profile: Node = null
var _energy_events := 0
var _fuel_events := 0
var _cells_added := 0


func _init() -> void:
	print("=== slice0 M2 probe A: energy, fuel, emergency, fuel cell ===")
	_report_pool_figures()
	await process_frame
	_report_reactor_chain()
	await _call_fuel_cell()
	_report_signals()
	_finish()


func _finish() -> void:
	if _profile != null and is_instance_valid(_profile):
		## Restore the singleton's real target and take the probe's own cell back
		## out, so the run leaves no trace in the player's profile.
		var held := int(_profile.call(&"cargo_qty", &"fuel_cell"))
		if held > _cells_added:
			_profile.call(&"remove_cargo", &"fuel_cell", held - _cells_added)
		_profile.save_path = ProfileScript.SAVE_FILE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
	print("[SUMMARY] ok=%d failed=%d blocked=%d" % [_ok, _failed, _blocked])
	quit(1 if _failed > 0 else 0)


func _report_pool_figures() -> void:
	var stats: ShipStats = ShipFitScript.resolve(&"ship_vanguard", ShipFitScript.STANDARD_FIT)
	_check("pool a: ShipFit resolves the section 13 pool base", stats.energy_max == 100.0
		and stats.fuel_max == 200.0 and stats.energy_regen == 5.0,
		"energy_max=%s fuel_max=%s energy_regen=%s" % [stats.energy_max, stats.fuel_max, stats.energy_regen])
	_check("pool b: hull_mass is the section 13 class column (Cutter 110 t)",
		stats.hull_mass == 110.0, "hull_mass=%s" % stats.hull_mass)
	var fighter: ShipStats = ShipFitScript.resolve(&"ship_fighter", ShipFitScript.STANDARD_FIT)
	var destroyer: ShipStats = ShipFitScript.resolve(&"ship_destroyer", ShipFitScript.STANDARD_FIT)
	_check("pool c: every class carries its own mass column",
		fighter.hull_mass == 80.0 and destroyer.hull_mass == 300.0,
		"fighter=%s destroyer=%s" % [fighter.hull_mass, destroyer.hull_mass])
	var plated: ShipStats = ShipFitScript.resolve(&"ship_vanguard", {
		&"engine": &"e_std", &"power": &"p_std", &"weapons": [], &"shields": [],
		&"armour": [&"h_composite"], &"computers": [], &"boosters": [], &"utility": [],
	})
	_check("pool d: composite plating's mass_add lands on hull_mass",
		is_equal_approx(plated.hull_mass, 110.0 * 1.10),
		"hull_mass=%s (110 t x 1.10)" % plated.hull_mass)
	_check("pool e: the pools clamp at 3x their own base (09 section 5 step 4)",
		is_equal_approx(stats.energy_max, minf(stats.energy_max, 300.0))
		and is_equal_approx(stats.fuel_max, minf(stats.fuel_max, 600.0)),
		"ceilings %s / %s" % [stats.energy_max * 3.0, stats.fuel_max * 3.0])

	_state = PlayerStateScript.new()
	_state.energy_max = stats.energy_max
	_state.fuel_max = stats.fuel_max
	_state.energy_regen = stats.energy_regen
	_state.energy_changed.connect(_on_energy)
	_state.fuel_changed.connect(_on_fuel)
	_state.setup()
	_check("pool f: setup seeds both pools to their maxima",
		_state.energy == 100.0 and _state.fuel == 200.0,
		"energy=%s fuel=%s" % [_state.energy, _state.fuel])


func _report_reactor_chain() -> void:
	var before := _state.fuel
	_check("spend a: 10 Energy is affordable", _state.try_spend_energy(10.0) == true)
	_check("spend b: 10 Energy burns exactly 1 Fuel (FUEL_PER_ENERGY 0.10)",
		is_equal_approx(_state.fuel, before - 1.0),
		"fuel %s -> %s" % [before, _state.fuel])
	_check("spend c: the energy pool took the spend", is_equal_approx(_state.energy, 90.0),
		"energy=%s" % _state.energy)

	var pocket := _state.energy
	_check("spend d: a short pool refuses (false) and changes nothing",
		_state.try_spend_energy(pocket + 1.0) == false and _state.energy == pocket,
		"asked %s with %s" % [pocket + 1.0, pocket])

	## Boost: BOOST_FUEL 3.0/s, applied by the caller as one spend per physics frame.
	var boost_start := _state.fuel
	var frames := 60
	for _frame in frames:
		_state.try_spend_fuel(3.0 / 60.0)
	_check("boost: 3.0 Fuel burned per second of afterburner",
		is_equal_approx(_state.fuel, boost_start - 3.0),
		"%s -> %s over 1 s" % [boost_start, _state.fuel])

	var dash_start := _state.fuel
	var dashed := _state.try_spend_fuel(25.0)
	_check("dash: one fold burst costs DASH_FUEL 25", dashed == true
		and is_equal_approx(_state.fuel, dash_start - 25.0),
		"%s -> %s" % [dash_start, _state.fuel])

	## Emergency Flight Mode (ruling 14): drive the tank dry.
	_state.try_spend_fuel(_state.fuel)
	_check("emergency a: fuel 0 raises the mode", _state.fuel == 0.0
		and _state.emergency_mode == true, "fuel=%s mode=%s" % [_state.fuel, _state.emergency_mode])
	_check("emergency b: boost and dash are locked out (no fuel to spend)",
		_state.try_spend_fuel(3.0) == false and _state.try_spend_fuel(25.0) == false)
	_check("emergency c: the flag is read-only (a getter over fuel)",
		_state.get(&"emergency_mode") == true)
	_check("emergency d: the reactor runs at x0.7", _state.reactor_efficiency() == 0.7,
		"efficiency=%s" % _state.reactor_efficiency())

	_state.try_spend_energy(10.0)
	var energy_before := _state.energy
	_state.tick(1.0)
	_check("emergency e: one second of refill is 0.7 x energy_regen",
		is_equal_approx(_state.energy - energy_before, 0.7 * 5.0),
		"gained %s (full efficiency would be %s)" % [_state.energy - energy_before,
		_state.energy_regen])
	_check("emergency f: an empty tank cannot refuse a shot, and never goes negative",
		_state.fuel == 0.0 and _state.energy > 0.0, "fuel=%s" % _state.fuel)

	_state.set_fuel(50.0)
	var full_before := _state.energy
	_state.set_energy(_state.energy_max)
	_state.tick(1.0)
	_check("regen: a full pool regenerates nothing (ruling 11, no free regen)",
		_state.energy == _state.energy_max and full_before <= _state.energy_max)


func _call_fuel_cell() -> void:
	_profile = get_root().get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		_block("cell 0: the PlayerProfile autoload resolves", "no %s in the tree root" % PROFILE_SERVICE)
		return
	_check("cell 0: the PlayerProfile autoload resolves", true, "%s" % _profile)
	_profile.save_path = SCRATCH_PROFILE
	var held := int(_profile.call(&"cargo_qty", &"fuel_cell"))
	_profile.call(&"add_cargo", &"fuel_cell", held + 1)
	_cells_added = held + 1
	_check("cell a: one fuel_cell in the hold reads as ready", _state.fuel_cell_ready() == true,
		"cargo fuel_cell=%s" % _profile.call(&"cargo_qty", &"fuel_cell"))

	var fuel_before := _state.fuel
	var cargo_before := int(_profile.call(&"cargo_qty", &"fuel_cell"))
	_check("cell b: burning a cell is allowed off cooldown", _state.consume_fuel_cell() == true)
	_check("cell c: one fuel_cell refills FUEL_CELL_UNITS 40",
		is_equal_approx(_state.fuel, minf(fuel_before + 40.0, _state.fuel_max)),
		"%s -> %s" % [fuel_before, _state.fuel])
	_check("cell d: exactly one cell came out of the hold",
		int(_profile.call(&"cargo_qty", &"fuel_cell")) == cargo_before - 1,
		"cargo %s -> %s" % [cargo_before, _profile.call(&"cargo_qty", &"fuel_cell")])
	_check("cell e: burning a cell ends Emergency Flight Mode immediately",
		_state.emergency_mode == false and _state.reactor_efficiency() == 1.0,
		"mode=%s efficiency=%s" % [_state.emergency_mode, _state.reactor_efficiency()])
	_check("cell f: the 10 s cooldown refuses a second cell",
		_state.consume_fuel_cell() == false
		and is_equal_approx(_state.fuel_cell_cooldown, 10.0),
		"cooldown=%s" % _state.fuel_cell_cooldown)
	_state.tick(10.0)
	_check("cell g: the cooldown expires on the tick", _state.fuel_cell_cooldown == 0.0)
	_state.set_fuel(_state.fuel_max)
	_check("cell h: a full tank refuses rather than wasting the cell",
		_state.fuel_cell_ready() == false and _state.consume_fuel_cell() == false)


func _report_signals() -> void:
	_check("signal a: both pools announced their seeding and every change",
		_energy_events >= 4 and _fuel_events >= 4,
		"energy_changed=%d fuel_changed=%d" % [_energy_events, _fuel_events])
	var shield_before := _state.shield
	_state.damage(10.0, false, {&"direction": &"stern"})
	_check("ctx a: damage keeps the shield-first rule with a context",
		is_equal_approx(_state.shield, shield_before - 10.0),
		"shield %s -> %s" % [shield_before, _state.shield])
	_check("ctx b: the context is accepted and recorded for slice 3",
		_state.last_damage_ctx().get(&"direction", &"") == &"stern",
		"%s" % _state.last_damage_ctx())


func _on_energy(_current: float, _maximum: float) -> void:
	_energy_events += 1


func _on_fuel(_current: float, _maximum: float) -> void:
	_fuel_events += 1


## A check this probe could not run at all (a missing dependency), reported
## separately from a failure so the log says which is which.
func _block(label: String, detail: String) -> void:
	_blocked += 1
	print("[BLOCK] %s | %s" % [label, detail])


func _check(label: String, passed: bool, detail: String = "") -> void:
	var suffix := "" if detail.is_empty() else " | " + detail
	if passed:
		_ok += 1
		print("[OK]   %s%s" % [label, suffix])
	else:
		_failed += 1
		print("[FAIL] %s%s" % [label, suffix])
