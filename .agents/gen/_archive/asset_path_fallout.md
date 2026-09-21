# Asset re-layout fallout — handover note for the graphics lane (2026-09-21)

## Status 2026-09-21 ~07:00 (M6 re-review measurement): the list below is empty

Every `res://assets/...` literal in the project source now resolves: a scan of all
`.gd` / `.tscn` / `.tres` outside `addons/` found **181 asset literals, 0
unresolvable (0 files)**. The env family healed after M4's review — `game/pickup.gd`,
`game/sector.gd` and `game/game.tscn` carry their per-family paths as of 02:11 — and
the boot gates agree: `game` exit 0 with only the pre-existing `invalid UID … using
text path instead` warnings (no `SCRIPT ERROR`, `game.gd` compiles again), `menu` and
`settings` clean, `station` clean apart from the pre-existing ObjectDB leak note.
Consequence for the acceptance item this note was carrying: M2's rocks probe's one
`[BLOCK]` is gone (**`ok=25 failed=0 blocked=0`**, "cleave S b: a depleted Small
bursts 1-2 pickups | 1 pickup(s) in the world") — the burst's *spawn* half measures
green again, but the ruling that it "stays unproven end to end until the graphics
lane ships" is unchanged, because spawn → drift → collect → cargo is not measured
here. Evidence: `.agents/gen/slice0_m6_probe_m2_rocks.txt`,
`.agents/gen/slice0_m6_boot_{game,menu,settings,station}.txt`.

Written by the coding orchestrator during engine slice 0. **No code was changed
here.** This is the list the graphics lane needs to finish the naming re-layout
sweep: every `res://assets/...` literal left in the project that no longer
resolves after the move into per-family containers.

Why it matters: the stale paths are **parse-time preloads** in several files, so
the scripts do not load at all. `game.gd` fails to compile transitively through
`sector.gd`, `hud.gd` fails on the tint set, `pickup.gd` and `asteroid.gd` fail
on the `env/pickup/` and `env/prop/` moves. That breaks every boot gate in the
slice-0 wave and one of its acceptance items.

## Already swept by the graphics lane (no action)

- `game/mineral_catalog.gd`, `game/component_catalog.gd`, `ui/screens/station.gd`,
  `ui/station/*`, `tests/test_p1_catalogues.gd` — the icon families moved to
  `assets/icons/<family>/` and the consumers were re-pointed
  (`staging/cut/refile_icon_paths.py`). The gate's single red
  (`test_p1_catalogues.test_mineral_icons_are_the_dedicated_glyphs`) is green
  again as of 2026-09-21 ~01:30.

## Still stale — the env family (12 files, measured by worker M2)

| File | Stale literal | Real location after the move |
|---|---|---|
| `game/pickup.gd` | `env/env_pickup_ore_pod.png` | `env/pickup/` |
| `game/sector.gd` | `env/env_station.png` | `env/poi/` |
| `game/sector_registry.gd` | `env/env_sector_1..7_bg.png` (7 refs) | `env/backdrop/` |
| `game/game.tscn` | `env/env_stars_layer1..3.png` (3 refs) | `env/tile/` |
| `ui/screens/loading.tscn` | `env/env_loading_bg.png` | `env/backdrop/` |
| `ui/screens/main_menu.tscn` | `env/env_menu_bg.png` | `env/backdrop/` |
| `game/asteroid.gd` | `env/env_asteroid_*.png` (9 preloads) | `env/prop/` — **already repaired by M2**, listed for completeness |
| `ui/hud/hud.gd` | `icons/tint/icon_*.png` (11 refs) | the tint set's new container |
| `ui/hud/hud.tscn` | `icons/tint/icon_*.png` (7 refs) | the tint set's new container |
| `ui/screens/_mockup_station.gd` | `icons/tint/*`, `icons/icon_equip_*` (17 refs) | tint set + `icons/equip/` |
| `ui/screens/_mockup_station.tscn` | `icons/icon_equip_*`, `icons/tint/*` (6 refs) | tint set + `icons/equip/` |
| `game/game.gd` | reported by M1 as failing to compile | transitively via `sector.gd` |

Two of these files are scheduled for deletion anyway, so they can be skipped if
the deletion lands first: `ui/screens/_mockup_station.{gd,tscn}`
(`STATION_HUB.md` §12.6, gated on the live S2 verification).

## Owner ruling on this note (2026-09-21)

Asked whether the slice-0 wave should sweep the paths itself, the owner ruled:
**defer — the graphics lane owns the asset tree.** Slice-0 workers therefore
record these failures as *environment-deferred until the designer ships* and do
not touch `assets/**` or any file outside their own set.

## Code-side items the slice-0 wave keeps (not yours)

- `game/pickup.gd`'s one-line preload repair — flagged by M2 as HIGH because it
  blocks the "a Small bursts into pickups" acceptance item. It is a code file in
  no slice-0 worker's set; if the graphics lane's sweep reaches it first, that is
  fine and M5 should not double-edit it.
- `game/player_ship.gd`'s emergency-thrust guard (M2 §6.2) — code, M5's remit.
