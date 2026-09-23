extends Node
## G3 warning-sweep static guard: pins the eight shadowing cures and the retired
## declarations they replaced, in the six files G3 owns.
##
## The runtime ledger (`tests/probe_g3_lint.gd`, run with `--headless --debug`) is the
## primary evidence that the warnings are gone; this probe is the regression guard that
## survives a later wave re-introducing the construct. Same shape as
## `tests/probe_w3_lint.gd`:
##
##   1. compile -- every G3 script is loaded fresh from disk (CACHE_MODE_IGNORE), so a
##      parse error introduced by the pass fails here;
##   2. line    -- the exact source line each `at: GDScript::reload (...)` row named now
##      holds the renamed construct;
##   3. absence -- none of the eight retired declarations survives anywhere in its file;
##   4. resolves -- the two renamed preload consts still point at the very catalog script
##      the global class name resolves to, so every `MineralCatalogScript.x` call is the
##      `MineralCatalog.x` call it replaced. Measured, never argued.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_g3_shadow.tscn --quit-after 600
## Signal: the [G3-PASS]/[G3-FAIL] lines and the closing `[G3] passed=N failed=M`.
## Exit code is 1 when any check fails. Not part of the universal gate: the runner in
## headless_runner.gd discovers `test_*.gd` only, and this file is deliberately `probe_*`.

const TOUCHED: Array[String] = [
	"res://ui/station/exchange_panel.gd",
	"res://ui/station/shipyard_panel.gd",
	"res://ui/station/launch_panel.gd",
	"res://ui/components/slot_button.gd",
	"res://game/sector.gd",
]

## `line` is 1-based, as the warning rows and the report both are.
const LINE_CHECKS: Array[Dictionary] = [
	# SHADOWED_GLOBAL_IDENTIFIER: the panel's two preload consts against the global
	# classes `MineralCatalog` / `ComponentCatalog`. Cured the way game/exchange.gd
	# cured the same pair: suffix the const name with `Script`.
	{&"path": "res://ui/station/exchange_panel.gd", &"line": 24, &"must": "const MineralCatalogScript := preload("},
	{&"path": "res://ui/station/exchange_panel.gd", &"line": 25, &"must": "const ComponentCatalogScript := preload("},
	# SHADOWED_VARIABLE_BASE_CLASS: `size` vs Control.size, in both panels' plate builder.
	# (S5-J1, 2026-09-23: the shipyard's line moved with the hangar rework - the signature
	# is unchanged, only its line number is.)
	{&"path": "res://ui/station/shipyard_panel.gd", &"line": 842, &"must": "variation: StringName, plate_size: float"},
	{&"path": "res://ui/station/launch_panel.gd", &"line": 246, &"must": "variation: StringName, plate_size: float"},
	# SHADOWED_VARIABLE_BASE_CLASS: `pressed` vs BaseButton.pressed and `disabled` vs
	# BaseButton.disabled, in `_apply_plates`.
	{&"path": "res://ui/components/slot_button.gd", &"line": 95, &"must": "var pressed_plate: Texture2D = _plate_texture("},
	{&"path": "res://ui/components/slot_button.gd", &"line": 96, &"must": "var disabled_plate: Texture2D = _plate_texture("},
	# SHADOWED_VARIABLE: `fields` vs the `fields()` method, in `populate`.
	{&"path": "res://game/sector.gd", &"line": 125, &"must": "var rolled_fields := _roll_range("},
	# SHADOWED_VARIABLE_BASE_CLASS: `position` vs Node2D.position, in `_add_field`.
	{&"path": "res://game/sector.gd", &"line": 309, &"must": "func _add_field(field_position: Vector2"},
]

