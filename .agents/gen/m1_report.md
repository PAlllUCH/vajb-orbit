# M1 report - main menu v2 shipping screen

Coder worker, 2026-09-18. Spec followed: `docs/design/MAIN_MENU_V2.md` (single source of truth),
structure contract `docs/design/IMPLEMENTATION_PLAN.md` sections 3.4, 3.11, 3.12, 4.3, 7, 9.1-9.6.
No redesign: every geometry, motion and copy number below is either taken from the spec or
measured from the built scene.

## 1. Deliverables

| File | State |
|---|---|
| `vajb-orbit/ui/screens/main_menu.tscn` | rebuilt, 276 lines, spec node tree minus the mockup-only `QuitStandIn` subtree |
| `vajb-orbit/ui/screens/main_menu.gd` | rebuilt, 325 lines, `extends Screen` |
| `vajb-orbit/ui/components/menu_button.tscn` | `custom_minimum_size` 280x56 -> 350x70 (offsets 350/70); root script, `Button` child name, `Glow` underlay unchanged |
| `vajb-orbit/ui/components/menu_button.gd` | added `MINIMUM_HEIGHT` (70) + `_sync_minimum_height()`; published interface (`pressed` / `hovered` / `unhovered`, `Button` child, `BORDER_WIDTH` 1 px ring, press scale, breathing border, glow) unchanged |
| `vajb-orbit/ui/screens/_mockup_main_menu.tscn`, `_mockup_main_menu.gd`, `_mockup_main_menu.gd.uid` | **deleted** (contract 9.6). Confirmed absent: `ls ui/screens` now lists only boot, loading, main_menu, settings, settings_rebind_row, station plus `_mockup_station.*` (the station wave's own mockup, not mine) |
| `.agents/gen/m1_report.md` | this file |

Nothing outside those paths was edited. `ui/paths.gd`, `loading.gd`, `game.gd`, the theme,
`project.godot`, `addons/` and `ui/station/` were only read.

### 1.1 What the scene now is

`MainMenu` (Control, preset 15, grow 2/2, `theme = res://ui/theme/vajb_theme.tres`, `main_menu.gd`)
-> `BackdropLayer` (`%Backdrop` + `%EmberPulse`, `%LeftScrim`, `%BottomScrim`) -> `GrainLayer`
-> `SafeArea` (MarginContainer 96/64/96/48) -> `Bands` -> `HeaderBand` (`%Logo`) /
`MiddleBand` (`CommandColumn` -> `CommandHeader` (`%CommandHeader` -> `HeaderGutter`,
`%InsigniaBadge`) + `VerbStack` (three rows of tick + plate) | `MiddleSpacer`) /
`FooterBand` (`%FocusReadout`, `%VersionLabel` = `VAJB ORBIT v0.2`).

No region is placed by a hand-tuned offset; the only offsets in the file are the backdrop's
24 px drift slack and the 500 px ember box, both from the spec.

## 2. Exact commands and output

Binary: `C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe`, project path
`G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit`. The editor (PID 9048) was never touched and
`--headless --editor` was never run.

### 2.1 Required headless runs (final pass, single process per invocation)

| # | Command (`..._console.exe --headless --path <proj> <scene> --quit-after 300`) | Output |
|---|---|---|
| 1 | `res://ui/screens/main_menu.tscn` | `Godot Engine v4.7.2.stable.official.ed1daf0bf`, `[godot_ai game_helper] registered mcp capture`, exit 0 |
| 2 | `res://ui/screens/boot.tscn` | same, exit 0 |
| 3 | `res://ui/screens/settings.tscn` | same, exit 0 |
| 4 | `res://game/game.tscn` | same, exit 0 |

Also run: `res://ui/screens/boot.tscn --quit-after 20000` (long enough in wall time for the
boot timeline to complete and hand the route to `main_menu` inside the run) -> exit 0, no
script errors, and the menu was demonstrably entered (see 2.3).

No script errors, no `push_error`/`push_warning`, no missing-resource messages in any run.
The only stdout line any of these runs emits is the vendored
`[godot_ai game_helper] registered mcp capture` registration that every scene in this project
emits (spec 13.5 gotcha 3).

### 2.2 One warning that is not from the screen (reported, not hidden)

Some runs end with the engine's exit-time block:

```
WARNING: 4 ObjectDB instances were leaked at exit
ERROR: 2 resources still in use at exit
```

Facts, all measured:

- `--verbose` identifies the leaked objects on a menu run as
  `OggPacketSequence`, `AudioStreamOggVorbis`, `AudioStreamPlaybackOggVorbis`,
  `OggPacketSequencePlayback`, i.e. the menu music bed `mus_menu_theme_01.ogg`.
- It is **intermittent and not scene-specific**. Same command, same scene: clean in several runs
  (including the four-row table above, and `menu A`/`menu B`) and present in others. Loops of
  three or four menu runs produced one block per run; a single `game.tscn` run produced one block
  in one batch and none in another, although `game.tscn` contains no audio call and none of the
  files I own.
- Control experiment A (`ui/screens/_scratch_audio_probe.gd`, scratch, since deleted) whose whole
  `_ready()` is `AudioManager.play_music(&"mus_menu_theme_01", 1.5)` + `get_tree().quit()`:
  the identical block, with none of the menu's code in the process.
- Control experiment B, same scratch script plus `AudioManager.stop_music(0.2)` followed by
  0.6 s of frames so the fade reaches its `player.stop()` callback: **clean exit**.

Cause: `AudioManager` never stops its players; `stop_music()` reaches `player.stop()` through a
`Tween` callback, which needs a frame, and `--quit-after` tears the tree down in the same
iteration that the screen's `_exit_tree()` calls it. So a bed that is still playing at teardown
leaks. It is timing sensitive, which is why it comes and goes.

Needed contract change (outside my file ownership, so not applied):
`vajb-orbit/autoload/audio_manager.gd` should stop its players in its own teardown, e.g.

```gdscript
func _exit_tree() -> void:
	_kill_music_tween()
	_kill_ambience_tween()
	_music_player.stop()
	_ambience_player.stop()
	_ui_player.stop()
	for player in _sfx_players:
		player.stop()
```

`stop_music(MUSIC_STOP_SECONDS)` in `main_menu.gd::_exit_tree()` is the spec's own rule and is
kept as required; it is correct for every real route change (menu -> loading), where the fade
completes and the player stops.

### 2.3 Measurement probe (throwaway, deleted)

`res://tools/_probe_m1.gd` (`extends SceneTree`, calls `quit()`), run with:

```
..._console.exe --headless --path <proj> --script res://tools/_probe_m1.gd
```

It instantiates `main_menu.tscn` four times, each with the theme duplicated and scaled exactly
the way `Router._scale_font_sizes()` scales it (base `default_font_size` 14 plus every entry of
`Router.FONT_SIZE_ITEMS`, read off the script resource because autoload identifiers are not
registered yet inside a `--script` main loop), waits for layout, and dumps engine rects. It never
touches `SettingsManager`, so `user://settings.cfg` is not written.

Measured canvas coordinates (canvas = 1920x1080; the window was 2560x1440 from `settings.cfg`, so
`canvas_items`/`expand` scale is 1.3333, and every number lands exactly on the spec's 1920x1080
table):

| ui_scale | plate box | plate x | row tops | pitch | visible gap | inner `Button` min h | component min h | tick box | column | emblem |
|---|---|---|---|---|---|---|---|---|---|---|
| 1.0 | 350 x 70 | 118..468 | 541 / 625 / 709 | 84 | 14 | 47 | 70 | 6 x 60, y 546..605 | 372 x 312 at (96, 467) | 50 x 58 at x 118 |
| 1.2 | 350 x 70 | 118..468 | 538 / 622 / 706 | 84 | 14 | 57 | 70 | 6 x 60, y 543..602 | 372 x 312 at (96, 464) | 50 x 58 at x 118 |
| 1.4 | 350 x 70 | 118..468 | 536 / 620 / 704 | 84 | 14 | 67 | 70 | 6 x 60, y 541..600 | 372 x 312 at (96, 462) | 50 x 58 at x 118 |
| 2.0 | 350 x 93 | 118..468 | 494 / 601 / 708 | 107 | 14 | 93 | 93 | 6 x 60 | 372 x 381 at (96, 420) | 50 x 58 at x 118 |

This reproduces the spec's own tables (section 3.1, section 12.1, section 12.2) number for number:
constant 70 px row and 14 px gap at 1.0/1.2/1.4, no plate stretch, the 5 px / 3 px upward shift of
the column, and at 2.0 the font-driven minimum (93) overtakes the 70 px floor and the row grows -
which is what "row height follows the font, never a pinned constant" has to mean.

Contract checks from the same probe:

```
CONTRACT focus_on_entry=Button:<Button#...> parent=PlayButton
CONTRACT tick_alphas=["1.00","0.00","0.00"] play_focused_flag=true readout=ENTER THE STATION HUB
CONTRACT stamp_variation=Version stamp_colour=(0.7882,0.8196,0.8627,1.0) token_text_primary=(same) theme_tokens_match=true
CONTRACT intent route=loading params={&"destination": &"station"}
CONTRACT intent route=settings params={}
CONTRACT intent route=quit_confirm params={}
CONTRACT esc_depth0_last_route=quit_confirm
CONTRACT esc_with_overlay depth=1 emitted=0
CONTRACT music track=mus_menu_theme_01 player_playing=true player_stream_null=false
```

The intents are produced by emitting the inner `Button`'s real `pressed` signal (router and
overlay-push calls are stubbed by the probe's own local signal listeners), and the Esc guard was
exercised twice: with no overlay it emits `quit_confirm`, and after a real
`Router.push_overlay(&"settings")` (`overlay_depth()` = 1) it emits nothing.

## 3. Focus ring

`menu_button.gd` `BORDER_WIDTH = 1.0`; `_draw()` builds `Rect2(0.5, 0.5, size.x - 1, size.y - 1)`
and calls `draw_rect(ring, colour, false, 1.0)`, so the ring is exactly one pixel on each of the
four sides and independently of the plate size. The probe reads the constants back off the script
at every scale: `BORDER_WIDTH=1.0`. A pixel-count measurement is not available in a `--headless`
run (dummy renderer, no framebuffer); the earlier engine dump in `.agents/gen/d4c_report.md`
section 15.4 measured exact one-row/one-column runs at 1.0, 1.2 and 1.4 for this same component,
and the drawing code is unchanged.

## 4. Asset resolution

Every `res://` path the screen or the component references (theme, grain, `env_menu_bg`,
`fx_ember_pulse`, `logo_vajb_orbit`, `ui_insignia_neutral`, `menu_button.tscn`,
`menu_button.gd`, `glow_underlay.gd`, `mus_menu_theme_01.ogg`) returned
`ResourceLoader.exists = true`. `ui_panel_frame.png` is referenced nowhere in the screen,
matching spec sections 2.1 and 7.

## 5. `user://settings.cfg` and `user://profile.cfg`

| File | sha256 before any run | sha256 after all runs |
|---|---|---|
| `C:\Users\Kamil\AppData\Roaming\Godot\app_userdata\Vajb Orbit\settings.cfg` | `EDB17B3FCF9C3B29720A7590DADE2DE3262CFBB78699BB78A239FCC9DD233617` | `EDB17B3FCF9C3B29720A7590DADE2DE3262CFBB78699BB78A239FCC9DD233617` |
| `...\profile.cfg` | `15025E5299AC9736E9AAD9B4D06565EA7A4D11CACA6BAEA719D7C4B86D35A4CA` | `15025E5299AC9736E9AAD9B4D06565EA7A4D11CACA6BAEA719D7C4B86D35A4CA` |

Byte-identical, across roughly twenty headless runs. (`SettingsManager._write_settings()` is
guarded by `_dirty`, so nothing in this flow writes the settings file, and the probe scaled the
theme itself instead of going through the settings slider.)

## 6. Judgement calls and deviations

1. **The row-height rule lives in the component, not the screen.** `MAIN_MENU_V2` section 12.1
   describes the mockup's screen-side `_sync_plate_minimum()`; the rule itself is "no pinned row
   height, the plate's minimum is `max(70, inner Button minimum)`". I implemented it once in
   `menu_button.gd` (`MINIMUM_HEIGHT` + `_sync_minimum_height()`, called from `_ready()` and from
   `NOTIFICATION_THEME_CHANGED`) so no consumer of the component can pin a row, and the screen
   carries no `custom_minimum_size` on any instance and no `_sync_plate_minimum()`. Measured
   outcome is identical to the spec's table (see 2.3), including the 2.0 column.
2. **The component's baked size changed 280x56 -> 350x70** rather than being overridden per
   instance. The spec allows either ("or the component must be updated for every other screen at
   the same time"); `menu_button.tscn` has exactly one consumer, `main_menu.tscn` (verified by
   grep over the project), so updating the component is the cleaner half of that choice.
3. **`_on_verb_pressed` switches on verb indices** (`VERB_PLAY/OPTIONS/EXIT`), the shape the
   approved mockup uses, instead of the string actions the Phase C screen used, so `READOUT`,
   `_verbs`, `_ticks` and the opener index all address the same thing. The intent payloads are
   unchanged in shape.
4. **Overlay-pop focus** remembers the verb that emitted the overlay intent (not the hard-coded
   EXIT of Phase C), which also fixes OPTIONS; the Esc guard
   (`Router.overlay_depth() > 0` -> ignore) is kept as required.
5. **`UiCue.CONFIRM` is not used.** Spec section 11 wants `CONFIRM` on PLAY, and the audio wave
   has since added `CONFIRM`/`DENIED`/`SCROLL` to `AudioManager` (09:43). The brief scoped this
   screen to "keep the hover and click calls on the verbs", so the screen calls `HOVER` on
   hover/keyboard focus and `CLICK` on every press, and nothing else. Adding `CONFIRM` on PLAY is
   a one-line change if the owner wants it.
6. **The station route exists now.** `ui/paths.gd` gained `&"station"` while I was working
   (09:43, parallel worker), so the guard resolves PLAY -> `loading {destination: station}`
   today; earlier in the session the same probe printed `{destination: game}`. Both branches are
   therefore exercised, and the guard code is untouched. Per the brief I did not add the route.
7. **`tools/` is not down to two scripts.** After deleting my probe and its `.uid`, `tools/`
   holds `build_theme.gd`(+uid), `derive_icon_tints.gd`(+uid) and **`_probe_s1.gd`**, the station
   wave's scratch probe, which is still present. It is not mine to delete; the orchestrator
   should remove it after that wave reports.

## 7. What I could not verify

- **Pixels.** Every run in this environment is `--headless` (dummy renderer, no framebuffer, and
  the editor's viewport already belongs to the open editor session), so no screenshot of the
  shipping screen was taken. The geometry, colour sources, focus state and motion wiring are
  verified programmatically and match the numbers in `.agents/gen/d4c_report.md`, whose renders
  were produced from the mockup this screen was ported from; a rendered confirmation of the
  shipping scene itself is still worth one editor screenshot.
- **The ember re-anchor under a live aspect change.** The formula (`KEEP_ASPECT_COVERED` cover
  factor, `origin + drawn * (0.791, 0.618) - size / 2`) is ported verbatim from the mockup and
  was verified numerically there at 1920x1080 (D4c); it was not re-rendered here.
- **True 1 px ring measurement.** As above: source-level proof plus the earlier engine dump, not a
  pixel count from a rendered frame.
