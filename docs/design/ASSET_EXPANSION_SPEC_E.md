# Vajb Orbit — Asset Expansion Spec (Phase E)

**Status:** approved 2026-09-17 by user (go with the 1–4 ranked suggestions, expanded: space bases ×4 variants, outposts in a few variants each). Budget: user added **1000 kie.ai credits**; planned 17 runs at 10 credits / $0.05 per 2K run ≈ **$0.85** plus retries. The script's printed 30-credit estimate is the stale hint (`usage-ledger.jsonl` over-reports 3×; the kie.ai console is authoritative).

**Model:** `gpt-image-2-5-flare-text-to-image` (`flare`), fallback `sunburst`, edits `flare-i2i`.

**Predecessor:** `ASSET_EXPANSION_SPEC.md` (Phase D). Palette, lighting, weathering vocabulary and framing come from `STYLE_BIBLE.md`; every run passes a style block via `--style-file`.

---

## 1. Spec amendments this document makes

| Amends | Change |
|---|---|
| `ENVIRONMENT_SPEC.md` §6 | New POI classes: **bases** (station-scale structures) and **outposts** (smaller platforms). Both follow §1 material rules and the station-lamp emissive exception (burnt ember `#C8461B` lamps only, contained, no bloom). |
| `ENVIRONMENT_SPEC.md` §9 | Airless body additions are permitted: ice moon, ore-scarred moon, shattered moon, and one **background body plate** (huge airless limb at the frame edge, one value step darker than ships, no atmosphere, no clouds, no terminator glow, no emissive). No new emissive anywhere except station/gate lamps. |
| `ICONS_SPEC.md` §7 | Two more panels are sanctioned: `panel_boosters` (2×3) and `panel_status` (3×3), split and downscaled exactly like the Phase D painted panels. As with §11.2 of the Phase D spec, painted output is the accepted reality (the style block outweighs the flat-vector override) and ships without tint derivation. |
| Phase D §7 | `env_mine` (deployed mine, world object) joins the environment set; `env_asteroid_b1..b6` is a second rock-look set for map variety. |

---

## 2. Generation rules (all runs)

1. **Prompt shape:** style block via `--style-file` + the subject block from this document + the family negative list (`staging/phase_e/wave_e.py` carries the exact text).
2. **Resolution:** 2K; single objects and panels `--aspect 1:1`, the background body plate `--aspect 16:9` (a non-`auto` aspect is mandatory at 2K).
3. **Transparency — the A/B this phase runs.** Phase D proved `--transparent` alone loses to the style block's void-background sentence. Phase E spends 2 runs on a controlled test:
   - run `base_mining` — control: standard `style-block.txt`, `--transparent`;
   - run `base_mining_alpha` — variant: `staging/phase_e/style-block-alpha.txt` (identical block, but the background sentence requests a fully transparent background where an isolated sprite is requested, and keeps the void language only for full scenes), `--transparent`.
   - **Decision rule:** if the variant returns native alpha (RGBA, >10 % alpha-0 coverage) without breaking the painted style, the variant becomes the style file for every Phase E sprite run; otherwise the standard block stays and the local matte pipeline (`staging/phase_d/reprocess.py`) remains the alpha source, exactly as in Phase D §11.1. The outcome is recorded in §11.
4. **Fallback alpha:** `reprocess.matte` (border-ring median background, threshold 16, 7×7 median, speck removal) then trim; FX-free sprites only.
5. **Splitting:** panels are cut either by component or by grid (`grid_split`) when a cell contains disconnected shapes; the driver tries components first and falls back to grid on a cell-count mismatch.
6. **Naming:** snake_case, family-prefixed as in §3–§7. Panels keep the painted master next to the splits; icon splits ship at 16 px and 48 px.
7. **Staging:** all output lands in `staging/phase_e/<family>/` and moves into `vajb-orbit/assets/<family>/` after the wave, followed by one editor reimport.
8. **Logging:** per-family `generation_log_phase_e.md` (date, model, job id, final files, full prompt, status); run folders keep `job.json`. AI art is not CC0 (`AGENTS.md`).

---

## 3. Space bases (wave 1, 4 runs + 1 A/B twin)

Single centred renders, 1:1, top-down orthographic, structure at ~60 % frame width, station-scale (visibly larger than every outpost), ember warning lamps only.

| File | Role | Silhouette read | Class markers |
|---|---|---|---|
| `env_base_mining` | Mining base (the reference station archetype) | drum-shaped ore silos in a row around a central crusher derrick, conveyor arms reaching out, clamp legs for mooring against a rock | silo row + crusher derrick dominate; no weapon batteries |
| `env_base_trade` | Trade / refinery base | wide docking ring with mooring arms on both sides, cargo transfer cranes over a central plaza deck, fuel cells at the rim | docking ring + crane gantries; no ore silos |
| `env_base_defense` | Defense fortress | layered casemates stacked in a terraced pyramid, a row of heavy gun batteries along the top terrace, sensor masts | terrace stack + battery row; no cranes, no silos |
| `env_base_shipyard` | Shipyard / drydock | open construction cradle between two gantry towers, empty scaffolding where a hull would sit (no ship in frame), tug rails along the spine | the empty cradle is the read; no finished ship, no cranes over a hull |

