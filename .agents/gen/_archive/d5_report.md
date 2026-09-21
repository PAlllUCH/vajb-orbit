# D5b report - finishing the station hub mockup

**Date:** 2026-09-18 (D5b continuation of D5). **Worker:** designer, medium = Godot 4.7 UI scene.
**Files written:**

| Path | Action | Size |
|---|---|---|
| `vajb-orbit/ui/screens/_mockup_station.gd` | edited in place (7 changes, section 3) | 45 273 bytes |
| `vajb-orbit/ui/screens/_mockup_station.tscn` | edited in place (2 changes) | 27 102 bytes |
| `docs/design/STATION_HUB.md` | created | 57 571 bytes |
| `.agents/gen/d5_report.md` | created (this file) | - |
| `.agents/gen/previews/d5_station_*.png` | 9 rendered/captured frames, 11.4 MB total | - |
| `.agents/gen/previews/d5_tools.py`, `measure.py`, `aspect_probe.py` | measurement and settings helpers used for every number below | - |

`.agents/gen/previews/` already held review sheets and the sibling menu preview (`sheet_*.jpg`,
`menu_v2_mockup_1920x1080.jpg`, `vanguard_rotations.jpg` and similar, 1.1 MB) from earlier phases. Those were
left untouched; the only files removed were the four `_probe_*` and six `_v_*` scratch images this session
created.

Nothing else was written. `STATION_SPEC.md`, `game/station_catalog.gd`, `autoload/player_profile.gd`,
`ui/theme/vajb_theme.tres`, `ui/screens/main_menu.tscn`, `_mockup_main_menu.*`, `ui/components/slot_button.gd`,
`project.godot` and `addons/` were **not** modified (all were read). `user://settings.cfg` was patched
temporarily for the aspect and ui_scale probes and **restored byte-for-byte** (section 7).

---

## 1. State inherited, and what was wrong with it

The previous D5 run left three files: a 26 983 byte scene, a 43 705 byte script and no docs. The inherited
work was substantially complete and correct: the four modules plus LOG OUT, the real catalogue names and
prices, the `PanelRaised` chrome, the three `ScrollContainer` lists, the `ItemList` manifest, the focus ring,
the two-press launch and the tween-only motion were all present and all rendered.

It was **not** correct in seven places. Six are real defects, one is the fix the previous run was mid-way
through when it died:

| # | Defect found | Fix |
|---|---|---|
| 1 | `_make_slot_plate()` applied the theme plate textures **before** the plate entered the tree, so `has_theme_stylebox()` could not resolve the root theme and every call was a no-op. The plates only rendered because a later `_refresh_plate_textures()` pass happened to run after the nodes were added. | `_make_slot_plate(parent, variation, size)` now adds the child first and then applies the textures; the `_apply_tokens()` refresh stays as the second pass for theme changes. |
| 2 | `CreditsPanel` was the only `PanelContainer` on the screen without `theme_type_variation = &"PanelRaised"` (it fell back to the flat `panel` box while the rail, host, preview and dialog used the framed one). | `theme_type_variation = &"PanelRaised"` in the scene. |
| 3 | The three list `ScrollContainer`s left `horizontal_scroll_mode` at the engine default, so a wider-than-panel row would have drawn an **unthemed** `HScrollBar` (the theme registers `VScrollBar` chrome only). | `horizontal_scroll_mode = 0` (disabled) on `OutfittingScroll`, `UpgradesScroll`, `ShipScroll`. |
| 4 | The launch `Fade` rect tweened `color:a` to 1.0 over an opaque **black** literal, an untokenised colour on a blackout that covers the whole screen. | `_apply_tokens()` now pushes `Tokens/void_fade` into the rect (alpha 0); the tween only animates alpha. |
| 5 | Row icons started at `modulate.a` 1.0 but the hover-out tween returned them to `ROW_ICON_IDLE_ALPHA` 0.72, so the resting state depended on whether the mouse had ever crossed the row. | `_make_row()` sets the initial alpha to `ROW_ICON_IDLE_ALPHA`, matching the tween target. |
| 6 | Switching to LAUNCH dropped focus on a row of the module that had just been hidden (LAUNCH has no list rows), so the focus ring disappeared and keyboard navigation stalled. | `_focus_primary_row()` falls back to `%LaunchButton` when the module owns no rows. |
| 7 | No way to render a specific state without input, so "three module states" could not be evidenced. | Two inert debug arguments: `--station-module=<outfitting\|shipyard\|upgrades\|launch>` and `--station-credits=<int>`. With neither argument the screen is the shipping-intent composition and prints nothing. |

