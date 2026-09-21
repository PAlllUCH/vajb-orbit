# D3 report: theme extension + music/ambience API

Worker: **coder** (D3). Date: 2026-09-18. Workspace: `G:/Mój dysk/Projekty/Vajb Orbit`.
Engine: Godot 4.7.2 console binary, headless only. The open editor (PID 9048) was never touched;
`--headless --editor` was never run; `project.godot` and `addons/` were not modified.

Deliverables: `docs/design/THEME_AUDIO_EXTENSION.md` (written before the code), the theme extension in
`tools/build_theme.gd`, the regenerated `ui/theme/vajb_theme.tres`, the `Router.FONT_SIZE_ITEMS` sync, and
the music/ambience API in `autoload/audio_manager.gd`.

---

## 1. Files changed

| Action | Path | Before | After | Lines after |
|---|---|---|---|---|
| edit | `vajb-orbit/tools/build_theme.gd` | 13543 bytes | 17994 bytes | 431 |
| regenerate | `vajb-orbit/ui/theme/vajb_theme.tres` | 18190 bytes, sha256 `D254EEFB...EAD9CCD` | 24314 bytes, sha256 `DE2C3713...0EC3AF78` | 545 |
| edit | `vajb-orbit/autoload/router.gd` | 10520 bytes | 10993 bytes | 340 (+6, the 6 new list entries and their comment line) |
| edit | `vajb-orbit/autoload/audio_manager.gd` | 3655 bytes | 7316 bytes | 251 |
| create | `docs/design/THEME_AUDIO_EXTENSION.md` | - | 18457 bytes | 280 |
| create | `.agents/gen/d3_report.md` | - | - | this file |

`tools/build_theme.gd` structural change: `PANEL_FRAME_PATH`, `PANEL_FRAME_MARGIN`, `FRAME_EXPAND_MARGIN`,
`SCROLL_CONTENT_MARGIN` constants; `MENU_PLATE_VARIATIONS` replaced by `PLATE_VARIATIONS` (name to font
size); `_register_menu_button()` generalised into `_register_plate_variations()`; new `_register_chrome()`,
`_register_scroll_chrome()`, `_register_list_chrome()`, `_panel_frame_box()`, `_scroll_box()`;
`LABEL_VARIATIONS`/`VARIATION_BASE` extended; four new label font colours; `_make_boxes()` gains
`panel_frame`. No function was removed without its replacement, and `_report()` is unchanged, so its output
is directly comparable run to run.

`autoload/audio_manager.gd` structural change: 4 new constants and 8 new vars; `MusicPlayer` and
`AmbiencePlayer` created in `_ready()` next to the existing players; the six briefed public methods; helpers
`_crossfade()`, `_start_stream()`, `_fade_out()`, `_bus_target_db()`, `_set_loop()`,
`_kill_music_tween()`, `_kill_ambience_tween()`. `play_ui`, `play_sfx`, `set_bus_linear`, `bus_linear`,
`_play`, `_load_cue`, `_build_buses`, `_ensure_bus`, `_apply_settings_volumes`, `_make_player`, `_service`
are byte-identical to before.

## 2. Deviations from the brief (each with the reason)

1. **Probe filename.** The brief names `res://tools/_probe.gd`. That path was **owned by the parallel D2
   worker at the time** (verified: `tools/_probe.gd`, 14347 bytes, mtime `18.09.2026 01:59:42`, no `.uid`,
   and its size changed between two reads while I was reading `paths.gd`). I used
   `res://tools/_probe_d3.gd` instead, and two extra throwaway probes for leak/behaviour attribution
   (`_probe_min.gd`, `_probe_pre.gd`). All three were deleted; see section 7.
2. **`FONT_SIZE_ITEMS` count is 27, not 26.** The brief budgets five new font-size items; the brief's own
   `ItemList` spec (`panel`, `font_size` 14, ...) is a sixth, because `ItemList` is a `Control` that asks
   the theme for its own `font_size`. Registering it in the theme but not in the router list would leave
   station list rows ignoring `ui_scale`, which is the failure the list exists to prevent. Measured:
   theme items 27, router entries 27, missing in either direction 0.