## 4. Outposts (wave 1, 4 runs)

Single centred renders, 1:1, clearly smaller than a base (about half the footprint), one distinctive silhouette each, same weathering palette.

| File | Role | Silhouette read | Emissive |
|---|---|---|---|
| `env_outpost_mining` | Mining outpost | compact rock-anchored rig: a drill tower on a platform with two clamp arms biting into a small asteroid chunk beneath it and one small ore hopper | one ember lamp |
| `env_outpost_defense` | Defense outpost | squat armoured drum with two stacked gun turrets and a segmented, slightly raised shield-plate collar | two ember lamps |
| `env_outpost_relay` | Comms relay | tall thin mast on a small cross-braced platform, three dish antennas at different heights, blinking-position lamp at the top | one ember lamp at the mast top |
| `env_outpost_repair` | Repair post | open docking cradle with two articulated clamp arms and a tool rack, a small hangar front with a dark aperture, hazard-striped landing pad | two ember lamps, no warm glow from the aperture |

## 5. Bodies (wave 2, 4 runs)

Airless only, per `ENVIRONMENT_SPEC.md` §9 as amended; one value step darker than ships; no clouds, no terminator glow, no emissive.

| File | Aspect | Subject |
|---|---|---|
| `env_body_ice_moon` | 1:1 | pale desaturated ice-crusted moon, cracked crust with frost speckle catching the cold steel rim, cratered, no blue tint, no atmosphere |
| `env_body_ore_moon` | 1:1 | mining-scarred moon with open-cast pits, rusted-ochre ore seams (non-emissive) in the cracks, spoil ridges around the pits |
| `env_body_shattered` | 1:1 | fractured moon held in a loose ring of shattered chunks, deep dark fissures, no glow, chunks separated for readability |
| `env_bg_body_plate` | 16:9 | huge airless body limb entering from one frame edge, extremely low contrast, limb only, no surface detail centre-frame, no atmosphere rim, no stars baked |

## 6. Booster and status icons (wave 2, 2 runs)

Painted panels on pure white, keyed and split like Phase D §11.2; masters kept, 16/48 px splits ship, no tint derivation.

| Panel | Grid | Subjects (reading order) |
|---|---|---|
| `panel_boosters` | 2×3 | `icon_booster_speed` (twin vent pod with stacked chevron vents), `icon_booster_damage` (squared amplifier block with a barbed emitter stud), `icon_booster_shield` (field emitter with a segmented collar), `icon_booster_repair` (repair bot: compact rounded drone with two tool arms, no face), `icon_booster_emp` (emp charge: capped cylinder with radiating stub antennas), `icon_booster_teleport` (jump beacon: tripod beacon with a ring aperture, small ember lamp) |
| `panel_status` | 3×3 | `icon_status_burning` (ember flame biting a plate corner), `icon_status_slowed` (chevron chain dragging a weight), `icon_status_disabled` (cracked bolt inside a hex), `icon_status_shielded` (steel highlight dome over a plate), `icon_status_repairing` (steel wrench-and-plate mark over a small pulse ring), `icon_status_locked` (targeting bracket around a hex core), `icon_status_cloaked` (shimmer outline with a missing middle), `icon_status_radiated` (hazard starburst inside a ring), `icon_status_drained` (battery outline with a hollow centre) |

## 7. Map variety (wave 2, 2 runs)

| File | Mode | Subject |
|---|---|---|
| `env_asteroid_b1..b6` (panel `panel_asteroids_b`, 3×2) | white panel | second rock-look set: b1–b2 large, b3–b4 medium, b5–b6 small; different shapes than the Phase B nine (elongated, twin-lobed, heavily pitted, ore-flecked, flat-shard, rubble-cluster), same material rules, no emissive |
| `env_mine` | single trim | deployed-space-mine world object: spiked spherical mine, iron black body, riveted seam ring, four stub detonator caps, one small burnt ember lamp |

---

## 8. Wave tables

### Wave 1 — 9 runs

| Run | Output | Runs |
|---|---|---|
| 1–2 | `env_base_mining` A/B pair (control vs alpha-variant) | 2 |
| 3–5 | `env_base_trade`, `env_base_defense`, `env_base_shipyard` | 3 |
| 6–9 | `env_outpost_mining`, `env_outpost_defense`, `env_outpost_relay`, `env_outpost_repair` | 4 |

### Wave 2 — 8 runs

| Run | Output | Runs |
|---|---|---|
| 10–13 | `env_body_ice_moon`, `env_body_ore_moon`, `env_body_shattered`, `env_bg_body_plate` | 4 |
| 14–15 | `panel_boosters`, `panel_status` | 2 |
| 16–17 | `panel_asteroids_b`, `env_mine` | 2 |

---

## 9. Acceptance checklist

