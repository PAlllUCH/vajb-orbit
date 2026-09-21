# UI-chrome wave — W3 report (defect D5: one GDScript lint pass)

**Worker:** W3. **Defect owned:** D5 only. **File set:** `vajb-orbit/autoload/`,
`vajb-orbit/ui/screen.gd`, `vajb-orbit/ui/screens/station.gd`,
`vajb-orbit/ui/station/refinery_panel.gd`, `vajb-orbit/game/exchange.gd`,
`vajb-orbit/tests/`.

**Verdict:** all **23** warning rows the editor recorded in the nine D5-owned files are
gone (21 from the brief's list plus 2 siblings of the same two codes in the same files,
§3). No pinned signature changed; `docs/CONTRACTS.md` needed no edit (§5.5). The gate is
green: `[SUMMARY] passed=226 failed=0`, exit 0 — the **219** pre-existing tests are
unchanged and still pass; the extra 7 are W1's new `tests/test_ui_slot_layout.gd`, which
landed in the shared `tests/` directory during this wave (§5.3). No test file was edited;
nothing outside the file set above was touched (no `docs/**`, no theme, no
`project.godot`, no `addons/**`, no assets).

---

## 1. Where the D5 evidence comes from

The warnings are rows in the **live editor's log buffer** — the same source the playtest
session used. Read through godot-ai against session `vajb-orbit@e33a3a6d694802ed`
(editor PID 63876, plugin 4.1.0):

```
logs_read(source="editor", count=60)            -> total_count 82
logs_read(source="editor", offset=60, count=30) -> has_more false
```

The buffer's **82 rows** break down as:

| Kind | Rows | Note |
|---|---|---|
| GDScript warning rows | **70** | the lint material; 23 of them in W3's file set |
| `ext_resource, invalid UID` at scene load | 7 | D4, W2's defect |
| `router.gd:89 @ route()` invalid UID (runtime re-load) | 3 | D4 fallout, same three `env_stars_layer*` textures |
| pathless rows (`line: 0`, empty path): "Standalone expression", "Values of the ternary operator are not mutually compatible" | 2 | unattributable in the buffer — no file, no line; listed for the orchestrator, not fixable from this evidence |

**A headless run cannot observe a warning.** GDScript only prints warnings when a script
debugger is attached, and a CLI run reports `debugger active=false`; `--check-only
--script` prints parse/compile errors and no warnings, and setting
`debug/gdscript/warnings/treat_warnings_as_errors` at runtime has no effect (the warning
levels are read once when the GDScript language initialises). Measured, all three:

- `godot --headless --path vajb-orbit --check-only --script res://tests/_w3_subject_tmp.gd`
  on a file carrying a deliberate `UNUSED_SIGNAL` + `SHADOWED_VARIABLE_BASE_CLASS`
  produced **no warning output**;
- the same probe with `treat_warnings_as_errors` set from GDScript before `load()`
  produced **no warning output**;
- a no-op `script_patch` (which reloads the script in the editor) **did not append** to
  the editor log either (`total_count` stayed 82).

So the re-read is asserted against the source by
`tests/probe_w3_lint.tscn` (§5.2) instead of by re-collecting warning rows.
**Recipe for a fresh engine-side batch** (for W5 / the orchestrator's close-out, not run
here because the tree carries two other workers' in-flight edits and a game boot has
side effects on `user://profile.cfg`):
`project_run(mode="main", autosave=false)` → `logs_read(source="editor")` →
`project_manage(op="stop")`. A game run compiles every autoload and scene with the
debugger attached, which is how the 70 rows above were produced in the first place.

---

## 2. Per-item fix table

Engine wording is quoted as the log holds it; the code labels are the ones the brief uses.

