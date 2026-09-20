# S2 — The station's remaining three module panels: SHIPYARD, UPGRADES, LAUNCH

You are a **coder** worker. The station shell and the OUTFITTING panel are built and verified. Build the other three panels the same way, from the same specs. **Do not redesign anything, and do not modify the shell's interface** unless the spec requires it and you say so in your report.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (your cwd). Godot project: `vajb-orbit/`.
- Godot 4.7.2, base render target 1920x1080, stretch `canvas_items`, aspect `expand`.
- **An editor is open on this project (PID 9048). Never run `--headless --editor`.** Never touch `project.godot`, `addons/`, the theme, or `ui/theme/vajb_theme.tres`.
- Headless: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/station.tscn --quit-after 300`
- Kill only a hung Godot of your own; never the editor.

## Read first

1. `AGENTS.md`
2. **`docs/design/STATION_HUB.md`** — sections 4 (node tree), **5.2 SHIPYARD, 5.3 UPGRADES, 5.4 LAUNCH**, 5.6 (insufficient credits), 6 (type scale), 7 (art map, including the ship preview sizing in 7.2 and the additive rule in 7.3), 8 (theme items), 9 (motion), 10 (focus), 11 (audio), and 12 (implementation notes: constants, data wiring, what to delete). Section 12 is your work order.
3. **`docs/design/STATION_SPEC.md`** — the `PlayerProfile` API and the `StationCatalog` entry shapes you read.
4. **`vajb-orbit/ui/station/outfitting_panel.tscn` + `outfitting_panel.gd`** — the pattern to match: row construct, columns, states, affordability presentation, refusal path, `profile_changed` / `purchase_failed` reactions, audio hooks, focus behaviour. Your three panels must look and behave like siblings of it.
5. `vajb-orbit/ui/screens/station.gd` — the shell: how it hosts a panel, what it expects from one, and the placeholder behaviour while a panel file is missing.
6. `vajb-orbit/ui/screens/_mockup_station.gd` — the approved mockup, a working reference for the shipyard comparison table, the cargo strip and the arming beat. Port from it; never copy its stub constants.
7. `vajb-orbit/game/station_catalog.gd`, `autoload/player_profile.gd`, `docs/design/IMPLEMENTATION_PLAN.md` §7 (coding rules) and §9.

## What to build

| File | Contents |
|---|---|
| `vajb-orbit/ui/station/shipyard_panel.tscn` + `.gd` | Hull list with OWNED / ACTIVE / LOCKED rows, the large side-view preview, the comparison table against the active hull, the price, BUY and SET ACTIVE. |
| `vajb-orbit/ui/station/upgrades_panel.tscn` + `.gd` | The six refits with slot, effect, price and status (AVAILABLE / INSTALLED / LOCKED), install through `PlayerProfile.install_upgrade`. |
| `vajb-orbit/ui/station/launch_panel.tscn` + `.gd` | The flight briefing, the cargo plate strip, the manifest from `PlayerProfile.cargo_items()`, and the arming beat that ends in the LAUNCH intent. |

Requirements for all three:

- Every value comes from `StationCatalog` or `PlayerProfile`. **No literal prices, names, ids, counts or credits anywhere.** The one exception is layout geometry, which is a constant.
- React to `profile_changed(&"credits" / &"ships" / &"upgrades" / &"cargo")` by rebuilding the affected rows, and to `purchase_failed(reason, id)` with the status presentation specified in section 12.4 (`REFUSED · ...` in `accent_danger`, the credits-housing pulse, focus and selection untouched, never a dialog).
- Set the ship preview as the spec sizes it (section 7.2), with the documented scale and maximum width. The sprite is RGBA and must not be additively blended; say in your report which blend mode each textured element uses.
- LAUNCH declares `route_requested(&"loading", {destination: &"game"})`, computes the destination line from the route table rather than hard-coding a string, and honours the arm window.
- Full keyboard and pad traversal per section 10: within a panel and out to the rail, one unmistakable focus ring, and the panel must not steal focus from a hidden row.
- `ui_scale` 1.0 and 1.4 must both be correct: use the theme items from section 8, never a per-node font-size override, and let row heights follow the font.
- No `_process` for animation; `Tween`s on the owning node, killed in `_exit_tree()` when they outlive it. No hex literals. No comments unless the why is non-obvious.

## Verification (measurements, not assertions)

1. Headless `res://ui/screens/station.tscn`: exit 0, clean stdout.
2. A throwaway probe at `res://tools/_probe_s2.gd` (`extends SceneTree`, calls `quit()`) that proves, with printed values:
   - each of the three panel scenes loads and instantiates;
   - the SHIPYARD's hull rows and the UPGRADES' refit rows match the catalogue counts and ids exactly (no invented entries, none missing);
   - a scripted `buy_ship` on an affordable hull, `set_active_ship`, and `install_upgrade` each mutate the profile and are reflected in the rebuilt rows, with credits dropping by exactly the catalogue price;
   - the refusal path for `insufficient_credits` and for `already_owned` produces the specified status text and leaves credits unchanged;
   - the LAUNCH panel's computed destination resolves to the route the route table holds;
   - the arm window produces the armed state within its window and reverts afterwards.
3. `ui_scale` 1.0 and 1.4 render without clipped text or overlapping rows (a measured geometry dump or a render is fine).
4. `user://settings.cfg` byte-identical before and after (report both sha256). `user://profile.cfg` must end in its documented default state; restore it and say so if a probe changed it.
5. Delete the probe and its `.uid`; confirm `tools/` holds only `build_theme.gd` and `derive_icon_tints.gd` plus their sidecars.
6. Report everything in `.agents/gen/s2_report.md`, including every judgement call.

**Known engine artifact, do not chase it:** a headless run that has a looping stream playing at exit prints `WARNING: 4 ObjectDB instances were leaked at exit` and `ERROR: 2 resources still in use at exit` for the Ogg playback objects. The orchestrator reproduced and isolated this to the engine's handling of looping streams at process exit (stopping the players and clearing their streams in `_exit_tree` does not prevent it). Filter that line when checking for real errors and do not attempt to fix it.

## Files you own

`ui/station/shipyard_panel.tscn` + `.gd`, `ui/station/upgrades_panel.tscn` + `.gd`, `ui/station/launch_panel.tscn` + `.gd`, `.agents/gen/s2_report.md`. Nothing else: not the shell, not `outfitting_panel.*`, not `ui/paths.gd`, not `loading.gd`, not `game.gd`, not the autoloads, not the menu, not the mockups.

## Rules

- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`. Prefer separate calls.
- No em dashes in code or config.
- Never edit a file you have not read in this session.
- If the spec contradicts the frozen contract, follow the spec and say so in your report.
