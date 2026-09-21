extends Node
## Rock-cleave warning ledger (CONTRACTS section 9, fifth harness limit): the files this
## wave touched, plus the two it added, loaded one at a time between printed markers with
## `CACHE_MODE_IGNORE`, so `--headless --debug` prints each GDScript warning as a
## `WARNING:` line carrying its own `at: GDScript::reload (res://file:line)` attribution.
## Same harness as `probe_g4_lint.gd` / `probe_w5_lint.gd`; attribution groups by the
## `at:` line's path, never by marker block (the first load of a file also compiles its
## dependencies).
##
## Run:  godot --headless --debug --path vajb-orbit res://tests/probe_rock_cleave_lint.tscn --quit-after 900
##       `-- --only=res://game/asteroid.gd` (repeatable) lints just those files instead of
##       the wave's sets, which is how a pre-existence A/B is measured against a stashed
##       file.
## Signal: the `[RC-LINT]` lines; the last is `[RC-LINT] done`.

const FILES_TOUCHED: Array[String] = [
	"res://game/asteroid.gd",
	"res://game/asteroid_field.gd",
	"res://game/projectile.gd",
	"res://autoload/audio_manager.gd",
	"res://tests/test_engine2_cleaving.gd",
	"res://tests/test_weapon_fx_f2.gd",
]

## The two files it added, minus this ledger itself: a file cannot `load()` its own
## script mid-run without tripping an engine-internal crash in the GDScript VM (measured
## here: `Internal script error! Opcode: 19` on the self-load).
const FILES_NEW: Array[String] = [
	"res://tests/probe_rock_cleave.gd",
]

## `game/asteroid.gd` carried three warnings before this wave (CONTRACTS section 9's
## G4 ledger: "15 rows in five files no worker owned -- game/asteroid.gd 3"); this wave
## owns the file, so the same file is the positive control that the run is not blind.
const CONTROL_POSITIVE: String = "res://game/asteroid.gd"
const CONTROL_NEGATIVE: String = "res://autoload/world_clock.gd"


func _ready() -> void:
	await get_tree().process_frame
	print("[RC-LINT] debugger_active=%s" % EngineDebugger.is_active())
	var only := _only()
	if not only.is_empty():
		for path: String in only:
			_lint_file("ONLY", path)
		print("[RC-LINT] done")
		get_tree().quit(0)
		return
	for path: String in FILES_TOUCHED:
		_lint_file("TOUCHED", path)
	for path: String in FILES_NEW:
		_lint_file("NEW", path)
	_lint_file("NEGATIVE-CONTROL", CONTROL_NEGATIVE)
	_lint_file("POSITIVE-CONTROL", CONTROL_POSITIVE)
	print("[RC-LINT] done")
	get_tree().quit(0)


## `-- --only=res://path` (repeatable): lint exactly those files, for an A/B against a
## stashed revision.
func _only() -> Array[String]:
	var out: Array[String] = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			out.append(arg.substr("--only=".length()))
	return out


func _lint_file(group: String, path: String) -> void:
	print("[RC-LINT] BEGIN %s %s" % [group, path])
	var script: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	print("[RC-LINT] END   %s %s loaded=%s" % [group, path, script != null])
