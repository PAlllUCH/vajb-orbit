# S1 — Implement the station hub shell + the OUTFITTING panel

You are a **coder** worker. The station screen is designed and approved; build its shipping shell and the first module panel from the spec. **Do not redesign anything.** Where the spec is silent, follow the closest existing project convention and say so in your report.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (your cwd). Godot project: `vajb-orbit/`.
- Godot 4.7.2, base render target 1920x1080, stretch `canvas_items`, aspect `expand`.
- **An editor is open on this project (PID 9048). Never run `--headless --editor`.** Never touch `project.godot`, `addons/`, the theme resource, or `ui/theme/vajb_theme.tres`.
- Headless: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/station.tscn --quit-after 300`
- Kill only a hung Godot of your own; never the editor.

## Read first

1. `AGENTS.md`
2. **`docs/design/STATION_HUB.md`** — the approved spec. Section 4 is the exact node tree, section 5 the per-module spec, section 8 the theme items, section 9 the motion table, section 10 focus and input, section 11 audio hooks, **section 12 the implementation notes: files, build order, constants, data wiring, and what to delete**. That section is your work order.
3. **`docs/design/STATION_SPEC.md`** — the `PlayerProfile` API and the `StationCatalog` data model. You call these; you never write `user://profile.cfg`.
4. `docs/design/IMPLEMENTATION_PLAN.md` — the binding contract: §3.12 (theme assignment), §4.7 (HUD chrome conventions), §7 (coding rules), §9 (Phase D: the flow, the station route, the theme items).
5. `docs/design/THEME_AUDIO_EXTENSION.md` for the theme items you may use, `docs/design/UI_SPEC.md` and `docs/design/STYLE_BIBLE.md` for the laws and the art direction.
6. `vajb-orbit/ui/screens/_mockup_station.tscn` + `_mockup_station.gd` — the approved mockup. It is your visual reference and a working example of the row construct, the states, the focus ring, the entry motion and the arming beat. Port from it; do not copy its stub constants.
7. `vajb-orbit/ui/screen.gd`, `ui/paths.gd`, `ui/screens/loading.gd`, `game/game.gd`, `autoload/player_profile.gd`, `game/station_catalog.gd`, `ui/components/slot_button.gd`.

## What to build

**1. `ui/screens/station.tscn` + `station.gd`** — the shell: backdrop, grain, safe area, header with the credits readout, the module rail, the host, the footer, the entry motion, the module switch, and the focus contract.

- Root is a `Control` on the full-rect preset, `extends Screen`, baking the theme in the `.tscn`.
- Modules: OUTFITTING, SHIPYARD, UPGRADES, LAUNCH plus LOG OUT, exactly as the spec's navigation model describes.
- LAUNCH → `route_requested(&"loading", {destination: &"game"})`; LOG OUT → `route_requested(&"main_menu")`. Never `change_scene_to_*`.
- The host loads a panel scene per module from `ui/station/`. **The three panels that a later worker will write do not exist yet**, so the host must handle a missing panel file gracefully: show an in-place placeholder that names the missing module and does not error, warn or crash. Say in your report exactly how you did that and confirm the placeholder disappears the moment a real panel scene lands.
- Read the profile with `get_node_or_null(^"PlayerProfile")` as section 12.4 instructs, and react to `profile_changed` and `purchase_failed` per that section.

**2. `ui/station/outfitting_panel.tscn` + `.gd`** — the OUTFITTING module, in full, per spec sections 5.1 and 12: the five ammo packs read from `StationCatalog`, held/max from `PlayerProfile`, price, status (AT CAP / IN STOCK / OVER CAP / EMPTY), the advisory hold-capacity copy, affordability presentation, the buy action through `PlayerProfile.buy_ammo`, and the refusal path. This panel is the pattern the later worker copies for the other three, so make it complete and conventional.

**3. Wiring owned by you:**
- `ui/paths.gd`: add `&"station": "res://ui/screens/station.tscn"` to `ROUTES`.
- `ui/screens/loading.gd`: map `destination == &"station"` to the station route, keeping the existing default behaviour.
- `game/game.gd`: `ui_cancel` now docks back to the station, i.e. `route_requested(&"loading", {destination: &"station"})`, replacing the current return to `main_menu`.
- `autoload/audio_manager.gd`: extend the `UiCue` enum with `CONFIRM`, `DENIED` and `SCROLL` so the three already-shipping cue files become reachable, and keep every existing enum value and behaviour intact. Do not change `play_ui` / `play_sfx` signatures or the bus logic.
- `autoload/router.gd`: only if a new font-size item is needed. You should not need one: section 8 of the spec says every item you need exists. If you do add one, it must also join `FONT_SIZE_ITEMS`, and `Router.FONT_SIZE_ITEMS` must stay in sync with the generated theme in both directions.

**4. Audio call sites for the station** per spec section 11: music or ambience on entry, the UI cues on module switches and purchases, the refusal cue on `purchase_failed`. Name real files from `docs/design/ASSET_AUDIT.md` section D.

**5. Leave the mockup alone.** Do not delete `_mockup_station.*`; that happens in a later cleanup step once the real screen is verified. A parallel worker owns the menu and `ui/components/menu_button.*`, so do not touch those either.

## Verification (measurements, not assertions)

1. Headless run of `res://ui/screens/station.tscn`: exit 0, clean stdout. Then the same for `res://ui/screens/main_menu.tscn`, `res://ui/screens/loading.tscn`, `res://game/game.tscn`, `res://ui/screens/boot.tscn`: all exit 0, no new errors or warnings.
2. Prove the navigation and data path with a throwaway probe at `res://tools/_probe_s1.gd` (`extends SceneTree`, calls `quit()`), printing: the resolved route path for `&"station"`, each module's panel path and whether it loads, the credits readout value with `PlayerProfile.credits()`, and the result of a scripted `buy_ammo` call followed by the panel's refreshed held count. Delete the probe and its `.uid` afterwards and confirm `tools/` holds only `build_theme.gd` and `derive_icon_tints.gd` plus their sidecars.
3. Confirm `ui_scale` 1.0 and 1.4 both render correctly (no clipped text, no overlapping rows) using a render or a measured geometry dump.
4. `user://settings.cfg` byte-identical before and after (report both sha256). `user://profile.cfg` must end in its documented default state; if your probe changes it, restore it and say so.
5. Report every command with its output in `.agents/gen/s1_report.md`, plus anything you could not verify and every judgement call you made.

## Files you own

`ui/screens/station.tscn` + `station.gd`, `ui/station/outfitting_panel.tscn` + `.gd`, `ui/paths.gd`, `ui/screens/loading.gd`, `game/game.gd`, `autoload/audio_manager.gd`, `autoload/router.gd` (font list only if strictly needed), and `.agents/gen/s1_report.md`. Nothing else.

## Rules

- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`. Prefer separate calls.
- No em dashes in code or config.
- Never edit a file you have not read in this session.
- If the spec contradicts the frozen contract, follow the spec and say so in your report.
- Another worker is editing `ui/screens/main_menu.*` and `ui/components/menu_button.*` at the same time. Do not open those for writing.