**Verdict on the previous run's last finding.** `ui/components/slot_button.gd` lines 89-103 (`_apply_plates`)
**has** landed. Its file mtime is `2026-09-17 21:44`, i.e. before the D5 run started (03:18 on 2026-09-18), so
it is Phase C code, not a D5 fix: the mechanism it documents (a `TextureButton` has no theme stylebox items, so
`SlotButtonWeapon/styles/*` is never read by the engine and the textures must be copied onto the node) is
exactly what the mockup had to replicate. The D5 run replicated it but in the wrong order (defect 1). Both are
now correct and proven by measurement (section 4.3).

A dead end worth recording: I first tried to verify `ui_scale` 1.4 with a local stand-in that duplicated
`Router._scale_font_sizes` in the mockup. Probing showed the stand-in *did* set the scaled theme
(`HeroTitle` 48 -> 144 at scale 3.0) but the render never changed, because `Router._bind_entry_scene()`
reassigns its own live theme to the entry scene's root Control one frame after `_ready`. That also revealed the
right answer: **`ui_scale` needs no stand-in**, Router hands this scene its live theme at runtime. The
stand-in was deleted and the verification is done through the real mechanism (section 4.4).

## 2. Requirement audit against `.agents/gen/d5_task.md`

| # | Requirement | Verdict | Evidence |
|---|---|---|---|
| 1 | Four modules plus LOG OUT, navigation pattern proposed and justified | MET | 4 rail entries + a session entry for LOG OUT in the render; pattern and justification in `STATION_HUB.md` section 2 |
| 2 | Real data, stub state: 5 ammo packs, 4 ships, 6 upgrades with the exact names and prices from `STATION_SPEC.md` | MET | All 15 rows render the spec's names and prices; `Laser Cells 120`, `Cannon Shells 180`, `Rocket Pod 240`, `Mine Rack 200`, `Plasma Cells 320`, `Lancer 9 000`, `Vanguard 18 000`, `Bulwark 36 000`, `Obliterator 72 000`, `Reactor Mk2 4 200`, `Shield Amplifier 5 200`, `Ion Drive 3 800`, `Deep Scanner 4 600`, `Cargo Expansion 3 000`, `Repair Drone Bay 6 800` |
| 3 | Credits readout | MET | `%CreditsPanel` housing with `%CreditsValue`; `4 900` measured (ink 638 px) and `0` in the zero-credit frame (ink 466 px) |
| 4 | Owned / locked states, affordable / unaffordable treatment, and what happens when the player cannot afford something | MET | One frame shows `OWNED` + `ACTIVE` + 2 x `LOCKED` (shipyard) and `INSTALLED` + `AVAILABLE` + `LOCKED` (upgrades); the refusal path writes `REFUSED · NOT ENOUGH CREDITS · <cost> NEEDED` into the status strip and pulses the price cell and the credits housing (`STATION_HUB.md` 5.6) |
| 5 | At least two states per module | MET | OUTFITTING: `AT CAP`, `IN STOCK`, `OVER CAP`, `EMPTY`. SHIPYARD: `ACTIVE`, `OWNED`, `LOCKED`. UPGRADES: `INSTALLED`, `AVAILABLE`, `LOCKED`. LAUNCH: 3 occupied + 2 disabled cargo plates, an `ItemList` with a selected row, `IN SERVICE` vs `SET ACTIVE`/`BUY` action text |
| 6 | Ship preview at a size that reads as a ship, with the stat rows beside it | MET | 480 px wide draw of the real `_side` sprite (423 px of measured hull ink), with `HULL/SHIELD/CARGO/HARDPOINTS` compared `SELECTED` vs `ACTIVE` in two 110 px right-aligned columns |
| 7 | `PanelRaised` for panels, `ItemList` and `ScrollContainer` chrome for lists | MET | 5 `PanelRaised` containers (rail, host, preview, credits, dialog); 3 themed `ScrollContainer` lists with horizontal scrolling disabled; 1 themed `ItemList` (selected band measured at `metal_mid` luminance 49.6) |
| 8 | Container-driven responsive layout, `size_flags` named, 21:9 and 4:3 behaviour | MET | No absolute placement except the centered dialog overlay; measured at 2560x1080 and 1440x1080 (section 4.5); every flag named in `STATION_HUB.md` 3.3 |
| 9 | Motion table, Tween only, killed in `_exit_tree()` | MET | 19 motion beats tabulated with measured durations; `_tweens` array pruned and killed in `_exit_tree()`; no `_process` anywhere (grep evidence in section 6) |
| 10 | Keyboard and pad first: focus traversal, one focus ring, Escape behaviour, a visible selected row | MET | Ring measured as a single 1390x76 outline in exact `accent_danger_bright`; selected row also changes background; pad shoulders cycle modules; Escape chain in `STATION_HUB.md` section 2 (traversal order derived from tree order, see section 8) |
| 11 | `ui_scale` correct at 1.0 and 1.4, theme items only, every item named in the spec | MET | No `add_theme_font_size_override` / `theme_override_font_sizes` in either file; measured title ink 36 -> 50 px at 1.4 through Router's live theme; all 8 variations named in `STATION_HUB.md` section 6 |
| 12 | Root is a full-rect `Control` baking the theme | MET | `[node name="Station" type="Control"]`, `anchors_preset = 15`, `theme = ExtResource("2_vajb_theme")` |
| 13 | No hex literals; colours from `Tokens` | MET | Script: zero hex literals, all colour through `get_theme_color(token, &"Tokens")`. Scene: one neutral `modulate = Color(1, 1, 1, 0.08)` on the grain layer (the same idiom `_mockup_main_menu.tscn` uses) and the pre-first-frame placeholder `color = Color(0, 0, 0, 0)` on the invisible launch fade, which is overwritten from `Tokens/void_fade` in `_ready` |
| 14 | No `class_name`, no autoload calls, no `Router` calls | MET | grep: the only occurrences of `PlayerProfile` and `Router.` in the script are in comments (section 6) |
| 15 | Must render a complete, presentable screen with zero input and print nothing | MET | Four 1920x1080 renders with zero input; stdout of every run carries only the vendored `[godot_ai game_helper] registered mcp capture` line that `boot.tscn` also emits |
| 16 | Headless check exits 0 with clean stdout | MET | exit 0 (section 3) |
| 17 | `docs/design/STATION_HUB.md` with the briefed sections | MET | All 14 briefed sections present (Intent, Navigation, Composition, Node tree, Per-module, Type scale, Art map, Motion, Focus/input, Audio, Implementation notes, Open questions) plus a verification section |
| 18 | `.agents/gen/d5_report.md` with the audit, commands, exit code, measurements, asset list | MET | This file |

