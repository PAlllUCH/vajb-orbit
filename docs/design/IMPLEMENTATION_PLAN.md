# Vajb Orbit — Phase C Implementation Plan (frozen interface contract)

**Status:** written 2026-09-17 before any worker dispatch. This file is the contract every Phase C worker codes against. Change it only by amendment, and only before the affected worker is dispatched.

**Sources of truth, in order:** `docs/design/UI_SPEC.md` → `MAIN_MENU_SPEC.md` → `ICONS_SPEC.md` → `UI_CHROME_ASSETS_SPEC.md` → `STYLE_BIBLE.md` → this file. Where this file states a measured number (asset size, region rect, position), the measured number wins over any estimate in the specs.

## 0. Phase C scope (user-approved 2026-09-17)

| Decision | Value |
|---|---|
| Mode / tier / model | Code · paid · `opencode-go/deepseek-v4.1-flash` (verified in the live catalog the same day) |
| In scope | core loop (boot, loading, main menu, quit dialog) · settings screen · placeholder game scene · full HUD |
| Font | Godot fallback font, with one Blaec-ready slot in the theme (`Theme.default_font`, §3.2) |
| Audio | AudioServer bus layout built at startup, hook API wired, **all cues silent no-ops** until files exist (§3.8) |
| Tests | No test suite this phase. Verification = headless parse/boot checks + live editor run (§6) |
| Workers | W0 foundation (serial) → W1–W5 parallel → W6 reviewer (mandatory) → fix loop |

## 1. Worker ownership

