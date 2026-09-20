# Theme and audio extension (D3)

**Status:** written 2026-09-18 before the code, as the workspace rule requires (docs, then code, then tests).
**Scope:** the station/hero theme items the generated theme was missing, the list and scroll chrome a station
list needs, and the music/ambience half of `AudioManager` (93 of the 95 shipped audio files were unreachable
because only `play_ui` / `play_sfx` existed).

**Files this document governs**

| Action | Path |
|---|---|
| edit | `vajb-orbit/tools/build_theme.gd` (the generator; the theme is generated, never hand-edited) |
| regenerate | `vajb-orbit/ui/theme/vajb_theme.tres` (only by running the generator) |
| edit | `vajb-orbit/autoload/router.gd` (the `FONT_SIZE_ITEMS` list only) |
| edit | `vajb-orbit/autoload/audio_manager.gd` |
| create | this file |

Nothing in `project.godot`, `addons/`, `ui/paths.gd`, `autoload/player_profile.gd`, `game/station_catalog.gd`,
`ui/screens/*`, `ui/components/*`, `ui/hud/*` or `IMPLEMENTATION_PLAN.md` is touched.

---

## 1. Why the theme is being extended

`IMPLEMENTATION_PLAN.md` section 3.2 freezes the theme as *generated* by `tools/build_theme.gd`, and the
theme as of Phase C carries the menu, HUD and settings vocabulary only (12 variations, 21 per-type font-size
items). The next two screens (station hub, menu v2) need a larger title, a 22 px plate button, station panel
labels, and list/scroll chrome; without them every `Label`, `Button`, `ItemList` and `Tree` in those screens
falls back either to the 14 px body size or to Godot's engine default theme (16 px, engine greys), which is
exactly the class of failure the frozen `FONT_SIZE_ITEMS` rule exists to prevent.

The generator keeps every hex literal in the project; all new values below are read from the existing
`Tokens` dictionary, and no new token is introduced.

## 2. Theme items added

### 2.1 New type variations (6)

| Variation | Base type | Items | Registered by |
|---|---|---|---|
| `HeroTitle` | `Label` | `font_size` 48, `font_color` `text_primary` | `LABEL_VARIATIONS` + `VARIATION_BASE` |
| `StationPanelTitle` | `Label` | `font_size` 20, `font_color` `text_primary` | `LABEL_VARIATIONS` + `VARIATION_BASE` |
| `StationValue` | `Label` | `font_size` 18, `font_color` `text_primary` | `LABEL_VARIATIONS` + `VARIATION_BASE` |
| `StationCaption` | `Label` | `font_size` 13, `font_color` `text_dim` | `LABEL_VARIATIONS` + `VARIATION_BASE` |
| `StationButton` | `Button` | `font_size` 22 plus the five plate styleboxes below, and the same font colours as `MenuButtonPlate` | `PLATE_VARIATIONS` + `VARIATION_BASE` |
| `PanelRaised` | `PanelContainer` | `panel` = `panel_frame` (see 2.3) | `VARIATION_BASE` + `_register_chrome()` |

`StationButton` is a `Button` variation, not a plate re-implementation: `_register_menu_button()` is
generalised into `_register_plate_variations(theme)`, which builds the plate dictionary **once** and loops a
`Dictionary` of variation name to font size (`MenuButton` 34, `MenuButtonPlate` 34, `StationButton` 22). One
code path, three variations, no duplicated shapes. `MenuButton` stays in that map (it is a built-in class
name, so `set_type_variation` refuses it and it is listed in `NATIVE_CLASS_NAMES`; its items still theme a
native `MenuButton` node).

### 2.2 `StationButton` plate styleboxes

Built by the shared `PLATE_PATH` template `res://assets/ui/ui_button_plate_%s.png`, exactly as
`MenuButtonPlate` is today:

