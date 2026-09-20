# Vajb Orbit — Icon Set Spec

**Status:** draft 2026-09-17. Palette, wording, and rules copied from `STYLE_BIBLE.md`; state colours and HUD consumption follow `UI_SPEC.md`; menu consumption follows `MAIN_MENU_SPEC.md` (menu buttons are text-only — no icons are consumed there in v1; icon consumers are the HUD and dialogs). Font verdicts and the icon gap come from `docs/assets/research/grimdark_ui_hud.md` (no CC0 icon family exists; icons are generated, flat vector over the fixed style block).

**Total: 20 generated icons** in three generation panels (see §4). The minimap compass rose is deliberately **not** generated: per `UI_SPEC.md` §3.3 the minimap is a custom `_draw()` control, so the compass rose (circle + cardinal ticks + needle) is script-drawn in Burnt Ember/Ash Text and excluded from the panels and the 20 outputs.

## 1. Grid and stroke rules

- All icons are designed on a **16 px grid**; every geometry lands on whole pixels of that grid at 16 px.
- **Stroke weight: 1.5 px-equivalent** at 16 px (3 px at 32 px source scale, 96 px at the 2K panel cell scale). Strokes are uniform across the set; no tapering, no variable-width calligraphy.
- **16 px legibility band (F.2 amendment, 2026-09-18):** the four outline glyphs whose read
  depends on thin outlines — `icon_zoom_plus`, `icon_zoom_minus`, `icon_credits`,
  `icon_shield` — carry a **heavier master weight** so their 16 px cut reads as solid iron
  black instead of grey. Measured after the F.2 pass: stroke 2.5-3.5 px and solid-ink share
  0.42-0.50 at 16 px, against the set's own 1.5 px-equivalent / 0.29 median. A pixel-true
  100 % solid read is unreachable at 16 px under this section — the whole 139-family set
  measures 0.00-0.61 with a 0.29 median — so the band is judged on those two numbers, not on
  "solid black" (`ICONS_SPEC` §9.8, C2b).
- **Corner radius 0** everywhere — hard sci-fi mitred corners, no rounded caps, no rounded joins.
- Icons are **single-colour flat silhouettes with cut-line details** (negative-space cuts define interior detail), generated in Iron Black `#232629` on pure white. All state colouring is applied in-engine by modulate — the generated art never bakes a state colour.
- **State colours (engine-side, from STYLE_BIBLE §2.4):**
  - Inactive / disabled fill: **Ash Text `#8D939B`** (the UI token `text_dim`).
  - Active / focused fill: **Bone Text `#C9CDD2`** (the UI token `text_primary`).
  - **Burnt Ember `#C8461B` — and nothing else — only for danger or armed states** (armed weapon slot, ammo ≤ 10 %, full-cargo alert). Ember Glow `#E8703A` is not used on icons. No second accent colour anywhere; no multicolour icons.

## 2. Icon list — weapons (5)

| File | Subject (one line) | Avoid |
|---|---|---|
| `icon_weapon_laser.png` | A short energy emitter barrel: rectangular housing with a single forward emissive slit and rear cooling fins, shown in right-facing profile. | No beam, no glow, no lens flare, no visible projectile, no rounded muzzle, no crossguard, no second barrel. |
| `icon_weapon_cannon.png` | A stubby mass-driver cannon: thick single barrel on a blocky breech with one underside grip, right-facing profile. | No muzzle flash, no bullet in flight, no rivets, no curvature in the barrel, no scope. |
| `icon_weapon_rocket.png` | A single plain rocket: cylindrical body, pointed nose cone, three small tail fins, horizontal. | No flame trail, no smoke, no explosion, no wings, no window, no rounded nose. |
| `icon_weapon_mine.png` | A naval-style space mine: spiked sphere with a flat top mount, silhouette-dominant. | No blinking light, no chain, no glow halo, no smiley or face, no shadow under the sphere. |
| `icon_weapon_plasma.png` | A containment emitter: circular coil ring around a small rectangular core with two side vents. | No swirling plasma, no energy arcs, no glow ring, no gradient, no lightning bolt. |

## 3. Icon list — cargo and ore (6)

| File | Subject (one line) | Avoid |
|---|---|---|
| `icon_cargo_ore.png` | A raw ore chunk: angular faceted rock with one flat cleaved face, silhouette-dominant. | No sparkle, no crystals shooting light, no gem facets, no pickaxe, no shadow. |
| `icon_cargo_crate.png` | A plain cargo crate: rectangular box with a lid seam and two clamp edges, three-quarter-flat front view. | No rivets, no stencilled text, no hazard stripes, no wood grain, no rounded corners. |
| `icon_cargo_container.png` | An iso-container: long rectangular pod with corner brackets and one central seam line, front view. | No corrugation, no doors ajar, no windows, no stacking, no perspective tilt. |
| `icon_cargo_fuel_cell.png` | A fuel cell canister: vertical cylinder with a capped top valve and a single horizontal band. | No flame, no droplet, no gauge, no glow, no rounded dome cap. |
| `icon_cargo_salvage.png` | A torn hull plate fragment: irregular angular scrap with one sheared edge and two bolt holes. | No skull, no wrench, no treasure chest, no coins, no jagged saw teeth, no blood. |
| `icon_cargo_data_core.png` | A data core: square slab with a central square inset and two corner cut notches. | No circuit traces, no glowing lines, no chip pins, no key symbol, no rounded corners. |

