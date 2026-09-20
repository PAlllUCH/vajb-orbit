# Vajb Orbit - Asset Catalog

**Generated:** 2026-09-20 18:42 from `vajb-orbit/assets/` by `staging/phase_d/build_catalog.py`. Tables are mechanical (filesystem); do not hand-edit - regenerate instead.

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
| `res://assets/ships/` | 92 | 21 | 53 | 0 | 18 |
| `res://assets/icons/` | 685 | 88 | 90 | 77 | 430 |
| `res://assets/env/` | 66 | 16 | 20 | 20 | 10 |
| `res://assets/ui/` | 46 | 39 | 7 | 0 | 0 |
| `res://assets/fx/` | 19 | 9 | 7 | 0 | 3 |
| **Total** | **908** | **173** | **177** | **97** | **461** |

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
| `ship_bomber_back.png` | 710x896 | rgba | D | Bomber, hostile ordnance (expansion spec 3 #13). Rotation sheet: back view, bow down. |
| `ship_bomber_front.png` | 697x824 | rgba | D | Bomber, hostile ordnance (expansion spec 3 #13). Rotation sheet: front view, bow up. |
| `ship_bomber_side.png` | 908x299 | rgba | D | Bomber, hostile ordnance (expansion spec 3 #13). Rotation sheet: side view, bow right. |
| `ship_bomber_three_quarter.png` | 682x642 | rgba | D | Bomber, hostile ordnance (expansion spec 3 #13). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_boss_boneyard.png` | 2011x872 | rgba | F | Boneyard Behemoth, S3 Meridian arena boss (SHIPS_SPEC 3.8). Single centred render. |
| `ship_boss_leviathan.png` | 1939x1112 | rgba | D | Leviathan, hammerhead boss (expansion spec 3). Single centred render. |
| `ship_boss_maw.png` | 2048x2048 | rgba | B | Maw dreadnought, boss (SHIPS_SPEC 3.6). Single centred render. |
| `ship_boss_maw_mmo.png` | 1853x1896 | rgba | D | Maw dreadnought, boss (SHIPS_SPEC 3.6). Single centred render. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_boss_pyre.png` | 2014x535 | rgba | F | Pyre Hierophant, S6 Choir arena boss (SHIPS_SPEC 3.9). Single centred render. |
| `ship_boss_spire.png` | 1982x1078 | rgba | D | Spire, relay leviathan boss (expansion spec 3). Single centred render. |
| `ship_boss_thorn.png` | 2003x1203 | rgba | D | Thorn, hive-mother boss (expansion spec 3). Single centred render. |
| `ship_corvette_back.png` | 282x899 | rgba | B | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: back view, bow down. |
| `ship_corvette_front.png` | 276x903 | rgba | B | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: front view, bow up. |
| `ship_corvette_mmo_back.png` | 291x903 | rgba | D | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: back view, bow down. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_corvette_mmo_front.png` | 281x910 | rgba | D | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: front view, bow up. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_corvette_mmo_side.png` | 893x234 | rgba | D | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: side view, bow right. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_corvette_mmo_three_quarter.png` | 686x791 | rgba | D | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: three-quarter view, bow 45 deg. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_corvette_side.png` | 888x231 | rgba | B | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: side view, bow right. |
| `ship_corvette_three_quarter.png` | 676x784 | rgba | B | Corvette, enemy hull class (SHIPS_SPEC 3.4). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_destroyer_back.png` | 330x907 | rgba | D | Destroyer, hostile capital (expansion spec 3 #9). Rotation sheet: back view, bow down. |
| `ship_destroyer_front.png` | 378x918 | rgba | D | Destroyer, hostile capital (expansion spec 3 #9). Rotation sheet: front view, bow up. |
| `ship_destroyer_side.png` | 982x217 | rgba | D | Destroyer, hostile capital (expansion spec 3 #9). Rotation sheet: side view, bow right. |
| `ship_destroyer_three_quarter.png` | 791x802 | rgba | D | Destroyer, hostile capital (expansion spec 3 #9). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_drone_swarm_back.png` | 408x804 | rgba | D | Drone swarm unit (expansion spec 3 #10). Rotation sheet: back view, bow down. |
| `ship_drone_swarm_front.png` | 396x814 | rgba | D | Drone swarm unit (expansion spec 3 #10). Rotation sheet: front view, bow up. |
| `ship_drone_swarm_side.png` | 806x365 | rgba | D | Drone swarm unit (expansion spec 3 #10). Rotation sheet: side view, bow right. |
| `ship_drone_swarm_three_quarter.png` | 509x706 | rgba | D | Drone swarm unit (expansion spec 3 #10). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_fighter_back.png` | 507x808 | rgba | B | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. |
| `ship_fighter_choir_back.png` | 513x818 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_choir_front.png` | 499x791 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_choir_side.png` | 815x348 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_choir_three_quarter.png` | 631x689 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. Ember Choir bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_concord_back.png` | 513x823 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_concord_front.png` | 499x791 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_concord_side.png` | 814x349 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_concord_three_quarter.png` | 631x689 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. Concord of Iron bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_front.png` | 489x698 | rgba | B | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. |
| `ship_fighter_meridian_back.png` | 513x812 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_meridian_front.png` | 499x791 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_meridian_side.png` | 816x351 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_meridian_three_quarter.png` | 632x690 | rgba | F | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. Meridian Free Ports bounty-hunter livery of the base hull (pattern/weathering only; brief P1). |
| `ship_fighter_mmo_back.png` | 514x814 | rgba | D | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: back view, bow down. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_fighter_mmo_front.png` | 499x790 | rgba | D | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: front view, bow up. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_fighter_mmo_side.png` | 814x351 | rgba | D | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_fighter_mmo_three_quarter.png` | 631x688 | rgba | D | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_fighter_side.png` | 817x290 | rgba | B | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: side view, bow right. |
| `ship_fighter_three_quarter.png` | 595x645 | rgba | B | Fighter, enemy hull class (SHIPS_SPEC 3.3). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_freighter_back.png` | 299x826 | rgba | B | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: back view, bow down. |
| `ship_freighter_front.png` | 290x825 | rgba | B | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: front view, bow up. |
| `ship_freighter_mmo_back.png` | 307x886 | rgba | D | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: back view, bow down. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_freighter_mmo_front.png` | 297x886 | rgba | D | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: front view, bow up. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_freighter_mmo_side.png` | 899x256 | rgba | D | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: side view, bow right. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_freighter_mmo_three_quarter.png` | 710x716 | rgba | D | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: three-quarter view, bow 45 deg. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_freighter_side.png` | 892x251 | rgba | B | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: side view, bow right. |
| `ship_freighter_three_quarter.png` | 700x707 | rgba | B | Freighter, enemy hull class (SHIPS_SPEC 3.5). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_gunship_back.png` | 695x802 | rgba | D | Gunship, hostile mid-tier (expansion spec 3 #8). Rotation sheet: back view, bow down. |
| `ship_gunship_front.png` | 710x746 | rgba | D | Gunship, hostile mid-tier (expansion spec 3 #8). Rotation sheet: front view, bow up. |
| `ship_gunship_side.png` | 859x385 | rgba | D | Gunship, hostile mid-tier (expansion spec 3 #8). Rotation sheet: side view, bow right. |
| `ship_gunship_three_quarter.png` | 842x725 | rgba | D | Gunship, hostile mid-tier (expansion spec 3 #8). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_interceptor_back.png` | 173x902 | rgba | D | Interceptor, hostile fast attack (expansion spec 3 #7). Rotation sheet: back view, bow down. |
| `ship_interceptor_front.png` | 147x871 | rgba | D | Interceptor, hostile fast attack (expansion spec 3 #7). Rotation sheet: front view, bow up. |
| `ship_interceptor_side.png` | 940x107 | rgba | D | Interceptor, hostile fast attack (expansion spec 3 #7). Rotation sheet: side view, bow right. |
| `ship_interceptor_three_quarter.png` | 671x777 | rgba | D | Interceptor, hostile fast attack (expansion spec 3 #7). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_mine_layer_back.png` | 360x855 | rgba | D | Mine layer, hostile support (expansion spec 3 #14). Rotation sheet: back view, bow down. |
| `ship_mine_layer_front.png` | 385x834 | rgba | D | Mine layer, hostile support (expansion spec 3 #14). Rotation sheet: front view, bow up. |
| `ship_mine_layer_side.png` | 943x228 | rgba | D | Mine layer, hostile support (expansion spec 3 #14). Rotation sheet: side view, bow right. |
| `ship_mine_layer_three_quarter.png` | 747x705 | rgba | D | Mine layer, hostile support (expansion spec 3 #14). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_miner_back.png` | 621x836 | rgba | F | Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1). Rotation sheet: back view, bow down. |
| `ship_miner_front.png` | 812x810 | rgba | F | Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1). Rotation sheet: front view, bow up. |
| `ship_miner_side.png` | 986x342 | rgba | F | Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1). Rotation sheet: side view, bow right. |
| `ship_miner_three_quarter.png` | 821x695 | rgba | F | Delver miner, player mining hull (SHIPS_SPEC 3.7, brief P1). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_patrol_back.png` | 317x859 | rgba | D | Patrol, neutral enforcer (expansion spec 3 #12). Rotation sheet: back view, bow down. |
| `ship_patrol_front.png` | 325x921 | rgba | D | Patrol, neutral enforcer (expansion spec 3 #12). Rotation sheet: front view, bow up. |
| `ship_patrol_side.png` | 1053x289 | rgba | D | Patrol, neutral enforcer (expansion spec 3 #12). Rotation sheet: side view, bow right. |
| `ship_patrol_three_quarter.png` | 796x718 | rgba | D | Patrol, neutral enforcer (expansion spec 3 #12). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_trader_back.png` | 276x902 | rgba | D | Trader, neutral civil (expansion spec 3 #11). Rotation sheet: back view, bow down. |
| `ship_trader_front.png` | 217x913 | rgba | D | Trader, neutral civil (expansion spec 3 #11). Rotation sheet: front view, bow up. |
| `ship_trader_side.png` | 973x287 | rgba | D | Trader, neutral civil (expansion spec 3 #11). Rotation sheet: side view, bow right. |
| `ship_trader_three_quarter.png` | 701x789 | rgba | D | Trader, neutral civil (expansion spec 3 #11). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_turret_platform.png` | 1903x1726 | rgba | D | Turret platform, hostile static (expansion spec 3 #15). Single centred render. |
| `ship_vanguard_back.png` | 560x898 | rgba | B | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: back view, bow down. |
| `ship_vanguard_damaged_back.png` | 563x899 | rgba | B | Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2). Rotation sheet: back view, bow down. |
| `ship_vanguard_damaged_front.png` | 542x841 | rgba | B | Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2). Rotation sheet: front view, bow up. |
| `ship_vanguard_damaged_side.png` | 907x389 | rgba | B | Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2). Rotation sheet: side view, bow right. |
| `ship_vanguard_damaged_three_quarter.png` | 747x812 | rgba | B | Player Vanguard cutter, damaged variant (SHIPS_SPEC 3.2). Rotation sheet: three-quarter view, bow 45 deg. |
| `ship_vanguard_front.png` | 540x837 | rgba | B | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: front view, bow up. |
| `ship_vanguard_mmo_back.png` | 568x897 | rgba | D | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: back view, bow down. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_vanguard_mmo_front.png` | 549x840 | rgba | D | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: front view, bow up. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_vanguard_mmo_side.png` | 907x394 | rgba | D | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: side view, bow right. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_vanguard_mmo_three_quarter.png` | 739x813 | rgba | D | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: three-quarter view, bow 45 deg. MMO-livery refit of the base hull (pattern/weathering only; expansion spec 4). |
| `ship_vanguard_side.png` | 905x387 | rgba | B | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: side view, bow right. |
| `ship_vanguard_three_quarter.png` | 741x807 | rgba | B | Player Vanguard cutter (SHIPS_SPEC 3.1). Rotation sheet: three-quarter view, bow 45 deg. |

## icons - glyphs, item art, starmap markers

| File | px | a | ph | Purpose |
|---|---|---|---|---|
| `icon_ammo_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ammo_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ammo_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ammo_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ammo_laser.png` | 230x569 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_ammo_laser_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_ammo_laser_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_ammo_laser_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_ammo_laser_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_ammo_rocket.png` | 358x584 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_ammo_rocket_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_ammo_rocket_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_ammo_rocket_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_ammo_rocket_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_damage.png` | 470x601 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_damage_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_damage_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_damage_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_damage_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_emp.png` | 488x676 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_emp_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_emp_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_emp_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_emp_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_repair.png` | 573x645 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_repair_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_repair_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_repair_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_repair_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_shield.png` | 587x564 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_shield_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_shield_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_shield_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_shield_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_speed.png` | 575x692 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_speed_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_speed_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_speed_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_speed_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_teleport.png` | 503x690 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_booster_teleport_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_teleport_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_teleport_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_booster_teleport_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_cargo_container_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_container_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_container_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_container_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_crate_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_crate_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_crate_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_crate_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_data_core.png` | 906x901 | rgba | B | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_cargo_data_core_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_data_core_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_data_core_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_data_core_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_fuel_cell_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_fuel_cell_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_fuel_cell_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_fuel_cell_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_ore_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_ore_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_ore_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_ore_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_salvage_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_salvage_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_salvage_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_cargo_salvage_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_close_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_close_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_close_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_close_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_escort.png` | 530x565 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_contract_escort_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_escort_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_escort_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_escort_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_expedition.png` | 548x560 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_contract_expedition_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_expedition_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_expedition_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_expedition_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_gather.png` | 494x728 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_contract_gather_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_gather_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_gather_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_gather_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_haul.png` | 587x394 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_contract_haul_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_haul_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_haul_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_haul_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_hunt.png` | 573x585 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_contract_hunt_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_hunt_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_hunt_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_contract_hunt_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_credits.png` | 624x719 | rgba | B | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_credits_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_credits_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_credits_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_credits_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_equip_drone.png` | 462x535 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_drone_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_drone_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_drone_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_drone_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_engine.png` | 524x471 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_engine_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_engine_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_engine_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_engine_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_extra.png` | 406x518 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_extra_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_extra_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_extra_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_extra_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_generator.png` | 511x515 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_generator_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_generator_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_generator_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_generator_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_module.png` | 539x351 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_module_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_module_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_module_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_module_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_pet.png` | 422x517 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_pet_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_pet_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_pet_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_pet_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_shield_gen.png` | 473x481 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_equip_shield_gen_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_shield_gen_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_shield_gen_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_equip_shield_gen_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_gear_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_gear_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_gear_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_gear_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_hull_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_hull_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_hull_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_hull_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_aluminium.png` | 315x249 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_aluminium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_aluminium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_aluminium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_aluminium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_cerulite.png` | 343x272 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_cerulite_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_cerulite_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_cerulite_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_cerulite_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_chromium.png` | 348x234 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_chromium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_chromium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_chromium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_chromium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_cobalt.png` | 328x266 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_cobalt_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_cobalt_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_cobalt_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_cobalt_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_copper.png` | 330x256 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_copper_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_copper_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_copper_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_copper_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_emberite.png` | 334x255 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_emberite_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_emberite_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_emberite_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_emberite_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_gold.png` | 332x267 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_gold_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_gold_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_gold_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_gold_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_iridium.png` | 332x259 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_iridium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_iridium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_iridium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_iridium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_iron.png` | 354x266 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_iron_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_iron_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_iron_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_iron_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_krilium.png` | 343x243 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_krilium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_krilium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_krilium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_krilium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_neodymium.png` | 335x269 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_neodymium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_neodymium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_neodymium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_neodymium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_nickel.png` | 331x263 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_nickel_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_nickel_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_nickel_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_nickel_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_osmium.png` | 323x263 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_osmium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_osmium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_osmium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_osmium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_palladium.png` | 339x272 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_palladium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_palladium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_palladium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_palladium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_platinum.png` | 345x280 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_platinum_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_platinum_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_platinum_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_platinum_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_silicon.png` | 372x257 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_silicon_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_silicon_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_silicon_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_silicon_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_silver.png` | 337x257 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_silver_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_silver_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_silver_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_silver_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_titanium.png` | 342x280 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_titanium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_titanium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_titanium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_titanium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_tungsten.png` | 273x290 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_tungsten_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_tungsten_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_tungsten_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_tungsten_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_voidglass.png` | 338x260 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_ingot_voidglass_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_voidglass_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_voidglass_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_ingot_voidglass_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_choir.png` | 678x783 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_insignia_choir_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_choir_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_choir_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_choir_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_concord.png` | 678x789 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_insignia_concord_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_concord_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_concord_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_concord_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_meridian.png` | 681x787 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_insignia_meridian_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_meridian_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_meridian_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_insignia_meridian_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_logout_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_logout_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_logout_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_logout_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_map_bookmark.png` | 411x506 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_bookmark_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_bookmark_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_bookmark_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_bookmark_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_asteroid.png` | 539x682 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_asteroid_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_asteroid_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_asteroid_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_asteroid_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_danger.png` | 394x657 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_danger_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_danger_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_danger_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_danger_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_gate.png` | 531x471 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_gate_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_gate_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_gate_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_gate_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_home.png` | 433x572 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_home_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_home_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_home_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_home_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_neutral.png` | 514x563 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_neutral_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_neutral_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_neutral_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_neutral_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_pvp.png` | 486x468 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_pvp_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_pvp_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_pvp_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_pvp_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_station.png` | 485x541 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_node_station_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_station_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_station_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_node_station_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_route.png` | 516x503 | rgba | D | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_map_route_16.png` | 16x16 | rgba | D | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_route_192.png` | 192x192 | rgba | D | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_route_48.png` | 48x48 | rgba | D | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_map_route_96.png` | 96x96 | rgba | D | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_mineral_aluminium.png` | 363x227 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_aluminium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_aluminium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_aluminium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_aluminium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_cerulite.png` | 313x342 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_cerulite_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_cerulite_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_cerulite_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_cerulite_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_chromium.png` | 292x334 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_chromium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_chromium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_chromium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_chromium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_cobalt.png` | 283x333 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_cobalt_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_cobalt_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_cobalt_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_cobalt_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_copper.png` | 341x316 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_copper_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_copper_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_copper_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_copper_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_emberite.png` | 298x315 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_emberite_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_emberite_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_emberite_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_emberite_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_gold.png` | 326x332 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_gold_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_gold_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_gold_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_gold_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_iridium.png` | 337x376 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_iridium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_iridium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_iridium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_iridium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_iron.png` | 333x323 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_iron_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_iron_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_iron_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_iron_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_krilium.png` | 357x349 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_krilium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_krilium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_krilium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_krilium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_neodymium.png` | 299x332 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_neodymium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_neodymium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_neodymium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_neodymium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_nickel.png` | 335x304 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_nickel_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_nickel_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_nickel_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_nickel_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_osmium.png` | 353x407 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_osmium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_osmium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_osmium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_osmium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_palladium.png` | 249x317 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_palladium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_palladium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_palladium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_palladium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_platinum.png` | 333x302 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_platinum_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_platinum_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_platinum_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_platinum_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_silicon.png` | 383x259 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_silicon_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_silicon_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_silicon_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_silicon_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_silver.png` | 304x391 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_silver_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_silver_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_silver_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_silver_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_titanium.png` | 319x342 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_titanium_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_titanium_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_titanium_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_titanium_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_tungsten.png` | 319x339 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_tungsten_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_tungsten_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_tungsten_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_tungsten_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_voidglass.png` | 318x301 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_mineral_voidglass_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_voidglass_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_voidglass_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_mineral_voidglass_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_b_afterburner.png` | 531x377 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_b_afterburner_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_b_afterburner_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_b_afterburner_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_b_afterburner_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_b_fold.png` | 458x452 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_b_fold_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_b_fold_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_b_fold_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_b_fold_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_ewar.png` | 575x385 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_c_ewar_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_ewar_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_ewar_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_ewar_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_nexus.png` | 460x427 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_c_nexus_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_nexus_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_nexus_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_nexus_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_scanner.png` | 424x520 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_c_scanner_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_scanner_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_scanner_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_scanner_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_target.png` | 473x464 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_c_target_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_target_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_target_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_target_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_twin.png` | 353x515 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_c_twin_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_twin_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_twin_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_c_twin_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_ion.png` | 495x453 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_e_ion_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_ion_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_ion_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_ion_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_std.png` | 502x416 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_e_std_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_std_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_std_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_std_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_vector.png` | 575x481 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_e_vector_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_vector_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_vector_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_e_vector_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_composite.png` | 490x484 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_h_composite_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_composite_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_composite_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_composite_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_plate_heavy.png` | 604x329 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_h_plate_heavy_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_plate_heavy_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_plate_heavy_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_plate_heavy_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_plate_light.png` | 497x448 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_h_plate_light_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_plate_light_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_plate_light_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_h_plate_light_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_core.png` | 562x453 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_p_core_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_core_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_core_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_core_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_mk2.png` | 488x481 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_p_mk2_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_mk2_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_mk2_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_mk2_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_std.png` | 514x434 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_p_std_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_std_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_std_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_p_std_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_heavy.png` | 554x450 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_s_heavy_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_heavy_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_heavy_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_heavy_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_ion.png` | 559x388 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_s_ion_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_ion_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_ion_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_ion_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_light.png` | 545x328 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_s_light_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_light_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_light_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_s_light_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_cargo.png` | 499x462 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_u_cargo_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_cargo_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_cargo_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_cargo_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_drones.png` | 548x420 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_u_drones_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_drones_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_drones_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_drones_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_holds.png` | 468x487 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_u_holds_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_holds_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_holds_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_holds_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_refine.png` | 489x542 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_u_refine_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_refine_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_refine_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_refine_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_salvage.png` | 610x386 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_u_salvage_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_salvage_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_salvage_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_salvage_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_tractor.png` | 610x360 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_u_tractor_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_tractor_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_tractor_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_u_tractor_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_w_mining.png` | 552x235 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_w_mining_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_w_mining_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_w_mining_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_w_mining_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_w_railgun.png` | 644x242 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_module_w_railgun_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_w_railgun_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_w_railgun_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_module_w_railgun_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_bounty.png` | 692x701 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_service_bounty_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_bounty_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_bounty_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_bounty_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_insurance.png` | 610x746 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_service_insurance_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_insurance_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_insurance_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_insurance_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_vault.png` | 761x726 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_service_vault_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_vault_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_vault_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_service_vault_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_shield.png` | 594x744 | rgba | B | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_shield_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_shield_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_shield_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_shield_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_b.png` | 404x349 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_slot_b_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_b_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_b_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_b_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_c.png` | 371x370 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_slot_c_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_c_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_c_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_c_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_engine.png` | 405x365 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_slot_engine_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_engine_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_engine_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_engine_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_h.png` | 396x321 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_slot_h_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_h_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_h_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_h_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_power.png` | 408x384 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_slot_power_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_power_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_power_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_power_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_s.png` | 431x366 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_slot_s_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_s_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_s_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_s_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_u.png` | 408x415 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_slot_u_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_u_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_u_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_u_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_w.png` | 414x322 | rgba | F | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_slot_w_16.png` | 16x16 | rgba | F | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_w_192.png` | 192x192 | rgba | F | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_w_48.png` | 48x48 | rgba | F | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_slot_w_96.png` | 96x96 | rgba | F | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_status_burning.png` | 437x462 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_burning_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_burning_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_burning_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_burning_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_cloaked.png` | 418x536 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_cloaked_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_cloaked_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_cloaked_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_cloaked_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_disabled.png` | 439x493 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_disabled_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_disabled_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_disabled_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_disabled_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_drained.png` | 269x475 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_drained_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_drained_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_drained_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_drained_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_locked.png` | 456x436 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_locked_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_locked_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_locked_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_locked_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_radiated.png` | 498x498 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_radiated_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_radiated_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_radiated_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_radiated_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_repairing.png` | 457x467 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_repairing_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_repairing_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_repairing_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_repairing_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_shielded.png` | 489x638 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_shielded_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_shielded_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_shielded_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_shielded_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_slowed.png` | 470x531 | rgba | E | Painted icon master (source of the icon splits; not a runtime sprite). |
| `icon_status_slowed_16.png` | 16x16 | rgba | E | Painted icon split, 16 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_slowed_192.png` | 192x192 | rgba | E | Painted icon split, 192 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_slowed_48.png` | 48x48 | rgba | E | Painted icon split, 48 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_status_slowed_96.png` | 96x96 | rgba | E | Painted icon split, 96 px. Direct consumer, no tint derivation (expansion spec 11.2). |
| `icon_weapon_cannon_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_cannon_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_cannon_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_cannon_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_laser_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_laser_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_laser_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_laser_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_mine_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_mine_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_mine_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_mine_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_plasma_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_plasma_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_plasma_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_plasma_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_rocket_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_rocket_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_rocket_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_weapon_rocket_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_zoom_minus.png` | 718x703 | rgba | B | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_zoom_minus_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_zoom_minus_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_zoom_minus_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_zoom_minus_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_zoom_plus.png` | 712x702 | rgba | B | Flat single-colour glyph master (retained re-cut source of the _16/_48/_96/_192 cuts). |
| `icon_zoom_plus_16.png` | 16x16 | rgba | B | Flat single-colour glyph, 16 px, micro chip band (HUD spots; ICONS_SPEC 6 legibility check); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_zoom_plus_192.png` | 192x192 | rgba | B | Flat single-colour glyph, 192 px, detail band (inspect panes, 4K + UI-scale headroom); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_zoom_plus_48.png` | 48x48 | rgba | B | Flat single-colour glyph, 48 px, legacy consumer band (never silently re-pointed); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `icon_zoom_plus_96.png` | 96x96 | rgba | B | Flat single-colour glyph, 96 px, default band for new consumers (1:1 at 4K / 2x canvas); contain-fit cut from the master, tintable via icons/tint/ (ICONS_SPEC 9.2/9.6). |
| `panel_boosters.png` | 2048x2048 | rgba | E | Icon atlas panel, 2K (booster consumable icons, 2x3 - spec E 6). Source of the cut icon_* sprites; not a runtime sprite. |
| `panel_cargo.png` | 2048x2048 | rgb | B | Icon atlas panel, 2K (cargo item glyphs, 2x3). Source of the cut icon_* sprites; not a runtime sprite. |
| `panel_glyphs.png` | 2048x2048 | rgb | B | Icon atlas panel, 2K (HUD glyphs, 3x3). Source of the cut icon_* sprites; not a runtime sprite. |
| `panel_status.png` | 2048x2048 | rgba | E | Icon atlas panel, 2K (HUD status effect icons, 3x3 - spec E 6). Source of the cut icon_* sprites; not a runtime sprite. |
| `panel_weapons.png` | 2048x2048 | rgb | B | Icon atlas panel, 2K (weapon glyphs, 2x3). Source of the cut icon_* sprites; not a runtime sprite. |

## env - scenery, POIs, pickups, props

| File | px | a | ph | Purpose |
|---|---|---|---|---|
| `env_arena_barricade.png` | 954x1484 | rgba | F | Arena prop: bolted barricade plate run, no lamps (brief P1, 14 section 5). |
| `env_arena_nav_pylon.png` | 887x936 | rgba | F | Arena prop: nav-pylon ring beacon post, ember lamps (brief P1, 14 section 5). |
| `env_asteroid_b1.png` | 618x771 | rgba | E | Rock look 2: large elongated cigar body (spec E 7). |
| `env_asteroid_b2.png` | 632x623 | rgba | E | Rock look 2: large twin-lobed body (spec E 7). |
| `env_asteroid_b3.png` | 559x538 | rgba | E | Rock look 2: medium heavily pitted body (spec E 7). |
| `env_asteroid_b4.png` | 567x657 | rgba | E | Rock look 2: medium ore-flecked body (spec E 7). |
| `env_asteroid_b5.png` | 404x413 | rgba | E | Rock look 2: small flat shard (spec E 7). |
| `env_asteroid_b6.png` | 433x466 | rgba | E | Rock look 2: small rubble cluster (spec E 7). |
| `env_asteroid_L1.png` | 649x676 | rgba | B | Asteroid sprite, size tier L1 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_asteroid_L2.png` | 555x642 | rgba | B | Asteroid sprite, size tier L2 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_asteroid_L3.png` | 636x649 | rgba | B | Asteroid sprite, size tier L3 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_asteroid_M1.png` | 522x482 | rgba | B | Asteroid sprite, size tier M1 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_asteroid_M2.png` | 499x552 | rgba | B | Asteroid sprite, size tier M2 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_asteroid_M3.png` | 539x519 | rgba | B | Asteroid sprite, size tier M3 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_asteroid_S1.png` | 314x329 | rgba | B | Asteroid sprite, size tier S1 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_asteroid_S2.png` | 370x361 | rgba | B | Asteroid sprite, size tier S2 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_asteroid_S3.png` | 336x340 | rgba | B | Asteroid sprite, size tier S3 (S/M/L x1-3; ENVIRONMENT_SPEC 4). |
| `env_base_defense.png` | 1744x1670 | rgba | E | Defense fortress: terraced casemates, battery row, sensor masts (spec E 3). |
| `env_base_mining.png` | 1955x1722 | rgba | E | Mining base, station-scale POI: silo row, crusher derrick, conveyor arms (spec E 3). |
| `env_base_shipyard.png` | 1929x1105 | rgba | E | Shipyard/drydock: empty construction cradle between gantry towers (spec E 3). |
| `env_base_trade.png` | 2004x1344 | rgba | E | Trade/refinery base: docking ring, mooring arms, transfer cranes (spec E 3). |
| `env_bg_body_plate.png` | 2048x1152 | rgb | E | Background body plate, 16:9 opaque parallax layer (spec E 5). |
| `env_body_ice_moon.png` | 1839x1873 | rgba | E | Airless ice moon, top-down body sprite (spec E 5). |
| `env_body_ore_moon.png` | 1871x1906 | rgba | E | Airless mining-scarred moon with ore seams (spec E 5). |
| `env_body_shattered.png` | 1870x1891 | rgba | E | Airless shattered moon with a chunk ring (spec E 5). |
| `env_debris_field.png` | 1986x1956 | rgba | D | Scattered torn-hull debris field (expansion spec 6). |
| `env_ice_field.png` | 1891x1869 | rgba | D | Frozen fragment cluster (expansion spec 6). |
| `env_jump_gate.png` | 1936x1277 | rgba | D | Jump gate structure, welded pylons + segmented ring (expansion spec 6). |
| `env_jump_gate_ring.png` | 1636x1590 | rgba | F | Jump gate ring: segmented radial structure with four engine blocks, no aperture glow (brief P1, 11 section 2.1). |
| `env_loading_bg.png` | 2048x1152 | rgb | B | Loading screen background, 16:9 opaque. |
| `env_menu_bg.png` | 2048x1152 | rgb | B | Main menu background, 16:9 opaque (MAIN_MENU_SPEC). |
| `env_mine.png` | 1396x1588 | rgba | E | Deployed mine world object: spiked sphere, ember seam lamp (spec E 7). |
| `env_nebula_veil.png` | 2048x2048 | rgb | D | Tiling nebula haze, very low contrast, RGB (expansion spec 6). |
| `env_ore_cluster.png` | 1790x1803 | rgba | D | Dense mineable ore cluster with veins (expansion spec 6). |
| `env_outpost_defense.png` | 1156x1591 | rgba | E | Defense outpost: stacked turrets on an armoured drum (spec E 4). |
| `env_outpost_mining.png` | 1220x1843 | rgba | E | Mining outpost: drill tower anchored on a rock chunk (spec E 4). |
| `env_outpost_relay.png` | 636x1864 | rgba | E | Comms relay outpost: lattice mast with three dishes (spec E 4). |
| `env_outpost_repair.png` | 1350x1934 | rgba | E | Repair post: open cradle, clamp arms, tool rack (spec E 4). |
| `env_pickup_ammo_pod.png` | 725x443 | rgba | D | World pickup: ammo canister (expansion spec 5). |
| `env_pickup_bonus_box.png` | 755x463 | rgba | D | World pickup: sealed ordnance crate (expansion spec 5). |
| `env_pickup_ore_pod.png` | 760x463 | rgba | D | World pickup: ore container (expansion spec 5). |
| `env_pickup_repair_pod.png` | 728x510 | rgba | D | World pickup: repair pod (expansion spec 5). |
| `env_pickup_shield_pod.png` | 524x502 | rgba | D | World pickup: shield emitter pod (expansion spec 5). |
| `env_pickup_speed_pod.png` | 780x284 | rgba | D | World pickup: speed boost pod (expansion spec 5). |
| `env_planet_moon.png` | 1601x1650 | rgba | D | Airless dead moon (map/skybox POI; expansion spec 6). |
| `env_prop_drive_core.png` | 631x748 | rgba | D | Wreck fragment: drive core (expansion spec 9). |
| `env_prop_hull_mid.png` | 581x755 | rgba | D | Wreck fragment: mid section (expansion spec 9). |
| `env_prop_hull_nose.png` | 584x864 | rgba | D | Wreck fragment: bow section (expansion spec 9). |
| `env_prop_hull_stern.png` | 591x816 | rgba | D | Wreck fragment: stern section (expansion spec 9). |
| `env_prop_plate_section.png` | 551x823 | rgba | D | Wreck fragment: plate section (expansion spec 9). |
| `env_prop_rib_cluster.png` | 580x826 | rgba | D | Wreck fragment: rib cluster (expansion spec D 9). |
| `env_sector_1_bg.png` | 2048x1152 | rgb | F | Sector backdrop: Halcyon Reach, ordered home space, 2048x1152 opaque (brief P1, 11 section 1). |
| `env_sector_2_bg.png` | 2048x1152 | rgb | F | Sector backdrop: Iron Marches, the industrial belt, 2048x1152 opaque (brief P1). |
| `env_sector_3_bg.png` | 2048x1152 | rgb | F | Sector backdrop: Meridian Span, the trade crossroads, 2048x1152 opaque (brief P1). |
| `env_sector_4_bg.png` | 2048x1152 | rgb | F | Sector backdrop: Ashveil Expanse, the contested edge, 2048x1152 opaque (brief P1). |
| `env_sector_5_bg.png` | 2048x1152 | rgb | F | Sector backdrop: Cinder Verge, exotic territory, 2048x1152 opaque (brief P1). |
| `env_sector_6_bg.png` | 2048x1152 | rgb | F | Sector backdrop: The Hollows, the deep exotic belt, 2048x1152 opaque (brief P1). |
| `env_sector_7_bg.png` | 2048x1152 | rgb | F | Sector backdrop: Maw Belt, lawless arena belt, 2048x1152 opaque (brief P1). |
| `env_stars_layer1.png` | 2048x2048 | rgb | B | Parallax star layer 1 (tiling, RGB; ENVIRONMENT_SPEC 2). |
| `env_stars_layer2.png` | 2048x2048 | rgb | B | Parallax star layer 2 (tiling, RGB; ENVIRONMENT_SPEC 2). |
| `env_stars_layer3.png` | 2048x2048 | rgb | B | Parallax star layer 3 (tiling, RGB; ENVIRONMENT_SPEC 2). |
| `env_station.png` | 2048x2048 | rgba | B | Dockable station (POI). |
| `env_station_mmo.png` | 1942x1531 | rgba | D | Station in MMO plate pattern (expansion spec 6). |
| `env_station_ruined.png` | 1810x1626 | rgba | D | Gutted hostile station, torn ring (expansion spec 6). |
| `env_wreck_hulk.png` | 1877x1487 | rgba | B | Wreck hulk, salvage POI. |
| `panel_asteroids_b.png` | 2048x2048 | rgba | E | Asteroid sheet master, 2K (source of env_asteroid_b1..b6; not a runtime sprite). |

## ui - chrome, insignia, backdrops

| File | px | a | ph | Purpose |
|---|---|---|---|---|
| `logo_vajb_orbit.png` | 2048x2048 | rgba | B | Game logo (menu title) |
| `ui_backdrop_hangar.png` | 2048x1152 | rgb | D | Hangar screen backdrop, 16:9 opaque (expansion spec 8) |
| `ui_backdrop_login.png` | 2048x1152 | rgb | D | Login/company-select backdrop, 16:9 opaque (expansion spec 8) |
| `ui_backdrop_starmap.png` | 2048x1152 | rgb | D | Starmap screen backdrop, 16:9 opaque (expansion spec 8) |
| `ui_bar_caps.png` | 42x14 | rgba | B | Status bar end caps (42x14) |
| `ui_bar_caps@2x.png` | 84x28 | rgba | B | Status bar end caps (42x14) (2x cut, UI_CHROME_ASSETS_SPEC 10). |
| `ui_button_plate_disabled.png` | 280x56 | rgba | B | UI button plate, disabled state, 280x56 (UI_CHROME_ASSETS_SPEC). |
| `ui_button_plate_disabled@2x.png` | 560x112 | rgba | B | UI button plate, disabled state, 560x112 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_button_plate_hover.png` | 280x56 | rgba | B | UI button plate, hover state, 280x56 (UI_CHROME_ASSETS_SPEC). |
| `ui_button_plate_hover@2x.png` | 560x112 | rgba | B | UI button plate, hover state, 560x112 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_button_plate_normal.png` | 280x56 | rgba | B | UI button plate, normal state, 280x56 (UI_CHROME_ASSETS_SPEC). |
| `ui_button_plate_normal@2x.png` | 560x112 | rgba | B | UI button plate, normal state, 560x112 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_button_plate_pressed.png` | 280x56 | rgba | B | UI button plate, pressed state, 280x56 (UI_CHROME_ASSETS_SPEC). |
| `ui_button_plate_pressed@2x.png` | 560x112 | rgba | B | UI button plate, pressed state, 560x112 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_insignia_mic.png` | 776x889 | rgba | D | Company emblem: Miner's Incorporated (MENU_FLOW 3.3-3.7) |
| `ui_insignia_mmo.png` | 779x891 | rgba | D | Company emblem: Mars Mining Operations (MENU_FLOW 3.3-3.7) |
| `ui_insignia_neutral.png` | 780x894 | rgba | D | Company emblem: neutral plate (MENU_FLOW 3.3-3.7) |
| `ui_insignia_ven.png` | 783x894 | rgba | D | Company emblem: Venus Resources (MENU_FLOW 3.3-3.7) |
| `ui_minimap_bezel.png` | 200x200 | rgba | B | Minimap bezel ring, 200x200. |
| `ui_minimap_bezel@2x.png` | 400x400 | rgba | B | Minimap bezel ring, 200x200 (2x cut, UI_CHROME_ASSETS_SPEC 10). |
| `ui_panel_frame.png` | 96x96 | rgba | B | 9-slice panel frame, 96x96 with a 32 px painted border band (the nine-slice margin; ICONS_SPEC 9.8 C1) |
| `ui_panel_frame@2x.png` | 192x192 | rgba | B | 9-slice panel frame, 192x192 with a 64 px painted border band, 2x cut of the 96x96 frame (ICONS_SPEC 9.8 C1; UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_cargo_disabled.png` | 40x40 | rgba | B | Slot plate: cargo slot, disabled state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_cargo_disabled@2x.png` | 80x80 | rgba | B | Slot plate: cargo slot, disabled state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_cargo_hover.png` | 40x40 | rgba | B | Slot plate: cargo slot, hover state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_cargo_hover@2x.png` | 80x80 | rgba | B | Slot plate: cargo slot, hover state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_cargo_normal.png` | 40x40 | rgba | B | Slot plate: cargo slot, normal state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_cargo_normal@2x.png` | 80x80 | rgba | B | Slot plate: cargo slot, normal state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_cargo_pressed.png` | 40x40 | rgba | B | Slot plate: cargo slot, pressed state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_cargo_pressed@2x.png` | 80x80 | rgba | B | Slot plate: cargo slot, pressed state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_inventory_disabled.png` | 56x56 | rgba | B | Slot plate: inventory slot, disabled state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_inventory_disabled@2x.png` | 112x112 | rgba | B | Slot plate: inventory slot, disabled state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_inventory_hover.png` | 56x56 | rgba | B | Slot plate: inventory slot, hover state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_inventory_hover@2x.png` | 112x112 | rgba | B | Slot plate: inventory slot, hover state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_inventory_normal.png` | 56x56 | rgba | B | Slot plate: inventory slot, normal state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_inventory_normal@2x.png` | 112x112 | rgba | B | Slot plate: inventory slot, normal state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_inventory_pressed.png` | 56x56 | rgba | B | Slot plate: inventory slot, pressed state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_inventory_pressed@2x.png` | 112x112 | rgba | B | Slot plate: inventory slot, pressed state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_weapon_disabled.png` | 48x48 | rgba | B | Slot plate: weapon slot, disabled state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_weapon_disabled@2x.png` | 96x96 | rgba | B | Slot plate: weapon slot, disabled state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_weapon_hover.png` | 48x48 | rgba | B | Slot plate: weapon slot, hover state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_weapon_hover@2x.png` | 96x96 | rgba | B | Slot plate: weapon slot, hover state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_weapon_normal.png` | 48x48 | rgba | B | Slot plate: weapon slot, normal state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_weapon_normal@2x.png` | 96x96 | rgba | B | Slot plate: weapon slot, normal state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |
| `ui_slot_weapon_pressed.png` | 48x48 | rgba | B | Slot plate: weapon slot, pressed state (UI_CHROME_ASSETS_SPEC). |
| `ui_slot_weapon_pressed@2x.png` | 96x96 | rgba | B | Slot plate: weapon slot, pressed state, 2x cut (UI_CHROME_ASSETS_SPEC 10). |

## fx - combat and screen effects

| File | px | a | ph | Purpose |
|---|---|---|---|---|
| `fx_anomaly_grave_glow.png` | 2048x2048 | rgb | F | Grave-cache anomaly glow, steel highlight core, RGB on void black (brief P1) |
| `fx_anomaly_rift.png` | 2048x2048 | rgb | F | Void-rift anomaly tear, ember pair (hazard), RGB on void black (brief P1) |
| `fx_anomaly_shimmer.png` | 2048x2048 | rgb | F | Ore-bloom anomaly shimmer, steel highlight only, RGB on void black (brief P1, 11 section 3.2) |
| `fx_cargo_pulse.png` | 2048x2048 | rgb | B | Cargo tractor pulse. |
| `fx_ember_pulse.png` | 2048x2048 | rgb | B | Ember pulse, generic danger bloom. |
| `fx_emp_arc.png` | 2048x2048 | rgb | D | EMP arc discharge (expansion spec 7) |
| `fx_engine_trail.png` | 2048x2048 | rgb | B | Engine trail. |
| `fx_explosion.png` | 2048x2048 | rgb | B | Explosion, 5-frame sheet. |
| `fx_hull_critical_vignette.png` | 2048x2048 | rgb | B | Hull-critical screen vignette (single) |
| `fx_jump_portal.png` | 2048x2048 | rgb | D | Jump aperture ring, ember (single frame; expansion spec 7) |
| `fx_laser_bolt.png` | 2048x2048 | rgb | B | Laser bolt projectile (single frame) |
| `fx_mining_beam.png` | 2048x2048 | rgb | B | Mining beam, 4-frame sheet. |
| `fx_missile_trail.png` | 2048x2048 | rgb | D | Missile trail, 4-frame sheet (expansion spec 7) |
| `fx_muzzle_flash.png` | 2048x2048 | rgb | B | Muzzle flash, 4-frame sheet. |
| `fx_repair_pulse.png` | 2048x2048 | rgb | D | Repair pulse ring, steel highlight (non-ember exception; expansion spec 7) |
| `fx_secondary_explosion.png` | 2048x2048 | rgb | D | Secondary explosion (expansion spec 7) |
| `fx_shield_break.png` | 2048x2048 | rgb | D | Shield collapse, 4-frame sheet, no ember (expansion spec 7) |
| `fx_shield_ripple.png` | 2048x2048 | rgb | B | Shield hit ripple (steel highlight) |
| `fx_tractor_beam.png` | 2048x2048 | rgb | D | Tractor beam (expansion spec 7) |

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
- Run folders (`assets/<family>/20260917-*/`): 105 directories holding the raw generator downloads and their `job.json`; kept for provenance, not consumers.
- `icons/tint/`: 556 PNGs, derived white stencils (RGB = white, alpha byte-identical) of every `icons/icon_*_{16,48}.png` source, written by `tools/derive_icon_tints.gd`. Engine-side modulate tints them with theme colours. The flat glyphs (Phase B and Phase F) are the intended consumers; the painted Phase D/E icon splits are never consumed tinted, so their stencils are unused.
- Phase D panel masters (`panel_equipment`, `panel_map_markers`, `panel_pickups`, `panel_insignia`, `panel_props`) were consumed during splitting and deleted with the other intermediates; only the splits ship (deviation from expansion spec 2.6, recorded in 12).
- Phase F panel masters (`panel_minerals_ore`, `panel_minerals_ingot`, `panel_modules_a/b/c`, `panel_slots`, `panel_contracts`, `panel_service_glyphs`, `panel_faction_insignia`) never entered `assets/`: they stay in `staging/phase_f/<family>/` with their `job.json` files as provenance, and only the cut sprites ship. Per-family evidence: `assets/<family>/generation_log_phase_f.md`.

