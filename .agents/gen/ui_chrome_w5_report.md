# W5 report — mandatory review of the UI-chrome wave (code lane)

Reviewer: **W5**. File set: `vajb-orbit/tests/`, `vajb-orbit/tools/`. Host: Linux
(`~/VajbOrbit`), Godot 4.7.2-stable at `~/.local/bin/godot`, 2026-09-21.
Read in full before reviewing: `.agents/gen/ui_chrome_wave_task.md` (law), then the four
worker reports `ui_chrome_w1_report.md` … `ui_chrome_w4_report.md`.

**Nothing was fixed.** Every number below is a measurement taken in this pass; each finding
names the command that reproduces it and quotes the raw output.

---

## 1. Verdict

**No HIGH findings. Two MED, ten LOW.** All four workers' acceptances are met, verified by
re-running their own probes byte-identically and by independent measurement:

| Worker | Acceptance | Verdict |
|---|---|---|
| W1 | `ignore_texture_size = true` at every plate site; 48/40 cells kept; panel width inside 1920 with the 880×876 / 873×864 art in place; strip 7×48 / 5×40; gate green | **met** — 6 insertions at the 6 named lines, strip 360×48 / 224×40, panels 1260 / 952 wide, suite 7/7 |
| W2 | every `ext_resource` UID in the two scenes matches its `.import`; no stale-UID warning; every L16 literal resolves | **met** — 6/6 uids match, probe `stale_uids=0 missing_literals=0`, zero `WARNING`, `[LIT] checked=30 missing=0` |
| W3 | every warning in the D5 list gone at its named line; clean parse; no behaviour change | **met** — 26/26 named lines hold the fixed construct, **0 warnings for all 9 files** in an engine-side per-file lint, probe `passed=56 failed=0`, no test edited |
| W4 | B2-3 sentence repointed at §9.8 item 6; §9 states the measured count; no other doc, no code | **met as briefed** — both edits present; the count it wrote (219) is already stale against the tree (MED-1) |

**The gate count I measured myself: `[SUMMARY] passed=226 failed=0`, exit 0**, 18 suites,
`[FAIL]` 0, `SCRIPT ERROR` 0, one deliberate `WARNING` (the `test_p1_clock_log` unwritable-path
probe). 219 of those 226 are the pre-wave baseline; the 7 are W1's `tests/test_ui_slot_layout.gd`.
So the contested number is **226**, and `docs/CONTRACTS.md` §9's `219` is stale by exactly 7.

Two findings head the list:

- **MED-1** — §9's expected-count line (and its arithmetic) states 219 while the wave ships a
  226-pass tree; line 657 still claims 217 is "the number this file now expects".
- **MED-2** — W3's report asserts as a measurement that "a headless run cannot observe a
  warning". **That is false**: `--headless --debug` prints every GDScript warning with its
  `res://file:line`. The wave's D5 verification was therefore done without an engine-side lint
  that was available, and the D5 closure is only now proven engine-side (by me, §5.3).

---

## 2. W1 — D3 slot-plate guard

### 2.1 The probe, re-run byte-identically — result: **byte-identical**

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn \
  --quit-after 1200 -- --suite=test_ui_slot_layout
```

```
[SUMMARY] passed=7 failed=0
```

`diff /tmp/w5/w1_suite_scoped.log .agents/gen/ui_chrome_w1_suite_after.log` → **exit 0 (no
difference)**. The full scoped run, raw:

```
[ui_slot_layout] launch with (4096.0, 4096.0) art: strip (224.0, 40.0), panel (952.0, 1985.0) (before (952.0, 1985.0))
[ui_slot_layout] shipyard with (4096.0, 4096.0) art: strip (360.0, 48.0), panel (1260.0, 1740.0) (before (1260.0, 1740.0))
[ui_slot_layout] launch: strip (224.0, 40.0) (art (873.0, 864.0)), panel minimum (952.0, 1985.0), LaunchButton minimum (71.0, 88.0), viewport (1920.0, 1080.0)
[ui_slot_layout] shipyard: strip (360.0, 48.0) (art (880.0, 876.0)), panel minimum (1260.0, 1740.0), viewport (1920.0, 1080.0)
[ui_slot_layout] hud: 5 x (48.0, 48.0) (art (880.0, 876.0)) and 40 x (40.0, 40.0) (art (873.0, 864.0))
[ui_slot_layout] slot component: weapon art (880.0, 876.0) -> cell (48.0, 48.0), cargo art (873.0, 864.0) -> cell (40.0, 40.0)
```

Same script, same art (measured below), same numbers. Art on disk, measured off the PNG
headers (`assets/ui/ui_slot_*.png`): weapon `880x876`, cargo `873x864`, inventory `882x870`.

### 2.2 The six guard sites, re-read — all present at the reported lines

| file | line | content |
|---|---|---|
| `ui/components/slot_button.tscn` | 7 | `ignore_texture_size = true` |
| `ui/components/slot_button.gd` | 61 | `ignore_texture_size = true` (first line of `configure()`) |
| `ui/station/shipyard_panel.gd` | 328 | `plate.ignore_texture_size = true` |
| `ui/station/launch_panel.gd` | 253 | `plate.ignore_texture_size = true` |
| `ui/hud/hud.gd` | 608 | `slot.ignore_texture_size = true` (`_build_weapon_slots`) |
| `ui/hud/hud.gd` | 701 | `cell.ignore_texture_size = true` (`_ensure_cargo_cells`) |

`git diff --stat` for the five files: 6 insertions, 0 deletions, no other line touched
(`slot_button.gd` 1, `slot_button.tscn` 1, `hud.gd` 2, `launch_panel.gd` 1,
`shipyard_panel.gd` 1). The documented cell sizes survive: `CELL_SIZE_WEAPON` 48,
`CELL_SIZE_CARGO` 40 in `slot_button.gd:18-19`, and both `_make_plate()`s still set
`custom_minimum_size = Vector2(size, size)` from `PLATE_SIZE`/`CARGO_PLATE_SIZE`.

### 2.3 W1's "before" column — re-measured, not trusted

W1's before column came from throwaway probes it deleted. I rebuilt the same seam in memory
(no shipped file written): `tests/probe_w5_layout.tscn` mounts the shipped scenes under a
themed 1920×1080 host, reads the guard-ON state, flips `ignore_texture_size = false` on the
live plates with `update_minimum_size()`, re-reads immediately and again after a frame, then
restores the guard.

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_w5_layout.tscn --quit-after 300
```