| Wave | Owns these files (creates them; do not touch others') |
|---|---|
| W0 | `ui/paths.gd`, `ui/screen.gd`, `tools/build_theme.gd`, `tools/derive_icon_tints.gd`, `ui/theme/vajb_theme.tres` (generated), `assets/icons/tint/*` (generated), `autoload/settings_manager.gd`, `autoload/audio_manager.gd`, `autoload/router.gd`, `autoload/dialog_manager.gd`, `ui/components/menu_button.tscn` + `.gd`, `ui/components/glow_underlay.gd`, `docs/design/PROJECT_SETTINGS_PATCH.md` |
| W1 | `ui/screens/boot.tscn` + `.gd`, `ui/screens/loading.tscn` + `.gd` |
| W2 | `ui/screens/main_menu.tscn` + `.gd`, `ui/dialogs/dialog.tscn` + `.gd`, `ui/dialogs/quit_confirm.tscn` |
| W3 | `ui/screens/settings.tscn` + `.gd`, `ui/screens/settings_rebind_row.tscn` + `.gd` |
| W4 | `game/game.tscn` + `.gd`, `game/player_state.gd` |
| W5 | `ui/hud/hud.tscn` + `.gd`, `ui/hud/minimap.gd`, `ui/hud/target_reticle.gd`, `ui/components/slot_button.tscn` + `.gd` |

`project.godot` is **not** written by any worker. W0 emits `docs/design/PROJECT_SETTINGS_PATCH.md`; the orchestrator applies it through the live `godot-ai` editor (§5), which is the only safe way to edit settings while the editor holds the project open.

Nothing in `addons/godot_ai/` is ever edited (AGENTS.md).

## 2. Measured asset facts — use these numbers, do not guess

Verified 2026-09-17 with Pillow against the shipped files.

| File | Facts to wire with |
|---|---|
| `ui/ui_button_plate_{normal,hover,pressed,disabled}.png` | 280×56, RGBA, alpha-cut, real rivet highlights (no keying fringe). 1:1 with the menu button size |
| `ui/ui_slot_weapon_{...}.png` | 48×48 — HUD weapon slots (UI_SPEC §3.2) |
| `ui/ui_slot_cargo_{...}.png` | 40×40 — HUD cargo cells (UI_SPEC §3.4) |
| `ui/ui_slot_inventory_{...}.png` | 56×56 — no consumer in Phase C (hangar is future scope) |
| `ui/ui_bar_caps.png` | 42×14 strip: **left cap = columns 0–19, columns 20–21 empty, right cap = columns 22–41** → two `AtlasTexture` regions `Rect2(0,0,20,14)` / `Rect2(22,0,20,14)` |
| `ui/ui_minimap_bezel.png` | 200×200, fully opaque, 16 px frame → `NinePatchRect` with `patch_margin_* = 16`; interior 168×168 hosts the minimap `Control` |
| `ui/ui_panel_frame.png` | 96×96, 32 px frame → nine-patch margins 32. **No consumer in Phase C** (hangar/equipment chrome per UI_SPEC §5.3) |
| `ui/logo_vajb_orbit.png` | 2048×2048 RGBA, ink bbox `Rect2i(56, 719, 1937, 591)`. Crop with `AtlasTexture` region `Rect2(44, 707, 1961, 615)` (12 px pad for the drop shadow), `filter_clip = true` |
| `env/env_menu_bg.png` | 2048×1152 RGB. Burning wreck: ember bbox x 0.601–0.847, y 0.573–0.921 of the frame; brightest ember pixel at **(0.791, 0.618)** → ember-pulse sprite position (MAIN_MENU_SPEC §5.2) |
| `env/env_loading_bg.png` | 2048×1152 RGB, effectively zero warm pixels (0 accent) → draw at 40 % opacity over `void_base` (MAIN_MENU_SPEC §2) |
| `env/env_stars_layer{1,2,3}.png` | 2048×2048 RGB, seamless tiles → `ParallaxLayer` each with `motion_mirroring = Vector2(2048, 2048)` and a `TextureRect` with `texture_repeat = TEXTURE_REPEAT_ENABLED` |
| `fx/fx_ember_pulse.png` | 2048×2048 **RGB, no alpha channel**. It is a glow on black → use additive blending (`CanvasItemMaterial` `blend_mode = BLEND_MODE_ADD`) and drive `modulate.a` 0.25↔0.45 (MAIN_MENU_SPEC §5.2), never `modulate` over an opaque black square |
| `fx/*.png` (all 9) | All 2048×2048 RGB. Same no-alpha rule applies to every FX texture in future phases |
| `icons/icon_*_{16,48}.png` | RGBA whose **alpha channel is the glyph** and whose RGB is dark iron-black (mean ≈ `#26292D`) → cannot be tinted by `modulate` (§3.3) |
| `icons/panel_{weapons,cargo,glyphs}.png` | 2048×2048 RGB masters, not consumed by the engine |
| `ships/ship_vanguard_side.png` | Ship facing right in top-down view → the placeholder player sprite (§4.4). `_front` = nose up (yaw −90°), `_back` = nose down (+90°), `_three_quarter` = nose upper-right (−45°) |

Icon consumers in Phase C: `icon_weapon_{laser,cannon,rocket,mine,plasma}` (the 5 HUD weapon slots, one per slot), `icon_ammo`, `icon_hull`, `icon_shield`, `icon_cargo_{ore,crate,container,fuel_cell,salvage,data_core}`, `icon_gear`, `icon_close`, `icon_zoom_plus`, `icon_zoom_minus`. Unconsumed until later phases (hangar, company select, logout): `icon_credits`, `icon_logout` — recorded, not a defect.

## 3. Frozen contracts

### 3.1 `ui/paths.gd` — the single place any `res://` path is written

```gdscript
class_name UIPaths
extends RefCounted

const THEME := "res://ui/theme/vajb_theme.tres"
const ROUTES := {
    &"boot": "res://ui/screens/boot.tscn",
    &"main_menu": "res://ui/screens/main_menu.tscn",
    &"loading": "res://ui/screens/loading.tscn",
    &"game": "res://game/game.tscn",
    &"settings": "res://ui/screens/settings.tscn",
    &"dialog": "res://ui/dialogs/dialog.tscn",
    &"quit_confirm": "res://ui/dialogs/quit_confirm.tscn",
    &"hud": "res://ui/hud/hud.tscn",   # amendment 2026-09-17 (NOTE 12): game.gd instantiates it directly; listed here so no path lives outside this module
}
const SETTINGS_FILE := "user://settings.cfg"
const INPUTS_FILE := "user://inputs.cfg"
```

Documented deviation from the godot-master "never use `res://` in logic scripts" rule: scene routes must live somewhere, and one constants module is a single reviewable source instead of scattered string literals. Every other script resolves paths from here or uses `preload()`.

### 3.2 `ui/theme/vajb_theme.tres` — generated, never hand-edited

Built by `tools/build_theme.gd` (`extends SceneTree`, run headless, `ResourceSaver.save`). Re-runnable and deterministic. **All hex literals live here and nowhere else.** UI_SPEC §1 token → theme colour on the custom theme type `Tokens`:

`void_base #07090d`, `void_panel #0b0f15`, `void_panel_raised #10151d`, `metal_dark #1b2028`, `metal_mid #2a313c`, `metal_light #3d4654`, `text_primary #c9d1dc`, `text_dim #6b7484`, `accent_danger #c8471f`, `accent_danger_bright #e8622a`, plus `menu_glow` = `#e8703a` at alpha 0.60 (MAIN_MENU_SPEC §4 halo) and `void_fade` = `#07090d` at alpha 1.0.

Scripts read colours only via `theme.get_color(&"text_dim", &"Tokens")`. No hex outside the generator.

Theme type variations the phases consume (name → base type → items):

| Variation | Base | Items |
|---|---|---|
| `Tokens` | (none) | all colours above |
| `ScreenTitle` | Label | font_size 22, font_color `text_primary` |
| `SectionHeader` | Label | font_size 16, font_color `text_dim` |
| `HudReadout` | Label | font_size 18, font_color `text_primary` |
| `MenuButtonPlate` | Button | styles normal/hover/pressed/disabled = `StyleBoxTexture` from the four plates; `focus` = **`StyleBoxEmpty`** since 2026-09-18 (§9.8 item 1 — the red focus rectangle is retired); font_size 34; font_color / font_hover_color `text_primary`, font_disabled_color `text_dim` |
| `HudHullBar` | ProgressBar | background = `progress_bg`, fill = `accent_danger` |
| `HudShieldBar` | ProgressBar | background = `progress_bg`, fill = `metal_light` |
| `SlotButtonWeapon` | TextureButton | normal/hover/pressed/disabled = `ui_slot_weapon_*` |
| `SlotButtonCargo` | TextureButton | normal/hover/pressed/disabled = `ui_slot_cargo_*` |
| `DialogTitle` | Label | font_size 18, font_color `text_primary` (amendment 6) |
| `Version` | Label | font_size 13, font_color `text_dim` (amendment 6) |
| `SlotNumber` | Label | font_size 10, font_color `text_dim` (amendment 6) |

Base-type items to set (UI_SPEC §2.1): `panel`, `panel_raised`, `progress_bg` (bg `void_base` + 1 px `metal_mid`), `progress_fill` (bg `accent_danger`), `focus`, `lineedit`, `lineedit_focus`, `slider_groove`, `slider_grabber`, `tooltip_panel`; font size 14 default on Label/Button/LineEdit/OptionButton/PopupMenu, 13 on RichTextLabel and tooltips; TabContainer panel + tab states so the settings tabs read; OptionButton/PopupMenu panel + hover. All corners radius 0, border width 1 px.

**Base `ProgressBar` gets `background` = `progress_bg` and `fill` = `progress_fill`** — the loading screen uses a plain `ProgressBar` (MAIN_MENU_SPEC §2). The `HudHullBar` / `HudShieldBar` variations override only `fill`; the `HudHullBar` fill is additionally switched to `accent_danger_bright` from script when hull < 25 % (UI_SPEC §3.1), which is a runtime `theme_override_styles/fill`, the one sanctioned per-control override.

**Amendments 2026-09-17, from W0 verification (all three W0 workers confirmed these independently):**

1. **`MenuButton` cannot be a theme variation** — it is a built-in Godot class, so `Theme.set_type_variation` refuses it and items stored under that name are not resolved by a plain `Button`. The variation consumers use is **`MenuButtonPlate`**; the generator also keeps an identical item set under `MenuButton` so a native `MenuButton` node still themes. `menu_button.tscn` was corrected to `MenuButtonPlate`.
2. **The two-tone bevel is approximated.** A `StyleBoxFlat` has a single `border_color`, so UI_SPEC §2.1's "`metal_light` top/left, `metal_dark` bottom/right" is realised as `border_color = metal_light` plus a 1 px `metal_dark` shadow offset to (1, 1). Corners stay radius 0 and there are no gradients.
3. **Base items are registered on the empty theme type (`""`) and wired to the concrete engine slots** (`PanelContainer/panel`, `ProgressBar/background|fill`, `Button/normal|hover|pressed|disabled|focus`, `LineEdit`, `Slider`, `PopupMenu`, `TooltipPanel`, `TabContainer`), because that is the lookup Godot's cascade actually performs.
4. **The four `button_*` styleboxes are base `Button` items**, not only part of the menu variation — `settings.tscn` and the dialogs need a themed plain `Button`.
5. **`--script` runs do not resolve `class_name` globals** until the editor's global class table is rebuilt; tool scripts must `preload("res://ui/paths.gd")` rather than reference `UIPaths` directly. The orchestrator runs `filesystem_manage(op="scan")` after this wave.

**Amendments 2026-09-17 (second set, from the W6 review + W7 fix round — findings 3, 9, 10, NOTE 13):**

6. **Three text variations exist so no widget carries a per-node font-size override**: `DialogTitle` 18, `Version` 13 (`text_dim`), `SlotNumber` 10 (`text_dim`). Consumers: `dialog.tscn`, `main_menu.gd`, `slot_button.tscn`.
7. **`ui_scale` is applied by `Router.live_theme()`**, not by the generator: the router keeps the baked theme as its `_theme_source` and re-writes `default_font_size` plus **all 21 per-type font-size items** as `roundi(base * scale)` on a duplicate. Any new font-size item added to this table must be added to `router.gd`'s list in the same change, or it silently stops scaling (this is exactly what made the setting inert before). `RichTextLabel`'s five items (`normal/bold/italics/bold_italics/mono`) are all pinned at 13 so they can never drift apart.

**`Theme.default_font` stays unset** (Godot fallback). The Blaec swap later is a one-line change plus a `FontFile` in `ui/theme/`.

### 3.3 Icon tint derivation

`tools/derive_icon_tints.gd` (`extends SceneTree`) reads every `res://assets/icons/icon_*_{16,48,96,192}.png`, sets `RGB = (1,1,1)` keeping alpha byte-identical, and writes `res://assets/icons/tint/<same filename>`. It asserts the alpha channel is unchanged and prints a per-file report. Consumers use the `tint/` files and tint with theme colours: inactive `text_dim`, active `text_primary`, danger `accent_danger` (ICONS_SPEC §1).

**Amendment 2026-09-18 (F.1):** the glob covers the full quartet `_{16,48,96,192}` — `_96` is the default band for new consumers and `_192` for detail surfaces (`17_coder_handoff.md` §2.1), so both need stencils. Cut geometry is aspect-preserving contain-fit and is not the tool's concern (ICONS_SPEC §9.6).

**Amendment 2026-09-18 (F.2):** re-run after the F.2 pass, which changed the bytes of 16 cuts (the four outline glyphs' quartet, re-cut from heavier masters — ICONS_SPEC §1 and §9.8 C2b). The stencil set is unchanged at 556 files, and the tool remains the way to regenerate any of them. Chrome `@2x` cuts carry no stencils: the coder points the theme at the `@2x` file and renders it at half scale (`UI_CHROME_ASSETS_SPEC.md` §10).

### 3.4 `ui/screen.gd` — the intent contract for every routed screen

```gdscript
class_name Screen
extends Control

signal route_requested(route: StringName, params: Dictionary)
signal overlay_requested(route: StringName, params: Dictionary)
signal overlay_close_requested

func on_route(params: Dictionary) -> void:   # virtual; router calls it after the scene is added
    pass
```

Screens emit intent and never route themselves. The router connects these three signals on every screen and overlay it instantiates (signals up). `settings.tscn`, `dialog.tscn` and `quit_confirm.tscn` extend `Screen` too.

### 3.5 Autoloads (project.godot order is significant)

| Order | Name | Script | Depends on |
|---|---|---|---|
| — | `_mcp_game_helper` | (existing, godot-ai) | must not be removed |
| 1 | `SettingsManager` | `res://autoload/settings_manager.gd` | — |
| 2 | `AudioManager` | `res://autoload/audio_manager.gd` | SettingsManager |
| 3 | `Router` | `res://autoload/router.gd` | SettingsManager, AudioManager |
| 4 | `DialogManager` | `res://autoload/dialog_manager.gd` | Router |

API signatures (frozen):

```gdscript
# SettingsManager
signal setting_changed(section: StringName, key: StringName, value: Variant)
func get_value(section: StringName, key: StringName, default: Variant = null) -> Variant
func set_value(section: StringName, key: StringName, value: Variant) -> void   # applies live + saves (debounced)
func register_row(...) -> void                                               # not required in Phase C
func rebindable_actions() -> Array[StringName]
func binding_text(action: StringName, index: int) -> String
func set_binding(action: StringName, index: int, event: InputEvent) -> void
func reset_all_inputs() -> void
func save_inputs() -> void
func ui_scale() -> float

# AudioManager
enum UiCue { CLICK, HOVER }
func play_ui(cue: UiCue) -> void            # silent no-op when the stream is absent
func play_sfx(cue: StringName) -> void       # silent no-op when the stream is absent
func set_bus_linear(bus: StringName, value: float) -> void
func bus_linear(bus: StringName) -> float
const CUE_DIRS := { &"ui": "res://assets/audio/ui/", &"sfx": "res://assets/audio/sfx/", &"music": "res://assets/audio/music/" }

# Router
signal screen_changed(route: StringName)
signal overlay_pushed(route: StringName)
signal overlay_popped(route: StringName)
func route(route: StringName, params: Dictionary = {}) -> void
func push_overlay(route: StringName, params: Dictionary = {}) -> void
func pop_overlay() -> void
func current_route() -> StringName
func overlay_depth() -> int
func is_busy() -> bool
func live_theme() -> Theme
func request_quit() -> void

# DialogManager
signal dialog_confirmed(id: StringName)
signal dialog_cancelled(id: StringName)
func confirm(id: StringName, title: String, body: String, confirm_text := "CONFIRM", cancel_text := "CANCEL") -> void
func message(id: StringName, title: String, body: String, confirm_text := "OK") -> void
func resolved(id: StringName, confirmed: bool) -> void   # called by dialog.gd; added in W0
func is_open() -> bool
```

Behaviour rules:

- `Router` owns two `CanvasLayer`s created in `_ready()`: `OverlayLayer` (layer 20, UI_SPEC §2.3) and `FadeLayer` (layer 100) holding a full-rect `ColorRect` in `Tokens/void_fade`. Full-screen routes use `get_tree().change_scene_to_packed()`; overlays are instantiated into `OverlayLayer` so they survive a screen change. Screens never call `change_scene`.
- Transition: 0.2 s fade to opaque, swap, 0.2 s fade back (MAIN_MENU_SPEC §7 = 0.4 s total). `is_busy()` guards re-entry.
- After the new scene is added, if its root has `on_route`, call it with the params (calls down).
- Before adding, if the root is a `Control`, assign `Router.live_theme()` to it — `live_theme()` is `UIPaths.THEME` loaded once and duplicated, with `default_font_size` scaled by `SettingsManager.ui_scale()`. Scenes still bake `vajb_theme.tres` on their root so F6 (run current scene) looks right.
- One overlay instance per route: re-pushing an open route is ignored. `pop_overlay()` restores focus to the stored opener (a `WeakRef`, validated with `is_instance_valid`) before freeing.
- `DialogManager` queues requests and drives `Router.push_overlay(&"dialog", ...)`; it is the only owner of dialog lifecycle.

### 3.6 `SettingsManager` keys

`user://settings.cfg` via `ConfigFile`. Input bindings in `user://inputs.cfg`.

| Section | Keys | Applied how |
|---|---|---|
| `graphics` | `resolution` (Vector2i), `display_mode` (0 windowed / 1 fullscreen / 2 borderless), `vsync` (bool), `render_scale` (0.5–2.0), `effects_quality` (0–2) | resolution + mode + vsync via `DisplayServer`/`Window`; render_scale via `get_window().content_scale_factor`; `effects_quality` is **stored only** in v1 (documented no-op) |
| `audio` | `master`, `music`, `sfx`, `ui` (0.0–1.0 linear) | `AudioManager.set_bus_linear`; defaults are the AUDIO_SPEC §4.3 levels **mapped to the right buses** — master 0 dB, music −8 dB, sfx −6 dB, ui −10 dB. (W0 amendment: this section originally wrote `db_to_linear(-8/-6/-6/-10)` positionally, which would have mis-assigned master and double-attenuated music through the Master send.) |
| `interface` | `ui_scale` (0.85–1.5, default 1.0), `hud_opacity` (0.4–1.0, default 1.0) | `ui_scale` → `Router.live_theme().default_font_size`; `hud_opacity` → read by the HUD on `bind()` |

Bindings are written back with `InputMap.action_erase_events()` + `action_add_event()` and persisted to `user://inputs.cfg` (project.godot is read-only at runtime in an export).

### 3.7 Input map (Phase C convention — flag in the final report)

`ui_*` actions are the engine defaults and are not rebindable. User actions created by W0's patch and shown in the settings rebinding list, in this order:

`thrust_forward` (W) · `thrust_backward` (S) · `turn_left` (A) · `turn_right` (D) · `fire_primary` (Space) · `fire_secondary` (Left Ctrl) · `mine` (E) · `boost` (Shift) · `cargo_toggle` (C) · `weapon_1`..`weapon_5` (1–5) · `target_next` (Tab is reserved by ui_focus_next — use `Q`) · `interact` (F — dock/gate/interact prompts) · `warp` (H — safe warp).

No spec fixes a control scheme; this set exists so the rebinding UI is meaningful and the placeholder game is playable. Amend the list here if the eventual combat spec disagrees.

**Amendment 2026-09-18 (engine wave, ENGINE_SPEC §11).** The combat spec lands: `interact` = F and `warp` = H are appended (17 actions total), per `PROJECT_SETTINGS_PATCH.md` §2, applied by the orchestrator through godot-ai. `ui_cancel` (ESC) keeps its binding and changes meaning in-game only — *cancel order + lock*; ESC docking retires (§9.9). Until the two actions exist in `project.godot`, code reads them behind `InputMap.has_action(&"interact")` / `&"warp"` guards.

### 3.8 Audio cue convention (Phase C convention — flag in the final report)

`AudioManager` builds the AUDIO_SPEC §4.3 bus tree in `_ready()`: `Music`, `SFX` (+ `SFXWeapon`, `SFXImpact`, `SFXWorld`), `UI`. A cue resolves to `CUE_DIRS[bus] + cue + ".ogg"`; if the file is not imported the call returns silently — this is the whole "no-op hooks" decision. The menu controller calls `AudioManager.play_ui(AudioManager.UiCue.HOVER / .CLICK)` on button hover/press (MAIN_MENU_SPEC §4), never the buttons themselves.

### 3.9 `PlayerState` — the only gameplay↔HUD channel

`game/player_state.gd`, `class_name PlayerState extends Resource`. Created at runtime in `game.gd` (never `@export`, to avoid the shared-Resource bug in godot-master Part 8 #1).

```gdscript
signal hull_changed(current: float, maximum: float)
signal shield_changed(current: float, maximum: float)
signal weapon_changed(slot: int, weapon_id: StringName, ammo: int, ammo_max: int)
signal cargo_changed(used: int, maximum: int)
signal died

var hull_max: float = 1000.0
var shield_max: float = 600.0
var cargo_max: int = 40
var hull: float
var shield: float
var ammo: Array[int]
var ammo_max: Array[int]
var cargo_used: int
const WEAPONS: Array[StringName] = [&"laser", &"cannon", &"rocket", &"mine", &"plasma"]

func setup() -> void
func set_hull(value: float) -> void
func damage(amount: float, bypass_shield := false) -> void
func set_shield(value: float) -> void
func set_ammo(slot: int, value: int) -> void
func set_cargo_used(used: int) -> void
```

The HUD never mutates the state and never holds a `Node` reference to gameplay: it connects to these signals (Layer Cake, godot-master Part 1 "Data → Reactivity").

**Amendment 2026-09-18 (engine wave, ENGINE_SPEC §4.2/§12 item 5).** `damage` gains `bypass_shield := false`: a non-bypassing hit is absorbed by a live shield (`shield > 0`) up to its current value with **no carry-over** to hull; otherwise hull takes it. Kinetic weapons, rockets and mines bypass. The five HUD signals above are unchanged.

### 3.10 `Hud` public API — called down by `game.gd`

```gdscript
class_name Hud
extends Control

signal weapon_slot_selected(slot: int)
signal cargo_toggled(open: bool)
signal minimap_zoom_changed(delta: int)

func bind(state: PlayerState) -> void
func set_sector_name(sector: String) -> void
func set_minimap_scale(world_radius: float) -> void
func set_minimap_blips(blips: Array[Dictionary]) -> void   # {"pos": Vector2 (world), "kind": &"self"|&"hostile"|&"neutral"|&"friendly"}
func set_target(screen_position: Vector2, hull_fraction: float) -> void
func clear_target() -> void
func set_cargo_open(open: bool) -> void   # amendment 2026-09-17 (finding 6): public setter so game.gd can honour the cargo_toggle action; the HUD button calls the same path
func set_prompt(text: String) -> void   # amendment 2026-09-18 (engine wave): dock/gate/interact prompt strip; empty hides
func set_warp_channel(progress: float) -> void   # amendment 2026-09-18 (engine wave): warp bar; ≤ 0 hides
```

**Amendment 2026-09-18 (engine wave, ENGINE_SPEC §10/§12 item 4).** Two API additions and three payload/draw changes, all listed in §9.9:

- `set_prompt(text)` and `set_warp_channel(progress)` are the dock/gate prompt strip and the warp channel bar (per the signatures above).
- Blip kinds gain `&"friendly"` (stations, gates, beacons); POI subkinds ride as data on the blip dict. Blip classes per ENGINE_SPEC §8: friendly / neutral (derelicts, convoys, scanned anomalies) / hostile (pirates, hunters).
- The target window's `set_target_info` payload (shipped per §9.8 item 4) gains a **range state**: in/out of range for the selected weapon.
- The reticle is drawn at the cursor with plain / in-range / out-of-range / hostile states (slice-1 scope: plain + mining states) plus small hit markers; no floating damage numbers in v1.

`game.gd` does the world→screen projection (it owns the camera) and passes screen coordinates; the HUD stays dumb and testable. Blips carry world positions and the HUD maps them through `set_minimap_scale` — the map is **player-centred**: the `self` blip always sits at the disc's centre and every other blip is drawn at `(pos - self_pos) * unit`. (Amendment 2026-09-17, finding 2: the earlier wording allowed an absolute-origin reading that emptied the map once the ship left the origin.)

### 3.11 `MenuButton` component

`ui/components/menu_button.tscn` — `MenuButton` (Control, `custom_minimum_size 280×56`) → `Glow` (Control, anchors full rect with offsets −6 on all sides, `mouse_filter = IGNORE`, `glow_underlay.gd`) → `Button` (full rect, `theme_type_variation = &"MenuButtonPlate"`).

- `glow_underlay.gd` draws a `StyleBoxFlat` from `Tokens/menu_glow` with `expand_margin_* = 6` in `_draw()`, visible only on hover (the sanctioned menu privilege).
- `menu_button.gd` owns two looping `Tween`s, one for the 1 px border colour breathing `metal_mid`↔`metal_light` over 4 s (desynchronised per instance by ±0.6 s) and the press scale 0.98 for 80 ms; plus a focus ring drawn in `_draw()` when the inner Button has focus. **No `_process`, no per-button `get_node()` on other nodes.**
- Emits `pressed`, `hovered`, `unhovered` — the screen connects them to `AudioManager`.

### 3.12 Theme assignment and F6

Every screen/overlay root bakes `theme = ExtResource(vajb_theme.tres)` in its `.tscn` so F6 works standalone; the router then replaces it with `live_theme()` at runtime. Both behaviours are required.

## 4. Per-screen frozen structure

### 4.1 `boot.tscn` (W1)
`Screen` full-rect → `void_base` `ColorRect` → logo `TextureRect` (`AtlasTexture` crop per §2) → 2 px progress line (240 wide, `metal_light`, 3 ticks 25/60/100 %) → black `ColorRect` crossfade. Timeline exactly MAIN_MENU_SPEC §1 (≤3 s), any key ignored, skip guard at t=1.4 s if the engine reports loading finished. On completion emits `route_requested(&"main_menu", {})`.

### 4.2 `loading.tscn` (W1)
`Screen` → `void_base` → `env_loading_bg` at 40 % opacity → centred `Label` "ENTERING SPACE" (Label 22, `text_primary`) → progress bar 260×14 (`progress_bg`/`progress_fill`) tweening 0→100 % over ≥1.2 s → 0.4 s fade out, then `route_requested(params["destination"], params)`. Reads `params["destination"]` (default `&"game"`).

### 4.3 `main_menu.tscn` (W2)
Structure per MAIN_MENU_SPEC §3: BackgroundLayer (`env_menu_bg`) → GrainLayer → logo (top-left 8 % / 12 % from top) → `MenuButtons` VBox (x 8 %, y 58 %, separation 14) with three `MenuButton`s PLAY / OPTIONS / EXIT → `VersionLabel` bottom-right 13 px `text_dim`. Controller owns: dust drift (UV/`region_rect` scroll, 96 px over 20 s per §9.8 item 3), ember pulse sprite at normalised (0.791, 0.618) with additive blending, breathing tweens, hover glow, focus order PLAY→OPTIONS→EXIT, default focus PLAY, Esc → quit dialog, `AudioManager` hover/click hooks. Intents: PLAY → `route_requested(&"loading", {destination: &"game"})`; OPTIONS → `overlay_requested(&"settings", {})`; EXIT → `overlay_requested(&"quit_confirm", {})`.

### 4.4 `dialog.tscn` / `quit_confirm.tscn` (W2)
`dialog.tscn` follows UI_SPEC §5.2 exactly (full-rect `MOUSE_FILTER_STOP` → 60 % `void_base` dimmer → `CenterContainer` → `PanelContainer` min width 420 `panel_raised` → title/body/buttons, CONFIRM default focus, Esc = CANCEL). It extends `Screen`, exposes `configure(title, body, confirm_text, cancel_text)` called via `on_route(params)`, and reports to `DialogManager`. `quit_confirm.tscn` is a thin configured variant with title/body for the quit path.

### 4.5 `settings.tscn` (W3)
UI_SPEC §4: full-rect `Screen` → `PanelContainer` (`panel`) → margins 24 → header (Label "SETTINGS" `ScreenTitle` + spacer + BACK) → `TabContainer` with GRAPHICS / AUDIO / CONTROLS / INTERFACE. Rows are the §4.1/§4.2/§4.3/§4.4 controls, all values written through `SettingsManager`. Controls tab builds rows at runtime from `SettingsManager.rebindable_actions()` using `settings_rebind_row.tscn` as the template, with listen mode ("PRESS KEY…"), conflict highlighting in `accent_danger`, and RESET ALL / SAVE in the footer. BACK emits `overlay_close_requested`.

### 4.6 `game.tscn` (W4)
`Node2D` root + `game.gd` → `ParallaxBackground` with three `ParallaxLayer`s (`env_stars_layer1..3`, mirroring 2048², scroll scales 0.02/0.05/0.12) → `Sprite2D` player using `ship_vanguard_side.png` at a gameplay-appropriate scale, `rotation` = heading → `Camera2D` (`position_smoothing_enabled`, speed 5, current) → instanced `hud.tscn`. `game.gd` owns the `PlayerState`: thrust/turn from the input map in `_physics_process`, an ember-free mock drain of shield/hull so the HUD visibly moves, `set_minimap_blips` at ~10 Hz with a `self` blip plus a few neutral/hostile mock blips, `set_target` when a mock target is in range, and `ui_cancel` → `route_requested(&"loading", {destination: &"main_menu"})` (loading is the only bridge in both directions, MENU_FLOW §1).

### 4.7 `hud.tscn` (W5)
UI_SPEC §3 structure exactly: root `Control` (`mouse_filter = IGNORE`, full rect) → `CanvasLayer` layer 10 → TopLeft (hull/shield blocks with caps, AtlasTextures per §2), BottomLeft (ammo panel + 5× `SlotButton` weapon cells 48×48 with the 5 weapon icons at `tint/` modulate, cargo toggle), BottomRight (`NinePatchRect` bezel at patch margins 16 + 200×200 minimap `_draw` + sector label + zoom `TextureButton`s), CenterOverlay (target reticle `_draw` with 4 corner brackets + 60×4 hull micro-bar, and the toggleable cargo panel `GridContainer` 5 columns of 40×40 `SlotButton`s, default hidden). Root `modulate.a` = `SettingsManager` `hud_opacity` on `bind()`. Every HUD `TextureButton` (slot cells, zoom) uses `focus_mode = FOCUS_NONE`: `fire_primary` is `Space`, which is also the engine default `ui_accept`, so a focused HUD button would activate on the same key the player fires with.

## 5. `project.godot` changes (orchestrator-applied via godot-ai)

W0 writes `docs/design/PROJECT_SETTINGS_PATCH.md` listing, exhaustively and machine-readably: autoload name/path/order, the §3.7 input actions with their default bindings, the four audio bus names, and `main_scene`. The orchestrator then applies them with `autoload_manage`, `input_map_manage` and `project_manage(set_main_scene)` against the live editor, runs `filesystem_manage(scan)` so new `class_name` scripts register, and re-reads `project.godot` to confirm.

## 6. Verification (every worker, before reporting done)

1. Parse/import check: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --editor --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit` → exit 0 and no script errors.
2. Boot check: `..._console.exe --headless --path <proj> --quit-after 240` → no parse/runtime errors in stdout.
3. Report the exact commands run and their output. If a check is impossible (editor lock, missing import), say so explicitly instead of claiming success.
4. Never leave `push_error`/print noise in shipped scripts.

## 7. Coding rules (binding)

- Typed GDScript everywhere; `class_name` + `extends` order per godot-best-practices; signal names past_tense snake_case.
- Signals up, calls down. UI never mutates gameplay data; gameplay never reaches into UI nodes.
- No `_process` for UI animation — controller-owned `Tween`s only (UI_SPEC §2, MAIN_MENU_SPEC §5).
- No hex literals outside `tools/build_theme.gd`; read colours from the theme.
- `%UniqueName` or `@onready` typed paths; no absolute `/root/...` paths; no `get_node()` in loops.
- `Tween` created via `create_tween()` on the owning node and killed in `_exit_tree()` if it outlives.
- No comments unless the *why* is non-obvious (AGENTS.md).
- Do not touch another wave's files; report a needed contract change instead of working around it.

## 8. Deferred / out of scope (recorded, not defects)

Hangar, equipment, company select, starmap, login, pause menu, credits screen (MENU_FLOW future scope) · `ui_panel_frame.png` and `ui_slot_inventory_*.png` unconsumed (hangar chrome) · `icon_credits`, `icon_logout` unconsumed · audio cues silent (no files) · gameplay systems beyond the placeholder · settings reachable from the main menu only in v1 (no pause menu means MENU_FLOW's "settings from every screen" invariant is not yet met in the game scene) · `effects_quality` stored but unapplied.

## 9. Phase D amendments (2026-09-18) — menu modernisation and the station hub

### 9.1 Render base changed to 1920x1080

`display/window/size/viewport_width=1920`, `viewport_height=1080`, `window_width_override=1920`, `window_height_override=1080`; stretch stays `canvas_items` / `expand`. Reason: every pixel spec in this contract (§2 art crops, §4.7 HUD sizes, the 280×56 plates, the 14/34 px fonts) was authored for a 1920×1080 base while the project rendered at 1152×648, so all UI was upscaled 1.67× and soft at 1080p. Applied by the orchestrator through `project_manage(settings_set)`, never by hand. Consequence: absolute-positioned screens (boot, loading, main_menu) keep their pixel sizes but change their screen proportion; the container-driven screens (settings, dialog, hud) are unaffected. Resolution stays a user setting (`SettingsManager` graphics resolution and display mode) — the base viewport is fixed, the window is not.

### 9.2 Flow

PLAY → `loading{destination: &"station"}` → `station` (new route) → LAUNCH → `loading{destination: &"game"}` → game. `loading` remains the only bridge (MENU_FLOW §1). `ui_cancel` in the game docks back to the station: `route_requested(&"loading", {destination: &"station"})`. The station exposes LOG OUT → `main_menu`. This supersedes the PLAY and `ui_cancel` intents frozen in §4.3 and §4.6.

### 9.3 Persistent player model

`autoload/player_profile.gd` (autoload `PlayerProfile`, deliberately **no** `class_name`: a global class that hides an autoload singleton is a parse error, and no autoload in this project carries one) is the single owner of credits, ammo, cargo items, owned ships, active ship and installed upgrades, persisted to `user://profile.cfg` with `save_version` 1. `PlayerState` stays scene-local and keeps owning in-game hull and shield; the profile never reaches into a scene and the UI never writes the ConfigFile. Full API and semantics: `docs/design/STATION_SPEC.md`. Stub catalogue of ammo, ships and upgrades: `game/station_catalog.gd` (`class_name StationCatalog`).

### 9.4 Station screen

Route `&"station"` → `res://ui/screens/station.tscn` (Control root, `extends Screen`, bakes `theme` and the router replaces it as §3.12 requires). Modules: OUTFITTING / SHIPYARD / UPGRADES / LAUNCH / LOG OUT. Panels live in `ui/station/`. Every module is container-driven, and every price and value is read from `StationCatalog` and `PlayerProfile` — no literal prices in scenes.

### 9.5 Theme items added for this phase (these names are contract)

`HeroTitle` (48, `text_primary`), `StationButton` (22, Button plus the four plate styleboxes and `focus`), `StationPanelTitle` (20), `StationValue` (18), `StationCaption` (13, `text_dim`), the variation `PanelRaised` (a `PanelContainer` using the `panel_frame` StyleBoxTexture built from `ui_panel_frame.png`, patch margins 32), plus list and scroll chrome for `ScrollContainer`, `VScrollBar`, `ItemList` and `Tree`. All five font-size items must also be present in `Router.FONT_SIZE_ITEMS`. The theme is generated by `tools/build_theme.gd` and never hand-edited.

### 9.6 Mockup workflow (binding for this phase)

Each new screen is first built as a throwaway live mockup scene by a designer worker, screenshotted in the editor and approved by the owner before any implementation: `ui/screens/_mockup_main_menu.tscn` and `ui/screens/_mockup_station.tscn`, each with a companion spec (`docs/design/MAIN_MENU_V2.md`, `docs/design/STATION_HUB.md`). The mockup scenes are deleted when the real screens land. New art, where the audit finds a gap, comes from the image-generator pipeline (`gpt-image-2-5`, 2K, transparent for sprites, RGB on void black for FX) with the generation logged under `vajb-orbit/assets/`.

### 9.7 P1 economy amendments (2026-09-18) — RPG layer, phase P1

Amendments recorded while implementing `docs/gameplay/01`–`05` (P1 economy core):

1. **Rail grows to seven modules.** `station.gd` carries OUTFITTING, REFINERY, EXCHANGE, SHIPYARD, UPGRADES, REPAIRS, LAUNCH plus LOG OUT, per the `STATION_HUB.md` P1 amendment (its §2 table and §5.7–§5.9). §9.4's four-module list is superseded.
2. **Panels are loaded by naming convention, not instanced.** The shell resolves `ui/station/<module>_panel.tscn` at runtime and degrades to a marked placeholder when a panel file is absent (`station.gd` `MODULE_FILES`). "station.tscn instances the four panels" (STATION_HUB §12.1) is superseded; `station.tscn` holds no pane nodes and needed no edit when the three new panels landed.
3. **Save version 2.** §9.3's `save_version 1` is superseded by `save_version 2` with the key set in `17_coder_handoff.md` §3 (v1 profiles migrate to per-key defaults, no data loss).
4. **Catalogue-owned icon tints.** `IMPLEMENTATION_PLAN` §7's "no hex literals outside `tools/build_theme.gd`" governs UI chrome. The per-tier and per-grade icon tints (ICONS_SPEC §8.6) are icon data: they live as `Color` constants in `game/mineral_catalog.gd` (`TIER_TINTS`) and `game/component_catalog.gd` (`GRADE_TINTS`), are consumed by panels as modulate data, and are not duplicated anywhere. This is the documented exception; UI chrome still reads colours from the theme only.
5. **Phase F mineral glyphs wired.** `MineralCatalog.MINERALS` now points `icon_ore` / `icon_ingot` at the dedicated Phase F glyphs (`assets/icons/icon_mineral_<id>_48.png`, `icon_ingot_<id>_48.png`) per ICONS_SPEC §8.1 "retire the 02 §6 fallback"; `TIER_TINTS` remains the fallback for any mineral whose dedicated glyph is absent and is still the tint map for the generic cargo glyphs where they remain in use (components).

### 9.8 Wave-1 review amendments (2026-09-18) — menu cue, fonts, readability, flight placeholder

Amendments recorded while fixing the live walkthrough findings (owner crosscheck, 2026-09-18).
Execution evidence: `.agents/gen/fix_wave1_w7_report.md`.

1. **Menu focus ring removed.** §3.11's focus ring (the 1 px `accent_danger_bright` rectangle drawn by `menu_button.gd`) is retired; the main menu plates never draw a red rectangle for focus. The left band (`_ticks`) stays the selection cue, and the emissive emblem above the verb stack pulses brighter when focus moves between verbs (owner ruling). The idle breathing border and hover border are unchanged. **Scope ruling (Wave-1 W6 review, 2026-09-18):** the retirement covers the `MenuButtonPlate` variation only — Godot draws a `Button`-derived control's theme `focus` stylebox automatically, so W1's script-side removal alone left the same rectangle on screen. `MenuButtonPlate/focus` is now a `StyleBoxEmpty` and the base `Button`, `MenuButton` and `StationButton` focus boxes stay, because the station rail and the dialogs have no other keyboard focus affordance.
2. **Typography adopted.** The theme gains three OFL families (in `assets/fonts/`, licences beside them): Oxanium variable as the display/title face (`FontVariation` wght 700) for `ScreenTitle`, `HeroTitle`, `StationPanelTitle`, `DialogTitle`, `HudReadout`, `MenuButtonPlate`; Rajdhani as the body face (`default_font` Rajdhani-Regular, `StationValue` Rajdhani-SemiBold); Saira Stencil One as the flavour face in a new `FlavourText` variation (version stamp, menu read-out, station subline, minimap sector label). The theme stays generated by `tools/build_theme.gd`; §3.2's `default_font intentionally unset` is superseded.
3. **Station readability.** `station.gd` `BACKDROP_DIM_ALPHA` 0.72 → 0.84 for caption contrast over the blurred backdrop. OUTFITTING's header row gets the same scroll content inset as its rows (`SCROLL_CONTENT_MARGIN` 5 px) so captions sit exactly over their columns. REFINERY's three action buttons share one size (88 px — the LaunchButton height — at the full 360 px box width; the heights are scene values in `refinery_panel.tscn`). The credits frame and a replacement backdrop stay deferred to an art batch.
4. **Flight placeholder pass.** `game.gd`: `DRAG` 260 → 120 and `ACCELERATION` 520 → 420 (inertia); mouse-wheel camera zoom 0.70–1.50, smoothed, script-handled with the input map untouched; the orbiting mock target gains `ship_interceptor_side.png` plus a stats window (`hud.gd` `set_target_info`, mock data — P2 replaces it with real ship data); the HUD gains the bottom-centre `ESC · DOCK AT KEPLER-9` hint and usable minimap zoom buttons.
5. **Interim sector naming.** Station strings change from `SECTOR K-9` to `HELIOS DRIFT` (launch destination and station subline) to match the flight HUD's sector label; the seven-sector roster of `docs/gameplay/11_galactic_map.md` supersedes all of it at P2.

### 9.9 Engine wave amendments (2026-09-18) — flight, mining, sectors

Amendments transcribed from `docs/gameplay/18_engine_spec.md` (owner-locked 2026-09-18 as the workspace-root `ENGINE_SPEC.md`; moved into `docs/gameplay/` as doc 18 on 2026-09-20) before any engine code was written. The spec is the contract; every number below lives there, in §13. The 2026-09-20 rulings 8–26 in the spec's §2.1 extend this section with slice 0 (physics & fuel) and the amended slice 2 scope — transcribed by the slice-0/slice-2 doc-check workers, not here.

Decisions 1–7 of ENGINE_SPEC §2 are law for the engine phase:

1. **Controls: hybrid.** WASD always available; clicking empty space sets a fly-to order that any manual input cancels. Mass-scaled inertia — the heavier the ship, the more noticeable.
2. **Weapons: families × cursor aim.** All guns fire toward the cursor; the lock only marks (HUD, rocket homing). Energy = instant, shields-first. Kinetics = travelling bolts, bypass shields. Rockets = homing, destructible, flight time. Mines = dropped.
3. **Exit: hardcore + safe warp.** While an enemy is engaged there is no escape button — fly to a station or gate. Safe warp only when no enemy is engaged: a few-second channel with an animation, landing docked at the current sector's station; no station in the sector → no warp.
4. **Sectors: same size, different identities.** One arena size for all; sectors differ by backdrop/palette, owning faction, resource tier mix (11 §1.1), enemy mix and density, hazards.
5. **NPCs: six archetypes** on one shared brain (pirate, patrol, trader/convoy, hunter wing, station turret, boss).
6. **Mining: laser primary, guns secondary.** Regular weapons can also break rocks, at 10 % efficiency vs the mining laser.
7. **Death: cargo drops.** Cargo spawns as pickups at the wreck with a 5-minute recovery window; hull/fit follow 14 §3 insurance.

Amendments to this contract:

- **§3.7 input map.** Two actions are added: **`interact` = F** (dock/gate/interact prompts) and **`warp` = H** (safe warp); the rebinding list grows to 17. `ui_cancel` (ESC) keeps its binding but its in-game meaning changes to *cancel order + lock*. The two actions are recorded in `PROJECT_SETTINGS_PATCH.md` §2 and applied by the orchestrator via godot-ai after this wave; until then, code reads them behind `InputMap.has_action(&"interact")` / `&"warp"` guards.
- **§3.9 `PlayerState.damage`.** Signature becomes `damage(amount: float, bypass_shield := false) -> void` (ENGINE_SPEC §4.2): a non-bypassing hit is absorbed by a live shield up to its current value with **no carry-over**; otherwise hull takes it. The HUD signals are unchanged.
- **§3.10 `Hud`.** Gains `set_prompt(text: String)` (empty hides) and `set_warp_channel(progress: float)` (≤ 0 hides); blip kinds gain `&"friendly"`; the `set_target_info` payload gains a range state (in/out per selected weapon); the reticle is drawn at the cursor with plain/in-range/out-of-range/hostile states (slice-1 scope: plain + mining states) and small hit markers, with no floating damage numbers in v1.
- **Retirements.** The ESC-docks-anywhere placeholder retires (decision 3): §4.6's and §9.2's `ui_cancel` docking intent is superseded — docking is the station dock zone's `F` prompt (`interact`), and ESC in-game only cancels the fly-to order and the lock. The route out of flight stays dock → station → LOG OUT (§9.2). The `MOCK_*` constants in `game.gd` retire with it (the §4.6 mock shield/hull drain, the orbiting mock target and the mock minimap blips), as does §9.8 item 4's static `ESC · DOCK AT KEPLER-9` hint.
- **Companion doc amendments in the same wave**, all transcribed from the same spec: 08 §2 (the per-class handling column is ENGINE_SPEC §13 and 08 references it), 09 §3.1 (weapon `family` + `shield rule` columns; the railgun's "ignores 50 % armour" line retired), 09 §3.2 (base shield regen 2/s), 11 §1 (one arena size for every sector).

Interface and numbers for slice 1 come from ENGINE_SPEC §9 (`ShipFit`/`ShipStats`), §13 (calibration: speed scale, per-class handling, weapon ranges, aggro radii, `AGGRO_COOLDOWN`, `WARP_CHANNEL`, `SECTOR_SIZE`, pickup lifetime and tractor values, `MINE_CYCLE`) and §14 slice 1 (file ownership).

**Slice 0 — Physics & fuel (2026-09-20; spec §2.1 ruling 8, §14 slice 0 — the migration wave that runs before slice 2).** Deliverable: the hull flies on real physics and runs on the reactor chain, so slice 2 codes on top unchanged. `game/impact.gd` is new (collision damage, recoil/knockback/explosion impulse helpers); `game/player_ship.gd`'s `HullBody` becomes a `RigidBody2D`, thrust forces = mass × class acceleration and torque mass-scaled, the §3.2 accel/coast/spin-up feel preserved by derivation rather than retuned, plus contact-monitor collision damage and the recoil caller; `game/asteroid.gd` turns the static rock into a rigid body with heavy mass and damping so fields drift slow, `game/asteroid_field.gd` takes the spawn wiring; the wave lands the **tiered cleaving** (fragment spawn on depletion, §6) and the **energy/fuel pools** — `ShipStats`/`ShipFit` gain `hull_mass`/`energy_max`/`energy_regen`/`fuel_max`, `PlayerState` gains the pools plus `try_spend_energy` and emergency mode, `impact.gd` wires §4.2 items 6–8. Station side: `repairs.gd` gains the refuel/recharge services (§12 item 8), `autoload/player_profile.gd` persists fuel (save v3), and the HUD gains `set_pool`/`set_emergency`. Speed table v2 bakes in only after the owner's tick (§16 item 1).

**Owner ruling 2026-09-21 — refuel and recharge are free station services.** Both charge no CR: refuel and recharge are free and instant, and the spec carries no refuel CR rate, so no worker may invent one. This supersedes the pinned-interface wording that sourced a rate per fuel point from `18_engine_spec` §13 (that pointer survives only in the owner-locked spec's §4.4 ruling 13 and §12 item 8; `14_station_services.md` §1 no longer repeats it) and closes M0 discrepancy D3 (`.agents/gen/slice0_m0_report.md`).