No requirement is MISSING. Two are PARTIAL in the sense that the *verification* is narrower than the feature:
the module-switch/hover/refusal/launch animations and the focus traversal order are documented but not
frame-captured (section 8).

## 3. Commands and outputs

### 3.1 Headless load check (the contract check)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_station.tscn --quit-after 300
```

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
FINAL_HEADLESS_EXIT=0
```

Run again after the last source edit (03:51:25): **exit code 0**, stdout clean. The single helper line comes
from the vendored `addons/godot_ai/` autoload, not from the mockup.

Argument parsing verified with the same scene plus flags:

```
... res://ui/screens/_mockup_station.tscn --station-module=launch --station-ui-scale=1.4 --station-credits=0 --quit-after 60
EXIT_ARGS=0
```

Godot does not warn on the unknown `--station-*` arguments; `OS.get_cmdline_args()` receives them
(`args=["--scene", "res://ui/screens/_mockup_station.tscn", "--station-module=shipyard", "--station-ui-scale=3.0"]`).

### 3.2 Renders (the movie writer, 1920x1080, deterministic)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --scene res://ui/screens/_mockup_station.tscn --station-module=outfitting --write-movie "C:/Users/Kamil/AppData/Local/Temp/vajb_d5/f_outfitting.png" --quit-after 48
```

```
Movie Maker mode enabled, recording movie in 1920x1080 @ 60 FPS...
Done recording movie at path: C:/Users/Kamil/AppData/Local/Temp/vajb_d5/f_outfitting.png
48 frames at 60 FPS (movie length: 00:00:00:48), recorded in 00:00:24 (4% of real-time speed).
```

Exit code 0. Six runs, each 48 frames:

| Run | Argument | Frames | Exit |
|---|---|---|---|
| `f_outfitting` | `--station-module=outfitting` | 48 | 0 |
| `f_shipyard` | `--station-module=shipyard` | 48 | 0 |
| `f_upgrades` | `--station-module=upgrades` | 48 | 0 |
| `f_launch` | `--station-module=launch` | 48 | 0 |
| `f_nocredits` | `--station-credits=0` | 48 | 0 |
| `f_shipyard14` | `--station-module=shipyard` with `user://settings.cfg` `ui_scale=1.4` | 48 | 0 |