| # | Code | File:line (recorded) | Construct before | Fix | Re-read after |
|---|---|---|---|---|---|
| 1 | `INT_AS_ENUM_WITHOUT_CAST` | `autoload/settings_manager.gd:391` | `var button: MouseButton = int(source.get("button", 1))` | `… as MouseButton` on the int expression | 391 holds `as MouseButton` |
| 2 | `INT_AS_ENUM_WITHOUT_CAST` | `autoload/settings_manager.gd:400` | `var pad_button: JoyButton = int(source.get("button", 0))` | `… as JoyButton` | 400 holds `as JoyButton` |
| 3 | `INT_AS_ENUM_WITHOUT_CAST` | `autoload/settings_manager.gd:405` | `var axis: JoyAxis = int(source.get("axis", 0))` | `… as JoyAxis` | 405 holds `as JoyAxis` |
| 4 | `SHADOWED_VARIABLE_BASE_CLASS` | `autoload/router.gd:83` | `func route(route: StringName, …)`: the parameter shadows the method `route()`; the body read it at 86, 87, 89, 91, 99, 105 | parameter → `route_name`, all six reads with it | 83 holds `func route(route_name: StringName` |
| 5 | `SHADOWED_VARIABLE` | `autoload/router.gd:111` | `func push_overlay(route: …)`, same collision; body at 112, 114, 115, 117, 119, 133, 134 | parameter → `route_name` | 111 holds `func push_overlay(route_name: StringName` |
| 6 | `SHADOWED_VARIABLE` | `autoload/router.gd:235` | `func _on_route_requested(route: …)` → `route(route, params)` | → `route(route_name, params)` | 235 holds `func _on_route_requested(route_name: StringName` |
| 7 | `SHADOWED_VARIABLE` | `autoload/router.gd:239` | `func _on_overlay_requested(route: …)` → `push_overlay(route, params)` | → `push_overlay(route_name, params)` | 239 holds `func _on_overlay_requested(route_name: StringName` |
| 8 | `SHADOWED_VARIABLE` | `autoload/router.gd:264` | `func _find_overlay(route: …)`, read at 266 | parameter → `route_name` | 264 holds `func _find_overlay(route_name: StringName` |
| 9 | `SHADOWED_VARIABLE_BASE_CLASS` | `autoload/router.gd:284` | `var owner := viewport.gui_get_focus_owner()` vs `Node.owner`; read at 285, 287 | `var focus_owner` | 284 holds `var focus_owner := viewport.gui_get_focus_owner()` |
| 10 | `SHADOWED_VARIABLE_BASE_CLASS` | `autoload/router.gd:336` | `func _service(name: StringName)` vs `Node.name`; read at 341 | parameter → `service_name` | 336 holds `_service(service_name` |
| 11 | `SHADOWED_VARIABLE_BASE_CLASS` | `autoload/audio_manager.gd:249` | `func _service(name: StringName)`; read at 254 | parameter → `service_name` | 249 holds `_service(service_name` |
| 12 | `SHADOWED_VARIABLE_BASE_CLASS` | `autoload/dialog_manager.gd:111` | `func _service(name: StringName)`; read at 116 | parameter → `service_name` | 111 holds `_service(service_name` |
| 13 | `SHADOWED_VARIABLE_BASE_CLASS` | `autoload/player_profile.gd:576` | `var name := StringName(str(value))`, read at 577, 578 | `var entry_name` | 576 holds `var entry_name := StringName(` |
| 14 | `SHADOWED_VARIABLE_BASE_CLASS` | `autoload/player_profile.gd:735` | `for name: StringName in names:`, read at 736 | `for entry_name: StringName in names:` | 735 holds `for entry_name: StringName in names:` |
| 15 | `UNUSED_SIGNAL` | `ui/screen.gd:7` | `signal route_requested(…)` "declared but never explicitly used in the class" | **signal kept**; `@warning_ignore("unused_signal")` + a doc block naming the intended consumer | declaration now 15, waiver on 14 |
| 16 | `UNUSED_SIGNAL` | `ui/screen.gd:8` | `signal overlay_requested(…)` | as above | declaration now 17, waiver on 16 |
| 17 | `UNUSED_SIGNAL` | `ui/screen.gd:9` | `signal overlay_close_requested` | as above | declaration now 19, waiver on 18 |
| 18 | `SHADOWED_VARIABLE_BASE_CLASS` | `ui/screens/station.gd:348` | `_make_icon(…, size: float)` vs `Control.size`, read at 350 (twice) | parameter → `icon_size` | 348 holds `tinted: bool, icon_size: float` |
| 19 | `SHADOWED_VARIABLE_BASE_CLASS` | `ui/screens/station.gd:407` | `var owner := get_viewport().gui_get_focus_owner()`, read at 408 (twice) | `var focus_owner` | 407 holds `var focus_owner := …` |
| 20 | `UNUSED_PARAMETER` | `ui/station/refinery_panel.gd:533` | `_on_row_focused(row: Button, payload: Dictionary)`; the engine's own advice is "prefix it with an underscore" | `_row: Button` | 533 holds `func _on_row_focused(_row: Button, payload: Dictionary)` |
| 21 | `SHADOWED_GLOBAL_IDENTIFIER` | `game/exchange.gd:45` | `const MineralCatalog := preload("res://game/mineral_catalog.gd")` vs the global `class_name MineralCatalog`; 13 value reads | `MineralCatalogScript` (the name five other project files already use for this exact preload) | 45 holds `const MineralCatalogScript := preload(` |
| 22 | `SHADOWED_VARIABLE_BASE_CLASS` | `autoload/settings_manager.gd:427` | `func _service(name: StringName)`, read at 432 | parameter → `service_name` | 427 holds `_service(service_name` |
| 23 | `SHADOWED_GLOBAL_IDENTIFIER` | `game/exchange.gd:46` | `const ComponentCatalog := preload("res://game/component_catalog.gd")` vs the global class; 6 value reads | `ComponentCatalogScript` | 46 holds `const ComponentCatalogScript := preload(` |

