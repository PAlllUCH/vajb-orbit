# Vajb Orbit - Asset Catalog

**Generated:** 2026-09-22 23:46 from `vajb-orbit/assets/` by `staging/phase_d/build_catalog.py`. Tables are mechanical (filesystem); do not hand-edit - regenerate instead.

**Scope:** Phase B (109 files, `GENERATION_PLAN.md`) + Phase D expansion (141 files, `ASSET_EXPANSION_SPEC.md`) + Phase E expansion (67 files, `ASSET_EXPANSION_SPEC_E.md`) + Phase F RPG/economy layer (`docs/gameplay/16_art_design_brief.md`) + the F.1 resolution and integrity pass (icon quartet, `ICONS_SPEC.md` 9.7) + the audio family (95 files, `AUDIO_SPEC.md` section 8), all imported by the live editor.

## How to use

- Paths below are relative to `vajb-orbit/`; load as `res://assets/...`. Every file is imported (.import sidecars exist).
- Column `ph`: `F`/`E`/`D` = expansion phases F (RPG/economy layer), E (bases, outposts, bodies, asteroid set B) and D; `B` = original Phase B set.
- Column `a`: `rgba` = sprite with real alpha (cut locally, see expansion spec 11.1); `rgb` = opaque (FX on void black for additive blending, backdrops, tiling layers).
- Each sprite has a `<file>.job.json` manifest (prompt/model/seed/date) next to it; per-family `generation_log.md` and `generation_log_phase_d.md` hold the full history.
- Audio rows come from `staging/audio/audio_report.json`; per-file provenance and loop-seam measurements are in `vajb-orbit/assets/audio/generation_log_audio.md`, and the cue names the code can pass today are in `docs/design/ASSET_WIRING_HANDOFF.md`.
- Never reference these from code, they are provenance only: `style-block.txt`, the `20260917-*`/`20260918-*` run folders (raw generator downloads), and `icons/tint/` (derived white stencils; only the flat glyphs are consumed tinted).
- Visual review sheets (Phase D marked in ember): `staging/phase_d/_preview/review_<family>.png`.

## Summary

| Folder | Files | Phase B | Phase D | Phase E | Phase F |
|---|---|---|---|---|---|
| `res://assets/ships/` | 104 | 33 | 53 | 0 | 18 |
| `res://assets/icons/` | 270 | 151 | 18 | 15 | 86 |
| `res://assets/env/` | 0 | 0 | 0 | 0 | 0 |
| `res://assets/ui/` | 29 | 22 | 7 | 0 | 0 |
| `res://assets/fx/` | 146 | 96 | 35 | 0 | 15 |
| **Total** | **549** | **302** | **113** | **15** | **119** |

| Audio folder | Files |
|---|---|
| `res://assets/audio/music/` | 6 |
| `res://assets/audio/sfx/` | 62 |
| `res://assets/audio/ambience/` | 16 |
| `res://assets/audio/ui/` | 11 |
| **Audio total** | **95** |

## ships - hulls, bosses, liveries