Determinism check: the same run repeated 40 minutes apart produced byte-identical frames
(`md5 f_outfitting00000047.png = 661eda3cc72e1f2f923ada2736e49836` both times), so the frame-to-frame
comparisons below are meaningful. The pre-edit baseline differs
(`6474cd73cf47af693fa1813d6f39a08d`), which confirms the seven fixes actually changed pixels.

### 3.3 Aspect probes (windowed native captures)

`--write-movie` always renders the project's 1920x1080 base viewport, so 21:9 and 4:3 were captured from real
windows instead (`previews/aspect_probe.py`, which launches the build, grabs the window's client rect with
`mss`, then terminates the process it started):

```
py -3.14 ".agents/gen/previews/aspect_probe.py" 2560 1080 "C:/Users/Kamil/AppData/Local/Temp/vajb_d5/wide_native.png" --station-module=shipyard
client 60,60 2560x1080
saved .../wide_native.png bytes=1893989

py -3.14 ".agents/gen/previews/d5_tools.py" resolution 1440 1080
py -3.14 ".agents/gen/previews/aspect_probe.py" 1440 1080 .../tall_native.png --station-module=shipyard
client 60,60 1440x1080
saved .../tall_native.png bytes=1045545
```

(The first 4:3 attempt came back 2560x1080: `SettingsManager` applies the stored `user://settings.cfg`
resolution at startup and overrides the CLI `--resolution`. The second attempt set the stored resolution
first, which is also the path a real player takes.)

### 3.4 Asset verification

Every `res://` path in the scene and the script, resolved on disk:

```
py -3.14 -c "<regex over both files, os.path.isfile per path>"
OK  res://assets/icons/icon_ammo_laser_48.png
OK  res://assets/icons/icon_ammo_rocket_48.png
OK  res://assets/icons/icon_equip_drone_48.png
OK  res://assets/icons/icon_equip_engine_48.png
OK  res://assets/icons/icon_equip_extra_48.png
OK  res://assets/icons/icon_equip_generator_48.png
OK  res://assets/icons/icon_equip_module_48.png
OK  res://assets/icons/icon_equip_shield_gen_48.png
OK  res://assets/icons/icon_map_node_station_48.png
OK  res://assets/icons/icon_map_route_48.png
OK  res://assets/icons/tint/icon_cargo_data_core_48.png
OK  res://assets/icons/tint/icon_cargo_ore_48.png
OK  res://assets/icons/tint/icon_cargo_salvage_48.png
OK  res://assets/icons/tint/icon_credits_48.png
OK  res://assets/icons/tint/icon_hull_48.png
OK  res://assets/icons/tint/icon_logout_48.png
OK  res://assets/icons/tint/icon_weapon_cannon_48.png
OK  res://assets/icons/tint/icon_weapon_mine_48.png
OK  res://assets/icons/tint/icon_weapon_plasma_48.png
OK  res://assets/ships/ship_destroyer_side.png
OK  res://assets/ships/ship_fighter_side.png
OK  res://assets/ships/ship_gunship_side.png
OK  res://assets/ships/ship_vanguard_side.png
OK  res://assets/ui/ui_backdrop_hangar.png
OK  res://ui/screens/_mockup_station.gd
OK  res://ui/theme/grain.tres
OK  res://ui/theme/vajb_theme.tres
```

