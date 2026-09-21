# W2 — D4: stale `ext_resource` UIDs (wave UI-chrome, code lane)

Worker: **W2**. Declared file set: `vajb-orbit/game/game.tscn`,
`vajb-orbit/game/player_ship.tscn`, `vajb-orbit/game/pickup.gd`,
`vajb-orbit/game/sector.gd`, `vajb-orbit/game/sector_registry.gd`,
`vajb-orbit/ui/screens/loading.tscn`, `vajb-orbit/ui/screens/main_menu.tscn`,
`vajb-orbit/tests/`.

Verdict: **D4 closed** — 4 stale UIDs → 0, the engine's own warning is gone from both
scenes, and every literal in the L16 list resolves. No asset, theme, `project.godot`,
addon or doc file was modified.

## 1. What was wrong, measured

All four defects reproduce exactly as the brief measured them. The declared uid in the
scene does not equal the engine's uid for that path:

| Scene line | Asset | Scene declared (before) | `.import` / engine uid |
|---|---|---|---|
| `game/player_ship.tscn:4` | `assets/ships/ship_vanguard_side.png` | `uid://cmi25sgdnd7ga` | `uid://c7myl1rn82g5b` |
| `game/game.tscn:4` | `assets/env/tile/env_stars_layer1.png` | `uid://o68c15elst7g` | `uid://fv4vfbadcprt` |
| `game/game.tscn:5` | `assets/env/tile/env_stars_layer2.png` | `uid://c4l2b7bxc00k4` | `uid://b4nhnjtgrej5n` |
| `game/game.tscn:6` | `assets/env/tile/env_stars_layer3.png` | `uid://bipbl3vgvqekw` | `uid://di3dmpv64ldaa` |

The engine reports each one on load, in the exact form the D4 row predicted:

```
WARNING: res://game/player_ship.tscn:4 - ext_resource, invalid UID: uid://cmi25sgdnd7ga - using text path instead: res://assets/ships/ship_vanguard_side.png
     at: load (scene/resources/resource_format_text.cpp:501)
```

## 2. Fix route — the editor's own writer (the brief's sanctioned route)

Both scenes were fixed by `scene_open(force_reload=true)` → `scene_save()`, i.e. the
engine re-serialized them and wrote the uid it actually resolved. Nothing was
hand-edited, so no text edit can fight the writer.

* `game/game.tscn` — **3-line diff, nothing else**:
  ```diff
  -[ext_resource type="Texture2D" uid="uid://o68c15elst7g" path="res://assets/env/tile/env_stars_layer1.png" id="2_stars1"]
  -[ext_resource type="Texture2D" uid="uid://c4l2b7bxc00k4" path="res://assets/env/tile/env_stars_layer2.png" id="3_stars2"]
  -[ext_resource type="Texture2D" uid="uid://bipbl3vgvqekw" path="res://assets/env/tile/env_stars_layer3.png" id="4_stars3"]
  +[ext_resource type="Texture2D" uid="uid://fv4vfbadcprt" path="res://assets/env/tile/env_stars_layer1.png" id="2_stars1"]
  +[ext_resource type="Texture2D" uid="uid://b4nhnjtgrej5n" path="res://assets/env/tile/env_stars_layer2.png" id="3_stars2"]
  +[ext_resource type="Texture2D" uid="uid://di3dmpv64ldaa" path="res://assets/env/tile/env_stars_layer3.png" id="4_stars3"]
  ```
* `game/player_ship.tscn` — the uid fix plus the writer's normal form for a scene that
  had never been re-saved by this engine version: it gains a scene uid
  (`uid://4wusgnoy58y0`), gains the script ext_resource's uid
  (`uid://bxmaw3m6d4wav`), gains node `unique_id`s (which `game.tscn` already carried),
  loses `load_steps=4` (a size hint the writer recomputes) and loses
  `collision_mask = 1`, which **is Godot's default** — re-measured below as `mask=1`.
  Property order changes because the writer sorts them.

**Idempotency proof** (so the wave diff cannot drift under a later editor save): both
scenes were re-opened with `force_reload=true` and re-saved a second time, and the file
hashes did not move.