## The retired declarations, asserted absent from their file: a stale copy of any of
## these is the warning coming back.
const ABSENCE_CHECKS: Array[Dictionary] = [
	{&"path": "res://ui/station/exchange_panel.gd", &"text": "const MineralCatalog := preload("},
	{&"path": "res://ui/station/exchange_panel.gd", &"text": "const ComponentCatalog := preload("},
	{&"path": "res://ui/station/shipyard_panel.gd", &"text": "variation: StringName, size: float"},
	{&"path": "res://ui/station/shipyard_panel.gd", &"text": "Vector2(size, size)"},
	{&"path": "res://ui/station/launch_panel.gd", &"text": "variation: StringName, size: float"},
	{&"path": "res://ui/station/launch_panel.gd", &"text": "Vector2(size, size)"},
	{&"path": "res://ui/components/slot_button.gd", &"text": "var pressed: Texture2D"},
	{&"path": "res://ui/components/slot_button.gd", &"text": "var disabled: Texture2D"},
	{&"path": "res://game/sector.gd", &"text": "var fields := _roll_range("},
	{&"path": "res://game/sector.gd", &"text": "_add_field(position: Vector2"},
]

## Each renamed const must still resolve to the catalog script its shadowed global class
## name named. Compared by `resource_path`, so the check does not depend on the resource
## cache serving the same object instance to the probe.
const RESOLVES_CHECKS: Array[Dictionary] = [
	{
		&"script": "res://ui/station/exchange_panel.gd",
		&"constant": "MineralCatalogScript",
		&"resolves": "res://game/mineral_catalog.gd",
	},
	{
		&"script": "res://ui/station/exchange_panel.gd",
		&"constant": "ComponentCatalogScript",
		&"resolves": "res://game/component_catalog.gd",
	},
]

var _passed := 0
var _failed := 0


func _ready() -> void:
	_check_compile()
	_check_lines()
	_check_absence()
	_check_resolves()
	print("[G3] passed=%d failed=%d" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _check_compile() -> void:
	for path: String in TOUCHED:
		var script: Variant = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script is GDScript and (script as GDScript).can_instantiate():
			_pass("compile %s" % path)
		else:
			_fail("compile %s" % path)


func _check_lines() -> void:
	for check: Dictionary in LINE_CHECKS:
		var path: String = check[&"path"]
		var lines := _lines(path)
		var wanted: int = int(check[&"line"])
		if lines.size() < wanted:
			_fail("%s:%d missing (file has %d lines)" % [path, wanted, lines.size()])
			continue
		var text: String = lines[wanted - 1]
		if text.contains(str(check[&"must"])):
			_pass("%s:%d holds %s" % [path, wanted, check[&"must"]])
		else:
			_fail("%s:%d is '%s' (wanted %s)" % [path, wanted, text.strip_edges(), check[&"must"]])


func _check_absence() -> void:
	for check: Dictionary in ABSENCE_CHECKS:
		var path: String = check[&"path"]
		var needle: String = str(check[&"text"])
		var body := FileAccess.get_file_as_string(path)
		if body.contains(needle):
			_fail("%s still contains '%s'" % [path, needle])
		else:
			_pass("%s free of '%s'" % [path, needle])


func _check_resolves() -> void:
	for check: Dictionary in RESOLVES_CHECKS:
		var path: String = check[&"script"]
		var owner_script: Variant = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not owner_script is GDScript:
			_fail("%s does not load as a GDScript" % path)
			continue
		var constants: Dictionary = (owner_script as GDScript).get_script_constant_map()
		var constant_name: String = check[&"constant"]
		if not constants.has(constant_name):
			_fail("%s declares no constant %s" % [path, constant_name])
			continue
		var target: Variant = constants[constant_name]
		var wanted: String = check[&"resolves"]
		if target is GDScript and (target as GDScript).resource_path == wanted:
			_pass("%s.%s resolves %s" % [path, constant_name, wanted])
		else:
			_fail("%s.%s resolves %s, wanted %s" % [path, constant_name, target, wanted])


func _lines(path: String) -> PackedStringArray:
	return FileAccess.get_file_as_string(path).split("\n")


func _pass(label: String) -> void:
	_passed += 1
	print("[G3-PASS] %s" % label)


func _fail(label: String) -> void:
	_failed += 1
	print("[G3-FAIL] %s" % label)