All 27 paths exist; there is no MISSING line. The theme-referenced chrome
(`ui_panel_frame.png`, the four `ui_button_plate_*`, the four `ui_slot_weapon_*`, the four `ui_slot_cargo_*`)
was verified through the theme file: `ui/theme/vajb_theme.tres` lists all 13 as `ext_resource` entries and
each is present on disk. The four ship sprites' native sizes: fighter 817x290, vanguard 905x387, gunship
859x385, destroyer 982x217. The audio files named in `STATION_HUB.md` section 11 were also verified on disk
(14 of 14 exist).

### 3.5 Settings patch and restore (user:// only)

```
before: [interface] hud_opacity=1.0  ui_scale=1.0 ; [graphics] display_mode=1  resolution=Vector2i(2560, 1440)
during: [interface] ui_scale=1.0 (then 1.4) ; [graphics] display_mode=0  resolution=Vector2i(1920,1080) (then 2560x1080, then 1440x1080)
after:  py -3.14 ".agents/gen/previews/d5_tools.py" restore
        -> [interface] hud_opacity=1.0  ui_scale=1.0 ; [graphics] display_mode=1  resolution=Vector2i(2560, 1440)
```

The file was backed up to `C:/Users/Kamil/AppData/Local/Temp/vajb_d5/settings.cfg.bak` before the first patch.
No project file was touched to change a display setting.

## 4. Measured evidence

All numbers come from `previews/measure.py` against the full-resolution frames.

### 4.1 Composition at 1920x1080

| Element | Expected | Measured | Verdict |
|---|---|---|---|
| Safe margin / rail left frame | 24, frame band from 23 | bright band x 23..30 | exact (24 - 1 px `expand_margin`) |
| Rail right frame | 384 | band x 377..384 | exact |
| Host left frame | 400 | band x 399..406 | exact |
| Host right frame | 1896 | band x 1889..1895 | exact |
| Panel top edge (rail and host) | after the header plus the 16 px separation | both panels start at y 163 (bright band 163..170), bottom band 1015..1021 | exact, and it exposed the content inset below |
| Row 1 | 76 tall at the top of the scroll | y 322..397, pitch 82 (76 + 6) | exact |
| Row 1 width | pane content box | x 453..1842 (1390 px) | exact |
| Column header strip | above row 1 | ink y 292..303 | consistent (16 px `SectionHeader`) |
| Pane footer | bottom of the pane content | ink y 957..965 | consistent (13 px `StationCaption`) |
| Footer status line | bottom band | ink y 1041..1052 | consistent (13 px `StationCaption`) |
| Credits housing | right safe edge | x 1709..1896, y 23..147 | exact |
| Ship list rows (SHIPYARD) | 340 px minimum width | focused row outline measured x 453..790, y 308..383 (338 x 76, 824 accent px against a 828 px perimeter) | exact |

Two derived facts that took a bisection to pin down, both worth carrying into the shipping screen:

1. **The header band is 123 px, not the 76 px its `custom_minimum_size` asks for.** The `CreditsPanel` is a
   `PanelRaised` `PanelContainer`, and a `StyleBoxTexture` with no explicit content margins uses its texture
   margins (32 px) as content margins, so the housing needs `16 + 43 + 64 = 123` px. The header grows to it and
   the Body therefore starts at 163, not 116. Everything below follows.
2. **`PanelRaised` insets its child by 33 px per side** (32 px content margin + 1 px `expand_margin`), before the
   screen's own `MarginContainer` margins. Evidence: the host's content box starts at
   `400 + 1 + 32 + 20 = 453`, which is exactly where the row outline measures; the rail's starts at
   `24 + 1 + 32 + 12 = 69`, which is where its entry plate art starts (measured x 71). This is written up as a
   gotcha in `STATION_HUB.md` section 3.4.

