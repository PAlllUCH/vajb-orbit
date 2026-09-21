# Vajb Orbit - Asset Audit (Phase D/E art and audio reachability)

**Produced 2026-09-18 by the D1 audit worker.** Read-only pass: no asset, scene, script, theme or config was
modified, and no image or audio was generated or downloaded. Every path in this document was checked against a
filesystem listing before it was written.

**Scope:** the 317 shipped sprites and 95 shipped audio files, audited against what the two upcoming screens
(`MAIN_MENU_V2.md` and `STATION_HUB.md`, both named in `IMPLEMENTATION_PLAN.md` section 9.6 but not yet
written) are going to need. Section 9 of that plan is the only spec for those screens today: 9.2 flow
(main_menu -> loading{destination:station} -> station -> LAUNCH -> loading{destination:game} -> game),
9.4 modules (OUTFITTING / SHIPYARD / UPGRADES / LAUNCH / LOG OUT), 9.5 theme items (`PanelRaised` from
`ui_panel_frame.png`, patch margins 32).

**Measurement shorthand used in the tables.** `offpal` = fraction of subject pixels (alpha > 128, or RGB > 28
for opaque files) whose summed-absolute RGB distance to the nearest of the 16 `STYLE_BIBLE` hexes exceeds 90 on
a 0-765 scale. `lum` = mean luminance of those pixels. `ember` = count of subject pixels in the ember hue band
(R > 110, R > G + 45, G >= B). `fringe` = fraction of the outer alpha band (alpha 1..64) that is bright
(luminance > 150) and near-neutral (max - min < 40). All numbers are from the commands listed in
`.agents/gen/d1_report.md`.

---

## A. Verification of the inventory

`ASSET_CATALOG.md` was parsed mechanically (419 data rows: 317 sprites + 95 audio + 7 summary rows).

| Family | On disk | In catalog | Disagreement | Referenced in code |
|---|---|---|---|---|
| `res://assets/ships/` | 74 | 74 | none | 1 (`ship_vanguard_side.png`) |
| `res://assets/icons/` | 144 | 144 | none | 17 (all through `icons/tint/`) |
| `res://assets/icons/tint/` (derived) | 40 | not catalogued (appendix only) | none | 17 |
| `res://assets/env/` | 56 | 56 | none | 5 (`env_loading_bg`, `env_menu_bg`, `env_stars_layer1..3`) |
| `res://assets/ui/` | 27 | 27 | none | 15 (4 button plates, 8 slot states, `logo_vajb_orbit`, `ui_bar_caps`, `ui_minimap_bezel`) |
| `res://assets/fx/` | 16 | 16 | none | 1 (`fx_ember_pulse.png`) |
| `res://assets/audio/` | 95 | 95 | none | 2 by cue (`ui_click.ogg`, `ui_hover.ogg`) |

**Sprite subtotal:** 317 on disk = 74 + 144 + 56 + 27 + 16. **Audio subtotal:** 95 = 6 music + 62 sfx + 16
ambience + 11 ui. Both match the catalog exactly, so the "317 + 95" headline is confirmed, not repeated.

**Reference count:** 39 distinct sprite files are referenced by the 13 `.gd`, 11 `.tscn` and 2 `.tres` files in
the project (plus 2 directory constants in `tools/derive_icon_tints.gd`). 22 are painted sprites and 17 are
derived tints. The 39 break down as ships 1, icons 17, env 5, ui 15, fx 1. Zero of the 317 references are
dangling: 54 of 54 concrete asset-path strings found in code resolve to an existing file (the other 15 are
path templates such as the `ui_button_plate_%s.png` format string in `tools/build_theme.gd`).

### A.1 Disagreements between documents and the filesystem

The catalog is generated from the filesystem and wins in every case below. The filesystem and the catalog were
cross-checked for pixel size and alpha mode on all 317 sprites with Pillow, and for duration and channel count
on all 95 audio files with `soundfile`:

1. **No pixel-size or alpha-mode mismatch at all**: 0 of 317 catalog px strings differ from the decoded size.
2. **No duration or channel mismatch at all**: 0 of 95 catalog `Len s` / `Ch` values differ from the measured
   values.
3. **`ASSET_WIRING_HANDOFF.md` section 1.4 says "`ambience/`: all 16 files" are loop-material.** The `.import`
   sidecars contain exactly 25 `loop=true` files, of which 11 are ambience; the five `amb_space_misc_{01..05}.ogg`
   files are one-shots, and the catalog's `Loop` column agrees with the sidecars ("-"). The handoff sentence is
   the error; the assets are consistent with each other.
4. **`ASSET_CATALOG.md` calls 15 UI files `rgba`.** They do carry an alpha channel but contain no fully
   transparent pixel: `ui_panel_frame.png` (alpha min 198), the 12 `ui_slot_*` state plates (alpha min 223-253)
   and `ui_minimap_bezel.png` (alpha 0 only on 0.01 percent of pixels). They are opaque plates with feathered
   edges, not cut-out sprites. Harmless for their documented use, misleading as a catalog claim.
5. **`ASSET_CATALOG.md` calls `ui_minimap_bezel.png` a "bezel ring".** Measured: an opaque 200x200 face (centre
   pixel `16,18,23` at alpha 255) with a 15 px metal border band; the HUD uses it as a `NinePatchRect` with
   `patch_margin_* = 16`, which matches the 15 px band. The asset is right and the purpose text is loose.
6. **5 sprites were generated with the `sunburst` fallback model**, not the `flare` model the specs name:
   `env_stars_layer2`, `fx_engine_trail`, `fx_hull_critical_vignette`, `fx_ember_pulse`, `logo_vajb_orbit` (all
   Phase B, all with `<file>.png.job.json`). Provenance is recorded, the model deviation is not.
7. **Provenance coverage:** 229 of 317 sprites have a `job.json` (208 `flare` text-to-image, 21 `flare`
   image-to-image). The 88 without one are Phase B (40 icon glyphs, 7 env, 20 ui chrome, 9 fx, `logo_vajb_orbit`)
   plus `panel_boosters.png` and `panel_status.png`; their provenance is the per-family `generation_log*.md`.
   Phase B wrote `<file>.png.job.json`, Phase D/E wrote `<stem>.job.json`, so a naive glob for one shape misses
   the other.

---

## B. Phase D/E audit table

Every asset added in Phase D (141 files) or E (67 files) is covered. Families above 40 assets (ships 53,
icons 101) are tabled in full for the assets that matter to the two upcoming screens and summarised otherwise,
as the brief allows. `alpha mode` is measured, not taken from the catalog: `cutout` = a real silhouette alpha
channel, `plate` = opaque with feathered edges, `opaque(rgb)` = no alpha channel at all.

### B.1 ships (53 Phase D files; 17 tabled, 36 summarised)