## 4. Icon list — glyphs (9)

| File | Subject (one line) | Avoid |
|---|---|---|
| `icon_gear.png` | Settings gear: eight-tooth cog with a square centre hole, flat top-down view. | No wrench overlay, no double gears, no rounded teeth, no shine, no screwdriver. |
| `icon_close.png` | Close X: two crossing bars of equal length forming a square X. | No circle around it, no rounded stroke ends, no drop shadow, no arrowhead. |
| `icon_zoom_plus.png` | Zoom in: square magnifier outline with a plus built from two crossing bars inside. | No handle shine, no circle lens, no rounded handle, no map behind, no gradient. |
| `icon_zoom_minus.png` | Zoom out: same magnifier outline with a single horizontal bar inside. | No plus remnant, no circle lens, no rounded handle, no eye symbol, no gradient. |
| `icon_credits.png` | Credits symbol: hexagonal coin outline with a plain vertical bar struck through its centre. | No dollar sign, no currency letter, no shine, no stack of coins, no glow. |
| `icon_shield.png` | Shield: flat heater-shield outline with a single vertical centre seam. | No crest, no cross, no wings, no shine, no damage cracks, no rounded base. |
| `icon_hull.png` | Hull integrity: angular ship-hull plate outline with two rivet notches and one crack line. | No heart, no wrench, no ship silhouette, no gauge, no warning triangle. |
| `icon_ammo.png` | Ammo: three parallel vertical cartridge slugs of equal height, flat tips. | No bullets in flight, no magazine, no gun, no flame, no rounded tips, no shell casings. |
| `icon_logout.png` | Logout: door-frame outline with an arrow exiting through its right side. | No power symbol, no padlock, no user figure, no rounded arrow, no keyhole. |

## 5. Generation panels

Three prompt-ready panel images. Each panel prompt = the verbatim contents of `vajb-orbit/assets/style-block.txt`, followed by the panel's flat-vector subject block below and this fixed framing sentence, copied into every panel:

> "flat vector icon sheet, 2x3 grid (icons arranged in two columns and three rows), generous even gaps between icons, plain solid pure white background, no grid lines, no labels, no text, no watermark, isolated objects, no shadows, no glow, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style."

- **Panel 1 — weapons (4+1 in a 2x3 grid):** the five weapon subjects from §2, placed left-to-right, top-to-bottom: laser, cannon, rocket, mine (top two rows) and plasma alone in the third row's first cell; the last cell stays empty. Keep all five icons identical in visual mass; the empty cell is blank white.
- **Panel 2 — cargo (6 in a 2x3 grid):** the six cargo subjects from §3, left-to-right, top-to-bottom: ore, crate, container, fuel cell, salvage, data core.
- **Panel 3 — glyphs (9 in a 3x3 grid):** the nine glyph subjects from §4, left-to-right, top-to-bottom: gear, close, zoom plus, zoom minus, credits, shield, hull, ammo, logout. Framing sentence adjusted to "3x3 grid (three columns and three rows)".

## 6. Generation notes

- Production tool: an image generator driven by the fixed style block file `vajb-orbit/assets/style-block.txt`, prepended verbatim and unchanged to every panel prompt (STYLE_BIBLE §8 prompt rules).
- Style target: **flat vector style** rendered to **PNG, 2K resolution, 1:1 aspect**, one image per panel.
- Post-processing: each panel is **auto-split into individual PNGs** on the panel's grid, then **downscaled to 16 px and 48 px** variants. The 2K panel is the master; the 16 px cut is the HUD/texture-button size (`UI_SPEC.md` §3), the 48 px cut is the weapon-slot cell size (`UI_SPEC.md` §3.2).
- After splitting, engine-side modulate applies the §1 state colours; the generated Iron Black art is the tint source. No state colour exists in any generated file.
- Check every split cut against §1 at 16 px: if the 1.5 px-equivalent stroke breaks up or a mitred corner rounds off when downscaled, thicken the panel source stroke and regenerate — never hand-blur or anti-alias-fix individual icons.

## 7. File naming convention

- All 20 split outputs are snake_case, prefixed `icon_`, under `vajb-orbit/assets/icons/`, suffixed per size as `icon_<name>_16.png` and `icon_<name>_48.png` from the same master cut. Master panel images are `panel_weapons.png`, `panel_cargo.png`, `panel_glyphs.png`.
- The 20 master names (size suffixes omitted):

```
icon_weapon_laser.png      icon_weapon_cannon.png    icon_weapon_rocket.png
icon_weapon_mine.png       icon_weapon_plasma.png
icon_cargo_ore.png         icon_cargo_crate.png      icon_cargo_container.png
icon_cargo_fuel_cell.png   icon_cargo_salvage.png    icon_cargo_data_core.png
icon_gear.png              icon_close.png            icon_zoom_plus.png
icon_zoom_minus.png        icon_credits.png          icon_shield.png
icon_hull.png              icon_ammo.png             icon_logout.png
```

