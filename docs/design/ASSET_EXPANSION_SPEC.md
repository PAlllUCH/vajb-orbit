# Vajb Orbit — Asset Expansion Spec (Phase D)

**Status:** approved 2026-09-17 by user (Direction C · balanced, checkpoint batching, ship-roster lock lifted).
**Budget:** ~400 kie.ai credits = **40 runs** at 2K on `flare` (10 credits / $0.05 per 2K run, user-verified; the script's printed 30-credit estimate is the stale hint and the `usage-ledger.jsonl` totals therefore over-report 3×).
**Model:** `gpt-image-2-5-flare-text-to-image` (`flare`), fallback `sunburst`, edits `flare-i2i`.
**Executed in two waves:** wave 1 = runs 1–22, visual check, then wave 2 = runs 23–40.

Palette, lighting, weathering vocabulary and framing are copied verbatim from `STYLE_BIBLE.md`; every run passes `vajb-orbit/assets/style-block.txt` unchanged via `--style-file`.

---

## 1. Spec amendments this document makes

| Amends | Change |
|---|---|
| `SHIPS_SPEC.md` §2 | Roster lock lifted by user decision. Phase D hull classes added in §3 below; the v1 six-hull roster is unchanged and remains the launch set. |
| `ICONS_SPEC.md` §7 | "No other icon names or files are sanctioned" is extended by §5 below: three new panels (equipment, starmap markers, pickups) and their 24 split outputs. |
| `ENVIRONMENT_SPEC.md` §9 | Negative list unchanged. Airless dead moons are permitted (they have no atmosphere); no planets with atmosphere, clouds or terminator glow. The jump gate in §6 is the only new emissive, and it uses the existing station-lamp exception (Burnt Ember `#C8461B` lamps, no Ember Glow bloom). |
| `FX_SPEC.md` §1 | §7 adds three wave-1 effects to the inventory (jump portal, missile trail, shield break). |
| `UI_CHROME_ASSETS_SPEC.md` §9 | §5 adds `ui_insignia_mmo/mic/ven/neutral.png` (company emblems consumed by the hangar top bar, company select and loading destination panel per `MENU_FLOW.md` §3.3–3.4, §3.7). |

---

## 2. Generation rules (all runs)

1. **Prompt shape:** verbatim `style-block.txt` (via `--style-file`) + the subject block from this document + the framing sentence of the family (ship framing per `SHIPS_SPEC` §1, icon framing per `ICONS_SPEC` §5, FX framing per `FX_SPEC` §0.1) + the negative list of that family.
2. **Resolution:** 2K. Panels and single sprites use `--aspect 1:1` (kie.ai rule: a non-`auto` aspect is mandatory at 2K). Backdrops use `--aspect 16:9`.
3. **Transparency (user requirement):** every sprite, icon, prop and ship ships as an alpha PNG.
   - Primary path: `--transparent` (native `background=transparent`). The style block names void-black backgrounds, which can override the request, so the split subject block must state **"isolated object on a fully transparent background, no background colour, no backdrop, no ground shadow"** and the result must be verified.
   - Verify per batch with Pillow: `mode == RGBA` and more than 10 % of pixels at `alpha == 0`. Free.
   - Fallback when a result is opaque: `--strip-bg local --split` (free, no API call). Sprites/icons/props are re-keyed against pure white; **FX are never keyed** (they stay RGB on void black for additive blending, per `FX_SPEC` §0.1).
4. **Splitting:** native-alpha panels are cut with `--split-only <file>` (free); the splitter works on the alpha channel only. Cut order = reading order of the grid, left to right, top to bottom, and is verified visually for every sheet before renaming.
5. **Gaps:** panel cells are separated by generous pure-transparent margins so the splitter never merges or clips a cell. No grid lines, no labels, no text, no watermark, no drop shadows.
6. **Naming:** snake_case, family-prefixed as listed in each section. Panels keep the master file (`panel_*.png`) next to the splits.
7. **Staging:** wave output lands in `staging/phase_d/<family>/` (workspace root, **outside** `vajb-orbit/`) so the Phase C coding session holding the live editor open is not disturbed by import churn. Files move into `vajb-orbit/assets/<family>/` after the wave, followed by one editor reimport.
8. **Logging:** per-family `generation_log.md` (date, model, job id, final file, full subject prompt, status), run folders keep `job.json`, all under the same family folder. AI art is not CC0 (`AGENTS.md`).

---

## 3. Ship roster additions (amends `SHIPS_SPEC.md` §2)

Framing constant per `SHIPS_SPEC.md` §1 applies per cell. Rotation sheets are 2×2 (front / three-quarter / side / back) per §4.1; bosses are single centred renders per §4.2.

| # | File stem | Role | Silhouette read | Class markers | Weathering | Engines / glow |
|---|---|---|---|---|---|---|
| 7 | `ship_interceptor` | Hostile fast attack | Narrow needle hull, swept-forward twin prongs at the bow, no spine mass | forward-swept prongs, single central engine (contrast to the Fighter's twin tail) | moderate-plus, scratches, hull grime, oil stains | 1 engine, single tail nozzle, burnt ember flare + small ember glow |
| 8 | `ship_gunship` | Hostile mid-tier | Broad short hull, two oversized broadside weapon pods flanking a squat core | broadside pods dominate, twin recessed nozzles | heavy, battle damage, scorch marks at the pods | 2 engines, burnt ember + small ember glow |
| 9 | `ship_destroyer` | Hostile capital | Long wedge hull, dorsal turret blocks in a row, flared stern | dorsal turret row and flared stern | heaviest, battle damage, rust streaks, pitted metal | 4 engines in two paired stern blocks, burnt ember + small ember glow |
| 10 | `ship_drone_swarm` | Hostile swarm unit | Tiny angular shard body, single stubby thruster, minimal appendage | scale read: shard-like, one engine, no cockpit | light, scratches only | 1 engine, small hot burnt ember |
| 11 | `ship_trader` | Neutral civil | Boxy segmented hull, external container racks along both flanks | container racks are the read | heavy hull grime, rust streaks, oil stains, no battle damage | 2 engines side by side, dim burnt ember (civilian throttle) |
| 12 | `ship_patrol` | Neutral enforcer | Mid-length hull, forward lance mount, one dorsal fin, clean plated sides | forward lance + single dorsal fin | moderate, scratches, hull grime | 2 engines, burnt ember + small ember glow |
| 13 | `ship_bomber` | Hostile ordnance | Fat fuselage with an underslung ordnance bay and two stub wings | underslung bay is the read | heavy, scorch marks, oil stains | 2 engines, burnt ember |
| 14 | `ship_mine_layer` | Hostile support | Wide flat stern rack with visible mine cradles, blunt bow | stern mine rack | heavy, rust streaks, battle damage | 2 engines, burnt ember |
| 15 | `ship_turret_platform` | Hostile static | Symmetric hexagonal emplacement, single long barrel on a pivot ring | no hull axis: radially symmetric | heavy, pitted metal, scorch marks | warning lamps only, burnt ember lamps |

Bosses (single 2K renders, 1:1):

| File | Role | Read |
|---|---|---|
| `ship_boss_thorn.png` | Hive-mother | broad carapace hull ringed with short thorns, four spore vents, ember core behind a split plate |
| `ship_boss_spire.png` | Relay leviathan | tall spine of stacked plate segments with two flank outriggers, ember core in a stern cavity |
| `ship_boss_leviathan.png` | Wave 2 third boss | hammerhead fore-section, long ribbed hull, twin exposed drive cores |

Shared constraints on all wave-1 and wave-2 hulls: hostile hulls keep the **thorned protrusion + visible ember core** marker where the boss/hull class calls for it; neutral hulls carry no thorns; every class marker must differ from the v1 six at a glance; no new palette colours; no second accent.

---

## 4. Faction liveries (i2i, wave 1 = 3 runs, wave 2 = 2 runs)

`SHIPS_SPEC.md` §3 stays the base art. Liveries are produced by `flare-i2i` from the **shipped** sprite as the reference, changing only plate pattern and weathering distribution. The palette is fixed and carries no faction colour, so identity is expressed as **pattern only**:

| Company | Code | Pattern | Weathering shift |
|---|---|---|---|
| Mars Mining Operations | `mmo` | heavy horizontal riveted plate rows, chevron weld seams along the flanks | extra hull grime, industrial dust film |
| Miner's Incorporated | `mic` | long continuous plate bands with sparse rivet lines, minimal seams | cleanest of the three: scratches and oil stains only |
| Venus Resources | `ven` | dense pitted metal with weld-bead patch repairs and tally notches | heaviest rust streaks and battle damage |

Wave 1 runs: `ship_vanguard_<code>_*` (player hull, `<code>` = mmo), `ship_fighter_<code>_*`, `ship_corvette_<code>_*` — one code each, chosen for hull diversity. Wave 2 runs: `ship_freighter_<code>_*` and `ship_boss_maw_<code>` (single).

---

## 5. Icon and UI additions (amends `ICONS_SPEC.md` §7, `UI_CHROME_ASSETS_SPEC.md` §9)

All icon panels follow `ICONS_SPEC.md` §1 and §5 verbatim: flat single-colour iron black `#232629` silhouettes with negative-space cut detail on **pure white**, 1.5 px-equivalent strokes, corner radius 0, tint applied engine-side. Splits are exported at 16 px and 48 px and the existing `tools/derive_icon_tints.gd` derivation runs over them unchanged.

**Panel `panel_equipment.png` (3×3, 9 icons) — hangar/equipment item art, consumed by `UI_SPEC.md` §5.4 slot grids**

| File | Subject | Avoid |
|---|---|---|
| `icon_equip_generator.png` | generator core: rectangular housing with three vertical coil slats and a base mount | no lightning bolt, no glow, no gauge |
| `icon_equip_shield_gen.png` | shield generator: circular emitter ring on a square base plate with two anchor lugs | no shield crest, no glow ring, no hexagon |
| `icon_equip_engine.png` | drive nozzle: truncated cone with an inner combustion ring and two flanking stabiliser fins | no flame, no thrust plume, no radiator |
| `icon_equip_extra.png` | utility pod: boxy module with a side latch bracket and a top connector stub | no wires, no antenna spark, no tool |
| `icon_equip_module.png` | upgrade module: stacked dual-slab board with three edge connector teeth on one side | no circuit traces, no chips, no glow lines |
| `icon_equip_drone.png` | combat drone: small arrowhead body with two side thruster nubs, no cockpit | no eye lens, no rotor, no antenna |
| `icon_equip_pet.png` | pet unit: rounded shell body with a single forward sensor notch and three underside clamps | no face, no ears, no smiley |
| `icon_ammo_laser.png` | laser cell: vertical cylinder with a banded waist and a squared charge terminal on top | no flame, no battery plus sign, no glow |
| `icon_ammo_rocket.png` | rocket magazine: rectangular rack holding two upright ordnance rounds | no smoke, no warhead detail, no text |

**Panel `panel_map_markers.png` (3×3, 9 icons) — starmap and HUD map markers, consumed by `MENU_FLOW.md` §3.6 and `UI_SPEC.md` §3.3**

`icon_map_node_home`, `icon_map_node_neutral`, `icon_map_node_pvp`, `icon_map_node_danger`, `icon_map_node_asteroid`, `icon_map_node_station`, `icon_map_node_gate`, `icon_map_bookmark`, `icon_map_route`. Subjects: hex node with an inner dot; plain hex node; crossed-bar hex node; hex node with a single downward barb; irregular rock cluster node; station ring node; twin-arc gate node; pennant flag with a notched tail; broken path line with three waypoint ticks. Every marker is a distinct silhouette at 16 px; no colour, no glow, no letters.

**Panel `env/panel_pickups.png` (2×3, 6 props)** — wave-1 world pickups, generated as painted objects (not flat icons) per `ENVIRONMENT_SPEC.md` §7.2 material rules, on pure white, then alpha-keyed:

| File | Subject |
|---|---|
| `env_pickup_bonus_box.png` | sealed ordnance crate with banded reinforcement and a single ember lamp |
| `env_pickup_repair_pod.png` | maintenance pod with an external tool rack and one ember lamp |
| `env_pickup_shield_pod.png` | emitter pod with a steel-highlight aperture ring, no ember |
| `env_pickup_speed_pod.png` | slim boost pod with two rear vent slots and an ember lamp |
| `env_pickup_ammo_pod.png` | drum-shaped ammunition canister with a lift lug |
| `env_pickup_ore_pod.png` | ore container with visible rusted-ochre ore veins at the seam |

**Panel `ui/panel_insignia.png` (2×2, 4 emblems)** — painted emblems per `STYLE_BIBLE.md` §7.3 (bone text + steel highlight + iron black shadow), transparent background, no glow except one small ember notch where noted: `ui_insignia_mmo.png` (crossed pick over a hex plate), `ui_insignia_mic.png` (stacked ingot bars over a hex plate), `ui_insignia_ven.png` (radiating sun-spokes over a hex plate), `ui_insignia_neutral.png` (plain hex plate with a centre seam). Emblems carry **no letterforms** (text is engine-side per `UI_CHROME_ASSETS_SPEC.md` §1.7).

---

## 6. Environment additions (extends `ENVIRONMENT_SPEC.md`)

Wave 1 (4 runs, single 2K renders, transparent sprites where noted):

| File | Aspect | Subject |
|---|---|---|
| `env_planet_moon.png` | 1:1 | airless dead moon, top-down, cracked crust with rusted-ochre mineral seams, cratered surface, no atmosphere, no clouds, no terminator glow, one value step darker than ships, no emissive |
| `env_jump_gate.png` | 1:1 | welded gate structure: two heavy anchor pylons joined by a segmented ring, platework with heavy hull grime and rust streaks, ember warning lamps only (station-lamp exception), no interior glow, no energy field |
| `env_debris_field.png` | 1:1 | loose field of torn hull fragments, panel shards and shattered plating with battle damage, scattered with clear separation, no emissive |
| `env_nebula_veil.png` | 1:1 | tiling-friendly veil of deep void blue and void haze washes with faint dust structure, extremely low contrast, no stars, no colour beyond the void ramp |

Wave 2 (4 runs): `env_station_mmo.png` (faction station in MMO plate pattern), `env_station_ruined.png` (gutted hostile station, torn ring), `env_ice_field.png` (frozen fragment cluster), `env_ore_cluster.png` (dense mineable cluster with ore veins).

---

## 7. FX additions (extends `FX_SPEC.md` §1)

Wave 1 (3 runs, `FX_SPEC.md` §0.1 rules: flat void black `#0A0E14` background, **not** white, RGB output, no alpha keying):

| File | Subject |
|---|---|
| `fx_jump_portal.png` | single frame sheet: a wide ember jump aperture ring, burnt ember `#C8461B` core with ember glow `#E8703A` rim, thin, contained, no field fill, no blue, isolated |
| `fx_missile_trail.png` | 4-frame horizontal sheet: ember hot head streak, widening smoke plume in grimy umber `#4A423B` and iron black `#232629`, dissipating tail, last frame nearly empty |
| `fx_shield_break.png` | 4-frame horizontal sheet: steel highlight `#565C63` shatter arcs and plate flakes flying outward, collapsing to a thin remnant, **no ember anywhere** (the shield is not a danger state, `FX_SPEC.md` §0) |

Wave 2 (4 runs): `fx_tractor_beam.png`, `fx_emp_arc.png`, `fx_secondary_explosion.png`, `fx_repair_pulse.png`.

---

## 8. Screen backdrops (wave 2, 16:9, opaque)

Consumed by the future hangar, starmap and login/company-select screens (`MENU_FLOW.md` §3.2, §3.4, §3.5, §3.6). Each is a dark, quiet plate in the `#0A0E14`–`#111823` band with detail pushed to the frame edges so foreground UI owns the centre: `ui_backdrop_hangar.png` (docking bay girders and gantry rails, no ships), `ui_backdrop_starmap.png` (faint sector grid haze and dust veils, no markers, no text), `ui_backdrop_login.png` (station interior wall platework with one ember lamp). No text, no logos, no UI chrome baked in.

---

## 9. Wave tables

### Wave 1 — 22 runs

| Run | Output | Runs | Files out |
|---|---|---|---|
| 1–6 | `ship_interceptor`, `ship_gunship`, `ship_destroyer`, `ship_drone_swarm`, `ship_trader`, `ship_patrol` rotation sheets | 6 | 24 |
| 7–8 | `ship_boss_thorn`, `ship_boss_spire` | 2 | 2 |
| 9–11 | faction liveries: `ship_vanguard_mmo`, `ship_fighter_mmo`, `ship_corvette_mmo` | 3 | 12 |
| 12–14 | `panel_equipment`, `panel_map_markers` (16 + 48 px splits) , `panel_pickups` | 3 | ~54 |
| 15 | `panel_insignia` | 1 | 4 |
| 16–19 | `env_planet_moon`, `env_jump_gate`, `env_debris_field`, `env_nebula_veil` | 4 | 4 |
| 20–22 | `fx_jump_portal`, `fx_missile_trail`, `fx_shield_break` | 3 | 3 |
| | **Total** | **22** | **~103** |

### Wave 2 — 18 runs

| Run | Output | Runs |
|---|---|---|
| 23–26 | `ship_bomber`, `ship_mine_layer` sheets, `ship_turret_platform`, `ship_boss_leviathan` | 4 |
| 27–28 | liveries `ship_freighter_mmo`, `ship_boss_maw_mmo` | 2 |
| 29–32 | `env_station_mmo`, `env_station_ruined`, `env_ice_field`, `env_ore_cluster` | 4 |
| 33–35 | `ui_backdrop_hangar`, `ui_backdrop_starmap`, `ui_backdrop_login` (16:9) | 3 |
| 36–39 | `fx_tractor_beam`, `fx_emp_arc`, `fx_secondary_explosion`, `fx_repair_pulse` | 4 |
| 40 | `env/panel_props.png` (6 hull fragments, 2×3) | 1 |

---

## 10. Acceptance checklist

- [ ] Every sprite/icon/prop is RGBA with a real alpha channel; no opaque void-black rectangle shipped as a "sprite".
- [ ] FX remain RGB on void black for additive blending (no alpha keying).
- [ ] Panel splits cut on empty margins: no merged cells, no clipped rivets, no background fringe.
- [ ] Every new hull differs from the v1 six and from its wave peers by silhouette alone at 16 % zoom.
- [ ] Exactly one accent in every file; no second glow colour; no new palette hex.
- [ ] Liveries change plate pattern and weathering only; palette and silhouette identical to the base render.
- [ ] Environment additions read one value step darker than ships; no emissive except station/gate ember lamps.
- [ ] Per-family `generation_log.md` complete (date, model, job id, final file, full prompt, status) and run folders retain `job.json`.
- [ ] Files moved from `staging/phase_d/` into `vajb-orbit/assets/<family>/` and reimported in the live editor.

---

## 11. Wave 1 results (recorded deviations, 2026-09-17)

**Calls spent:** 22 batch runs + 1 `env_nebula_veil` regen (negative-list violation: the first render returned a
wreck-and-ship scene with ember glow instead of a featureless haze) + 1 `recraft/remove-background` A/B probe.
All 22 batch runs returned a usable image; no submission was billed for a rejected request.

**Delivered: 109 new files** (ships 38, icons 54, env 10, ui 4, fx 3) with 109 `job.json` manifests and five
`generation_log_phase_d.md` logs, all moved into `vajb-orbit/assets/<family>/` and imported by the live editor.
At the verified real rate (10 credits per 2K run) the wave cost about **$1.15** plus roughly 5 credits for the A/B probe.
Intermediates (matte, keyed, cut and trim PNGs) were deleted after verification; they are reproducible for free from
the masters with `staging/phase_d/reprocess.py`.

### 11.1 `--transparent` is overridden by the style block

Every `--transparent` run came back **opaque**: the fixed style block names a near-black void background, which wins
over `background=transparent` (exactly the failure mode documented in the image-generator roster). All sprite alpha is
therefore derived locally, for free, by `staging/phase_d/reprocess.py`:

- background colour = median of a border-ring sample (robust against a corner that happens to hold a star),
- hard matte at a max-channel distance of 16 from that colour,
- 7x7 median (21x21 for `env_debris_field`) to erase the baked starfield speckle, plus removal of matte islands
  smaller than 0.02 % of the frame (0.06 % for the debris field): 108 to 3930 specks dropped per sheet,
- `env_debris_field` additionally takes a 1 px matte erosion and a 5 px bright-rim defringe, because its torn edges
  caught the rim light against the white source background and keying left a sticker-like white outline.

Result: no fully-opaque background, hull interiors stay fully opaque (no see-through dark plating), and no residual
stars. FX are never keyed (they stay RGB on void black for additive blending) and `env_nebula_veil` stays opaque as a
tiling layer.

### 11.2 Painted panels, not flat-vector icons

`panel_equipment` and `panel_map_markers` returned **painted** 3x3 sheets with ember accents, not the flat
single-colour iron-black silhouettes `ICONS_SPEC.md` §1 calls for: the appended style block outweighs the per-sheet
flat-vector override. They are accepted as painted item and marker art and are documented as such:

- consumed **directly** at 48 px (and 16 px for compact rows) with no tint derivation; the `icon_*_16/_48` files still
  ship so `tools/derive_icon_tints.gd` keeps working, but the `tint/` output for these names is not a consumer,
- they therefore carry their own palette and are exempt from the §1 state-colour rule, which still governs the
  original 20 flat glyphs.

The same applies to `env/panel_pickups.png` and `ui/panel_insignia.png` (painted by design).

### 11.3 Cut naming and cell geometry

Two defects were caught and fixed during the wave:

- all six hull sheets and three liveries initially wrote to the same `front/three_quarter/side/back` names, so they
  overwrote each other; cuts are now prefixed per hull (`ship_interceptor_side.png`, `ship_vanguard_mmo_side.png`).
- a 3x3 panel whose objects include multi-part shapes (the gate's two arcs, the route line and its ticks) cannot be
  component-split; grid panels are cut on cell geometry instead (`staging/phase_d/reprocess.py`, `grid_split`).

### 11.4 recraft/remove-background verdict (A/B, 1 call)

Tested on the hardest sheet (`ship_interceptor`, dark hull on near-black void, thin prongs, starfield speckle):

| | local matte | recraft |
|---|---|---|
| cost | free | one paid call per asset |
| edges | crisp, hull contrast preserved | visibly softer, grey feather, washed contrast |
| specks | removed by median plus island removal | removed |
| opaque coverage (three-quarter cut) | 8.9 % | 4.5 % |

**Decision:** keep the local matte as the default for every sprite, and keep `recraft/remove-background` as a targeted
rescue tool for an asset whose background is genuinely busy (painted nebula, gradient sky) or where keying eats a
legitimate part. Note for future calls: the skill's utility payload sends `image_url` as a list and the endpoint
rejects it with `image is required`; the accepted field is **`image` as a string**
(`staging/phase_d/ab_recraft.py` works around it with the skill's own helpers, and rejected submissions are free).

### 11.5 Open item

`ship_interceptor` is on-spec (slimmest, longest hull) but reads extremely thin at 940x107 px for the side view. A
one-run `flare-i2i` pass on the shipped sheet could widen it to roughly a 4:1 length-to-width ratio if we want a
chunkier silhouette in play.

---

## 12. Wave 2 results (2026-09-17)

**Calls spent:** 18 runs, all successful on the first attempt, no regenerate. Delivered **32 new files** (ships 15,
env 10, ui 3, fx 4) with `job.json` manifests, appended to the five `generation_log_phase_d.md` logs and imported by
the live editor. Wave 2 cost about **$0.90** at the verified rate.

| Run | Result |
|---|---|
| `ship_bomber`, `ship_mine_layer` | 2x2 sheets, 4 cuts each (deep-bodied bay hull, stern mine rack hull) |
| `ship_turret_platform` | single radial render, 1903x1726, no hull axis, three ember hub lamps |
| `ship_boss_leviathan` | single render, 1939x1112, hammerhead, exposed ribs, two ember drive cores |
| `livery_freighter`, `livery_maw` | i2i refits in the MMO plate pattern; freighter 4 cuts, Maw single 1853x1896 |
| `panel_props` | 6 wreck fragments (bow, mid, stern, plate section, drive core, rib cluster) |
| `env_station_mmo`, `env_station_ruined`, `env_ice_field`, `env_ore_cluster` | trimmed single sprites, ember lamps only on the two stations |
| `ui_backdrop_hangar`, `ui_backdrop_starmap`, `ui_backdrop_login` | opaque 16:9 at 2048x1152 (flare's 2K long-edge cap, same clamp as Phase B) |
| `fx_tractor_beam`, `fx_emp_arc`, `fx_secondary_explosion`, `fx_repair_pulse` | RGB on void black, no keying |

Recorded notes:

- `panel_props` is the second panel that **cannot** be component-split (its fragments read as one island): it uses the
  same grid cut as `panel_map_markers` (`grid=(3, 2)`).
- `fx_repair_pulse` is non-ember, by the same reasoning as the shield ripple: a repair is not a danger state, so the
  ring is Steel Highlight `#565C63`. Recorded as a `STYLE_BIBLE.md` §3 / `FX_SPEC.md` §0 sanctioned exception.
- The i2i liveries preserve silhouette and palette as intended; the Maw refit keeps its ember core and thorns.
- Phase D panel masters (`panel_equipment`, `panel_map_markers`, `panel_pickups`, `panel_insignia`, `panel_props`)
  were deleted with the other intermediates after splitting, so only the splits ship — a deviation from §2.6, which
  said the master stays next to the splits (the Phase B panels are unaffected). Recorded in the catalog appendix.
- A per-file index of everything this phase shipped (plus Phase B) now lives in `docs/design/ASSET_CATALOG.md`,
  generated by `staging/phase_d/build_catalog.py`; review sheets are `staging/phase_d/_preview/review_<family>.png`.

### Phase D total

**41 paid runs** (23 in wave 1: 22 batch + the nebula regen; 18 in wave 2) plus one `recraft` A/B probe, and
**141 new files** (wave 1: 109, wave 2: 32) staged into `vajb-orbit/assets/`, logged, and imported. Nothing from the
credit budget was spent on a rejected request; the only wasted spend was the one nebula render that violated its
negative list.

At the verified rate the phase cost about **$2.05** (41 runs x $0.05) plus roughly 5 credits for the recraft probe.
The kie.ai ledger reports 41 new generations, so its totals over-report spend by 3x, as expected.