Raw (`.agents/gen/ui_chrome_w5_layout_probe.log`):

```
[W5-LAYOUT] viewport=(1920, 1080)
[W5-LAYOUT] shipyard on: strip (360.0, 48.0) panel (1260.0, 1324.0) statsbox (360.0, 396.0) (art (880.0, 876.0), separation 4, children 7)
[W5-LAYOUT] shipyard guard-off immediate: strip (6184.0, 876.0) panel (7084.0, 1324.0) statsbox (6184.0, 1224.0)
[W5-LAYOUT] shipyard guard-off frame1: strip (6184.0, 876.0) panel (7084.0, 1277.0) statsbox (6184.0, 1224.0)
[W5-LAYOUT] shipyard guard-restored: strip (360.0, 48.0) panel (1260.0, 449.0) statsbox (360.0, 396.0)
[W5-LAYOUT] launch on: strip (224.0, 40.0) panel (952.0, 1985.0) launchbutton (71.0, 88.0) (art (873.0, 864.0), separation 6, children 5)
[W5-LAYOUT] launch guard-off immediate: strip (4389.0, 864.0) panel (4781.0, 2809.0) launchbutton (71.0, 88.0)
[W5-LAYOUT] launch guard-off frame1: strip (4389.0, 864.0) panel (4781.0, 1339.0) launchbutton (71.0, 88.0)
[W5-LAYOUT] launch guard-restored: strip (224.0, 40.0) panel (952.0, 515.0) launchbutton (71.0, 88.0)
[W5-LAYOUT] component weapon on: cell (48.0, 48.0) (art (880.0, 876.0), ignore=true)
[W5-LAYOUT] component weapon off immediate: cell (880.0, 876.0)
[W5-LAYOUT] component weapon off frame1: cell (880.0, 876.0)
[W5-LAYOUT] component cargo on: cell (40.0, 40.0) (art (873.0, 864.0), ignore=true)
[W5-LAYOUT] component cargo off immediate: cell (873.0, 864.0)
[W5-LAYOUT] component cargo off frame1: cell (873.0, 864.0)
[W5-LAYOUT] hud on: weapons 5 first (48.0, 48.0) (art (880.0, 876.0)), cargo 40 first (40.0, 40.0) (art (873.0, 864.0))
[W5-LAYOUT] hud guard-off immediate: 5/5 weapons read 880x876, 40/40 cargo read 873x864
[W5-LAYOUT] hud guard-off frame1: first weapon (880.0, 876.0), first cargo (873.0, 864.0)
```

Against W1's table:

| reading | W1 "before" | W5 measured before | W1 "after" | W5 measured after |
|---|---|---|---|---|
| shipyard strip (7 cells) | 6184 × 876 | **6184 × 876** | 360 × 48 | **360 × 48** |
| shipyard stats column | 6184 × 1224 | **6184 × 1224** | 360 × 396 | **360 × 396** |
| shipyard panel root min | 7084 × 1740 | **7084 × (1324/1740)** † | 1260 × 1740 | **1260 × (1324/1740)** † |
| launch strip (5 cells) | 4389 × 864 | **4389 × 864** | 224 × 40 | **224 × 40** |
| launch panel root min | 4781 × 2809 | **4781 × 2809** | 952 × 1985 | **952 × 1985** |
| LaunchButton min | 71 × 88 | **71 × 88** | 71 × 88 | **71 × 88** |
| slot cell, weapon art | 880 × 876 | **880 × 876** | 48 × 48 | **48 × 48** |
| slot cell, cargo art | 873 × 864 | **873 × 864** | 40 × 40 | **40 × 40** |
| HUD weapon cells | 880 × 876 each | **5/5 read 880 × 876** | 48 each | **48 each** |
| HUD cargo cells | 873 × 864 each | **40/40 read 873 × 864** | 40 each | **40 each** |
| strip under 4096² art | — | 360 × 48 / 224 × 40 | unchanged | **unchanged (suite + probe)** |
| viewport | 1920 × 1080 | **1920 × 1080** (from `project.godot`) | — | — |

† **the panel height is not a stable number** — see **LOW-1**. Every *width* in the table
reproduces exactly; the two panel *heights* move with the instant the reading is taken
(1740 on one process run, 1324 on another, 1277 at frame 1, 449 once layout settles).

The playtest reconciliation is arithmetically sound and now measured at both ends: 6184 =
7 × 880 + 6 × 4, 4389 = 5 × 873 + 4 × 6, and the panel roots are 7084 / 4781 with the guard
off. The playtest's `x = −2393` = (2298 − 7084) / 2 closes on the measured 7084 given the
playtest's own 2298 px host width, which I did **not** re-measure — it is the playtest's
figure, not W1's.

The suite is also not vacuous in the other direction: measurement shows a fresh read after
`update_minimum_size()` recomputes immediately (880 × 876 on the very next line), so W1's
`after == before` assertion on the 4096² art is a real reading and not a stale cache.

---

## 3. W2 — D4 stale ext_resource UIDs