Every rename is **positional-only**: GDScript has no named arguments, so a parameter
name is not part of any call's meaning. Call sites were already positional
(`_service(&"SettingsManager")`, `route(ROUTE_LOADING, {…})`,
`router.call(&"push_overlay", DIALOG_ROUTE, {…})`,
`row.focus_entered.connect(_on_row_focused.bind(row, payload))`,
`_make_icon(icon_path, tinted, RAIL_ICON_SIZE)`); none was changed except the two
in-file forwarders in `router.gd` (#6, #7).

Styling choices follow the existing code: `route_name` matches
`router.gd:218`'s existing iterator name, `service_name`/`entry_name`/`icon_size`/
`focus_owner` mirror the surrounding naming, and the two catalogue constants reuse the
project's established `…CatalogScript` convention (`mining_laser.gd:25`,
`loot_tables.gd:32`, `asteroid_field.gd:36`, `sector_registry.gd:26`, `pickup.gd:27`,
`test_engine2_loot.gd:19-20`).

### 2.1 The signal is kept, not deleted (brief rule)

`ui/screen.gd`'s three signals are a pinned interface, not dead code: subclasses emit
them (`boot.gd:67`, `main_menu.gd:204,217`, `loading.gd:83`, `station.gd:427,434`,
`settings.gd:77,298`, `dialogs/dialog.gd:91`) and the Router binds them by name in
`autoload/router.gd:227-232`. Deleting them would delete the interface. The fix is the
engine's own documented remedy — an explicit `unused_signal` waiver — plus a doc block
that names the emitters and the consumer, so the reason the warning is waived is on disk:

```
## The three intent signals below are the routed-screen interface. Subclasses emit
## them (boot.gd, main_menu.gd, loading.gd, station.gd, settings.gd, dialog.gd) and
## autoload/router.gd connects them in _bind_intents(); this base class declares the
## interface and never emits it itself, so each signal carries an explicit
## unused_signal waiver instead of being deleted. The signatures are pinned by
## IMPLEMENTATION_PLAN section 3.4 and must not change.

@warning_ignore("unused_signal")
signal route_requested(route: StringName, params: Dictionary)
```

The three signatures are byte-identical to the pinned ones. (`ui/screen.gd`'s recorded
line numbers necessarily shift by +8: the fix adds the documentation. The probe asserts
the new numbers 14-19 and that the three signatures are unchanged.)

---

## 3. Two items beyond the literal D5 list (declared, not smuggled)