| Item | Asset |
|---|---|
| `normal` | `ui_button_plate_normal.png` |
| `hover` | `ui_button_plate_hover.png` |
| `pressed` | `ui_button_plate_pressed.png` |
| `disabled` | `ui_button_plate_disabled.png` |
| `hover_pressed` | alias of `pressed` (same `StyleBoxTexture` instance) |
| `focus` | the shared `focus` `StyleBoxFlat`: 1 px `accent_danger_bright`, no centre fill |

Font colours on the variation: `font_color`, `font_hover_color`, `font_pressed_color`, `font_focus_color`
= `text_primary`; `font_disabled_color` = `text_dim`; `font_size` 22.

### 2.3 Panel chrome

| Item | Type | Value |
|---|---|---|
| `panel_frame` (base item, empty type) | `StyleBoxTexture` | texture `res://assets/ui/ui_panel_frame.png`; `texture_margin_left/top/right/bottom = 32` (the measured 32 px frame of a 96x96 source, `UI_SPEC.md` section 5.3); `expand_margin_* = 1.0` |
| `PanelContainer / panel_raised` | `StyleBoxTexture` | the same `panel_frame` instance |
| `PanelRaised / panel` | `StyleBoxTexture` | the same `panel_frame` instance |

**Two registrations, deliberately.** The briefed wiring is `PanelContainer`'s `styles/panel_raised`. A
`PanelContainer` asks the theme for the item named `panel`, and Godot resolves a variation by looking that
same item name up under the variation type first (`PanelRaised`), then under the base class
(`PanelContainer`). Registering only `PanelContainer/panel_raised` would leave the frame unused, because
nothing in `PanelContainer` ever reads an item called `panel_raised`. So both are registered: the briefed
`PanelContainer/panel_raised` (present in the `.tres`, inert, documented) and `PanelRaised/panel`, which is
what actually makes `theme_type_variation = &"PanelRaised"` render the framed panel. This is measured in
the probe (section 4.2) through a live `PanelContainer` node, not assumed.

**Border convention reading (documented deviation).** `StyleBoxTexture` has no `border_width_*` and no
`border_color`; the theme's 1 px border convention is therefore expressed as `expand_margin_* = 1.0`, which
is the same 1 px footprint every `StyleBoxFlat` border in this theme occupies, plus `modulate_color` left at
white so the 1 px `#2A2E35` steel border painted into `ui_panel_frame.png` is not tinted. Tinting a
gunmetal frame with `metal_mid` would double-darken it (`#2a313c` on top of gunmetal), which no other item in
the theme does; the briefed "border colour convention" is honoured in geometry rather than by a colour
multiply, and that choice is recorded here and in the worker report.

### 2.4 Scroll chrome

| Type | Item | Box | Tokens |
|---|---|---|---|
| `ScrollContainer` | `panel` | `_flat` | bg `void_panel`, border `metal_mid` (the shared `panel` box) |
| `VScrollBar` | `scroll` | `_flat` + 5 px left/right content margins | bg `metal_mid`, border `metal_mid` |
| `VScrollBar` | `grabber` | `_flat` + 5 px content margins | bg `metal_light`, border `metal_light` |
| `VScrollBar` | `grabber_highlight` | `_flat` + 5 px content margins | bg `metal_light`, border `accent_danger` |

The 5 px content margins are the same convention `slider_grabber` already uses (5 px margins + 1 px borders
= the 12 px grabber `UI_SPEC.md` section 2.1 specifies); without them a `StyleBoxFlat` reports a zero
minimum size and the bar would collapse to nothing.

`accent_danger` is applied as the **1 px border on the hovered grabber only**, not as a fill.
`UI_SPEC.md` section 1 reserves the accent for damage, alerts and armed weapons; a moving scrollbar is not
one of those, so the orange is kept to a hairline. Mapped as briefed (`metal_mid` trough, `metal_light`
grabber, `accent_danger` highlight), with that reservation respected.