### 3.1 The probe re-run — clean, zero warnings

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_w2_scene_uids.tscn --quit-after 120
```

```
[UID] res://game/player_ship.tscn res://game/player_ship.gd declared=uid://bxmaw3m6d4wav engine=uid://bxmaw3m6d4wav OK
[UID] res://game/player_ship.tscn res://assets/ships/ship_vanguard_side.png declared=uid://c7myl1rn82g5b engine=uid://c7myl1rn82g5b OK
[UID] res://game/game.tscn res://game/game.gd declared=uid://cl63txknckawf engine=uid://cl63txknckawf OK
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer1.png declared=uid://fv4vfbadcprt engine=uid://fv4vfbadcprt OK
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer2.png declared=uid://b4nhnjtgrej5n engine=uid://b4nhnjtgrej5n OK
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer3.png declared=uid://di3dmpv64ldaa engine=uid://di3dmpv64ldaa OK
[SWEEP] scenes=26 stale_in_sweep=0
[LIT] checked=30 missing=0
[PROBE] stale_uids=0 missing_literals=0
```

`grep -c WARNING` over that output: **0**. `[SWEEP] scenes=26` where W2 recorded 24 then 25 —
the probe's own report text says the count tracks the tree, and it does (three probes were
added between W2 and me). `stale_in_sweep=0` is the value that matters.

### 3.2 Independent, engine-free cross-check of every ext_resource

W2's check is engine-driven. I wrote a second, text-level check that does not use Godot at
all: for each `ext_resource` line in every `.tscn`/`.tres` (vendored `addons/` excluded) it
resolves the authority for that path — `.import` for an imported asset, `.uid` for a script,
the `[gd_resource]`/`[gd_scene]` header for a resource — and compares. `tools/w5_uidcheck.py`.

```sh
python3 vajb-orbit/tools/w5_uidcheck.py vajb-orbit game.tscn player_ship.tscn
```

```
[UIDCHK] game/game.tscn:3 res://game/game.gd type=Script src=gd.uid declared=uid://cl63txknckawf OK
[UIDCHK] game/game.tscn:4 res://assets/env/tile/env_stars_layer1.png type=Texture2D src=.import declared=uid://fv4vfbadcprt OK
[UIDCHK] game/game.tscn:5 res://assets/env/tile/env_stars_layer2.png type=Texture2D src=.import declared=uid://b4nhnjtgrej5n OK
[UIDCHK] game/game.tscn:6 res://assets/env/tile/env_stars_layer3.png type=Texture2D src=.import declared=uid://di3dmpv64ldaa OK
[UIDCHK] game/player_ship.tscn:3 res://game/player_ship.gd type=Script src=gd.uid declared=uid://bxmaw3m6d4wav OK
[UIDCHK] game/player_ship.tscn:4 res://assets/ships/ship_vanguard_side.png type=Texture2D src=.import declared=uid://c7myl1rn82g5b OK
[UIDCHK] SUMMARY scope=['game.tscn', 'player_ship.tscn'] ext_resources=6 stale=0 no_uid_declared=0 missing_paths=0 no_authority=0
```

All six `ext_resource` entries in the two scenes match their authorities (the `game.gd` and
`player_ship.gd` entries are scripts, so their authority is the `.uid` sidecar, not a
`.import` file). Project-wide:

```
[UIDCHK] SUMMARY scope=ALL ext_resources=97 stale=0 no_uid_declared=71 missing_paths=0 no_authority=2
```

**0 stale uids and 0 missing paths anywhere in the project.** The 71 `no_uid_declared` are
path-only references (no uid written) and are silent — proven, not assumed: `slot_button.tscn`
is one of them, it is instantiated by the gate and by `test_ui_slot_layout`, and neither the
engine probe nor the `--debug` gate emits a warning for it. The 2 `no_authority` are
`menu_button.tscn` and `dialog.tscn`, which carry no uid in their own `[gd_scene]` header, so
there is nothing to compare.

### 3.3 The writer's normalisation is inert — values re-read

The probe's `[PROP]` lines, re-run by me, are unchanged from W2's §4 table:

```
[PROP] player_ship group=true texture=res://assets/ships/ship_vanguard_side.png scale=(0.0663, 0.0663) layer=2 mask=1 gravity=0.0
[PROP] player_ship contact_monitor=true max_contacts=4 can_sleep=false damp=lin:1/ang:1 radius=30.0
[PROP] game StarsLayer1 texture=res://assets/env/tile/env_stars_layer1.png repeat=2 mirror=(2048.0, 2048.0) size=(2048.0, 2048.0)
```

`mask=1` is the load-bearing one: the re-save **deleted** the explicit `collision_mask = 1`
line from `player_ship.tscn`, and `docs/CONTRACTS.md` §4 pins `HullBody` as "layer 2, mask 1
= the rock layer, `gravity_scale = 0.0`, `contact_monitor = true`, `max_contacts_reported =
4`, `can_sleep = false`, `damp_mode` REPLACE". Every one of those is read back out of the
instantiated scene above and matches the pin, so the contract holds by measurement rather than
by the text of the file. Good call by W2 to re-read instead of arguing.

### 3.4 Idempotency hashes

```sh
sha256sum game/player_ship.tscn game/game.tscn
cf953d4a740652cd19832dc3660264a8d40d89eaf78563e1ee8e70cb8ab142d8  game/player_ship.tscn
016c240b0cf71eaa2d06ae5c94eabc5a485a2aee37ffbe6a296b5c6c8d90d80a  game/game.tscn
```

Both match W2's §2 hashes exactly. `git diff --stat`: `game.tscn` 6 lines, `player_ship.tscn`
19 lines, 12 insertions / 13 deletions — matches the report. I read both diffs in full:
`game.tscn` is the three uid lines and nothing else; `player_ship.tscn` is the two uid fixes
plus the writer's normal form (scene uid gained, node `unique_id`s gained, `load_steps=4`
dropped, `collision_mask = 1` dropped as the default, property order sorted).

### 3.5 The 7 historical editor rows — confirmed as W2 describes

`logs_read(source="editor")` returns 53 rows, of which exactly **7** are
`ext_resource, invalid UID`, naming only the four pre-fix uids (`cmi25sgdnd7ga`,
`o68c15elst7g`, `c4l2b7bxc00k4`, `bipbl3vgvqekw`). Reading with `since_cursor=7` returns 0
more and reports `appended_total: 7`, so those 7 are the entire Logger-backed set and nothing
was appended after the fix — the same conclusion W2 reached, independently reproduced.

---

## 4. W3 — D5 lint pass

### 4.1 Every named site, re-read (26/26 hold the fixed construct)

```
settings_manager.gd:391   var button: MouseButton = int(source.get("button", 1)) as MouseButton
settings_manager.gd:400   var pad_button: JoyButton = int(source.get("button", 0)) as JoyButton
settings_manager.gd:405   var axis: JoyAxis = int(source.get("axis", 0)) as JoyAxis
settings_manager.gd:427   func _service(service_name: StringName) -> Node:
router.gd:83              func route(route_name: StringName, params: Dictionary = {}) -> void:
router.gd:111             func push_overlay(route_name: StringName, params: Dictionary = {}) -> void:
router.gd:235             func _on_route_requested(route_name: StringName, params: Dictionary) -> void:
router.gd:239             func _on_overlay_requested(route_name: StringName, params: Dictionary, _source: Node) -> void:
router.gd:264             func _find_overlay(route_name: StringName) -> Node:
router.gd:284             var focus_owner := viewport.gui_get_focus_owner()
router.gd:336             func _service(service_name: StringName) -> Node:
audio_manager.gd:249      func _service(service_name: StringName) -> Node:
dialog_manager.gd:111     func _service(service_name: StringName) -> Node:
player_profile.gd:576     var entry_name := StringName(str(value))
player_profile.gd:735     for entry_name: StringName in names:
screen.gd:14/16/18        @warning_ignore("unused_signal")
screen.gd:15/17/19        signal route_requested / overlay_requested / overlay_close_requested
station.gd:348            func _make_icon(icon_path: String, tinted: bool, icon_size: float) -> TextureRect:
station.gd:407            var focus_owner := get_viewport().gui_get_focus_owner()
refinery_panel.gd:533     func _on_row_focused(_row: Button, payload: Dictionary) -> void:
exchange.gd:45            const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
exchange.gd:46            const ComponentCatalogScript := preload("res://game/component_catalog.gd")
```

Absence audit of the 12 retired constructs across the nine files — every count **0**:
`func _service(name:`, `func route(route:`, `func push_overlay(route:`,
`_on_route_requested(route:`, `_on_overlay_requested(route:`, `_find_overlay(route:`,
`var owner :=`, `for name: StringName in names`, `tinted: bool, size: float`,
`func _on_row_focused(row: Button`, `const MineralCatalog :=`, `const ComponentCatalog :=`.
Also 0 remaining `(MouseButton|JoyButton|JoyAxis) = int(` without `as` in those files.

`ui/screen.gd`'s diff is exactly the 7-line doc block plus 3 waivers (10 insertions, 0
deletions); the three signal signatures are byte-identical to the pin
(`docs/design/IMPLEMENTATION_PLAN.md:140-142`), and `on_route` is untouched.

### 4.2 W3's probe, re-run

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_w3_lint.tscn --quit-after 600
[W3] passed=56 failed=0        (exit 0, `grep -c FAIL` = 0)
```

Matches W3's §5.2 exactly.

### 4.3 The engine-side proof W3 said could not be taken — it can, and this is MED-2

W3's §1 concludes: *"A headless run cannot observe a warning. GDScript only prints warnings
when a script debugger is attached, and a CLI run reports `debugger active=false`."* The
first half is true and the conclusion does not follow: `--headless --debug` attaches the
**local stdout debugger**, and every warning then prints with its file and line. Two
measurements:

**(a) The whole gate, with `--debug`** (`grep '^WARNING'` = 58, all attributed):

```
WARNING: The local function parameter "weapon_id" is shadowing an already-declared function at line 1073 in the current class.
     at: GDScript::reload (res://game/weapons.gd:410)
```
`grep -oE "at: GDScript::reload \(res://[^)]+\)" | sort | uniq -c` gives 46 rows across
`weapons.gd` (19), `npc_ship.gd` (4), `npc_brain.gd` (4), `projectile.gd` (3),
`npc_registry.gd` (3), `asteroid.gd` (3), `sector.gd` (2), `slot_button.gd` (2),
`shipyard_panel.gd` (1), `launch_panel.gd` (1), `target_reticle.gd` (1), `minimap.gd` (1),
plus 12 in test suites (`test_engine2_cleaving` 8, `test_p1_market` 3, `test_engine2_npc` 1,
`test_p1_repairs` 1). **Zero rows name any of the nine D5 files.** That 46 matches the
editor's live warning list line for line.

**(b) A per-file lint ledger with positive controls** — `tests/probe_w5_lint.tscn` loads one
file at a time with `CACHE_MODE_IGNORE`, so every `WARNING` between two markers belongs to
the file the opening marker names (bare engine output names no file, which is why the ledger
exists):

```sh
~/.local/bin/godot --headless --debug --path vajb-orbit res://tests/probe_w5_lint.tscn --quit-after 600
[W5-LINT] debugger_active=true
[W5-LINT] BEGIN D5 res://autoload/settings_manager.gd
[W5-LINT] END   D5 res://autoload/settings_manager.gd loaded=true
... (all nine D5 files: BEGIN then END, no WARNING line between)
[W5-LINT] BEGIN W1 res://ui/components/slot_button.gd
WARNING: ... "pressed" ... at: GDScript::reload (res://ui/components/slot_button.gd:95)
WARNING: ... "disabled" ... at: GDScript::reload (res://ui/components/slot_button.gd:96)
[W5-LINT] BEGIN POSITIVE-CONTROL res://game/weapons.gd
WARNING: ... weapon_ids ... at: GDScript::reload (res://game/weapons.gd:221)
... (19 rows for weapons.gd, 1 for minimap.gd — the positive controls)
[W5-LINT] BEGIN NEGATIVE-CONTROL res://autoload/world_clock.gd
[W5-LINT] END   NEGATIVE-CONTROL res://autoload/world_clock.gd loaded=true
```

**Every one of the nine D5 files: zero warnings, engine-side, with a method proven to detect
warnings.** D5 is closed by measurement, not only by source reading. The same ledger shows
the four warnings that *do* live in files this wave touched: `slot_button.gd:95`,
`slot_button.gd:96`, `shipyard_panel.gd:321`, `launch_panel.gd:246` (all but the last two are
in W1's set; none is on the D5 list — see LOW-4).

### 4.4 The addendum's item 3 — `push_overlay` emits a StringName, proven

The addendum places the two Callable-resolving references in `settings_manager.gd`; the
function is `router.gd:111` and `settings_manager.gd` contains no `overlay` text at all
(`grep -n "overlay" autoload/settings_manager.gd` → nothing; W3's report names `router.gd:119,
134`). The real code reads `route_name` at both: `push_warning("Router: overlay '%s' is not a
PackedScene" % route_name)` and `overlay_pushed.emit(route_name)`. Measured, not argued:

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_w5_overlay.tscn --quit-after 300
[W5-OVERLAY] signal screen_changed(route:StringName)
[W5-OVERLAY] signal overlay_pushed(route:StringName)
[W5-OVERLAY] signal overlay_popped(route:StringName)
[W5-OVERLAY] method route(route_name:StringName, params:Dictionary = <null>)
[W5-OVERLAY] method push_overlay(route_name:StringName, params:Dictionary = <null>)
[W5-OVERLAY] method pop_overlay()
[W5-OVERLAY] method current_route()
[W5-OVERLAY] bare `route` in Router resolves to type=Callable (Node(router.gd)::route), is_callable=true
[W5-OVERLAY] route_exists(dialog)=true
[W5-OVERLAY] overlay_pushed received 1 signal(s): [&"dialog"]
[W5-OVERLAY]   arg type=StringName (dialog) is_stringname=true is_callable=false equals_route=true
[W5-OVERLAY] overlay_depth=1
[W5-OVERLAY] stack entry route type=StringName (dialog) is_stringname=true
[W5-OVERLAY] _find_overlay(dialog) found=true (dedupe read works)
[W5-OVERLAY] after pop depth=0
```

Read it as four independent claims:

1. **The emitted value is a `StringName`, never a `Callable`** — `type=StringName (dialog)
   is_stringname=true is_callable=false equals_route=true`, through the exact call shape
   `DialogManager` uses (`router.call(&"push_overlay", DIALOG_ROUTE, {…})`).
2. **A consumer receives the route** — the probe's `overlay_pushed` handler appended `&"dialog"`;
   no production or test code connects to that signal, so the probe is the consumer that
   proves it. The stack entry (`_overlays.back[&"route"]`) is also a `StringName`, so
   `_find_overlay`'s dedupe read and `_pop_entries`' `overlay_popped.emit(entry[&"route"])`
   both get the route.
3. **The trap was real** — a bare `route` in `Router` resolves to `type=Callable
   (Node(router.gd)::route)`, so a surviving `% route` / `emit(route)` would have compiled and
   shipped a Callable. W3's §4 warning is correct and worth keeping.
4. **The pinned interface is intact** — the four public entry points keep their names, arity,
   types and defaults (`route`, `push_overlay`, `pop_overlay`, `current_route`), and the three
   signals keep `(route: StringName)`. Only the local parameter label moved, which GDScript
   cannot observe (no named arguments) — see LOW-2 for the doc-text consequence.

### 4.5 No behaviour change, no test edited

`git status` over `vajb-orbit/tests/`: the only `test_*.gd` change anywhere in the wave is the
new (untracked) `test_ui_slot_layout.gd`. No existing test was touched, so no test was edited
to hide a warning. The gate is green (§6). None of the new probe/suite files repoints
`PlayerProfile.save_path` (`grep -rn save_path vajb-orbit/tests/` finds only pre-existing
suites), so the L17 probe-hygiene rule was respected.

---

## 5. W4 — D6 doc ticks

### 5.1 Both edits are present and are what the report says

`git diff --stat`: `docs/CONTRACTS.md` 8 lines, `docs/gameplay/19_testing_notes.md` 3 lines;
7 insertions / 4 deletions across both — matching W4's report exactly. No code, asset, theme
or scene file is in W4's diff.

**Edit 1** (`19_testing_notes.md`, B2-3) — before `…and the step 800. Tiny coder task + a line
in \`IMPLEMENTATION_PLAN\` §9.8 follow-up.`; after `…and the step 800. Landed 2026-09-21,
recorded in \`IMPLEMENTATION_PLAN\` §9.8 item 6 with the measured bindings (see the fix note
below).` **The target exists**: `docs/design/IMPLEMENTATION_PLAN.md:412` is
"6. **Batch-2 playtest follow-up (2026-09-21).**" and carries the measured bindings
(`%ZoomPlus` → `-1` → 3200 → 2400; `%ZoomMinus` → `+1` → 3200 → 4000; clamp/step/wheel
unchanged), so the sentence now points at landed evidence instead of asking for work.

**Edit 2** (`docs/CONTRACTS.md` §9, lines 639-647) — the `Expected:` line and the arithmetic
now say 219 and name `tests/test_engine2_dock.gd` (**2**). Every other number in the paragraph
is byte-identical to HEAD (53, 16, 9, 29, 28, 20, 19, 13, 13, 17, the W6 `200` record and its
15-suite list, the W8 `217` record and its 16-suite list, the `test_p1_profile.gd:204` note).
No section was renumbered.

### 5.2 The count drift — MED-1

```sh
grep -n "217\|219\|226" docs/CONTRACTS.md
639:Expected: `[SUMMARY] passed=219 failed=0` (re-measured on this host 2026-09-21),
647:`tests/test_engine2_dock.gd` (**2**), so the total is **219** and the count
657:2026-09-21 (W8 re-review, the number this file now expects): `passed=217 failed=0`,
765:  write, or a `_docking` flag). **§9**: the expected total is the **measured 217** with
```

W4 met its brief literally: D6 said "§9 still says `passed=217` where the measured gate is
**219**", and 219 is what it wrote, from a gate log it archived
(`.agents/gen/ui_chrome_w4_gate.log`, mtime 14:27:05 — before `test_ui_slot_layout.gd`'s
14:27:57, which is why W4's own run really did measure 219). But the wave **ships** a 226-pass
tree (§6): W1's suite added 7 and §9's number did not follow. W4's report noticed the shape of
this and left the decision to the orchestrator; W3 flagged it in its §8.5.

**Class**: doc/contract drift, not a code or test defect — the gate is green and §9 itself
says "the count to read is the measured one with zero failures, never a stale total", which is
why this is MED and not HIGH. But §9 is the contract every future wave reads and the wave's
own close-out cites it, so it must be corrected before the wave is called done.

**Fix (one pass, `docs/CONTRACTS.md` only)** — line 639 and line 647: state **226** with its
composition (`219` pre-wave + `7` from `tests/test_ui_slot_layout.gd`, the D3 slot-layout
suite), keeping the `2026-09-21` date; line 657: drop "the number this file now expects" (that
parenthetical is what makes a *historical* 217 record read as the live expectation — e.g.
"before `engine2_dock` landed").

W4's own residual line numbers were both off: it reported 655 and 763; the lines are **657**
and **765**. The addendum's 657 is right; its 763 is off by two.

---

## 6. The gate, measured by me

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

```
[SUMMARY] passed=226 failed=0        (exit 0)
```
`[FAIL]` 0 · `SCRIPT ERROR` 0 · `WARNING` 1 (the `test_p1_clock_log` unwritable-path probe) ·
18 suites. Per suite, measured:

```
engine2_cleaving 9 · engine2_damage 20 · engine2_dock 2 · engine2_fixes 17 · engine2_hud 19 ·
engine2_loot 13 · engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 ·
p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 ·
p1_refinery 6 · p1_repairs 5 · ui_slot_layout 7        = 226
```

The 17 pre-existing suites reproduce W4's list exactly. Excluding W1's suite:
`grep '^\[PASS\]' | grep -v test_ui_slot_layout | wc -l` → **219**, and
`grep -c test_ui_slot_layout` → **7**. So `226 = 219 + 7` and the count grew rather than
shrank. The same command with `--debug` also measures 226/0, so the flag changes nothing about
the gate's verdict (raw output: `.agents/gen/ui_chrome_w5_gate_debug.log`).

---

## 7. Pinned signatures vs `docs/CONTRACTS.md` — the drift check

Grepped across **every** file the wave changed (the changed set is exactly W1+W2+W3+W4's
declared sets: 21 code/doc/theme paths, `git diff --stat`). Result: **no interface drift**.
`docs/CONTRACTS.md` pins nothing whose text this wave moved.

| Pin | Source | Measured |
|---|---|---|
| §4 `HullBody` = RigidBody2D layer 2, **mask 1**, `gravity_scale` 0.0, `contact_monitor` true, `max_contacts_reported` 4, `can_sleep` false, damp modes REPLACE | `docs/CONTRACTS.md:105-108` | probe `[PROP]` line: `layer=2 mask=1 gravity=0.0 contact_monitor=true max_contacts=4 can_sleep=false damp=lin:1/ang:1` — holds even though the re-save dropped the explicit `collision_mask` text |
| §4 `signal damage_taken(amount: float)` | `CONTRACTS.md:92` | `game/player_ship.gd:31` unchanged |
| §7 HUD frozen + additive API (`set_target`, `clear_target`, `set_prompt`, `set_warp_channel`, `set_pool`, `set_emergency`, `set_lock_progress`, `set_speedometer`, `hit_marker`, `lock_progress`, `speedometer_ratio`, `lock_ring`, `speedometer`, `hit_marker_node`, `target_info`, `set_target_info`) | `CONTRACTS.md:227-261` | all 16 present in `ui/hud/hud.gd` with the pinned signatures; `hud.tscn` not in the diff (file stays byte-identical, as §7 requires) |
| §8 `PlayerProfile.set_vitals(ship_id, hull, shield, fuel := FUEL_UNFILED)`, `vitals_of`, `set_ammo(weapon_id, rounds)`, `SAVE_VERSION 3`, `MIN_READABLE_VERSION 1` | `CONTRACTS.md:314-333` | all present, unchanged (`player_profile.gd:389, 375, 169, 24, 25`) |
| §3.5 autoload API — SettingsManager 8 methods + `setting_changed`, AudioManager `UiCue`/`play_ui`/`play_sfx`/`set_bus_linear`/`bus_linear`/`CUE_DIRS`, Router 3 signals + 8 methods, DialogManager 2 signals + `confirm`/`message`/`resolved`/`is_open` | `IMPLEMENTATION_PLAN.md:162-205` | all present with the pinned parameter lists and defaults (`register_row` is absent, which the same block marks "not required in Phase C") |
| Screen's three intent signals | `IMPLEMENTATION_PLAN.md:140-142` | `ui/screen.gd:15/17/19`, byte-identical |
| Router's `route`/`push_overlay` **parameter names** | `IMPLEMENTATION_PLAN.md:188-189` (`route: StringName`) | code says `route_name` — see **LOW-2**; arity, types, defaults and behaviour unchanged (measured in §4.4) |

A whole-project sweep for `res://` literals adds nothing: 479 distinct literals across 94
files, and the only reads my scanner could not resolve are string-prefix concatenations
(`"res://tests/test_"`, `"res://assets/icons/ingot/icon_ingot_" + …`), i.e. **0 genuinely
unresolved paths**. There is no environment-deferred item in this wave.

---

## 8. Findings, tiered

### MED-1 — `docs/CONTRACTS.md` §9's expected count is stale by 7

- **Tier**: MED (one fixer pass; `docs/CONTRACTS.md` only). Not HIGH: no code or test is
  wrong, §9 self-heals with "never a stale total", and the wave's acceptance criteria do not
  mention the number.
- **Repro / raw output**: §5.2 (`grep -n "217\|219\|226" docs/CONTRACTS.md` → 639 `219`,
  647 `219`, 657 `217` "the number this file now expects", 765 `217`) against §6
  (`[SUMMARY] passed=226 failed=0`).
- **Why it matters**: §9 is the pinned gate contract for every following wave, and the wave
  that grew the count is the wave that must record it. A reader following D6's own rule would
  now see 219 in the contract and 226 on the tree.
- **Fix**: 639/647 → **226** with the composition (219 pre-wave + 7 from
  `tests/test_ui_slot_layout.gd`); 657 → drop "the number this file now expects".

### MED-2 — W3's stated tooling limit is false; the wave skipped an available engine-side lint

- **Tier**: MED (one fixer pass; `docs/CONTRACTS.md` §9's trap list, and the one sentence in
  W3's report that asserts the false limit). Not HIGH: the code is correct and D5 is now
  proven closed by measurement, so nothing is left unverified.
- **Repro / raw output**: §4.3 —
  `~/.local/bin/godot --headless --debug --path vajb-orbit res://tests/probe_w5_lint.tscn --quit-after 600`
  → `[W5-LINT] debugger_active=true`, 0 warnings for all 9 D5 files, 19 for the
  `weapons.gd` positive control; and the `--debug` gate → 58 `WARNING` lines, every one
  attributed to a file, none in a D5 file.
- **Why it matters**: `docs/CONTRACTS.md` §9's trap list is where a worker looks before
  deciding what is measurable, and this pass records that warnings are observable headless.
  Without it, the next D5-style task repeats "verified by re-reading the source" when a
  complete engine-side ledger costs one command.
- **Fix**: add a fourth item to §9's trap block: `--headless --debug` attaches the local stdout
  debugger and prints `WARNING: …` with `at: GDScript::reload (res://file:line)`, so a
  per-file lint ledger is buildable by loading one file at a time between printed markers
  (`vajb-orbit/tests/probe_w5_lint.tscn` is the reference implementation); correct W3's §1
  sentence so the wave's evidence chain does not carry the false limit forward.

### LOW-1 — the panels' minimum **height** is instant-dependent, and W1's note for it is not reproducible

- **Tier**: LOW → `.agents/gen/LOW_BACKLOG.md`, with a recommendation.
- **Repro / raw output**: §2.3. The same unmodified code produced `panel (1260, 1740)` on one
  process run and `panel (1260, 1324)` on the next; one frame later `1277`, and `449` once
  layout settles. Launch: `1985` → `1339` → `515`. Every **width** is invariant
  (360/1260/224/952 on every reading).
- **What is wrong**: W1's table publishes `1260 × 1740` and `952 × 1985` as panel-root
  minimums, and its out-of-scope note concludes "both taller than the 1080 window". The
  settled minimums are 449 and 515 — inside the frame. The driver is the preview
  `TextureRect`: `shipyard_panel.gd:_update_preview_size()` and
  `launch_panel.gd:_update_preview_size()` size it against `_preview_center.size` /
  `_hull_center.size`, which is 0 until the first layout pass, so the first minimum is the
  unclamped art size and it shrinks as the box clamp starts to bite. Nothing is broken on the
  horizontal axis this wave fixed, no test asserts height (the suite asserts
  `measured.x <= viewport.x`), and the Art-independent claim in the brief is written for the
  width.
- **Recommendation**: annotate W1's two height figures as instant-dependent (one line in its
  report) and route the preview-site coupling — the same class as D3 on a different node, as
  W1 itself recorded — to a future slice rather than a fixer pass: a real fix changes the
  preview's contain-fit timing on a screen whose art the parallel graphics lane is re-cutting.
  If the orchestrator wants the wave's purpose sentence ("art can never break a panel again")
  to hold on the vertical axis too, promote this to MED — the fix is one site — but not while
  the slot/preview art is in flight.

### LOW-2 — `IMPLEMENTATION_PLAN.md` §3.4 still names the parameters `route`

- **Repro**: `grep -n "push_overlay(route\|route(route:" docs/` →
  `docs/design/IMPLEMENTATION_PLAN.md:188` `func route(route: StringName, params: Dictionary = {}) -> void`,
  `:189` `func push_overlay(route: StringName, params: Dictionary = {}) -> void`.
- **Measured against the code**: `probe_w5_overlay` prints
  `method route(route_name:StringName, params:Dictionary = <null>)` — same name, arity, types,
  defaults and behaviour; GDScript has no named arguments, so no caller can observe the label.
  This is doc text lagging a required rename, not interface drift. One-word tick for the next
  `IMPLEMENTATION_PLAN` writer (W3's file set excluded `docs/`).

### LOW-3 — `docs/CONTRACTS.md:765` (v1.1 changelog) still says the expected total is 217

- **Repro**: `grep -n "measured 217" docs/CONTRACTS.md` → line 765. Correct **as a record of
  what v1.1 wrote**; the cure is a v1.2 changelog entry, and changelog authorship was not in
  any worker's set. (W4 reported this line as 763; the addendum repeated 763; the line is
  **765**.) Fold the fix into MED-1's pass if a changelog entry is written anyway.

### LOW-4 — four warnings remain in files this wave touched, none on the D5 list

- **Repro**: §4.3's ledger → `slot_button.gd:95`, `slot_button.gd:96` (in W1's set),
  `shipyard_panel.gd:321`, `launch_panel.gd:246` (in W1's set), plus `sector.gd:125` and
  `sector.gd:309` (in W2's set). W3 reported all of these in its §7 as out of the D5 list, and
  the D5 row enumerates rows, not whole files, so they were correctly left. They are the same
  mechanical fix and belong in the backlog.

### LOW-5 — W3's "47 leftover warning rows" measures 46

- **Repro**: `grep -oE "at: GDScript::reload \(res://[^)]+\)" .agents/gen/ui_chrome_w5_gate_debug.log | wc -l`
  → 46 in project scripts (58 including 12 in test suites); the editor's live warning list
  holds the same 46. W3 derived 47 from a buffer that has since been repopulated
  (its 82 rows vs today's 53). Informational only: both counts are outside its file set, so
  nothing about the D5 closure depends on it.

### LOW-6 — W2's parenthetical about W1's suite contributing "0 passes" cannot be true

- W2's §6 says `test_ui_slot_layout.gd` "was present in the tree during this run and
  contributed 0 passes". The runner discovers by filename, so a present, parseable suite
  contributes 7 (it does today) and a present, unparseable one would have produced a load
  error, not a silent zero. Its measured 219 is consistent with the pre-suite tree — W1's
  suite file is timestamped 14:27:57 and W4's own 219 gate log 14:27:05, so 219 is simply the
  pre-suite count. Informational; the wave-end number is what MED-1 fixes.

### LOW-7 — the mockup still has the unguarded plate site (W1's finding, confirmed)

- **Repro**: `grep -n "ignore_texture_size" ui/screens/_mockup_station.gd` → no match;
  `ui/screens/_mockup_station.gd:658` sets `plate.custom_minimum_size = Vector2(size, size)`.
  `AGENTS.md` schedules `_mockup_station.tscn` for deletion at close-out; if it survives, it
  needs the guard.

### LOW-8 — `assets/ui/ui_slot_inventory_*.png` has no consumer (W1's finding, confirmed)

- **Repro**: `grep -rn "ui_slot_inventory" --include=*.gd --include=*.tscn --include=*.tres vajb-orbit`
  → no match. Four 882 × 870 plates with no site; the inventory family's re-cut is the
  graphics lane's call, not a code defect.

### LOW-9 — the worker-file hook denies absolute paths on this host

- **Repro**: any write whose `file_path` is absolute while `VAJB_WORKER_FILES` is set →
  `deny: outside this worker's declared file set`. `.crush/hooks/enforce_worker_files.py::_norm()`
  strips only the Windows workspace root (`g:/mój dysk/projekty/vajb orbit/`), so
  `/home/…/VajbOrbit/vajb-orbit/tests/x.gd` normalises to itself and never matches a relative
  allow-entry. All four workers hit it and worked around it with workspace-relative paths; so
  did I (my first write to `/tmp` was denied). `AGENTS.md`'s "always use absolute paths"
  guidance is wrong for hooked writes on this host. One-line cure: also strip the Linux
  workspace root in `_norm`.

### LOW-10 — the batch-2 evidence chain points at an archived path

- **Repro**: `ls .agents/gen/batch2_report.md` → absent; the file is at
  `.agents/gen/_archive/batch2_report.md`. `docs/gameplay/19_testing_notes.md:29,46,63` and
  `docs/design/IMPLEMENTATION_PLAN.md:412` still cite the un-archived path. W4's new sentence
  points at §9.8 item 6, which carries the measured bindings inline, so no reader is stranded —
  but the last hop of the chain is a moved file. Pre-existing, untouched by this wave.

---

## 9. Out of scope, verified as out of scope

- **The theme diff is uid stamping only — confirmed, not assumed.**
  `git diff vajb-orbit/ui/theme/vajb_theme.tres`: 20 removed / 20 added lines, and **0 pairs
  differ beyond the uid attribute** (`[gd_resource …]` gains `uid://c2flhwg6af5xm`; each of the
  19 `ext_resource` lines gains its `uid=` before `path=`). No token, stylebox, font size or
  path changed. Treated as the graphics lane's, not a finding, not reverted.
- `staging/phase_f/**`, `.agents/gen/designer_slots_report.md` and `vajb-orbit/assets/**` are
  the parallel lane's; I read none of them for findings. The only asset read was the PNG
  headers of the 12 slot plates, to prove W1's "same art" precondition (880 × 876 / 873 × 864 /
  882 × 870, unchanged).
- `game/sector.gd:125,309` and the other 40-odd pre-existing warnings are reported (LOW-4),
  not treated as wave defects: the D5 row enumerates rows, and two of those files are only in
  W2's set as *evidence* files, which W2 did not modify.

## 10. Addendum corrections (informational)

1. **`push_overlay` is in `router.gd`, not `settings_manager.gd`.** `grep -rn "push_overlay"
   --include=*.gd` finds it only in `router.gd:111` (definition), `router.gd:240` (the
   `_on_overlay_requested` forwarder), `dialog_manager.gd:81` (the caller) and the probes;
   `settings_manager.gd` has no `overlay` text at all. The substance is verified in full
   (§4.4).
2. **Line numbers**: the two 217 residuals are `docs/CONTRACTS.md:657` (addendum correct) and
   `:765` (addendum said 763; W4 said 655 and 763 — both wrong).
3. **Confirmations asked for**: line 657 and 765 both still say 217 — **confirmed**; the
   measured gate is **226**, not 219 — **confirmed**; 219 is the pre-wave baseline
   (17 suites, 219 passes) and W1's suite is the +7 — **confirmed**.

## 11. Files I wrote

Review tools (my declared set, `vajb-orbit/tools/`, `vajb-orbit/tests/`):

| Path | Role |
|---|---|
| `vajb-orbit/tools/w5_uidcheck.py` | engine-free uid cross-check (`.import` / `.uid` / header authority) |
| `vajb-orbit/tests/probe_w5_layout.gd` + `.tscn` + `.gd.uid` | two-state layout probe (W1's before column, in memory only) |
| `vajb-orbit/tests/probe_w5_lint.gd` + `.tscn` + `.gd.uid` | per-file warning ledger under `--debug`, with positive and negative controls |
| `vajb-orbit/tests/probe_w5_overlay.gd` + `.tscn` + `.gd.uid` | the `push_overlay` emit type + the Router's public signature |

Evidence logs, kept raw under `.agents/gen/`:
`ui_chrome_w5_layout_suite.log` (the byte-identical W1 re-run),
`ui_chrome_w5_layout_probe.log`, `ui_chrome_w5_uid_probe.log`, `ui_chrome_w5_lint_ledger.log`,
`ui_chrome_w5_lint_probe_w3.log`, `ui_chrome_w5_overlay_probe.log`, `ui_chrome_w5_gate.log`,
`ui_chrome_w5_gate_debug.log`, and this report.

No shipped file, asset, theme, doc, `project.godot` or addon was modified by this pass. One
transient `res://tests/_w5_editorwrite.txt` was written through the editor to test whether the
shared editor session accepts writes (it does, despite `is_playing=true`) and deleted again.

## 12. What was not verified, and why

- W1's deleted throwaway probes (`ui_chrome_w1_prefix_probe.log`, `ui_chrome_w1_cell_probe.log`)
  are logs, not re-runnable code: I re-derived their before column independently (§2.3) instead
  of reading their numbers.
- The playtest's `x = −2393` depends on the playtest's own 2298 px host width, which I did not
  re-measure; both panel roots it is derived from (7084, 4781) are measured here.
- `--quit-after` bounded runs and the no-background-command rule cannot be audited after the
  fact; no worker reported a wedge and every reported command carries `--quit-after`.
- Whether the graphics lane's re-cut changes the plate art is outside my read; the suite
  asserts cell sizes rather than art sizes, so it should stay green, but every number in §2.3
  is tied to the 880 × 876 / 873 × 864 art measured on disk today.
