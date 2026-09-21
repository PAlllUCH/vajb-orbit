# Full-loop live playtest — 2026-09-21 (session 1)

Driven end-to-end through godot-ai (project_run, input injection, live UI-tree
reads, `game_eval` state pulls, game screenshots). The owner watched the same
run and recorded impressions in `USER_NOTES.md` (workspace root); the
crosscheck table below reconciles both. The session stopped after launch into
open space: the in-flight HUD is visually broken by the same root cause as the
station panels, and the remaining legs (flight/mining/combat/death/economy)
need a clean second session — see "Not covered".

## Verified working (structure + logic)

- Boot → main menu: clean, zero game-log errors. PLAY / OPTIONS / EXIT,
  focus readout, version `VAJB ORBIT v0.2`.
- Main menu → station hub via PLAY (mouse click on the focused row).
- OUTFITTING: 5 ammo packs with correct held/max/status (laser + cannon
  `AT CAP` 300/300; rocket/mine/plasma `OVER CAP`, "capacity is advisory, a
  purchase is never clamped" note present).
- REFINERY: correct empty state — `NO CONVERTIBLE STACKS`, steppers/refine
  buttons disabled, fee row 0, footer "BRING RAW ORE FROM THE BELT".
- EXCHANGE: 20 minerals with live prices, index multipliers and HOT/COOLING
  bands; 18 surplus quotas (kinds SALVAGE/MACHINERY/ELECTRONICS/WEAPONS/POWER/
  ORE-GRADE, grades I–III); hold-empty state; "THE STATION BUYS · IT NEVER
  SELLS IN V1".
- SHIPYARD data: 4 hulls (Lancer 700/3HP FOR SALE 18 000 CR; Vanguard 1000/4HP
  ACTIVE; Bulwark 1400/5HP and Obliterator 2200/7HP LOCKED), comparison table,
  hardpoint plates row (data correct — rendering broken, see D1).
- UPGRADES data: 6 refits available, `0 / 6 SLOTS FILLED`.
- REPAIRS contract: `UNDOCK AND DOCK TO FILE A DAMAGE REPORT`, fee rules in
  footer (1 CR / 2 hull, 1 CR / 3 shield).
- LAUNCH logic: two-press arm/confirm inside the 3 s window works; briefing
  correct (hull/shield limits, 4 hardpoints, cargo 0/40, 1 500 rounds across
  5 weapons). Launched via direct button-handler emit because the real button
  was pushed off-screen (D1).
- Space scene on launch: `/Game` builds correctly — station + DockZone,
  5 asteroid fields / 33 RigidBody2D rocks, NpcPatrol1 + NpcTrader2/3/4,
  PlayerShip (RigidBody2D hull + WeaponComponent), 3-layer star parallax, HUD
  containers, camera.

## Defects

**D1 (blocker, art): `ui_slot_*` chrome ships as whole sheet cells.**
- `ui_slot_weapon_{normal,pressed,hover,disabled}.png` are **880×876 px** and
  `ui_slot_cargo_*.png` are **873×864 px** — entire sheet cells, not cut
  plates. Consumed at native size by:
  - SHIPYARD `Hardpoint01`–`Hardpoint07` (TextureButton, no size constraint) →
    the panel overflows to **6184 px wide / 1224 px tall**; the ship list is
    pushed to x = −2393 (off-screen). The owner sees "only pistols" — correct.
  - LAUNCH `CargoSlot01`–`05` → panel 4781 px wide; `LaunchButton` at
    x ≈ 3178 (off a 1920 screen). The owner sees "only crates" — correct.
  - In-flight HUD slot buttons (1 `SlotButton` + ~40 `@TextureButton@` nodes)
    render the same two textures at native size over the viewport.
- Root cause class is the 2026-09-21 00:17 chrome re-cut regression
  (`ui_chrome_regression.md`): whole-cell cuts. Fix: tight re-cut via
  `staging/phase_f/plates_cut.py` route 1 (target ~64–96 px plates per
  UI_SPEC), plus a code-side guard (D3) so oversized source art can never
  break layout again.

**D2 (known, reconfirmed): remaining chrome regression items** — menu logo
slot (`Logo`, 560×176) renders empty (wordmark crop holds 0 ink pixels); menu
button plates 287×8.6 px ≈90 % transparent; minimap bezel thin; zoom buttons
tiny (3.43 texels/px). All already in `ui_chrome_regression.md`; owner notes
confirm the visual impact (buttons "too small", credits frame "too small",
backgrounds "out of place").

**D3 (defensive, code): TextureButtons consume texture-native size.** Every
affected button relies on the texture's native size (no
`ignore_texture_size`, no `custom_minimum_size`, no stretch). A code guard
makes layout independent of art sizing.

