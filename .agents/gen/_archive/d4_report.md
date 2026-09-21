# D4 report - main menu v2 mockup and spec

Date: 2026-09-18. Worker: designer (medium: a live Godot 4.7 UI scene).
Brief: `.agents/gen/d4_task.md`.

## 1. What was built

| Action | Path | Size |
|---|---|---|
| create | `vajb-orbit/ui/screens/_mockup_main_menu.tscn` | 12180 bytes, 396 lines |
| create | `vajb-orbit/ui/screens/_mockup_main_menu.gd` | 10483 bytes, 301 lines |
| create | `docs/design/MAIN_MENU_V2.md` | the coder contract for the shipping screen |
| create | `.agents/gen/d4_report.md` | this file |
| create (engine sidecar) | `vajb-orbit/ui/screens/_mockup_main_menu.gd.uid` | written by Godot itself when the headless run scanned the project, exactly as every other `.gd` in `ui/` has one |
| create (preview, not a contract artefact) | `.agents/gen/previews/menu_v2_mockup_1920x1080.jpg` | 123123 bytes, frame 60 of the 1920x1080 movie render, downscaled |

Nothing else was written. `main_menu.tscn`, `main_menu.gd`, `menu_button.tscn`,
`menu_button.gd`, `glow_underlay.gd`, `vajb_theme.tres`, `grain.tres`, `paths.gd`,
`screen.gd`, every autoload, `project.godot`, `addons/` and the parallel designer's
`_mockup_station.*` were not edited. No new theme item, asset, autoload or `class_name`
was introduced.

The scene is a standalone `Control` (not `Screen`), bakes `vajb_theme.tres`, reads every
colour from the `Tokens` type, uses no autoload, no `Router`, no `class_name`, no
`_process` and prints nothing. Composition: one full-rect `MarginContainer` safe area
(margins 96/64/96/48) holding three bands; the header band carries the wordmark, the
middle band carries a nine-patch metal housing (380 x 314) with a neutral company badge,
a `COMMAND` caption and three 280 x 56 verb plates in rows with 6 x 48 px focus ticks, the
footer band carries a focus read-out and the version stamp. Two script-built `void_base`
scrims (left, bottom) and a resize-corrected ember pulse sit over the vista. Esc toggles a
local stand-in for `quit_confirm.tscn`.

## 2. Commands run, with their output

### 2.1 Mandated headless check (final state of the scene)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_main_menu.tscn --quit-after 300
```

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
```

**Exit code 0.** Run twice during the task: once on the finished scene before any render pass, and once
again after all four deliverables were written. Identical output both times.

### 2.2 Control run, to attribute the one stdout line

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after 300
```

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
```

The project's own main scene (`boot.tscn`) emits the same line, so it comes from the
vendored `addons/godot_ai/` autoload and not from the mockup. The scene itself prints
nothing; the mockup is not the source of that line.

### 2.3 Real-renderer run, windowed (21:9 case)

```
powershell -Command "Start-Process -FilePath 'C:\Godot_4_7_2\Godot_v4.7.2-stable_win64.exe' -WorkingDirectory 'G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit' -ArgumentList '--always-on-top','--resolution','1280x720','--position','2050,300','res://ui/screens/_mockup_main_menu.tscn' -PassThru | Select-Object -ExpandProperty Id | Out-File -Encoding ascii 'C:\Users\Kamil\AppData\Local\Temp\vajb_d4\pid.txt'"
```

Window rectangle, measured with `user32!GetWindowRect` against the returned PID (22576,
then 21292):

```
RECT 0,0 to 3440,1440
```

The project's `SettingsManager` autoload applies `user://settings.cfg` at startup, and
that file held `display_mode=1` (exclusive fullscreen) with `resolution=Vector2i(2560, 1440)`,
so the CLI `--resolution` / `--position` were overridden and the game covered the whole
3440 x 1440 panel. Under `canvas_items` + `expand` that is a 2580 x 1080 viewport at scale
1.333, i.e. the **21:9 case**. Screenshot (region 190,140,1320,790, then a full-monitor
capture) taken with the vision skill's `capture.py`; both were inspected. Result: the rail
stayed anchored to the left safe margin (its left edge at about 4 percent of the frame
width, i.e. 96 viewport px), the logo stayed top-left, the read-out stayed bottom-left and
the version stamp stayed bottom-right, and the extra 640 px of width all sat to the right
of the rail. The ember pulse sat on the wreck. This is the section 3.2 "extra width" rule
of `MAIN_MENU_V2.md`, observed rather than asserted.

### 2.4 Deterministic 1920 x 1080 render (the 16:9 target), and the measurement suite

