# S2 report: the station's remaining three module panels (SHIPYARD, UPGRADES, LAUNCH)

Worker: coder (S2). Date: 2026-09-18. Workspace: `G:/Mój dysk/Projekty/Vajb Orbit`.
Godot 4.7.2 stable, `--headless` only. The open editor (PID 9048) was never touched, never
restarted, and no `--headless --editor` run was made. No `project.godot`, `addons/`,
theme, shell, OUTFITTING panel, `ui/paths.gd`, `loading.gd`, `game.gd`, autoload, menu or
mockup file was edited. No documentation file was edited either: the brief's file list ends
with this report, so the docs-first rule was satisfied by the existing specs.

Everything below is measured. Where I could not measure something, the section says so.

---

## 1. Deliverables

| # | File | Bytes | State |
|---|---|---|---|
| 1 | `vajb-orbit/ui/station/shipyard_panel.tscn` | 5184 | new (hull list, preview housing, comparison table, hardpoint strip, price, action) |
| 2 | `vajb-orbit/ui/station/shipyard_panel.gd` | 20589 | new (rows from `StationCatalog.SHIPS`, state from `PlayerProfile`) |
| 3 | `vajb-orbit/ui/station/upgrades_panel.tscn` | 2320 | new (header, column strip, scroll, rows, footer) |
| 4 | `vajb-orbit/ui/station/upgrades_panel.gd` | 15127 | new (rows from `StationCatalog.UPGRADES`, `install_upgrade`) |
| 5 | `vajb-orbit/ui/station/launch_panel.tscn` | 3724 | new (brief, cargo strip, manifest, deck control) |
| 6 | `vajb-orbit/ui/station/launch_panel.gd` | 16860 | new (briefing from the profile, two-press arming beat, undock intent) |

The editor generated the three `.uid` sidecars (`shipyard_panel.gd.uid`,
`upgrades_panel.gd.uid`, `launch_panel.gd.uid`); they are the normal Godot 4 artifact for a
script I own and were left in place, exactly as the S1 wave left its own.

The three panels are siblings of `outfitting_panel.*`: same root type (`VBoxContainer`,
unique-named `Shipyard` / `Upgrades` / `Launch`), same `PaneHeader` (icon, title, subtitle,
tag), same column strip + scroll + rows + footer construct for the two table panes, same
row anatomy (`Button` -> `RowInner` -> `HBoxContainer` -> icon + `TitleBox` + value cells),
same state vocabulary style, same refusal path, same tween bookkeeping, same
`_profile()` / `_token()` / `_format_int()` helpers. No panel bakes a theme, so the
station's live (Router-scaled) theme reaches every text node.

---

## 2. Commands and outputs

Binary used throughout:
`"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe"` with
`--path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"`.

### 2.1 Verification 1: headless `res://ui/screens/station.tscn`

```
$ ... --headless ... res://ui/screens/station.tscn --quit-after 300
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
STATION_EXIT=0

WARNING: 4 ObjectDB instances were leaked at exit (run with `--verbose` for details).
ERROR: 2 resources still in use at exit (run with --verbose for details).
```

Exit 0, stdout clean apart from the vendored helper line. The two shutdown lines are the
engine's Ogg-playback-at-exit artifact the brief names; they are identical to the pre-S2
baseline of `station.tscn` (S1 report section 2.2) and are filtered from here on.

### 2.2 Verification 2: the probe (`res://tools/_probe_s2.gd`, `extends SceneTree`, `quit()`)

`PROBE_EXIT=0`, no `SCRIPT ERROR`, no `push_error`/`push_warning` from any panel. Full
output, with the geometry block left to section 2.3:

```
[catalogue] ships=4 upgrades=6 ammo=5
[panel] OUTFITTING exists=true packed=true instance=true script=res://ui/station/outfitting_panel.gd
[panel] SHIPYARD   exists=true packed=true instance=true script=res://ui/station/shipyard_panel.gd
[panel] UPGRADES   exists=true packed=true instance=true script=res://ui/station/upgrades_panel.gd
[panel] LAUNCH     exists=true packed=true instance=true script=res://ui/station/launch_panel.gd
[station] placeholders=0 credits=10000 owned=[&"ship_vanguard"] active=ship_vanguard upgrades=[] cargo={  }
[focus] module OUTFITTING focus=Layout/Page/Body/ModuleHost/HostMargin/Outfitting/OutfittingScroll/OutfittingRows/AmmoLaser inside_pane=true
[focus] module SHIPYARD   focus=Layout/Page/Body/ModuleHost/HostMargin/Shipyard/ShipyardBody/ShipListBox/ShipScroll/ShipList/ShipFighter inside_pane=true
[focus] module UPGRADES   focus=Layout/Page/Body/ModuleHost/HostMargin/Upgrades/UpgradesScroll/UpgradeRows/UpgradeGenerator inside_pane=true
[focus] module LAUNCH     focus=Layout/Page/Body/ModuleHost/HostMargin/Launch/LaunchBody/LaunchActionBox/LaunchButton inside_pane=true
[shipyard] tag=ACTIVE HULL VANGUARD subtitle=BUY AND SWITCH HULLS · 4 IN THE CRADLE · SIDE VIEWS ONLY
[shipyard] rows=4 catalogue=4 ids_match=true
[shipyard] row 0 node=ShipFighter id=ship_fighter catalogue_id=ship_fighter tag=FOR SALE
[shipyard] row 1 node=ShipVanguard id=ship_vanguard catalogue_id=ship_vanguard tag=ACTIVE
[shipyard] row 2 node=ShipGunship id=ship_gunship catalogue_id=ship_gunship tag=LOCKED
[shipyard] row 3 node=ShipDestroyer id=ship_destroyer catalogue_id=ship_destroyer tag=LOCKED
[upgrades] rows=6 catalogue=6 ids_match=true
[upgrades] row 0 node=UpgradeGenerator id=upgrade_generator catalogue_id=upgrade_generator tag=AVAILABLE
[upgrades] row 1 node=UpgradeShield id=upgrade_shield catalogue_id=upgrade_shield tag=AVAILABLE
[upgrades] row 2 node=UpgradeEngine id=upgrade_engine catalogue_id=upgrade_engine tag=AVAILABLE
[upgrades] row 3 node=UpgradeModule id=upgrade_module catalogue_id=upgrade_module tag=AVAILABLE
[upgrades] row 4 node=UpgradeExtra id=upgrade_extra catalogue_id=upgrade_extra tag=AVAILABLE
[upgrades] row 5 node=UpgradeDrone id=upgrade_drone catalogue_id=upgrade_drone tag=AVAILABLE
[balance] top_up=12000 balance=22000
[buy_ship] id=ship_fighter cost=9000 credits 22000 -> 13000 delta=9000 expected=9000 owns=true tag=OWNED action=SET ACTIVE
[set_active] ship_vanguard -> ship_fighter credits=13000 tag=ACTIVE action=IN SERVICE comparison=HULL / 700 / 700
[install_upgrade] id=upgrade_extra cost=3000 credits 13000 -> 10000 delta=3000 expected=3000 installed=true tag=INSTALLED
[upgrades] footer=INSTALLING CHARGES CREDITS AND IS PERMANENT FOR V1 tag=1 / 6 SLOTS FILLED effect=SHIELD REGEN +30% · ENERGY REGEN +20%
[refusal insufficient] strip=REFUSED · NOT ENOUGH CREDITS · 72 000 NEEDED credits 10000 -> 10000 unchanged=true
[refusal already_owned hull] strip=REFUSED · ALREADY THE ACTIVE HULL · LANCER credits unchanged=true
[refusal already_owned refit] strip=REFUSED · ALREADY INSTALLED · CARGO EXPANSION credits unchanged=true
[upgrades complete] footer=EVERY SLOT IS FILLED · NO UNINSTALL API IN V1 tag=6 / 6 SLOTS FILLED rows=upgrade_generator:INSTALLED upgrade_shield:INSTALLED upgrade_engine:INSTALLED upgrade_module:INSTALLED upgrade_extra:INSTALLED upgrade_drone:INSTALLED
[shipyard empty] name=NO HULL IN THE CRADLE texture=<Object#null> price=0 stats=HULL / 0 / 700 plates_enabled=0 action=BUY
[preview] id=ship_fighter native=(817.0, 290.0) drawn=(480.0, 170.3794) name=Lancer
[preview] id=ship_vanguard native=(905.0, 387.0) drawn=(480.0, 205.2597) name=Vanguard
[preview] id=ship_gunship native=(859.0, 385.0) drawn=(480.0, 215.1339) name=Bulwark
[preview] id=ship_destroyer native=(982.0, 217.0) drawn=(480.0, 106.0693) name=Obliterator
[launch destination] route=game in_table=true path=res://game/game.tscn line=OPEN SPACE · SECTOR K-9 brief_row=OPEN SPACE · SECTOR K-9
[launch subtitle] UNDOCK AND RETURN TO OPEN SPACE · LOADING BRIDGE DESTINATION GAME | tag=TWO PRESSES · 3 s WINDOW
[launch brief] hull=LANCER hull_limit=700 shield_limit=400 hardpoints=3 cargo=35 / 25 ammo=1 500 ROUNDS ACROSS 5 WEAPONS
[launch cargo] caption=CARGO HOLD · 3 STACKS manifest=Ore Fragment   22 | Data Core   2 | Salvage Plate   11 plates=40px:enabled:icon 24x24 res://assets/icons/tint/icon_cargo_ore_48.png 40px:enabled:icon 24x24 res://assets/icons/tint/icon_cargo_data_core_48.png 40px:enabled:icon 24x24 res://assets/icons/tint/icon_cargo_salvage_48.png 40px:disabled:empty 40px:disabled:empty
[arm] armed=true colour_override=true strip=ARMED · PRESS LAUNCH AGAIN WITHIN 3 s TO UNDOCK launches=0
[arm] disarm_returns=true armed=false strip=PRESS LAUNCH TO ARM · A SECOND PRESS CONFIRMS WITHIN 3 s
[arm] disarm_when_idle=false
[fire] armed=false launches=1 strip=LAUNCH CONFIRMED · HANDOFF TO THE LOADING BRIDGE · DESTINATION GAME routes=loading{ &"destination": &"game" }
[arm window] armed_after_press=true wait_time=3.00
[arm expiry] armed=false colour_override=false strip=ARMING EXPIRED · PRESS LAUNCH TO ARM AGAIN
```