| File | px | a | ph | Purpose |
|---|---|---|---|---|
| `ship_apex_back.png` | 549x1009 | rgba | B | Ship sprite. |
| `ship_apex_front.png` | 531x1046 | rgba | B | Ship sprite. |
| `ship_apex_side.png` | 1180x461 | rgba | B | Ship sprite. |
| `ship_apex_three_quarter.png` | 944x899 | rgba | B | Ship sprite. |
| `ship_bomber_back.png` | 797x903 | rgba | D | Bomber, hostile ordnance (expansion spec 3 #13). Rotation sheet: back view, bow down. |
| `ship_bomber_front.png` | 746x906 | rgba | D | Bomber, hostile ordnance (expansion spec 3 #13). Rotation sheet: front view, bow up. |
| `ship_bomber_side.png` | 954x543 | rgba | D | Bomber, hostile ordnance (expansion spec 3 #13). Rotation sheet: side view, bow right. |
| `ship_bomber_three_quarter.png` | 758x759 | rgba | D | Bomber, hostile ordnance (expansion spec 3 #13). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_boss_boneyard.png` | 2232x1091 | rgba | F | Boneyard Behemoth, S3 Meridian arena boss (SHIPS_SPEC 3.8). Single centred render. |
| `ship_boss_leviathan.png` | 2157x1849 | rgba | D | Leviathan, hammerhead boss (expansion spec 3). Single centred render. |
| `ship_boss_maw.png` | 2061x2110 | rgba | B | Maw dreadnought, boss (SHIPS_SPEC 3.6). Single centred render. |
| `ship_boss_maw_mmo.png` | 2062x2110 | rgba | D | Maw dreadnought, boss (SHIPS_SPEC 3.6). Single centred render. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_boss_pyre.png` | 2235x752 | rgba | F | Pyre Hierophant, S6 Choir arena boss (SHIPS_SPEC 3.9). Single centred render. |
| `ship_boss_spire.png` | 2223x1522 | rgba | D | Spire, relay leviathan boss (expansion spec 3). Single centred render. |
| `ship_boss_thorn.png` | 2225x2114 | rgba | D | Thorn, hive-mother boss (expansion spec 3). Single centred render. |
| `ship_corvette_back.png` | 289x935 | rgba | B | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: back view, bow down. |
| `ship_corvette_front.png` | 303x953 | rgba | B | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: front view, bow up. |
| `ship_corvette_mmo_back.png` | 979x997 | rgba | D | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: back view, bow down. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_corvette_mmo_front.png` | 979x997 | rgba | D | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: front view, bow up. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_corvette_mmo_side.png` | 979x997 | rgba | D | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: side view, bow right. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_corvette_mmo_three_quarter.png` | 979x997 | rgba | D | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: three-quarter view, bow 45 deg. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_corvette_side.png` | 1038x246 | rgba | B | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: side view, bow right. |
| `ship_corvette_three_quarter.png` | 879x806 | rgba | B | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_destroyer_back.png` | 389x1004 | rgba | D | Destroyer, hostile capital (expansion spec 3 #9). Rotation sheet: back view, bow down. |
| `ship_destroyer_front.png` | 440x1019 | rgba | D | Destroyer, hostile capital (expansion spec 3 #9). Rotation sheet: front view, bow up. |
| `ship_destroyer_side.png` | 1028x349 | rgba | D | Destroyer, hostile capital (expansion spec 3 #9). Rotation sheet: side view, bow right. |
| `ship_destroyer_three_quarter.png` | 902x853 | rgba | D | Destroyer, hostile capital (expansion spec 3 #9). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_drone_swarm_back.png` | 1260x940 | rgba | D | Drone swarm unit (expansion spec 3 #10). Rotation sheet: back view, bow down. |
| `ship_drone_swarm_front.png` | 465x844 | rgba | D | Drone swarm unit (expansion spec 3 #10). Rotation sheet: front view, bow up. |
| `ship_drone_swarm_side.png` | 950x349 | rgba | D | Drone swarm unit (expansion spec 3 #10). Rotation sheet: side view, bow right. |
| `ship_drone_swarm_three_quarter.png` | 670x670 | rgba | D | Drone swarm unit (expansion spec 3 #10). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_fighter_back.png` | 1659x1539 | rgba | B | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. |
| `ship_fighter_choir_back.png` | 896x893 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_choir_front.png` | 896x893 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_choir_side.png` | 896x893 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_choir_three_quarter.png` | 896x893 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_concord_back.png` | 896x900 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_concord_front.png` | 896x900 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_concord_side.png` | 896x900 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_concord_three_quarter.png` | 896x900 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_front.png` | 676x843 | rgba | B | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. |
| `ship_fighter_meridian_back.png` | 896x891 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_meridian_front.png` | 896x891 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_meridian_side.png` | 896x891 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_meridian_three_quarter.png` | 896x891 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_mmo_back.png` | 895x889 | rgba | D | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_fighter_mmo_front.png` | 895x889 | rgba | D | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_fighter_mmo_side.png` | 895x889 | rgba | D | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_fighter_mmo_three_quarter.png` | 895x889 | rgba | D | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_fighter_side.png` | 897x415 | rgba | B | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. |
| `ship_fighter_three_quarter.png` | 718x665 | rgba | B | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_freighter_back.png` | 344x936 | rgba | B | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: back view, bow down. |
| `ship_freighter_front.png` | 336x961 | rgba | B | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: front view, bow up. |
| `ship_freighter_mmo_back.png` | 987x975 | rgba | D | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: back view, bow down. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_freighter_mmo_front.png` | 987x975 | rgba | D | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: front view, bow up. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_freighter_mmo_side.png` | 987x975 | rgba | D | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: side view, bow right. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_freighter_mmo_three_quarter.png` | 987x975 | rgba | D | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: three-quarter view, bow 45 deg. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_freighter_side.png` | 982x342 | rgba | B | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: side view, bow right. |
| `ship_freighter_three_quarter.png` | 827x757 | rgba | B | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_gunship_back.png` | 2107x1245 | rgba | D | Gunship, hostile mid-tier (expansion spec 3 #8). Rotation sheet: back view, bow down. |
| `ship_gunship_front.png` | 777x882 | rgba | D | Gunship, hostile mid-tier (expansion spec 3 #8). Rotation sheet: front view, bow up. |
| `ship_gunship_side.png` | 983x644 | rgba | D | Gunship, hostile mid-tier (expansion spec 3 #8). Rotation sheet: side view, bow right. |
| `ship_gunship_three_quarter.png` | 923x838 | rgba | D | Gunship, hostile mid-tier (expansion spec 3 #8). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_interceptor_back.png` | 380x953 | rgba | D | Interceptor, hostile fast attack (expansion spec 3 #7). Rotation sheet: back view, bow down. |
| `ship_interceptor_front.png` | 325x966 | rgba | D | Interceptor, hostile fast attack (expansion spec 3 #7). Rotation sheet: front view, bow up. |
| `ship_interceptor_side.png` | 1016x299 | rgba | D | Interceptor, hostile fast attack (expansion spec 3 #7). Rotation sheet: side view, bow right. |
| `ship_interceptor_three_quarter.png` | 813x778 | rgba | D | Interceptor, hostile fast attack (expansion spec 3 #7). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_mine_layer_back.png` | 441x933 | rgba | D | Mine layer, hostile support (expansion spec 3 #14). Rotation sheet: back view, bow down. |
| `ship_mine_layer_front.png` | 493x951 | rgba | D | Mine layer, hostile support (expansion spec 3 #14). Rotation sheet: front view, bow up. |
| `ship_mine_layer_side.png` | 1062x381 | rgba | D | Mine layer, hostile support (expansion spec 3 #14). Rotation sheet: side view, bow right. |
| `ship_mine_layer_three_quarter.png` | 929x807 | rgba | D | Mine layer, hostile support (expansion spec 3 #14). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_miner_back.png` | 1929x1258 | rgba | F | Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1). Rotation sheet: back view, bow down. |
| `ship_miner_front.png` | 595x881 | rgba | F | Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1). Rotation sheet: front view, bow up. |
| `ship_miner_side.png` | 981x355 | rgba | F | Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1). Rotation sheet: side view, bow right. |
| `ship_miner_three_quarter.png` | 882x790 | rgba | F | Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_patrol_back.png` | 402x972 | rgba | D | Patrol, neutral enforcer (expansion spec 3 #12). Rotation sheet: back view, bow down. |
| `ship_patrol_front.png` | 383x983 | rgba | D | Patrol, neutral enforcer (expansion spec 3 #12). Rotation sheet: front view, bow up. |
| `ship_patrol_side.png` | 1007x384 | rgba | D | Patrol, neutral enforcer (expansion spec 3 #12). Rotation sheet: side view, bow right. |
| `ship_patrol_three_quarter.png` | 906x773 | rgba | D | Patrol, neutral enforcer (expansion spec 3 #12). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_sibelon_back.png` | 2030x1536 | rgba | B | Ship sprite. |
| `ship_sibelon_front.png` | 431x927 | rgba | B | Ship sprite. |
| `ship_sibelon_side.png` | 1057x409 | rgba | B | Ship sprite. |
| `ship_sibelon_three_quarter.png` | 860x770 | rgba | B | Ship sprite. |
| `ship_swarmer_back.png` | 1540x2049 | rgba | B | Ship sprite. |
| `ship_swarmer_front.png` | 553x917 | rgba | B | Ship sprite. |
| `ship_swarmer_side.png` | 1071x504 | rgba | B | Ship sprite. |
| `ship_swarmer_three_quarter.png` | 918x693 | rgba | B | Ship sprite. |
| `ship_trader_back.png` | 2033x1097 | rgba | D | Trader, neutral civil (expansion spec 3 #11). Rotation sheet: back view, bow down. |
| `ship_trader_front.png` | 461x970 | rgba | D | Trader, neutral civil (expansion spec 3 #11). Rotation sheet: front view, bow up. |
| `ship_trader_side.png` | 1022x389 | rgba | D | Trader, neutral civil (expansion spec 3 #11). Rotation sheet: side view, bow right. |
| `ship_trader_three_quarter.png` | 840x782 | rgba | D | Trader, neutral civil (expansion spec 3 #11). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_turret_platform.png` | 1862x1455 | rgba | D | Turret platform, hostile static (expansion spec 3 #15). Single centred render. |
| `ship_vanguard_back.png` | 578x939 | rgba | B | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: back view, bow down. |
| `ship_vanguard_damaged_back.png` | 1023x997 | rgba | B | Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2). Rotation sheet: back view, bow down. |
| `ship_vanguard_damaged_front.png` | 1023x997 | rgba | B | Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2). Rotation sheet: front view, bow up. |
| `ship_vanguard_damaged_side.png` | 1023x997 | rgba | B | Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2). Rotation sheet: side view, bow right. |
| `ship_vanguard_damaged_three_quarter.png` | 1023x997 | rgba | B | Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_vanguard_front.png` | 653x897 | rgba | B | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: front view, bow up. |
| `ship_vanguard_mmo_back.png` | 995x985 | rgba | D | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: back view, bow down. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_vanguard_mmo_front.png` | 995x985 | rgba | D | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: front view, bow up. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_vanguard_mmo_side.png` | 995x985 | rgba | D | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: side view, bow right. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_vanguard_mmo_three_quarter.png` | 995x985 | rgba | D | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: three-quarter view, bow 45 deg. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_vanguard_side.png` | 960x521 | rgba | B | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: side view, bow right. |
| `ship_vanguard_three_quarter.png` | 785x776 | rgba | B | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: three-quarter view, bow 45 deg. |

## icons - glyphs, item art, starmap markers

| File | px | a | ph | Purpose |
|---|---|---|---|---|
| `icon_alt_angled_armor_plates.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_angled_metal_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_angled_pipe_weapon.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_angled_side_enemy_ship.png` | 884x884 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_arched_glowing_vent.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_armored_node_panel.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_arrow_direction_plaque.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_barred_container_silhouette.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_barred_rectangular_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_battery_cells.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_beveled_metal_ingot.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_beveled_plate_dark_gray.png` | 974x372 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_beveled_plate_plain_dark.png` | 974x372 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_beveled_plate_rust_tinge.png` | 974x372 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_broken_jagged_shard.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_buckled_crate_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_chevron_armor_plate.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_chevron_engine_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_chevron_marked_hatch.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_chevron_striped_canister.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_chevron_vent_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_chunky_dark_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_circle_slash.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_circular_ring_hatch.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_claw_hook.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_claw_ring_coupling.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_clawed_cone_lamp.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_cracked_glowing_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_crossed_frame.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_crosshair_target_reticle.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_crosshair_targeting_plaque.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_crystal_cluster_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_cubic_rusty_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_dark_jagged_boulder.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_diamond_box_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_dish_antenna_device.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_dish_antenna_signal.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_dome_arch_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_double_arrow_marker.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_double_barreled_cannon.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_double_grooved_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_double_ridged_bar.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_double_window_panels.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_double_winged_lamp.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_drilled_metal_bar.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_embedded_metal_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_exhaust_thruster_nozzle.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_faceted_dark_crystal.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_flame_emblem.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_flared_tower_silhouette.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_flat_angular_slab.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_flat_plate_dark_gray.png` | 974x372 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_flat_topped_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_front_view_enemy_ship.png` | 884x884 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_glowing_arched_handle.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_glowing_barrel_weapon.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_glowing_coil_module.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_glowing_vertical_core.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_golden_porous_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_gripper_claw_device.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_grooved_rounded_bar.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_hangar_fighter_bay.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_hangar_fighters.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_hollow_metal_pipe.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_hopper_funnel.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_hopper_funnel_unit.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_lattice_patterned_plate.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_launching_pad.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_layered_dark_stone.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_missile_crosshair.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_octagonal_armored_plate.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_octagonal_bracket_frame.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_octagonal_frame_hatch.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_octagonal_ring_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_open_clamp_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_open_metal_crate.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_orange_arc_gauge.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_orange_lined_reactor.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_orange_veined_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_part_4.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_part_4_2.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_part_6.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_perforated_metal_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_pointed_rocket_missile.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_rear_view_enemy_ship.png` | 884x884 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_ridged_rectangular_bar.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_ringed_glowing_device.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_riveted_side_panel.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_robotic_arm.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_robotic_claw_arm.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_rock_with_gem.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_rounded_metal_brick.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_rusty_cone_lamp.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_rusty_fractured_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_rusty_grooved_bar.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_sensor_targeting_modules.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_shield.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_side_podded_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_side_view_enemy_ship.png` | 884x884 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_slotted_metal_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_smooth_clear_shard.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_spiked_metal_rock.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_spiked_naval_mine.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_spiky_mineral_formation.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_split_end_bar.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_square_circuit_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_square_circuit_panel.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_square_metal_plate.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_square_notched_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_stacked_flat_stones.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_stacked_metal_plates.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_stacked_plate_layers.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_stepped_angled_bar.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_stepped_metal_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_striped_dark_mineral.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_tapered_metal_wedge.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_thick_arched_handle.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_thin_arched_handle.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_thin_sharp_shard.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_three_horizontal_bars.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_thruster_engine_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_thruster_exhaust.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_trapezoid_cup_module.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_trapezoid_vent_panel.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_u_channel_bar.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_vault_door.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_vented_power_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_vented_trapezoid_thruster.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_vertical_storage_containers.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_alt_winged_tower_emitter.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_alt_x_scored_block.png` | 512x512 | rgba | B | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_damage.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_emp.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_repair.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_shield.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_speed.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_teleport.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_cargo_container.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_cargo_crate.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_cargo_data_core.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_cargo_fuel_cell.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_cargo_ore.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_cargo_salvage.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_credits.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_contract_escort.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_contract_expedition.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_contract_gather.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_contract_haul.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_contract_hunt.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_equip_drone.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_engine.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_extra.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_generator.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_module.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_pet.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_shield_gen.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_close.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_gear.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_hull.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_logout.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_shield.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_zoom_minus.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_zoom_plus.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_aluminium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_cerulite.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_chromium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_cobalt.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_copper.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_emberite.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_gold.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_iridium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_iron.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_krilium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_neodymium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_nickel.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_osmium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_palladium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_platinum.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_silicon.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_silver.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_titanium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_tungsten.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ingot_voidglass.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_insignia_choir.png` | 512x512 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_insignia_concord.png` | 512x512 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_insignia_meridian.png` | 512x512 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_map_bookmark.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_asteroid.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_danger.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_gate.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_home.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_neutral.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_pvp.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_station.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_route.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_mineral_aluminium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_cerulite.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_chromium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_cobalt.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_copper.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_emberite.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_gold.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_iridium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_iron.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_krilium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_neodymium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_nickel.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_osmium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_palladium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_platinum.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_silicon.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_silver.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_titanium.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_tungsten.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_mineral_voidglass.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_b_afterburner.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_b_fold.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_c_ewar.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_c_nexus.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_c_scanner.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_c_target.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_c_twin.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_e_ion.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_e_std.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_e_vector.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_h_composite.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_h_plate_heavy.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_h_plate_light.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_p_core.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_p_mk2.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_p_std.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_s_heavy.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_s_ion.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_s_light.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_u_cargo.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_u_drones.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_u_holds.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_u_refine.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_u_salvage.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_u_tractor.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_w_mining.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_module_w_railgun.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_service_bounty.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_service_insurance.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_service_vault.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_slot_b.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_slot_c.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_slot_engine.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_slot_h.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_slot_power.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_slot_s.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_slot_u.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_slot_w.svg` | 96x96 | rgba | F | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_status_burning.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_cloaked.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_disabled.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_drained.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_locked.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_radiated.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_repairing.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_shielded.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_slowed.png` | 512x512 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_ammo.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_ammo_laser.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_ammo_rocket.png` | 512x512 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_weapon_cannon.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_weapon_laser.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_weapon_mine.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_weapon_plasma.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |
| `icon_weapon_rocket.svg` | 96x96 | rgba | B | Hand-authored SVG master (flat fills on the 96 grid, imported at 192 px via svg/scale=2). The one master per symbol - Godot scales it. Replaces the _16/_48/_96/_192 raster family and its tint stencils (D2 icon unification, 2026-09-22). |

## env - scenery, POIs, pickups, props

| File | px | a | ph | Purpose |
|---|---|---|---|---|

## ui - chrome, insignia, backdrops

| File | px | a | ph | Purpose |
|---|---|---|---|---|
| `logo_vajb_orbit.png` | 2048x2048 | rgba | B | Game logo (menu title) |
| `ui_backdrop_hangar.png` | 2048x1152 | rgb | D | Hangar screen backdrop, 16:9 opaque (expansion spec 8) |
| `ui_backdrop_login.png` | 2048x1152 | rgb | D | Login/company-select backdrop, 16:9 opaque (expansion spec 8) |
| `ui_backdrop_starmap.png` | 2048x1152 | rgb | D | Starmap screen backdrop, 16:9 opaque (expansion spec 8) |
| `ui_bar_caps.png` | 42x14 | rgba | B | Status bar end caps (42x14) |
| `ui_bar_caps_alt.png` | 317x178 | rgba | B | UI sprite. |
| `ui_button_plate_disabled.png` | 280x56 | rgba | B | UI button plate, disabled state, 280x56 (UI_CHROME_ASSETS_SPEC). |
| `ui_button_plate_hover.png` | 280x56 | rgba | B | UI button plate, hover state, 280x56 (UI_CHROME_ASSETS_SPEC). |
| `ui_button_plate_normal.png` | 280x56 | rgba | B | UI button plate, normal state, 280x56 (UI_CHROME_ASSETS_SPEC). |
| `ui_button_plate_pressed.png` | 280x56 | rgba | B | UI button plate, pressed state, 280x56 (UI_CHROME_ASSETS_SPEC). |
| `ui_insignia_mic.png` | 865x976 | rgba | D | Company emblem: Miner's Incorporated (MENU_FLOW 3.3-3.7) |
| `ui_insignia_mmo.png` | 865x976 | rgba | D | Company emblem: Mars Mining Operations (MENU_FLOW 3.3-3.7) |
| `ui_insignia_neutral.png` | 865x976 | rgba | D | Company emblem: neutral plate (MENU_FLOW 3.3-3.7) |
| `ui_insignia_ven.png` | 865x976 | rgba | D | Company emblem: Venus Resources (MENU_FLOW 3.3-3.7) |
| `ui_minimap_bezel.png` | 200x200 | rgba | B | Minimap bezel ring, 200x200. |
| `ui_panel_frame.png` | 96x96 | rgba | B | 9-slice panel frame, 96x96 with a 32 px painted border band (the nine-slice margin; ICONS_SPEC 9.8 C1) |
| `ui_panel_frame_alt.png` | 1841x1831 | rgba | B | UI sprite. |
| `ui_slot_cargo_disabled.png` | 40x40 | rgba | B | Slot plate: cargo slot, disabled state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_cargo_hover.png` | 40x40 | rgba | B | Slot plate: cargo slot, hover state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_cargo_normal.png` | 40x40 | rgba | B | Slot plate: cargo slot, normal state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_cargo_pressed.png` | 40x40 | rgba | B | Slot plate: cargo slot, pressed state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_inventory_disabled.png` | 56x56 | rgba | B | Slot plate: inventory slot, disabled state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_inventory_hover.png` | 56x56 | rgba | B | Slot plate: inventory slot, hover state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_inventory_normal.png` | 56x56 | rgba | B | Slot plate: inventory slot, normal state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_inventory_pressed.png` | 56x56 | rgba | B | Slot plate: inventory slot, pressed state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_weapon_disabled.png` | 48x48 | rgba | B | Slot plate: weapon slot, disabled state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_weapon_hover.png` | 48x48 | rgba | B | Slot plate: weapon slot, hover state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_weapon_normal.png` | 48x48 | rgba | B | Slot plate: weapon slot, normal state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_weapon_pressed.png` | 48x48 | rgba | B | Slot plate: weapon slot, pressed state (UI_CHROME_ASSETS_SPEC). |

## fx - combat and screen effects

| File | px | a | ph | Purpose |
|---|---|---|---|---|
| `fx_acid_burn.png` | 2048x2048 | rgba | B | FX sprite.. |
| `fx_acid_burn_f1.png` | 864x880 | rgba | B | FX sprite.. |
| `fx_acid_burn_f2.png` | 864x880 | rgba | B | FX sprite.. |
| `fx_acid_burn_f3.png` | 864x880 | rgba | B | FX sprite.. |
| `fx_acid_burn_f4.png` | 864x880 | rgba | B | FX sprite.. |
| `fx_anomaly_grave_glow.png` | 2048x2048 | rgb | F | Grave-cache anomaly glow, steel highlight core, RGB on void black (brief P1) |
| `fx_anomaly_grave_glow_f1.png` | 752x872 | rgba | F | FX sprite.. |
| `fx_anomaly_grave_glow_f2.png` | 752x872 | rgba | F | FX sprite.. |
| `fx_anomaly_grave_glow_f3.png` | 752x872 | rgba | F | FX sprite.. |
| `fx_anomaly_grave_glow_f4.png` | 752x872 | rgba | F | FX sprite.. |
| `fx_anomaly_rift.png` | 2048x2048 | rgb | F | Void-rift anomaly tear, ember pair (hazard), RGB on void black (brief P1) |
| `fx_anomaly_rift_f1.png` | 536x1024 | rgba | F | FX sprite.. |
| `fx_anomaly_rift_f2.png` | 536x1024 | rgba | F | FX sprite.. |
| `fx_anomaly_rift_f3.png` | 536x1024 | rgba | F | FX sprite.. |
| `fx_anomaly_rift_f4.png` | 536x1024 | rgba | F | FX sprite.. |
| `fx_anomaly_shimmer.png` | 2048x2048 | rgb | F | Ore-bloom anomaly shimmer, steel highlight only, RGB on void black (brief P1, 11 section 3.2) |
| `fx_anomaly_shimmer_f1.png` | 784x768 | rgba | F | FX sprite.. |
| `fx_anomaly_shimmer_f2.png` | 784x768 | rgba | F | FX sprite.. |
| `fx_anomaly_shimmer_f3.png` | 784x768 | rgba | F | FX sprite.. |
| `fx_anomaly_shimmer_f4.png` | 784x768 | rgba | F | FX sprite.. |
| `fx_arc_spark.png` | 2048x2048 | rgb | B | FX sprite.. |
| `fx_arc_spark_f1.png` | 912x672 | rgba | B | FX sprite.. |
| `fx_arc_spark_f2.png` | 912x672 | rgba | B | FX sprite.. |
| `fx_arc_spark_f3.png` | 912x672 | rgba | B | FX sprite.. |
| `fx_arc_spark_f4.png` | 912x672 | rgba | B | FX sprite.. |
| `fx_bio_plasma.png` | 2048x2048 | rgb | B | FX sprite.. |
| `fx_bio_plasma_f1.png` | 744x728 | rgba | B | FX sprite.. |
| `fx_bio_plasma_f2.png` | 744x728 | rgba | B | FX sprite.. |
| `fx_bio_plasma_f3.png` | 744x728 | rgba | B | FX sprite.. |
| `fx_bio_plasma_f4.png` | 744x728 | rgba | B | FX sprite.. |
| `fx_cargo_pulse.png` | 2048x2048 | rgb | B | Cargo tractor pulse. |
| `fx_cargo_pulse_f1.png` | 416x384 | rgba | B | FX sprite.. |
| `fx_cargo_pulse_f2.png` | 416x384 | rgba | B | FX sprite.. |
| `fx_cargo_pulse_f3.png` | 416x384 | rgba | B | FX sprite.. |
| `fx_cargo_pulse_f4.png` | 416x384 | rgba | B | FX sprite.. |
| `fx_dash_charge.png` | 2048x2048 | rgb | B | FX sprite.. |
| `fx_dash_charge_f1.png` | 936x960 | rgba | B | FX sprite.. |
| `fx_dash_charge_f2.png` | 936x960 | rgba | B | FX sprite.. |
| `fx_dash_charge_f3.png` | 936x960 | rgba | B | FX sprite.. |
| `fx_dash_charge_f4.png` | 936x960 | rgba | B | FX sprite.. |
| `fx_dust_streak.png` | 2048x2048 | rgba | B | FX sprite.. |
| `fx_dust_streak_f1.png` | 592x64 | rgba | B | FX sprite.. |
| `fx_dust_streak_f2.png` | 592x64 | rgba | B | FX sprite.. |
| `fx_dust_streak_f3.png` | 592x64 | rgba | B | FX sprite.. |
| `fx_dust_streak_f4.png` | 592x64 | rgba | B | FX sprite.. |
| `fx_ember_pulse.png` | 2048x2048 | rgb | B | Ember pulse, generic danger bloom. |
| `fx_ember_pulse_f1.png` | 536x536 | rgba | B | FX sprite.. |
| `fx_ember_pulse_f2.png` | 536x536 | rgba | B | FX sprite.. |
| `fx_ember_pulse_f3.png` | 536x536 | rgba | B | FX sprite.. |
| `fx_ember_pulse_f4.png` | 536x536 | rgba | B | FX sprite.. |
| `fx_ember_ring.png` | 2048x2048 | rgb | B | FX sprite.. |
| `fx_ember_ring_alt.png` | 2048x2048 | rgb | B | FX sprite.. |
| `fx_ember_ring_alt_f1.png` | 840x824 | rgba | B | FX sprite.. |
| `fx_ember_ring_alt_f2.png` | 840x824 | rgba | B | FX sprite.. |
| `fx_ember_ring_alt_f3.png` | 840x824 | rgba | B | FX sprite.. |
| `fx_ember_ring_alt_f4.png` | 840x824 | rgba | B | FX sprite.. |
| `fx_ember_ring_f1.png` | 848x848 | rgba | B | FX sprite.. |
| `fx_ember_ring_f2.png` | 848x848 | rgba | B | FX sprite.. |
| `fx_ember_ring_f3.png` | 848x848 | rgba | B | FX sprite.. |
| `fx_ember_ring_f4.png` | 848x848 | rgba | B | FX sprite.. |
| `fx_emp_arc.png` | 2048x2048 | rgb | D | EMP arc discharge (expansion spec 7) |
| `fx_emp_arc_f1.png` | 824x872 | rgba | D | FX sprite.. |
| `fx_emp_arc_f2.png` | 824x872 | rgba | D | FX sprite.. |
| `fx_emp_arc_f3.png` | 824x872 | rgba | D | FX sprite.. |
| `fx_emp_arc_f4.png` | 824x872 | rgba | D | FX sprite.. |
| `fx_engine_trail.png` | 2048x2048 | rgb | B | Engine trail. |
| `fx_engine_trail_f1.png` | 712x64 | rgba | B | FX sprite.. |
| `fx_engine_trail_f2.png` | 712x64 | rgba | B | FX sprite.. |
| `fx_engine_trail_f3.png` | 712x64 | rgba | B | FX sprite.. |
| `fx_engine_trail_f4.png` | 712x64 | rgba | B | FX sprite.. |
| `fx_explosion.png` | 2048x2048 | rgb | B | Explosion, 5-frame sheet. |
| `fx_explosion_f1.png` | 904x776 | rgba | B | FX sprite.. |
| `fx_explosion_f2.png` | 904x776 | rgba | B | FX sprite.. |
| `fx_explosion_f3.png` | 904x776 | rgba | B | FX sprite.. |
| `fx_explosion_f4.png` | 904x776 | rgba | B | FX sprite.. |
| `fx_explosion_f5.png` | 904x776 | rgba | B | FX sprite.. |
| `fx_hull_critical_vignette.png` | 2048x2048 | rgba | B | Hull-critical screen vignette (single) |
| `fx_hull_critical_vignette_f1.png` | 984x960 | rgba | B | FX sprite.. |
| `fx_hull_critical_vignette_f2.png` | 984x960 | rgba | B | FX sprite.. |
| `fx_hull_critical_vignette_f3.png` | 984x960 | rgba | B | FX sprite.. |
| `fx_hull_critical_vignette_f4.png` | 984x960 | rgba | B | FX sprite.. |
| `fx_jump_portal.png` | 2048x2048 | rgb | D | Jump aperture ring, ember (single frame; expansion spec 7) |
| `fx_jump_portal_f1.png` | 608x680 | rgba | D | FX sprite.. |
| `fx_jump_portal_f2.png` | 608x680 | rgba | D | FX sprite.. |
| `fx_jump_portal_f3.png` | 608x680 | rgba | D | FX sprite.. |
| `fx_jump_portal_f4.png` | 608x680 | rgba | D | FX sprite.. |
| `fx_laser_bolt.png` | 2048x2048 | rgb | B | Laser bolt projectile (single frame) |
| `fx_laser_bolt_f1.png` | 800x160 | rgba | B | FX sprite.. |
| `fx_laser_bolt_f2.png` | 800x160 | rgba | B | FX sprite.. |
| `fx_laser_bolt_f3.png` | 800x160 | rgba | B | FX sprite.. |
| `fx_laser_bolt_f4.png` | 800x160 | rgba | B | FX sprite.. |
| `fx_lock_channel.png` | 2048x2048 | rgb | B | FX sprite.. |
| `fx_lock_channel_f1.png` | 544x552 | rgba | B | FX sprite.. |
| `fx_lock_channel_f2.png` | 544x552 | rgba | B | FX sprite.. |
| `fx_lock_channel_f3.png` | 544x552 | rgba | B | FX sprite.. |
| `fx_lock_channel_f4.png` | 544x552 | rgba | B | FX sprite.. |
| `fx_mine.png` | 1784x1784 | rgba | B | FX sprite.. |
| `fx_mine_f1.png` | 744x736 | rgba | B | FX sprite.. |
| `fx_mine_f2.png` | 744x736 | rgba | B | FX sprite.. |
| `fx_mine_f3.png` | 744x736 | rgba | B | FX sprite.. |
| `fx_mine_f4.png` | 744x736 | rgba | B | FX sprite.. |
| `fx_mining_beam.png` | 2048x2048 | rgb | B | Mining beam, 4-frame sheet. |
| `fx_mining_beam_f1.png` | 440x424 | rgba | B | FX sprite.. |
| `fx_mining_beam_f2.png` | 440x424 | rgba | B | FX sprite.. |
| `fx_mining_beam_f3.png` | 440x424 | rgba | B | FX sprite.. |
| `fx_mining_beam_f4.png` | 440x424 | rgba | B | FX sprite.. |
| `fx_missile_trail.png` | 2048x2048 | rgb | D | Missile trail, 4-frame sheet (expansion spec 7) |
| `fx_missile_trail_f1.png` | 552x248 | rgba | D | FX sprite.. |
| `fx_missile_trail_f2.png` | 552x248 | rgba | D | FX sprite.. |
| `fx_missile_trail_f3.png` | 552x248 | rgba | D | FX sprite.. |
| `fx_missile_trail_f4.png` | 552x248 | rgba | D | FX sprite.. |
| `fx_muzzle_flash.png` | 2048x2048 | rgb | B | Muzzle flash, 4-frame sheet. |
| `fx_muzzle_flash_f1.png` | 504x496 | rgba | B | FX sprite.. |
| `fx_muzzle_flash_f2.png` | 504x496 | rgba | B | FX sprite.. |
| `fx_muzzle_flash_f3.png` | 504x496 | rgba | B | FX sprite.. |
| `fx_muzzle_flash_f4.png` | 504x496 | rgba | B | FX sprite.. |
| `fx_repair_pulse.png` | 2048x2048 | rgb | D | Repair pulse ring, steel highlight (non-ember exception; expansion spec 7) |
| `fx_repair_pulse_f1.png` | 888x904 | rgba | D | FX sprite.. |
| `fx_repair_pulse_f2.png` | 888x904 | rgba | D | FX sprite.. |
| `fx_repair_pulse_f3.png` | 888x904 | rgba | D | FX sprite.. |
| `fx_repair_pulse_f4.png` | 888x904 | rgba | D | FX sprite.. |
| `fx_secondary_explosion.png` | 2048x2048 | rgb | D | Secondary explosion (expansion spec 7) |
| `fx_secondary_explosion_f1.png` | 352x312 | rgba | D | FX sprite.. |
| `fx_secondary_explosion_f2.png` | 352x312 | rgba | D | FX sprite.. |
| `fx_secondary_explosion_f3.png` | 352x312 | rgba | D | FX sprite.. |
| `fx_secondary_explosion_f4.png` | 352x312 | rgba | D | FX sprite.. |
| `fx_shield_break.png` | 2048x2048 | rgb | D | Shield collapse, 4-frame sheet, no ember (expansion spec 7) |
| `fx_shield_break_f1.png` | 536x624 | rgba | D | FX sprite.. |
| `fx_shield_break_f2.png` | 536x624 | rgba | D | FX sprite.. |
| `fx_shield_break_f3.png` | 536x624 | rgba | D | FX sprite.. |
| `fx_shield_break_f4.png` | 536x624 | rgba | D | FX sprite.. |
| `fx_shield_ripple.png` | 2048x2048 | rgb | B | Shield hit ripple (steel highlight) |
| `fx_shield_ripple_f1.png` | 736x720 | rgba | B | FX sprite.. |
| `fx_shield_ripple_f2.png` | 736x720 | rgba | B | FX sprite.. |
| `fx_shield_ripple_f3.png` | 736x720 | rgba | B | FX sprite.. |
| `fx_shield_ripple_f4.png` | 736x720 | rgba | B | FX sprite.. |
| `fx_smoke_plume.png` | 2048x2048 | rgba | B | FX sprite.. |
| `fx_smoke_plume_f1.png` | 464x1024 | rgba | B | FX sprite.. |
| `fx_smoke_plume_f2.png` | 464x1024 | rgba | B | FX sprite.. |
| `fx_smoke_plume_f3.png` | 464x1024 | rgba | B | FX sprite.. |
| `fx_smoke_plume_f4.png` | 464x1024 | rgba | B | FX sprite.. |
| `fx_tractor_beam.png` | 2048x2048 | rgb | D | Tractor beam (expansion spec 7) |
| `fx_tractor_beam_f1.png` | 848x104 | rgba | D | FX sprite.. |
| `fx_tractor_beam_f2.png` | 848x104 | rgba | D | FX sprite.. |
| `fx_tractor_beam_f3.png` | 848x104 | rgba | D | FX sprite.. |
| `fx_tractor_beam_f4.png` | 848x104 | rgba | D | FX sprite.. |

## audio - music, sfx, ambience, ui

Cue resolution and the names the code can pass today: `docs/design/ASSET_WIRING_HANDOFF.md`.

| File | Len s | Ch | Loop | Mode | Purpose | Source |
|---|---|---|---|---|---|---|
| `amb_space_drone_01.ogg` | 223.52 | 2 | yes | loopfix | S13 dead-ship sector drone | projects (yd) |
| `amb_space_float_01.ogg` | 19.512 | 2 | yes | encode | S17 floating ambience 1/2 | raw-audio-oga_ship_floating (OpenGameArt community) |
| `amb_space_float_02.ogg` | 19.512 | 2 | yes | encode | S17 floating ambience 2/2 | raw-audio-oga_ship_floating (OpenGameArt community) |
| `amb_space_misc_01.ogg` | 2.052 | 2 | - | copy | space cue pool, cue 1/5 cut on silence (AUDIO_SPEC 8.4) | raw-audio-oga_joth_space_sounds (Joth) |
| `amb_space_misc_02.ogg` | 5.546 | 2 | - | copy | space cue pool, cue 2/5 cut on silence (AUDIO_SPEC 8.4) | raw-audio-oga_joth_space_sounds (Joth) |
| `amb_space_misc_03.ogg` | 0.34 | 2 | - | copy | space cue pool, cue 3/5 cut on silence (AUDIO_SPEC 8.4) | raw-audio-oga_joth_space_sounds (Joth) |
| `amb_space_misc_04.ogg` | 0.298 | 2 | - | copy | space cue pool, cue 4/5 cut on silence (AUDIO_SPEC 8.4) | raw-audio-oga_joth_space_sounds (Joth) |
| `amb_space_misc_05.ogg` | 5.393 | 2 | - | copy | space cue pool, cue 5/5 cut on silence (AUDIO_SPEC 8.4) | raw-audio-oga_joth_space_sounds (Joth) |
| `amb_space_rumble_01.ogg` | 84.589 | 2 | yes | copy | S15 capital-ship rumble | raw-audio-oga_gmason_engine (gmason) |
| `amb_space_rumble_02.ogg` | 84.589 | 2 | yes | copy | S15 deep rumble | raw-audio-oga_gmason_engine (gmason) |
| `amb_space_wind_01.ogg` | 45.83 | 2 | yes | loopfix | S14 open-space wind bed | raw-audio-oga_space_wind (OpenGameArt community) |
| `amb_station_noise_loop_01.ogg` | 7.232 | 2 | yes | copy | station static bed | sfx_loops (OpenGameArt community) |
| `amb_station_pump_loop_01.ogg` | 3.103 | 2 | yes | copy | station machinery room bed | sfx_loops (OpenGameArt community) |
| `amb_station_room_01.ogg` | 8.234 | 2 | yes | copy | S25 station room tone 1/3 | sfx_loops (OpenGameArt community) |
| `amb_station_room_02.ogg` | 3.17 | 2 | yes | copy | S25 station room tone 2/3 | sfx_loops (OpenGameArt community) |
| `amb_station_room_03.ogg` | 7.042 | 2 | yes | copy | S25 station room tone 3/3 | sfx_loops (OpenGameArt community) |
| `mus_boss_metal_01_loop.ogg` | 40.478 | 2 | yes | loopfix | M4 boss loop | raw-audio-oga_nene_boss_metal (nene) |
| `mus_boss_metal_01_opening.ogg` | 16.991 | 2 | - | encode | M4 boss one-shot opening | raw-audio-oga_nene_boss_metal (nene) |
| `mus_combat_loop_01.ogg` | 24.765 | 2 | yes | encode | M3 combat loop | raw-audio-oga_combat_loops (Ville Nousiainen / XCVG) |
| `mus_exploration_ambient_01.ogg` | 123.0 | 2 | yes | copy | M2 exploration bed | raw-audio-oga_yd_industrial (yd) |
| `mus_exploration_dread_01.ogg` | 317.858 | 2 | yes | loopfix | M5 dread bed (advertises seamless loop) | raw-audio-oga_subspaceaudio_horror (Juhani Junkala) |
| `mus_menu_theme_01.ogg` | 205.228 | 2 | yes | loopfix | M1 main menu theme | raw-audio-oga_yd_space_ambient (yd) |
| `sfx_impact_hull_01.ogg` | 0.168 | 2 | - | copy | S4 hull impact 1/4 | kenney_impact-sounds (Kenney) |
| `sfx_impact_hull_02.ogg` | 0.359 | 2 | - | copy | S4 hull impact 2/4 | kenney_impact-sounds (Kenney) |
| `sfx_impact_hull_03.ogg` | 0.117 | 2 | - | copy | S4 hull impact 3/4 | kenney_impact-sounds (Kenney) |
| `sfx_impact_hull_04.ogg` | 0.207 | 2 | - | copy | S4 hull impact 4/4 | kenney_impact-sounds (Kenney) |
| `sfx_impact_hull_05.ogg` | 0.364 | 2 | - | copy | S4 hull impact 5/5 (plate ring) | kenney_impact-sounds (Kenney) |
| `sfx_impact_rock_01.ogg` | 0.089 | 2 | - | copy | S4 asteroid impact 1/4 | sfx_breaking_and_falling (OpenGameArt community) |
| `sfx_impact_rock_02.ogg` | 0.865 | 2 | - | copy | S4 asteroid impact 2/4 | sfx_breaking_and_falling (OpenGameArt community) |
| `sfx_impact_rock_03.ogg` | 0.08 | 2 | - | copy | S4 asteroid impact 3/4 | sfx_breaking_and_falling (OpenGameArt community) |
| `sfx_impact_rock_04.ogg` | 0.129 | 2 | - | copy | S4 asteroid impact 4/4 | sfx_breaking_and_falling (OpenGameArt community) |
| `sfx_impact_shield_hit_01.ogg` | 0.921 | 2 | - | encode | S5 shield hit 1/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_hit_02.ogg` | 0.941 | 2 | - | encode | S5 shield hit 2/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_hit_03.ogg` | 0.928 | 2 | - | encode | S5 shield hit 3/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_hit_04.ogg` | 0.924 | 2 | - | encode | S5 shield hit 4/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_hit_05.ogg` | 0.941 | 2 | - | encode | S5 shield hit 5/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_hit_06.ogg` | 0.923 | 2 | - | encode | S5 shield hit 6/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_hit_07.ogg` | 0.922 | 2 | - | encode | S5 shield hit 7/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_hit_08.ogg` | 0.901 | 2 | - | encode | S5 shield hit 8/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_hit_09.ogg` | 0.912 | 2 | - | encode | S5 shield hit 9/9 | space-shield-sounds (bart) |
| `sfx_impact_shield_loop_01.ogg` | 5.237 | 2 | yes | copy | S6 shield-up hum (advertises seamless loop) | raw-audio-oga_qubodup_energy_loop (qubodup) |
| `sfx_mining_beam_01.ogg` | 5.237 | 2 | yes | copy | S7 beam bed (same loop as S6, pitched per tier in code) | raw-audio-oga_qubodup_energy_loop (qubodup) |
| `sfx_mining_chip_01.ogg` | 0.486 | 2 | - | copy | S8 chip transient 1/4 | kenney_impact-sounds (Kenney) |
| `sfx_mining_chip_02.ogg` | 0.475 | 2 | - | copy | S8 chip transient 2/4 | kenney_impact-sounds (Kenney) |
| `sfx_mining_chip_03.ogg` | 0.457 | 2 | - | copy | S8 chip transient 3/4 | kenney_impact-sounds (Kenney) |
| `sfx_mining_chip_04.ogg` | 20.901 | 1 | - | copy | S8 chip transient 4/4 | raw-audio-oga_jordan4ibanez_mining (jordan4ibanez) |
| `sfx_ship_boost_01.ogg` | 5.889 | 1 | - | encode | S12 boost / take-off | launch (qubodup) |
| `sfx_ship_engine_01.ogg` | 5.319 | 2 | yes | loopfix | S16 thruster bed 1/2 | raw-audio-oga_ezduzziteh_thruster (EZduzziteh) |
| `sfx_ship_engine_02_loop.ogg` | 6.09 | 2 | yes | encode | S16 thruster bed 2/2 | raw-audio-oga_rocket_engine (OpenGameArt community) |
| `sfx_ship_jump_01.ogg` | 0.115 | 2 | - | copy | S11 teleport / jump 1/2 | sci-fi-sfx (rubberduck) |
| `sfx_ship_jump_02.ogg` | 1.744 | 2 | - | copy | S11 teleport / jump 2/2 | sci-fi-sfx (rubberduck) |
| `sfx_station_boiler_loop_01.ogg` | 22.154 | 2 | yes | encode | S18 boiler body layer | raw-audio-oga_bart_boiler_loop (bart) |
| `sfx_station_breaker_off_01.ogg` | 0.108 | 2 | - | encode | S19 breaker OFF | circuit-breaker (OpenGameArt community) |
| `sfx_station_breaker_on_01.ogg` | 0.168 | 2 | - | encode | S19 breaker ON | circuit-breaker (OpenGameArt community) |
| `sfx_station_hull_crack_01.ogg` | 0.593 | 2 | - | encode | S20 fracture layer (low-pass 120 Hz in code) | deep_breaks (OpenGameArt community) |
| `sfx_station_hull_crack_02.ogg` | 0.463 | 2 | - | encode | S20 fracture layer 2 | deep_breaks (OpenGameArt community) |
| `sfx_station_hull_crack_03.ogg` | 0.433 | 2 | - | encode | S20 fracture layer 3 | deep_breaks (OpenGameArt community) |
| `sfx_station_hull_groan_01.ogg` | 6.581 | 1 | - | copy | S20 hull groan body (pitch 0.6-0.8 in code) | raw-audio-oga_tree_creak (OpenGameArt community) |
| `sfx_station_hull_ring_01.ogg` | 0.427 | 1 | - | encode | S20 metal ring layer 1/3 | metal_interactions (OpenGameArt community) |
| `sfx_station_hull_ring_02.ogg` | 0.432 | 1 | - | encode | S20 metal ring layer 2/3 | metal_interactions (OpenGameArt community) |
| `sfx_station_hull_ring_03.ogg` | 0.308 | 1 | - | encode | S20 metal ring layer 3/3 | metal_interactions (OpenGameArt community) |
| `sfx_station_hum_loop_01.ogg` | 1.735 | 1 | yes | encode | S18 electrical hum layer | raw-audio-oga_qubodup_device_loop (qubodup) |
| `sfx_station_machine_loop_01.ogg` | 1.196 | 2 | yes | copy | S18 machine loop 1/3 | sfx_loops (OpenGameArt community) |
| `sfx_station_machine_loop_02.ogg` | 0.111 | 2 | yes | copy | S18 machine loop 2/3 | sfx_loops (OpenGameArt community) |
| `sfx_station_machine_loop_03.ogg` | 0.121 | 2 | yes | copy | S18 machine loop 3/3 | sfx_loops (OpenGameArt community) |
| `sfx_station_power_off_01.ogg` | 2.207 | 2 | - | copy | S19 blackout event | raw-audio-oga_machine_power_off (OpenGameArt community) |
| `sfx_stinger_anomaly_01.ogg` | 2.774 | 2 | - | encode | S24 anomaly stinger 1/3 | dark_magic (OpenGameArt community) |
| `sfx_stinger_anomaly_02.ogg` | 0.985 | 2 | - | encode | S24 anomaly stinger 2/3 | dark_magic (OpenGameArt community) |
| `sfx_stinger_anomaly_03.ogg` | 2.356 | 2 | - | encode | S24 anomaly stinger 3/3 | dark_magic (OpenGameArt community) |
| `sfx_stinger_boss_roar_01.ogg` | 6.025 | 2 | - | encode | S21 boss arrival | raw-audio-oga_monster_roar (OpenGameArt community) |
| `sfx_stinger_rumble_pass_01.ogg` | 19.091 | 2 | - | encode | S23 something huge is near | raw-audio-oga_rumble_fx (OpenGameArt community) |
| `sfx_stinger_scare_01.ogg` | 22.922 | 2 | - | encode | S22 scare stab 1/2 | horror_sfx (TinyWorlds) |
| `sfx_stinger_scare_02.ogg` | 15.658 | 2 | - | encode | S22 scare stab 2/2 | horror_sfx (TinyWorlds) |
| `sfx_weapon_cannon_01.ogg` | 3.46 | 2 | - | encode | S2 heavy cannon, tier 1 (short turret burst) | raw-audio-oga_tad_doomsday_laser (TAD) |
| `sfx_weapon_cannon_02_medium.ogg` | 8.381 | 2 | - | encode | S2 heavy cannon tier 2 | raw-audio-oga_tad_doomsday_laser (TAD) |
| `sfx_weapon_cannon_03_long.ogg` | 17.974 | 2 | - | encode | S2 heavy cannon tier 3 | raw-audio-oga_tad_doomsday_laser (TAD) |
| `sfx_weapon_explosion_01.ogg` | 1.84 | 2 | - | copy | explosion pool 1/2 | sci-fi-sfx (rubberduck) |
| `sfx_weapon_explosion_02.ogg` | 1.229 | 2 | - | copy | explosion pool 2/2 | sci-fi-sfx (rubberduck) |
| `sfx_weapon_laser_01.ogg` | 0.092 | 2 | - | copy | S1 laser round-robin 1/4 | sci-fi-sfx (rubberduck) |
| `sfx_weapon_laser_02.ogg` | 0.077 | 2 | - | copy | S1 laser round-robin 2/4 | sci-fi-sfx (rubberduck) |
| `sfx_weapon_laser_03.ogg` | 0.064 | 2 | - | copy | S1 laser round-robin 3/4 | sci-fi-sfx (rubberduck) |
| `sfx_weapon_laser_04.ogg` | 1.244 | 2 | - | copy | S1 laser round-robin 4/4 | sci-fi-sfx (rubberduck) |
| `sfx_weapon_rocket_01.ogg` | 2.051 | 2 | - | copy | S3 rocket launch layer | sci-fi-sfx (rubberduck) |
| `sfx_weapon_rocket_02_warhead.ogg` | 1.085 | 2 | - | copy | S3 warhead layer (+80 ms offset in code) | 25-cc0-bang-sfx (OpenGameArt community) |
| `ui_click.ogg` | 0.1 | 1 | - | copy | S9 UI click (primary, exact name the AudioManager resolves) | kenney_interface-sounds (Kenney) |
| `ui_click_02.ogg` | 0.012 | 1 | - | copy | S9 UI click pool 2/5 | kenney_interface-sounds (Kenney) |
| `ui_click_03.ogg` | 0.01 | 1 | - | copy | S9 UI click pool 3/5 | kenney_interface-sounds (Kenney) |
| `ui_click_04.ogg` | 0.022 | 1 | - | copy | S9 UI click pool 4/5 | kenney_interface-sounds (Kenney) |
| `ui_click_05.ogg` | 0.01 | 1 | - | copy | S9 UI click pool 5/5 | kenney_interface-sounds (Kenney) |
| `ui_confirm_01.ogg` | 0.282 | 1 | - | copy | S10 confirmation | kenney_interface-sounds (Kenney) |
| `ui_denied_01.ogg` | 0.104 | 2 | - | copy | S10 denied / blocked action | kenney_interface-sounds (Kenney) |
| `ui_hover.ogg` | 0.043 | 2 | - | copy | S10 UI hover (primary) | kenney_interface-sounds (Kenney) |
| `ui_hover_02.ogg` | 0.043 | 2 | - | copy | S10 UI hover pool 2/3 | kenney_interface-sounds (Kenney) |
| `ui_hover_03.ogg` | 0.383 | 1 | - | copy | S10 UI hover pool 3/3 | kenney_interface-sounds (Kenney) |
| `ui_scroll_01.ogg` | 0.225 | 1 | - | copy | S10 menu scroll | kenney_interface-sounds (Kenney) |

## Provenance appendix

- Audio (`audio/generation_log_audio.md`): every file is CC0 1.0, no attribution required. 25 sources were downloaded into `asset-library/` and recorded in `asset-library/ASSET_MANIFEST.json` with their checksums; the per-file source pack, author and URL are in the table above and in the generation log.
- Run folders (`assets/<family>/20260917-*/`): 0 directories holding the raw generator downloads and their `job.json`; kept for provenance, not consumers.
- `icons/tint/`: 540 PNGs, derived white stencils (RGB = white, alpha byte-identical) of the raster-kept icon masters' historical size cuts, written by `tools/derive_icon_tints.gd`. Engine-side modulate tints them with theme colours. The 135 SVG-side symbols' stencils were retired with their raster families (D2 icon unification, 2026-09-22); the painted D/E stencils stay unused until the tint rework (D3 item 2).
- Phase D panel masters (`panel_equipment`, `panel_map_markers`, `panel_pickups`, `panel_insignia`, `panel_props`) were consumed during splitting and deleted with the other intermediates; only the splits ship (deviation from expansion spec 2.6, recorded in 12).
- Phase F panel masters (`panel_minerals_ore`, `panel_minerals_ingot`, `panel_modules_a/b/c`, `panel_slots`, `panel_contracts`, `panel_service_glyphs`, `panel_faction_insignia`) never entered `assets/`: they stay in `staging/phase_f/<family>/` with their `job.json` files as provenance, and only the cut sprites ship. Per-family evidence: `assets/<family>/generation_log_phase_f.md`.

