# S3-K5 probes and gate readings (archived as text — no `res://` file, so nothing here can boot the profile autoload; T-93)

Everything below was produced on this machine on 2026-09-23 by the S3 fixer pass. The one
probe the pass needed was deleted from `vajb-orbit/tests/` immediately after its run; its
source is reproduced here so a later reader can re-run it (L121's reproducibility gap).

## 1. The strip's economy-log side effect (`tests/probe_s3_k5_strip_log.gd`)

Launch (bounded, sandboxed twice over — scratch `save_path`, scratch `EconomyLog.log_path`,
own `XDG_DATA_HOME`):

```sh
XDG_DATA_HOME=/tmp/vajb_k5_xdg_probe "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
  res://tests/probe_s3_k5_strip_log.tscn --quit-after 600
```

Output (`/tmp/vajb_k5_probe_strip_log.log`, exit 0):

```text
[k5probe] default_save_path=user://profile.cfg
[k5probe] scratch_save_path=user://k5_probe/profile.cfg scratch_log=user://k5_probe/economy_log.txt
[k5probe] fit_module_at=true instance=mod_0001
[k5probe] log lines before=1
[k5probe] strip remove_module=true
[k5probe] cell= module_count(instance)=1
[k5probe] log lines after=2
[k5probe] appended=2026-09-23T00:29:00, FIT_MODULE, mod_0001, 1, +0, 10000
```

Source as run (`probe_s3_k5_strip_log.gd`), plus its six-line scene
(`probe_s3_k5_strip_log.tscn`: one `Node` root with this script attached):

```gdscript
extends Node
## S3-K5 side-effect probe (T-93-sandboxed, TEMPORARY -- removed from the tree before the
## report): what the OUTFITTING strip's REMOVE writes to the economy log now that it goes
## through the composed `clear_fit_slot` instead of the raw `set_fit_slot` + `add_module`.
## Both writable stores are repointed at scratch paths here AND the whole run is launched
## under its own XDG_DATA_HOME, so the owner's live user:// is unreachable either way.

const PROFILE_PATH := "user://k5_probe/profile.cfg"
const LOG_PATH := "user://k5_probe/economy_log.txt"
const VANGUARD: StringName = &"ship_vanguard"
const LASER: StringName = &"w_laser"

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const LogScript := preload("res://game/economy_log.gd")

var _tree: SceneTree = null


func _ready() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		_finish(1)
		return
	var profile: Node = _tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile == null:
		print("[k5probe] no PlayerProfile autoload")
		_finish(1)
		return
	DirAccess.make_dir_recursive_absolute("user://k5_probe")
	print("[k5probe] default_save_path=%s" % String(profile.get(&"save_path")))
	profile.set(&"save_path", PROFILE_PATH)
	LogScript.log_path = LOG_PATH
	print("[k5probe] scratch_save_path=%s scratch_log=%s" % [String(profile.get(&"save_path")), String(LogScript.log_path)])

	## The p2b1 suite's own fixture, written through the same private fields.
	var owned: Array[StringName] = [VANGUARD]
	profile.set(&"_credits", 10000)
	profile.set(&"_active_ship", VANGUARD)
	profile.set(&"_owned_ships", owned)
	profile.set(&"_fits", {})
	profile.set(&"_modules", {})
	profile.call(&"flush")

	var host := Control.new()
	host.name = "K5ProbeHost"
	host.theme = ThemeRes
	profile.add_child(host)
	var panel := PanelScene.instantiate() as Control
	host.add_child(panel)

	var instance := StringName(
		profile.call(&"add_instance", LASER, &"magic", [{"id": "keen", "value": 0.16}], ["whale"])
	)
	print(
		"[k5probe] fit_module_at=%s instance=%s"
		% [str(profile.call(&"fit_module_at", VANGUARD, &"weapons", 0, instance)), String(instance)]
	)
	print("[k5probe] log lines before=%d" % _line_count())
	var removed := bool(panel.call(&"remove_module", 0))
	print("[k5probe] strip remove_module=%s" % str(removed))
	print("[k5probe] cell=%s module_count(instance)=%d" % [
		String(profile.call(&"fit_for", VANGUARD)[&"weapons"][0]),
		int(profile.call(&"module_count", instance)),
	])
	print("[k5probe] log lines after=%d" % _line_count())
	print("[k5probe] appended=%s" % _new_lines())
	_finish(0)


func _line_count() -> int:
	if not FileAccess.file_exists(LOG_PATH):
		return 0
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return -1
	var text := file.get_as_text()
	file.close()
	var count := 0
	for line: String in text.split("\n", false):
		count += 1
	return count


func _new_lines() -> String:
	if not FileAccess.file_exists(LOG_PATH):
		return "<no log file>"
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return "<unreadable>"
	var lines := file.get_as_text().split("\n", false)
	file.close()
	if lines.size() <= 1:
		return "<none: %d line(s)>" % lines.size()
	return " | ".join(lines.slice(1))


func _finish(code: int) -> void:
	if _tree != null:
		_tree.quit(code)
```

## 2. The pre-fix regression proof

`vajb-orbit/ui/station/outfitting_panel.gd` was restored to its pre-fix bytes
(`git checkout --`), the p2b1 suite was run alone, and the fixed file was copied back from
a kept copy immediately after (verified with `git diff`).

```sh
XDG_DATA_HOME=/tmp/vajb_k5_xdg "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
  --quit-after 1200 res://tests/headless_runner.tscn -- --suite=test_p2b1_outfitting_panel
```

```text
[RUN] suites=test_p2b1_outfitting_panel
[FAIL] test_p2b1_outfitting_panel.gd.test_strip_remove_does_not_duplicate_a_base_keyed_unit: the fitted instance is back as itself
[FAIL] test_p2b1_outfitting_panel.gd.test_strip_remove_hands_back_the_fitted_instance: and the same instance is back in the bag
[PASS] test_p2b1_outfitting_panel.gd.test_strip_remove_is_the_ammo_panes_one_fit_action
[SUMMARY] passed=9 failed=2
```

The `--suite=` filter needs the `--` separator (`OS.get_cmdline_user_args()`); without it
the flag is an engine argument and the runner runs the whole gate, which is how the first
full run of this pass happened.

## 3. The four full gate runs

```sh
"$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
# run 1 and 2: default user://, before the CONTRACTS edits, exit 0
# run 3 and 4: the final tree, exit 0
```

```text
run 1 (gate1.log:542)  [SUMMARY] passed=493 failed=0
run 2 (gate2.log:542)  [SUMMARY] passed=493 failed=0
run 3 (gate3.log:542)  [SUMMARY] passed=493 failed=0
run 4 (gate4.log:542)  [SUMMARY] passed=493 failed=0
scratch XDG run (vajb_k5_suite_p2b1.log)  [SUMMARY] passed=493 failed=0
zero [FAIL] lines in all five logs; the one SCRIPT ERROR in each is L61's line at
tests/test_weapon_fx_f4.gd:178
```

## 4. The live store (T-93), before and after everything

```text
md5(user://profile.cfg)     9182b34ffe0e51dc2ea8fa3051de4ae2  →  9182b34ffe0e51dc2ea8fa3051de4ae2
md5(user://economy_log.txt) 38b05767f005bafab286e4bbe8ed1764  →  38b05767f005bafab286e4bbe8ed1764
mtime(profile.cfg)          2026-09-23 01:22:35  →  unchanged
mtime(economy_log.txt)      2026-09-23 00:28:08  →  unchanged
```
