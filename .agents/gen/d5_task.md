# D5 — Space station hub mockup (live Godot scene) + spec

You are a **designer** worker whose medium is a **Godot 4.7 UI scene**. You build a throwaway, fully working mockup of a space station hub screen so the owner can look at it in the real renderer with the real fonts and art, and you write the spec a coder will follow to build the shipping screen. The mockup must RUN and LOOK like the final thing; it does not ship as-is.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (your cwd). Godot project: `vajb-orbit/`.
- Godot 4.7.2, Forward+, D3D12. **An editor is open on this project (PID 9048). Never run `--headless --editor`.** Never touch `project.godot` or `addons/`.
- Base render target is **1920x1080** (stretch `canvas_items`, aspect `expand`). Design for 1920x1080 and say what happens at 2560x1440, 1600x900 and 21:9.
- Headless check: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_station.tscn --quit-after 300` must exit 0 with clean stdout. The orchestrator will also launch it in the real renderer, so it must look complete with zero input and print nothing.
- Kill a hung Godot after 60 s: `powershell -Command "Get-Process Godot* | Stop-Process"`. Never kill PID 9048.

## Read first (all of it, in this order)

1. `AGENTS.md`
2. `docs/design/STATION_SPEC.md` — **the contract for this screen**: `PlayerProfile`'s API, the save file, and the `StationCatalog` data model with item ids, names, prices and icons. Your rows must show this real data.
3. `docs/design/UI_SPEC.md` — the UI laws (palette roles, 1 px borders, no `_process` for animation, focus rules)
4. `docs/design/STYLE_BIBLE.md` — the art direction
5. `docs/design/IMPLEMENTATION_PLAN.md` — read §3.12 (theme assignment), §4.7 (the HUD, for chrome conventions), and **§9 Phase D amendments**: §9.2 flow, §9.4 the station screen, §9.5 the exact new theme items, §9.6 the mockup workflow
6. `docs/design/ASSET_AUDIT.md` — **section E `STATION_SHORTLIST` and section F art gaps**. This is your art palette. Use only the exact `res://` paths it lists.
7. `docs/design/THEME_AUDIO_EXTENSION.md` — the exact new theme items and variations available to you
8. `vajb-orbit/ui/theme/vajb_theme.tres` — the generated theme, to confirm every item name you use
9. `vajb-orbit/ui/screens/settings.tscn` + `settings.gd` and `vajb-orbit/ui/dialogs/dialog.tscn` — the closest existing screens; match their container and spacing conventions

## Deliverables

| Action | Path |
|---|---|
| create | `vajb-orbit/ui/screens/_mockup_station.tscn` |
| create (only if it needs code) | `vajb-orbit/ui/screens/_mockup_station.gd` |
| create | `docs/design/STATION_HUB.md` |
| create | `.agents/gen/d5_report.md` |

Touch nothing else. Do **not** edit `STATION_SPEC.md`, `station_catalog.gd`, `player_profile.gd`, the theme, any screen, or `project.godot`.

## The brief

Design the screen the player lands on after choosing PLAY: a **space station hub** in the grimdark industrial look, where the player buys ammunition, buys and switches ships, installs upgrades, and launches back into space. It replaces the current straight jump into gameplay.

Required properties:

1. **Four modules plus a way out.** OUTFITTING (buy ammo), SHIPYARD (buy and switch ships), UPGRADES (install upgrades), LAUNCH (leave the station), and LOG OUT (back to the main menu). Propose the navigation pattern (module rail, tabs, cards) and justify it in the spec — this is the single most important design decision on the screen, because the player will bounce between modules constantly.
2. **Real data, stub state.** Rows come from `StationCatalog` (5 ammo packs, 4 ships, 6 upgrades, with the real names, prices and icon paths from `STATION_SPEC.md`). Show a credits readout, owned/locked states, an affordable/unaffordable treatment, and what happens when the player cannot afford something. You must show at least two states per module (owned vs not, affordable vs not, installed vs available).
3. **Responsive, container-driven.** No fixed absolute placement for the major regions; containers and anchors only, with `size_flags` named in the spec. State the behaviour at 21:9 and at 4:3.
4. **The ship preview is the centrepiece of SHIPYARD.** Use a real side-view sprite from the audit's ship list, at a size that reads as a ship (not a thumbnail), with the ship's hull/shield/cargo/hardpoint numbers beside it as comparison rows.
5. **Chrome.** The station is interior architecture: use the hangar/station backdrop and the panel chrome the audit shortlists. Panels must use the new `PanelRaised` variation (a `PanelContainer` variation backed by the framed panel stylebox). Lists must use the new `ItemList` and `ScrollContainer` chrome so nothing falls back to engine defaults.
6. **Motion with intent.** Module switch transition, list hover and selection states, the credits counter, the LAUNCH confirm beat, and an ambient idle layer. Exact durations, curves, and target properties in a motion table. `Tween` only, never `_process`, kill tweens in `_exit_tree()` when they outlive their node.
7. **Keyboard and pad first.** Full focus traversal within and between modules, one unmistakable focus ring, Escape behaviour (propose it: back out of a module, then offer to leave the station), and a visible selected row.
8. **`ui_scale` compatibility.** Correct at 1.0 and 1.4. Use theme items, never per-node font overrides, and name every theme item in the spec.

## Rules for the scene

- Root is a `Control` with the full-rect anchor preset, baking `theme = ExtResource("res://ui/theme/vajb_theme.tres")`.
- No hex literals. Colours come from the theme `Tokens`.
- No `class_name`, no autoload calls, no `Router` calls. Pretend the data: copy the catalogue values you read in `STATION_SPEC.md` into the mockup as local constants and say so in the spec. The coder wave will replace them with real `StationCatalog` reads.
- No literal prices inside the shipping scene's design: prices come from the catalogue. In the mockup, mark every copied value in the spec's implementation notes.
- Must render a complete, presentable screen with zero input.

## `docs/design/STATION_HUB.md` contents

- **Intent**: what this screen is for and the feeling it must produce.
- **Navigation model**: modules, how the player moves between them, what the LAUNCH and LOG OUT paths do, and the justification for the pattern you chose.
- **Composition**: the layout grid with proportions, per region, plus the responsive rule and breakpoint behaviour per region.
- **Node tree**: exact names, types, containers, anchor presets, `size_flags`, `custom_minimum_size`.
- **Per-module spec**: for each of the four modules, the rows/columns, the data shown, the states, the actions, and the empty and error states.
- **Type scale**: every text element with its theme item and role.
- **Art map**: every asset with its `res://` path, role, size and blend mode. Note explicitly which are RGB and must be additive.
- **Motion table** and a **focus and input table**.
- **Audio hooks**: which `AudioManager` calls happen when, naming real files from the audit's shortlist (the service has `play_ui`, `play_sfx`, `play_music`, `play_ambience`).
- **Implementation notes for the coder**: exact constants, which containers to build first, how the modules are instantiated (four panel scenes under `ui/station/`), and what to do when `PlayerProfile.purchase_failed` fires.
- **Open questions** for the owner at the end.

## `.agents/gen/d5_report.md`

What you built, exact commands and their output, the headless exit code, the asset list with a verification that each path exists on disk, and anything you could not verify. Measurements, not assertions.

## Rules

- Invent no asset filename, theme item, catalogue id, price or node name. Item ids and prices must match `STATION_SPEC.md` exactly; asset paths must exist on disk and appear in the audit; theme items must exist in the generated theme.
- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`.
- No em dashes; no comments in code unless the why is non-obvious.
- Another designer is building `_mockup_main_menu.tscn` in the same folders at the same time. Do not touch their files.
