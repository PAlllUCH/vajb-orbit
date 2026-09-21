# Wave UI-chrome (code lane) — task brief

Law, in order: `AGENTS.md`, `docs/CONTRACTS.md` (v1.1), `docs/gameplay/18_engine_spec.md`,
this brief, `.agents/gen/WAVEBOARD.md` (state + enforcement protocol). Sources of the
defect evidence: `.agents/gen/playtest_fullloop_20260921.md` (D3/D4/D5) and
`.agents/gen/ui_chrome_regression.md` (the measured chrome table). **Nothing here
re-derives a number; every figure below is copied from those two reports.**

This brief is the **code lane only**. The art re-cut (D1/D2) is the graphics
orchestrator's queue (`.agents/gen/dispatch_designer.md` items 1–3) and is running in
parallel. A worker in this wave **never touches `vajb-orbit/assets/**`, the theme**
(`ui/theme/vajb_theme.tres`, `tools/build_theme.gd`), `project.godot`,
`addons/godot_ai/**`, or `docs/**` except where the worker table below assigns a doc file.

## Why this wave exists

The 2026-09-21 00:17 chrome re-cut shipped whole sheet cells as chrome
(`ui_slot_weapon_*` 880×876, `ui_slot_cargo_*` 873×864 — measured on disk today). Every
consumer is a `TextureButton` whose minimum size is driven by the texture's native size,
because no site sets `ignore_texture_size`. Measured consequences (playtest session 1):
SHIPYARD panel 6184×1224 with the ship list pushed to x = −2393; LAUNCH panel 4781 wide
with `LaunchButton` at x ≈ 3178; the in-flight HUD paints the same textures at native
size over the viewport. The art half is the graphics lane's; **this wave makes the layout
independent of the art**, so oversized source art can never break a panel again.

## Defects owned by this wave