`grabber_pressed` and `scroll_focus` are **not** registered: the brief enumerates three `VScrollBar` items
and inventing more would put unrequested items in the generated file. Consequence: a pressed grabber and a
focused scrollbar fall back to the engine default theme. Recorded as a follow-up, not a defect.

### 2.5 List chrome

| Type | Item | Value |
|---|---|---|
| `ItemList` | `panel` | shared `panel` box: bg `void_panel`, border `metal_mid` |
| `ItemList` | `font_size` | 14 (`BASE_FONT_SIZE`) |
| `ItemList` | `font_color` | `text_primary` |
| `ItemList` | `selected` | bg `metal_mid`, border `metal_light` |
| `ItemList` | `hovered` | bg `metal_mid`, border `metal_mid` |
| `ItemList` | `cursor` | the shared `focus` box: 1 px `accent_danger_bright`, no fill |
| `Tree` | `panel` | shared `panel` box |
| `Tree` | `title_button_normal` | `_bevel(metal_dark)` (border `metal_light` + 1 px `metal_dark` shadow at (1, 1)) |
| `Tree` | `title_button_hover` | bg `metal_mid`, border `metal_light` |
| `Tree` | `title_button_pressed` | bg `void_panel_raised`, border `metal_dark` |
| `Tree` | `title_button_disabled` | bg `metal_dark`, border `metal_dark` |
| `Tree` | `selected` | bg `metal_mid`, border `metal_light` |
| `Tree` | `cursor` | the shared `focus` box |

All boxes come from the existing `_flat` / `_bevel` / `_focus_box` factories, so every one of them keeps the
theme's conventions: corner radius 0, 1 px borders, no gradients.

**Colour entries beyond the briefed minimum, and why.** The brief lists styleboxes for the two list controls
plus a font size for `ItemList`. A stylebox-only registration still leaves engine-default *text* on exactly
the widgets the brief says must not "fall back to engine defaults", so four `ItemList` colours
(`font_color`, `font_selected_color`, `font_hovered_color`, `font_disabled_color`) and four `Tree` colours
(`font_color`, `font_selected_color`, `font_disabled_color`, `title_button_color`) are registered from the
existing tokens. No extra font-size item is added this way, so the `FONT_SIZE_ITEMS` arithmetic is
unaffected.

**Tree font sizes are deliberately not registered.** The brief names no `Tree` font-size item; adding one
would add another `FONT_SIZE_ITEMS` entry that the brief does not budget for. Consequence: `Tree` text uses
the engine default 16 px and does not follow `ui_scale`. This is a real gap for whichever screen uses a
`Tree`, it is recorded here, and the fix is one `set_font_size` call plus one router entry.

## 3. `FONT_SIZE_ITEMS` consequence

`Router.FONT_SIZE_ITEMS` is the list of per-type font-size items that `Router._scale_font_sizes()` re-writes
as `roundi(base * ui_scale)` on the duplicated live theme, reading the base back from the source theme on
every call (so repeated scale changes never compound). The documented rule is that the list and the theme
must agree in **both** directions, or a new item silently stops scaling.

| Direction | Before | After |
|---|---|---|
| Theme per-type font-size items | 21 | **27** |
| `Router.FONT_SIZE_ITEMS` entries | 21 | **27** |
| Theme items missing from the list | 0 | 0 |
| List entries missing from the theme | 0 | 0 |

Six items are added, not five: the five new variations (48/22/20/18/13) **plus `ItemList/font_size` 14**,
which section 2.5 above requires. `ItemList` is a `Control` that asks the theme for its own `font_size`, so
leaving it out of the router list would make station list rows ignore `ui_scale`, which is the exact failure
mode the list exists to prevent. The briefed target of 26 assumes five new items; the measured, in-sync
number is 27, and the probe reports both directions so the arithmetic is auditable. Full inventory in
section 5.

## 4. `AudioManager`: music and ambience

The existing API (`play_ui`, `play_sfx`, `set_bus_linear`, `bus_linear`) is unchanged, including the
`set_bus_linear` semantics that `SettingsManager` drives. Six methods are added, exactly the briefed
signatures:

