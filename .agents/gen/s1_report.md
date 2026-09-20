# S1 report: station hub shell + OUTFITTING panel

Worker: coder (S1). Date: 2026-09-18. Workspace: `G:/Mój dysk/Projekty/Vajb Orbit`.
Godot 4.7.2 stable, `--headless` only (an editor is open on the project; it was never touched,
never restarted, and no `--headless --editor` run was made).

Everything below is measured. Where I could not measure something, the section says so.

---

## 1. Deliverables

| # | File | State |
|---|---|---|
| 1 | `vajb-orbit/ui/screens/station.tscn` | new (shell: backdrop, grain, safe area, header, rail, host, footer, leave confirm, fade) |
| 2 | `vajb-orbit/ui/screens/station.gd` | new (shell controller: modules, focus contract, credits readout, refusals, audio, leave confirm) |
| 3 | `vajb-orbit/ui/station/outfitting_panel.tscn` | new (OUTFITTING pane: header, column strip, scroll, rows, footer) |
| 4 | `vajb-orbit/ui/station/outfitting_panel.gd` | new (rows built from `StationCatalog.AMMO_PACKS`, state from `PlayerProfile`) |
| 5 | `vajb-orbit/ui/paths.gd` | edited: `&"station": "res://ui/screens/station.tscn"` in `ROUTES` |
| 6 | `vajb-orbit/ui/screens/loading.gd` | edited: the destination is resolved to a route (station included), default behaviour kept |
| 7 | `vajb-orbit/game/game.gd` | edited: `ui_cancel` docks to the station, not the menu |
| 8 | `vajb-orbit/autoload/audio_manager.gd` | edited: `UiCue` gains `CONFIRM`, `DENIED`, `SCROLL`; `UI_CUE_NAMES` gains their three names |

The editor generated `.uid` sidecars for the two new scripts (`station.gd.uid`,
`outfitting_panel.gd.uid`); they are the normal Godot 4 artifact for a script I own and were left in place.

Not touched, as instructed: `_mockup_station.*`, `ui/screens/main_menu.*`, `ui/components/menu_button.*`,
`project.godot`, `addons/`, the theme resource, `tools/build_theme.gd`, `tools/derive_icon_tints.gd`.
No documentation file was edited either: the brief's file list ends with `.agents/gen/s1_report.md`, so the
docs-first rule was satisfied by the existing specs rather than by new doc edits.

`autoload/router.gd` was **not** changed. No new font-size item was needed (section 8 of the spec is
exhaustive for this screen), so `Router.FONT_SIZE_ITEMS` stays at 27 entries and in sync with the theme
(measured, section 2.8).

---

## 2. Commands and outputs

Binary used throughout:
`"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe"` with
`--path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"`.

### 2.1 Baseline headless runs (taken before writing any code)

```
... res://ui/screens/loading.tscn --quit-after 300   -> EXIT=0, stdout clean
... res://ui/screens/boot.tscn    --quit-after 300   -> EXIT=0, stdout clean
... res://game/game.tscn          --quit-after 300   -> EXIT=0, stdout clean
... res://ui/screens/settings.tscn --quit-after 300  -> EXIT=0, stdout clean
... res://ui/screens/_mockup_station.tscn --quit-after 300 -> EXIT=0, stdout clean
... res://ui/screens/main_menu.tscn --quit-after 300 -> EXIT=0 but:
      WARNING: 4 ObjectDB instances were leaked at exit
      ERROR: 2 resources still in use at exit
```