```
$ sha256sum game/player_ship.tscn game/game.tscn      # before the second re-save
cf953d4a740652cd19832dc3660264a8d40d89eaf78563e1ee8e70cb8ab142d8  game/player_ship.tscn
016c240b0cf71eaa2d06ae5c94eabc5a485a2aee37ffbe6a296b5c6c8d90d80a  game/game.tscn
$ sha256sum game/player_ship.tscn game/game.tscn      # after it
cf953d4a740652cd19832dc3660264a8d40d89eaf78563e1ee8e70cb8ab142d8  game/player_ship.tscn
016c240b0cf71eaa2d06ae5c94eabc5a485a2aee37ffbe6a296b5c6c8d90d80a  game/game.tscn
```

Diff footprint: `game.tscn` 6 lines, `player_ship.tscn` 19 lines (12 insertions,
13 deletions across both).

## 3. Evidence — bounded headless probe, raw output

The probe is `vajb-orbit/tests/probe_w2_scene_uids.gd` + `.tscn` (deliberately *not*
`test_`-prefixed, so the pinned gate count is untouched). It is read-only. It rebuilds the
engine's own check (`ResourceLoader.get_resource_uid(path)` vs the uid the scene
declares), then `load()`s both scenes so the engine itself prints its warning if one is
left, then audits every `res://` literal in the L16 files, then sweeps every `.tscn` in
the project.

Command (this host, Linux):

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_w2_scene_uids.tscn --quit-after 120
```

The probe always exits 0; the gate signal is the last line,
`[PROBE] stale_uids=<n> missing_literals=<n>`.

### 3.1 Before the fix — raw

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[PROBE] W2 start
[UID] res://game/player_ship.tscn res://game/player_ship.gd declared=<none> engine=uid://bxmaw3m6d4wav OK
[UID] res://game/player_ship.tscn res://assets/ships/ship_vanguard_side.png declared=uid://cmi25sgdnd7ga engine=uid://c7myl1rn82g5b STALE
[UID] res://game/game.tscn res://game/game.gd declared=uid://cl63txknckawf engine=uid://cl63txknckawf OK
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer1.png declared=uid://o68c15elst7g engine=uid://fv4vfbadcprt STALE
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer2.png declared=uid://c4l2b7bxc00k4 engine=uid://b4nhnjtgrej5n STALE
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer3.png declared=uid://bipbl3vgvqekw engine=uid://di3dmpv64ldaa STALE
WARNING: res://game/player_ship.tscn:4 - ext_resource, invalid UID: uid://cmi25sgdnd7ga - using text path instead: res://assets/ships/ship_vanguard_side.png
     at: load (scene/resources/resource_format_text.cpp:501)
     GDScript backtrace (most recent call first):
         [0] _load_scene (res://tests/probe_w2_scene_uids.gd:81)
         [1] _ready (res://tests/probe_w2_scene_uids.gd:41)
[LOAD] res://game/player_ship.tscn ok (2 ext_resources, 4 nodes)
WARNING: res://game/player_ship.tscn:4 - ext_resource, invalid UID: uid://cmi25sgdnd7ga - using text path instead: res://assets/ships/ship_vanguard_side.png
     at: load (scene/resources/resource_format_text.cpp:501)
     GDScript backtrace (most recent call first):
         [0] _load_scene (res://tests/probe_w2_scene_uids.gd:81)
         [1] _ready (res://tests/probe_w2_scene_uids.gd:41)
WARNING: res://game/game.tscn:4 - ext_resource, invalid UID: uid://o68c15elst7g - using text path instead: res://assets/env/tile/env_stars_layer1.png
     at: load (scene/resources/resource_format_text.cpp:501)
     GDScript backtrace (most recent call first):
         [0] _load_scene (res://tests/probe_w2_scene_uids.gd:81)
         [1] _ready (res://tests/probe_w2_scene_uids.gd:41)
WARNING: res://game/game.tscn:5 - ext_resource, invalid UID: uid://c4l2b7bxc00k4 - using text path instead: res://assets/env/tile/env_stars_layer2.png
     at: load (scene/resources/resource_format_text.cpp:501)
     GDScript backtrace (most recent call first):
         [0] _load_scene (res://tests/probe_w2_scene_uids.gd:81)
         [1] _ready (res://tests/probe_w2_scene_uids.gd:41)
WARNING: res://game/game.tscn:6 - ext_resource, invalid UID: uid://bipbl3vgvqekw - using text path instead: res://assets/env/tile/env_stars_layer3.png
     at: load (scene/resources/resource_format_text.cpp:501)
     GDScript backtrace (most recent call first):
         [0] _load_scene (res://tests/probe_w2_scene_uids.gd:81)
         [1] _ready (res://tests/probe_w2_scene_uids.gd:41)
[LOAD] res://game/game.tscn ok (4 ext_resources, 9 nodes)
[LIT] res://game/pickup.gd res://game/economy_log.gd OK
[LIT] res://game/pickup.gd res://game/ship_fit.gd OK
[LIT] res://game/pickup.gd res://game/mineral_catalog.gd OK
[LIT] res://game/pickup.gd res://assets/env/pickup/env_pickup_ore_pod.png OK
[LIT] res://game/sector.gd res://game/sector_registry.gd OK
[LIT] res://game/sector.gd res://autoload/world_clock.gd OK
[LIT] res://game/sector.gd res://game/npc_registry.gd OK
[LIT] res://game/sector.gd res://game/npc_ship.gd OK
[LIT] res://game/sector.gd res://game/ship_fit.gd OK
[LIT] res://game/sector.gd res://game/asteroid_field.gd OK
[LIT] res://game/sector.gd res://assets/env/poi/env_station.png OK
[LIT] res://game/sector_registry.gd res://game/mineral_catalog.gd OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_1_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_2_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_3_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_4_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_5_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_6_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_7_bg.png OK
[LIT] res://ui/screens/loading.tscn res://ui/screens/loading.gd OK
[LIT] res://ui/screens/loading.tscn res://ui/theme/vajb_theme.tres OK
[LIT] res://ui/screens/loading.tscn res://assets/env/backdrop/env_loading_bg.png OK
[LIT] res://ui/screens/main_menu.tscn res://ui/theme/vajb_theme.tres OK
[LIT] res://ui/screens/main_menu.tscn res://assets/env/backdrop/env_menu_bg.png OK
[LIT] res://ui/screens/main_menu.tscn res://assets/fx/fx_ember_pulse.png OK
[LIT] res://ui/screens/main_menu.tscn res://ui/theme/grain.tres OK
[LIT] res://ui/screens/main_menu.tscn res://ui/components/menu_button.tscn OK
[LIT] res://ui/screens/main_menu.tscn res://assets/ui/logo_vajb_orbit.png OK
[LIT] res://ui/screens/main_menu.tscn res://assets/ui/ui_insignia_neutral.png OK
[LIT] res://ui/screens/main_menu.tscn res://ui/screens/main_menu.gd OK
[L16] checked=30 missing=0
[PROBE] stale_uids=4 missing_literals=0
```