3. **`panel_frame` border convention.** `StyleBoxTexture` has no `border_width_*` / `border_color`. The 1 px
   theme border is expressed as `expand_margin_* = 1.0` and `modulate_color` is left white so the frame's
   own painted `#2A2E35` steel border is not double-darkened. Measured in the probe:
   `margins=32/32/32/32 expand=1/1/1/1`.
4. **`PanelRaised` is registered twice.** The briefed `PanelContainer/styles/panel_raised` is present, but a
   `PanelContainer` asks the theme for the item named `panel`; only `PanelRaised/styles/panel` makes the
   framed panel actually render. Measured through a live `PanelContainer` node with
   `theme_type_variation = &"PanelRaised"`: the resolved `panel` stylebox is a `StyleBoxTexture` over
   `res://assets/ui/ui_panel_frame.png`.
5. **Colour supersets on the two list controls.** Beyond the briefed items: `ItemList`
   (`font_selected_color`, `font_hovered_color`, `font_disabled_color`) and `Tree` (`font_color`,
   `font_selected_color`, `font_disabled_color`, `title_button_color`). A stylebox-only registration still
   leaves engine-default *text* on the widgets the brief says must not fall back to engine defaults. No
   extra font-size item was added this way, so the arithmetic in item 2 is unaffected.
6. **`VScrollBar/grabber_highlight` token mapping.** The brief names `metal_mid`/`metal_light`/
   `accent_danger`; the accent is used as the 1 px **border on the hovered grabber**, not as a fill, to keep
   `UI_SPEC.md` section 1's reservation of orange for damage, alerts and armed weapons.
7. **The probe changes `ui_scale` without writing `user://settings.cfg`.** `SettingsManager.set_value()`
   schedules a debounced write, so the probe writes the live `ConfigFile` through
   `settings.get(&"_config")` instead and restores the original value; `_dirty` is never set, so
   `flush()` on exit writes nothing. Measured: `settings.cfg` sha256 identical before and after (section 8).

## 3. Theme inventory, before and after

### 3.1 Per-type font-size items (the `FONT_SIZE_ITEMS` universe)

Before: **21**. After: **27**. Every before item is still present, unchanged.

| Type / item | Before | After |
|---|---|---|
| `Button/font_size` | 14 | 14 |
| `DialogTitle/font_size` | 18 | 18 |
| `HeroTitle/font_size` | - | **48** |
| `HudReadout/font_size` | 18 | 18 |
| `ItemList/font_size` | - | **14** |
| `Label/font_size` | 14 | 14 |
| `LineEdit/font_size` | 14 | 14 |
| `MenuButton/font_size` | 34 | 34 |
| `MenuButtonPlate/font_size` | 34 | 34 |
| `OptionButton/font_size` | 14 | 14 |
| `PopupMenu/font_size` | 14 | 14 |
| `RichTextLabel/bold_font_size` | 13 | 13 |
| `RichTextLabel/bold_italics_font_size` | 13 | 13 |
| `RichTextLabel/italics_font_size` | 13 | 13 |
| `RichTextLabel/mono_font_size` | 13 | 13 |
| `RichTextLabel/normal_font_size` | 13 | 13 |
| `ScreenTitle/font_size` | 22 | 22 |
| `SectionHeader/font_size` | 16 | 16 |
| `SlotNumber/font_size` | 10 | 10 |
| `StationButton/font_size` | - | **22** |
| `StationCaption/font_size` | - | **13** |
| `StationPanelTitle/font_size` | - | **20** |
| `StationValue/font_size` | - | **18** |
| `TabBar/font_size` | 14 | 14 |
| `TabContainer/font_size` | 14 | 14 |
| `TooltipLabel/font_size` | 13 | 13 |
| `Version/font_size` | 13 | 13 |