`main_menu.tscn` already leaked 4 instances / 2 resources **before** any of my edits (this is the parallel
worker's screen, mid-flight). That baseline matters for the next section.

### 2.2 Final headless runs

```
$ ... res://ui/screens/station.tscn --quit-after 300
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
WARNING: 4 ObjectDB instances were leaked at exit (run with `--verbose` for details).
ERROR: 2 resources still in use at exit (run with `--verbose` for details).
EXIT=0
```

Exit 0, no script errors, no runtime warnings from my code. The two shutdown lines are the engine's leak
report, and they are **not** new to the project (see 2.3).

```
$ ... res://ui/screens/loading.tscn --quit-after 300   -> EXIT=0, stdout clean
$ ... res://ui/screens/boot.tscn    --quit-after 300   -> EXIT=0, stdout clean
$ ... res://game/game.tscn          --quit-after 300   -> EXIT=0, stdout clean
$ ... res://ui/screens/main_menu.tscn --quit-after 300 -> EXIT=0, same 4/2 leak as its own baseline
```

No new error or warning appears in any of the five.

### 2.3 The station's shutdown leak, identified and bounded

`--verbose` names the leaked objects exactly:

```
$ ... --verbose --log-file <temp> ... res://ui/screens/station.tscn --quit-after 300
Leaked instance: OggPacketSequence ... Reference count: 3
Leaked instance: AudioStreamOggVorbis ... Reference count: 1
Leaked instance: AudioStreamPlaybackOggVorbis ... Reference count: 1
Leaked instance: OggPacketSequencePlayback ... Reference count: 1
Resource still in use: res://assets/audio/ambience/amb_station_room_01.ogg::OggPacketSequence
Resource still in use: res://assets/audio/ambience/amb_station_room_01.ogg
```

Three throwaway probes (each a 12-line `extends SceneTree` script, since deleted) isolate it:

| probe | calls | result |
|---|---|---|
| A | `play_ambience(amb_station_room_01, 2.0)`, wait 1.0 s, quit | leak 4 / 2 |
| B | `play_ambience`, wait 0.5 s, `stop_ambience(0.1)`, wait 0.5 s, quit | clean |
| C | `play_ambience(0.2)` (fade finished), wait 2.0 s, quit | leak 4 / 2 |

So the artifact is "the process exits while a bed is still playing", nothing to do with the station's code:
probe A contains no station code at all. The identical signature is the pre-existing baseline of
`main_menu.tscn`, whose `--verbose` log names the same four objects for `mus_menu_theme_01.ogg`.

`autoload/audio_manager.gd` is the place a fix belongs (stop its players on `NOTIFICATION_WM_CLOSE_REQUEST`);
the brief allows me only the `UiCue` extension there, so I left it and I am reporting it instead.

I also tried the station-side mitigation (`_exit_tree` -> `stop_ambience`) and removed it again: at shutdown
`stop_ambience` only starts a fade tween, the tween never runs, and the leak is unchanged. Dead code is
worse than an honest report.

### 2.4 The verification probe (verification 2)

`res://tools/_probe_s1.gd`, `extends SceneTree`, calls `quit()`. Full output, abridged only where the
geometry block repeats (section 2.5 has it in full):

```
[route] station -> 'res://ui/screens/station.tscn' exists=true
[panel] module OUTFITTING -> res://ui/station/outfitting_panel.tscn exists=true
[panel] module SHIPYARD -> res://ui/station/shipyard_panel.tscn exists=false
[panel] module UPGRADES -> res://ui/station/upgrades_panel.tscn exists=false
[panel] module LAUNCH -> res://ui/station/launch_panel.tscn exists=false
[credits] PlayerProfile.credits()=10000 readout='10 000'
[buy] row press -> credits 10000 -> 9880, held '300 / 300' -> '600 / 300'
[buy] row tag='OVER CAP' caption='CAPACITY IS ADVISORY'
[buy] status strip: 'PURCHASED · LASER CELLS · +300 ROUNDS'
[buy] buy_ammo(laser, 300, 999999)=false status strip: 'REFUSED · NOT ENOUGH CREDITS · 120 NEEDED'
[buy] profile after the probe: credits=9880 laser=600
[cancel] focus at entry: AmmoLaser
[cancel] after ui_cancel 1: focus OutfittingEntry
[cancel] after ui_cancel 2: confirm visible=true focus LeaveCancel
[cancel] after ui_cancel 3: confirm visible=false focus OutfittingEntry
[intents] declared by the shell: loading { &"destination": &"game" }, main_menu {  }
[swap] with res://ui/station/shipyard_panel.tscn present: Shipyard (foreign scene), first label ''
[swap] with res://ui/station/shipyard_panel.tscn removed: Shipyard (offline placeholder), first label 'MODULE OFFLINE'
[swap] stub still on disk: false
[flow] loading{destination: station} -> route='station' scene='Station' panes=4
```

Read as evidence:

- **Route**: `&"station"` resolves to a path that exists.
- **Panels**: the module to panel path mapping the shell uses, with existence. One panel exists, three do not.
- **Credits**: the readout label carries the profile balance (`10 000`), not a literal.
- **Purchase**: `row.pressed.emit()` runs the real UI path -> `buy_ammo` succeeds, credits fall 10000 -> 9880,
  and the held cell refreshes to `600 / 300` with tag `OVER CAP` and caption `CAPACITY IS ADVISORY` through
  `profile_changed` -> shell -> panel. The status strip reads the success copy.
- **Refusal**: a call that cannot be afforded returns `false`, and the strip reads
  `REFUSED · NOT ENOUGH CREDITS · 120 NEEDED` in the danger colour (the cost is the catalogue's, see
  judgement call 7).
- **Focus contract**: `ui_cancel` walks pane -> rail entry -> leave confirm -> closed, exactly as
  section 10 requires, and focus never lands on a hidden row.
- **Intents**: LAUNCH declares `loading{destination: &"game"}`, LOG OUT declares `main_menu`. Both were
  captured by connecting a probe listener to `route_requested`; nothing routed during this part of the probe.
- **Missing panel handling**: with a real `shipyard_panel.tscn` on disk the host instantiates it (the pane is
  a foreign scene, not the placeholder); with the file removed the host synthesises the offline placeholder
  again and its first label reads `MODULE OFFLINE`. The stub file is deleted again by the probe
  (`stub still on disk: false`), so the answer to "does the placeholder disappear the moment a real panel
  scene lands" is yes, measured in both directions in one run.
- **Flow**: `Router.route(&"loading", {destination: &"station"})` runs the loading bridge for real, the bridge
  forwards the destination, and the Router lands on `route='station'`, `scene='Station'` with 4 panes built.

The probe was deleted afterwards, together with its `.uid` (section 3.5).

### 2.5 Geometry at ui_scale 1.0 and 1.4 (verification 3)

Measured with the probe on a real instance of `station.tscn` (1920x1080 canvas; the headless window is
2560x1440 and the stretch keeps the canvas at 1920x1080, so all numbers are directly comparable with the
spec's table). At 1.4 the theme was scaled with `Router._scale_font_sizes()`'s own math, read from
`Router.FONT_SIZE_ITEMS`, because `user://settings.cfg` has to stay byte-identical (verification 4).

```
[geometry] ui_scale 1.00
[geometry] viewport (2560, 1440) root (1920.0, 1080.0)
[geometry]   Layout      x 0..1920 y 0..1080
[geometry]   Page        x 24..1896 y 24..1056
[geometry]   Header      x 24..1896 y 24..111
[geometry]   Body        x 24..1896 y 127..1022
[geometry]   ModuleRail  x 24..384 y 127..1022
[geometry]   ModuleHost  x 400..1896 y 127..1022
[geometry]   HostMargin  x 408..1888 y 135..1014
[geometry]   rail OutfittingEntry y 175..231 h 56 gap 0 x 44..364
[geometry]   rail ShipyardEntry   y 237..293 h 56 gap 6 x 44..364
[geometry]   rail UpgradesEntry   y 299..355 h 56 gap 6 x 44..364
[geometry]   rail LaunchEntry     y 361..417 h 56 gap 6 x 44..364
[geometry]   row  AmmoLaser       y 261..337 h 76 gap 0 x 429..1867
[geometry]   row  AmmoCannon      y 343..419 h 76 gap 6 x 429..1867
[geometry]   row  AmmoRocket      y 425..501 h 76 gap 6 x 429..1867
[geometry]   row  AmmoMine        y 507..583 h 76 gap 6 x 429..1867
[geometry]   row  AmmoPlasma      y 589..665 h 76 gap 6 x 429..1867
[geometry]   row  Slack           y 671..671 h 0 gap 6 x 429..1867
[geometry]   pane Outfitting loaded panel x 428..1868 y 155..994
[geometry]     OutfittingHeader: @Control@26 x 0 w 40, @Label@27 x 52 w 928, @Label@28 x 992 w 130, @Label@29 x 1134 w 110, @Label@30 x 1256 w 160
[geometry]     AmmoLaser/RowInner: Icon x 0 w 40, TitleBox x 52 w 913, Held x 977 w 143, Price x 1132 w 110, Status x 1254 w 160
[geometry]     Outfitting: labels checked 43, clipped 0
[geometry]   pane Shipyard offline placeholder x 428..1868 y 155..994, 3 labels, clipped 0
[geometry]   pane Upgrades offline placeholder x 428..1868 y 155..994, 3 labels, clipped 0
[geometry]   pane Launch   offline placeholder x 428..1868 y 155..994, 3 labels, clipped 0
[geometry]     LeaveConfirm: labels checked 2, clipped 0

[geometry] ui_scale 1.40
[geometry]   Header      x 24..1896 y 24..144
[geometry]   Body        x 24..1896 y 160..1014
[geometry]   ModuleRail  x 24..384 y 160..1014
[geometry]   ModuleHost  x 400..1896 y 160..1014
[geometry]   rail OutfittingEntry y 216..272 h 56 gap 0 x 44..364
[geometry]   rail ShipyardEntry   y 278..334 h 56 gap 6 x 44..364
[geometry]   rail UpgradesEntry   y 340..396 h 56 gap 6 x 44..364
[geometry]   rail LaunchEntry     y 402..458 h 56 gap 6 x 44..364
[geometry]   row  AmmoLaser       y 321..397 h 76 gap 0 x 429..1867
[geometry]   row  AmmoCannon      y 403..479 h 76 gap 6 x 429..1867
[geometry]   row  AmmoRocket      y 485..561 h 76 gap 6 x 429..1867
[geometry]   row  AmmoMine        y 567..643 h 76 gap 6 x 429..1867
[geometry]   row  AmmoPlasma      y 649..725 h 76 gap 6 x 429..1867
[geometry]   row  Slack           y 731..731 h 0 gap 6 x 429..1867
[geometry]   pane Outfitting loaded panel x 428..1868 y 188..986
[geometry]     OutfittingHeader: @Control@26 x 0 w 40, @Label@27 x 52 w 928, @Label@28 x 992 w 130, @Label@29 x 1134 w 110, @Label@30 x 1256 w 160
[geometry]     AmmoLaser/RowInner: Icon x 0 w 40, TitleBox x 52 w 859, Held x 923 w 197, Price x 1132 w 110, Status x 1254 w 160
[geometry]     Outfitting: labels checked 43, clipped 0
[geometry]   panes Shipyard / Upgrades / Launch: placeholders, 3 labels each, clipped 0
[geometry]     LeaveConfirm: labels checked 2, clipped 0
```

Answering verification 3 directly:

- **No clipped text**: every visible `Label` in the OUTFITTING pane (43), in the three placeholders (3 each)
  and in the leave confirm (2) satisfies `size >= get_minimum_size()` at both scales, `clipped 0` everywhere.
  Hidden panes are excluded from the check and measured by toggling visibility, so the numbers are real.
- **No overlapping rows**: pitch is 76 + 6 = 82 at both scales, `gap 6` on every pair, `gap 0` before the
  first row. Rail entries: 56 tall, `gap 6`, unchanged at 1.4.
- **Fixed pixels stay fixed**: the rail is 360 wide, the row 76 tall, the rail entry 56 tall, the x extents
  identical at 1.0 and 1.4. Only the text-driven bands grow: the header band 87 -> 120 px tall (24..111 ->
  24..144) and the footer slightly, which is what pushes the Body down at 1.4. The pane still has 798 px of
  height for 5 rows (404 px + Slack).

### 2.6 Profile and settings byte identity (verification 4)

```
before: profile.cfg  15025e5299ac9736e9aad9b4d06565ea7a4d11caca6baea719d7c4b86d35a4ca
        settings.cfg edb17b3fcf9c3b29720a7590dade2de3262cfbb78699bb78a239fcc9dd233617
after:  profile.cfg  15025e5299ac9736e9aad9b4d06565ea7a4d11caca6baea719d7c4b86d35a4ca
        settings.cfg edb17b3fcf9c3b29720a7590dade2de3262cfbb78699bb78a239fcc9dd233617
```

`settings.cfg` was never written by me: **byte-identical**, same sha256 before and after.

`profile.cfg` *was* changed by the probe (it buys two laser packs, and `PlayerProfile` flushes on
`NOTIFICATION_EXIT_TREE`), so I copied the file aside before the probe runs and restored it afterwards. It is
now byte-identical to the baseline hash above and holds its documented default state
(`credits=10000`, `owned_ships=["ship_vanguard"]`, `ammo` 300 each, `upgrades=[]`, `cargo={}`). Both the
pre-probe copy and the post-restore hash were taken with `certutil -hashfile <path> SHA256`.

### 2.7 Cleanup

```
$ ls vajb-orbit/tools/
build_theme.gd  build_theme.gd.uid  derive_icon_tints.gd  derive_icon_tints.gd.uid

$ ls vajb-orbit/ui/station/
outfitting_panel.gd  outfitting_panel.gd.uid  outfitting_panel.tscn
```

`_probe_s1.gd` and `_probe_s1.gd.uid` are deleted; `tools/` holds exactly the two scripts the brief names.
`ui/station/` holds only the OUTFITTING panel.

### 2.8 Audio and theme reachability (supporting evidence for section 4 of the brief)

A second throwaway probe asked `AudioManager` to resolve each cue the station names:

```
[cue] ui/ui_click   -> res://assets/audio/ui/ui_click.ogg
[cue] ui/ui_hover   -> res://assets/audio/ui/ui_hover.ogg
[cue] ui/ui_confirm -> res://assets/audio/ui/ui_confirm_01.ogg
[cue] ui/ui_denied  -> res://assets/audio/ui/ui_denied_01.ogg
[cue] ui/ui_scroll  -> res://assets/audio/ui/ui_scroll_01.ogg
[cue] sfx/sfx_station_breaker_on_01 -> res://assets/audio/sfx/sfx_station_breaker_on_01.ogg
[cue] sfx/sfx_ship_boost_01         -> res://assets/audio/sfx/sfx_ship_boost_01.ogg
[cue] sfx/sfx_ship_jump_01          -> res://assets/audio/sfx/sfx_ship_jump_01.ogg
[cue] ambience/amb_station_room_01      -> res://assets/audio/ambience/amb_station_room_01.ogg
[cue] ambience/amb_station_pump_loop_01 -> res://assets/audio/ambience/amb_station_pump_loop_01.ogg
[cue] ambience/amb_station_noise_loop_01-> res://assets/audio/ambience/amb_station_noise_loop_01.ogg
[theme] font-size items declared by the theme: 27
[theme] declared but not in Router.FONT_SIZE_ITEMS: none
[theme] Router.FONT_SIZE_ITEMS entries: 27
```

The three files that were unreachable before (`ui_confirm_01`, `ui_denied_01`, `ui_scroll_01`) now resolve
through the documented `_01` fallback, and every cue the station names is a real file
(`ASSET_AUDIT.md` D.1 items 2, 3, 4, 7, 8, 9). The theme's 27 font-size items and
`Router.FONT_SIZE_ITEMS`' 27 entries agree with no item missing, so `ui_scale` reaches every station text
item and I added no new one.

---

## 3. The one place where the spec contradicts the approved mockup

**STATION_HUB sections 3.1 and 3.4 give numbers my screen (and the approved mockup) do not reproduce.**
I measured both, in one probe run, in the same process:

| Node | Spec 3.1 | Mockup (measured now) | Shipping station (measured) |
|---|---|---|---|
| Header band | y 24..147 (123 tall) | y 24..111 (87 tall) | y 24..111 (87 tall) |
| Body band | y 163..1022 | y 127..1022 | y 127..1022 |
| Rail content x | 69..339 | 44..364 (entries) | 44..364 (entries) |
| First rail entry | y ~236 | y 175..231 | y 175..231 |
| Row 1 | y 322..397, x 453..1842 | y 261..337, x 429..1867 | y 261..337, x 429..1867 |
| HostMargin | x 453.. | x 408..1888 | x 408..1888 |

The cause is section 3.4's arithmetic. It claims `PanelRaised` insets its child by `32 + 1 = 33` px per side
because the `StyleBoxTexture` never had explicit content margins. Measured, the inset is **8 px per side**
(400 -> 408 on the host, 24 -> 32 on the rail), i.e. the painted frame band plus the 1 px expand margin. Every
box in 3.1 is therefore 25 px per side narrower than the table says, which also explains why the header band
is set by the title block (87 px) rather than by the credits housing (123 px in the table).

I followed the mockup, as the brief instructs ("it is your visual reference ... port from it"), and kept the
frozen constants from 12.3 (safe margin 24, band separation 16, header min height 76, rail width 360, rail
entry 56, rail/host inner margins 12/20, row 76 + 6, columns 40/130/110/160). The shipping screen and the
mockup agree on **every** number I measured, which is the strongest available statement that the shell is the
approved composition. What I did not do is retune the layout to section 3.1's table, because that table
disagrees with the artifact it was supposedly measured from.

Consequence worth knowing for the next wave: because the inset is 8 and not 33, the host's content box is
1440 px wide, not 1390, and every row is 1438 px wide starting at x 429.

---

## 4. Judgement calls

1. **`get_node_or_null(^"PlayerProfile")` as written cannot work.** A bare `NodePath` resolves against the
   caller, so from the station or a panel that call looks for a *child* named `PlayerProfile` and always
   returns null. I kept the intent (resolve the autoload by name, typed through
   `preload("res://autoload/player_profile.gd")`) but anchored the lookup at the tree root, the same way
   `router.gd` and `audio_manager.gd` resolve their services. Both files document it at the call site.
2. **The panel contract is mine**, because the spec defines the panels' content but not their interface with
   the host. Documented in `station.gd`'s header, and this is what the three later panels must expose:
   `signal status_requested(message: String, danger: bool)`, `signal launch_requested()`,
   `func refresh_profile(key: StringName) -> void`, `func focus_primary() -> void`,
   `func disarm() -> bool` (optional, used by `ui_cancel` step 2).
3. **Panel scenes do not bake the theme.** Section 3.12's rule is for *routed screen and overlay roots*;
   a panel that baked `vajb_theme.tres` would override the Router's live (scaled) theme in its own subtree and
   silently break `ui_scale`. The panel inherits the station's live theme. F6 on the panel alone is unstyled
   by design.
4. **Rail entries and placeholder panes are built in script** (the mockup's own construct, and the rail needs
   runtime `pressed` connections). The placeholder joins the `station_placeholder` group so a verifier can
   tell an offline module from a loaded one without reading text. Rail buttons are named
   `OutfittingEntry` / `ShipyardEntry` / `UpgradesEntry` / `LaunchEntry` / `LogOutEntry`, and the panes keep
   the spec's names (`Outfitting`, `Shipyard`, `Upgrades`, `Launch`), so the two never collide in a
   `find_child` (they did before I named them, and it bit the probe).
5. **LAUNCH routing is declared but not yet reachable by UI.** The shell implements the handoff
   (`_on_launch_requested` -> `route_requested(&"loading", {destination: &"game"})`, plus the boost and jump
   cues and `stop_ambience`), and wires it to a loaded panel's `launch_requested` signal. Because
   `ui/station/launch_panel.tscn` is the later worker's file and does not exist, the LAUNCH module currently
   shows the offline placeholder and nothing can fire that signal. I did not fabricate a launch control in
   the shell: that would duplicate section 5.4's briefing, the cargo hold and the two-press control.
   LOG OUT -> `main_menu` **is** reachable now (measured: `[intents] ... main_menu { }`).
6. **Keys are read directly.** `PageUp`/`PageDown` come from `key.keycode` and the module cycle from
   `InputEventJoypadButton`, because `station_prev_module` / `station_next_module` are not in the input map
   and `project.godot` is off limits. Same shape as the mockup, and spec section 10 says so.
7. **Refusal copy resolves the price from the catalogue.** `purchase_failed` carries only
   `(reason, id)`, so `REFUSED · NOT ENOUGH CREDITS · <cost> NEEDED` looks the entry up in
   `StationCatalog`. In every shipping path that is exactly the cost the panel passed, so the copy is
   correct; a synthetic call with a bogus cost shows the catalogue price instead (visible in the probe log,
   where `999999` renders as `120 NEEDED`). `already_owned` is disambiguated to
   `ALREADY INSTALLED` / `ALREADY OWNED` / `ALREADY THE ACTIVE HULL` by asking the catalogue and the profile.
8. **Ammunition has no `LOCKED` state.** Section 5.6's "the STATUS cell reads LOCKED" cannot apply to
   OUTFITTING, whose STATUS vocabulary section 5.1 freezes as EMPTY / IN STOCK / AT CAP / OVER CAP.
   Unaffordability is presented on the ammo pane through the price colour only; `LOCKED` belongs to SHIPYARD
   and UPGRADES.
9. **The disabled `STOCK UNAVAILABLE` row is implemented for a malformed catalogue entry** (missing id, name
   or rounds) rather than for "an id the catalogue does not know". The second reading requires enumerating
   the profile's ammo ids, which only `PlayerState.WEAPONS` can supply, and section 12.4 forbids the station
   importing `PlayerState`. Flagging it rather than bending that rule.
10. **The idle machinery layer is not played.** Section 11 asks for
    `play_sfx(&"sfx_station_machine_loop_01")` "at low volume under the ambience"; `play_sfx` has no volume
    parameter and the brief forbids changing its signature, so calling it would play the loop at full SFX
    bus level. Gap, not an oversight.
11. **The station bed is stopped on the way out of both exits.** Section 11 lists `stop_ambience` only for
    LOG OUT; I also stop it on the LAUNCH handoff, because a docking-ring bed must not follow the player into
    space. One line, and the closest existing convention.
12. **`loading.gd` maps the destination through `UIPaths.route_exists`** and falls back to `&"game"` for a
    destination that has no route. `&"station"` is forwarded like any other route (that is what the file
    already did, and it is what makes the station legible to the bridge); the fallback only removes a stall
    where an unknown destination left the bridge parked on its own fade. No existing route changes behaviour.
13. **The header/row column mismatch is inherited, not introduced.** The `HELD / MAX` cell grows to fit its
    state-line caption while the header cell stays at the declared 130 px, so the header label sits 15 px
    (ui_scale 1.4: 69 px) right of the values it labels. The mockup has the identical construct and I measured
    the same behaviour in it (its Held cell is 130 px while the caption is short, and grows when the caption
    is `CAPACITY IS ADVISORY`). Fixing it means choosing between widening the constant to 143, shortening the
    copy, or letting the header follow the widest row cell, all of which are design decisions. Left as the
    mockup has it, reported here.
14. **Panel rows carry named nodes** (`RowInner`, `TitleBox`, `Icon`, `Held`, `Price`, `Status`, `Value`,
    `Caption`). Not in the spec, but the spec's own section 4 node tree names these constructs and the names
    are what let the probe (and any future verifier) address a cell without guessing.
15. **`_set_status(STATUS_DOCKED, false)` on every module switch.** The mockup keeps the strip untouched;
    resetting it keeps the footer honest about the current module. One line, no design change.

---

## 5. What I could not verify

1. **A rendered frame of the shipping screen.** Headless has no renderer, and using the open editor
   (godot-ai `editor_screenshot`) would have hijacked the editor the parallel worker is using. Verification 3
   explicitly allows a measured geometry dump, which is what section 2.5 is. I did look at the approved
   mockup's own preview (`previews/d5_station_outfitting_1920x1080.png`, downscaled and cropped with Pillow in
   the OS temp dir) to read the approved look, and I measured the mockup scene directly, but no pixel of my
   screen was inspected.
2. **The SCROLL cue end to end.** The call site is a `scroll_started` connection on the panel's
   `ScrollContainer`; the probe never scrolled, so the cue was not heard. The file resolves
   (`ui/ui_scroll -> ui_scroll_01.ogg`, section 2.8) and the signal exists (the connection succeeded with no
   error), but the gesture itself is untested.
3. **Gamepad and mouse behaviour.** Shoulder-button module cycling, mouse hover and click on a row, and the
   pointer cursor are wired but were not exercised; only keyboard-level focus movement and a synthetic row
   press were.
4. **The station as the `current_scene` in a real player session.** The probe's geometry came from a station
   instantiated under `/root`; the flow test proved the routed station is the same scene and built 4 panes,
   but the geometry dump was not repeated on the routed instance.
5. **`ui_scale` through `SettingsManager`.** The 1.4 run scales the theme with Router's own math
   (mirrored in the probe) rather than by changing the setting, because `user://settings.cfg` has to stay
   byte-identical. The engine path is `Router._scale_font_sizes()`, which I read and did not modify.
6. **`RESOLUTION`/display behaviour**, which is not this screen's business.
7. **The three missing panels**, obviously, and therefore SHIPYARD / UPGRADES / LAUNCH's own content.

---

## 6. Handoff notes for the next wave

- Copy `outfitting_panel.tscn` / `.gd` for the other three. The panel contract is in section 4.2 above.
- `launch_panel.tscn` must emit `launch_requested` for the shell to route to
  `loading{destination: &"game"}`; the shell owns the cues and the ambience stop.
- `profile_changed` is forwarded to every loaded panel through `refresh_profile(key)`; the OUTFITTING panel
  filters on `&"credits"` and `&"ammo"`. SHIPYARD wants `&"ships"`, UPGRADES `&"upgrades"`, LAUNCH `&"cargo"`.
- A panel that returns `true` from `disarm()` takes over `ui_cancel` step 2 (the LAUNCH arming beat).
- The `PanelRaised` inset is 8 px, not 33 (section 3). Any layout arithmetic copied from STATION_HUB 3.1
  will be 25 px per side out.
- `_mockup_station.*` is untouched and still runs clean headless, as section 12.6 asks, for the cleanup step.