| ID | Defect | Measured evidence |
|---|---|---|
| **D3** | `TextureButton` consumes texture-native size: no `ignore_texture_size`, no stretch anywhere on the slot plates | `ui/components/slot_button.tscn` root `TextureButton` sets only `custom_minimum_size = Vector2(48, 48)`; `ui/components/slot_button.gd` `configure()` sets `custom_minimum_size` to `CELL_SIZE_WEAPON` 48 or `CELL_SIZE_CARGO` 40; `ui/station/shipyard_panel.gd` `_make_plate()` (Hardpoint01–07), `ui/station/launch_panel.gd` `_make_plate()` (CargoSlot01–05) and `ui/hud/hud.gd` `_build_weapon_slots()` / `_ensure_cargo_cells()` all set `custom_minimum_size` only |
| **D4** | Stale `ext_resource` UIDs on two scenes (asset re-layout fallout; engine falls back to the text path and warns on every load) | `game/player_ship.tscn:4` carries `uid://cmi25sgdnd7ga` for `ship_vanguard_side.png`, whose `.import` says `uid://c7myl1rn82g5b`; `game/game.tscn:4-6` carry `uid://o68c15elst7g` / `uid://c4l2b7bxc00k4` / `uid://bipbl3vgvqekw` for `env/tile/env_stars_layer{1,2,3}.png`, whose `.import` files say `uid://fv4vfbadcprt` / `uid://b4nhnjtgrej5n` / `uid://di3dmpv64ldaa`. Also re-check the L16 path list (`game/pickup.gd`, `game/sector.gd`, `game/sector_registry.gd`, `ui/screens/loading.tscn`, `ui/screens/main_menu.tscn`) — the graphics lane reported `asset_path_fallout.md` empty (181 literals, 0 unresolvable), so the remaining defect is the UID field, not the path |
| **D5** | One lint pass over the GDScript warnings session 1 recorded | `INT_AS_ENUM_WITHOUT_CAST` `autoload/settings_manager.gd:391,400,405`; `SHADOWED_VARIABLE(_BASE_CLASS)` `autoload/router.gd`, `autoload/audio_manager.gd`, `autoload/dialog_manager.gd`, `autoload/player_profile.gd`, `ui/screens/station.gd:348,407`; `UNUSED_SIGNAL` `ui/screen.gd:7-9`; unused parameter `ui/station/refinery_panel.gd:533`; `SHADOWED_GLOBAL_IDENTIFIER` `game/exchange.gd:45` (constant `MineralCatalog` vs the global class) |
| **D6** | Doc ticks owed by the batch-2 lane (its worker's file set excluded `docs/`) | `docs/gameplay/19_testing_notes.md` B2-3 still closes with "Tiny coder task + a line in `IMPLEMENTATION_PLAN` §9.8 follow-up" although the fix landed and §9.8 item 6 records it; `docs/CONTRACTS.md` §9's expected count line still says `passed=217` where the measured gate is **219** |

## Worker table

| ID | Role | `VAJB_WORKER_FILES` | Acceptance |
|---|---|---|---|
| **W1** | coder — D3 guard | `vajb-orbit/ui/components/,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/hud/hud.gd,vajb-orbit/tests/` | `ignore_texture_size = true` set at every plate site (scene, `configure()`, both `_make_plate()`s), with the documented 48 weapon / 40 cargo cell sizes preserved; a new headless suite proves the layout is art-independent: with the **current** 880×876 / 873×864 art in place, the shipyard panel's measured size is inside a 1920-wide viewport (today 6184×1224) and the launch panel likewise (today 4781 wide), and the hardpoint/cargo strip reports 7×48 / 5×40. Numbers before and after in the report; gate green |
| **W2** | coder — D4 UIDs | `vajb-orbit/game/game.tscn,vajb-orbit/game/player_ship.tscn,vajb-orbit/game/pickup.gd,vajb-orbit/game/sector.gd,vajb-orbit/game/sector_registry.gd,vajb-orbit/ui/screens/loading.tscn,vajb-orbit/ui/screens/main_menu.tscn,vajb-orbit/tests/` | Every `ext_resource` UID in the two scenes matches its asset's `.import` UID (or is dropped, letting the path resolve); a headless scene-load probe prints no stale-UID warning; every literal in the L16 list still resolves. Re-save through the editor (`scene_open` + `scene_save`) is the sanctioned route when hand-editing a `.tscn` would fight the engine's writer |
| **W3** | coder — D5 lint | `vajb-orbit/autoload/,vajb-orbit/ui/screen.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/game/exchange.gd,vajb-orbit/tests/` | Every warning in the D5 list is gone, verified by re-reading the same line numbers and by a clean parse of each touched file; no behaviour change (the gate stays green, no test edited to hide a warning) |
| **W4** | coder — doc ticks (D6) | `docs/gameplay/19_testing_notes.md,docs/CONTRACTS.md` | B2-3's stale follow-up sentence is corrected to point at §9.8 item 6; CONTRACTS §9's expected count line states the measured `passed=219 failed=0` with the date of the measurement. No other doc file, no code file |
| **W5** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Re-runs W1's layout probe **byte-identically** and re-measures every number W1–W4 reported (the lesson of the last two waves: reviewers probe at the seams by measurement, never by trusting reports); greps the pinned signatures across every changed file and diffs findings against `docs/CONTRACTS.md`, not against this brief; tiers findings HIGH/MED/LOW |
| **W6** | coder — fixer | per W5's per-finding sets | Only dispatched if W5 leaves HIGH or MED findings. One pass, then W5's probe re-run. LOW findings go to `.agents/gen/LOW_BACKLOG.md` and ride with the next wave |

## Hard rules for every dispatch

- `VAJB_WORKER_FILES` exactly as the table; the PreToolUse hook denies writes outside it.
- Bounded Godot runs only: `--quit-after N`, stdout redirected to a log the worker reads.
  Never leave a command unmonitored in the background (the 2026-09-18 wedge rule).
- **Probe hygiene (L17):** a probe that repoints `PlayerProfile.save_path` must stop/flush
  the 0.5 s debounce before restoring it, or the pending write lands on the real
  `user://profile.cfg`.
- The test gate is `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
  --quit-after 1200` on this host (Windows path in `CONTRACTS.md` §9); measured at
  **passed=219 failed=0** before this wave. Grow the count with tests; never shrink it.
- A boot or scene load failing **only** on a missing sprite/texture path is
  *environment-deferred until the designer ships* (owner ruling), not a code finding.
  A probe failing on logic still counts.

## Close-out (orchestrator)

1. Test gate re-run, count recorded.
2. `py -3.14 staging/verify_wave.py verify --baseline ui_chrome_start --forbidden
   project.godot --expect-reports <the wave's reports>` (the harness patch in this wave
   makes `--tests` host-aware; prefer it).
3. `.agents/gen/WAVEBOARD.md` updated: this wave Done with its report paths, item 1's code
   half closed, playtest session 2 still gated on the graphics lane's slot plates.
4. Wave-boundary commit; report to the owner.