The brief's list names `exchange.gd:45` and stops the settings item at `405`; the editor
batch holds two more rows in the same files with the same codes:

- `autoload/settings_manager.gd:427` — `SHADOWED_VARIABLE_BASE_CLASS`, four rows below
  the three `INT_AS_ENUM` rows the brief names in that file;
- `game/exchange.gd:46` — `SHADOWED_GLOBAL_IDENTIFIER`, the very next line after the
  named `exchange.gd:45`, and the same construct (a preload const shadowing a global
  class).

Both were fixed: same warning class, same files, both inside W3's file set, and the
playtest report names the shadowed group by *file* without line numbers (`router.gd`,
`audio_manager.gd`, `dialog_manager.gd`, `player_profile.gd`, `station.gd:348,407`), so
the file list, not a line list, is what D5 scoped. Neither change is behavioural (a
parameter rename; a const rename inside one file). Nothing else was widened: the 47
warning rows outside this file set are reported, not touched (§7).

---

## 4. The trap this pass found — read this before re-measuring

Renaming a parameter that shadows a **function** is not caught by a parse check, because
a bare function name is a legal expression (a `Callable`). In `push_overlay` the first
rename left two reads of the old name — and the compiler accepted them silently:

```
119:  push_warning("Router: overlay '%s' is not a PackedScene" % route)   # -> "%s" % <Callable>
134:  overlay_pushed.emit(route)                                          # -> emits a Callable
```

A clean parse, a clean `--check-only` and a clean editor load all passed with this in
place; the file would have logged `Router: overlay '<Callable>' is not a PackedScene`
and handed every `overlay_pushed` listener a `Callable` where a `StringName` is
contracted (`IMPLEMENTATION_PLAN.md` §3.4-3.6, the overlay stack contract the two files
themselves cite; `router.gd:261` reads the value back as `entry[&"route"]`). It was found
by auditing the *old* identifier per renamed scope
(§5.6), not by the compiler, and fixed at 119/134 before any measurement was taken.

**Consequence for W5:** for this pass, "compiles clean" is necessary and *not*
sufficient. The evidence that carries weight is the per-scope absence audit — the probe
asserts all 18 retired declarations are absent from the touched files — plus the
per-scope greps in §5.6.

---

## 5. Verification

### 5.1 Re-read of every recorded line

`sed -n` on the recorded numbers, after the pass (below: current content).
Probe-asserted, so each of these is a pass/fail check rather than an eyeball:

```
settings_manager.gd:391  var button: MouseButton = int(source.get("button", 1)) as MouseButton
settings_manager.gd:400  var pad_button: JoyButton = int(source.get("button", 0)) as JoyButton
settings_manager.gd:405  var axis: JoyAxis = int(source.get("axis", 0)) as JoyAxis
settings_manager.gd:427  func _service(service_name: StringName) -> Node:
settings_manager.gd:432      return get_tree().root.get_node_or_null(NodePath(service_name))
audio_manager.gd:249     func _service(service_name: StringName) -> Node:
audio_manager.gd:254         return get_tree().root.get_node_or_null(NodePath(service_name))
dialog_manager.gd:111    func _service(service_name: StringName) -> Node:
dialog_manager.gd:116        return get_tree().root.get_node_or_null(NodePath(service_name))
player_profile.gd:576        var entry_name := StringName(str(value))
player_profile.gd:577        if entry_name != &"":
player_profile.gd:578            names.append(entry_name)
player_profile.gd:735    for entry_name: StringName in names:
player_profile.gd:736        out.append(String(entry_name))
router.gd:83             func route(route_name: StringName, params: Dictionary = {}) -> void:
router.gd:111            func push_overlay(route_name: StringName, params: Dictionary = {}) -> void:
router.gd:235            func _on_route_requested(route_name: StringName, params: Dictionary) -> void:
router.gd:239            func _on_overlay_requested(route_name: StringName, params: Dictionary, _source: Node) -> void:
router.gd:264            func _find_overlay(route_name: StringName) -> Node:
router.gd:284            var focus_owner := viewport.gui_get_focus_owner()
router.gd:336            func _service(service_name: StringName) -> Node:
screen.gd:14/16/18       @warning_ignore("unused_signal")
screen.gd:15/17/19       signal route_requested / overlay_requested / overlay_close_requested
station.gd:348           func _make_icon(icon_path: String, tinted: bool, icon_size: float) -> TextureRect:
station.gd:350           icon.custom_minimum_size = Vector2(icon_size, icon_size)
station.gd:407           var focus_owner := get_viewport().gui_get_focus_owner()
station.gd:408           if focus_owner != null and panel.is_ancestor_of(focus_owner):
refinery_panel.gd:533    func _on_row_focused(_row: Button, payload: Dictionary) -> void:
exchange.gd:45           const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
exchange.gd:46           const ComponentCatalogScript := preload("res://game/component_catalog.gd")
```

