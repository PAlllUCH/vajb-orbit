# W4 report — repairs + launch panels (fix wave 1)

Brief: `.agents/gen/fix_wave1_task.md` §W4. Rulings: `docs/design/IMPLEMENTATION_PLAN.md` §9.8
items 3 (readability lives in W2) and 5 (interim sector naming), plus the W4 section itself.
Worker: W4. Date: 2026-09-18.

Files touched (exactly the W4 list; nothing else was written):

| File | Before | After | Delta |
|---|---|---|---|
| `vajb-orbit/ui/station/repairs_panel.gd` | 11 693 | 14 053 | +2 360 |
| `vajb-orbit/ui/station/repairs_panel.tscn` | 3 624 | 4 288 | +664 |
| `vajb-orbit/ui/station/launch_panel.gd` | 16 766 | 18 797 | +2 031 |
| `vajb-orbit/ui/station/launch_panel.tscn` | 3 724 | 4 790 | +1 066 |
| `vajb-orbit/ui/screens/station.tscn` | 10 433 | 10 435 | +2 |

(The two `.gd` files were re-written in place, byte-identical, by the editor's `script_patch`
below at 14:26, so the "after" sizes above are the on-disk truth. `ui/screens/station.gd` is
untouched: the subline string is scene data.)

## 1. REPAIRS — active-hull side render in the empty framed area