- No other icon names or files are sanctioned. The minimap compass rose (§ preamble) is drawn in code and has no file.
- **Amendment 2026-09-17:** `docs/design/ASSET_EXPANSION_SPEC.md` §5 sanctions three further panels (`panel_equipment.png`, `panel_map_markers.png` and the pickups panel `env/panel_pickups.png`) plus `ui/panel_insignia.png`. Splits from `panel_equipment` and `panel_map_markers` follow §1, §5 and §7 verbatim: `icon_*_16.png` / `icon_*_48.png` under `vajb-orbit/assets/icons/`, tinted engine-side via the existing `tools/derive_icon_tints.gd` derivation. The pickups panel and the insignia panel are painted art, not flat icons, and live under `env/` and `ui/` respectively.

## 8. Amendment 2026-09-18 (Phase F — RPG/economy icon families)

Source of this amendment: `docs/gameplay/16_art_design_brief.md` §P0 and §P2, which
satisfies the "no other icon names or files are sanctioned" rule of §7 for the names
below. Everything in §1, §5 and §7 applies unchanged: flat single-colour iron black
`#232629` silhouettes on pure white, 1.5 px-equivalent strokes, corner radius 0, hard
mitred corners, no glow, no gradient, no shading, **ember `#C8461B` for danger/armed
states only and never baked into a file**, tint applied engine-side. Every split is
exported at 16 px and 48 px; `tools/derive_icon_tints.gd` derives the tint variants
unchanged because every name below is prefixed `icon_` (masters are not tint sources —
only the `_16`/`_48` splits are).

### 8.1 Minerals — 20 ore + 20 ingot glyphs (brief P0)

Two panels, both **5×4 grids with the twenty minerals in 02 §2 tier order**
(reading order: T1 Iron…Aluminium, T2 Titanium…Silver, T3 Gold…Osmium,
T4 Palladium…Krillum):

| Panel | Splits | Read |
|---|---|---|
| `panel_minerals_ore.png` | `icon_mineral_<name>_{16,48}.png` | raw faceted ore chunk — angular rock with one flat cleaved face |
| `panel_minerals_ingot.png` | `icon_ingot_<name>_{16,48}.png` | refined ingot — stamped bar, flat top face with a single strike mark |

`<name>` is the mineral id suffix from 02 §2 (`iron`, `copper`, `chromium`,
`silicon`, `aluminium`, `titanium`, `nickel`, `cobalt`, `tungsten`, `silver`,
`gold`, `platinum`, `neodymium`, `iridium`, `osmium`, `palladium`, `cerulite`,
`emberite`, `voidglass`, `krilium`).

The brief specifies one 5×4 sheet carrying both reads per mineral; the pipeline cuts
it as **two panels of the same twenty minerals in the same tier order** so that each
cell holds exactly one object and the §5 grid cut stays clean (a single sheet would
need 40 objects and a two-objects-per-cell cut, which the splitter in
`staging/phase_d/reprocess.py` cannot isolate). Grid, tier order, output names and
count are as specified; only the panel count differs, and it is recorded in the
per-family `generation_log_phase_f.md`.

Retire the 02 §6 fallback: the four-tier tint table in §8.6 is the v1 fallback until
the mineral glyphs are wired, then it covers ore/container only where a glyph is absent.

### 8.2 Modules — one glyph per 09 §3 module (brief P0)

Twenty-seven new glyphs, `icon_module_<module-id>_{16,48}.png`, drawn from
`docs/gameplay/09_ship_slots_modules.md` §3 with §4.5's mining laser included
(it is a weapon module). Family-grouped across three 3×3 panels, reading order:

| Panel | Splits (in reading order) |
|---|---|
| `panel_modules_a.png` | `icon_module_w_railgun`, `icon_module_w_mining`, `icon_module_s_light`, `icon_module_s_heavy`, `icon_module_s_ion`, `icon_module_h_plate_light`, `icon_module_h_plate_heavy`, `icon_module_h_composite`, `icon_module_p_std` |
| `panel_modules_b.png` | `icon_module_p_mk2`, `icon_module_p_core`, `icon_module_e_std`, `icon_module_e_ion`, `icon_module_e_vector`, `icon_module_b_afterburner`, `icon_module_b_fold`, `icon_module_c_target`, `icon_module_c_scanner` |
| `panel_modules_c.png` | `icon_module_c_twin`, `icon_module_c_ewar`, `icon_module_c_nexus`, `icon_module_u_cargo`, `icon_module_u_salvage`, `icon_module_u_refine`, `icon_module_u_drones`, `icon_module_u_tractor`, `icon_module_u_holds` |