**D4 (housekeeping): stale ext_resource UIDs.** `player_ship.tscn:4` and
`game.tscn:4–6` carry UIDs that no longer resolve
(`ship_vanguard_side.png`, `env_stars_layer{1,2,3}.png`) — engine falls back
to text paths; clean by re-saving the scenes (asset re-layout fallout).

**D5 (lint, one pass): GDScript warnings** — `INT_AS_ENUM_WITHOUT_CAST`
(`settings_manager.gd:391,400,405`), `SHADOWED_VARIABLE(_BASE_CLASS)`
(`router.gd`, `audio_manager.gd`, `dialog_manager.gd`, `player_profile.gd`,
`station.gd:348,407`), `UNUSED_SIGNAL` (`screen.gd:7–9`), unused param
(`refinery_panel.gd:533`), `SHADOWED_GLOBAL_IDENTIFIER`
(`exchange.gd:45`, constant `MineralCatalog` vs global class).

**Unverified (do not fix on this evidence):** Enter on the focused main-menu
button did not activate PLAY (mouse click did) and one rail click (LAUNCH)
did not register — both may be godot-ai input-injection artifacts
(press-without-release); re-test by hand in session 2.

## Crosscheck: USER_NOTES.md ↔ findings

| User note | Agent verification | Root cause |
|---|---|---|
| No VAJB ORBIT logo in loading/main menu | Logo slot present but renders empty (560×176) | D2 wordmark crop regression; loading screen itself untested (boot skipped it) |
| Menu button sprites too small | Button plates 287×8.6 px, ~90 % transparent | D2 |
| Menu animation stuttery | Not measured this session | park for the feel pass; add to session-2 checklist |
| Drydock: use good background images from assets | Viable — asset-library has panel/backdrop plates; needs owner-approved review sheet per pipeline law | design-lane direction, not a defect |
| OUTFITTING: background offset, cells outside it | Panel data correct; chrome geometry suspect | D1/D2 class |
| Module buttons too small, backgrounds need work | Rail rows render, icons small | D2 |
| Credits frame too small | CreditsPanel 135×74, 28 px icon | D2 |
| REFINERY: background/buttons out of place | Panel logic correct | D1/D2 class |
| SHIPYARD: no panel, only pistols | Confirmed + root-caused | D1 (`ui_slot_weapon_*` 880×876) |
| REPAIRS needs overhaul | Data correct; chrome same class | D1/D2 |
| LAUNCH: only crates | Confirmed + root-caused | D1 (`ui_slot_cargo_*` 873×864) |

## Not covered (playtest session 2, after the chrome wave)

Flight physics/fuel/reactor chain, speedometer, mining (lock + cleave +
cargo pickup), combat (weapons vs NPCs, NPC aggression, countermeasures Z/X,
fuel cell R), death/respawn, dock-back economy (sell/refine/repair with real
cargo), upgrades/ship purchase flows, save/load, boot/loading screen (logo),
menu stutter measurement.

## Tooling notes for the next session

- `game_eval` intermittently fails its 250 ms liveness probe while
  `debug_status` shows the loop live; retry once, or fall back to
  `game_manage` ops (`get_ui_elements` never flaked).
- The embedded game freezes when the editor window loses focus (owner typing
  notes); it self-recovers on refocus. Wayland: no shell-side focus tools.
- `editor_screenshot` at `max_resolution=1920` for full-detail evidence.
- Game was stopped mid-space; if the profile autosaved on undock, session 2
  may boot back into space — check the router state before assuming dock.
