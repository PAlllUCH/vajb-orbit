# Fix Wave 1 — W3 (flight scene) report

**Worker:** W3 (parallel with W1/W2/W4; W5 and W6 follow).
**Brief:** `.agents/gen/fix_wave1_task.md` §W3, rulings in `docs/design/IMPLEMENTATION_PLAN.md` §9.8 items 3/4/5.
**Scope touched:** `vajb-orbit/ui/hud/hud.gd`, `vajb-orbit/ui/hud/hud.tscn`,
`vajb-orbit/game/game.gd`, `vajb-orbit/game/game.tscn`. Nothing else.

---

## 1. Files changed — byte sizes

| file | before | after | delta | lines before → after |
|---|---|---|---|---|
| `vajb-orbit/ui/hud/hud.tscn` | 13 440 | 17 212 | +3 772 | 420 → 542 |
| `vajb-orbit/ui/hud/hud.gd` | 14 856 | 18 363 | +3 507 | 452 → 553 |
| `vajb-orbit/ui/hud/minimap.gd` | 4 610 | 4 610 | 0 | 144 → 144 (**untouched** — see §5.1) |
| `vajb-orbit/game/game.tscn` | 1 932 | 2 175 | +243 | 51 → 56 |
| `vajb-orbit/game/game.gd` | 10 961 | 13 494 | +2 533 | 340 → 403 |

**How the before column was obtained.** This workspace has no VCS and no backup (verified:
no `.git` at the workspace root or in `vajb-orbit/`; no `.orig`/snapshot copy exists; Godot keeps
no scene backups under `.godot/`). The `after` sizes are read from disk. The `before` sizes are
**derived**, not measured: every W3 edit was insert-only, so `before = after − inserted bytes`,
computed by a throwaway Python script (run at the workspace root, deleted afterwards) that deleted
only the inserted spans from the post-edit files, located by exact anchors. The reconstruction was
accepted only after four independent checks:

1. **Zero residue** — none of `_target_info`, `DISTANCE_FORMAT`, `_zoom_hovered`,
   `_bind_zoom_feedback`, `set_target_info`, `_camera_zoom`, `CAMERA_ZOOM*`, `TARGET_NAME`,
   `TARGET_SHIELD`, `TARGET_THREAT`, `TARGET_DISTANCE_STEP`, `TargetBody`, `TopRight`,
   `BottomCenter`, `DockHint`, `TargetPanel`, `ignore_texture_size`, `_96.png` appears in any
   reconstruction.
2. **Landmark line numbers** — 8–9 untouched landmarks per file land on exactly the numbers read
   before the first edit: `hud.tscn` `BottomLeft` 187 / `ZoomMinus` 315 / `ZoomPlus` 323 /
   `CenterOverlay` 331 / `TargetReticle` 340 / `CargoPanel` 367; `hud.gd`
   `HULL_DANGER_FRACTION` 44 / `CARGO_PANEL_GAP` 48 / `_top_left` 50 / `_apply_opacity` 211 /
   `SettingsManager.get_value` 212 / `_release_state` 178 / `_refresh_static_tints` 348 /
   `_apply_minimap` 409; `game.gd` `_update_movement` 125 / `_update_target` 179 /
   `_update_route_input` 195 / `_profile` 207 / `_world_to_screen` 288 / `_instantiate_hud` 292 /
   `_on_minimap_zoom_changed` 332.
3. **Totals** — the reconstruction line counts equal the pre-edit reads (hud.tscn 420, hud.gd 452,
   game.tscn 51, game.gd 340).
4. **Compile equivalence** — the two reconstructed `.gd` files were written to temporary
   `res://tools/_w3_check_hud.gd` / `_w3_check_game.gd` copies (class_name stripped from the first)
   and parsed: each fails with **exactly one** error, the same autoload-identifier error as the
   shipped file, with the line shift matching the whole-file delta —
   `SettingsManager` 212 → 250 and `Router` 309 → 372 (63 lines = 403 − 340). Both temp files and
   their `.uid` sidecars were deleted.

---

## 2. What changed

### 2.1 Minimap zoom controls usable (§W3.1)

`hud.tscn`: `ZoomMinus` / `ZoomPlus` now point at `res://assets/icons/tint/icon_zoom_minus_96.png`
and `icon_zoom_plus_96.png` (was `_16`), and each gained