### 3.2 Styleboxes by type (generator report, verbatim item names)

| Type | Before | After |
|---|---|---|
| `<base>` | 14: panel, panel_raised, button_normal, button_hover, button_pressed, button_disabled, progress_bg, progress_fill, focus, lineedit, lineedit_focus, slider_groove, slider_grabber, tooltip_panel | 15: the same 14 + **panel_frame** |
| `PanelContainer` | 1: panel | 2: panel + **panel_raised** |
| `Panel` | 1: panel | 1 (unchanged) |
| `PopupPanel` | 1: panel | 1 (unchanged) |
| `PopupMenu` | 2: panel, hover | 2 (unchanged) |
| `TabContainer` | 7 | 7 (unchanged) |
| `Button` | 5: normal, hover, pressed, disabled, focus | 5 (unchanged) |
| `LineEdit` | 2 | 2 (unchanged) |
| `Slider` | 3 | 3 (unchanged) |
| `ProgressBar` | 2 | 2 (unchanged) |
| `TooltipPanel` | 1 | 1 (unchanged) |
| `MenuButton` | 6 | 6 (unchanged) |
| `MenuButtonPlate` | 6 | 6 (unchanged) |
| `StationButton` | - | **6: normal, hover, pressed, disabled, hover_pressed, focus** |
| `HudHullBar` | 2 | 2 (unchanged) |
| `HudShieldBar` | 2 | 2 (unchanged) |
| `SlotButtonWeapon` | 4 | 4 (unchanged) |
| `SlotButtonCargo` | 4 | 4 (unchanged) |
| `PanelRaised` | - | **1: panel** |
| `ScrollContainer` | - | **1: panel** |
| `VScrollBar` | - | **3: scroll, grabber, grabber_highlight** |
| `ItemList` | - | **4: panel, hovered, selected, cursor** |
| `Tree` | - | **7: panel, title_button_normal, title_button_hover, title_button_pressed, title_button_disabled, selected, cursor** |
| **stylebox types** | **17** | **23** |
| **variations (report)** | **12** | **18** |

### 3.3 Variations

Before (12, report order): ScreenTitle, SectionHeader, HudReadout, DialogTitle, Version, SlotNumber,
MenuButton, MenuButtonPlate, HudHullBar, HudShieldBar, SlotButtonWeapon, SlotButtonCargo.

After (18): the same 12 plus **HeroTitle, StationPanelTitle, StationValue, StationCaption, StationButton,
PanelRaised**.

`base_type` entries serialised in the `.tres`: **11 before, 17 after** (11 pre-existing + HeroTitle,
StationPanelTitle, StationValue, StationCaption, StationButton, PanelRaised; `MenuButton` is absent by
design because it is a built-in class name). `Tokens` colours unchanged at 12, and no token value changed.

## 4. Commands run and exit codes