| asset res:// path | px | alpha mode | intended use per docs | style-bible verdict | alpha-correct for that use | verdict | target screen |
|---|---|---|---|---|---|---|---|
| `res://assets/ships/ship_bomber_side.png` | 908x299 | cutout | Bomber, hostile ordnance, side view (expansion spec 3 #13) | CONFORMS: offpal 0.004, ember 751, cutout | yes | WIRE NOW (shipyard preview) | STATION |
| `res://assets/ships/ship_corvette_mmo_side.png` | 893x234 | cutout | Corvette, MMO livery refit, side view (expansion spec 4) | CONFORMS: offpal 0.005, ember 909 | yes | WIRE LATER (no faction system yet) | STATION |
| `res://assets/ships/ship_destroyer_side.png` | 982x217 | cutout | Destroyer, hostile capital, side view (expansion spec 3 #9) | CONFORMS: offpal 0.007, ember 971 | yes | WIRE NOW (shipyard preview) | STATION |
| `res://assets/ships/ship_drone_swarm_side.png` | 795x257 | cutout | Drone swarm unit, side view (expansion spec 3 #10) | DRIFTS: white fringe 1.0 on the outer alpha band (mean outer lum 245 vs interior 54) | yes (cutout) but the edge reads light on dark | WIRE LATER (fix fringe first) | STATION |
| `res://assets/ships/ship_fighter_mmo_side.png` | 814x351 | cutout | Fighter, MMO livery refit, side view (expansion spec 4) | CONFORMS: offpal 0.005, ember 1855 | yes | WIRE LATER | STATION |
| `res://assets/ships/ship_freighter_mmo_side.png` | 899x256 | cutout | Freighter, MMO livery refit, side view (expansion spec 4) | CONFORMS: offpal 0.005, ember 874 | yes | WIRE LATER | STATION |
| `res://assets/ships/ship_gunship_side.png` | 859x385 | cutout | Gunship, hostile mid-tier, side view (expansion spec 3 #8) | CONFORMS: offpal 0.008, ember 1534 | yes | WIRE NOW (shipyard preview) | STATION |
| `res://assets/ships/ship_interceptor_side.png` | 940x107 | cutout | Interceptor, hostile fast attack, side view (expansion spec 3 #7) | CONFORMS: offpal 0.006 (spec 11.5 notes it reads very thin) | yes | WIRE LATER | STATION |
| `res://assets/ships/ship_mine_layer_side.png` | 943x228 | cutout | Mine layer, hostile support, side view (expansion spec 3 #14) | CONFORMS: offpal 0.004, ember 1252 | yes | WIRE NOW (shipyard preview) | STATION |
| `res://assets/ships/ship_patrol_side.png` | 1053x289 | cutout | Patrol, neutral enforcer, side view (expansion spec 3 #12) | CONFORMS: offpal 0.003, ember 714 | yes | WIRE NOW (shipyard preview) | STATION |
| `res://assets/ships/ship_trader_side.png` | 973x287 | cutout | Trader, neutral civil, side view (expansion spec 3 #11) | CONFORMS: offpal 0.002, ember 387 | yes | WIRE NOW (shipyard preview) | STATION |
| `res://assets/ships/ship_vanguard_mmo_side.png` | 907x394 | cutout | Player Vanguard cutter, MMO livery refit, side view (expansion spec 4) | CONFORMS: offpal 0.006, ember 1425 | yes | WIRE NOW (player hull in the preview) | STATION |
| `res://assets/ships/ship_boss_leviathan.png` | 1939x1112 | cutout | Wave 2 third boss, single render (expansion spec 3) | CONFORMS: offpal 0.009, ember 13315, ember core is the class marker | yes | WIRE LATER (gameplay) | gameplay |
| `res://assets/ships/ship_boss_spire.png` | 1982x1078 | cutout | Relay leviathan boss (expansion spec 3) | CONFORMS: offpal 0.008, ember 12380 | yes | WIRE LATER | gameplay |
| `res://assets/ships/ship_boss_thorn.png` | 2003x1203 | cutout | Hive-mother boss (expansion spec 3) | CONFORMS: offpal 0.009, ember 25223 (loudest ember of the set, still no second accent) | yes | WIRE LATER | gameplay |
| `res://assets/ships/ship_boss_maw_mmo.png` | 1853x1896 | cutout | Maw dreadnought, MMO livery refit (expansion spec 4) | CONFORMS: offpal 0.010, ember core and thorns kept per spec 12 | yes | WIRE LATER | gameplay |
| `res://assets/ships/ship_turret_platform.png` | 1903x1726 | cutout | Hostile static emplacement (expansion spec 3 #15) | CONFORMS: offpal 0.006, ember lamps only | yes | WIRE LATER | gameplay |

**Summarised ships (36 files).** The front / back / three-quarter views of the 12 hull sets above
(`ship_bomber_*`, `ship_destroyer_*`, `ship_drone_swarm_*`, `ship_gunship_*`, `ship_interceptor_*`,
`ship_mine_layer_*`, `ship_patrol_*`, `ship_trader_*`, and the `_mmo_` refits of corvette, fighter, freighter
and vanguard). Measured range across all 53: offpal 0.001-0.017, mean lum 41.1-63.5, every file a cutout with a
real silhouette. No anomalies beyond the two listed in section C (drone-swarm fringe, class-hierarchy framing).

### B.2 env (40 Phase D/E files, all tabled)

| asset res:// path | px | alpha mode | intended use per docs | style-bible verdict | alpha-correct for that use | verdict | target screen |
|---|---|---|---|---|---|---|---|
| `res://assets/env/env_base_mining.png` | 1955x1722 | cutout | Mining base, station-scale POI (spec E 3) | CONFORMS: offpal 0.001, ember 2254 (lamps) | yes | WIRE LATER (world POI) | gameplay |
| `res://assets/env/env_base_trade.png` | 2004x1344 | cutout | Trade / refinery base (spec E 3) | CONFORMS: offpal 0.002, ember 1364 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_base_defense.png` | 1744x1670 | cutout | Defense fortress (spec E 3) | CONFORMS: offpal 0.000, ember 842 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_base_shipyard.png` | 1929x1105 | cutout | Shipyard / drydock, empty cradle by design (spec E 3) | CONFORMS: offpal 0.002, ember 2625 | yes | WIRE NOW (station POI + shipyard module plate) | STATION |
| `res://assets/env/env_outpost_mining.png` | 1220x1843 | cutout | Mining outpost (spec E 4) | DRIFTS: white fringe 0.998 (mean outer lum 241 vs interior 47) | yes (cutout) but the edge reads light | WIRE LATER (fix fringe first) | gameplay |
| `res://assets/env/env_outpost_defense.png` | 1156x1591 | cutout | Defense outpost (spec E 4) | CONFORMS: offpal 0.004, ember 1962 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_outpost_relay.png` | 636x1864 | cutout | Comms relay outpost (spec E 4) | CONFORMS: offpal 0.002, ember 1019 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_outpost_repair.png` | 1350x1934 | cutout | Repair post (spec E 4) | DRIFTS: white fringe 0.998 (mean outer lum 243 vs interior 42) | yes (cutout) but the edge reads light | WIRE LATER (fix fringe first) | gameplay |
| `res://assets/env/env_body_ice_moon.png` | 1672x1713 | cutout | Airless ice moon, airless only, one step darker than ships (spec E 5) | DRIFTS: mean lum 91.0 vs ships 54.3, p95 195.3; no blue tint (offpal 0.012) so the hue is right and the value is not | yes | WIRE LATER (value regression) | gameplay |
| `res://assets/env/env_body_ore_moon.png` | 1871x1906 | cutout | Airless mining-scarred moon (spec E 5) | CONFORMS: offpal 0.001, ember 259 (ore seams non-emissive) | yes | WIRE LATER | gameplay |
| `res://assets/env/env_body_shattered.png` | 1870x1891 | cutout | Airless shattered moon (spec E 5) | CONFORMS: offpal 0.004, ember 4 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_bg_body_plate.png` | 2048x1152 | opaque(rgb) | 16:9 parallax body plate, limb only (spec E 5) | CONFORMS: offpal 0.000, mean lum 48.4; checked against `env_stars_layer3.png` (24x24 correlation) and they are different images (3 percent of pixels differ by > 12) | correct (backdrop layer, no alpha wanted) | WIRE LATER | gameplay |
| `res://assets/env/env_asteroid_b1.png` | 618x771 | cutout | Rock look 2, large cigar body (spec E 7) | CONFORMS: offpal 0.000 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_asteroid_b2.png` | 632x623 | cutout | Rock look 2, large twin-lobed body (spec E 7) | CONFORMS: offpal 0.000 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_asteroid_b3.png` | 559x538 | cutout | Rock look 2, medium heavily pitted (spec E 7) | CONFORMS: offpal 0.000 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_asteroid_b4.png` | 567x657 | cutout | Rock look 2, medium ore-flecked (spec E 7) | CONFORMS: offpal 0.001, ember 667 (ochre fleck only) | yes | WIRE LATER | gameplay |
| `res://assets/env/env_asteroid_b5.png` | 404x413 | cutout | Rock look 2, small flat shard (spec E 7) | CONFORMS: offpal 0.000 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_asteroid_b6.png` | 433x466 | cutout | Rock look 2, small rubble cluster (spec E 7) | CONFORMS: offpal 0.000 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_mine.png` | 1396x1588 | cutout | Deployed mine world object, one ember lamp (spec E 7) | DRIFTS: white fringe 0.994 (mean outer lum 244 vs interior 42) | yes (cutout) but the edge reads light | WIRE LATER (fix fringe first) | gameplay |
| `res://assets/env/env_planet_moon.png` | 1601x1650 | cutout | Airless dead moon POI (expansion spec 6) | DRIFTS: white fringe 0.989 (mean outer lum 243 vs interior 50) | yes (cutout) but the edge reads light | WIRE LATER (fix fringe first) | gameplay |
| `res://assets/env/env_jump_gate.png` | 1936x1277 | cutout | Jump gate, ember lamps only (expansion spec 6) | CONFORMS: offpal 0.006, ember 3956 lamps, no interior glow | yes | WIRE LATER | gameplay |
| `res://assets/env/env_debris_field.png` | 1986x1956 | cutout | Scattered torn-hull debris field (expansion spec 6) | DRIFTS: white fringe 0.881 (mean outer lum 212 vs interior 42); spec 11.1 records a defringe pass that did not fully clear it | yes (cutout) but the edge reads light | WIRE LATER (fix fringe first) | gameplay |
| `res://assets/env/env_ice_field.png` | 1891x1869 | cutout | Frozen fragment cluster (expansion spec 6) | CONFORMS: offpal 0.002, ember 1242 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_ore_cluster.png` | 1790x1803 | cutout | Dense mineable ore cluster (expansion spec 6) | CONFORMS: offpal 0.003, ember 996 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_station_mmo.png` | 1942x1531 | cutout | Faction station in MMO plate pattern (expansion spec 6) | CONFORMS: offpal 0.003, ember 5618 lamps | yes | WIRE LATER (needs a faction system) | gameplay |
| `res://assets/env/env_station_ruined.png` | 1810x1626 | cutout | Gutted hostile station (expansion spec 6) | CONFORMS: offpal 0.003, ember 674 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_pickup_bonus_box.png` | 755x463 | cutout | World pickup, sealed ordnance crate (expansion spec 5) | CONFORMS: offpal 0.005, ember 1776 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_pickup_repair_pod.png` | 728x510 | cutout | World pickup, repair pod (expansion spec 5) | CONFORMS: offpal 0.007, ember 2255 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_pickup_shield_pod.png` | 524x502 | cutout | World pickup, shield emitter pod, no ember (expansion spec 5) | CONFORMS: offpal 0.008, ember 4 (steel aperture by spec) | yes | WIRE LATER | gameplay |
| `res://assets/env/env_pickup_speed_pod.png` | 780x284 | cutout | World pickup, speed pod (expansion spec 5) | CONFORMS: offpal 0.007, ember 1186 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_pickup_ammo_pod.png` | 725x443 | cutout | World pickup, ammo canister (expansion spec 5) | CONFORMS: offpal 0.002, ember 9 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_pickup_ore_pod.png` | 760x463 | cutout | World pickup, ore container (expansion spec 5) | CONFORMS: offpal 0.001, ember 1348 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_prop_hull_nose.png` | 584x864 | cutout | Wreck fragment: bow section (expansion spec 9) | CONFORMS: offpal 0.001, ember 59 | yes | WIRE LATER (composite wreck layouts) | gameplay |
| `res://assets/env/env_prop_hull_mid.png` | 581x755 | cutout | Wreck fragment: mid section (expansion spec 9) | CONFORMS: offpal 0.000 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_prop_hull_stern.png` | 591x816 | cutout | Wreck fragment: stern section (expansion spec 9) | CONFORMS: offpal 0.004, ember 726 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_prop_plate_section.png` | 551x823 | cutout | Wreck fragment: plate section (expansion spec 9) | CONFORMS: offpal 0.001, ember 17 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_prop_drive_core.png` | 631x748 | cutout | Wreck fragment: drive core (expansion spec 9) | CONFORMS: offpal 0.001, ember 75 | yes | WIRE LATER | gameplay |
| `res://assets/env/env_prop_rib_cluster.png` | 580x826 | cutout | Wreck fragment: rib cluster (expansion spec 9) | CONFORMS: offpal 0.000, ember 13 | yes | WIRE LATER | gameplay |
| `res://assets/env/panel_asteroids_b.png` | 2048x2048 | cutout | Asteroid sheet master, not a runtime sprite (spec E 7) | CONFORMS as a master: offpal 0.000 | not a consumer | REJECT (documented master, consumer rule 5) | none |

### B.3 ui (7 Phase D files, all tabled)

| asset res:// path | px | alpha mode | intended use per docs | style-bible verdict | alpha-correct for that use | verdict | target screen |
|---|---|---|---|---|---|---|---|
| `res://assets/ui/ui_backdrop_hangar.png` | 2048x1152 | opaque(rgb) | Hangar screen backdrop, 16:9 opaque (expansion spec 8) | CONFORMS: offpal 0.004, mean lum 49.2, ember 3039 lamps, centre low-detail per prompt | correct (backdrop) | WIRE NOW | STATION |
| `res://assets/ui/ui_backdrop_login.png` | 2048x1152 | opaque(rgb) | Login / company-select backdrop (expansion spec 8) | CONFORMS: offpal 0.001, mean lum 37.5, ember 1951 | correct (backdrop) | WIRE LATER (no login screen in this phase) | menu v2 alternative |
| `res://assets/ui/ui_backdrop_starmap.png` | 2048x1152 | opaque(rgb) | Starmap backdrop (expansion spec 8) | CONFORMS: offpal 0.000, mean lum 31.8, ember 0 (no markers by spec) | correct (backdrop) | WIRE LATER | future starmap |
| `res://assets/ui/ui_insignia_mic.png` | 776x889 | cutout | Company emblem: Miner's Incorporated (spec D 5) | DRIFTS: white fringe 1.0 on the outer alpha band (mean outer lum 252 vs interior 51) | yes (cutout) but the edge reads light on dark panels | WIRE NOW with a defringe pass | menu v2 / STATION |
| `res://assets/ui/ui_insignia_mmo.png` | 779x891 | cutout | Company emblem: Mars Mining Operations (spec D 5) | DRIFTS: white fringe 1.0 (mean outer lum 251 vs interior 47), ember 650 notch as specified | yes (cutout), edge reads light | WIRE NOW with a defringe pass | menu v2 / STATION |
| `res://assets/ui/ui_insignia_neutral.png` | 780x894 | cutout | Company emblem: neutral plate (spec D 5) | DRIFTS: white fringe 1.0 (mean outer lum 251 vs interior 38) | yes (cutout), edge reads light | WIRE NOW with a defringe pass | menu v2 |
| `res://assets/ui/ui_insignia_ven.png` | 783x894 | cutout | Company emblem: Venus Resources (spec D 5) | DRIFTS: white fringe 1.0 (mean outer lum 251 vs interior 45) | yes (cutout), edge reads light | WIRE NOW with a defringe pass | menu v2 |

### B.4 fx (7 Phase D files, all tabled)

| asset res:// path | px | alpha mode | intended use per docs | style-bible verdict | alpha-correct for that use | verdict | target screen |
|---|---|---|---|---|---|---|---|
| `res://assets/fx/fx_jump_portal.png` | 2048x2048 | opaque(rgb) | Jump aperture ring, ember, single frame (expansion spec 7) | CONFORMS: offpal 0.143 measured, but every off-palette pixel is a deeper ember shade (mean of those pixels `131,52,26`, hue 16-19), not a second accent | correct (RGB on void black, additive) | WIRE LATER (gameplay) | gameplay |
| `res://assets/fx/fx_missile_trail.png` | 2048x2048 | opaque(rgb) | Missile trail, 4-frame sheet (expansion spec 7) | CONFORMS: offpal 0.032, off-palette pixels are ember/umber | correct (additive) | WIRE LATER | gameplay |
| `res://assets/fx/fx_shield_break.png` | 2048x2048 | opaque(rgb) | Shield collapse, 4-frame sheet, no ember (expansion spec 7) | CONFORMS: 0 off-palette pixels, steel highlight only, matches the sanctioned exception | correct (additive) | WIRE LATER | gameplay |
| `res://assets/fx/fx_repair_pulse.png` | 2048x2048 | opaque(rgb) | Repair pulse ring, steel highlight (expansion spec 7) | CONFORMS: 0 off-palette pixels, no ember anywhere | correct (additive) | WIRE LATER | gameplay |
| `res://assets/fx/fx_tractor_beam.png` | 2048x2048 | opaque(rgb) | Tractor beam (expansion spec 7 wave 2) | CONFORMS: offpal 0.189, all deep-ember shades (mean `119,39,16`) | correct (additive) | WIRE LATER | gameplay |
| `res://assets/fx/fx_emp_arc.png` | 2048x2048 | opaque(rgb) | EMP arc discharge (expansion spec 7 wave 2) | CONFORMS: offpal 0.111, ember band only | correct (additive) | WIRE LATER | gameplay |
| `res://assets/fx/fx_secondary_explosion.png` | 2048x2048 | opaque(rgb) | Secondary explosion (expansion spec 7 wave 2) | CONFORMS: offpal 0.059, hot core `204,134,106` is the sanctioned brightened ember flash | correct (additive) | WIRE LATER | gameplay |

### B.5 icons (101 Phase D/E files; 11 tabled, the rest summarised)

Every Phase D/E icon is `rgba` and cut out. Grouped measurements (offpal mean / max): `equip` 0.018 / 0.085,
`map` 0.005 / 0.034, `status` 0.007 / 0.031, `ammo` 0.004 / 0.006, `booster` 0.002 / 0.010. The worst offender,
`icon_equip_generator_16.png` at 0.085, is 15 pixels of deeper ember (`116,42,13`), i.e. a value drift inside
the single accent hue, never a second colour.

| asset res:// path | px | alpha mode | intended use per docs | style-bible verdict | alpha-correct for that use | verdict | target screen |
|---|---|---|---|---|---|---|---|
| `res://assets/icons/icon_ammo_laser_48.png` | 48x48 | cutout | Painted ammo icon, direct consumer, no tint (spec D 5) | CONFORMS: offpal 0.005, ember 19 | yes | WIRE NOW (ammo module) | STATION |
| `res://assets/icons/icon_ammo_rocket_48.png` | 48x48 | cutout | Painted ammo icon (spec D 5) | CONFORMS: offpal 0.003 | yes | WIRE NOW (ammo module) | STATION |
| `res://assets/icons/icon_equip_engine_48.png` | 48x48 | cutout | Painted equipment icon: drive nozzle (spec D 5) | CONFORMS: offpal 0.026, ember 29 | yes | WIRE NOW (UPGRADES module) | STATION |
| `res://assets/icons/icon_equip_generator_48.png` | 48x48 | cutout | Painted equipment icon: generator core (spec D 5) | CONFORMS: offpal 0.032, deepest ember shading of the set | yes | WIRE NOW (UPGRADES module) | STATION |
| `res://assets/icons/icon_equip_shield_gen_48.png` | 48x48 | cutout | Painted equipment icon: shield generator (spec D 5) | CONFORMS: offpal 0.016, ember 73 | yes | WIRE NOW | STATION |
| `res://assets/icons/icon_equip_module_48.png` | 48x48 | cutout | Painted equipment icon: upgrade module (spec D 5) | CONFORMS: offpal 0.000 | yes | WIRE NOW | STATION |
| `res://assets/icons/icon_equip_drone_48.png` | 48x48 | cutout | Painted equipment icon: combat drone (spec D 5) | CONFORMS: offpal 0.018 | yes | WIRE NOW | STATION |
| `res://assets/icons/icon_equip_pet_48.png` | 48x48 | cutout | Painted equipment icon: pet unit (spec D 5) | CONFORMS: offpal 0.000 | yes | WIRE NOW | STATION |
| `res://assets/icons/icon_equip_extra_48.png` | 48x48 | cutout | Painted equipment icon: utility pod (spec D 5) | CONFORMS: offpal 0.002 | yes | WIRE NOW | STATION |
| `res://assets/icons/icon_map_route_48.png` | 48x48 | cutout | Starmap route marker (spec D 5) | CONFORMS: offpal low, distinct silhouette | yes | WIRE NOW (map / LAUNCH stand-in) | STATION |
| `res://assets/icons/icon_map_bookmark_48.png` | 48x48 | cutout | Starmap bookmark marker (spec D 5) | CONFORMS: offpal 0.000 | yes | WIRE NOW (map module) | STATION |

**Summarised icons (90 files).** The 16 px half of every pair above (same art, same measurements); the 9
`icon_equip_*` and 9 `icon_map_*` component masters (`icon_equip_engine.png` 524x471 down to
`icon_map_node_danger.png` 394x657), documented masters and rejected as runtime sprites; the 7 `icon_map_node_*`
markers and their 16 px cuts; the 6 `icon_booster_*` and 9 `icon_status_*` painted sets (offpal group means
0.024 and 0.073), which are HUD consumers, not station chrome; and the two Phase E masters
`panel_boosters.png` and `panel_status.png` (2048x2048, REJECT for the same master reason).
`icon_cargo_data_core_16.png` is rejected outright (section C, anomaly C2).

## C. Anomaly list

Ordered by impact on the two upcoming screens. Every entry names the file and the measurement behind it.

1. **`res://assets/ui/ui_panel_frame.png` cannot serve the 32 px nine-slice contract the station hub is
   scheduled to use.** The painted metal border band is 7 px (vertical profile at x = 48: `47,53,59` at y = 0
   through `9,10,11` at y = 7, then interior for the remaining 89 px; median band 7 px on both axes).
   `tools/build_theme.gd:23` sets `PANEL_FRAME_MARGIN := 32.0`, `vajb_theme.tres` carries
   `texture_margin_* = 32`, and `IMPLEMENTATION_PLAN.md` section 9.5 schedules `PanelRaised` with "patch
   margins 32". `UI_CHROME_ASSETS_SPEC.md` section 2 specified a 32 px frame. A 32 px slice tiles 7 px of
   border plus 25 px of panel black, so the frame reads about 4.5 times too thick and the riveted corners are
   cropped. No scene uses `PanelRaised` yet, so the defect is latent, and it lands on the station hub first.
2. **`res://assets/icons/icon_cargo_data_core_16.png` is not legible as a glyph.** Ink coverage 0.98 of the
   frame (peers `icon_cargo_ore_16.png` 0.68, `icon_hull_16.png` 0.50, and its own 48 px sibling 0.93), and the
   silhouette touches all four frame edges, so at 16 px it reads as a solid square that also collides with
   adjacent icons in a HUD or station strip. 1.17 percent of its pixels are transparent.
3. **White matte fringe on 13 sprites** (outer alpha band is bright and near-neutral at ratio 0.88-1.00, mean
   outer luminance 212-252 against interior 38-76). Pixel-level evidence from a scanline across
   `env_outpost_mining.png` at y = 921: `(243,244,244,9)` then `(241,242,242,63)` then `(141,137,135,198)`
   before the subject. Files: `ui_insignia_mic.png`, `ui_insignia_mmo.png`, `ui_insignia_neutral.png`,
   `ui_insignia_ven.png`, `ship_drone_swarm_back.png`, `ship_drone_swarm_front.png`,
   `ship_drone_swarm_side.png`, `ship_drone_swarm_three_quarter.png`, `env_outpost_mining.png`,
   `env_outpost_repair.png`, `env_mine.png`, `env_planet_moon.png`, `env_debris_field.png`. Four
   `ui_button_plate_*` files sit just behind them at 0.46-0.61 (mean outer luminance 162-187 versus interior
   37-72). Contradiction to record: `ASSET_EXPANSION_SPEC_E.md` section 11.2 claims "0 fringe pixels per file"
   for the wave 1 bases and outposts; that holds for the four bases (they measured dark outer pixels, e.g.
   `env_base_mining.png` edge `(3,9,14,0)`) but not for `env_outpost_mining.png` or `env_outpost_repair.png`.
4. **`res://assets/env/env_body_ice_moon.png` breaks the "one value step darker than ships" rule** with mean
   subject luminance 91.0 and p95 195.3, against a ships family mean of 54.3. It is the brightest environment
   sprite shipped. No blue tint (offpal 0.012), so the material read is right and only the value is wrong.
5. **Environment as a family is not darker than ships**, so the `STYLE_BIBLE` section 7.2 / expansion spec 10
   value rule is unmet at family level: env mean luminance 55.4 versus ships 54.3. Per family means: ships
   54.3, env 55.4, icons 55.8, ui 44.2, fx 49.8.
6. **Outposts are not "clearly smaller than bases" by footprint.** Subject-pixel areas:
   `env_outpost_mining.png` 2.19 M, `env_outpost_repair.png` 2.55 M, `env_outpost_defense.png` 1.78 M,
   `env_outpost_relay.png` 1.14 M, against `env_base_shipyard.png` 2.07 M, `env_base_trade.png` 2.63 M,
   `env_base_defense.png` 2.85 M, `env_base_mining.png` 3.29 M. The relay is genuinely small, but two outposts
   are larger than the smallest base, against spec E section 9 ("outposts read clearly smaller than bases").
7. **Six audio files decode above full scale**, so they clip on playback: `sfx_ship_boost_01.ogg` 1.464,
   `sfx_weapon_laser_03.ogg` 1.146, `mus_menu_theme_01.ogg` 1.036, `mus_boss_metal_01_loop.ogg` 1.030,
   `mus_exploration_dread_01.ogg` 1.013, `sfx_mining_chip_04.ogg` 1.001. 19 files exceed the -1 dBFS (0.891)
   figure that `ASSETS.md` gives for the encode path, including 11 of the 35 `encode`-mode files.
8. **`res://assets/audio/sfx/sfx_mining_chip_04.ogg` contradicts its own documented purpose.** 20.901 s long,
   against 0.457-0.486 s for chip transients 01-03, and from a different source pack
   (`raw-audio-oga_jordan4ibanez_mining`) than the Kenney impacts used for 01-03. Its catalog purpose is
   "S8 chip transient 4/4". A round-robin that treats the four as peers would fire a 21 s sample per chip.
9. **`res://assets/audio/sfx/sfx_weapon_laser_04.ogg` is a 1.244 s outlier in a 0.064-0.092 s pool** and is
   documented as "S1 laser round-robin 4/4". Same failure mode as C8 in a different pool.
10. **`ASSET_WIRING_HANDOFF.md` section 1.4 is wrong about ambience loop flags** (see A.1 item 3): 11 of 16
    ambience files are loops, not 16. No asset change needed; fix the handoff.
11. **Phase D icon atlas masters inconsistent with Phase E.** Phase D deleted its panel masters
    (`panel_equipment`, `panel_map_markers`, `panel_pickups`, `panel_insignia`, `panel_props`) and kept the
    component masters (`icon_equip_*.png`, `icon_map_*.png`, `icon_ammo_laser.png`, `icon_ammo_rocket.png`);
    Phase E kept its panel masters (`panel_boosters.png`, `panel_status.png`) and `env/panel_asteroids_b.png`.
    Both conventions are documented, but a tool that looks for one misses the other.
12. **Frame layout of the multi-frame FX sheets is under-documented.** `fx_explosion.png` is a 2x3 grid whose
    per-cell ink is 0.307 / 0.370 / 0.192 / 0.051 / 0.055 / 0.0015 in reading order, i.e. five frames plus the
    empty cell `FX_SPEC.md` section 1.4 specifies; the other four sheets (`fx_muzzle_flash.png`,
    `fx_mining_beam.png`, `fx_missile_trail.png`, `fx_shield_break.png`) are 1x4 strips in which all ink sits
    in the vertical middle half (ink rows 1-2 of 4), so a plain `hframes = 4` slice keeps about 75 percent
    empty pixels per frame. `ASSET_WIRING_HANDOFF.md` says "fx_explosion 5 frames" with no grid, and a
    five-column slice would be wrong.
13. **All 74 ships are trimmed to their subject**, so subject width is 86-100 percent of the frame (mean
    0.969) against the `STYLE_BIBLE` section 5 constant of about 60 percent. The constant was applied inside
    the generator and then removed by the local trim, which is fine, but it means the shipped sprites carry no
    framing margin: scaling every hull to one fixed box in code would erase the class size hierarchy that
    `SHIPS_SPEC` / expansion spec 3 build the classes on. Scale from each sprite's native pixel size.
14. **15 UI files are catalogued `rgba` but contain no fully transparent pixel** (see A.1 item 4). Cosmetic
    catalog issue, no consumer impact.
15. **Cleared suspicions, so they are not re-investigated later.** Zero byte-identical duplicates among the 357
    shipped PNGs (SHA-256 over all of them, including `icons/tint/`). Zero zero-byte or unreadable PNG or OGG
    files, and no unexpected file extensions at the top of any family folder. Two visual near-matches were
    checked at full resolution and cleared: `env_bg_body_plate.png` versus `env_stars_layer3.png` (24x24
    signature difference 1.98, but 3.0 percent of pixels differ at full size) and `ship_vanguard_damaged_side.png`
    versus `ship_vanguard_side.png` (3.69, the expected magnitude for a damage variant).
16. **`game/station_catalog.gd` mixes two icon families inside one list.** Its `AMMO_PACKS` binds
    `icon_ammo_laser_48.png` and `icon_ammo_rocket_48.png` (painted Phase D art: mean RGB `55,51,50` and
    `51,48,46`, brightest pixels above 200) alongside `icon_weapon_cannon_48.png`,
    `icon_weapon_mine_48.png` and `icon_weapon_plasma_48.png` (Phase B flat glyphs: mean RGB `40,44,47`,
    brightest pixel 56-65, i.e. a near-black shape barely above the `#1B2028` panel tone). Three of five ammo
    rows would render as dark unlit glyphs next to two bright painted icons. Related consumer-rule breach: the
    flat glyphs are the tintable family, so the documented path is `icons/tint/icon_weapon_cannon_48.png`
    (measured mean `255,255,255`) plus `modulate`, not the untinted original that the catalogue names.

## D. Audio reachability

**Definition used.** A file is reachable when a call site that exists in the project today resolves its exact
path. `autoload/audio_manager.gd` resolves `res://assets/audio/<bus>/<cue>.ogg` then `<cue>_01.ogg`, and the
only call sites in the codebase are `main_menu.gd:80` (`play_ui(HOVER)`) and `main_menu.gd:84`
(`play_ui(CLICK)`); `play_sfx()` has no caller. Therefore exactly 2 files are reachable
(`ui/ui_click.ogg`, `ui/ui_hover.ogg`) and 93 are not. Note the moving target: during this audit the audio
service gained `play_music()` / `stop_music()` / `play_ambience()` / `stop_ambience()` (`THEME_AUDIO_EXTENSION.md`
section 4) and `Paths.AUDIO_DIRS` gained an `ambience` entry, so the API half of the music gap is closing in
parallel; the reachable count is still 2 because nothing calls those functions yet.

Cross-check: all 31 distinct cue names listed in `ASSET_WIRING_HANDOFF.md` section 1.1 resolve mechanically
against the shipped tree (31 of 31), so the unreachability is purely a code-side gap, not a naming problem.

| Bus dir | Cluster | Files | The 93 unreachable files |
|---|---|---|---|
| `res://assets/audio/music/` | menu / exploration / combat / boss beds | 6 | `mus_boss_metal_01_loop.ogg`, `mus_boss_metal_01_opening.ogg`, `mus_combat_loop_01.ogg`, `mus_exploration_ambient_01.ogg`, `mus_exploration_dread_01.ogg`, `mus_menu_theme_01.ogg` |
| `res://assets/audio/ambience/` | space beds | 10 | `amb_space_drone_01.ogg`, `amb_space_float_01.ogg`, `amb_space_float_02.ogg`, `amb_space_misc_01.ogg`, `amb_space_misc_02.ogg`, `amb_space_misc_03.ogg`, `amb_space_misc_04.ogg`, `amb_space_misc_05.ogg`, `amb_space_rumble_01.ogg`, `amb_space_rumble_02.ogg`, `amb_space_wind_01.ogg` |
| `res://assets/audio/ambience/` | station room beds | 5 | `amb_station_noise_loop_01.ogg`, `amb_station_pump_loop_01.ogg`, `amb_station_room_01.ogg`, `amb_station_room_02.ogg`, `amb_station_room_03.ogg` |
| `res://assets/audio/sfx/` | station machinery and power | 11 | `sfx_station_boiler_loop_01.ogg`, `sfx_station_breaker_off_01.ogg`, `sfx_station_breaker_on_01.ogg`, `sfx_station_hull_crack_{01,02,03}.ogg`, `sfx_station_hull_groan_01.ogg`, `sfx_station_hull_ring_{01,02,03}.ogg`, `sfx_station_hum_loop_01.ogg`, `sfx_station_machine_loop_{01,02,03}.ogg`, `sfx_station_power_off_01.ogg` |
| `res://assets/audio/sfx/` | ship movement | 6 | `sfx_ship_boost_01.ogg`, `sfx_ship_engine_01.ogg`, `sfx_ship_engine_02_loop.ogg`, `sfx_ship_jump_{01,02}.ogg` |
| `res://assets/audio/sfx/` | weapons and ordnance | 13 | `sfx_weapon_cannon_{01,02_medium,03_long}.ogg`, `sfx_weapon_explosion_{01,02}.ogg`, `sfx_weapon_laser_{01,02,03,04}.ogg`, `sfx_weapon_rocket_01.ogg`, `sfx_weapon_rocket_02_warhead.ogg` |
| `res://assets/audio/sfx/` | impacts and shield | 17 | `sfx_impact_hull_{01..05}.ogg`, `sfx_impact_rock_{01..04}.ogg`, `sfx_impact_shield_hit_{01..09}.ogg`, `sfx_impact_shield_loop_01.ogg` |
| `res://assets/audio/sfx/` | mining | 6 | `sfx_mining_beam_01.ogg`, `sfx_mining_chip_{01,02,03,04}.ogg` |
| `res://assets/audio/sfx/` | stingers | 9 | `sfx_stinger_anomaly_{01,02,03}.ogg`, `sfx_stinger_boss_roar_01.ogg`, `sfx_stinger_rumble_pass_01.ogg`, `sfx_stinger_scare_{01,02}.ogg` |
| `res://assets/audio/ui/` | UI pool beyond the two live cues | 9 | `ui_click_{02,03,04,05}.ogg`, `ui_confirm_01.ogg`, `ui_denied_01.ogg`, `ui_hover_{02,03}.ogg`, `ui_scroll_01.ogg` |

Cluster totals: music 6 + ambience 15 + sfx 62 + ui 9 = 93. Note the sfx clusters are unreachable for the
extra reason that `play_sfx()` currently has no caller; adding any caller also activates
`sfx_impact_rock`, `sfx_impact_hull`, `sfx_mining_beam` and `sfx_ship_engine` because their `_01` fallback
already resolves (verified mechanically, 31 of 31).

### D.1 The 12 files to wire first, with the reason for each

| # | File | Why this one, for this screen |
|---|---|---|
| 1 | `res://assets/audio/music/mus_menu_theme_01.ogg` | The only main-menu bed (M1). 205.2 s, `loop = true`. Menu v2's music bed; the `play_music()` API landed during this audit, so only a call site is missing. |
| 2 | `res://assets/audio/ambience/amb_station_room_01.ogg` | S25 station room tone 1/3 of 3, 8.2 s loop. The station hub's floor bed; the three takes exist so each module can hold a different tone. |
| 3 | `res://assets/audio/ambience/amb_station_pump_loop_01.ogg` | Station machinery-room bed, 3.1 s loop. Layers under the room tone for the OUTFITTING / UPGRADES rack area. |
| 4 | `res://assets/audio/ambience/amb_station_noise_loop_01.ogg` | Station static bed, 7.2 s loop. The quiet third layer that keeps the hub from sounding like a vacuum. |
| 5 | `res://assets/audio/sfx/sfx_station_machine_loop_01.ogg` | S18 machinery layer 1/3, 1.2 s loop, already a resolvable cue name (`sfx_station_machine_loop`). Pairs with `sfx_station_boiler_loop` and `sfx_station_hum_loop`, which also resolve. |
| 6 | `res://assets/audio/sfx/sfx_station_hum_loop_01.ogg` | S18 electrical hum layer, 1.7 s loop. The top layer of the three-part S18 bed the spec describes. |
| 7 | `res://assets/audio/sfx/sfx_ship_boost_01.ogg` | S12 boost / take-off, 5.9 s. The LAUNCH module cue. Blocked on the clipping fix (peak 1.464, anomaly C7). |
| 8 | `res://assets/audio/sfx/sfx_ship_jump_01.ogg` | S11 jump 1/2, 0.115 s, cue name `sfx_ship_jump` resolves. The undock / depart chime; shorter and cheaper than the boost for a menu confirm. |
| 9 | `res://assets/audio/sfx/sfx_station_breaker_on_01.ogg` | S19 breaker ON, 0.168 s. A mechanical power-up cue for entering a module, which keeps the station out of the UI click family. |
| 10 | `res://assets/audio/ui/ui_confirm_01.ogg` | S10 confirmation, 0.282 s, resolves as the cue `ui_confirm`. PLAY / LAUNCH confirm. Needs one new `UiCue` enum member, not a new API. |
| 11 | `res://assets/audio/ui/ui_scroll_01.ogg` | S10 menu scroll, 0.225 s, resolves as `ui_scroll`. The station's ship and upgrade lists will scroll; nothing else in the set serves that. |
| 12 | `res://assets/audio/ui/ui_denied_01.ogg` | S10 denied / blocked, 0.104 s, resolves as `ui_denied`. Insufficient credits is the one failure state the station will hit on the first frame. |

Already live and to be kept: `res://assets/audio/ui/ui_click.ogg` and `res://assets/audio/ui/ui_hover.ogg`.
The remaining 81 files are pools and gameplay cues (`sfx_impact_*`, `sfx_weapon_*`, stingers, the 9 shield
hits, the 4 mining chips) that belong to the gameplay pass, not to these two screens.

## E. Art shortlists for the two upcoming screens

### E.1 `MENU_V2_SHORTLIST`

| Role on the screen | Exact asset | Notes for the wire |
|---|---|---|
| Full-screen backdrop | `res://assets/env/env_menu_bg.png` | 2048x1152 opaque. Already wired in `main_menu.tscn`. Verified: the single burning wreck in the plate sits at anchored (0.792, 0.618), and the wired `%EmberPulse` anchor is (0.791, 0.618), so the pulse lands on the wreck. |
| Backdrop alternative if v2 changes mood | `res://assets/ui/ui_backdrop_login.png` | 2048x1152, mean luminance 37.5, one ember lamp. Darker than the vista, so text contrast is safer. |
| Title lockup | `res://assets/ui/logo_vajb_orbit.png` | 2048x2048; the live scene crops it with an `AtlasTexture` region of (44, 707, 1961, 615). Transparent PNG. |
| Button chrome, 4 states | `res://assets/ui/ui_button_plate_normal.png`, `res://assets/ui/ui_button_plate_hover.png`, `res://assets/ui/ui_button_plate_pressed.png`, `res://assets/ui/ui_button_plate_disabled.png` | 280x56 each, already wired as `StyleBoxTexture` states in `vajb_theme.tres`. The 6 px hover bloom stays engine-drawn (menu-screen privilege, `STYLE_BIBLE` section 7.3 amendment). |
| Panel / plate chrome | `res://assets/ui/ui_panel_frame.png` | 96x96. Usable for a flat plate; see anomaly C1 before using it as a 9-slice. |
| Company insignia (selection or header plate) | `res://assets/ui/ui_insignia_mic.png`, `res://assets/ui/ui_insignia_mmo.png`, `res://assets/ui/ui_insignia_ven.png`, `res://assets/ui/ui_insignia_neutral.png` | 776-783 x 889-894, transparent. Defringe before use (C3). |
| Wreck ember pulse | `res://assets/fx/fx_ember_pulse.png` | 2048x2048 RGB, already wired with `CanvasItemMaterial.blend_mode = 1` (additive) at alpha 0.25-0.45. Correct as is. |
| Film grain layer | `res://ui/theme/grain.tres` | `NoiseTexture2D`, not a generated image. Nothing to source. |
| Menu music and cues | `res://assets/audio/music/mus_menu_theme_01.ogg`, `res://assets/audio/ui/ui_click.ogg`, `res://assets/audio/ui/ui_hover.ogg`, `res://assets/audio/ui/ui_confirm_01.ogg`, `res://assets/audio/ui/ui_scroll_01.ogg` | Click and hover are live today; the other three need the music API or one enum member (section D.1). |

### E.2 `STATION_SHORTLIST`

| Role on the screen | Exact asset | Notes for the wire |
|---|---|---|
| Station backdrop | `res://assets/ui/ui_backdrop_hangar.png` | 2048x1152 opaque, docking bay girders, centre deliberately low-detail so panels read on top. |
| Station POI behind / beside the hub | `res://assets/env/env_base_shipyard.png` | 1929x1105 cutout, and per spec E section 3 it renders an **empty** construction cradle, so a ship sprite composites into it without a clash. |
| Alternate station plate | `res://assets/env/env_station.png` | 2048x2048 cutout, the B-phase dockable station. Use when the hub is presented as a POI rather than a drydock. |
| Main panel frame (all modules) | `res://assets/ui/ui_panel_frame.png` | Intended for `PanelRaised`, patch margins 32. Blocked by C1: today it would render a frame roughly 4.5 times too thick. |
| Inventory slot art | `res://assets/ui/ui_slot_inventory_normal.png`, `res://assets/ui/ui_slot_inventory_hover.png`, `res://assets/ui/ui_slot_inventory_pressed.png`, `res://assets/ui/ui_slot_inventory_disabled.png` | 56x56, interior item silhouette present (6-22 percent of interior pixels within 28 of steel highlight, dimmer in `disabled`, matching the 40 percent disabled rule). |
| Weapon slot art | `res://assets/ui/ui_slot_weapon_normal.png`, `res://assets/ui/ui_slot_weapon_hover.png`, `res://assets/ui/ui_slot_weapon_pressed.png`, `res://assets/ui/ui_slot_weapon_disabled.png` | 48x48, same state system. |
| Cargo slot art | `res://assets/ui/ui_slot_cargo_normal.png`, `res://assets/ui/ui_slot_cargo_hover.png`, `res://assets/ui/ui_slot_cargo_pressed.png`, `res://assets/ui/ui_slot_cargo_disabled.png` | 40x40, same state system. |
| OUTFITTING module icon | `res://assets/icons/icon_equip_module_48.png` (+ `_16`) | Reads as a stacked module board. Painted, full colour, no tint. |
| SHIPYARD module icon | **no shipped asset fills this role** (gap G1) | Nearest shipped: `res://assets/icons/icon_hull_48.png` (tintable flat hull glyph) or `res://assets/icons/icon_map_node_station_48.png`. Neither reads as a drydock. |
| UPGRADES module icon | `res://assets/icons/icon_equip_generator_48.png`, `res://assets/icons/icon_equip_engine_48.png`, `res://assets/icons/icon_equip_shield_gen_48.png`, `res://assets/icons/icon_equip_drone_48.png`, `res://assets/icons/icon_equip_pet_48.png`, `res://assets/icons/icon_equip_extra_48.png` | The 7 painted equipment glyphs, plus their `_16` cuts, already cover an upgrade list. |
| LAUNCH module icon | **no shipped asset fills this role** (gap G2) | Nearest shipped: `res://assets/icons/icon_map_route_48.png` (broken path line with waypoints). |
| Ammo module icons | `res://assets/icons/icon_ammo_laser_48.png`, `res://assets/icons/icon_ammo_rocket_48.png` (+ `_16`) | Painted, direct consumers. `game/station_catalog.gd` additionally binds `icon_weapon_cannon_48.png`, `icon_weapon_mine_48.png` and `icon_weapon_plasma_48.png` in the same list; see anomaly C16 before wiring those three. |
| Credits readout icon | `res://assets/icons/icon_credits_48.png` (+ `_16`) | Flat glyph, tint with the theme token (`icons/tint/icon_credits_48.png` is the derived white stencil). |
| LOG OUT icon | `res://assets/icons/icon_logout_48.png` (+ `_16`) | Flat glyph, tintable. |
| Map / sector icons | `res://assets/icons/icon_map_route_48.png`, `res://assets/icons/icon_map_bookmark_48.png`, `res://assets/icons/icon_map_node_asteroid_48.png`, `res://assets/icons/icon_map_node_danger_48.png`, `res://assets/icons/icon_map_node_gate_48.png`, `res://assets/icons/icon_map_node_home_48.png`, `res://assets/icons/icon_map_node_neutral_48.png`, `res://assets/icons/icon_map_node_pvp_48.png`, `res://assets/icons/icon_map_node_station_48.png` | Painted markers; the `_16` cuts exist for compact rows. |
| Shipyard preview sprites | `res://assets/ships/ship_vanguard_side.png`, `res://assets/ships/ship_vanguard_mmo_side.png`, `res://assets/ships/ship_gunship_side.png`, `res://assets/ships/ship_destroyer_side.png`, `res://assets/ships/ship_bomber_side.png`, `res://assets/ships/ship_mine_layer_side.png`, `res://assets/ships/ship_patrol_side.png`, `res://assets/ships/ship_trader_side.png` | Side views only (`_side` = bow right, the shipped rotation convention). 17 `_side` files exist in `assets/ships/`; these 8 are the ones with a clean matte and a full silhouette. Scale from native pixels (C13). |
| Station ambience and cues | `res://assets/audio/ambience/amb_station_room_01.ogg`, `res://assets/audio/ambience/amb_station_pump_loop_01.ogg`, `res://assets/audio/ambience/amb_station_noise_loop_01.ogg`, `res://assets/audio/sfx/sfx_station_machine_loop_01.ogg`, `res://assets/audio/sfx/sfx_station_hum_loop_01.ogg`, `res://assets/audio/sfx/sfx_station_breaker_on_01.ogg`, `res://assets/audio/sfx/sfx_ship_boost_01.ogg`, `res://assets/audio/sfx/sfx_ship_jump_01.ogg`, `res://assets/audio/ui/ui_confirm_01.ogg`, `res://assets/audio/ui/ui_denied_01.ogg`, `res://assets/audio/ui/ui_scroll_01.ogg` | All eleven need the code-side work listed in section G item 2. |

## F. Art gaps

Two roles on the station hub have no shipped asset that can fill them, plus one role whose shipped asset fails its own specification. Each brief below is ready to run on `gpt-image-2-5-flare-text-to-image` at 2K. Runs 1 and 2 prepend the standard `vajb-orbit/assets/style-block.txt` exactly as Phase D/E did, then the subject paragraph, then "2K, 1:1" and the family negative list.

### G1. Shipyard module glyph (station module icon)

Painted industrial glyph for the station hub's SHIPYARD module button, one isolated object centred in the frame with generous clean margins: a compact drydock cradle seen top-down, two short gantry towers flanking an open construction bed, four mooring clamps and two tug rails along the spine, an empty hull-shaped cradle between the towers, painted weathered gunmetal in gunmetal mid `#3A3F46`, gunmetal dark `#2B2F35` and iron black `#232629` with a steel highlight `#565C63` rim on the upper-left edges and one small hot burnt ember `#C8461B` lamp on the port gantry mast, no second glow, subtle film grain, top-down orthographic, harsh upper-left key light, silhouette-first design so the cradle reads by its blacked-out outline at 48 px, no letterforms, no numbers, no arrows, no ships in frame, no cranes over a hull, no UI frame, no grid lines, no text, no watermark. Negative list: no chrome, no neon, no gloss, no purple, no green, no teal, no yellow, no blue, no rainbow, no smiley faces, no gradients outside the palette. Aspect ratio 1:1, 2048x2048, one subject. Painted on a plain pure white background so the local matte can key it, and **this glyph must ship transparent**; the delivered file must be an RGBA PNG with more than 10 percent of pixels at alpha 0 once keyed, and the interior of the cradle must stay opaque. Output is a 2K master named `icon_module_shipyard.png` plus 48 px and 16 px cuts, because no shipped icon carries the `ship` or `launch` group today.

### G2. Launch / depart glyph (station module icon)

Painted industrial glyph for the station hub's LAUNCH module button, one isolated object centred in the frame: a heavy bay door aperture seen top-down, half-open, with a single squat thruster nozzle core behind it and two short chevron exhaust vanes, painted weathered gunmetal in gunmetal mid `#3A3F46` and gunmetal dark `#2B2F35` with iron black `#232629` recesses, a thin steel highlight `#565C63` rim on the upper-left edges, and the only emissive is a small hot burnt ember `#C8461B` core inside the nozzle with a restrained ember glow `#E8703A` halo, small and contained, no ambient bloom, a single hard light from the upper-left, heavy pitted metal and scorch marks radiating from the nozzle port, subtle film grain, top-down orthographic, silhouette-first so the door-and-nozzle read survives at 48 px, no letterforms, no numbers, no arrows, no chevrons as text, no ship, no station in frame, no UI frame, no grid lines, no text, no watermark. Negative list: no chrome, no neon, no gloss, no purple, no green, no teal, no yellow, no blue, no rainbow, no lens flare, no star field. Aspect ratio 1:1, 2048x2048, one subject. Plain pure white background for the local matte, and **this glyph must ship transparent** (RGBA, more than 10 percent alpha-0 pixels after keying). Master `icon_module_launch.png` plus 48 px and 16 px cuts. If both module glyphs are generated in one run instead, generate a 2-cell 1x2 panel with equal gaps, then cut on the empty margin; a component split is safe because each glyph is one island.

### G3. `ui_panel_frame.png` regenerated at the specified frame width (station panel chrome)

Regenerate the nine-slice metal panel frame at 96x96 with a frame band that is actually **32 px wide**, since the shipped file measures 7 px and the theme, the spec and the station plan all assume 32 (anomaly C1). One square panel frame filling the frame: a weathered gunmetal plate border, chamfered 45 degree corners, painted panel steel `#2A2E35` border face with a 1 px steel highlight `#565C63` inner edge catch and an iron black `#232629` outer edge, a recessed interior of panel black `#15181D` with a very subtle inner shadow just inside the frame, two or three small pitted rivet heads with a steel highlight catch set into each of the four corner blocks and entirely inside the corner squares, the left edge band identical top to bottom, the top edge band identical left to right, and likewise right and bottom, so the 32 px edge bands tile cleanly when stretched, faint hull grime toward the frame with no rust streaks and no oil stains, subtle film grain at reduced opacity, no letterforms anywhere. Negative list: no chrome, no neon, no gloss, no rounded corners, no purple, no green, no teal, no yellow, no blue, no rainbow, no ember glow anywhere in the frame, no text, no labels, no grid lines, no watermark. Aspect ratio 1:1, 2048x2048, generated at 2K and delivered at 96x96. **This piece does not need transparency**: ship an opaque interior (RGBA is fine, but no see-through centre) so it can sit behind a `PanelContainer` as a background.
### F.1 No other gaps, and the closest shipped match for every remaining role

| Screen | Role | Closest shipped asset that fills it |
|---|---|---|
| Menu v2 | backdrop | `res://assets/env/env_menu_bg.png` (verified ember alignment, section E.1) |
| Menu v2 | title lockup | `res://assets/ui/logo_vajb_orbit.png` |
| Menu v2 | button chrome, all four states | `res://assets/ui/ui_button_plate_normal.png`, `res://assets/ui/ui_button_plate_hover.png`, `res://assets/ui/ui_button_plate_pressed.png`, `res://assets/ui/ui_button_plate_disabled.png` |
| Menu v2 | film grain | `res://ui/theme/grain.tres` |
| Menu v2 | hover bloom | engine-drawn 6 px `StyleBoxFlat` underlay, intentionally not art |
| Menu v2 | company insignia | `res://assets/ui/ui_insignia_mic.png`, `res://assets/ui/ui_insignia_mmo.png`, `res://assets/ui/ui_insignia_ven.png`, `res://assets/ui/ui_insignia_neutral.png` |
| Menu v2 / STATION | credits, logout, map | `res://assets/icons/icon_credits_48.png`, `res://assets/icons/icon_logout_48.png`, `res://assets/icons/icon_map_route_48.png` |
| STATION | backdrop | `res://assets/ui/ui_backdrop_hangar.png` |
| STATION | panel chrome | `res://assets/ui/ui_panel_frame.png` at its measured 7 px margins, or regenerated per G3 |
| STATION | inventory slot art (4 states) | `res://assets/ui/ui_slot_inventory_normal.png`, `res://assets/ui/ui_slot_inventory_hover.png`, `res://assets/ui/ui_slot_inventory_pressed.png`, `res://assets/ui/ui_slot_inventory_disabled.png` |
| STATION | weapon slot art (4 states) | `res://assets/ui/ui_slot_weapon_normal.png`, `res://assets/ui/ui_slot_weapon_hover.png`, `res://assets/ui/ui_slot_weapon_pressed.png`, `res://assets/ui/ui_slot_weapon_disabled.png` |
| STATION | cargo slot art (4 states) | `res://assets/ui/ui_slot_cargo_normal.png`, `res://assets/ui/ui_slot_cargo_hover.png`, `res://assets/ui/ui_slot_cargo_pressed.png`, `res://assets/ui/ui_slot_cargo_disabled.png` |
| STATION | shipyard preview sprite | `res://assets/ships/ship_vanguard_side.png` and the other 7 clean `_side` views in section E.2 |
| STATION | OUTFITTING module icon | `res://assets/icons/icon_equip_module_48.png` (the other six `icon_equip_*_48.png` cuts are enumerated in section E.2) |
| STATION | UPGRADES module icons | `res://assets/icons/icon_equip_generator_48.png`, `res://assets/icons/icon_equip_engine_48.png`, `res://assets/icons/icon_equip_shield_gen_48.png`, `res://assets/icons/icon_equip_drone_48.png`, `res://assets/icons/icon_equip_pet_48.png`, `res://assets/icons/icon_equip_extra_48.png` |
| STATION | ammo module icons | `res://assets/icons/icon_ammo_laser_48.png`, `res://assets/icons/icon_ammo_rocket_48.png` |
| STATION | map markers | `res://assets/icons/icon_map_route_48.png`, `res://assets/icons/icon_map_bookmark_48.png`, `res://assets/icons/icon_map_node_asteroid_48.png`, `res://assets/icons/icon_map_node_danger_48.png`, `res://assets/icons/icon_map_node_gate_48.png`, `res://assets/icons/icon_map_node_home_48.png`, `res://assets/icons/icon_map_node_neutral_48.png`, `res://assets/icons/icon_map_node_pvp_48.png`, `res://assets/icons/icon_map_node_station_48.png` |
| STATION | hangar / drydock plate with an empty cradle | `res://assets/env/env_base_shipyard.png` |
| STATION | station ambience and cues | the 11 audio files in section E.2 |

**Late arrivals and what is still not verified.** `docs/design/STATION_SPEC.md` and
`vajb-orbit/game/station_catalog.gd` were written by a parallel worker while this audit was running, so the
station contract now exists and part of this audit's blind spot is closed: all 15 `res://assets/` paths in the
catalogue were re-checked against disk and all 15 exist (2 Phase B and 2 Phase D ship previews for
`ship_fighter`, `ship_vanguard`, `ship_gunship`, `ship_destroyer`, and 11 icons, three of which are the flat
glyphs noted in anomaly C16). `MAIN_MENU_V2.md` and `STATION_HUB.md` are still absent, so any menu v2 or hub
layout change beyond `MAIN_MENU_SPEC.md` and `IMPLEMENTATION_PLAN.md` section 9 remains unknown, and the
catalogue's prices and names were not audited (not an art question). 16 px icon legibility was assessed
numerically (ink coverage and edge contact) and not by eye. Loop-seam quality was not re-measured; the
handoff's numbers were not independently confirmed.

## G. Recommendations

1. **Bind now, no new art needed.** On the station hub: `ui_backdrop_hangar.png`, the 12 slot state plates
   enumerated in section E.2, the seven `icon_equip_*_48.png` equipment icons (also enumerated in E.2, for
   example `icon_equip_generator_48.png`), `icon_ammo_laser_48.png`, `icon_ammo_rocket_48.png`,
   `icon_credits_48.png`, `icon_logout_48.png`, `icon_map_route_48.png` and the eight other map markers named
   in E.2, `ship_vanguard_side.png` plus the 7 other clean side views, and `env_base_shipyard.png`. On menu
   v2: `env_menu_bg.png`, `logo_vajb_orbit.png`, the 4 button plates, `fx_ember_pulse.png`, the 4 insignia.
   Everything in that list already imports cleanly and is palette-conformant by measurement.
2. **Unblock audio before wiring it.** The music and ambience API already landed during this audit
   (`play_music`, `play_ambience`, and an `ambience` entry in `Paths.AUDIO_DIRS`), so the remaining work is
   call sites: `main_menu` calls `play_music(&"mus_menu_theme")`, the station screen calls `play_ambience`
   plus the S18 layers, and the `UiCue` enum gains `CONFIRM`, `DENIED` and `SCROLL` so the three already
   resolving ui cues become reachable. Then wire the 12 files in section D.1. Normalise
   `sfx_ship_boost_01.ogg` first: at peak 1.464 it clips.
3. **Fix the panel frame before the station hub ships.** Either regenerate `ui_panel_frame.png` at a true
   32 px frame width (brief G3, one run) or set `PANEL_FRAME_MARGIN` to the measured 7 px in
   `tools/build_theme.gd:23` and re-run the theme build. Do not wire `PanelRaised` with the current 32 px
   margin on the current texture.
4. **Defringe the 13 flagged files** with the existing local pipeline (`staging/phase_d/reprocess.py`, bright
   rim defringe) rather than regenerating them. The 4 insignia matter most because they are on both screens.
5. **Reject from any consumer:** the 3 panel masters (`panel_boosters.png`, `panel_status.png`,
   `env/panel_asteroids_b.png`) and the 16 component icon masters, per the documented consumer rule;
   `icon_cargo_data_core_16.png` (illegible at 16 px, anomaly C2); `sfx_mining_chip_04.ogg` and
   `sfx_weapon_laser_04.ogg` as pool members until their durations are trimmed (anomalies C8, C9).
6. **Regenerate only if the owner wants to spend:** the two newest-image candidates are G1 (shipyard glyph)
   and G2 (launch glyph), one run each, both transparent sprites; G3 (panel frame) is a fix rather than new
   content and is the highest value per credit of the three because it is already blocking a scheduled theme
   item. Lower priority: `env_body_ice_moon.png` for its value regression (anomaly C4) and a widening pass on
   `ship_interceptor_side.png` (already an open item in `ASSET_EXPANSION_SPEC.md` section 11.5).
7. **Documentation fixes, no asset change:** correct `ASSET_WIRING_HANDOFF.md` section 1.4 (11 of 16 ambience
   files loop, not 16); record the frame grid for every multi-frame FX sheet (2x3 for `fx_explosion.png`, 1x4
   for the other four); tighten the `ASSET_CATALOG.md` alpha wording for opaque UI plates and for
   `ui_minimap_bezel.png`. If the catalog gains a `grid` column, generated from the alpha/ink projection, all
   four items become self-documenting.