- [ ] Every sprite ships as RGBA with a real alpha channel (native if the A/B won, else local matte); no opaque void rectangle.
- [ ] Bases read station-scale and mutually distinct by silhouette at 16 % zoom; outposts read clearly smaller than bases.
- [ ] Bodies: airless only, no clouds/no terminator glow/no emissive; one value step darker than ships.
- [ ] Panel splits cut on empty margins; 16 px cuts legible; masters kept.
- [ ] Exactly one accent (ember) in every file; no new palette hex.
- [ ] Per-family `generation_log_phase_e.md` complete; run folders keep `job.json`.
- [ ] Files moved into `vajb-orbit/assets/<family>/`, reimported, and `docs/design/ASSET_CATALOG.md` regenerated.

## 10. Open items

- Damaged/ruined variants of the new bases and outposts (a follow-up wave if wanted; `env_station_ruined` is the only ruined structure today).
- Second livery pass (MIC/VEN) for hulls, parked from Phase D.
- Audio remains the largest uncovered asset family (separate pipeline decision; not in this spec).

## 11. Results (filled after execution)

### 11.1 Transparency A/B verdict (2026-09-17) — native alpha is not available

Two runs of the same mining-base subject, both with `--transparent`:

| | control `base_mining` | variant `base_mining_alpha` |
|---|---|---|
| style block | `style-block.txt` | `style-block-alpha.txt` (background sentence requests transparent) |
| master returned | **RGB, opaque** | **RGB, opaque** |
| estimated background | `#04090F` (void) | `#F6F6F6` (near **white**) |
| keying | local matte, clean edges | local matte; visible white speckle fringe along the silhouette |
| final look | darker, matches the one-value-step rule | brighter (white bounce light), off the value rule |

**Verdict:** kie.ai's flare endpoint still returns an opaque PNG; the `background=transparent`
parameter is accepted but not honoured. Worse, the variant style block translates "transparent"
into a *painted white canvas*, which both lightens the subject and re-introduces the exact white
fringe class removed from the Phase B sprites this session. **The standard block plus the local
matte (`staging/phase_d/reprocess.py`) remains the production path**; the variant run is kept only
as the record of this verdict. Every Phase E sprite run therefore uses `style-block.txt`.

### 11.2 Wave 1 results — bases and outposts (9 runs)

All nine runs succeeded on the first attempt (27-40 s each). Delivered `env_base_mining` (A/B
control kept; the variant render discarded), `env_base_trade`, `env_base_defense`,
`env_base_shipyard`, and `env_outpost_mining`, `env_outpost_defense`, `env_outpost_relay`,
`env_outpost_repair`. All are trimmed RGBA sprites keyed by the local matte (white-edge check: 0
fringe pixels per file). The four bases read station-scale and mutually distinct (silo row,
docking ring, terraced fortress, gantry cradle); outposts stay clearly smaller, with the relay
mast the thinnest silhouette in the set. No regeneration was needed.

### 11.3 Wave 2 results — bodies, icons, map variety (8 runs)

All eight runs succeeded on the first attempt. Delivered `env_body_ice_moon`,
`env_body_ore_moon`, `env_body_shattered`, `env_bg_body_plate` (16:9, RGB), `panel_boosters`
(2x3), `panel_status` (3x3), `panel_asteroids_b` (3x2) and `env_mine`.

Recorded deviations:

- **`--strip-bg local` does not key the icon panels.** The panels render on an off-white
  background (`#F6F6F6`-range) that the script's white keying misses, so all three panels were
  re-matted and re-split locally in a `--post-only` pass (free, no new submissions; this matches
  how Phase D panels were actually finalised). The two icon panels needed the grid fallback
  (`icon_status` component-split into 10 pieces), the asteroid panel component-split cleanly and
  its reading order matches the spec (b1 cigar, b2 twin-lobed, b3 pitted, b4 ore-flecked,
  b5 flat shard, b6 rubble cluster).
- Painted output remains the reality for icon panels (same as Phase D §11.2): no tint derivation
  for the 15 new icon names; masters kept (`panel_boosters.png`, `panel_status.png`,
  `panel_asteroids_b.png`).

### 11.4 Phase E total

**17 paid runs** (16 subjects + the A/B twin) ≈ **$0.85** at the verified rate; zero failures,
zero regenerations, zero rejected submissions. **67 new files** (env 20, icons 47) moved into
`vajb-orbit/assets/`, logged per family, imported by the live editor, and indexed by the
regenerated `docs/design/ASSET_CATALOG.md` (317 files total: 109 B / 141 D / 67 E).

### 11.5 Sign-off and closeout (2026-09-17)

**User review: approved, no regenerations requested.** The labelled sheets in
`staging/phase_d/_preview/` (`review_env.png`, `review_icons.png`, `review_ships.png`,
`review_ui.png`, `review_fx.png`) were reviewed and accepted, which closes Phase E with zero
revision spend. Phase E therefore stands at 17 paid runs / $0.85 / 67 files, unchanged.

The remaining Phase E work is not generation but **binding**: nothing under
`vajb-orbit/assets/` is referenced by game code yet except the Phase B/C subset already wired by
Phase C. That contract now lives in `docs/design/ASSET_WIRING_HANDOFF.md`, which covers the whole
shipped library (Phases B/D/E plus the audio family added in the same pass) and is the document
the Phase C agent should read before touching asset paths.
