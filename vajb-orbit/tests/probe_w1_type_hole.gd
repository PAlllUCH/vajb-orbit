extends Node
## W1 probe (P2-B proper): the one fit guard the pin's refusal list does not name.
##
## `fit_module_at` refuses on the pin's five conditions (hull, slot key, index,
## owned module, `ShipFit.fit_legal`), and neither it nor `fit_legal` compares the
## module's own `slot` with the cell's type - the pane's ACTION is what gates that
## (rule 6, the module's own type). This probe measures the shape of that hole on
## the engine build of the wave, so the reviewer has a number rather than a reading:
## it fits `e_std` (an engine, `slot: "engine"`) into a W cell of an otherwise
## delivered Fighter and prints the result, the cell before and after, the
## inventory before and after, and `fit_legal`'s own verdict on the candidate.
##
## Bounded by the caller: `--quit-after 600`. No engine writes: the profile is a
## throwaway instance pointed at a scratch file, exactly as the suites' harness.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_w1_type_hole.tscn --quit-after 600

const Profile := preload("res://autoload/player_profile.gd")
const FitData := preload("res://game/ship_fit.gd")

const SCRATCH := "user://probe_w1_type_hole.cfg"
const HULL: StringName = &"ship_fighter"


func _ready() -> void:
	var profile := Profile.new()
	profile.save_path = SCRATCH
	profile.set_fit(HULL, FitData.standard_fit(HULL))
	profile.add_module(&"e_std", 1)
	print("[W1-HOLE] e_std slot=%s, cell under test=weapons[0] slot=%s"
		% [FitData.MODULES[&"e_std"][&"slot"], &"weapons"])
	print("[W1-HOLE] before: weapons=%s inventory=%s" % [
		str(profile.fit_for(HULL)[&"weapons"]), str(profile.modules())
	])
	var candidate: Dictionary = profile.fit_for(HULL)
	var cells: Array = candidate[&"weapons"]
	cells[0] = "e_std"
	candidate[&"weapons"] = cells
	var legality: Dictionary = FitData.fit_legal(HULL, candidate)
	print("[W1-HOLE] fit_legal on the candidate: legal=%s overflow=%s missing=%s duplicates=%s power=%s"
		% [
			str(legality[&"legal"]),
			str(legality[&"overflow"]),
			str(legality[&"missing"]),
			str(legality[&"duplicates"]),
			str(legality[&"power"]),
		])
	var fitted: bool = profile.fit_module_at(HULL, &"weapons", 0, &"e_std")
	print("[W1-HOLE] fit_module_at(weapons, 0, e_std) -> %s" % str(fitted))
	print("[W1-HOLE] after:  weapons=%s inventory=%s" % [
		str(profile.fit_for(HULL)[&"weapons"]), str(profile.modules())
	])
	profile.free()
	var directory := DirAccess.open(SCRATCH.get_base_dir())
	if directory != null:
		directory.remove(SCRATCH.get_file())
	print("[W1-HOLE] done")
	get_tree().quit(0)