| Method | Bus | Behaviour |
|---|---|---|
| `play_music(track: StringName, fade_seconds: float = 1.0) -> void` | dedicated `AudioStreamPlayer` on `Music` | resolves the cue in `Paths.AUDIO_DIRS[&"music"]`, forces `stream.loop = true`, and plays it |
| `stop_music(fade_seconds: float = 1.0) -> void` | same player | fades to -80 dB, then stops the player |
| `current_music() -> StringName` | - | the requested track, or `&""` |
| `play_ambience(bed: StringName, fade_seconds: float = 1.0) -> void` | dedicated `AudioStreamPlayer` on `SFX` | resolves the cue in `Paths.AUDIO_DIRS[&"ambience"]`, forces the loop, and plays it |
| `stop_ambience(fade_seconds: float = 1.0) -> void` | same player | fades to -80 dB, then stops |
| `current_ambience() -> StringName` | - | the requested bed, or `&""` |

Both players are created in `_ready()` next to the existing UI and SFX pool players, named `MusicPlayer`
and `AmbiencePlayer`.

Resolution, no-ops and fading, as specified:

- **Cue resolution** reuses the existing `_load_cue(bus, cue)`: exact filename first, then the `_01`
  fallback, `.ogg` only. The bus keys are the new `MUSIC_DIR_KEY := &"music"` and
  `AMBIENCE_DIR_KEY := &"ambience"`.
- **Missing file is a silent no-op:** `_load_cue()` returns `null`, the call returns before touching either
  the player or the requested-track field. So a request for a file that does not exist leaves whatever is
  already playing alone, and `current_music()` keeps reporting the previous track. No `push_error`, no
  `print`.
- **Same track is a no-op:** `play_music(t)` returns immediately when `t == _music_track` (and likewise for
  ambience), so a screen that re-enters cannot restart the bed it is already listening to.
- **A different track crossfades, and cannot stack:** one player per bus means two tracks can never sound
  at once. `_crossfade()` tweens the playing track down to -80 dB over `fade_seconds / 2`, swaps the stream
  in a `Tween` callback (`_start_stream()` sets the stream, resets `volume_db` to -80 and calls `play()`),
  then tweens up to the target over the remaining `fade_seconds / 2`. Total fade time equals
  `fade_seconds`. Re-entrant calls kill the previous tween first, so a rapid double call cannot leave two
  fades racing. `AUDIO_SPEC.md` section 4.4's "never hard-cut music" is satisfied: the outgoing bed is
  faded, never cut.
- **Target level from the bus:** `_bus_target_db(bus)` returns `clampf(linear_to_db(bus_linear(bus)), -80,
  0)`, and returns `-80` when `bus_linear()` reports 0 (a muted bus, or a bus that does not exist). This
  honours a muted bus by leaving the player silent instead of raising an error, and it keeps `-inf`
  (`linear_to_db(0.0)`) out of the tween. `bus_linear()` and `set_bus_linear()` themselves are untouched.
  **Consequence, stated plainly:** the music slider therefore attenuates twice (once on the player, once on
  the bus), so the slider response for music is quadratic in dB. That is what "the value the bus volume
  implies" means literally; if the owner wants a single attenuation the fade target becomes `0.0` and the
  bus stays the only attenuator, a one-line change in `_bus_target_db()`.
- **Loop flag:** `_set_loop(stream)` sets `loop = true` on `AudioStreamOggVorbis`/`AudioStreamMP3` and
  `loop_mode = LOOP_FORWARD` on `AudioStreamWAV`. All 95 shipped files are OGG; 25 of them (6 music beds
  minus the M4 one-shot, 16 ambience beds, 9 looping SFX cues) already carry the flag in their `.import`
  sidecars, so this is belt and braces for stems that arrive un-flagged, per `AUDIO_SPEC.md` section 8.3.