Read as evidence:

- **Scenes**: all three new panels exist as `PackedScene`s, instantiate, and carry the
  expected script. The station builds **0 placeholder panes**, i.e. all four modules are
  now real panels and the shell's offline fallback is unused.
- **Catalogue fidelity**: the SHIPYARD's 4 hull rows and the UPGRADES' 6 refit rows match
  `StationCatalog.ship_ids()` / `upgrade_ids()` **element by element and in order**
  (`ids_match=true` both times), so no invented entry and none missing. The tags at the
  documented default profile (`credits=10000`, active `ship_vanguard`) are
  `FOR SALE` (Lancer 9000 affordable), `ACTIVE` (Vanguard), `LOCKED` (Bulwark 36000,
  Obliterator 72000), and `AVAILABLE` for all six refits (3000..6800).
- **Purchases through the real UI path** (`row.pressed.emit()`, then the profile signal
  back through the shell into the rebuilt rows):
  - `buy_ship(ship_fighter, 9000)`: credits 22000 -> 13000, **delta 9000 = the catalogue
    price**, `owns=true`, row tag `OWNED`, `ShipAction` becomes `SET ACTIVE`.
  - `set_active_ship(ship_fighter)`: active `ship_vanguard` -> `ship_fighter`, credits
    unchanged, row tag `ACTIVE`, action `IN SERVICE`, and the comparison column re-reads
    the new active hull (`HULL / 700 / 700`).
  - `install_upgrade(upgrade_extra, 3000)`: credits 13000 -> 10000, **delta 3000 = the
    catalogue price**, `installed=true`, row tag `INSTALLED`, tag `1 / 6 SLOTS FILLED`.
- **Refusals** (all three leave credits untouched, all three are the shell's strip copy in
  `accent_danger`, none opens a dialog):
  - `insufficient_credits`: `REFUSED · NOT ENOUGH CREDITS · 72 000 NEEDED`, 10000 -> 10000.
  - `already_owned` on the active hull: `REFUSED · ALREADY THE ACTIVE HULL · LANCER`.
  - `already_owned` on an installed refit: `REFUSED · ALREADY INSTALLED · CARGO EXPANSION`.
- **Nothing-left-to-buy**: with all six refits installed the UPGRADES footer switches to
  `EVERY SLOT IS FILLED · NO UNINSTALL API IN V1`, the tag reads `6 / 6 SLOTS FILLED` and
  every row reads `INSTALLED`.
- **SHIPYARD empty state**: a selection the catalogue cannot resolve blanks the image
  (`texture=<Object#null>`), prints `NO HULL IN THE CRADLE`, zeroes the price and the stat
  column and leaves **0 of 7** plates enabled.
- **Preview sizing**: every hull is drawn at the documented `PREVIEW_SCALE` 0.70 clamped to
  `PREVIEW_MAX_WIDTH` 480 (section 4 has the table).
- **LAUNCH destination**: `destination_route()` is `game`, **the route table holds it**
  (`in_table=true`), `UIPaths.route_path` resolves to `res://game/game.tscn`, and the
  brief's `DESTINATION` cell prints the same line the panel computes.
