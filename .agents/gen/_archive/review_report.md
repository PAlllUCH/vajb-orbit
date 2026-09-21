# Phase C review — 2026-09-17

Reviewer: W6 (world state read from disk + headless runs; no editor session driven, no file changed except this report).
Contract: `docs/design/IMPLEMENTATION_PLAN.md` (frozen, incl. the §3.2 amendments) is the authority; where it states a measured number it was checked against the code and, for the asset facts, re-measured with Pillow.

## Verdict

**16 issues found — 0 BLOCKER, 3 MAJOR, 8 MINOR, 5 NOTE.**

Nothing breaks at load: all three runtime checks pass with exit 0 and not a single warning, and every path/identifier/interface in the aggregation checklist resolves. The three MAJOR findings are all behaviour-level: focus is lost after closing the settings overlay, the minimap never re-centres on the player, and the interface UI-scale setting is inert (the W3 suspect — confirmed, with the exhaustive fix list below).

One reviewer probe script (`res://tools/_probe.gd`, `extends SceneTree`, `quit()`-terminated) was used for four measurements and **deleted with its `.uid` sidecar before this report was written**; `tools/` holds only `build_theme.gd` + `derive_icon_tints.gd` (+ their `.uid`).

## Findings

| # | Severity | File:line | Problem | Suggested fix |
|---|---|---|---|---|
| 1 | MAJOR | `autoload/router.gd:89-93` (+ `ui/screens/settings.gd:68`) | `push_overlay()` records the focus opener **after** `add_child()`/`on_route()`. `settings.gd::_ready()` grabs focus on `%ResolutionOption`, so the opener stored for the settings overlay is a control **inside** the overlay. Measured: focus before push = `/root/MainMenu/MenuButtons/OptionsButton/Button`; recorded opener = `…/OverlayLayer/Settings/…/ResolutionOption`; focus after `pop_overlay()` = `<null>`. `dialog.gd` avoids this by deferring its grab (`dialog.gd:42`), which is why the quit dialog is correct and OPTIONS is not. Violates MAIN_MENU_SPEC §7 ("Menu ⇄ Settings overlay … focus restored to the opener") and MENU_FLOW §1. | Move `var opener := _focus_weakref()` above `_overlay_layer.add_child(instance)` and store it in the entry (or defer `settings.gd`'s `grab_focus()` like `dialog.gd` does). |
| 2 | MAJOR | `ui/hud/minimap.gd:95-104` (+ `game/game.gd:181-190`) | Blips are plotted as **absolute world coordinates** (`offset = world * unit`, origin = world 0,0), and the `self` blip is plotted the same way. The ship starts at the origin, so the map looks right, but after flying ≳ `world_radius` (default 3200 u; MAX_SPEED 420 ⇒ ~7.6 s of thrust) the player blip and every contact falls outside the 200×200 disc and `_draw_blips()` skips them all — the minimap goes permanently empty. There is no player-centred origin anywhere in the draw path. | Derive the origin from the `self` blip (`offset = (pos - self_pos) * unit`, self drawn at the centre) or add an explicit origin to the Hud API; keep the off-disc skip for contacts. |
| 3 | MAJOR | `tools/build_theme.gd:150-155, 179-180, 202` (+ `ui/theme/vajb_theme.tres:283-393`) | **Confirmed: the UI-scale setting does nothing visible.** The generated theme pins a per-type size for every text-bearing type; per-type items shadow `Theme.default_font_size`, which is the only thing `Router.live_theme()` scales (`router.gd:113-119, 264-266`). Measured with a live (duplicated) theme whose `default_font_size` was forced to 20 (the value `ui_scale = 1.4`, currently in `user://settings.cfg`, produces): `DestinationLabel` (ScreenTitle) = 22, menu `Button` (MenuButtonPlate) = 34, `VersionLabel` = 13, and only text-less types (Control/Container/TextureRect/ProgressBar/HSlider) follow the scaled default. Real user data on disk (`ui_scale=1.4`) therefore changes nothing on screen. | Scale every item in the table below in `Router.live_theme()` (duplicate → multiply each item by `ui_scale`, keeping the unscaled values from the source theme) or drop the per-type items in `build_theme.gd` and drive one multiplier. Either way the per-node overrides in finding 9 must move into the theme first, or they stay pinned. |
| 4 | MINOR | `ui/screens/settings.gd:174` (`print("SettingsScreen: %d rebind rows built" …)`) and `game/game.gd:216,220,224` | Contract §6.4: "Never leave `push_error`/print noise in shipped scripts." Line 174 prints on **every** settings open (observed in a probe run: `SettingsScreen: 15 rebind rows built`). The three `game.gd` prints only fire on the HUD-missing degraded path, but they are still unconditional `print`s in a shipped script. | Delete the settings print; keep the HUD-missing diagnostics only if they become `push_warning` and stay gated behind "HUD genuinely unavailable". |
| 5 | MINOR | `ui/screens/boot.tscn:30,70,77`, `ui/screens/loading.tscn:25` | Raw `Color(…)` literals in scenes re-state theme tokens: boot backdrop & loading backdrop = `void_base` `#07090d` (`0.02745098,0.03529412,0.050980393`), boot `Track` = `metal_dark` `#1b2028`, boot `ProgressFill` = `metal_light` `#3d4654`. Contract §3.2: "**All hex literals live here and nowhere else**"; §7: "No hex literals outside `tools/build_theme.gd`; read colours from the theme." (No `"#rrggbb"` string exists outside the generator — the violation is the duplicated values, not the syntax.) A future token change silently desyncs the splash screens. | Give the backdrops the themed `PanelContainer`/`panel` stylebox, or set `color = _token(&"void_base")` etc. from script (boot/loading already have a `_token()` helper in the sibling screens), or add a `Backdrop` variation to the theme. |
| 6 | MINOR | `ui/hud/hud.gd:422-438`, `game/game.gd:130-137` | `cargo_toggle` (C) is created and shown in the rebind list, but nothing reads it: `game.gd` never checks `Input.is_action_just_pressed(&"cargo_toggle")`, and the HUD's panel state is private (`_set_cargo_open`) with no public setter in the §3.10 API — so `_on_cargo_toggled(_open)` in `game.gd` only refreshes blips. The binding is dead. | Either add `Hud.set_cargo_open(open: bool)` to the contract §3.10 API and call it from `game.gd` on `cargo_toggle` (symmetry with `weapon_slot_selected`), or remove the action. |
| 7 | MINOR | `ui/screens/settings.gd` (no `_input`/`_unhandled_input` for `ui_cancel`) | The settings overlay cannot be dismissed with Esc/B — only the BACK button works. MENU_FLOW §3.12: "B/Esc closes only when nothing is dirty"; in v1 every control applies live, so nothing is ever dirty. A keyboard/gamepad user must Tab to BACK. | In `settings.gd`, when `_listening_row == null` and `event.is_action_pressed(&"ui_cancel")`, mark input handled and emit `overlay_close_requested`. |
| 8 | MINOR | `game/game.gd:82-94, 213-229` | The HUD never receives `Router.live_theme()`: `Router.route()` assigns it only when the routed root `is Control` (`router.gd:63-64`) and `game.tscn`'s root is a `Node2D`, so the HUD keeps its baked theme. Harmless today only because ui_scale is inert (finding 3) — after that fix the HUD would still not scale. The HUD is already written for it (`hud.gd:122-130` re-propagates on `NOTIFICATION_THEME_CHANGED`). | In `_instantiate_hud()`, after `add_child(instance)`: `instance.theme = Router.live_theme()` (or have `Hud.bind()` pull it). |
| 9 | MINOR | `ui/dialogs/dialog.tscn:53` (`theme_override_font_sizes/font_size = 18`), `ui/screens/main_menu.gd:18,115` (`VERSION_FONT_SIZE = 13`) | Per-node font-size overrides, which UI_SPEC §2.1 forbids ("no per-node `add_theme_font_size_override`") and the contract sanctions only for the hull-bar fill (#3.2). They also cannot be scaled by any theme-side fix, so these two strings would stay pinned after finding 3 is fixed. | Add `DialogTitle` (18) and `Version` (13, `text_dim`) variations to `build_theme.gd` and use `theme_type_variation` in the two places. |
| 10 | MINOR | `ui/components/slot_button.tscn:26-35` | The slot-number overlay uses `theme_type_variation = &"SectionHeader"` → 16 px, in an 8×16 px rect (offsets `3,1 → 11,17`). UI_SPEC §3.2 asks for a "tiny `Label` overlay in the corner of the cell"; a 16 px glyph is not tiny and overflows its rect in a 48×48 cell. | Add a small (10-11 px) label variation for the slot number, or widen the rect and lower the size. |
| 11 | MINOR | `ui/hud/hud.tscn:350-360` | The reticle's hull micro-bar is positioned with fixed offsets (`-6,50 → 54,54`) instead of being laid out by the `VBoxContainer` UI_SPEC §3.5 specifies ("bracketed by a `VBoxContainer` inside the reticle `Control`"). Geometry is correct (60×4); this is structural only. | Wrap the brackets control and the bar in a `VBoxContainer`, or amend UI_SPEC §3.5 to allow fixed offsets. |
| 12 | NOTE | `ui/paths.gd:17` | `UIPaths.ROUTES` carries an extra `&"hud"` entry that contract §3.1 does not list. It is an addition (nothing existing was changed) and `game.gd:214` needs it. | Record it as a contract §3.1 amendment so the next phase does not treat it as drift. |
| 13 | NOTE | `tools/build_theme.gd:152`, `vajb_theme.tres:343` | `RichTextLabel` only pins `normal_font_size` 13; `bold_font_size` / `italics_font_size` / `bold_italics_font_size` / `mono_font_size` are unset, so they resolve from `default_font_size`. Measured: with `default_font_size = 20`, RTL normal = 13 but bold/italics/bold_italics/mono = 20. Once ui_scale works, bold text inside a tooltip/dialogue would not match its body text. | Set the four sibling items explicitly in `build_theme.gd` (all 13) and include them in the scaling list. |
| 14 | NOTE | `ui/screens/boot.gd:11-20, 40-52` | Boot's own timeline is exactly 3.0 s (0.5 + 0.9 logo, 0.15 flicker, 3 ticks + tail to 2.4, 0.6 crossfade), and the Router then adds 0.2 + 0.2 s (`router.gd:13`). MAIN_MENU_SPEC §8 item 1 ("Boot ≤ 3 s end-to-end") therefore holds only if the router transition is excluded. | No action required unless the 3 s budget is meant to include the router fade. |
| 15 | NOTE | `ui/hud/minimap.gd:96,103` vs `game/game.gd:186` | The status doc's "blip key type" concern is a non-issue: measured in 4.7.2, a `String` key and a `StringName` key are interchangeable in `Dictionary` lookups (`{&"id": …}.get("id")` and `{"id": …}.get(&"id")` both resolve). No code change needed. | Harmonise the contract §3.10 wording (quote the keys) so the next reader does not "fix" a non-bug. |
| 16 | NOTE | `autoload/dialog_manager.gd` (whole file) | `confirm()` / `message()` / `resolved()` have **no caller in Phase C**: the quit path goes straight to `overlay_requested(&"quit_confirm")` (MAIN_MENU_SPEC §6), which is correct, so `DialogManager` is contract-complete but entirely unexercised — including its queue, its `_visible` heuristic and its re-`pop_overlay()` after an external pop. | No action for this phase; flag it so the first real dialog (rebind-conflict / discard-changes) is verified against a working manager. |

### 3. — the exhaustive font-size list that must scale (finding 3)

Every item below is written by `tools/build_theme.gd` and shadows `Theme.default_font_size`; each must be multiplied by `ui_scale` (or removed in favour of one scaled multiplier).

| Theme type | Item | Base | `build_theme.gd` line |
|---|---|---|---|
| `Label` | `font_size` | 14 | 150-151 |
| `Button` | `font_size` | 14 | 150-151 |
| `LineEdit` | `font_size` | 14 | 150-151 |
| `OptionButton` | `font_size` | 14 | 150-151 |
| `PopupMenu` | `font_size` | 14 | 150-151 |
| `RichTextLabel` | `normal_font_size` | 13 | 152 |
| `TooltipLabel` | `font_size` | 13 | 153 |
| `TabContainer` | `font_size` | 14 | 154 |
| `TabBar` | `font_size` | 14 | 155 |
| `ScreenTitle` | `font_size` | 22 | 179-180 (`LABEL_VARIATIONS`, declared 38-42) |
| `SectionHeader` | `font_size` | 16 | 179-180 |
| `HudReadout` | `font_size` | 18 | 179-180 |
| `MenuButton` | `font_size` | 34 | 199-202 |
| `MenuButtonPlate` | `font_size` | 34 | 199-202 |

Total: **14 items on 14 theme types** (matches `theme.get_font_size_type_list()` in the generated `.tres` exactly). Additionally:

- `Theme.default_font_size = 14` (`build_theme.gd:91`) — already scaled by `Router.live_theme()`; it is the *only* thing that currently scales, and it reaches no text widget.
- `RichTextLabel`'s four unset siblings (`bold_font_size`, `italics_font_size`, `bold_italics_font_size`, `mono_font_size`) currently follow `default_font_size` — see NOTE 13.
- Per-node overrides that a theme-side fix cannot reach and that must be converted to variations first: `ui/dialogs/dialog.tscn:53` (18) and `ui/screens/main_menu.gd:18,115` (13).

## Contract conformance

| Contract section | Verdict |
|---|---|
| §3.1 `ui/paths.gd` | **PASS** — `class_name UIPaths extends RefCounted`, `THEME`, `ROUTES` (7 contracted keys + `hud`, NOTE 12), `SETTINGS_FILE`, `INPUTS_FILE` all exact; two extra `const`s (`GRAIN`, `AUDIO_DIRS`, plus `AUDIO_BUSES`/`AUDIO_SUB_BUSES`) are additive helpers. |
| §3.2 theme | **PASS with the finding-3 caveat** — 12 `Tokens` colours including `menu_glow`@0.60 and `void_fade`; all 8 contracted variations present (plus `MenuButton`, amendment 1) with the contracted items; base items registered on `""` and wired to `PanelContainer`/`Panel`/`PopupPanel`/`PopupMenu`/`TabContainer`/`Button`/`LineEdit`/`Slider`/`ProgressBar`/`TooltipPanel`/`TabBar`; `ProgressBar/background|fill` wired from `progress_bg`/`progress_fill`; `HudHullBar` fill `accent_danger`, `HudShieldBar` fill `metal_light`; slots are four `StyleBoxTexture`s each; corners radius 0, 1 px borders; `default_font` unset (deliberate). All per-type font sizes are present — which is exactly finding 3. |
| §3.3 icon tints | **PASS** — `derive_icon_tints.gd` reads `icon_*_{16,48}.png`, forces RGB=white, asserts the alpha channel byte-identical, writes `assets/icons/tint/`; 40 tint files exist and cover every Phase C consumer. |
| §3.4 `ui/screen.gd` | **PASS** — `class_name Screen extends Control`, the three signals and `on_route(params: Dictionary)` exact; `settings.tscn`, `dialog.tscn` and (via instancing) `quit_confirm.tscn` all extend it. |
| §3.5 autoloads + API | **PASS** — `project.godot [autoload]` holds exactly `_mcp_game_helper`, `SettingsManager`, `AudioManager`, `Router`, `DialogManager` in that order; every frozen signature matches (incl. `DialogManager.resolved(id, confirmed)`); services are looked up by name so a missing one degrades instead of crashing. |
| §3.6 settings keys | **PASS** — `graphics`: `resolution`/`display_mode`/`vsync`/`render_scale`/`effects_quality` (stored-only no-op, documented); `interface`: `ui_scale` 0.85-1.5, `hud_opacity` 0.4-1.0; `audio` defaults are the corrected per-key values (master 0 dB, music −8, sfx −6, ui −10 dB) and match `PROJECT_SETTINGS_PATCH.md` §3 exactly; debounced save; `__WM_CLOSE_REQUEST`/`EXIT_TREE` flush. |
| §3.7 input map | **PASS with two convention flags** — all 15 actions in the specified order with the specified keycodes (W/S/A/D/Space/Ctrl/E/Shift/C/1-5/Q); `ui_*` untouched. `fire_secondary` is never read by the game (no spec asks for it); `cargo_toggle` is dead (finding 6). |
| §3.8 audio | **PASS** — 7 buses (`Master`, `Music`, `SFX`, `UI`, `SFXWeapon`, `SFXImpact`, `SFXWorld`) built in `_ready()` with the contracted sends; `UiCue{CLICK,HOVER}`; cues resolve `CUE_DIRS[bus] + cue + ".ogg"` and return silently (no audio files exist — approved). |
| §3.9 `PlayerState` | **PASS** — `class_name PlayerState extends Resource`; the 5 signals, all members (`hull_max` 1000, `shield_max` 600, `cargo_max` 40, `ammo`/`ammo_max` `Array[int]`, `const WEAPONS` in the contracted order) and all 6 methods exact; created at runtime in `game.gd:83` (`PlayerStateScript.new()`), never `@export`. |
| §3.10 `Hud` API | **PASS** — 3 signals and the 6 methods exact; `bind(PlayerState)` is connected signal-per-signal and `_release_state()` disconnects cleanly; the HUD only reads state. |
| §3.11 `MenuButton` | **PASS** — `Control` 280×56 → `Glow` (full rect −6, `mouse_filter = IGNORE`/2) → `Button` (`MenuButtonPlate`); glow is a `StyleBoxFlat` with `expand_margin_* = 6` drawn in `_draw()`; two looping tweens (4 s breathing desynchronised by a golden-ratio stride over ±0.6 s, 0.98 press for 80 ms); own 1 px ring drawn in `_draw()`; emits `pressed`/`hovered`/`unhovered`; **no `_process`, no cross-node `get_node()`**. |
| §3.12 theme + F6 | **PARTIAL** — every screen/overlay root bakes `vajb_theme.tres` and `Router` replaces it with `live_theme()`; the HUD is not a routed root and therefore never receives the live theme (finding 8). |
| §4.1 boot | **PASS** — `Screen` → `void_base` → logo `AtlasTexture` `Rect2(44,707,1961,615)` `filter_clip` → 2 px / 240 wide progress line with ticks 25/60/100 → black `ColorRect` crossfade; timeline 0.5/1.4/1.4-1.7/1.4-2.4/0.6 (≤3 s); no input, nothing focusable; skip guard = `ResourceLoader.has_cached(main_menu)` sets logo α 1.0 and jumps to 1.4 s; emits `route_requested(&"main_menu", {})`. |
| §4.2 loading | **PASS** — `void_base` → `env_loading_bg` at 40 % → centred `ScreenTitle` "ENTERING SPACE" → `ProgressBar` 260×14 (base styles) tweened 0→100 over 1.2 s → 0.4 s fade → `route_requested(params["destination"], params)` (default `&"game"`, `sector` supported); no cancel button. |
| §4.3 main_menu | **PASS** — BackgroundLayer → GrainLayer → logo (8 %/12 %) → `MenuButtons` VBox (8 %/58 %, sep 14) with 3 `MenuButton`s → `VersionLabel` (13 px, bottom-right 12); dust drift, ember pulse at (0.791, 0.618) with `CanvasItemMaterial.blend_mode = ADD` and α 0.25↔0.45 over 8 s, default focus PLAY, Esc → quit dialog, `AudioManager` hooks on the controller not the buttons; intents are exactly PLAY → loading{game}, OPTIONS → settings overlay, EXIT → quit_confirm overlay. |
| §4.4 dialogs | **PASS** — full-rect `MOUSE_FILTER_STOP` → 60 % `void_base` dimmer → `CenterContainer` → `PanelContainer` min width 420 `panel_raised` → title/body/END-aligned buttons (CONFIRM is the danger-styled one, `border_color = accent_danger`); `on_route(params)` → `configure()`; reports to `DialogManager` when an id is present; `quit_confirm.tscn` is a thin instance with `focus_confirm = false` (Cancel default, MENU_FLOW §3.13) and Esc = CANCEL. |
| §4.5 settings | **PASS** — `PanelContainer(panel)` → margins 24 → header (ScreenTitle + spacer + BACK) → `TabContainer` GRAPHICS/AUDIO/CONTROLS/INTERFACE; every row writes through `SettingsManager`; CONTROLS builds rows at runtime from `rebindable_actions()` using the template scene with listen mode ("PRESS KEY…"), Esc-cancels-capture, `accent_danger` conflict highlighting, RESET ALL + SAVE footer; BACK emits `overlay_close_requested`. |
| §4.6 game | **PASS** — `Node2D` + `game.gd` → `ParallaxBackground` with 3 mirrored `ParallaxLayer`s (0.02/0.05/0.12) → `Sprite2D` (`ship_vanguard_side.png`, rotation = heading) → `Camera2D` (`position_smoothing_enabled`, speed 5, `enabled`) → instanced HUD; `PlayerState` owned by the game; thrust/turn/boost in `_physics_process`; shield→hull mock drain; blips at 10 Hz (self + 5 mock); `set_target` when a mock target is in range; `ui_cancel` → loading{main_menu}. `cargo_toggle` unhandled (finding 6); the mock target's 260 u orbit is always inside the 1400 u range, so `clear_target()` is unreachable (NOTE-level, no action needed). |
| §4.7 hud | **PASS** — `Control` (IGNORE, full rect) → `CanvasLayer` 10 → the four zones with margins 12; caps as the two contracted `AtlasTexture` regions on both bars (260×14); ammo panel (`panel_raised` override) + 5 weapon `SlotButton`s 48×48 with `tint/` icons and slot numbers; cargo toggle; `NinePatchRect` bezel with all four patch margins 16 hosting the 168×168 `MinimapView`; sector label + 16 px zoom buttons; reticle with 4 corner brackets + 60×4 micro-bar; cargo panel 5×40×40 cells + CARGO n/40 + close, hidden by default; `modulate.a` = `hud_opacity` on `bind()`; every HUD `TextureButton` is `FOCUS_NONE` (slot cells set it in script, the rest in the scene). |
| §5 `project.godot` | **PASS** — exactly the patch: 5 autoloads in order, the 15 actions with the patch's keycode numbers (`87/83/65/68/32/4194326/69/4194325/67/49-53/81`), `main_scene = res://ui/screens/boot.tscn`. The patch document accounts for every applyable key and nothing else in the file is claimable by it (`[display] canvas_items/expand`, `[physics] Jolt`, `[rendering] d3d12`, `[editor_plugins]` predate Phase C per AGENTS.md). Not a git repo, so "left alone" is verified against the patch's scope, not against history. |
| §6 verification / §7 coding rules | **PASS except** the print noise (finding 4), the scene colour literals (finding 5) and the per-node font overrides (finding 9). Signals-up/calls-down holds everywhere; no `_process` in UI; no `/root/...`; no `get_node()` in loops or hot paths; no `@export` Resource; typed GDScript with snake_case past-tense signals; all tweens killed in `_exit_tree()`; no `WeakRef` touched without `is_instance_valid`; no hex literal outside the generator. |

## Aggregation checklist (1-6)

1. **Filenames — PASS.** `UIPaths.THEME`/`GRAIN`, all 8 `ROUTES` values (incl. `hud`) and all 3 `AUDIO_DIRS` resolve on disk. All 30 `ExtResource` paths across the 10 `.tscn` files exist (verified file-by-file, incl. the two `tint/` icon families and `fx_ember_pulse.png`). The 4 `uid://` refs in `game.tscn` match their `.import` files exactly.
2. **Identifiers — PASS.** Every `%UniqueName`/`$Path` used by the 10 scripts was matched against the scene that declares it (hud: 21 names; settings: 23; dialog: 6; main_menu: 6; boot: 4; loading: 3; slot_button: 2; target_reticle: 1; rebind row: 4) — no misses. `PlayerState`/`Hud` signal names match between emitter (`player_state.gd`, `hud.gd`) and consumer (`hud.gd`, `game.gd`) character-for-character; `MenuButton`'s emitted names match `main_menu.gd`'s connects.
3. **Interface contracts — PASS.** `Router._bind_intents()`'s handlers match the `Screen` signal arities (`route_requested(2)` → `_on_route_requested(2)`, `overlay_requested(2)`+bound source → `_on_overlay_requested(3)`, `overlay_close_requested(0)`+bound → 1). `DialogManager._show_next()`'s dictionary keys equal `dialog.gd`'s `PARAM_*`; `game.gd`'s `_hud.call(...)` arities equal the §3.10 signatures; `Hud.bind(state: PlayerState)` receives a real `PlayerState` from `PlayerStateScript` (the same script), which the clean `game.tscn` run proves (the `_hud_api_ready()` guard would have printed otherwise).
4. **Data formats — PASS.** Route params `{destination, sector}` are read with the same names; blips use `{pos, kind}` and `minimap.gd` reads exactly `"pos"`/`"kind"` with `&"self"`/`&"hostile"` compared against W4's `&"self"`/`&"hostile"`/`&"neutral"`; `game.gd`'s `MOCK_BLIPS` use `&"offset"`/`&"kind"` internally and it reads them with the same names; String/StringName key interchangeability measured (NOTE 15). All 15 rebind rows, the 4 resolutions and the 3 display/effects levels index the same enums as `SettingsManager`.
5. **Wiring — one FAIL.** Connected and verified: the three `Screen` intents, `MenuButton.pressed/hovered`, `Router.overlay_popped` (main_menu re-focuses EXIT), `SettingsManager.setting_changed` → Router, all four `PlayerState` signals → HUD, all three HUD signals → game, every `Tween` is created and started (boot ticks/flicker/crossfade, loading progress/fade, menu drift/ember, per-button breath/press) and killed in `_exit_tree()`. `bind()` is called on a real `PlayerState`. **Fail:** the focus opener recorded by `push_overlay()` (finding 1), plus the dead `cargo_toggle` action (finding 6).
6. **Extraneous output — PASS.** No reference to a node, resource, action or method that does not exist: grep found no engine-default fallbacks, no `Identifier not found`, and all three runtime commands produced zero warnings. The only prints in shipped scripts are the four in finding 4.

## MAIN_MENU_SPEC §8 acceptance

| # | Item | Verdict |
|---|---|---|
| 1 | Boot ≤ 3 s end-to-end; no interactive elements during boot | **PASS** — boot's own sequence is exactly 3.0 s (NOTE 14 about the router's extra 0.4 s); the progress line is the only thing after the logo, every boot node is `MOUSE_FILTER_IGNORE` and nothing is focusable, so no key can do anything. |
| 2 | Exactly one accent colour visible; ember only as logo flicker, button hover bloom/focus ring, background wreck pulse | **PASS** — the logo flicker tweens to `accent_danger_bright` for 0.15 s once; the ember pulse is the wreck; the halo is the `menu_glow` underlay; the focus ring is the sanctioned state colouring (UI_SPEC §2.1/§4). No other accent reaches the menu graph. |
| 3 | Hover glow on menu buttons only — no `#E8703A` halo reachable anywhere else in this scene graph | **PASS** — `menu_glow` is read only by `glow_underlay.gd`, which is instantiated only inside `menu_button.tscn`, which is instantiated only by `main_menu.tscn`. (`#e8703a` appears exactly once in the tree: `build_theme.gd:30`.) |
| 4 | Keyboard-only run: PLAY reachable, focus ring on all three, Esc → quit dialog, Cancel returns focus to EXIT | **PASS** — default focus PLAY plus a container-guaranteed PLAY→OPTIONS→EXIT order; each button draws its own 1 px `accent_danger_bright` ring on focus, and it is **visible**: the plate art's outer 3 px are transparent (measured: columns/rows 0-2 have α ≤ 89), so the ring drawn behind the plate shows through. Esc opens the quit dialog (guarded against a stacked overlay); the dialog defers its focus grab, so the opener really is EXIT, and `main_menu._on_overlay_popped(quit_confirm)` re-focuses EXIT as a belt-and-braces. |
| 5 | Background animation without `_process` in any UI node | **PASS** — grep: `_process` exists nowhere in `ui/`, `autoload/` or `tools/`; the only `_process`-family override in project code is `game.gd::_physics_process`. Both idle animations are controller-owned looping tweens. |

## Runtime evidence

All three commands from the brief were run against the console binary with `--path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"`. Nothing hung; every run returned in a few seconds.

```
1) ..._console.exe --headless --path <proj> --quit-after 240
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT=0

2) ..._console.exe --headless --path <proj> res://ui/screens/main_menu.tscn --quit-after 300
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT=0

3) ..._console.exe --headless --path <proj> res://game/game.tscn --quit-after 300
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT=0
```

Nothing else was printed: no parse errors, no missing resources, no "Node not found", no orphan-node or invalid-theme-item warnings, no GDScript reload errors. Run 1 is the full loop (boot → main menu, 3 s of boot inside the 4 s/240-frame window) and it exited 0, so boot's `route_requested` found its listener (the orchestrator's `_bind_entry_scene` hotfix holds). Run 3 printed none of `game.gd`'s three HUD-unavailable messages, which means `hud.tscn` loaded, passed the §3.10 API guard and got `bind()`ed.