| # | Command | Exit | Notes |
|---|---|---|---|
| 1 | `..._console.exe --headless --path <proj> --script res://tools/build_theme.gd` (before any edit) | 0 | Baseline: 21 font-size items, 17 stylebox types, 12 variations, 11 `base_type`; `.tres` sha256 `D254EEFB...EAD9CCD` identical before and after this run, which is the determinism check on the pre-existing generator |
| 2 | `..._console.exe --headless --path <proj> --script res://tools/build_theme.gd` (after the theme edits) | 0 | 27 font-size items, 23 stylebox types, 18 variations; no `missing texture` line |
| 3 | `..._console.exe --headless --path <proj> --script res://tools/build_theme.gd --quit-after 2` (determinism re-run) | 0 | `.tres` sha256 `DE2C3713...0EC3AF78` identical before and after the re-run |
| 4 | `..._console.exe --headless --path <proj> --script res://tools/_probe_d3.gd` | 0 | One parse-error run (exit 1) first, fixed; the successful run is transcribed in section 5 |
| 5 | `..._console.exe --headless --path <proj> res://ui/screens/main_menu.tscn --quit-after 300` | 0 | stdout: engine banner + `[godot_ai game_helper] registered mcp capture` only |
| 6 | same, `res://ui/screens/settings.tscn` | 0 | as above |
| 7 | same, `res://game/game.tscn` | 0 | as above |
| 8 | same, `res://ui/hud/hud.tscn` | 0 | as above |
| 9 | `..._console.exe --headless --path <proj> --script res://tools/_probe_min.gd` (a bare probe with no audio) | 0 | No exit warnings at all, so `--script` teardown leaks nothing by itself |
| 10 | same probe with `play_music(&"mus_menu_theme_01", 0.0)`, quit | 0 | 4 leaked objects / 2 resources at exit (section 5 stderr) |
| 11 | same probe with `play_sfx(&"sfx_weapon_laser_01")` instead, quit | 0 | Identical 4 / 2 exit warnings on the pre-existing path, which attributes them to playback-at-exit, not to the music code |
| 12 | `..._console.exe --headless --path <proj> --script res://tools/_probe_pre.gd` | 0 | Pre-`_ready()` cue calls, see section 9 |

No run produced a script error except the two deliberate attribution probes (runs 10 and 11, section 9) and
the first, malformed `_probe_d3.gd` attempt (a `StringName` passed to `get_node_or_null()`, fixed by
wrapping in `NodePath()`).

## 5. Probe output (verbatim)