```
custom_minimum_size = Vector2(28, 28)
ignore_texture_size = true
stretch_mode = 5      # KEEP_ASPECT_CENTERED
```

`hud.gd`: `_push_zoom_tint()` + `_bind_zoom_feedback()` give the buttons hover feedback on the
glyph's own `modulate` from existing tokens (`text_dim` → `text_primary`), tracked through a single
`_zoom_hovered` field (the pointer is unique), so a theme-change tint pass cannot clobber an active
hover. `_refresh_static_tints()` now routes the two buttons through `_push_zoom_tint()`.

Why these choices: `ignore_texture_size` keeps the hit rect at `custom_minimum_size` instead of the
texture's natural 16 px; `stretch_mode = 5` scales the square cut into that rect without distortion;
the `_96` cut is the catalogue's "default band for new consumers" and is the first band that carries
mipmaps (`apply_import_settings.py`, ICONS_SPEC §9.2/§9.8), so the 96 → 28 minification is clean —
`_48` carries no mipmaps and aliases at 28 px. Wiring is unchanged
(`minimap_zoom_changed` → `game.gd` `MINIMAP_RADIUS_STEP` 800, clamp 800–6400).

### 2.2 ESC dock hint (§W3.2)

`hud.tscn`: new `BottomCenter` `MarginContainer` (anchors `PRESET_BOTTOM_WIDE` = 12, `mouse_filter`
IGNORE, margins 12/12/12/20) holding `DockHint`, a `Label` with `theme_type_variation =
&"StationCaption"`, `text = "ESC · DOCK AT KEPLER-9"`, `horizontal_alignment = 1`. `hud.gd` adds the
zone to `_apply_zone_theme()`'s list (a `CanvasLayer` breaks Control theme inheritance, so a zone
that is not listed resolves against the engine default theme — the first probe run caught exactly
that: the hint reported the fallback 16 px until the zone was added).

### 2.3 Mock target gets a body (§W3.3)

`game.tscn`: new `6_target` ext_resource (`uid://dgodsmtfh0ons`,
`res://assets/ships/ship_interceptor_side.png`) and `TargetBody` (`Sprite2D`, `scale = 0.0663`),
`load_steps` 6 → 7. `game.gd`: `_update_target()` sets

```gdscript
_target_body.global_position = _target_position
_target_body.rotation = _target_angle + PI * 0.5
```