(That run is the pre-extension probe: it predates the `[PROP]`/`[SWEEP]` sections added
in §3.2. Its `exit=0` was the hardcoded quit; the count line is the signal either way.)

### 3.2 After the fix — raw

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[PROBE] W2 start
[UID] res://game/player_ship.tscn res://game/player_ship.gd declared=uid://bxmaw3m6d4wav engine=uid://bxmaw3m6d4wav OK
[UID] res://game/player_ship.tscn res://assets/ships/ship_vanguard_side.png declared=uid://c7myl1rn82g5b engine=uid://c7myl1rn82g5b OK
[UID] res://game/game.tscn res://game/game.gd declared=uid://cl63txknckawf engine=uid://cl63txknckawf OK
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer1.png declared=uid://fv4vfbadcprt engine=uid://fv4vfbadcprt OK
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer2.png declared=uid://b4nhnjtgrej5n engine=uid://b4nhnjtgrej5n OK
[UID] res://game/game.tscn res://assets/env/tile/env_stars_layer3.png declared=uid://di3dmpv64ldaa engine=uid://di3dmpv64ldaa OK
[LOAD] res://game/player_ship.tscn ok (2 ext_resources, 4 nodes)
[PROP] player_ship group=true texture=res://assets/ships/ship_vanguard_side.png scale=(0.0663, 0.0663) layer=2 mask=1 gravity=0.0
[PROP] player_ship contact_monitor=true max_contacts=4 can_sleep=false damp=lin:1/ang:1 radius=30.0
[LOAD] res://game/game.tscn ok (4 ext_resources, 9 nodes)
[PROP] game StarsLayer1 texture=res://assets/env/tile/env_stars_layer1.png repeat=2 mirror=(2048.0, 2048.0) size=(2048.0, 2048.0)
[PROP] game StarsLayer2 texture=res://assets/env/tile/env_stars_layer2.png repeat=2 mirror=(2048.0, 2048.0) size=(2048.0, 2048.0)
[PROP] game StarsLayer3 texture=res://assets/env/tile/env_stars_layer3.png repeat=2 mirror=(2048.0, 2048.0) size=(2048.0, 2048.0)
[LIT] res://game/pickup.gd res://game/economy_log.gd OK
[LIT] res://game/pickup.gd res://game/ship_fit.gd OK
[LIT] res://game/pickup.gd res://game/mineral_catalog.gd OK
[LIT] res://game/pickup.gd res://assets/env/pickup/env_pickup_ore_pod.png OK
[LIT] res://game/sector.gd res://game/sector_registry.gd OK
[LIT] res://game/sector.gd res://autoload/world_clock.gd OK
[LIT] res://game/sector.gd res://game/npc_registry.gd OK
[LIT] res://game/sector.gd res://game/npc_ship.gd OK
[LIT] res://game/sector.gd res://game/ship_fit.gd OK
[LIT] res://game/sector.gd res://game/asteroid_field.gd OK
[LIT] res://game/sector.gd res://assets/env/poi/env_station.png OK
[LIT] res://game/sector_registry.gd res://game/mineral_catalog.gd OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_1_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_2_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_3_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_4_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_5_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_6_bg.png OK
[LIT] res://game/sector_registry.gd res://assets/env/backdrop/env_sector_7_bg.png OK
[LIT] res://ui/screens/loading.tscn res://ui/screens/loading.gd OK
[LIT] res://ui/screens/loading.tscn res://ui/theme/vajb_theme.tres OK
[LIT] res://ui/screens/loading.tscn res://assets/env/backdrop/env_loading_bg.png OK
[LIT] res://ui/screens/main_menu.tscn res://ui/theme/vajb_theme.tres OK
[LIT] res://ui/screens/main_menu.tscn res://assets/env/backdrop/env_menu_bg.png OK
[LIT] res://ui/screens/main_menu.tscn res://assets/fx/fx_ember_pulse.png OK
[LIT] res://ui/screens/main_menu.tscn res://ui/theme/grain.tres OK
[LIT] res://ui/screens/main_menu.tscn res://ui/components/menu_button.tscn OK
[LIT] res://ui/screens/main_menu.tscn res://assets/ui/logo_vajb_orbit.png OK
[LIT] res://ui/screens/main_menu.tscn res://assets/ui/ui_insignia_neutral.png OK
[LIT] res://ui/screens/main_menu.tscn res://ui/screens/main_menu.gd OK
[SWEEP] scenes=24 stale_in_sweep=0
[L16] checked=30 missing=0
[PROBE] stale_uids=0 missing_literals=0
```

`grep -c WARNING` over that output: **0**. Both scenes load, all four uid pairs match,
and every structural value a consumer can read is unchanged (§4).

The `[SWEEP]` line audits **every project scene** (the vendored `addons/` tree
excluded) — 24 at the recorded run, 25 on the final confirmation re-run, because the
tree gained a scene while this pass was in flight; the count tracks the tree and the
number that matters is `stale_in_sweep=0`. It reads 0 stale, and since the only files
this worker wrote are the two named scenes, no other scene can have been stale before the
fix either. Cross-checked outside Godot on the whole text tree: 26 `.tscn`/`.tres` files,
93 `ext_resource` entries, `missing_paths=0 stale_uids=0`.

### 3.3 Editor-side confirmation

The editor (`session vajb-orbit@e33a3a6d694802ed`, pid 63876) was open for the whole
pass, and was the writer for both fixes.

* Its log buffer holds exactly **7** `invalid UID` rows, all naming the four pre-fix
  uids (`cmi25sgdnd7ga`, `o68c15elst7g`, `c4l2b7bxc00k4`, `bipbl3vgvqekw`): 3 from the
  editor's own startup load of `game.tscn` (the current scene) and 4 from the two
  pre-fix `scene_open` calls. They are **historical**, not live.
* Re-opening and re-saving both scenes after the fix appended **nothing**:
  `logs_read(source="editor", since_cursor=7)` → `returned_count: 0`,
  `appended_total: 7`.
* `editor_state` after the pass: `current_scene = res://game/game.tscn` (the same scene
  the session started on), `readiness = ready`, `play_state = stopped`.

