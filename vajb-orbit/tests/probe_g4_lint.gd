extends Node
## G4 (reviewer) warning ledger: every file the flight-feel/beam wave touched, before and
## after, in one run.
##
## Same harness as probe_w5_lint.gd / probe_g1_lint.gd / probe_g2_lint.gd / probe_g3_lint.gd
## (CONTRACTS section 9, fifth harness limit): `--headless --debug` attaches the local stdout
## debugger and prints each GDScript warning as a `WARNING:` line followed by an
## `at: GDScript::reload (res://file:line)` attribution line. One file is loaded at a time
## between printed markers with CACHE_MODE_IGNORE, so the resource cache cannot serve a stale
## parse.
##
## Attribution rule (G3's measured correction): a block's WARNING lines are NOT all the
## block file's - the first load of a file also compiles its dependencies inside that block.
## The authority is the `at:` line's path, so the reviewer's count groups by that column, not
## by marker block.
##
## Run:  godot --headless --debug --path vajb-orbit res://tests/probe_g4_lint.tscn --quit-after 900
## Signal: the [G4-LINT] lines; the last line is [G4-LINT] done.

## The eleven tracked files the wave modified (git diff --name-only, 2026-09-21).
const FILES_TOUCHED: Array[String] = [
	"res://game/weapons.gd",
	"res://game/projectile.gd",
	"res://game/player_ship.gd",
	"res://game/ship_fit.gd",
	"res://autoload/settings_manager.gd",
	"res://game/sector.gd",
	"res://ui/components/slot_button.gd",
	"res://ui/station/exchange_panel.gd",
	"res://ui/station/launch_panel.gd",
	"res://ui/station/shipyard_panel.gd",
	"res://tests/test_combat_repair_c5.gd",
]

## The seven files the wave added.
const FILES_NEW: Array[String] = [
	"res://tests/test_flight_feel_g1.gd",
	"res://tests/test_flight_beam_g2.gd",
	"res://tests/probe_g1_flight_feel.gd",
	"res://tests/probe_g1_lint.gd",
	"res://tests/probe_g2_lint.gd",
	"res://tests/probe_g3_lint.gd",
	"res://tests/probe_g3_shadow.gd",
]

## A file known to warn on this build: a run that shows nothing for it is blind.
const CONTROL_POSITIVE: String = "res://ui/hud/minimap.gd"

## A file with no warning today.
const CONTROL_NEGATIVE: String = "res://autoload/world_clock.gd"


func _ready() -> void:
	await get_tree().process_frame
	print("[G4-LINT] debugger_active=%s" % EngineDebugger.is_active())
	_lint_group("TOUCHED", FILES_TOUCHED)
	_lint_group("NEW", FILES_NEW)
	_lint_file("POSITIVE-CONTROL", CONTROL_POSITIVE)
	_lint_file("NEGATIVE-CONTROL", CONTROL_NEGATIVE)
	print("[G4-LINT] done")
	get_tree().quit(0)


func _lint_group(group: String, files: Array[String]) -> void:
	for path: String in files:
		_lint_file(group, path)


func _lint_file(group: String, path: String) -> void:
	print("[G4-LINT] BEGIN %s %s" % [group, path])
	var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	print("[G4-LINT] END   %s %s loaded=%s" % [group, path, script != null])