The tangent of `(R,0).rotated(angle)` is `(R,0).rotated(angle + π/2)`; the catalogue records both
side renders as "bow right", so the body flies nose-first. `0.0663` is the player's
texture-pixel-to-screen factor (`ship_vanguard_side.png` 905×387 at 0.0663 = 60.00×25.66 px), so the
two ships share one world scale: the interceptor's 940×107 texture renders 62.32×7.09 px. The HUD
stays above the world (`CanvasLayer` layer 10 vs the world's 0).

### 2.4 Inertia (§W3.4)

`game.gd`: `ACCELERATION` 520.0 → **420.0**, `DRAG` 260.0 → **120.0**. `MAX_SPEED` 420.0,
`TURN_RATE` 2.6, `BOOST_MULTIPLIER` 2.1 unchanged. `move_toward(_speed, 0.0, DRAG * delta)` at
top speed therefore takes 420/120 = **3.5 s** to stop, i.e. the intended coast.

### 2.5 Camera wheel zoom (§W3.5)

`game.gd` gains `CAMERA_ZOOM_STEP` 0.10 / `CAMERA_ZOOM_MIN` 0.70 / `CAMERA_ZOOM_MAX` 1.50 /
`CAMERA_ZOOM_SECONDS` 0.18, an `_unhandled_input()` that maps `MOUSE_BUTTON_WHEEL_UP/DOWN` onto a
clamped target, and `_set_camera_zoom()` which kills any live tween and runs
`tween_property(_camera, "zoom", Vector2(t, t), 0.18)` with `TRANS_SINE`/`EASE_OUT`. The tween is
killed in `_exit_tree()`. `project.godot` and the input map are untouched.

### 2.6 Target preview window (§W3.6)

`hud.tscn`: new `TopRight` zone (`anchors_preset = 1` = `PRESET_TOP_RIGHT`, `mouse_filter` IGNORE,
margins 12) → `TargetPanel` (`PanelContainer`, `visible = false`, `theme_type_variation =
&"PanelRaised"`, the project's framed panel) → `TargetCaption` (`SectionHeader`, "TARGET") /
`%TargetName` (`StationValue`) / HULL + SHIELD rows (`StationCaption` caption + 140×10
`HudHullBar` / `HudShieldBar` bar, `max_value = 1.0`) / `%TargetDistance` / `%TargetThreat`.

`hud.gd`: new public `set_target_info(info: Dictionary)` with keys `name`, `hull` (0–1),
`shield` (0–1), `distance_m`, `threat`; `clear_target()` also clears the info state and hides the
panel; `_apply_target_info()` renders it; the threat caption takes `accent_danger` from
`_set_text_alert(..., true, TOKEN_DANGER)`; `_format_int()` (the same grouped formatter the station
panels use) renders the distance as `1 240 m`.

`game.gd`: `set_target_info` added to `HUD_METHODS`; `_update_target()` feeds
`_target_info()` = `{name: "RAIDER INTERCEPTOR", hull: _target_hull, shield: 0.6,
distance_m: round(dist/10)*10, threat: "HOSTILE"}`. Both the constants and `_target_info()` carry
the comment that this is mock data that P2 replaces with real ship data.

---

## 3. Commands run and their output

### 3.1 The brief's parse check (`--check-only --script`)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://<file>.gd
```

| file | exit | output |
|---|---|---|
| `res://ui/hud/minimap.gd` (unchanged, no autoload refs) | **0** | clean |
| `res://ui/hud/hud.gd` | 1 | `Compile Error: Identifier not found: SettingsManager at hud.gd:250` |
| `res://game/game.gd` | 1 | `Compile Error: Identifier not found: Router at game.gd:372` |
| `res://ui/screens/main_menu.gd` (**untouched baseline**) | 1 | `Compile Error: Identifier not found: AudioManager at main_menu.gd:118` |

The command cannot resolve autoload singletons — autoloads are not registered as GDScript global
identifiers this early in startup — so it fails identically on a file this wave never touched
(`main_menu.gd`) and passes on the one W3 file with no autoload reference. Both reported lines are
pre-existing autoload uses (`hud.gd` `_apply_opacity`, `game.gd` `_instantiate_hud`'s
`Router.live_theme()`), not new code. **Substitute evidence** (below): compiling both scripts with
`load()` inside a normal headless run, and instantiating + running both scenes.

### 3.2 Probe — compile, 1920×1080 layout, live flight pass

Throwaway `res://tools/_probe_w3.gd` (`extends SceneTree`, deleted with its `.uid`):

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_w3.gd
```

```
compile res://ui/hud/hud.gd -> ok
compile res://ui/hud/minimap.gd -> ok
compile res://game/game.gd -> ok
--- geometry ---
root window size: (2560, 1440)
hud size: (1920.0, 1080.0)
PRESET_TOP_RIGHT=1 PRESET_BOTTOM_WIDE=12 canvas_layer=10
ZoomMinus: size=(28.0, 28.0) rect=[P: (1847.0, 1039.0), S: (28.0, 28.0)] texture=(96.0, 96.0) ignore_texture_size=true stretch_mode=5
ZoomPlus: size=(28.0, 28.0) rect=[P: (1879.0, 1039.0), S: (28.0, 28.0)] texture=(96.0, 96.0) ignore_texture_size=true stretch_mode=5
hint: text=ESC · DOCK AT KEPLER-9 variation=StationCaption size=13 colour=(0.4196, 0.4549, 0.5176, 1.0) rect=[P: (12.0, 1042.0), S: (1896.0, 18.0)] bottom_gap=20.0 align=1
zoom hover: rest=(0.4196, 0.4549, 0.5176, 1.0)
zoom hover: entered=(0.7882, 0.8196, 0.8627, 1.0)
zoom hover: exited=(0.4196, 0.4549, 0.5176, 1.0)
--- target window ---
has set_target_info: true
fed: visible=true rect=[P: (1694.0, 12.0), S: (214.0, 157.0)] name=RAIDER INTERCEPTOR(18) caption=16 hull_caption=13 hull=0.62/1.0 shield=0.60/1.0 distance=1 240 m threat=HOSTILE threat_colour=(0.7843, 0.2784, 0.1216, 1.0)
cleared: visible=false
target body: { "player_texture": (905.0, 387.0), "player_on_screen": (60.0015, 25.6581), "target_texture": (940.0, 107.0), "target_scale": (0.0663, 0.0663), "target_on_screen": (62.322, 7.0941) }
--- flight scene ---
zoom rest: target=1.00 camera=1.0000
orbit: angle=0.1050 body_rotation=1.6758 delta=1.5708 body_position=(258.5681, 27.24986) hud_layer=10 reticle_visible=true
live target panel: visible=true name=RAIDER INTERCEPTOR distance=260 m threat=HOSTILE hull=0.62
HUD_METHODS: [&"bind", &"set_sector_name", &"set_minimap_scale", &"set_minimap_blips", &"set_target", &"set_target_info", &"clear_target", &"set_cargo_open"]
after wheel up: target=1.10 camera=1.0000
mid tween: target=1.10 camera=1.0145
after 20 wheel ups: target=1.50
after 40 wheel downs: target=0.70 tween_valid=true
late: target=0.70 camera=1.0023
settled at frame 39: target=0.70 camera=0.7000
```

The logical UI space is 1920×1080 (the project's viewport size under the stretch mode; the OS
window is 2560×1440), so every rect above is at the brief's acceptance resolution.

### 3.3 Probe B — the zoom buttons' pressed path end to end

Throwaway `res://tools/_probe_w3b.gd` (same pattern, deleted with its `.uid`). It instantiates the
flight scene and emits each button's `pressed` signal, then reads the game's radius, the HUD's copy
and the minimap control's own world radius:

```
"…_console.exe" --headless --path "…/vajb-orbit" --script res://tools/_probe_w3b.gd

rest: game_radius=3200 hud_radius=3200 minimap_world_radius=3200
after 1x minus: game_radius=2400 hud_radius=2400 minimap_world_radius=2400
after 2x plus: game_radius=4000 hud_radius=4000 minimap_world_radius=4000
after 10x minus (clamp low): game_radius=800 hud_radius=800 minimap_world_radius=800
after 12x plus (clamp high): game_radius=6400 hud_radius=6400 minimap_world_radius=6400
```

### 3.4 Cleanup

```
tools/ after: ['build_theme.gd', 'build_theme.gd.uid', 'derive_icon_tints.gd', 'derive_icon_tints.gd.uid']
```

`_probe_w3.gd`, `_probe_w3b.gd`, `_w3_check_hud.gd`, `_w3_check_game.gd` and their `.uid`
sidecars are gone; the workspace-root scratch files (`tmp_w3_sizes.py`, `tmp_w3_reverted/`) are
gone. `tmp_comp.txt` was already there and was not touched.

---

## 4. Acceptance evidence per item

| §W3 item | Requirement | Measured |
|---|---|---|
| 1 | hit area ≥ 24×24 px | `ZoomMinus` / `ZoomPlus` = **28×28**, rects (1847,1039) and (1879,1039) inside the 1920×1080 viewport |
| 1 | glyph clearly visible | source is the 96×96 cut, `ignore_texture_size = true`, `stretch_mode = 5` → the cut is drawn 28×28 (was a 16 px texture in a 16 px rect) |
| 1 | hover feedback from existing tokens | rest `(0.4196, 0.4549, 0.5176)` = `text_dim` `#6b7484` → hover `(0.7882, 0.8196, 0.8627)` = `text_primary` `#c9d1dc` → back to `text_dim` |
| 1 | clicking changes the map scale | probe B (§3.3), a `pressed` emission per button: game/HUD/minimap radii 3200 → **2400** (minus) → **4000** (two plus) → clamped **800** (ten minus) → clamped **6400** (twelve plus); the minimap control's own `world_radius()` follows every step, so the drawn scale changes |
| 2 | text / styling / margin | `text=ESC · DOCK AT KEPLER-9`, `variation=StationCaption`, **font 13**, colour `text_dim`, `align=1` (centre), rect `(12,1042)–(1908,1060)`, **bottom gap 20 px** (≥16) |
| 3 | body at the orbit position, facing travel | live: `body_rotation − _target_angle = 1.5708` (= π/2 exactly), `body_position = (258.5681, 27.24986)` → radius 260.0 = `TARGET_ORBIT_RADIUS` |
| 3 | player-matching scale | player 905×387 × 0.0663 = 60.00×25.66 px; target 940×107 × 0.0663 = **62.32×7.09 px** (same factor) |
| 3 | reticle stays on top | HUD `CanvasLayer` layer **10** vs the world's 0; `reticle_visible=true` while the target is in range |
| 4 | 420 / 120, other constants kept | constants read from `game.gd`: `MAX_SPEED 420.0`, `ACCELERATION 420.0`, `DRAG 120.0`, `TURN_RATE 2.6`, `BOOST_MULTIPLIER 2.1`; coast time 420/120 = **3.5 s** |
| 5 | wheel zooms in, clamped 0.70–1.50, smoothed, input map untouched | one wheel-up → target 1.10 with `camera.zoom` 1.0000 → **1.0145** (interpolating, not snapping); 20 wheel-ups → **1.50**; 40 wheel-downs → **0.70**; the tween then **settles at exactly 0.7000**; `project.godot` not touched |
| 6 | panel, API, wiring, hidden state | `has set_target_info: true`; default `visible=false`; fed → `visible=true`, rect (1694,12)–(1908,169) (12 px from the top-right edge), name `RAIDER INTERCEPTOR` at 18 px (`StationValue`), caption 16 px (`SectionHeader`), bar captions 13 px (`StationCaption`), `hull=0.62`, `shield=0.60`, `distance=1 240 m`, `threat=HOSTILE` in `accent_danger` `#c8471f`; `clear_target` → `visible=false`; live flight feed → `visible=true name=RAIDER INTERCEPTOR distance=260 m threat=HOSTILE hull=0.62`; `set_target_info` present in `HUD_METHODS` |

No new hex literal, no per-node font-size override: the three sizes above are resolved from the
theme's `StationValue` / `SectionHeader` / `StationCaption` items, and the only colour overrides are
`_token()` reads (`accent_danger`).

---

## 5. Deviations and open points

1. **`minimap.gd` is untouched.** It is in the W3 file list, but the finding was the buttons' size,
   glyph and feedback plus the (already correct) wiring; nothing in the minimap control needed a
   change. Its `set_world_radius`/`set_blips` path is exercised end to end by probe B (§3.3).
2. **`_96` tint cuts, not `_48`.** The catalogue calls `_96` the default band for new consumers and
   it is the first band with mipmaps (ICONS_SPEC §9.2/§9.8), so the 96 → 28 px minification is
   clean; `_48` has no mipmaps and would alias at 28 px. This is a band choice inside the icon spec,
   not a new asset.
3. **28 px, not the bare 24 px minimum.** 28 keeps the glyph legible and matches the HUD's icon
   band; the requirement is "at least 24×24".
4. **Hover is a modulate change, not `texture_hover`.** The zoom buttons carry no plate art, so
   there is nothing to swap; the existing `text_dim`/`text_primary` tokens are used, and a theme
   change re-applies the current hover state instead of clobbering it.
5. **The distance label reads a constant `260 m` in flight**, because the mock target orbits at the
   fixed `TARGET_ORBIT_RADIUS` (260 u). The brief's formula
   (`round(_target_position.distance_to(_player.position) / 10) * 10`) is implemented as written;
   the grouped `1 240 m` form is proven by the fed probe value.
6. **`clear_target` is unreachable in the mock flight scene**: the orbit stays at 260 u inside
   `TARGET_RANGE` 1400, so the range branch never fires (pre-existing mock behaviour, not widened
   here). The panel's hidden/cleared path is proven at HUD level (`cleared: visible=false`).
7. **The brief's parse check is not usable as written for these two files** (§3.1): the mode cannot
   resolve autoload singletons, and the untouched `main_menu.gd` fails it the same way. Compilation
   was instead proven by `load()` inside a headless run (`compile … -> ok` for all three scripts)
   and by instantiating and running both scenes.
8. **No reimport was run.** W3 adds no imported asset — the interceptor texture was already imported
   and the probe loaded it (940×107 from the shipped `.ctex`) — and the Godot editor is open
   (process present, LSP answering on 127.0.0.1:6005), so a second `--editor --quit` instance would
   have written the same import cache (AGENTS.md). Scene/script text needs no reimport.
9. **The mock target's on-screen height is 7.1 px** (940×107 texture × 0.0663). That is a direct
   consequence of matching the player's world scale with a genuinely slimmer hull, and of the
   brief's own numbers; if the owner wants a chunkier mock target that is an art/scale ruling, not
   a code defect.
10. **`set_target_info` is a new public HUD method**: §3.10's API list is amended by §9.8 item 4,
    and `HUD_METHODS` mirrors it, so the guard passes; the §3.10 code block itself is the
    orchestrator's to update (W3 did not touch `docs/`).