- **LAUNCH brief** from the profile and the catalogue: active hull `LANCER`, limits
  700 / 400 / 3, cargo `35 / 25` (35 units of cargo against the Lancer's 25 unit hold),
  ammunition `1 500 ROUNDS ACROSS 5 WEAPONS` (5 packs x 300 held).
- **Cargo strip and manifest**: 3 stacks -> caption `CARGO HOLD · 3 STACKS`, manifest lines
  `Ore Fragment   22`, `Data Core   2`, `Salvage Plate   11`, plate strip
  `40px:enabled:icon 24x24 ...` for the first three (a 24 px glyph inset 8 px inside a
  40 px plate) and `40px:disabled:empty` for the last two. With an empty hold the manifest
  is a single `HOLD EMPTY` item flagged disabled and all five plates are disabled.
- **Arm window**: the first press arms (`armed=true`, `font_color` override present, strip
  `ARMED · PRESS LAUNCH AGAIN WITHIN 3 s TO UNDOCK`); `disarm()` returns `true` while armed
  and `false` when idle, and restores the idle copy; a second press inside the window fires
  exactly one `launch_requested` (`launches=1`), clears the armed state, and the shell then
  declares `loading{ &"destination": &"game" }`; the timer's `wait_time` is `3.00`; the
  expiry path clears the colour override and prints
  `ARMING EXPIRED · PRESS LAUNCH TO ARM AGAIN`.
- **Focus**: after every module switch the focus owner is a descendant of the visible pane
  (`inside_pane=true` four times) and is never a hidden row: the LAUNCH pane's primary
  focus target is its `LaunchButton`, the three list panes focus their first row.

### 2.3 Verification 3: geometry at `ui_scale` 1.0 and 1.4

Measured on real instances of `station.tscn` under `/root` (the headless window is
2560x1440 and the stretch keeps the canvas at 1920x1080, so the numbers are directly
comparable with the spec's tables). At 1.4 the theme is scaled with `Router`'s own math read
from `Router.FONT_SIZE_ITEMS`, because `user://settings.cfg` has to stay byte-identical
(verification 4). `overflowing` counts labels whose text is wider than the rect they were
given (autowrap labels excluded); `overlap` compares consecutive row rects.

```
[geometry] ui_scale 1.00 viewport=(2560, 1440) canvas=(1920.0, 1080.0)
[geometry] 1.00 OUTFITTING pane=1440x839 labels=43 overflowing=0
[geometry] 1.00   row AmmoLaser      y 261..337 h 76 gap 0 x 429..1867 w 1438
[geometry] 1.00   row AmmoCannon     y 343..419 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   row AmmoRocket     y 425..501 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   row AmmoMine       y 507..583 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   row AmmoPlasma     y 589..665 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   rows=5 overlap=false
[geometry] 1.00 SHIPYARD   pane=1440x839 labels=37 overflowing=0
[geometry] 1.00   row ShipFighter    y 247..323 h 76 gap 0 x 429..767 w 338
[geometry] 1.00   row ShipVanguard   y 329..405 h 76 gap 6 x 429..767 w 338
[geometry] 1.00   row ShipGunship    y 411..487 h 76 gap 6 x 429..767 w 338
[geometry] 1.00   row ShipDestroyer  y 493..569 h 76 gap 6 x 429..767 w 338
[geometry] 1.00   row ShipAction     y 938..994 h 56 gap 369 x 1508..1868 w 360
[geometry] 1.00   rows=5 overlap=false
[geometry] 1.00 UPGRADES   pane=1440x839 labels=50 overflowing=0
[geometry] 1.00   row UpgradeGenerator y 261..337 h 76 gap 0 x 429..1867 w 1438
[geometry] 1.00   row UpgradeShield  y 343..419 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   row UpgradeEngine  y 425..501 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   row UpgradeModule  y 507..583 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   row UpgradeExtra   y 589..665 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   row UpgradeDrone   y 671..747 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.00   rows=6 overlap=false
[geometry] 1.00 LAUNCH     pane=1440x839 labels=22 overflowing=0
[geometry] 1.00   row LaunchButton   y 839..927 h 88 gap 0 x 1508..1868 w 360
[geometry] 1.00   rows=1 overlap=false
[geometry] 1.00 hardpoints x 1508..1868 w=360 stats_w=360 fits=true plates=48 48 48 48 disabled 48 disabled 48 disabled 48 disabled
[geometry] 1.00 preview center=660x669 drawn=(480.0, 170.3794) materials=none (normal blend everywhere)
[geometry] ui_scale 1.40 viewport=(2560, 1440) canvas=(1920.0, 1080.0)
[geometry] 1.40 OUTFITTING pane=1440x798 labels=43 overflowing=0
[geometry] 1.40   row AmmoLaser      y 321..397 h 76 gap 0 x 429..1867 w 1438
[geometry] 1.40   row AmmoCannon     y 403..479 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   row AmmoRocket     y 485..561 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   row AmmoMine       y 567..643 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   row AmmoPlasma     y 649..725 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   rows=5 overlap=false
[geometry] 1.40 SHIPYARD   pane=1440x798 labels=37 overflowing=0
[geometry] 1.40   row ShipFighter    y 307..383 h 76 gap 0 x 429..767 w 338
[geometry] 1.40   row ShipVanguard   y 389..465 h 76 gap 6 x 429..767 w 338
[geometry] 1.40   row ShipGunship    y 471..547 h 76 gap 6 x 429..767 w 338
[geometry] 1.40   row ShipDestroyer  y 553..629 h 76 gap 6 x 429..767 w 338
[geometry] 1.40   row ShipAction     y 930..986 h 56 gap 301 x 1477..1868 w 391
[geometry] 1.40   rows=5 overlap=false
[geometry] 1.40 UPGRADES   pane=1440x798 labels=50 overflowing=0
[geometry] 1.40   row UpgradeGenerator y 321..397 h 76 gap 0 x 429..1867 w 1438
[geometry] 1.40   row UpgradeShield  y 403..479 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   row UpgradeEngine  y 485..561 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   row UpgradeModule  y 567..643 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   row UpgradeExtra   y 649..725 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   row UpgradeDrone   y 731..807 h 76 gap 6 x 429..1867 w 1438
[geometry] 1.40   rows=6 overlap=false
[geometry] 1.40 LAUNCH     pane=1440x798 labels=22 overflowing=0
[geometry] 1.40   row LaunchButton   y 775..863 h 88 gap 0 x 1508..1868 w 360
[geometry] 1.40   rows=1 overlap=false
[geometry] 1.40 hardpoints x 1477..1837 w=360 stats_w=391 fits=true plates=48 48 48 48 disabled 48 disabled 48 disabled 48 disabled
[geometry] 1.40 preview center=629x590 drawn=(480.0, 170.3794) materials=none (normal blend everywhere)
```

Read as evidence:

- **No clipped or overflowing text at either scale**: 0 overflowing labels out of 152
  checked labels (43 + 37 + 50 + 22) per scale. The three new panels contribute 109 of
  those.
- **No overlapping rows**: 76 px rows on a 6 px gap at both scales, 4 ship rows and 6 refit
  rows, `overlap=false` everywhere. The row heights stay 76 and follow the font: at 1.4 the
  row content is 59 px tall (25 px title + 18 px caption + the 16 px inner margins) inside
  the same 76 px row, which is why nothing clips and why no per-node font size was needed.
- **Plates fit their columns**: the 7 weapon plates are 360 px wide (7 x 48 + 6 x 4) inside
  a 360 px stat column at 1.0 and a 391 px one at 1.4 (`fits=true` both times); the first
  three are enabled and the last four disabled for the Lancer's 3 hardpoints.
- **The preview is not clamped by its box at 1920x1080**: the `PreviewCenter` interior is
  660x669 at 1.0 and 629x590 at 1.4, both wider than the 480 px maximum, so the documented
  480 px maximum width is the binding constraint (the box clamp is the second clamp that
  protects narrower panes).

### 2.4 Verification 4: profile and settings byte identity

```
before: settings.cfg edb17b3fcf9c3b29720a7590dade2de3262cfbb78699bb78a239fcc9dd233617
after:  settings.cfg edb17b3fcf9c3b29720a7590dade2de3262cfbb78699bb78a239fcc9dd233617
before: profile.cfg  15025e5299ac9736e9aad9b4d06565ea7a4d11caca6baea719d7c4b86d35a4ca
after:  profile.cfg  15025e5299ac9736e9aad9b4d06565ea7a4d11caca6baea719d7c4b86d35a4ca
```

Both hashes were taken with `certutil -hashfile <path> SHA256`.

`settings.cfg` was never written: **byte-identical**, and the 1.4 geometry run scaled a
theme copy in memory rather than changing the setting.

`profile.cfg` **was** changed by the probe (it buys a hull, installs a refit, adds cargo and
uses `reset_to_defaults()`), so I copied the file aside before the first probe run and
restored it afterwards. It is now byte-identical to the pre-work hash and holds its
documented default state (`credits=10000`, `owned_ships=["ship_vanguard"]`, `active_ship`
`ship_vanguard`, `ammo` 300 each, `upgrades=[]`, `cargo={}`), verified by reading the file
after the restore.

**One concurrency note the orchestrator should know.** Between my baseline hash and my first
probe run, another process changed `profile.cfg` to `credits=8940` with a bought Lancer and
double ammunition: `C:/Users/Kamil/AppData/Roaming/Godot/app_userdata/Vajb Orbit/logs/`
holds a **graphical** session log at `10.43.28` (`D3D12 ... Embedded window only supports
Windowed mode`, i.e. the open editor running the game, not one of my headless runs). That is
why the probe calls `PlayerProfile.reset_to_defaults()` before it measures, so every number
in section 2.2 is deterministic whatever the file held on entry. If that other session is
still running it may write the profile again after this report; nothing I own reads or
depends on the file.

### 2.5 Verification 5: cleanup

```
$ ls vajb-orbit/tools/
build_theme.gd  build_theme.gd.uid  derive_icon_tints.gd  derive_icon_tints.gd.uid
```

`_probe_s2.gd` is deleted; no `_probe_s2.gd.uid` was ever created (the editor never scanned
it), so `tools/` holds exactly the two scripts the brief names plus their sidecars.

---

## 3. Blend modes of every textured element (requested)

Measured, not asserted: the probe walks every `CanvasItem` in the station and reports any
node that carries a material. Result, at both scales:
`materials=none (normal blend everywhere)`. No node in the station or in my three panels
sets a `CanvasItemMaterial` or a `ShaderMaterial`, so every element below draws with the
default **NORMAL** blend:

| Element | Node | Texture | Blend |
|---|---|---|---|
| SHIPYARD ship preview | `TextureRect` (`%PreviewImage`) | `assets/ships/ship_*_side.png`, RGBA | NORMAL |
| SHIPYARD pane icon | `TextureRect` (`%PaneIcon`) | `assets/icons/tint/icon_hull_48.png`, RGBA, `modulate` `Tokens/text_primary` | NORMAL |
| SHIPYARD hardpoint plates | 7 x `TextureButton` | `ui_slot_weapon_{normal,hover,pressed,disabled}.png` copied from the `SlotButtonWeapon` styleboxes | NORMAL |
| UPGRADES pane icon | `TextureRect` | `assets/icons/icon_equip_generator_48.png`, RGBA | NORMAL |
| UPGRADES row icons | 6 x `TextureRect` | `assets/icons/icon_equip_*_48.png`, painted RGBA, `modulate` white at alpha 0.72 | NORMAL |
| LAUNCH pane icon | `TextureRect` | `assets/icons/icon_map_route_48.png`, RGBA | NORMAL |
| LAUNCH cargo plates | 5 x `TextureButton` | `ui_slot_cargo_{normal,hover,pressed,disabled}.png` from the `SlotButtonCargo` styleboxes | NORMAL |
| LAUNCH cargo plate glyphs | 5 x `TextureRect` | `assets/icons/tint/icon_cargo_*_48.png`, RGBA | NORMAL |
| Chrome (frames, plates, focus ring, scroll bars, `ItemList` band) | `PanelContainer` / `Button` / `StyleBoxFlat` | `ui_panel_frame.png`, `ui_button_plate_*.png` | NORMAL |

The ship preview is RGBA and is **not** additively blended; nothing on this screen is
additive, and no FX asset (`assets/fx/*`) is used here (STATION_HUB section 7.3). The two
`ColorRect`s the shell tints (backdrop dim, leave dimmer) are the shell's, not mine.

---

## 4. Where the spec's own numbers disagree with the spec's own rule (STATION_HUB 7.2)

The brief says "set the ship preview as the spec sizes it (section 7.2), with the documented
scale and maximum width". The rule in 7.2 is `PREVIEW_SCALE` 0.70 of the native size,
clamped to `PREVIEW_MAX_WIDTH` 480 px, then clamped again to the `PreviewCenter` box. The
table in the same section lists four drawn sizes. Two of the four do not follow from the
rule:

| Hull | Native (measured) | Rule output (measured) | 7.2 table | Agrees? |
|---|---|---|---|---|
| Lancer `ship_fighter_side.png` | 817 x 290 | 480.0 x 170.4 | 480 x 170 | yes |
| Vanguard `ship_vanguard_side.png` | 905 x 387 | 480.0 x 205.3 | 480 x 205 | yes |
| Bulwark `ship_gunship_side.png` | 859 x 385 | 480.0 x 215.1 | 480 x 205 | **no** (table is 10 px short) |
| Obliterator `ship_destroyer_side.png` | 982 x 217 | 480.0 x 106.1 | 480 x 205 | **no** (table is 99 px tall) |

I implemented the **rule** (0.70, 480 px maximum), which is also exactly what the approved
mockup's `_update_preview_size()` does, and the brief names the scale and the maximum width
as the contract. The table's last two rows look hand-rounded or copied from the Vanguard's
aspect ratio. No code change is needed unless the owner wants the table to win, in which
case the rule has to be restated (e.g. "clamp to 480 x 205") and the destroyer would be
stretched.

The S1 wave's finding also still holds and affected my arithmetic: the `PanelRaised` inset
is **8 px** per side, not the 33 px STATION_HUB 3.1/3.4 claims, so the host's content box is
1440 px wide and every row measures x 429..1867 (1438 px) rather than the table's
x 453..1842. My panels reproduce the mockup's numbers, not 3.1's table, for the same reason
S1 did: the table disagrees with the artifact it was measured from.

---

## 5. Judgement calls

1. **"Computes the destination line from the route table" is implemented as: resolve the
   route through `UIPaths`, then look the wording up by that route id.**
   `DESTINATION_ROUTE` is `&"game"`; `destination_route()` returns it only if
   `UIPaths.route_exists(&"game")` is true, and `destination_line()` renders
   `DESTINATION_LINES[route]` (`OPEN SPACE · SECTOR K-9`) with the route's own upper-cased
   id as the fallback for a route the wording table does not name, and
   `NO ROUTE IN THE TABLE` when the route table cannot resolve the destination at all. So
   the *source* is the route table (as section 5.4 says) and the *wording* is a route-keyed
   table rather than a string spliced into the row. The panel still arms when the route
   cannot be resolved, because section 5.4 makes an unresolvable destination a routing bug
   and not a screen state. The probe proves the resolution: `route=game in_table=true
   path=res://game/game.tscn`, and the brief cell prints the same line.
2. **The panel emits `launch_requested()`; the shell owns
   `route_requested(&"loading", {destination: &"game"})`.** That split is S1's frozen panel
   contract (`station.gd` header: "LAUNCH panels declare the undock; only the shell
   routes"). I did not change the shell. The panel does name the loading route itself
   (`ROUTE_LOADING` builds the `LOADING BRIDGE` wording in its subtitle and its fired
   strip), so the handoff is derived on both sides instead of being typed twice. The probe
   captured the shell's declaration end to end: `routes=loading{ &"destination": &"game" }`.
3. **Cargo display names and glyphs are derived from the item id.** `PlayerProfile` counts
   cargo ids only, and `STATION_SPEC.md` says a mining/loot spec owns the item catalogue
   later, so no catalogue exists to read a name or an icon from. The name is
   `String(id).capitalize()`, which turns `ore_fragment` into `Ore Fragment`, `data_core`
   into `Data Core` and `salvage_plate` into `Salvage Plate` (Godot's `capitalize()` splits
   on underscores and title-cases). The glyph is resolved against the derived tint stencils
   on disk: `icon_cargo_<id>_48.png` first, then `icon_cargo_<leading token>_48.png`, then
   the generic `icon_cargo_crate_48.png`. Measured: `ore_fragment` -> `icon_cargo_ore_48.png`,
   `data_core` -> `icon_cargo_data_core_48.png`, `salvage_plate` ->
   `icon_cargo_salvage_48.png`. A real item catalogue would replace this helper, not the
   panel's structure.
4. **The manifest line format is the mockup's `"%s   %d"`** (three spaces between name and
   quantity), and the empty hold is a single `HOLD EMPTY` item added with
   `set_item_disabled(0, true)` plus five disabled plates, which is exactly the empty state
   section 5.4 asks for.
5. **A hull row press acts; a hull row focus selects.** Section 5.2 says `ui_accept` on a
   row "calls `set_active_ship(id)` when owned and `buy_ship(id, cost)` when not", so the
   row is both the preview selector (on focus, and on click through the same handler) and
   the buy/activate control. Pressing the hull that is already active therefore produces the
   shell's `REFUSED · ALREADY THE ACTIVE HULL · <name>` rather than a silent no-op, because
   the panel always lets `set_active_ship` decide (section 5.6).
6. **The SHIPYARD row has no price cell, so a refusal pulses the stat column's price.**
   Section 5.6 wants "the price cell" pulsed; the hull rows carry `STATUS` only, and the
   price lives in the stat column, so `_pulse(_price)` targets `ShipPrice`. That is the
   mockup's own behaviour (`payload[&"price"] = _ship_price`).
7. **The SHIPYARD panel tag names the profile's live active hull.** The mockup's tag was
   the stub string `DEFAULT HULL ship_vanguard`; section 12.5 lists that as a stub the
   shipping screen replaces with a profile read. The tag now reads
   `ACTIVE HULL VANGUARD` (the catalogue's `name`, upper-cased, with the raw id as the
   fallback when the catalogue cannot resolve it) and updates on `&"ships"`.
8. **The UPGRADES panel tag and footer are computed.** Tag: `%d / %d SLOTS FILLED` from
   `installed_upgrades().size()` against `Catalog.UPGRADES.size()`; footer: the default
   `INSTALLING CHARGES CREDITS AND IS PERMANENT FOR V1`, switching to
   `EVERY SLOT IS FILLED · NO UNINSTALL API IN V1` when all six are installed (measured).
   The mockup's `NO UNINSTALL API IN V1` tag would have been a constant, and the brief
   forbids literal counts.
9. **UPGRADES row icons are drawn at full colour, not tinted.** Section 7.1 lists the six
   `icon_equip_*_48.png` icons without the "tinted" note it gives `icon_hull_48.png` and the
   three flat ammo glyphs, and the mockup passes `tinted = false` for every refit row. I
   measured the assets to be sure: they are painted RGBA art (opaque-pixel mean around
   (53,43,39) with 255-range highlights), unlike the flat Phase B glyphs of audit anomaly
   C16 that OUTFITTING has to substitute. So the refit rows modulate white at alpha 0.72 and
   brighten to 1.0 on hover, and only the SHIPYARD's pane icon is tinted with
   `Tokens/text_primary`.
10. **UPGRADES effect labels.** Section 5.3 wants `<LABEL> +<n>%` joined with ` · ` and an
    unknown key rendered as its own upper-cased key; the label table is the mockup's
    (`SHIELD REGEN`, `ENERGY REGEN`, `SHIELD MAX`, `SPEED`, `SCANNER RANGE`, `CARGO MAX`,
    `HULL REPAIR`). A refit whose `effect` is missing or not a dictionary renders
    `NO EFFECT DATA` instead of a blank cell, which is the same "never blank" rule as an
    unknown key.
11. **A malformed catalogue entry degrades to a disabled row in UPGRADES too**, mirroring
    the OUTFITTING panel's C16-era handling: missing id or name disables the row and prints
    `STOCK UNAVAILABLE` / `CATALOGUE ENTRY INCOMPLETE`, so a catalogue that lost an entry is
    visible instead of a blank row.
12. **`disarm()` kills the arm pulse.** Section 9's arm beat tweens `modulate:a` down to
    0.70 and back four times; a `ui_cancel` or a fire in the middle of that tween would
    otherwise leave the button frozen at 0.70, so `_clear_arm()` kills the tween and forces
    `modulate.a` back to 1.0. The measured expiry path confirms the reset
    (`colour_override=false`).
13. **The fired strip keeps its copy and the panel does not fade.** Section 2 says the
    shipping screen "replaces the fade with `route_requested` and leaves the fade to
    Router", so the panel never touches the shell's `%Fade`; it prints
    `LAUNCH CONFIRMED · HANDOFF TO THE LOADING BRIDGE · DESTINATION GAME` and hands off.
14. **LAUNCH ignores `profile_changed(&"credits")`.** The briefing shows no credit figure
    (section 5.4 lists seven rows, none of them a balance), so the panel reacts to
    `&"cargo"` and `&"ships"` (strip, manifest, limits, cargo total) and to `&"ammo"`
    (the ammunition line). Refresh map for the three panels: SHIPYARD `credits` + `ships`;
    UPGRADES `credits` + `upgrades`; LAUNCH `cargo` + `ships` + `ammo`.
15. **Plates are `TextureButton`s whose four state textures are copied out of the theme
    styleboxes.** A `TextureButton` has no stylebox items, so `SlotButtonWeapon/styles/*` is
    never read by the engine on a bare `theme_type_variation` (the note in
    `ui/components/slot_button.gd`, and the mockup's construct). Repeating that lookup keeps
    the panels script-only and avoids instancing the HUD component; the copies are re-read
    on `NOTIFICATION_THEME_CHANGED` so a scaled theme re-tints the plates.
16. **Rows keep the fixed 76 px height and follow the font instead.** The brief asks that
    row heights follow the font; measured, the 1.4 row content is 59 px inside the same
    76 px row with 0 overflow, which is the mockup's and S1's behaviour, so no per-node font
    size and no height change was needed. No panel sets `theme_override_font_sizes` or calls
    `add_theme_font_size_override` (grep: zero hits in `ui/station/`).
17. **Named rows and cells for verifiability.** Rows are named from the catalogue id
    (`ShipVanguard`, `UpgradeExtra`), cells are named (`RowInner`, `TitleBox`, `Icon`,
    `Effect`, `Price`, `Status`, `Value`, `Caption`), brief lines are named
    (`BriefDestination`, `BriefHullName`, ...), cargo plates are `CargoSlot01..05`, and each
    row carries `set_meta(&"id", <catalogue id>)`. Not in the spec, but the spec's own node
    tree names these constructs, and it is what let the probe compare ids without parsing
    labels.
18. **The probe resets the profile before measuring.** See section 2.4: a concurrent editor
    game run had mutated `profile.cfg` between my baseline hash and my first probe run.
    `reset_to_defaults()` makes every measured number reproducible; the file was restored to
    its documented default afterwards.
19. **Audio.** Row focus plays `UiCue.HOVER`, row press and the launch button play
    `UiCue.CLICK`, a successful buy/install/set-active plays `UiCue.CONFIRM`, both new list
    panels wire `scroll_started` to `UiCue.SCROLL`, and arming plays
    `play_sfx(&"sfx_station_breaker_on_01")` (section 11). The boost, the jump and the
    ambience stop stay in the shell's `_on_launch_requested`, unchanged.
20. **No `_process` anywhere.** All animation is `Tween`s created on the owning panel and
    killed in `_exit_tree()`; the only `Timer` is the LAUNCH arm window, a one-shot
    `ArmTimer` child of the panel.
21. **`focus_primary()` falls back to the action button only when no row can take focus.**
    Every hull and refit row is always enabled, so in practice the first row takes the ring;
    the fallback keeps the contract honest for a catalogue that ships a disabled row.

---

## 6. What I could not verify

1. **A rendered frame of the shipping screen.** Headless has no renderer and I did not
   hijack the open editor to take a screenshot. Verification 3 explicitly allows a measured
   geometry dump, which section 2.3 is; the panels' own content is verified by node reads
   (tags, prices, effects, manifest lines, plate states, preview sizes), not by pixels.
2. **Mouse behaviour**: hover icon alpha tweens, the pointing-hand cursor and click-to-buy
   are wired (same calls as the OUTFITTING panel) but were not exercised; only synthetic
   `pressed` emissions and focus moves were.
3. **The `SCROLL` cue end to end.** Both new list panels connect `scroll_started`, and the
   probe never scrolled, so the cue was not heard (the OUTFITTING panel has the same
   untested connection).
4. **Gamepad shoulders, `PageUp`/`PageDown` and `Tab` traversal** are the shell's, unchanged
   by me, and were verified by S1 for the shell; my probe only moved the ring by module
   switch and by `grab_focus()`.
5. **The LAUNCH panel inside a *routed* station.** My probe instantiates `station.tscn`
   under `/root` (so the shell's `route_requested` is captured by the probe instead of the
   Router). S1 proved the routed station builds 4 panes; I proved the panels load where the
   shell expects them and that the launch handoff declares the documented route.
6. **21:9 and 4:3.** S1 measured the shell at those aspects; my geometry run used the 16:9
   canvas only. The new panes are all `size_flags`-driven with one `StatsSpacer` /
   `BriefSpacer` / `ActionSpacer` each, so the extra height is absorbed exactly as S1
   measured for OUTFITTING, but I did not re-measure it.
7. **The `ItemList` focus ring** on the cargo manifest (the manifest's item text, selection
   and disabled flag were measured, not its ring).

---

## 7. Handoff notes for the next wave

- The station now has all four module panels; `station.tscn` builds **zero** placeholder
  panes (measured), so the shell's offline fallback is only reachable if a panel file is
  removed. `_mockup_station.*` is untouched and still runs clean headless, so the cleanup
  step STATION_HUB section 12.6 describes can proceed whenever the owner signs off.
- The three panels expose exactly S1's contract: `status_requested(message, danger)`,
  `refresh_profile(key)`, `focus_primary()`, plus `launch_requested()` and `disarm() -> bool`
  on LAUNCH. A future panel only needs those.
- If a real cargo item catalogue lands, replace `launch_panel._cargo_display_name()` and
  `_cargo_icon_path()`; nothing else in the panel assumes ids are self-describing.
- If the owner wants STATION_HUB 7.2's table to be the contract for the gunship and the
  destroyer, the clamp has to be restated (section 4 above); today the rule and the approved
  mockup agree with each other and disagree with two rows of the table.
- `profile.cfg` was left in its documented default state and byte-identical to the pre-work
  hash, but another Godot process (an editor game session) was writing that file during this
  wave; a verifier should hash it before and after their own run rather than trusting mine.