Additional measurements (the temporary probe, since deleted; output quoted as produced):

```
# theme font-size shadowing, live-theme duplicate with default_font_size forced to 20
PROBE res://ui/screens/loading.tscn with live theme default_font_size=20
PROBE   DestinationLabel [Label] implicit=22 explicit=22      # ScreenTitle pinned
PROBE   Progress [ProgressBar] implicit=20 explicit=20        # no per-type item -> scaled
PROBE res://ui/screens/main_menu.tscn with live theme default_font_size=20
PROBE   Button [Button] implicit=34 explicit=34               # MenuButtonPlate pinned
PROBE   VersionLabel [Label] implicit=13 explicit=13          # per-node override pinned
PROBE RichTextLabel scaled-to-20: normal=13 bold=20 italics=20 bold_italics=20 mono=20
PROBE font_size types=14 items=14   # exactly the 14 items in the finding-3 table

# overlay focus-opener ordering
PROBE focus before push = /root/MainMenu/MenuButtons/OptionsButton/Button inside_tree=true
SettingsScreen: 15 rebind rows built                          # finding 4, seen live
PROBE recorded opener = ResolutionOption (path /root/Router/OverlayLayer/Settings/Panel/Margin/Layout/Tabs/GRAPHICS/ResolutionRow/ResolutionOption)
PROBE focus after pop = <null>                                # finding 1, confirmed

# dictionary key interchangeability
PROBE String key read by StringName = quit
PROBE StringName key read by String = quit
```