- **`ui/paths.gd`:** the `&"ambience"` key is a parallel worker's deliverable (`docs/design/STATION_SPEC.md`
  / D2). `AudioManager` is written against the key. Until the key exists, `CUE_DIRS.get(&"ambience", "")`
  returns an empty string, `_load_cue()` returns `null`, and `play_ambience()` is a silent no-op: a missing
  key degrades to the documented no-op, it does not error.

## 5. Item inventory, before and after

Measured from `ui/theme/vajb_theme.tres` and from the generator's own report.

| Measure | Before | After |
|---|---|---|
| Tokens colours | 12 | 12 |
| Per-type font-size items | 21 | 27 |
| Base-type styleboxes | 14 | 15 (`+ panel_frame`) |
| Stylebox types | 17 | 23 (`PanelContainer` +1 item, plus `StationButton`, `PanelRaised`, `ScrollContainer`, `VScrollBar`, `ItemList`, `Tree`) |
| Registered variations (generator report) | 12 | 18 |
| `base_type` entries in the `.tres` | 11 | 17 |
| New stylebox items | - | `panel_frame`; `PanelContainer/panel_raised`; `PanelRaised/panel`; `ScrollContainer/panel`; `VScrollBar/{scroll, grabber, grabber_highlight}`; `ItemList/{panel, hovered, selected, cursor}`; `Tree/{panel, title_button_normal, title_button_hover, title_button_pressed, title_button_disabled, selected, cursor}` |

Nothing that existed before is removed or renamed: every pre-existing item is diffed before and after, and
the two lists are reported in the worker report.

## 6. Verification to be run

1. Regenerate:

   ```
   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/build_theme.gd
   ```

   Expect exit 0, 27 font-size items reachable, 18 variations in the report, and no `missing texture` line.
2. Throwaway probe (`extends SceneTree`, `quit()` at the end), which prints:
   - the full per-type font-size inventory from `res://ui/theme/vajb_theme.tres`, every `type/item = size`,
     the `base_type` of every variation type, and the presence of each new item and variation by name;
   - `Router.live_theme()` font sizes for `HeroTitle`, `StationButton`, `StationPanelTitle`, `StationValue`,
     `StationCaption` and `ItemList` at `ui_scale` 1.0 and 1.4, the router-list count against the theme item
     count with both missing directions, and a full round-trip back to 1.0 that must restore every base size
     exactly (the scale is changed by writing `SettingsManager`'s in-memory `ConfigFile`, never through
     `set_value()`, so `user://settings.cfg` is not written);
   - a live `PanelContainer` with `theme_type_variation = &"PanelRaised"` whose resolved `panel` stylebox
     must be a `StyleBoxTexture` over `ui_panel_frame.png`;
   - `AudioManager.play_music(&"mus_menu_theme_01")` then `current_music()`, the resolved stream's
     `resource_path` and `get_length()`, then `stop_music()`; the same for
     `play_ambience(&"amb_space_drone_01")`; the presence of the `&"ambience"` key in `Paths.AUDIO_DIRS`;
     and a missing-cue no-op check.
3. Headless scene runs, each expected to exit 0 with no new errors or warnings:
   `res://ui/screens/main_menu.tscn`, `res://ui/screens/settings.tscn`, `res://game/game.tscn`,
   `res://ui/hud/hud.tscn`.
4. The probe and its `.uid` are deleted; `tools/` must end holding only `build_theme.gd`,
   `derive_icon_tints.gd` and their `.uid` files.

`user://settings.cfg` is read-only for this work: its sha256 is recorded before and after.

## 7. Recorded follow-ups (not defects)

- `VScrollBar/grabber_pressed` and `VScrollBar/scroll_focus` are left to the engine default (not in the
  briefed item list).
- `Tree` has no themed font size, so Tree text does not follow `ui_scale` (section 2.5).
- Music level is attenuated by both the player and the `Music` bus (section 4).