`"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_d3.gd`

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[probe] --- theme inventory ---
[probe] font_size Button/font_size = 14
[probe] font_size DialogTitle/font_size = 18
[probe] font_size HeroTitle/font_size = 48
[probe] font_size HudReadout/font_size = 18
[probe] font_size ItemList/font_size = 14
[probe] font_size Label/font_size = 14
[probe] font_size LineEdit/font_size = 14
[probe] font_size MenuButton/font_size = 34
[probe] font_size MenuButtonPlate/font_size = 34
[probe] font_size OptionButton/font_size = 14
[probe] font_size PopupMenu/font_size = 14
[probe] font_size RichTextLabel/bold_font_size = 13
[probe] font_size RichTextLabel/bold_italics_font_size = 13
[probe] font_size RichTextLabel/italics_font_size = 13
[probe] font_size RichTextLabel/mono_font_size = 13
[probe] font_size RichTextLabel/normal_font_size = 13
[probe] font_size ScreenTitle/font_size = 22
[probe] font_size SectionHeader/font_size = 16
[probe] font_size SlotNumber/font_size = 10
[probe] font_size StationButton/font_size = 22
[probe] font_size StationCaption/font_size = 13
[probe] font_size StationPanelTitle/font_size = 20
[probe] font_size StationValue/font_size = 18
[probe] font_size TabBar/font_size = 14
[probe] font_size TabContainer/font_size = 14
[probe] font_size TooltipLabel/font_size = 13
[probe] font_size Version/font_size = 13
[probe] font_size_items=27
[probe] variations=17 [DialogTitle->Label, HeroTitle->Label, HudHullBar->ProgressBar, HudReadout->Label, HudShieldBar->ProgressBar, MenuButtonPlate->Button, PanelRaised->PanelContainer, ScreenTitle->Label, SectionHeader->Label, SlotButtonCargo->TextureButton, SlotButtonWeapon->TextureButton, SlotNumber->Label, StationButton->Button, StationCaption->Label, StationPanelTitle->Label, StationValue->Label, Version->Label]
[probe] variation HeroTitle base=Label registered=true
[probe] variation StationButton base=Button registered=true
[probe] variation StationPanelTitle base=Label registered=true
[probe] variation StationValue base=Label registered=true
[probe] variation StationCaption base=Label registered=true
[probe] variation PanelRaised base=PanelContainer registered=true
[probe] stylebox /panel_frame present=true
[probe] stylebox PanelContainer/panel_raised present=true
[probe] stylebox PanelRaised/panel present=true
[probe] stylebox ScrollContainer/panel present=true
[probe] stylebox VScrollBar/scroll present=true
[probe] stylebox VScrollBar/grabber present=true
[probe] stylebox VScrollBar/grabber_highlight present=true
[probe] stylebox ItemList/panel present=true
[probe] stylebox ItemList/selected present=true
[probe] stylebox ItemList/hovered present=true
[probe] stylebox ItemList/cursor present=true
[probe] stylebox Tree/panel present=true
[probe] stylebox Tree/title_button_normal present=true
[probe] stylebox Tree/title_button_hover present=true
[probe] stylebox Tree/title_button_pressed present=true
[probe] stylebox Tree/title_button_disabled present=true
[probe] stylebox Tree/selected present=true
[probe] stylebox Tree/cursor present=true
[probe] stylebox_types=23 base_styleboxes=15
[probe] --- PanelRaised resolution ---
[probe] PanelRaised/panel is StyleBoxTexture texture=res://assets/ui/ui_panel_frame.png margins=32/32/32/32 expand=1/1/1/1
[probe] --- ui_scale ---
[probe] router_items=27 theme_items=27
[probe] missing_from_router=0 missing_from_theme=0
[probe] ui_scale=1.00 HeroTitle/font_size=48
[probe] ui_scale=1.00 StationButton/font_size=22
[probe] ui_scale=1.00 StationPanelTitle/font_size=20
[probe] ui_scale=1.00 StationValue/font_size=18
[probe] ui_scale=1.00 StationCaption/font_size=13
[probe] ui_scale=1.00 ItemList/font_size=14
[probe] requested_scale=1.40 default_font_size=20 router_requested_scale=1.40 base_font_size=14 live_cache_same=true
[probe] ui_scale=1.40 HeroTitle/font_size=67
[probe] ui_scale=1.40 StationButton/font_size=31
[probe] ui_scale=1.40 StationPanelTitle/font_size=28
[probe] ui_scale=1.40 StationValue/font_size=25
[probe] ui_scale=1.40 StationCaption/font_size=18
[probe] ui_scale=1.40 ItemList/font_size=20
[probe] restored_scale=1.00 default_font_size=14 drift_vs_first_pass=0 differs_from_source=0 scaled_sample=HeroTitle=67
[probe] --- audio ---
[probe] AUDIO_DIRS music=res://assets/audio/music/ ambience=res://assets/audio/ambience/ ambience_key_present=true
[probe] players_by_bus={ "UI": 1, "SFX": 5, "Music": 1 }
[probe] MusicPlayer=true AmbiencePlayer=true
[probe] play_music(cue_that_does_not_exist) -> current_music()='' (silent no-op expected)
[probe] play_music(mus_menu_theme_01) -> current_music()='mus_menu_theme_01'
[probe] music bus=Music playing=true volume_db=0.00 stream=res://assets/audio/music/mus_menu_theme_01.ogg length=205.228 loop=true
[probe] file_on_disk=true resolved_in_dir=true
[probe] play_music(same track, fade 1.0) -> stream_unchanged=true volume_unchanged=true
[probe] crossfade to mus_combat_loop_01 after 0.70 s of a 1.0 s fade ->
[probe] music mid-crossfade bus=Music playing=true volume_db=-49.10 stream=res://assets/audio/music/mus_combat_loop_01.ogg length=24.765 loop=true
[probe] stop_music(0.0) -> current_music()='' playing=false
[probe] muted Music bus (linear 0.0) ->
[probe] music muted-bus bus=Music playing=true volume_db=-80.00 stream=res://assets/audio/music/mus_menu_theme_01.ogg length=205.228 loop=true
[probe] Music bus restored to linear=1.0000
[probe] play_ambience(cue_that_does_not_exist) -> current_ambience()='' (silent no-op expected)
[probe] play_ambience(amb_space_drone_01) -> current_ambience()='amb_space_drone_01'
[probe] ambience bus=SFX playing=true volume_db=0.00 stream=res://assets/audio/ambience/amb_space_drone_01.ogg length=223.520 loop=true
[probe] file_on_disk=true resolved_in_dir=true
[probe] stop_ambience(0.0) -> current_ambience()='' playing=false
EXIT_CODE=0
```

Trailing stderr from the same run (also present, with identical counts, in the pre-existing `play_sfx`
attribution run, so it is not introduced by this change):

```
WARNING: 4 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
ERROR: 2 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
```

Reading of the numbers:

- `font_size_items=27` and the per-type dump match section 3.1 exactly.
- `variations=17` is the `.tres` count (18 registered minus `MenuButton`, which cannot be a variation), and
  every one of the six new names resolves with `registered=true`.
- All 18 new stylebox items are present, including the briefed `PanelContainer/panel_raised`.
- `ui_scale` reaches every new item: at 1.4 `HeroTitle` 48 -> 67, `StationButton` 22 -> 31,
  `StationPanelTitle` 20 -> 28, `StationValue` 18 -> 25, `StationCaption` 13 -> 18, `ItemList` 14 -> 20,
  and `default_font_size` 14 -> 20. Back at 1.0, `drift_vs_first_pass=0` and `differs_from_source=0`.
- Audio: the cue resolver finds the real file (path, length 205.228 s for the menu theme, 223.520 s for the
  space drone, both `loop=true` after `_set_loop`), the same-track call is a no-op (stream object id and
  volume unchanged), the crossfade to `mus_combat_loop_01` has already swapped the stream and is rising from
  -80 dB at 0.70 s of a 1.0 s fade, a muted `Music` bus parks the player at `volume_db=-80.00` while still
  playing rather than raising, and both missing-cue calls leave `current_music()`/`current_ambience()` empty.

## 6. Headless scene runs

| Scene | Exit | stdout beyond the engine banner |
|---|---|---|
| `res://ui/screens/main_menu.tscn` | 0 | `[godot_ai game_helper] registered mcp capture` |
| `res://ui/screens/settings.tscn` | 0 | same |
| `res://game/game.tscn` | 0 | same |
| `res://ui/hud/hud.tscn` | 0 | same |