Measured asset facts re-checked with Pillow (`py -3.14`): `ui_bar_caps.png` = 42×14 RGBA with columns 20-21 empty (left cap 0-19, right cap 22-41) → the two regions in `hud.tscn` are right; `ui_minimap_bezel.png` = 200×200 with an opaque centre and alpha-0 corners, so `patch_margin_* = 16` on a 168×168 interior is right; `logo_vajb_orbit.png` ink bbox = (56, 719)-(1994, 1310), inside the contracted crop `Rect2(44, 707, 1961, 615)`; `fx_ember_pulse.png` = 2048×2048 **RGB, no alpha** (used additively, per contract); `ui_button_plate_*.png` = 280×56 RGBA with a transparent 3 px outer margin; `env_loading_bg.png` has 0 warm pixels; `ship_vanguard_side.png` = 905×387 RGBA.

## Not reviewed / could not verify

- **Everything visual in a live editor.** No screenshot was taken: I ran headless only (the brief forbids `--headless --editor` because the editor holds the project) and did not drive the `godot-ai` session. Unverified: the settings tabs' real render, the rebind listen-mode interaction, the quit dialog's appearance, the cargo panel's open-state geometry (`_place_cargo_panel()` depends on laid-out rects and only runs when the panel opens), the reticle against a moving target, and whether the menu's breathing border reads as intended over the plate art (I only proved the ring is not occluded).
- **`hud.tscn` cargo panel placement** (`hud.gd:255-265`): the offsets are computed from `get_global_rect()` and are only re-evaluated on open, but the initial call in `_ready()` may read a zeroed layout. Not measurable headless; no defect claimed.
- **Audio**: no files exist under `assets/audio/**`, so every cue is the contracted silent no-op; nothing about bus routing could be heard or measured beyond the bus names existing at runtime (per the status doc's earlier evidence).
- **`DialogManager`'s confirm/message path** (NOTE 16) — no caller exists in Phase C, so it was reviewed by reading only.
- **No test suite** exists this phase (contract §0), so there are no unit assertions behind any of the above; every statement here comes from reading code, the three headless runs, the four probe measurements or the Pillow measurements.
- **`project.godot` provenance**: the workspace is not a git repository, so "no worker edited it" is verified only against `PROJECT_SETTINGS_PATCH.md`'s own scope and the patch's expected block, which match exactly.