`--write-movie` forces the movie to the project's base viewport resolution, so this is the
exact design target:

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --scene res://ui/screens/_mockup_main_menu.tscn --write-movie "C:/Users/Kamil/AppData/Local/Temp/vajb_d4/movie.png" --quit-after 120
```

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon RX 6800 XT

Movie Maker mode enabled, recording movie in 1920×1080 @ 60 FPS...
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
--------------------------------------------------------------------------------
Done recording movie at path: C:/Users/Kamil/AppData/Local/Temp/vajb_d4/movie.png
120 frames at 60 FPS (movie length: 00:00:02:00), recorded in 00:01:41 (1% of real-time speed).
```

**Exit code 0.** The first pass was rendered while the settings file still forced exclusive
fullscreen at 2560 x 1440, and the frames came out with the canvas translated 348 px to the
left (measured: the three plates ended at x 78 instead of x 426, the footer read-out was
off-screen, the version stamp absent). That is a Movie Writer plus forced-fullscreen
interaction, not a layout fault: with the display mode neutralised the same movie renders
pixel-correct (below). The display-mode patch was applied to `user://settings.cfg` only,
never to a project file, and was reverted (section 2.6).

Second pass, with `user://settings.cfg` temporarily set to `display_mode=0` (windowed) and
`resolution=Vector2i(1920, 1080)`:

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --scene res://ui/screens/_mockup_main_menu.tscn --write-movie "C:/Users/Kamil/AppData/Local/Temp/vajb_d4/w2.png" --quit-after 60
```

```
Movie Maker mode enabled, recording movie in 1920×1080 @ 60 FPS...
Done recording movie at path: C:/Users/Kamil/AppData/Local/Temp/vajb_d4/w2.png
60 frames at 60 FPS (movie length: 00:00:01:00), recorded in 00:00:41 (2% of real-time speed).
```

**Exit code 0**, 60 frames. Measurement of the final frame (`w200000059.png`, 1920 x 1080),
with Pillow and NumPy, spec value against measured value:

| Element | Specified | Measured in the render | Verdict |
|---|---|---|---|
| Logo box / ink | 560 x 176 at (96, 64) | ink bbox x 101..648, y 64..224 | exact (the 3 px inset is the `AtlasTexture` 12 px pad at 0.286 scale) |
| Rail housing frame | 380 x 314 at (96, 469) | metal border columns 96..474, rows 469..781 | exact |
| Verb plate row 1 | 280 x 56 at (146, 559) | plate band x 146..425, top row 559 | exact |
| Play plate label | 34 px `text_primary` centred at x 286 | "PLAY" ink x 248..326 (centre 287), peak luminance 208.1 (= `#c9d1dc`) | exact |
| `OPTIONS` / `EXIT` rows | tops at 629 / 699 | label ink present in the y 640..704 and y 704..768 bands | consistent, but the band analysis was quantised at 16 px, so rows 2 and 3 have no sub-pixel top measurement |
| Focus tick (row 1) | 6 x 48 at (124, 563) | accent pixel bbox x 124..129, y 563..610, 288 px = 6 x 48 of exact `#e8622a` | exact |
| Focus read-out | starts at x 96, 14 px `text_primary` | ink x 97..264, y 1017..1026, peak 208.1 | exact |
| Version stamp | right edge 1824, 13 px `text_dim` | ink x 1724..1820, y 1018..1028, peak 115.2 (= `#6b7484`) | exact |
| Badge | 40 x 46 at (124, 497) | bright art x 124..165, y 500..547 | exact |
| Caption `COMMAND` | starts at x 176, 16 px `text_dim` | dim ink from x 177, peak 115.2 | exact |
| Ember pulse centre | (1543, 682), computed from the audited anchor (0.791, 0.618) through the `KEEP_ASPECT_COVERED` mapping of the 2048 x 1152 vista | warm centroid of the rendered wreck (1544, 677), 4992 warm pixels | within 5 px; the additive pulse lands on the wreck |

Contrast ratios measured on the same frame (WCAG relative luminance against the local
background with the text pixels excluded): read-out **12.08:1**, verb labels **7.87:1**,
caption **4.06:1**, version stamp **3.88:1**, wordmark peak **16.24:1**. The 3.88:1 stamp is
the one finding below the `UI_SPEC.md` section 1 floor; the cause was isolated to the film
grain's additive +10.2 luminance lift (measured across four regions, model fit within
0.5 luminance), and even a fully black backing caps the stamp at 4.17:1 because `text_dim`
is luminance 115. It is written up in `MAIN_MENU_V2.md` section 6 item 2 and is open
question 4.

### 2.5 Asset verification (every `res://` path in the scene, resolved on disk)