### 4.2 Container arithmetic checks

| Claim | Measured |
|---|---|
| Hardpoint strip = 7 plates of 48 with 4 px separation | cells at x 1484..1531, 1536..1583, 1588..1635, 1640..1687, 1692..1739, 1744..1791, 1796..1843: seven cells of **exactly 48 px**, pitch 52 |
| Cargo strip = 5 plates of 40 with 6 px separation | cells at x 452..491, 498..537, 544..583, 590..629, 636..675: five cells of **exactly 40 px**, pitch 46 |
| Enabled vs disabled plates differ | weapon cells 1-3 peak luminance 103.7, cells 4-7 peak 65.8 (the Lancer's 3 hardpoints); cargo cells 1-3 mean 57.4-76.3 with icon ink, cells 4-5 mean 36.2 (disabled art) |
| Focus ring is 1 px and only one exists | accent pixels in row 1: 2940 px, bbox x 453..1842 y 322..397, mean rgb (231.7, 97.9, 41.9) = `#e8622a`; the theoretical perimeter `2 x (1390 + 76) = 2932`. Only 2 solid columns (>= 8 accent px), i.e. the left and right verticals |
| Selected row has a second channel | selected row background (16.0, 21.0, 29.0) = `void_panel_raised` (the `Button` pressed box) vs unselected row (27.0, 32.0, 40.0) = `metal_dark` |
| `PanelRaised` frame thickness | 7 px painted art + 1 px `expand_margin` = an 8 px band on the rail (23..30), host (399..406), preview and dialog |
| ItemList selected band | mean luminance 49.6 across the band, = `metal_mid` (`#2a313c`), not the engine default blue |

### 4.3 The plate fix, proven

The previous run's finding was that slot plates only draw when their textures are copied onto the node. The fix
is now order-correct and the proof is pixel-level, in two independent places:

- **SHIPYARD**, `%HardpointSlots`: 7 cells of exactly 48 px at y 498..546, cells 1-3 at the `normal` art's
  brightness and cells 4-7 at the `disabled` art's brightness (the Lancer has 3 hardpoints). A null
  `texture_normal` would render nothing at all, and a `texture_disabled` that was never applied would render
  the bright art in all seven.
- **LAUNCH**, `%CargoSlots`: 5 cells of exactly 40 px at y 570..610, the first three carrying painted item
  icons (peak luminance 208) and the last two dimmer with no icon (`disabled`).

### 4.4 Contrast (WCAG relative luminance, measured not eyeballed)

| Text | Measured ink | Background | Ratio | Floor |
|---|---|---|---|---|
| Station name 48 px `HeroTitle` | (201, 209, 220) | (19.2, 20.2, 22.9) | **11.94:1** | 11:1 (`text_primary`) |
| Row title / values 18 px `StationValue` | (201, 209, 220) | (16, 21, 29) | **11.89:1** | 11:1 |
| Held / status cells 18 px | (201, 209, 220) | (16, 21, 29) | **11.89:1** | 11:1 |
| Column headers 16 px `SectionHeader` | (107, 116, 132) | (11, 13.4, 17) | **4.12:1** | 4.0:1 (`text_dim`) |
| Footer hint 13 px `StationCaption` | (107, 116, 132) | (13.5, 15.6, 19.4) | **4.05:1** | 4.0:1 |
| Row meta 13 px `StationCaption` | (107, 116, 132) | (16, 21, 29) | **3.89:1** | 4.0:1 nominal, see below |
| Unaffordable price 18 px `accent_danger` | (200, 71, 31) = `#c8471f` exact | (27, 32, 40) | **3.41:1** | below the floor, open question 1 |

The two `text_dim` readings below 4.0:1 are the token's own arithmetic plus the film grain's lift
(`text_dim` on `void_panel_raised` is 4.07:1 before grain), the same finding the sibling menu recorded for its
version stamp (3.88:1). They are labels and captions, never body text, which is what `UI_SPEC.md` section 1
permits. The orange price is the one genuinely new finding and it is written up as open question 1 in
`STATION_HUB.md`.

### 4.5 Responsive behaviour, measured

| Case | Window | Measured |
|---|---|---|
| 16:9 | 1920x1080 movie | rail x 23..384, host 399..1896, panels y 163..1021, row 1 y 322..397 |
| 21:9 | 2560x1080 capture | the rail's left frame band still starts at y 163 and the left edge at x 23..30, the rail's right edge stays 377..384, the host's left band stays 399..406, the host's right band moves to 2529..2536, row 1 is still y 322..397 |
| 4:3 | 1440x1080 capture | the rail's left frame band starts at screen y 122 (= 163 x 0.75) and at x 17..22 (= 24 x 0.75), the rail's right edge 283..287 (= 384 x 0.75), the host's right edge 1417..1422, the panels' bottom bands at screen y 1031..1036 = viewport y 1375..1381 against 1015..1021 at 16:9, i.e. the Body absorbed all 360 extra viewport pixels |

Conclusion: all extra width goes to `ModuleHost` (plus the two spacers inside the header and footer), all extra
height goes to `Body`, and nothing else on the screen moves. That is the exact claim in `STATION_HUB.md` 3.3.

### 4.6 `ui_scale`

| Measure | 1.0 | 1.4 | Ratio |
|---|---|---|---|
| `HeroTitle` ink height | 36 px (y 58..93) | 50 px (y 57..106) | 1.39 |
| `HeroTitle` ink width | 604 px | 604 px (clipped by the region) | - |
| Hardpoint plates | 7 cells of 48 px at y 498..546 | 7 cells present at y 590..640, no clipping | - |
| Layout | - | no container overflows; the rail's 22 px labels still fit their 56 px entries | - |

`ui_scale` reaches the screen through `Router._bind_entry_scene()`, which assigns `live_theme()` to the entry
scene's root Control; `_scale_font_sizes()` re-writes all 27 `FONT_SIZE_ITEMS` as `roundi(base x scale)`. The
mockup names a theme variation on every text node and has no per-node font-size override (grep in section 6),
so nothing is left behind.

### 4.7 Motion

| Beat | Evidence |
|---|---|
| Entry fade | near-white ink pixel count 0, 0, 0, 8406, 13151, 13157 at frames 0, 8, 16, 24, 32, 40, then flat; a monotone rise to a plateau at ~0.54 s, matching `ENTRY_SECONDS` 0.30 + 0.24 max delay |
| Entry partial state | at frame 16 the header ink peak is 174.6 against 208.1 settled (about 84 % of the way through the fade) |
| No startup flash | 0 near-white pixels in frames 0, 8 and 16, so the uninitialised `BackdropDim`/`Fade` rects never render white |
| Idle ambience (beacon) | beacon region mean rgb (78.7, 35.3, 24.0) at frame 20 -> (154.8, 57.7, 28.4) at 28 -> (181.0, 65.4, 29.9) at 36 -> (172.9, 62.9, 29.6) at 44: a looping rise and fall on a 2.4 s half period |

## 5. Requirement-by-requirement: what is NOT verified

Stated plainly, because the brief asks for measurements and not assertions:

1. **The interaction animations were not captured.** Module-switch cross-fade, row hover, the refusal pulse,
   the launch arm/fire sequence and the leave dialog are wired and their durations and curves are read from
   the code and tabulated in `STATION_HUB.md` section 9, but no frame evidence exists for them: the movie
   writer cannot inject input, and the editor's running game refused `game_eval` with
   `EVAL_GAME_NOT_READY: the game helper is registered but its main loop is not advancing` (the embedded game
   view was not focused), so I could not drive it.
2. **Focus traversal order is derived, not measured.** It follows Godot's default tree-order focus walk over
   the visible panes and the rail. I could not read `gui_get_focus_owner()` frame by frame for the same
   reason as item 1. What *is* measured is the ring itself and the selected-row background.
3. **`texture_normal` non-null is inferred from pixels, not asserted at runtime.** No runtime property read
   was possible (item 1), so the proof is that the plate art appears, in all four states, at the exact
   expected cell size and pitch. A null texture would render nothing and a missing disabled texture would
   render the bright art everywhere.
4. **The themed `VScrollBar` was never rendered.** Five or six 76 px rows never overflow a ~690 px scroll area
   at 1080p, so the bar is configured (theme items exist) but unexercised. It cannot be seen in any frame.
5. **The aspect captures are screen captures, not framebuffer dumps.** They are native client-area grabs of a
   windowed run (`mss`), which would carry a stale frame if the window had been occluded. The measurements
   matched the container arithmetic to the pixel (including the 0.75 scale of the 4:3 case), so the frames were
   live, but the method is worth knowing about.
6. **No audio was played.** Every cue named in `STATION_HUB.md` section 11 exists on disk, and the reachability
   gap (`UiCue` has only `CLICK`/`HOVER`, so `ui_confirm_01`, `ui_denied_01` and `ui_scroll_01` cannot be
   played by any current call) is recorded as an implementation note and open question 7.
7. **Text metrics were measured for a subset of labels** (title, row title/meta, held, status, column header,
   footer, prices), not for all 100+ rendered strings.
8. **The 21:9 probe used `--resolution` end to end only after the stored resolution was set**, because
   `SettingsManager` overrides the CLI flag. Both cases were captured at their true native size (2560x1080 and
   1440x1080 client areas).

## 6. Static checks (grep evidence)

| Check | Command | Result |
|---|---|---|
| No `class_name` | grep `class_name\|PlayerProfile\|Router\.\|_process\|change_scene` on `_mockup_station.gd` | 3 matches, all inside comments (lines 4, 8, 27) |
| No `_process` / `_physics_process` | same grep | 0 |
| No hex literals in script | grep `Color(0x\|#[0-9a-fA-F]{6}` | 0 |
| No font-size overrides | grep `add_theme_font_size_override\|theme_override_font` on both files | 0 |
| No `print()` | grep `print(` on the script | 0 |
| Colour literals in the scene | grep `Color(` on `_mockup_station.tscn` | 2: the grain's neutral `modulate = Color(1, 1, 1, 0.08)` and the invisible launch fade's `color = Color(0, 0, 0, 0)` placeholder, both documented in `STATION_HUB.md` 6 and 10 |
| Theme item existence | `vajb_theme.tres` dump | every variation and token the scene uses is present, plus `Tokens/void_fade` used by the launch fade |

## 7. Workspace hygiene

- The editor (PID 9048) was never touched, never relaunched and never asked to write. `--headless --editor`
  was never run. `project.godot` and `addons/` were never opened for writing.
- A game session from the previous D5 run is **still playing in the editor** (Godot PID 25248, started
  03:22:42, helper live). I did not stop it: stopping it is an editor write and the previous run had left the
  editor in `playing` state, which is also why the last recorded `session_manage(list)` entry (`vajb-orbit@0fbbd5d8777eb795`)
  still reports `play_state: playing`. It is idle and renders the same scene my movie runs render.
- Only processes I started were killed: each `aspect_probe.py` run terminates the Godot PID it spawned. No
  blanket `Get-Process Godot* | Stop-Process` was ever issued.
- `.agents/gen/previews/` now holds 9 deliverable frames plus the three helper scripts. `aspect_probe.py`
  starts a visible window for a few seconds; `d5_tools.py` writes `user://settings.cfg` only through its
  `windowed` / `resolution` / `uiscale` / `restore` subcommands, and the file was restored at the end.
- Shell commands avoided parentheses, backticks, `&&`, `>` and `<` as the brief requires (Python helper
  scripts were used for every measurement for that reason).

## 8. Summary

The inherited mockup was close to the brief and is now complete and evidenced. The plates draw (measured),
the panels are all `PanelRaised`, lists use themed chrome, the layout is container-driven and measured at
three aspect ratios, the type scale is theme-driven and measured at `ui_scale` 1.0 and 1.4, the focus ring and
the selected-row channel are measured, and the entry and idle animations are measured frame by frame.
`docs/design/STATION_HUB.md` carries the per-module spec, the responsive rules, the motion and input tables,
the audio hooks with the one reachability gap, the implementation notes and nine open questions for the owner.