The empty area is the free space of the REPAIR CONTROL column (`RepairsBody/RepairBox`): the
`ActionSpacer` `Control` that used to absorb it. That spacer is now the frame
(`PanelRaised`, the same variation `shipyard_panel.tscn`'s `PreviewFrame` uses) with
`MarginContainer` → `CenterContainer` → `TextureRect`, mirroring the shipyard preview chain.

Resolution mirrors `shipyard_panel.gd` (`shipyard_panel.gd:399`: `load(String(ship.get(&"preview", "")))`):
the render comes from `StationCatalog`'s `preview` key for the profile's active hull, never a
path literal. `repairs_panel.gd:291` `hull_render(ship_id, missing_hull)`:

- `missing_hull <= 0` (no report, or nothing missing) → the catalogue's intact cut;
- `missing_hull > 0` → `preview.replace("_side.png", "_damaged_side.png")`, but only when that
  cut exists on disk, so a hull without a damaged cut keeps its intact render;
- unknown hull → `""` → no texture.

`_refresh_all` calls it with `maxi(0, hull_max - hull)` (`repairs_panel.gd:169`) and with `0` on
the no-report branch (`repairs_panel.gd:174`). Contain-fit: `PREVIEW_FIT` (0.70) of the frame's
width, aspect kept, shrunk to the frame's height when the column is short
(`_update_preview_size`, `repairs_panel.gd:309`), re-run on `HullCenter.resized`.
Nothing else in the panel changed: all existing strings, the fee math, the refusal paths and
the button wiring are untouched.

## 2. LAUNCH — intact render + `VANGUARD — READY`

The same empty area of the DECK CONTROL column (`LaunchBody/LaunchActionBox`: its
`ActionSpacer` is now `HullFrame`), with the caption `HullCaption` (`StationCaption`) inside the
frame beneath the render, exactly as `PreviewName` sits beneath `PreviewCenter` in the shipyard
frame. `launch_panel.gd:406` `hull_preview(ship_id)` reads the same catalogue key; the caption is
`HULL_READY_FORMAT` (`"%s — READY"`) fed the active hull's upper-cased name
(`launch_panel.gd:417`), the same name the ACTIVE HULL brief row prints. Intact cut only: LAUNCH
never shows the damaged render, that state belongs to REPAIRS. Briefing rows, cargo plates,
manifest and the arming beat are unchanged.

The em dash in that string is brief-literal (`fix_wave1_task.md` §W4.2) and has precedent in
shipped copy: `ui/station/exchange_panel.gd:104`, `ui/screens/loading.gd:14`.

## 3. Interim sector naming

| File | Before | After |
|---|---|---|
| `launch_panel.gd:40` (`DESTINATION_LINES[&"game"]`) | `OPEN SPACE · SECTOR K-9` | `OPEN SPACE · HELIOS DRIFT` |
| `station.tscn:101` (header subline) | `DOCKING RING 04 · SECTOR K-9 · HULL TRAFFIC LOW` | `DOCKING RING 04 · HELIOS DRIFT · HULL TRAFFIC LOW` |

`grep "SECTOR K-9"` over `vajb-orbit/ui` now matches only `ui/screens/_mockup_station.gd:713`
and `_mockup_station.tscn:105` — the mockups, which are outside the W4 file list and are
deleted at the Phase D close-out (IMPLEMENTATION_PLAN §9.6). Same for the stale `ActionSpacer`
in `_mockup_station.tscn:617`: no `ActionSpacer` remains in either shipping panel.

## 4. Commands run

### 4.1 The brief's parse check (global rules) — artifact, not a gate

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://ui/station/repairs_panel.gd
SCRIPT ERROR: Compile Error: Identifier not found: AudioManager
   at: GDScript::reload (res://ui/station/repairs_panel.gd:253)
ERROR: Failed to load script "res://ui/station/repairs_panel.gd" with error "Compilation failed".

"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://ui/station/launch_panel.gd
SCRIPT ERROR: Compile Error: Identifier not found: AudioManager
   at: GDScript::reload (res://ui/station/launch_panel.gd:452)
```

Control, untouched file:

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://ui/station/shipyard_panel.gd
SCRIPT ERROR: Compile Error: Identifier not found: AudioManager
   at: GDScript::reload (res://ui/station/shipyard_panel.gd:471)
```

So `--check-only` (and any `--script` run) has no autoload globals in this build and cannot
compile any panel that names `AudioManager` — the same failure hits a file this wave never
touched. It is therefore not usable as the parse gate for W4; the gates below are.

### 4.2 Gate 1 — scene-run probe (a `--script` main loop omits the autoloads; a scene run has them)

Throwaway probe `res://tools/_probe_w4.gd` + `res://tools/_probe_w4.tscn` (both deleted; see
§6). It preloads both panel scripts (compile gate) and mounts both scenes under a
1920×1080 window an renders/measures them. Captured output:

```
PROBE_W4 window=(1920.0, 1080.0) panel=(1560.0, 900.0)
-- damaged cuts on disk --
  ship_fighter preview_exists=true damaged_exists=false
  ship_vanguard preview_exists=true damaged_exists=true
  ship_gunship preview_exists=true damaged_exists=false
  ship_destroyer preview_exists=true damaged_exists=false
-- repairs.hull_render(ship_id, missing_hull) --
  ship_vanguard missing=0 (no report / repaired) -> ship_vanguard_side.png
  ship_vanguard missing=250 (damaged) -> ship_vanguard_damaged_side.png
  ship_vanguard missing=-4 (negative missing) -> ship_vanguard_side.png
  ship_fighter missing=300 (damaged hull, no damaged cut) -> ship_fighter_side.png
  ship_destroyer missing=1 (damaged hull, no damaged cut) -> ship_destroyer_side.png
   missing=500 (unknown hull) -> <none>
-- launch.hull_preview(ship_id) --
  ship_fighter -> ship_fighter_side.png
  ship_vanguard -> ship_vanguard_side.png
  ship_gunship -> ship_gunship_side.png
  ship_destroyer -> ship_destroyer_side.png
-- REPAIRS panel=(1560.0, 1792.0) action column RepairsBody/RepairBox --
  column children: ["ControlCaption(Label)", "HullFrame(PanelContainer)", "RepairButton(Button)", "RepairStrip(Label)", "RepairCaption(Label)"]
  ActionSpacer nodes left in panel: 0
  REPAIRS frame=(320.0, 1438.0) image_min=(224.0, 95.78785) expand=1 stretch=5
  REPAIRS native=(905.0, 387.0) target=(224.0, 95.78785) width_share=0.7000 aspect_error=-0.000000
  default active hull: ship_vanguard_side.png
  after _refresh_preview(vanguard, 250): ship_vanguard_damaged_side.png
  REPAIRS/damaged frame=(320.0, 1438.0) image_min=(224.0, 96.07056) expand=1 stretch=5
  REPAIRS/damaged native=(907.0, 389.0) target=(224.0, 96.07056) width_share=0.7000 aspect_error=-0.000000
  after _refresh_preview(vanguard, 0): ship_vanguard_side.png
-- LAUNCH panel=(1560.0, 2010.0) action column LaunchBody/LaunchActionBox --
  column children: ["ActionCaption(Label)", "HullFrame(PanelContainer)", "LaunchButton(Button)", "ConfirmStrip(Label)"]
  ActionSpacer nodes left in panel: 0
  LAUNCH frame=(320.0, 1682.0) image_min=(224.0, 95.78785) expand=1 stretch=5
  LAUNCH native=(905.0, 387.0) target=(224.0, 95.78785) width_share=0.7000 aspect_error=-0.000000
  launch caption: 'VANGUARD — READY' (variation=StationCaption)
exit=0
```

Measured acceptance:

- **intact vs damaged**: with the profile's real active hull (default `ship_vanguard`) the
  mounted REPAIRS panel holds `ship_vanguard_side.png`; `_refresh_preview(&"ship_vanguard", 250)`
  swaps it to `ship_vanguard_damaged_side.png` (905×387 → the 907×389 damaged cut), and
  `missing_hull = 0` swaps it back. No report and repaired both take the intact branch.
- **only vanguard has a damaged cut**: the disk table shows `damaged_exists=true` for
  `ship_vanguard` alone, and the two no-cut hulls resolve to their intact cuts instead of a
  missing resource.
- **contain-fit**: the image is exactly 70.0 % of the frame's width in both panels
  (224.0 of 320.0), aspect error ≤ 0.0000006 (`-0.000000`), `TextureRect` at
  `expand_mode=1` / `stretch_mode=5` inside a `CenterContainer` (centred), and the height clamp
  is not reached at this size.
- **launch caption**: `VANGUARD — READY`, variation `StationCaption` (an existing token).
- **structure**: `HullFrame(PanelContainer)` sits where the removed `ActionSpacer` was in both
  panels, `ActionSpacer` count 0 in both, all other children in their original order.
- No new art: the only textures referenced are the two `assets/ships/*_side.png` files named in
  the brief, resolved through the catalogue; no hex literals and no font-size overrides were added.

Probe artifact worth naming: the mounted panels report a height above the 900 px mount
(1792 / 2010) because a `Container` clamps its own size to its minimum size computed at
zero width before the width pass, and the probe mounts them under a plain `Control`. The widths
— the only thing this measurement is about — are unaffected (frame 320, image 224), and the
shipping shell assigns the panel size itself. The 1560×900 mount width is what the frame
numbers above are relative to.

### 4.3 Gate 2 — the editor's own diagnostics (godot-ai, plugin 4.1.0)

With the editor open (session `vajb-orbit@b6e49ec4e2c3dce2`, `readiness: "ready"`), a no-op
anchor patch on each script (identical `old_text`/`new_text`, so no byte changes) forces a
reload and returns the plugin's diagnostics:

```
script_patch res://ui/station/repairs_panel.gd  -> {"diagnostics":[],"diagnostics_status":"checked","reloaded":true,"size":14042,"replacements":1}
script_patch res://ui/station/launch_panel.gd   -> {"diagnostics":[],"diagnostics_status":"checked","reloaded":true,"size":18782,"replacements":1}
```

Both reload clean with zero diagnostics. (`size` here is the plugin's character count; on disk
the files are 14 053 / 18 797 bytes — the delta is the multibyte `·` and `—` copy in the files,
counted as one char each. `godot-lsp-bridge` diagnostics returned empty for both files, which
`AGENTS.md` records as uninformative, so it is not cited as evidence.)

### 4.4 Gate 3 — project test suite (regression)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn
[SUMMARY] passed=53 failed=0   (exit=0)
```

No suite covers the panels (`grep` for `repairs_panel|launch_panel` under `res://tests` finds
nothing), so this is a regression check that the wave broke no P1 logic, not panel coverage.

## 5. Theme variations used

`PanelRaised` (`vajb_theme.tres:435`, `base_type = &"PanelContainer"`) for both frames and
`StationCaption` (`vajb_theme.tres:488`, `base_type = &"Label"`, 13 px) for the launch caption —
both already shipped and already used by the shipyard frame. No new token, no theme edit
(W5 owns the generator and `vajb_theme.tres` was not touched).

## 6. Cleanup

`tools/` after the wave (mine removed, other waves' probes still in flight):

```
tools/_probe_w1.gd, tools/_probe_w2.gd, tools/_probe_w3.gd, tools/build_theme.gd(+.uid),
tools/derive_icon_tints.gd(+.uid)
```

`rm -f tools/_probe_w4.gd tools/_probe_w4.gd.uid tools/_probe_w4.tscn tools/_probe_w4.tscn.uid`
— no `_probe_w4*` file or sidecar remains. The probe source is not retained (the brief's
throwaway rule), so W6's re-run of the checks means §4.3 (no-op `script_patch`, the editor's own
diagnostics) and §4.4 (the test suite); §4.2's numbers are the W4 reading.

## 7. Deviations and open points

1. **Probe form.** The brief's probe rule names `res://tools/_probe_wN.gd`. A bare
   `--script` run cannot see the autoloads (§4.1), and W4's acceptance needs the panels
   compiled and laid out, so the probe shipped as a `Node` script plus a two-line
   `_probe_w4.tscn` companion driven by a scene run. Both were deleted; nothing was left in
   `tools/`.
2. **Parse check unusable as specified** — §4.1. Reported rather than silently replaced; gates
   4.2 and 4.3 carry the evidence.
3. **Where the render went.** The brief says "the large empty framed area inside
   `RepairControl`". No node is named `RepairControl`; the only empty framed area in that
   section is the action column's free space (the `ActionSpacer` that filled the space above
   REPAIR / LAUNCH). That is what now holds the frame, in both panels, which also matches
   "the same empty frame" in W4.2 and the measured 70 %-of-frame-width fit.
4. **Em dash in `VANGUARD — READY`** is brief-literal copy, with shipped precedent (§2).
5. **`_mockup_station.*`** still carries `SECTOR K-9` and an `ActionSpacer`; out of the W4 file
   list, deleted at the Phase D close-out. Flagged so W6 does not read it as a miss.
6. **Frame size.** The measured frame is 320 px wide inside the 360 px action column (the
   `PanelRaised` content margins plus the 12 px `HullMargin`), so the render is 224 px. If the
   owner wants a larger hull, `PREVIEW_FIT` or the frame margins are the dial; no token or new
   art is involved.
7. **Live visual check not run.** No editor screenshot of the station screen was taken (the
   editor's current scene is `boot.tscn`, and switching scenes under parallel workers risks
   their in-memory edits). The evidence above is structural and measured, not a pixel render;
   the W6 review and the owner walkthrough remain the visual gates, per the brief.