```
OK   res://assets/env/env_menu_bg.png            2819956
OK   res://assets/fx/fx_ember_pulse.png          2637004
OK   res://assets/ui/logo_vajb_orbit.png         2711747
OK   res://assets/ui/ui_insignia_neutral.png     1115179
OK   res://assets/ui/ui_panel_frame.png            11571
OK   res://ui/components/menu_button.tscn            923
OK   res://ui/screens/_mockup_main_menu.gd         10483
OK   res://ui/theme/grain.tres                       284
OK   res://ui/theme/vajb_theme.tres                24314
```

9 of 9 exist, 0 missing. Every art path appears in `ASSET_AUDIT.md` section E.1
`MENU_V2_SHORTLIST` or section F; the four plates used by the verb buttons are referenced
through the theme (`MenuButtonPlate`), not by the scene, and are audited in the same
section. No asset filename was invented.

### 2.6 `user://settings.cfg` round trip

Patched only for the 16:9 movie pass, from a byte copy, and reverted:

```
backup sha c251e58c6a3fa9a9   -> patched sha 07ee9100f2806c25   -> restored sha c251e58c6a3fa9a9
restored file: [graphics] display_mode=1  resolution=Vector2i(2560, 1440)
```

The file is app state, not a project file, and it is byte-identical to how it was found.

### 2.7 Static audit of the two new files

```
theme_override... lines in the scene: margin constants + one StyleBoxEmpty + three theme_type_variation
                                       (SectionHeader, Version, DialogTitle); no font-size override
hex-like colour literals in the scene: none
hex literals anywhere (scene + script):  []
colour literals in the scene: Color(1,1,1,0.25), Color(1,1,1,0.08), Color(1,1,1,0.0) x3
                                       (white-with-alpha for opacity only, the same pattern
                                       main_menu.tscn already uses for the ember and the grain)
func _process in the script: False
autoload references in the script: none (the only match is the word "Router" in the header comment)
class_name in the script: none (same header comment)
```

## 3. What could not be verified, and what limits the evidence

1. **4:3 (extra height) was reasoned, not rendered.** The 21:9 case was rendered and
   confirmed; 4:3 needs a 1440 x 1080 window, which the settings-forced display mode
   prevents and which I did not chase further, since the container structure makes the
   extra height land only in `MiddleBand` (the rail stays centred). The section 3.2 rule is
   a derivation from the bands, not a photograph. The ember re-anchor formula **is** exact
   under vertical cropping (verified at 16:9 and 21:9, where the crop is vertical); the
   4:3 crop is horizontal and was only computed, not seen.
2. **`ui_scale` 1.4 was reasoned, not rendered.** `SettingsManager` keeps its file in
   `user://` and the mockup may not read autoloads, so a 1.4 pass needs a settings-file
   patch plus a re-render. The mechanism (theme font-size items only, container-driven
   heights, a 14 percent vertical plate stretch) is derived from the theme and the
   container rules and is written up in `MAIN_MENU_V2.md` section 12; the plate stretch
   itself was not measured.
3. **The `--write-movie` frames are the game's viewport, not the editor's.** Both render
   passes ran a second Godot instance; the editor (PID 9048) was neither used nor touched,
   and no write to it was attempted, so "the owner sees this in the editor" is still
   unproven by me. The mockup is a plain scene and can be opened with F6.
4. **The insignia's white matte fringe (audit anomaly C3) is present in the render.** The
   badge is small (40 x 46) so the fringe reads as a rim highlight on the hex plate, but it
   is there and the defringe pass (audit recommendation 4) has not run.
5. **The audio hooks are specified, not exercised.** The mockup makes no audio calls by
   design. Two of the cues named in `MAIN_MENU_V2.md` section 11 (`CONFIRM`, `SCROLL`)
   need new `UiCue` members before they resolve; `play_music(&"mus_menu_theme")` resolves
   today but plays a bed that clips (audit anomaly C7).
6. **The `godot-ai` MCP was not used at all.** Deliberate: `project_run` on a custom scene
   can switch the editor's open scene, and a parallel designer is working in the same
   folders. All verification went through separate engine instances, so the editor session
   was never disturbed.

## 4. Notes for whoever approves this

- `MAIN_MENU_V2.md` has six open questions, the load-bearing ones being the housing (keep
  the metal rail or drop it) and the 3.88:1 version stamp.
- The mockup takes about 0.86 s to present itself fully; the backdrop and both scrims are
  at full opacity from frame 0, so a screenshot at any time is presentable.
- There is one trap for whoever wires the shipping screen: do not use
  `theme_type_variation = &"PanelRaised"` for the housing until the panel frame is
  regenerated (audit G3), because the theme's 32 px patch margins sit on a 7 px frame.