The 7 historical rows were **not** cleared: the debugger/log surface is shared with W3,
which was actively reading it to verify its lint fixes. `editor_manage(op="logs_clear")`
drops them when the wave is done.

## 4. No behaviour change (the re-save touched more than the uid line)

The re-save re-serialized `player_ship.tscn`. Every value below was read back out of the
instantiated scene (§3.2 `[PROP]` lines), so the normalisation is proven inert:

| Value | Before (declared in the file) | After (read from the loaded scene) |
|---|---|---|
| root `groups` | `["player_ship"]` | `group=true` |
| `Hull.texture` | `ExtResource("2_hull")` | `res://assets/ships/ship_vanguard_side.png` |
| `Hull.scale` | `(0.0663, 0.0663)` | `(0.0663, 0.0663)` |
| `HullBody.collision_layer` | `2` | `layer=2` |
| `HullBody.collision_mask` | `1` — **implicit default**, the writer omits it | `mask=1` |
| `HullBody.gravity_scale` | `0.0` | `gravity=0.0` |
| `HullBody.contact_monitor` | `true` | `contact_monitor=true` |
| `HullBody.max_contacts_reported` | `4` | `max_contacts=4` |
| `HullBody.can_sleep` | `false` | `can_sleep=false` |
| `HullBody.linear/angular_damp_mode` | `1` / `1` | `damp=lin:1/ang:1` |
| `Shape.shape.radius` | `30.0` | `radius=30.0` |
| 3 × `TextureRect.texture` | `ExtResource(...)` | the three `env/tile` paths |
| 3 × `TextureRect.texture_repeat` | `2` | `repeat=2` |
| 3 × `ParallaxLayer.motion_mirroring` | `(2048, 2048)` | `mirror=(2048.0, 2048.0)` |
| 3 × offset rect | `2048 × 2048` | `size=(2048.0, 2048.0)` |