### 5.2 Probe — `res://tests/probe_w3_lint.tscn`

New, re-runnable, deliberately **not** part of the gate (`headless_runner.gd` discovers
`test_*.gd` only; this file is `probe_*` like W2's `probe_w2_scene_uids`).

```
godot --headless --path vajb-orbit res://tests/probe_w3_lint.tscn --quit-after 600
[W3] passed=56 failed=0        (exit 0)
```

It checks four things:

1. **compile (9)** — every touched script is loaded fresh from disk
   (`ResourceLoader.CACHE_MODE_IGNORE`, so the resource cache cannot mask a parse error)
   and must be a GDScript that can be instantiated;
2. **line re-read (27)** — the construct at each recorded line, as §5.1;
3. **absence (18)** — the retired declarations must not survive anywhere in a touched
   file (`func _service(name:`, `func route(route:`, `var owner := viewport.…`,
   `const MineralCatalog := preload(`, `tinted: bool, size: float`,
   `func _on_row_focused(row: Button`, …);
4. **runtime control (4)** — the three `INT_AS_ENUM` sites are the only D5 edits with any
   semantic surface and **no gate suite drives `SettingsManager`** (`grep -rn
   "SettingsManager" tests/*.gd` is empty), so the cast is measured rather than argued:
   `_dict_to_event` must still return the event the dictionary describes —

```
[W3-PASS] mouse { "type": "mouse", "button": 2, "ctrl": true } -> button 2 ctrl true
[W3-PASS] mouse { "type": "mouse" } -> button 1 ctrl false
[W3-PASS] joy_button { "type": "joy_button", "button": 1 } -> button 1
[W3-PASS] joy_axis { "type": "joy_axis", "axis": 3, "axis_value": -1.0 } -> axis 3 value -1.0
```

### 5.3 Universal gate

```
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=226 failed=0        (exit 0)
```

`passed=219 failed=0` is the wave's declared baseline. The tree now measures **226**
because **W1's new suite landed in the shared `tests/` directory during this wave**:
`vajb-orbit/tests/test_ui_slot_layout.gd` (untracked, 7 tests) — its own logs agree
(`ui_chrome_w1_suite_before.log` → `passed=0 failed=7`,
`ui_chrome_w1_suite_after.log` → `passed=7 failed=0`). Measured with the suite excluded:

```
$ grep '^[PASS]' gate.log | grep -vc test_ui_slot_layout
219
$ grep '^[PASS]' gate.log | grep -c  test_ui_slot_layout
7
```

**No test file was edited by this pass** (no `test_*.gd` appears in the diff), and no test
was added by it; the count did not shrink. Files this pass wrote under `tests/`:
`probe_w3_lint.gd`, `probe_w3_lint.gd.uid`, `probe_w3_lint.tscn` (new, not discovered).

### 5.4 Whole-project parse

```
godot --headless --editor --path vajb-orbit --quit      -> exit 0
```

Zero `SCRIPT ERROR` / `Parse Error` / `Compile Error` lines, and no mention of any
touched file.

### 5.5 Per-file `--check-only`, with the autoload artifact controlled

| File | `--check-only --script` |
|---|---|
| `autoload/settings_manager.gd` | clean |
| `autoload/audio_manager.gd` | clean |
| `autoload/router.gd` | clean |
| `autoload/dialog_manager.gd` | clean |
| `autoload/player_profile.gd` | clean |
| `ui/screen.gd` | clean |
| `game/exchange.gd` | clean |
| `ui/screens/station.gd` | `Identifier not found: Router` at **167** — a line this pass did not touch |
| `ui/station/refinery_panel.gd` | `Identifier not found: AudioManager` at **452** — likewise |

The two rows are an artifact of isolated-script mode, **not** a defect from this pass, and
that is measured rather than asserted: the same command run on the **HEAD** copies of
those two files (extracted to `tests/`, then deleted) prints the identical rows
(`Identifier not found: Router` at station.gd:167; `Identifier not found: AudioManager` at
refinery_panel.gd:452). Autoload singletons are not registered in `--check-only --script`
mode. This is the trap **`docs/CONTRACTS.md` §9 already records** — "headless
`--check-only --script` cannot resolve autoload singletons — never use it as a gate; use
scene runs or `load()` probes" (`docs/CONTRACTS.md:662-664`) — and this pass followed that
rule: the per-file compile evidence is §5.2's `load()` probe and §5.4's editor parse, not
`--check-only`. `--check-only` is quoted here only as the negative control that shows the
two files were already "failing" it at HEAD.

### 5.6 Scope audit — no stale identifier survives a rename

For every renamed scope, the old name was grepped inside the scope's line range. This is
the check that caught the `push_overlay` near-miss (§4).

| Scope | Old name | Hits left in scope | Resolution |
|---|---|---|---|
| `router.gd route()` 83-108 | `route` | 0 (only `route_name`, `_route`, `Paths.route_*`, `&"on_route"`) | clean |
| `router.gd push_overlay()` 111-134 | `route` | 0 after the 119/134 fix (dict key `&"route"` is a string literal, kept) | **was 2, fixed** |
| `router.gd _on_route_requested` 235-236 | `route` | 0 | clean |
| `router.gd _on_overlay_requested` 239-240 | `route` | 0 | clean |
| `router.gd _find_overlay` 264-270 | `route` | 0 (`entry[&"route"]` literal kept) | clean |
| `router.gd _focus_weakref` 280-287 | `owner` | 0 | clean |
| `router.gd _service` 336-341 | `name` | 0 | clean |
| `settings_manager.gd _service` 427-432 | `name` | 0 | clean |
| `audio_manager.gd _service` 249-254 | `name` | 0 | clean |
| `dialog_manager.gd _service` 111-116 | `name` | 0 | clean |
| `player_profile.gd _read_names` 569-579 | `name` | 0 | clean |
| `player_profile.gd _names_to_strings` 733-737 | `name` | 0 | clean |
| `station.gd _make_icon` 348-356 | `size` | 0 (`Control.size` never referenced here) | clean |
| `station.gd _focus_active_panel` 401-411 | `owner` | 0 (file-wide grep: no `owner` in `station.gd` at all) | clean |
| `refinery_panel.gd _on_row_focused` 533-542 | `row` | 0 (parameter only; the caller's `.bind(row, payload)` is positional) | clean |
| `exchange.gd` file-wide | `MineralCatalog` / `ComponentCatalog` | 0 bare; 20 `…Script` sites (2 consts + 18 reads), matching the pre-pass counts | clean |

### 5.7 Contract check

- `docs/CONTRACTS.md` **pins no signature this pass touched.** Its sections are §1 input
  map, §2 `ShipStats`, §3 `ShipFit`, §4 `PlayerShip`, §5 combat/mining entities,
  §6 sector, §7 HUD, §8 economy seams, §8.1 slice 0, §8.2 slice 2, §9 the test gate,
  §10 changelog — there is no Router section and no Screen-signal section. `Router`
  appears only as prose (`:626` and `:764`, both inside §8.2's findings; `:671`, the §9
  gate note), never as a pinned parameter list. The interface the three signals belong to
  is pinned by `docs/design/IMPLEMENTATION_PLAN.md` §3.4-3.6, which
  `ui/screen.gd:5` and `autoload/router.gd:3` name in their headers, and which the doc
  block added by this pass points at.
- No public function was renamed, no signal signature changed, no default changed, no
  return type changed. The Router's four public entry points (`route`, `push_overlay`,
  `pop_overlay`, `current_route`) keep their names, parameter counts, types and defaults;
  only the local parameter label moved (`route` → `route_name`).
- `docs/**` untouched (D6 is W4's, and my file set excludes `docs/`).

---

## 6. Files touched

```
 vajb-orbit/autoload/audio_manager.gd    |  4 +--
 vajb-orbit/autoload/dialog_manager.gd   |  4 +--
 vajb-orbit/autoload/player_profile.gd   | 10 +++----
 vajb-orbit/autoload/router.gd           | 52 ++++++++++++++++-----------------
 vajb-orbit/autoload/settings_manager.gd | 10 +++----
 vajb-orbit/game/exchange.gd             | 40 ++++++++++++-------------
 vajb-orbit/ui/screen.gd                 | 10 +++++++
 vajb-orbit/ui/screens/station.gd        |  8 ++---
 vajb-orbit/ui/station/refinery_panel.gd |  2 +-
 9 files changed, 75 insertions(+), 65 deletions(-)
```

plus the new `vajb-orbit/tests/probe_w3_lint.{gd,gd.uid,tscn}`. Nothing else: no asset,
no theme, no `project.godot`, no `addons/**`, no `docs/**`, no scene file, and no
`test_*.gd`.

---

## 7. Out-of-set leftovers (reported, not touched)

The same editor batch holds **47 more GDScript warning rows** outside W3's file set. They
are listed here so the orchestrator can route them; each is the same kind of mechanical
fix, and none was touched (the PreToolUse hook would deny the write).

**In W1's file set** — `ui/components/slot_button.gd:94` (`var pressed` vs the
`BaseButton.pressed` signal), `:95` (`var disabled` vs `BaseButton.disabled`),
`ui/station/shipyard_panel.gd:321` (param `size` vs `Control.size`),
`ui/station/launch_panel.gd:246` (param `size`).
**In W2's file set** — `game/sector.gd:125` (`var fields` vs the method at 204), `:309`
(param `position` vs `Node2D.position`).
**Unowned in this wave** — `ui/station/exchange_panel.gd:24,25` (the *same two* catalogue
constants as `exchange.gd:45,46`, in the panel); `ui/hud/minimap.gd:82` (param
`world_radius` vs the method at 113); `ui/hud/target_reticle.gd:86` (param `state` vs the
method at 95); `game/projectile.gd:152` (`var source` vs the method at 216), `:224`,
`:300` (param/var `decoy`); `game/weapons.gd:221,251,410,437,456,490,519,526,561,767,778,
1002,1016,1021,1025,1033,1050,1061,1065` (18 × `weapon_id`/`weapon_ids` vs the methods at
1009/1073, plus `var owner` at 1065); `game/npc_registry.gd:541` (param `heat_tier`),
`:578` (param `floor` vs the built-in), `:739` (`var ids` vs the method at 523);
`game/npc_brain.gd:104` (params `archetype` and `row`), `:450` (`var floor`), `:477` (an
`INT_AS_ENUM_WITHOUT_CAST`); `game/asteroid.gd:184,279,300` (param `size_class` vs the
method at 228); `game/npc_ship.gd:163` (params `archetype`, `hull_id`), `:599`
(`hostility`), `:638` (iterator `faction`).

Also in the buffer, not warnings: the **10** `ext_resource, invalid UID` rows (D4, W2's
defect — 7 at scene load, 3 emitted from `router.gd:89 @ route()` when the game scene is
loaded at runtime), and **2** pathless rows (`line: 0`, empty path: "Standalone
expression"; "Values of the ternary operator are not mutually compatible") that cannot be
attributed to a file from the buffer alone.

---

## 8. Deviations and environment notes

1. **The worker-file hook needed workspace-relative paths on this host.** The session ran
   with `VAJB_WORKER_FILES` matching W3's row exactly (the hook enforces it correctly),
   but `enforce_worker_files.py::_norm` only strips the *Windows* workspace root
   (`g:/mój dysk/projekty/vajb orbit/`). On Linux an absolute target
   (`/home/.../VajbOrbit/vajb-orbit/tests/x.gd`) normalises to an absolute path that never
   matches a relative allow-entry, so **every** absolute-path write is denied, even inside
   the declared set; workspace-relative targets (`vajb-orbit/tests/x.gd`) are allowed. All
   writes in this pass used relative paths. The hook is not in my file set, so it was not
   changed — flagging it for the orchestrator (a `_norm` that also strips the Linux
   workspace root would fix it).
2. **`autoload/audio_manager.gd` is CRLF in the working tree** (254 of 254 lines) while
   HEAD is LF; the same is true today of `tests/test_engine2_cleaving.gd` and
   `tests/test_engine2_pools.gd`, which this pass never opened. So the state is
   pre-existing (a Windows↔Linux sync artifact), not introduced here; `.gitattributes`
   (`* text=auto eol=lf`) normalises it, and `git diff` shows only the 2 real changed lines
   (`warning: … CRLF will be replaced by LF the next time Git touches it`). Nothing was
   re-normalised, deliberately: converting the file would have turned a 2-line change into
   a 256-line diff.
3. **Two no-op `script_patch` calls** were made through godot-ai against `ui/screen.gd`
   and `autoload/settings_manager.gd` while testing whether an editor-side reload re-logs
   warnings (it does not — §1). Both wrote the files back byte-identical (`git diff` clean
   at the time; the eventual diffs contain only the D5 hunks).
4. **No game run was performed.** The `project_run` recipe in §1 was left to W5/the
   close-out on purpose: the tree carries W1's and W2's in-flight edits, and a boot would
   touch `user://profile.cfg` (the L17/hygiene concern) for a measurement the brief does
   not require from this worker.
5. **Seam to flag for W4 (D6) and the close-out: the gate's number moved during this
   wave.** D6 says `docs/CONTRACTS.md` §9's expected-count line "still says `passed=217`
   where the measured gate is **219**" — but the tree now measures **226/0** (exit 0),
   because W1's new `tests/test_ui_slot_layout.gd` supplies 7 of them (measured:
   `219 - 7` split, §5.3; W1's own logs agree). Writing 219 into §9 would leave the doc
   stale by 7 the moment this wave closes. Whatever number §9 ends up stating should be the
   tree's measured value with its composition recorded (219 pre-wave + 7 from the slot-layout
   suite), and it belongs to a worker whose file set includes `docs/` — this pass did not
   touch `docs/**`.

---

## 9. Acceptance check against the brief

| Brief line (W3 row) | Status |
|---|---|
| `INT_AS_ENUM_WITHOUT_CAST` `settings_manager.gd:391,400,405` gone | done, §2 #1-3, measured §5.2 |
| `SHADOWED_VARIABLE(_BASE_CLASS)` in `router.gd`, `audio_manager.gd`, `dialog_manager.gd`, `player_profile.gd`, `station.gd:348,407` gone | done — 13 rows across those five files, §2 #4-14, #18-19, #22 (the brief's file list plus the two extra rows it did not enumerate) |
| `UNUSED_SIGNAL` `ui/screen.gd:7-9` — signal kept + consumer documented | done, §2 #15-17 and §2.1: signals kept byte-identical, waivers added, emitters and the Router binding named in-file |
| unused parameter `refinery_panel.gd:533` | done, §2 #20 |
| `SHADOWED_GLOBAL_IDENTIFIER` `exchange.gd:45` | done, §2 #21 (and its sibling on line 46, §3) |
| verified by re-reading the same line numbers | done, §5.1 (probe-asserted, not eyeballed) |
| clean parse of every touched file | done, §5.2 (9 fresh compiles) + §5.4 (editor parse) + §5.5 (per-file, artifact controlled) |
| no behaviour change | argued per item (positional renames + the engine-prescribed cast), measured for the only semantic surface (§5.2 item 4) and by the 219 pre-existing gate tests (§5.3) |
| gate green, same test count, no test edited to hide a warning | done, §5.3: 226/0 exit 0 = 219 baseline + W1's 7; no test file in this pass's diff |