No parse errors, no runtime errors, no warnings. These runs also load the regenerated
`ui/theme/vajb_theme.tres` (every screen root bakes it), so the new `.tres` is loadable by the engine and
not only by the probe.

## 7. `tools/` final state

```
build_theme.gd            17994   18.09.2026 02:01:32
derive_icon_tints.gd       3575   17.09.2026 21:27:34
build_theme.gd.uid           20   17.09.2026 21:31:25
derive_icon_tints.gd.uid     20   17.09.2026 21:31:25
```

Exactly the two generators and their `.uid` files, as required. My three throwaway probes
(`_probe_d3.gd`, `_probe_min.gd`, `_probe_pre.gd`) were deleted; none of them ever produced a `.uid`
sidecar. D2's `tools/_probe.gd`, which existed when I started, is also gone now (D2's own cleanup, not
mine).

## 8. `user://settings.cfg` evidence

`C:\Users\Kamil\AppData\Roaming\Godot\app_userdata\Vajb Orbit\settings.cfg`

| | Value |
|---|---|
| sha256 before | `C251E58C6A3FA9A92B890F28ABB098E56E42BB5A4B5919281C6E3E67D6C9DBF2` |
| sha256 after (after all runs listed above) | `C251E58C6A3FA9A92B890F28ABB098E56E42BB5A4B5919281C6E3E67D6C9DBF2` |
| LastWriteTime before | `18.09.2026 01:02:06` |
| LastWriteTime after | `18.09.2026 01:02:06` |
| Length | 102 bytes, both times |

Byte-identical and not even rewritten: the probe mutates the in-memory `ConfigFile` only, and
`SettingsManager.flush()` returns early because `_dirty` is never set.