**Coverage note (the brief's "30" resolved):** 09 carries **32 module ids**. Five of the
six §3.1 weapons already have glyphs and are **reused, not regenerated** —
`w_laser` → `icon_weapon_laser`, `w_cannon` → `icon_weapon_cannon`,
`w_rocket` → `icon_weapon_rocket`, `w_mine` → `icon_weapon_mine`,
`w_plasma` → `icon_weapon_plasma` (§2). The remaining 27 are generated here.
No module id lacks a glyph and no id is drawn twice.

### 8.3 Slot types — 8 glyphs (brief P0)

`panel_slots.png`, a 4×2 grid, cuts `icon_slot_<type>_{16,48}.png` in reading order
`engine`, `power`, `w`, `s`, `h`, `c`, `b`, `u`. Subjects are **slot sockets**, not
module art: `engine` a single nozzle block, `power` a reactor core with three coil
bars, `w` a hardpoint mount with two clamp jaws, `s` an arc emitter half-ring,
`h` a three-layer plate stack, `c` a square board with a central node, `b` a chevron
burst vent, `u` an open pod socket with a latch bracket. Slot headers also carry an
engine-side text label; **no letterform is baked into any glyph** (§1.7 of
`UI_CHROME_ASSETS_SPEC.md` is the governing rule for text). The empty-mandatory-slot
warning state (09 §4.1) is the engine's `accent_danger` modulate on the `engine` and
`power` glyphs — per §1 the file ships without ember.

### 8.4 Contracts and services (brief P2)

| Panel | Grid | Splits |
|---|---|---|
| `panel_contracts.png` | 2×3 (one cell blank) | `icon_contract_haul`, `icon_contract_hunt`, `icon_contract_gather`, `icon_contract_escort`, `icon_contract_expedition` |
| `panel_service_glyphs.png` | 2×2 (one cell blank) | `icon_service_vault`, `icon_service_insurance`, `icon_service_bounty` |

Subjects: `haul` a crate on a two-wheel pallet bar, `hunt` a crosshair over a target
chevron, `gather` a claw over a faceted chunk, `escort` two chevrons travelling in
column with a bracket, `expedition` a ring with a single outward arrow;
`vault` a door slab with a three-spoke wheel, `insurance` a shield plate with a
horizontal seam and one rivet notch, `bounty` a coin outline struck through by a
notched band (distinct from `icon_credits`'s hexagonal coin + vertical bar).

### 8.5 Faction insignia — 3 glyphs (brief P2)

`panel_faction_insignia.png`, a 2×2 grid (one cell blank), cuts
`icon_insignia_concord_{16,48}.png`, `icon_insignia_meridian_{16,48}.png`,
`icon_insignia_choir_{16,48}.png` — single-colour, tintable, hex-based emblems per
`docs/gameplay/12_factions.md` §1 identity: Concord a hex plate with three stacked
plate bars (industrial authority), Meridian a hex plate split by a diagonal dock seam
with a docked pod (trade syndicate), Choir a hex plate with a three-tongue radial
flame (reactant cult). No letterforms; no ember. These live under `assets/icons/`
rather than the painted `ui_insignia_*` company-emblem family
(`ASSET_EXPANSION_SPEC.md` §5) precisely so the §7 tint derivation applies to them —
the brief requires the faction insignia to be tintable, and only files under
`assets/icons/` are tint sources.

### 8.6 Cargo glyph tier tint table (brief P2)

Engine-side modulate tints for the 02 §6 / 03 §4.1 ore-and-container fallback. These
are **palette hexes only** (STYLE_BIBLE §2 rule: no intermediate tones are invented);
the accent pair `#C8461B` / `#E8703A` is never used, per §1 and 02 §6.

| Tier | Tint | STYLE_BIBLE name | Rationale |
|---|---|---|---|
| T1 | `#565C63` | Steel Highlight | the neutral steel read |
| T2 | `#8D939B` | Ash Text (re-used as a metal tone) | the palette's brighter steel; "gunmetal-bright" resolved to a sanctioned hex |
| T3 | `#8A6A50` | Dry Rust | ochre |
| T4 | `#6E5B4A` | Rusted Ochre | desaturated ember-adjacent: the warmest palette tone that is not the accent |

Warmth rises monotonically T1 → T4 while the accent stays reserved for danger; T4 is
one step *away* from `#C8461B`, never toward it. The table is applied to
`icon_cargo_ore` and `icon_cargo_container` (and, after the §8.1 swap, to any mineral
whose dedicated glyph is not yet wired); it is a code-side colour map, not a set of
new files.

### 8.7 Phase F non-icon deliverables named by the same brief

| File | Family | Why it is not an icon |
|---|---|---|
| `env_jump_gate_ring.png` | env | painted structure (`ENVIRONMENT_SPEC` material rules), top-down orthographic |
| `env_sector_<id>_bg.png` (7) | env | 2048×1152 opaque 16:9 backdrops |
| `fx_anomaly_shimmer.png`, `fx_anomaly_grave_glow.png`, `fx_anomaly_rift.png` | fx | RGB on void black, additive, never alpha-keyed (`FX_SPEC` §0.1) |
| `env_arena_nav_pylon.png`, `env_arena_barricade.png` | env | painted props |
| `ship_boss_boneyard.png`, `ship_boss_pyre.png` | ships | boss renders (`SHIPS_SPEC` §3.8–3.9) |
| `ship_fighter_concord_*`, `ship_fighter_meridian_*`, `ship_fighter_choir_*` | ships | hunter liveries (`SHIPS_SPEC` §5 amendment) |

The 16 px minimap gate glyph the brief also asks for is **already shipped** as
`icon_map_node_gate_16.png` (`ASSET_EXPANSION_SPEC.md` §5) — a twin-arc gate node cut
at 16 px from `panel_map_markers`. It is reused rather than duplicated, and is
verified on the P1 review sheet.

## 9. Amendment 2026-09-18 (Phase F.1 — resolution standard and integrity fixes)

Source: `docs/gameplay/16_art_design_brief.md` §P0.5; cross-document review
(`docs/gameplay/README.md` review stamp). This section supersedes the **cut-size
language** of §5, §6, §7 and §8 ("16 px and 48 px") everywhere it appears; their
style, grid, naming and tint rules are untouched.

### 9.1 Why

The game renders a 1920×1080 canvas with `canvas_items` stretch, so every texture
scales by physical/logical ratio. Fonts survive any scale because the theme
re-scales them; PNG icons do not. Measured effect on a 48 px cut:

| Screen | Canvas scale | 48 px icon renders at | 48 px source result |
|--------|-------------|-----------------------|---------------------|
| 720p | 0.67× | 32 px | downscale — fine |
| 1080p | 1.0× | 48 px | native — fine |
| 1440p | 1.33× | 64 px | upscaled — soft |
| 4K | 2.0× | 96 px | upscaled 2× — visibly soft |

The UI-scale setting multiplies on top (4K at 1.25× UI scale = 2.5× physical).
The worst supported case is therefore **2.5× physical**.

### 9.2 The cut quartet (production law)

Every split icon family ships **four sizes** from the same retained master:

| Cut | Role |
|-----|------|
| `_16` | micro chips only (pixel-tight HUD spots); the §6 legibility check applies here |
| `_48` | legacy consumers (Phase C/D/E references) — retained, never re-pointed silently |
| `_96` | the default for all new consumers (1:1 at 4K / 2× canvas) |
| `_192` | detail/inspect views and 4K + UI-scale headroom (up to 2.5× physical) |

Naming: `icon_<name>_{16,48,96,192}.png`. The unsuffixed `icon_<name>.png`
**master is retained permanently** — it is the re-cut source for all future sizes
(Phase F already complies; legacy families re-split from the retained 2K panels
`panel_weapons.png`, `panel_cargo.png`, `panel_glyphs.png`, `panel_boosters.png`,
`panel_status.png`).

### 9.3 Cutting and stroke rules

- The 1.5 px-equivalent stroke of §1 maps across cuts as: 9 px at 96, 18 px at 192.
- Cuts are produced by **downscale from the master only** (same splitter, new
  sizes). Never upscale a smaller cut, never hand-fix a cut.
- Verify the chain at **16 px and 96 px**: if the stroke breaks at 16 or the
  silhouette mushes at 96, thicken the master stroke and regenerate the family —
  the §6 rule, unchanged.
- Import settings for `_96` and `_192`: **mipmaps generated, lossless
  compression, 3D detection disabled**, with the project's canvas texture filter
  set to Linear Mipmap (coder owns the project setting via
  `PROJECT_SETTINGS_PATCH.md`; see `17_coder_handoff.md` §2.1).

### 9.4 Integrity fixes required with this pass

1. **`icon_cargo_data_core_16.png` (ASSET_AUDIT C2):** coverage 0.98, silhouette
   touches all four frame edges. Redraw the 16 px read (fewer interior cuts,
   clear margin) and re-cut the quartet from the corrected master.
2. **Outline-weight 16 px glyphs** (`icon_zoom_plus`, `icon_zoom_minus`,
   `icon_credits`, `icon_shield` — `generation_log.md`: ~1.4 px-equivalent strokes
   read as grey, not solid): thicken strokes at the master so the 16 px cut
   thresholds to solid iron black.
3. **White matte fringe (ASSET_AUDIT C3):** 13 files carry a bright near-neutral
   outer alpha band — `ui_insignia_{mic,mmo,neutral,ven}`, `ship_drone_swarm_*`
   (4), `env_outpost_{mining,repair}`, `env_mine`, `env_planet_moon`,
   `env_debris_field`. Re-key or regenerate; acceptance is a clean edge check, no
   hand-patching.
4. **`ui_panel_frame.png` (ASSET_AUDIT C1):** the painted border band is 7 px
   against a 32 px nine-slice margin, so the frame reads ~4.5× too thick and the
   riveted corners crop. Regenerate the frame so the painted band equals the
   margin, and add the `@2x` cut (192×192, 64 px margins) for 4K chrome support.
   Coder wiring of the `@2x` variant is queued with the theme work.
5. **`env_body_ice_moon.png` (ASSET_AUDIT C4, optional):** value is one step
   brighter than the ships family against the STYLE_BIBLE §7.2 rule — fix only
   if a regeneration batch is already scheduled.

All five items are **closed** by the F.2 pass (§9.8). Item 2's acceptance sentence
("thresholds to solid iron black") is unreachable as written, because no anti-aliased cut
under §1 can be 100 % solid at 16 px; §9.8 reformulates it into two measured numbers and §1
gains the 16 px legibility band clause above.

### 9.5 Out of scope for this amendment

Audio anomalies (`ASSET_AUDIT` C7–C9), outpost footprint (C6) and the env-family
value mean (C5) are separate work orders, not icon-resolution issues.

### 9.6 Cut geometry — the aspect law (F.1 amendment, 2026-09-18)

§9.3's "downscale from the master only" is kept; the geometry of that downscale is
now fixed as **aspect-preserving contain-fit**, which supersedes the "same
splitter, new sizes" reading of the geometry half of §9.3:

- A cut is an `N`×`N` frame in which the trimmed master is scaled until its
  **longest** side equals `N`, centred, the remainder transparent. No axis is ever
  stretched, and all four tiers come from the same master by the same rule.
- Measured reason: the Phase F/D/E pipeline cut with `trim(alpha bbox)` →
  `Image.resize((N, N))`, which stretches a non-square bbox into a square.
  `icon_module_w_railgun` (master 644×242) shipped a 48 px cut whose ink bbox is
  48×45 — the glyph is compressed 2.6× along its long axis; 9 of the 119
  master-backed families exceed 1.6× of distortion and 24 exceed 1.35×. The 20 §7
  families already complied, because their splitter kept aspect
  (`icon_weapon_laser_48.png` has an ink bbox of 48×18 from a 778×281 source).
- F.1 re-cut all four tiers for the 119 master-backed families and added
  `_96`/`_192` for the 20 §7 families (re-split from the retained 2K panels). The
  pre-F.1 geometry is reproducible byte-for-byte with
  `staging/phase_f/recut_quartet.py --fit square`, so no regeneration is needed to
  reverse it.
- Chrome keeps its own geometry rules; its `@2x` cuts are
  `UI_CHROME_ASSETS_SPEC.md` §10.

### 9.7 F.1 execution record (2026-09-18)

Work order: `DESIGNER_TODO.MD` (root). Owner-approved: contain-fit geometry for all
four tiers, three regeneration runs for C1/C2/C2b, and the optional C4 ice moon.
Spend: **4 runs = $0.20** (10 credits = $0.05 per 2K run). Drivers:
`staging/phase_f/recut_quartet.py`, `chrome_2x.py`, `apply_import_settings.py`,
`rekey_halo.py`, `build_f1_review.py`, plus `staging/phase_d/defringe_edges.py`.

**Stage 0 — reconciliation.** All 461 staged consumer files were already moved,
imported and catalogued (0 missing). Retained re-cut sources: 119 per-icon masters in
`assets/icons/` + the five 2K panels.

**Stage 1 — the quartet.** 139 families × 4 tiers = 556 files: 278 new `_96`/`_192`
cuts, 278 existing cuts re-cut contain-fit. Longest ink axis per band: `_16`
13-16 px, `_48` 46-48, `_96` 90-96, `_192` 180-192 (the residue is the master's
10 px trim pad); all 556 rows measured clean in
`staging/phase_f/_preview/review_f1_table.txt`, sheets
`review_f1_quartet_<group>.png`, 4K composite `review_f1_4k.png`. The tint stencil set
grew 278 → 556 (`tools/derive_icon_tints.gd`, glob now `_{16,48,96,192}`).

**Stage 2 — integrity.**

| Item | Outcome |
|---|---|
| C2 data core | **met.** Master regenerated (906×901, job `a7fa1181…`); the 16 px ink coverage fell 0.98 → 0.50 and the silhouette is now a hollow outline instead of a solid square (peers: ore 0.62, hull 0.47) |
| C2b outline glyphs | **not met, evidence recorded.** The regenerated glyphs comply with §1 (measured 1.67 px-equivalent stroke at 16 px), so they still read partial-alpha at 16 px: solid-ink share 31.4 → 20.4 % (zoom_plus), 15.6 → 14.2 % (credits). The §1 base stroke (1.5 px-equivalent) and the C2b acceptance ("16 px thresholds to solid iron black") contradict each other: no master that obeys §1 can satisfy C2b. Options: amend §1 to a heavy-stroke 16 px band (1 run per sheet), or accept that `_16` is the micro-chip band and judge glyph legibility at `_48`+. Sheet-level prompt fix already applied (`ICON_OVERRIDE`'s stroke sentence is what the model follows) |
| C3 white fringe (13 files) | **band fixed, 9 files carry content-level white.** Band RGB defringed (`defringe_edges.py --apply`, 299 331 edge pixels) and, for the 9 whose skirt defeats it, luminance re-keyed (`rekey_halo.py`, alpha × ink fraction at a fixed 76-luminance reference). Measured outer-band mean luminance before → after: insignia 174-180 → 14-20; drone swarms 217-225 → 139-158; outposts 188-215 → 70-140; `env_mine` 200 → 100; `env_planet_moon` 202 → 134; `env_debris_field` 142 → 42 (`qc_f1.py fringe`). Verdicts: **4 PASS** (the insignia, ≤ 24 stray bright pixels of ~6 500 = 0.37 %), **6 CONTENT** (the residual bright edge pixels are 85-96 % *fully opaque*, i.e. subject): the four `ship_drone_swarm_*` (model-rendered white shards, 99 components, largest 252 px - an artifact, regeneration estimate **1 run = $0.05** for the whole rotation sheet), `env_outpost_repair`, `env_mine`, `env_debris_field` (bright surface detail, where removal would delete content), **2 residual band** (`env_outpost_mining`, `env_planet_moon`: a semi-transparent bright rim survives, both improved > 30 % in mean band luminance) |
| C1 panel frame | **partially met.** Regenerated (job `8f1c2499…`): painted band 7 → **15 px** at 96 (profile at x = 48: 66,72,74 → 39,42,45 → interior at y = 16) and 30 px at 192, so the frame now reads ~2× too thick instead of ~4.5×. The prompt asked for exactly one third; the model delivered 15.6 %. The corner rivet detail sits within 12 px of the corner, so a **16 px nine-slice margin (32 px on the `@2x`)** satisfies the "band equals margin, rivets uncropped" intent for free — `tools/build_theme.gd`'s `PANEL_FRAME_MARGIN` and `vajb_theme.tres` still say 32, and no scene consumes `PanelRaised` yet, so the margin decision can land with the station hub. Alternative: one more run to force 32 px |
| C4 ice moon | **improved, one bar short.** Regenerated (job `2277ee06…`): mean subject luminance 91.0 → **58.7** (p95 195.3 → 144.3), against a ships-family mean of 54.3 — 36 % darker, still just above the family mean |

**Stage 3 — chrome `@2x`.** 14 of 18 chrome families cut at 2× from the retained 2K
sources, each proven by re-running the original G6 chain at 1× and comparing with the
shipped file: the 12 slot plates, the minimap bezel and the bar caps reproduce byte
for byte (bar caps within 3 levels on seam pixels), so their `@2x` is the same art at
2×. The four `ui_button_plate_*` are **blocked**: no retained source reproduces them
(mean absolute channel error 26-32, worst 255, alpha mean 218 shipped against 246 for
the same source resized — a post-resize keying step whose recipe is not recorded).
Regeneration estimate: **1 run = $0.05** for a 2×2 plate panel at 1120×224. No spend
without approval. Evidence: `staging/phase_f/chrome_2x_report.json`.

**Stage 4 — import facts.** 571 `.import` files (278 icon quartet cuts, 278 tint
stencils of those bands, 15 chrome `@2x`) set to `mipmaps/generate=true`,
`compress/mode=0` (lossless), `detect_3d/compress_to=0`, then reimported by a headless
`--editor --quit` pass (rc 0). **Outstanding:** the project's canvas texture filter is
still the default Linear, not Linear Mipmap, so the generated mips are not sampled yet
- that is the coder's item per §9.3 and `17_coder_handoff.md` §2.1.

**Retained sources and reversal.** Masters are never deleted: per-icon
`assets/icons/icon_<name>.png`, the five 2K panels, the trimmed chrome master
`staging/phase_f/ui/ui_panel_frame-master.png`, and the pre-F.1 cuts of every family in
`staging/phase_f/_cut_backup/`. `recut_quartet.py --fit square` restores the pre-F.1
geometry byte for byte; `_rekey_backup/` and `_fringe_backup/` hold the pre-C3 sprites.

### 9.8 F.2 execution record (2026-09-18)

Second and final pass on `DESIGNER_TODO.MD`, after F.1 (§9.7): the four items F.1 left open
plus the four `ui_button_plate_*` `@2x` cuts that §10 of `UI_CHROME_ASSETS_SPEC.md` had
blocked. Owner-approved batch: **five runs = $0.25** (10 credits = $0.05 per 2K run).

Drivers: `staging/phase_f/wave_f.py` (the five `f2_*` runs), `reband_frame.py` (C1 band),
`thicken_master.py` (C2b weight), `silhouette_clean.py` (C3 needles), `plates_cut.py`
(chrome), `qc_f2.py` (every number below), reusing F.1's `recut_quartet.py`,
`apply_import_settings.py` and `staging/phase_d/defringe_edges.py`. Pre-regeneration bytes
sit in `staging/phase_f/_f2_backup/` (32 files; the first copy wins, so a re-run cannot
overwrite the true originals).

| Item | Outcome (`qc_f2.py`, before → after) |
|---|---|
| C1 panel frame | **met.** Painted band of a drawn nine-patch panel 12/13 px → **30/32 px** at 96 (margin 32) and 25/25 → **59/64** at 192 (margin 64) |
| C2b outline glyphs | **met**, with the acceptance reformulated into numbers: stroke 1-2 → **2.5-3.5 px** and solid-ink share 0.14-0.22 → **0.42-0.50** at 16 px (set median 0.29, §1) |
| C3 drone swarm | **met.** Outer band mean luminance 139-158 → **49.7-58.2**, bright pixels 822-1103 → **0-33** of ~5 500 band px; all four views PASS (`qc_f1.py fringe`) |
| C4 ice moon | **met.** Subject mean luminance 58.0 (ships family mean 56.2) → **49.6**, p95 144.2 → 113.6 |
| Chrome plates | **unblocked.** `ui_button_plate_{normal,hover,pressed,disabled}@2x.png` (560×112) cut, each with its 1× from the same cell (same-art diff ≤ **0.44** levels) |

**C1 — the band now equals the margin, by construction.** Both F.1 and F.2 asked the model
for a band of "exactly one third" and got 12-16 % back, so the F.2 run (job `9f67a39b…`, a
1612×1614 master with the rivet corners intact) is only half the fix:
`reband_frame.py` measures the master's painted band (304 px, edges within 6.9 %) and rebuilds
the nine-slice as 3×3 tiles of exactly `size/3` — corner tiles from the master's corner
squares, edge tiles from the straight band runs, centre from the interior opening. The band
therefore equals the margin whatever the model draws, and the corner rivets scale with the
band instead of being stretched by it. Accepted residue: 30 of 32 px at 96 and 59 of 64 at
192, the difference being the art's own near-black inner catch line. **No theme change is
needed**: the spec's original 32 px margin is correct for the 1× and 64 px for the `@2x`
(`tools/build_theme.gd` `PANEL_FRAME_MARGIN` stays 32; the `@2x` variant the coder adds takes
64).

**C2b — the heavy band, measured.** F.2 regenerated the four glyphs with a deliberately
chunky prompt (job `40396362…`) and the model answered with 2 px-equivalent strokes, still
under the bar. `thicken_master.py` then applied the Stage 1 rule literally — *thicken at the
master, never fix a cut*: a greyscale alpha dilation (disk radius 10-23 px at master scale,
RGB taken from the nearest ink pixel so the flat iron black is untouched) until the measured
stroke at 16 px reached 2.5 px, refusing any radius that would close the glyph's negative
space below a 4×4 opening (16 px) or push ink coverage past 0.85, which is C2's
solid-block bar. Result: solid-ink share 0.42-0.50 at 16 px against the 139-family median of
0.29, with the enclosed hole intact (16-28 px). §1 gains the "16 px legibility band" clause
that authorises this heavier weight, and §9.4's literal "solid iron black" is retired: the
whole set measures 0.00-0.61 at 16 px, so no cut under §1 can be 100 % solid.

**C3 — the needles were a colour defect, not a silhouette defect.** The regenerated rotation
sheet (job `a882721c…`) removed the pale rim light the prompt named but still rendered
near-white needles on the shard hull's silhouette — they are one connected component with the
hull, so a component filter cannot see them, and `defringe_edges.py` cannot fix them either
(the nearest opaque pixel to a needle is the needle). `silhouette_clean.py` recolours every
near-neutral pale pixel to the RGB of its nearest dark hull pixel (exact EDT, alpha untouched,
ember-adjacent pixels protected so the engine flare survives) and the defringe pass then
resolves the soft band against the now-dark needles. The shard silhouette is preserved and
back in palette: the brightest value anywhere on the hull is steel highlight `#565C63`.

**C4 — ice moon.** One run (job `1678960300…`) at three value steps instead of two lands the
subject mean below the ships family mean for the first time.

**Chrome plates — the §10 blocked family.** The four `ui_button_plate_*` had no retained
source that reproduces them, so one run (job `fedb0cff…`) redrew the 2×2 plate panel and
`plates_cut.py` cut **both** boxes from the same cell by the same rule: the logical 280×56 and
the 560×112 `@2x`, four states, each pair proving itself numerically (the `@2x` downscaled to
the logical box differs from the 1× by ≤ 0.44 levels). §10's same-art law therefore holds for
the pair. Consequence to be aware of: the shipped 1× plates are a new generation and read
**darker and flatter** than the F.1 set, which was glossier than `STYLE_BIBLE.md` §2 permits —
if the previous look is preferred, restore only the four 1× files from `_f2_backup/` and
accept a mismatched pair, or revert this item and leave the plates blocked.

**Import facts.** 51 changed files were reimported. The editor's filesystem cache had already
recorded the new mtimes without importing, so a plain scan or reimport marked them current
while the `.ctex` stayed stale; the fix was to touch the 51 sources and run a headless
`--import` pass, after which an audit of all **1445** imported assets found 0 stale and 0
missing. The four new plate `@2x` files were imported by the same pass (they are the only
files in this batch that had no `.import` entry before it); they then took the same import
settings as every other `@2x` cut — mipmaps on, lossless, 3D detection off — through
`apply_import_settings.py` plus one more (`touch`, then headless `--import`) round, because the
editor refuses writes while a game plays. Final audit across icons, tints, ui, ships, env, fx
and audio: **2261 imported assets, 0 stale**. The project boots headless with zero error lines
and the running game loads every F.2 texture at its documented size (verified through
`game_eval`). The project's canvas texture
filter is still Linear rather than Linear Mipmap, so the mip chains are generated but not
sampled yet — that remains the coder's item (§9.3, `17_coder_handoff.md` §2.1).

**Retained sources and reversal.** `_f2_backup/` holds the pre-F.2 shipped bytes (including
the pre-thicken glyph masters as `staging__icons__*.png`) and `staging__ui__ui_panel_frame-master.png`.
The F.2 six-run provenance stays in staging: `ui/` (the trimmed frame master, the four plate
cell masters `ui_button_plate_*-master.png`, the rebanded cuts), `icons/` (the F.2 glyph
masters), `ships/20260918-133108/` (the raw rotation sheet). The raw (pre-defringe) drone cuts
are reproducible with `wave_f.py f2_drone_swarm --post-only`, the post-defringe state is in
`staging/phase_d/_fringe_backup/`, the needled-pre-recolour state is gone by design (it was the
defect), the tint stencils regenerate with `tools/derive_icon_tints.gd`, and the pre-thicken
glyph masters are in `_f2_backup/`. `DESIGNER_TODO.MD` is closed and carries a status header;
every stage of it is executed.