`layer=2 / mask=1` also keeps the physics contract `game/asteroid.gd:55`,
`game/projectile.gd:28` and `game/npc_ship.gd:9` document against
(`player_ship.tscn`'s `HullBody`).

## 5. L16 literal re-check — **all resolve, 0 environment items**

`[LIT] checked=30 missing=0`. Every `res://` literal in the five files the brief names
resolves, by engine `ResourceLoader.exists()` or by `FileAccess.file_exists()`:

| File | literals | unresolved |
|---|---|---|
| `game/pickup.gd` | 4 | 0 |
| `game/sector.gd` | 7 | 0 |
| `game/sector_registry.gd` | 8 | 0 |
| `ui/screens/loading.tscn` | 3 | 0 |
| `ui/screens/main_menu.tscn` | 8 | 0 |
| **total** | **30** | **0** |

`game/game.tscn` is not in the W2 row's L16 list (D4 names it for the uid instead), but
its three asset literals are covered transitively: the `[UID]` lines resolve each path to
its `.import` uid with `ResourceLoader.get_resource_uid()`, which returns `INVALID_ID`
for a path that is not there. All three resolve. So this matches the graphics lane's
`asset_path_fallout.md` finding (181 literals, 0 unresolvable) — **the re-layout left the
paths correct and only the uid field stale**, and the uid field is now correct too.

**No environment item to report.**

## 6. Gate

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

```
[SUMMARY] passed=219 failed=0
```

Exit 0, `grep -c "[FAIL]"` = 0. Per-suite: `test_engine2_weapons` 29, `test_engine2_npc`
28, `test_engine2_damage` 20, `test_engine2_hud` 19, `test_engine2_fixes` 17,
`test_engine2_pools` 16, `test_p1_market` 13, `test_engine2_wiring` 13,
`test_engine2_loot` 13, `test_p1_catalogues` 11, `test_p1_profile` 9,
`test_engine2_cleaving` 9, `test_p1_refinery` 6, `test_p1_repairs` 5,
`test_p1_pricing` 5, `test_p1_clock_log` 4, `test_engine2_dock` 2 → 219.

Count unchanged from the wave's pre-wave baseline (219), because the probe is not
`test_`-prefixed so the runner does not discover it. (`test_ui_slot_layout.gd`, W1's, was
present in the tree during this run and contributed 0 passes at that moment.)

## 7. Deviations, and what the reviewer should check

1. **Harness deviation (LOW, not a code finding).** `.crush/hooks/enforce_worker_files.py`
   `_norm()` only maps the Windows root (`g:/mój dysk/projekty/vajb orbit/`); on Linux an
   **absolute** `file_path` normalises to `/home/.../vajborbit/vajb-orbit/...`, which never
   matches the relative allow-list, so every write is denied with
   `outside this worker's declared file set`. Workaround used: issue every write with a
   workspace-**relative** path (`vajb-orbit/tests/...`), which the hook matches. Same
   class of Windows-only assumption the wave brief already patches in `verify_wave.py
   --tests`; this hook is not patched.
2. **Shared-surface note.** The editor log buffer keeps the 7 historical pre-fix rows
   (§3.3) because W3 was reading that surface concurrently. A reviewer who greps the
   editor log for `invalid UID` and finds rows must check their uids — the four pre-fix
   uids are the whole content; nothing was appended after the fix.
3. **Files dirty in the tree that are not mine** (for attribution, not a finding):
   `docs/CONTRACTS.md`, `docs/gameplay/19_testing_notes.md` (W4), `vajb-orbit/ui/theme/
   vajb_theme.tres` — a re-save that adds the uids the file never carried (so it was
   never a stale-uid source) — plus `staging/phase_f/recut_slots*.py|json` (the parallel
   art/theme lane, D1/D2),
   `vajb-orbit/tests/_w3_*_tmp.gd` (W3), `vajb-orbit/tests/test_ui_slot_layout.gd` (W1).
   The only paths this worker wrote are `vajb-orbit/game/game.tscn`,
   `vajb-orbit/game/player_ship.tscn`, `vajb-orbit/tests/probe_w2_scene_uids.gd`,
   `vajb-orbit/tests/probe_w2_scene_uids.tscn` and this report.
4. **For W5 (re-run byte-identically).**
   `~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_w2_scene_uids.tscn --quit-after 120`
   must print `[PROBE] stale_uids=0 missing_literals=0`, `[SWEEP]
   scenes=<live count> stale_in_sweep=0` (24 at the recorded run, 25 on the final
   confirmation run — the count tracks the tree), `[LIT] checked=30 missing=0` and zero
   `WARNING` lines, and
   `sha256sum vajb-orbit/game/{game,player_ship}.tscn` must be
   `016c240b0cf71eaa2d06ae5c94eabc5a485a2aee37ffbe6a296b5c6c8d90d80a` and
   `cf953d4a740652cd19832dc3660264a8d40d89eaf78563e1ee8e70cb8ab142d8`.
5. **Backlog suggestion (LOW).** Promote the probe's check into a `test_`-prefixed suite
   that exits non-zero when `stale_uids > 0`, so a future asset re-layout fails the gate
   instead of only warning. Not done here: it would move the pinned gate count that W1/W4
   own this wave.

## 8. Files

| Path | Change |
|---|---|
| `vajb-orbit/game/game.tscn` | 3 `ext_resource` uids corrected; nothing else |
| `vajb-orbit/game/player_ship.tscn` | 2 `ext_resource` uids corrected (hull + script) + the editor writer's normal form; all values in §4 unchanged |
| `vajb-orbit/tests/probe_w2_scene_uids.gd` | new — read-only D4 evidence probe |
| `vajb-orbit/tests/probe_w2_scene_uids.tscn` | new — its scene wrapper |
| `.agents/gen/ui_chrome_w2_report.md` | this report |

No asset, theme, `project.godot`, `addons/` or `docs/` file was touched.
