# Phase C re-review — 2026-09-17

Reviewer: W8 (independent). Method: read the contract, the W6 findings and the W7 claims; re-measured everything with (a) a temporary `res://tools/_probe.gd` (`extends SceneTree`, `quit()`-terminated, deleted afterwards — no `.uid` sidecar was ever created for it), (b) the four required headless runs, (c) the live editor through `godot-ai` (`project_run` + `game_eval` + `input_key`). No project file was edited; the only file written is this report. `user://settings.cfg` was read, driven through `ui_scale` 1.0 → 1.4 → 1.0 and left **byte-identical** to its pre-review state (sha256 `c251e58c6a3fa9a92b890f28abb098e56e42bb5a4b5919281c6e3e67d6c9dbf2`); no `inputs.cfg` was created; the game is stopped and no Godot process but the editor + helpers is running.

## Verdict

**CLEAN on all 10 fixes — every W7 claim reproduced independently, 0 BLOCKER, 0 MAJOR. 2 MINOR + 3 NOTE new findings, none of them reachable from shipped Phase C paths.**

The three MAJOR findings are genuinely fixed and were re-measured live, not taken on trust: the focus opener is now the menu button (was the overlay's own control), the minimap is player-centred (self blip at the disc centre at world (9000, 7000), where the old maths put it 299.3 px off a 84 px disc), and `ui_scale` moves real on-screen fonts (menu plate 34 → 48, version stamp 13 → 18, HUD `HullValue` 18 → 25, and back to base at 1.0 with no compounding). The three MAJOR/MINOR fix pairs that touched the theme (findings 3/9/NOTE 13/10) are consistent between `tools/build_theme.gd`, the regenerated `.tres` and `router.gd`'s list — recounted 21/21 in both directions, 0 uncovered. No regression surfaced in the areas the brief flagged: empty-stack pop, lower-entry pop, external pop + `DialogManager` recovery, the settings listen-mode branch, the main menu's Esc → quit dialog, the game → loading → main menu loop, and the reticle geometry in all three states.

## Fix verification (A)

| # | Fix | Verified? | Evidence |
|---|---|---|---|
| 1 | focus opener captured before `add_child` in `router.gd::push_overlay()` | **YES** | Code: `router.gd:119` (`var opener := _focus_weakref()`) now precedes `:120` (`_overlay_layer.add_child(instance)`) and is stored at `:124`. Live (main menu, `game_eval`): `before=/root/MainMenu/MenuButtons/OptionsButton/Button during=/root/Router/OverlayLayer/Settings/Panel/Margin/Layout/Tabs/GRAPHICS/ResolutionRow/ResolutionOption recorded_opener=/root/MainMenu/MenuButtons/OptionsButton/Button after=/root/MainMenu/MenuButtons/OptionsButton/Button depth=0`. W6 measured `ResolutionOption` and `<null>`; neither reproduces. |
| 2 | minimap player-centred (`_draw_blips()`, `_blip_origin()`) | **YES** | Code: `minimap.gd:96` `origin = _blip_origin()`, `:103` `offset = (world - origin) * unit`, `:104` the off-disc skip is `kind != KIND_SELF` only. Probe (168×168 view, radius 3200, self at (9000,7000)): `usable=84.0 unit=0.02625 origin=(9000.0, 7000.0) self_offset=(0.0, 0.0) contact_offset=(18.9, -11.025)(21.9 px) hostile_offset=(-30.975, 9.45)(32.4 px) contact drawn=true hostile drawn=true | old absolute self offset=299.3 px (usable 84.0)`. Live game, player teleported to (9000,7000): `origin=(9000.0, 7000.0) self_offset=(0.0, 0.0) usable=84.0 radius=3200.0 nearest_contact=21.88 blips=6 size=(168.0, 168.0)`. No-self fallback measured: `no-self origin=(0.0, 0.0)`. |
| 3 | `ui_scale` scales every font item (`FONT_SIZE_ITEMS`, `_scale_font_sizes()`, `build_theme.gd`) | **YES** | Recount by the **regenerated** theme: `theme default_font_size=14 font_size items=21`; `router list entries=21`; `coverage theme_not_in_router=0 router_not_in_theme=0`. Scaling: `scale 1.4: default=20 items=21 ratio min=1.375 max=1.429 items not grown=0`, `scaled back to 1.0: items differing from base=0 (default=14)`, `scale 1.4 samples: Label=20 ScreenTitle=31 MenuButtonPlate=48 SlotNumber=14 DialogTitle=25 RTL_bold=18`. Live, real code path (`SettingsManager.set_value` → `Router._on_setting_changed` → `_scale_font_sizes`), main menu: `version/play before=13/34 at1.4=18/48 restored=13/34 default_at_1.4=20 cfg_ui_scale=1.0`; game HUD: `HullValue/SectorLabel before=18/16 at1.4=25/22 restored=18/16 zone_theme_is_live=true`. No compounding across 1.4 → 1.0 → 1.4. |
| 4 | prints removed (`settings.gd`), `push_warning` gated (`game.gd`) | **YES** | `grep print(` over every project `.gd` (excluding vendored `addons/`): zero hits in `ui/`, `game/`, `autoload/`; the only hits are `tools/build_theme.gd` and `tools/derive_icon_tints.gd`, whose progress output is the contract's intended tool behaviour. `game.gd:225/229/233` are `push_warning` and sit inside the three "HUD unavailable" branches. Headless `res://ui/screens/settings.tscn`: silent, EXIT=0 (W6 saw `SettingsScreen: 15 rebind rows built` here). Clean `game.tscn` run printed none of the three warnings. |
| 5 | boot/loading colours come from tokens | **YES** | `grep Color(` over `ui/` returns only `vajb_theme.tres` (the generator's output) plus the pre-existing `Color(0,0,0,0)` crossfade/fade rects and `Color(1,1,1,0)`/`Color(1,1,1,0.4)` modulates; the boot Backdrop/Track/ProgressFill and the loading Backdrop literals are gone and those nodes have no `color` in the scene. Probe against the live scene instances: `boot %Backdrop color=(0.0275, 0.0353, 0.051, 1.0) token_void_base=(...) match=true`, `%Track` = `metal_dark` `match=true`, `%ProgressFill` = `metal_light` `match=true`, `loading Backdrop ... match=true`. All runs exit 0 with no warning. |
| 6 | `Hud.set_cargo_open()` + `cargo_toggle` wired in `game.gd` | **YES** | Code: `hud.gd:174-175` public setter → `_set_cargo_open`; `game.gd:52-60` includes it in the §3.10 API guard, `:76` state, `:102` call site, `:143-146` `_update_cargo_input()` → `set_cargo_open(not _cargo_open)`, `:257-259` `_on_cargo_toggled` records the state. Live (`input_key "C"`): `panel_visible=false game_cargo_open=false hud_cargo_open=false` → **1st C**: `panel_visible=true game_cargo_open=true hud_cargo_open=true` → **2nd C**: `panel_visible=false game_cargo_open=false hud_cargo_open=false`. No double-toggle, no feedback loop (the HUD emits `cargo_toggled` from the same call, the game only records it — it never calls back into `set_cargo_open`). |
| 7 | settings `ui_cancel` closes the overlay | **YES** | Code: `settings.gd:71-78` — the `_listening_row == null` branch consumes `ui_cancel` and emits `overlay_close_requested` **before** the listen branch. Live: overlay open at depth 1 → `input_key Escape` → `depth=0 focus=/root/MainMenu/MenuButtons/OptionsButton/Button overlay_children=[] scene=MainMenu` — the overlay closed and no quit dialog was pushed (two independent guards cover this: the settings handler consumes the event in `_input` via `_accept_event()`, and `main_menu.gd:59` returns early while `Router.overlay_depth() > 0`). Listen-mode branch: entered `_on_binding_pressed(thrust_forward, 0)` → `listening_row=true` → Escape → `depth=1 listening_row=false listening_action=` (listen cancelled, overlay **stayed open** — the key was not swallowed by the new branch) → second Escape → `depth=0 focus=.../OptionsButton/Button`. |
| 8 | HUD receives `Router.live_theme()` in `_instantiate_hud()` | **YES** | Code: `game.gd:237-239` (`add_child` then `instance.theme = Router.live_theme()`), with the reason comment. Live: `scene=Game hud=Hud hud_theme_is_live=true theme_id_match=true hud_has_set_cargo_open=true`; `hud.get_node("CanvasLayer/TopLeft").theme == Router.live_theme()` is `true`. Consequence verified: the HUD now follows `ui_scale` (row 3's HUD measurement). |
| 9 | `DialogTitle`/`Version` variations replace per-node overrides | **YES** | `grep theme_override_font_sizes` over the whole project: **zero** hits outside `addons/godot_ai/` (vendored); no `add_theme_font_size_override` in project code. Consumers: `dialog.tscn:53 theme_type_variation = &"DialogTitle"`, `main_menu.gd:36 _version_label.theme_type_variation = &"Version"`; theme has both (`DialogTitle` 18/`text_primary`, `Version` 13/`text_dim`). Live: `version_variation=Version font=13 color=(0.4196,0.4549,0.5176,1.0) text_dim=(same) color_match=true text=VAJB ORBIT v0.1`; quit dialog (main menu + Esc): `depth=1 children=["QuitConfirm"] focus=.../CancelButton title_variation=DialogTitle font=18 color_match_text_primary=true title=Quit Vajb Orbit?`. `main_menu.gd` no longer contains `VERSION_FONT_SIZE`, `_style_version_label` or `_token` (grep across `ui/screens/` finds `_token` only in `boot.gd`, `loading.gd`, `settings_rebind_row.gd`). The only remaining override in the HUD path is the sanctioned hull-bar `theme_override_styles/fill` (`hud.gd:305`), plus the pre-existing stylebox overrides W6 already accepted. |
| 10 | `SlotNumber` (10 px) replaces `SectionHeader` in `slot_button.tscn` | **YES** | `slot_button.tscn:35 theme_type_variation = &"SlotNumber"`; theme carries `SlotNumber` → Label, `font_size 10`, `font_color text_dim`. Live in the game: `weapon_cells=5 slot0_variation=SlotButtonWeapon number_text=1 number_visible=true number_font=10 number_variation=SlotNumber number_rect=[P: (3.0, 1.0), S: (8.0, 16.0)]` — the glyph really is 10 px in the corner rect (cargo cells send `number = 0`, so their number stays hidden). |
| 11 | reticle micro-bar container-laid, 60×4 | **YES** | `hud.tscn:350-365`: `ReticleBarBox` (VBoxContainer) at the measured rect with `ReticleHullBar` inside (`layout_mode = 2`, `custom_minimum_size = Vector2(60,4)`, `%ReticleHullBar` kept); `target_reticle.gd:13` now `$ReticleBarBox/ReticleHullBar`. Probe, three states: `hidden: box size=(60.0, 4.0) box pos=(-6.0, 50.0) bar size=(60.0, 4.0) bar pos=(0.0, 0.0) parent=ReticleBarBox` / `visible: box pos=(-6.0, 50.0) bar size=(60.0, 4.0)` / `targeted: box pos=(-6.0, 50.0) bar size=(60.0, 4.0) reticle pos=(376.0, 276.0) value=42.0`. Live game (mock target in range): `reticle_visible=true box_size=(60.0, 4.0) box_pos=(-6.0, 50.0) bar=true bar_size=(60.0, 4.0) bar_pos=(0.0, 0.0) bar_parent=ReticleBarBox value=26.1`, and `%ReticleHullBar` resolves from the reticle, so the unique name survived. |

## Regressions / new findings (B)

| # | Severity | File:line | Problem | Suggested fix |
|---|---|---|---|---|
| B1 | MINOR | `autoload/router.gd:248` (also `:257`, `:264`) | `_pop_entries()` assigns a dictionary entry straight into a typed local: `var node: Node = entry[&"node"]`. If the tracked overlay node has been freed with `free()` (not `queue_free()`), that assignment itself raises `Trying to assign invalid previously freed instance` — so the very next line's `is_instance_valid(node)` guard is unreachable for the case it was written for. Reproduced live, but **only by my synthetic test** (`node.free()` on a node the Router still tracked); no shipped path does this today (the router is the only owner and it `queue_free()`s at `:250`, `game.gd:235`'s `free()` is on a HUD that was never added to the tree, and `DialogManager` only ever calls `pop_overlay()`). The same latent shape is in `_find_overlay()`'s `return entry[&"node"]` and `_index_of()`'s comparison. | Read as a Variant and validate before typing, e.g. `var node: Variant = entry[&"node"]` then `if node != null and is_instance_valid(node) and node is Node:` before `queue_free()`; do the same in `_find_overlay()`/`_index_of()`. |
| B2 | MINOR | `ui/hud/minimap.gd:114` (new `_blip_origin()`; same shape pre-exists at `:98`) | New editor warning introduced by fix 2: `GDScript::reload: The local variable "position" is shadowing an already-declared property in the base class "Control"` (line 98 already warned before the fix, so the file is at least internally consistent). No behaviour impact — the local wins inside the loop. | Rename both locals to `blip_position` (or `world_position`) in `_draw_blips()` and `_blip_origin()`. |
| B3 | NOTE | `ui/screens/boot.gd:116-119` vs `ui/screens/loading.gd:90-93` | The two new `_token()` helpers disagree on the fallback: boot returns `Color.WHITE`, loading returns `Color.BLACK`. Before fix 5 the boot backdrop was a scene literal, so this now matters more: with a theme that cannot resolve `Tokens/void_base` the boot screen would paint **white** full-screen (and the track/fill white too) instead of the void colour. Not reachable in the shipped configuration — `boot.tscn:19` bakes the theme and the probe measured all four rects equal to their tokens — so this is a robustness/appearance-fallback asymmetry, not a defect. | Make boot's fallback non-luminous (e.g. `Color.BLACK`, or a dedicated `_token_or(&"void_base", Color.BLACK)`), matching loading. |
| B4 | NOTE | `tools/build_theme.gd:338` (`_report`) | The generator's report says `variations: 12`, but only 11 type variations are actually registered in the regenerated `.tres` — `MenuButton` is deliberately skipped by `NATIVE_CLASS_NAMES` (`:193-194`), and a scan of the `.tres` finds exactly 11 `base_type` entries. W7's report quotes the generator line verbatim, which reads as if 12 variations were registered. No functional consequence (the `MenuButton` *items* are still stored and still scaled). | Print declared vs registered counts, e.g. `variations: %d declared / %d registered`. |
| B5 | NOTE | `tools/` + `.godot/uid_cache.bin`, `.godot/editor/filesystem_update4` | The deleted probe left no file behind (`tools/` holds only `build_theme.gd` + `derive_icon_tints.gd` and their `.uid`s), but the editor's own caches still hold the string `_probe` after a `filesystem_manage(op="scan")`. These are engine cache binaries, not project files; nothing matches `tools/_*` on disk. | No action; noted so the next reader does not mistake the cache string for a leftover file. |

Nothing else surfaced. Specifically re-checked and clean: `route()` (boot → main_menu; game → loading → main_menu live, `busy=false` afterwards), `pop_overlay()` on an empty stack (`empty_pop=0`), `_pop_source` on the top entry (`after_source_pop=0`) and on a lower entry with a second overlay above it (`stacked=2 after_lower_pop=0`), `_find_overlay` for a missing route (`missing_null=true`), the `DialogManager` external-pop recovery (`dialog_depth=1 open_before=true depth_external=0 depth_after_recover=1 open_after_recover=true final=0` — the queue/unwind path W6's NOTE 16 could only read), a dialog stacked over the settings overlay (Escape closed only the dialog: `depth=1 order=["settings"] dialog_open=false`), `live_theme()` validity at `ui_scale = 1.0` (tokens and font sizes all resolve), `setting_changed` re-scaling, `_apply_scene_colors()` on `NOTIFICATION_THEME_CHANGED` (both files guard with `is_node_ready()` and call it explicitly from `_ready()`, so no pre-`@onready` call), `%ReticleHullBar` uniqueness, every `theme_type_variation` in the project resolving to a registered variation (`ScreenTitle`, `SectionHeader`, `HudReadout`, `HudHullBar`, `HudShieldBar`, `DialogTitle`, `Version`, `SlotNumber`, `MenuButtonPlate`, `SlotButtonWeapon`, `SlotButtonCargo`), the theme's 14 base styleboxes + all contracted wiring + 12 `Tokens` colours + `default_font_size 14` (nothing lost in the regeneration), and `%WeaponGrid`/`%HullBar` fill = `accent_danger`, `hud.modulate.a = 1.00` at `hud_opacity = 1.0`, cargo panel hidden by default.

## Runtime evidence (C)

All four required commands, run with the console binary and `--path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"`. Every one returned in a few seconds; nothing hung and nothing had to be killed.

```
1) ..._console.exe --headless --path <proj> --quit-after 240
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT1=0

2) ..._console.exe --headless --path <proj> res://ui/screens/main_menu.tscn --quit-after 300
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT2=0

3) ..._console.exe --headless --path <proj> res://game/game.tscn --quit-after 300
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT3=0

4) ..._console.exe --headless --path <proj> res://ui/screens/settings.tscn --quit-after 300
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT4=0
```

Nothing else was printed: no parse errors, no missing resources, no "Node not found", no orphan-node, layout or invalid-theme-item warnings, no GDScript reload errors in the run output. Run 4 is the one that used to print the rebind-row line; it is silent.

Reviewer probe, run as `..._console.exe --headless --path <proj> --script res://tools/_probe.gd` (`EXIT=0`; the two `PROBE theme ...` item blocks are condensed into one line each below — every other line is verbatim; the probe (and no `.uid` sidecar) was deleted before this report):

```
PROBE theme default_font_size=14 font_size items=21
PROBE   theme {Button/DialogTitle/HudReadout/Label/LineEdit/MenuButton/MenuButtonPlate/OptionButton/PopupMenu}/font_size=14|18|18|14|14|34|34|14|14
PROBE   theme RichTextLabel/{bold,bold_italics,italics,mono,normal}_font_size=13
PROBE   theme ScreenTitle/font_size=22 SectionHeader=16 SlotNumber=10 TabBar=14 TabContainer=14 TooltipLabel=13 Version=13
PROBE router list entries=21
PROBE coverage theme_not_in_router=0 router_not_in_theme=0
PROBE scaled back to 1.0: items differing from base=0 (default=14)
PROBE scale 1.4: default=20 items=21 ratio min=1.375 max=1.429 items not grown=0
PROBE scale 1.4 samples: Label=20 ScreenTitle=31 MenuButtonPlate=48 SlotNumber=14 DialogTitle=25 RTL_bold=18
PROBE minimap size=(168.0, 168.0) usable=84.0 unit=0.02625 origin=(9000.0, 7000.0)
PROBE minimap self_offset=(0.0, 0.0) contact_offset=(18.9, -11.025)(21.9 px) hostile_offset=(-30.975, 9.45)(32.4 px)
PROBE minimap contact drawn=true hostile drawn=true | old absolute self offset=299.3 px (usable 84.0)
PROBE minimap no-self origin=(0.0, 0.0)
PROBE boot %Backdrop color=(0.0275, 0.0353, 0.051, 1.0) token_void_base=(0.0275, 0.0353, 0.051, 1.0) match=true
PROBE boot %Track color=(0.1059, 0.1255, 0.1569, 1.0) token_metal_dark=(...) match=true
PROBE boot %ProgressFill color=(0.2392, 0.2745, 0.3294, 1.0) token_metal_light=(...) match=true
PROBE loading Backdrop color=(0.0275, 0.0353, 0.051, 1.0) match=true
PROBE reticle size=(48.0, 48.0) visible=false
PROBE reticle hidden: box size=(60.0, 4.0) box pos=(-6.0, 50.0) bar size=(60.0, 4.0) bar pos=(0.0, 0.0) parent=ReticleBarBox
PROBE reticle visible: box pos=(-6.0, 50.0) bar size=(60.0, 4.0) bar pos=(0.0, 0.0)
PROBE reticle targeted: box pos=(-6.0, 50.0) bar size=(60.0, 4.0) bar pos=(0.0, 0.0) reticle pos=(376.0, 276.0) value=42.0
PROBE done
```

Live editor evidence (`godot-ai`, tool results quoted verbatim; the last two lines are the file/hash checks I ran locally, not tool output; game left stopped):

```
main menu, focus opener + pop      : before=/root/MainMenu/MenuButtons/OptionsButton/Button during=/root/Router/OverlayLayer/Settings/Panel/Margin/Layout/Tabs/GRAPHICS/ResolutionRow/ResolutionOption recorded_opener=/root/MainMenu/MenuButtons/OptionsButton/Button after=/root/MainMenu/MenuButtons/OptionsButton/Button depth=0
settings Esc                       : depth=0 focus=/root/MainMenu/MenuButtons/OptionsButton/Button overlay_children=[] scene=MainMenu
settings listen mode + Esc, Esc    : listening_row=true  -> depth=1 listening_row=false listening_action=  -> depth=0 focus=.../OptionsButton/Button
main menu Esc -> quit dialog       : depth=1 children=["QuitConfirm"] focus=.../CancelButton title_variation=DialogTitle font=18 color_match_text_primary=true title="Quit Vajb Orbit?"
version stamp                      : version_variation=Version font=13 color_match_text_dim=true text=VAJB ORBIT v0.1
ui_scale live (menu)               : version/play before=13/34 at1.4=18/48 restored=13/34 default_at_1.4=20 cfg_ui_scale=1.0
ui_scale live (HUD)                : HullValue/SectorLabel before=18/16 at1.4=25/22 restored=18/16 zone_theme_is_live=true
game HUD theme                     : scene=Game hud=Hud hud_theme_is_live=true theme_id_match=true hud_has_set_cargo_open=true
game cargo toggle                  : false -> (C) panel_visible=true game_cargo_open=true hud_cargo_open=true -> (C) panel_visible=false game_cargo_open=false hud_cargo_open=false
game minimap after teleport        : player=(9000.0, 7000.0) origin=(9000.0, 7000.0) self_offset=(0.0, 0.0) usable=84.0 radius=3200.0 nearest_contact=21.88 blips=6 size=(168.0, 168.0) old_absolute_self=299.3
game reticle                       : reticle_visible=true box_size=(60.0, 4.0) box_pos=(-6.0, 50.0) bar=true bar_size=(60.0, 4.0) bar_pos=(0.0, 0.0) bar_parent=ReticleBarBox value=26.1
game weapon slot number            : weapon_cells=5 slot0_variation=SlotButtonWeapon number_text=1 number_visible=true number_font=10 number_variation=SlotNumber number_rect=[P: (3.0, 1.0), S: (8.0, 16.0)]
pop paths                          : empty_pop=0 d1=1 after_source_pop=0 stacked=2 after_lower_pop=0 missing_null=true busy=false
DialogManager external pop         : dialog_depth=1 open_before=true depth_external=0 depth_after_recover=1 open_after_recover=true final=0
dialog over settings + Esc         : depth=1 order=["settings"] dialog_open=false
game Esc -> loading -> main menu   : scene=MainMenu route=main_menu depth=0 busy=false focus=/root/MainMenu/MenuButtons/PlayButton/Button
settings.cfg after the review      : sha256 c251e58c...  baseline_match True  (ui_scale=1.0, hud_opacity=1.0, display_mode=1, resolution=Vector2i(2560, 1440)); inputs.cfg exists: False
exact theme after regeneration     : 21 font_size items, 11 registered variations, 14 base styleboxes, 12 Tokens colours, default_font_size 14
```

One `game_eval` snippet failed and parked the game in the debugger: the B1 test's `node.free()` + `pop_overlay()` raised `EVAL_RUNTIME_ERROR: Trying to assign invalid previously freed instance. (res://autoload/router.gd:248 @ _pop_entries)` and `editor_state` reported `game_status.status = "break"`. I stopped the game (`project_manage(op="stop")`, `readiness_after: ready`), did not repeat that snippet, and re-measured the pop paths afterwards with a version that addresses nodes through `Router._overlays` instead of freeing anything (the `pop paths` line above).

## Not verified / could not verify

- **No pixels.** I took no screenshot and captured no frame; every colour, size and rect above is a value-level measurement (theme lookups, `get_theme_font_size`, `get_rect`, `color` comparisons) or a clean-load result. Not visually confirmed: the boot/loading palette as rendered, the 10 px slot glyph as rendered, the reticle in motion, the rebind listen-mode "PRESS KEY…" text, and the minimap as drawn (I measured the maths and the live blip set, not the RID draw commands).
- **The first frame of boot/loading.** `_ready()` sets the backdrop/track/fill colours before the first draw, and the measured values are correct, but I did not capture a frame to prove there is no one-frame white (the `ColorRect` default) flash after the scene literals were removed.
- **`ui_scale` outside the editor's debug build.** Driven through `SettingsManager` in the editor-launched game; no export was built, so release-path behaviour is untested.
- **Audio.** Still the contracted silent no-op (no files under `assets/audio/**`); nothing measurable beyond the buses existing.
- **B1's reachability.** I could not construct a shipped path that frees an overlay with `free()`; the finding is reported as a latent robustness gap, evidenced only by a synthetic test, and is explicitly labelled as such.
- **`project.godot` provenance.** Not a git repository, so "no worker edited it" remains checkable only against `PROJECT_SETTINGS_PATCH.md`; I did not edit it and the runs are consistent with the patched state.
- **Two `_input` handlers with `ui_cancel` (settings + dialog)** were measured only in the one stacking order I could create (dialog above settings) — that order behaves correctly (the top overlay consumes the event); no other stacking combination exists in Phase C.