Regenerated theme hash for the record: `ui/theme/vajb_theme.tres` sha256
`DE2C3713E16CBDA60BB8DD03B8BC41007994FC355ABAF0B149E4E9DC0EC3AF78` (stable across a repeat generator run).

## 9. Verified, and what was not

Verified by measurement:

- Theme item inventory, the six new variations, the 18 new stylebox items, 27 font-size items, 23 stylebox
  types, 17 `base_type` entries, and the absence of any removal (section 3).
- `ui_scale` reaches all six new font-size items and the round trip back to 1.0 is exact.
- `PanelRaised` resolves to the `ui_panel_frame.png` nine-patch with 32 px texture margins and 1 px expand
  margins, through a real `PanelContainer`, not through the theme API alone.
- Audio: cue resolution against `Paths.AUDIO_DIRS` (both keys present now that D2 landed `&"ambience"`), the
  resolved paths are the real files under `assets/audio/`, `loop=true` on both, same-track no-op, crossfade
  swap, muted-bus silence, missing-cue no-ops, and the stop paths.
- Exit 0 and clean stdout for all four scenes, plus the three generator runs and the probe.
- First attempt had to be fixed: `get_node_or_null(&"Name")` is a parse error in Godot 4.7.2 (`StringName`
  is not implicitly a `NodePath` in a call argument); the probe wraps them in `NodePath()`. `project.godot`
  scripts already do this, so no product code changed.

Not verified:

- **Visual appearance.** No screenshot was taken (the editor was left alone), and no shipped scene consumes
  the new items yet, so the chrome is proven correct by item values, not by pixels. The station screen is
  the first consumer.
- **`VScrollBar` pressed/focus states.** `grabber_pressed` and `scroll_focus` are deliberately not
  registered (not in the brief's item list), so they still fall back to the engine default theme. Recorded
  in the extension doc as a follow-up.
- **`Tree` font size.** Deliberately not registered (the brief names no Tree font-size item), so Tree text
  uses the engine default 16 px and does not follow `ui_scale`. Recorded as a follow-up; the fix is one
  `set_font_size` plus one router entry.
- **Screen-reader / asset wiring.** Nothing calls `play_music`/`play_ambience` yet; the API is measured
  directly, not through a screen.

Observed but deliberately not changed:

- **Pre-`_ready()` cue calls fail, as they already did.** `play_music` before `AudioManager._ready()` errors
  at `audio_manager.gd:196` (`_crossfade`), and the pre-existing `play_sfx`/`play_ui` error the same way
  (`_play` line 172 out-of-bounds on the empty SFX pool, line 169 null player for UI). Measured with
  `_probe_pre.gd`: `AudioManager=true children=0`, then both existing calls error. Autoload order guarantees
  `_ready()` runs before any scene, so this is not reachable in game; I left the new methods consistent with
  the existing ones rather than adding guards that only my methods have.
- **The `Music` bus sits at 0 dB, not the AUDIO_SPEC level.** `_apply_settings_volumes()` passes
  `default = 1.0` into `SettingsManager.get_value(&"audio", key, 1.0)`, and that default wins over
  `SettingsManager._defaults` (`db_to_linear(-8)` for music), so `bus_linear(&"Music")` is 1.0 until the
  user moves the slider. That is why the probe's unmuted music target is `volume_db=0.00`. Pre-existing
  Phase C behaviour, outside this brief (`set_bus_linear`/`bus_linear` semantics are frozen), so it is
  reported rather than changed.
- **Music level is attenuated twice** (once on the player, once on the `Music` bus), because the briefed
  fade target is the value the bus linear volume implies. Documented in the extension doc section 4 with the
  one-line alternative (`_bus_target_db()` returning `0.0`).
- **`--script` runs leak at exit once a cue plays** (4 objects, 2 resources). Measured identical counts for
  the pre-existing `play_sfx` path, and a bare probe (`--script` with no audio) leaks nothing, so it is a
  property of playing an `AudioStreamPlayer` at process exit in this environment, not of the music code.
  The four scene runs print no such warning.
