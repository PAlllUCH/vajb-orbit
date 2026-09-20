# Vajb Orbit — icon generation log (G3)

Batch: G3 icons (ICONS_SPEC §2–§7, GENERATION_PLAN batch table).
Tool: `C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts/kie_generate.py`.
Model: `flare` = `gpt-image-2-5-flare-text-to-image` (GENERATION_PLAN primary). Aspect 1:1, resolution 2K, `--strip-bg local --split`.
Real price: $0.05 per 2K run (kie.ai console basis). The script's printed $0.15 / 30-credit estimate is the stale hint documented in GENERATION_PLAN and was ignored.
AI-generated art is not CC0 (AGENTS.md): keep this log with the assets.

## Run summary

| Panel | Ran at | Task id (job.json) | Run folder | Assets cut | Status |
|---|---|---|---|---|---|
| `panel_weapons` (superseded) | 2026-09-17 18:31:09 | `d073d56d53ac222edaf3694c4d7ebfed` | `20260917-183109/` | 5 | rejected (painted-metal style, see Notes 1) |
| `panel_weapons` | 2026-09-17 18:32:45 | `fc9fc1465f203a3b56c48f98792f0b7c` | `20260917-183245/` | 5 | accepted |
| `panel_cargo` | 2026-09-17 18:34:46 | `04e356b4b7f8c74d2fdd3a5fcf4f3dcd` | `20260917-183446/` | 6 | accepted |
| `panel_glyphs` | 2026-09-17 18:37:22 | `65a81be9653c5ac502644e75ea8466e2` | `20260917-183722/` | 11 | accepted (fragment mapping in Notes 3) |

No run failed at the API level, so no `sunburst` retry was required. One sheet was regenerated on `flare` for style (Notes 1); its raw files are retained as provenance only.

## Prompt construction (all three panels)

`SUBJECT` = verbatim `vajb-orbit/assets/style-block.txt` text, then the panel's flat-vector subject block (each spec subject plus its `Avoid` list, in panel order), then the ICONS_SPEC §5 framing sentence verbatim (panel 3 uses the spec's adjusted "3x3 grid (three columns and three rows)" form). The style block was carried inside `--prompt` rather than through `--style-file` — see Notes 1.

Every subject block also states: "Render this as a flat vector icon sheet and not as painted metal: every icon is a solid single-colour iron black #232629 silhouette with clean uniform strokes on a plain solid pure white background, with no weathering, no rust, no scratches, no rim light, no film grain, no shading, no gloss, no glow, no ember highlights, no stars and no dark background", followed by the panel's row-by-row cell layout.

### SUBJECT — panel_weapons (accepted run)

grimdark painted sci-fi, semi-realistic weathered metal, harsh directional rim light from upper-left with a thin cold pale steel rim tracing shadow-side silhouettes, subtle film grain over the whole image, top-down orthographic view. Fixed palette: gunmetal mid #3A3F46, gunmetal dark #2B2F35, iron black #232629, steel highlight #565C63, rusted ochre #6E5B4A, dry rust #8A6A50, grimy umber #4A423B, void black #0A0E14, deep void blue #111823, void haze #1A2230, burnt ember #C8461B, ember glow #E8703A, panel black #15181D, panel steel #2A2E35, ash text #8D939B, bone text #C9CDD2. Metal colour is desaturated gunmetal and rusted steel, dark and tired, with scratches, oil stains, hull grime, rust streaks, pitted metal, scorch marks and battle damage. Glow colours are burnt ember #C8461B and ember glow #E8703A only, small and hot, used exclusively for engines, weapons and warning lights; no other glow or accent colour exists anywhere in the image. Backgrounds are near-black blue void, void black #0A0E14 to deep void blue #111823, sparse faint stars, desaturated throughout, no saturated colours, no chrome, no neon, no gloss, no clean surfaces, moody and menacing.

flat vector icon sheet for a dark sci-fi spaceship interface, five weapon icons on a 2x3 grid of two columns and three rows, arranged left to right and top to bottom. Render this as a flat vector icon sheet and not as painted metal: every icon is a solid single-colour iron black #232629 silhouette with clean uniform strokes on a plain solid pure white background, with no weathering, no rust, no scratches, no rim light, no film grain, no shading, no gloss, no glow, no ember highlights, no stars and no dark background. Row one: laser icon in the left cell, cannon icon in the right cell. Row two: rocket icon in the left cell, mine icon in the right cell. Row three: plasma emitter icon in the left cell, and the right cell stays empty plain pure white. All five icons have identical visual mass and generous even gaps between them. Icon one, laser in right-facing profile: a short energy emitter barrel, rectangular housing with a single forward emissive slit and rear cooling fins. No beam, no glow, no lens flare, no visible projectile, no rounded muzzle, no crossguard, no second barrel. Icon two, cannon in right-facing profile: a stubby mass-driver cannon, thick single barrel on a blocky breech with one underside grip. No muzzle flash, no bullet in flight, no rivets, no curvature in the barrel, no scope. Icon three, rocket horizontal: a single plain rocket, cylindrical body, pointed nose cone, three small tail fins. No flame trail, no smoke, no explosion, no wings, no window, no rounded nose. Icon four, mine: a naval-style space mine, spiked sphere with a flat top mount, silhouette-dominant. No blinking light, no chain, no glow halo, no smiley face, no shadow under the sphere. Icon five, plasma emitter: a containment emitter, circular coil ring around a small rectangular core with two side vents. No swirling plasma, no energy arcs, no glow ring, no gradient, no lightning bolt. Every icon is drawn as a single-colour flat silhouette in iron black #232629 with clean uniform strokes, isolated object, no shadows, no glow, no grid lines, no labels, no text, no watermark.

flat vector icon sheet, 2x3 grid (icons arranged in two columns and three rows), generous even gaps between icons, plain solid pure white background, no grid lines, no labels, no text, no watermark, isolated objects, no shadows, no glow, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style.

### SUBJECT — panel_cargo

grimdark painted sci-fi, semi-realistic weathered metal, harsh directional rim light from upper-left with a thin cold pale steel rim tracing shadow-side silhouettes, subtle film grain over the whole image, top-down orthographic view. Fixed palette: gunmetal mid #3A3F46, gunmetal dark #2B2F35, iron black #232629, steel highlight #565C63, rusted ochre #6E5B4A, dry rust #8A6A50, grimy umber #4A423B, void black #0A0E14, deep void blue #111823, void haze #1A2230, burnt ember #C8461B, ember glow #E8703A, panel black #15181D, panel steel #2A2E35, ash text #8D939B, bone text #C9CDD2. Metal colour is desaturated gunmetal and rusted steel, dark and tired, with scratches, oil stains, hull grime, rust streaks, pitted metal, scorch marks and battle damage. Glow colours are burnt ember #C8461B and ember glow #E8703A only, small and hot, used exclusively for engines, weapons and warning lights; no other glow or accent colour exists anywhere in the image. Backgrounds are near-black blue void, void black #0A0E14 to deep void blue #111823, sparse faint stars, desaturated throughout, no saturated colours, no chrome, no neon, no gloss, no clean surfaces, moody and menacing.

flat vector icon sheet for a dark sci-fi spaceship interface, six cargo and ore icons on a 2x3 grid of two columns and three rows, arranged left to right and top to bottom. Render this as a flat vector icon sheet and not as painted metal: every icon is a solid single-colour iron black #232629 silhouette with clean uniform strokes on a plain solid pure white background, with no weathering, no rust, no scratches, no rim light, no film grain, no shading, no gloss, no glow, no ember highlights, no stars and no dark background. Row one: raw ore chunk icon in the left cell, cargo crate icon in the right cell. Row two: iso-container icon in the left cell, fuel cell canister icon in the right cell. Row three: torn hull plate icon in the left cell, data core icon in the right cell. All six icons have identical visual mass and generous even gaps between them. Icon one, raw ore chunk: angular faceted rock with one flat cleaved face, silhouette-dominant. No sparkle, no crystals shooting light, no gem facets, no pickaxe, no shadow. Icon two, plain cargo crate: rectangular box with a lid seam and two clamp edges, three-quarter-flat front view. No rivets, no stencilled text, no hazard stripes, no wood grain, no rounded corners. Icon three, iso-container: long rectangular pod with corner brackets and one central seam line, front view. No corrugation, no doors ajar, no windows, no stacking, no perspective tilt. Icon four, fuel cell canister: vertical cylinder with a capped top valve and a single horizontal band. No flame, no droplet, no gauge, no glow, no rounded dome cap. Icon five, torn hull plate fragment: irregular angular scrap with one sheared edge and two bolt holes. No skull, no wrench, no treasure chest, no coins, no jagged saw teeth, no blood. Icon six, data core: square slab with a central square inset and two corner cut notches. No circuit traces, no glowing lines, no chip pins, no key symbol, no rounded corners. Every icon is drawn as a single-colour flat silhouette in iron black #232629 with clean uniform strokes, isolated object, no shadows, no glow, no grid lines, no labels, no text, no watermark.

flat vector icon sheet, 2x3 grid (icons arranged in two columns and three rows), generous even gaps between icons, plain solid pure white background, no grid lines, no labels, no text, no watermark, isolated objects, no shadows, no glow, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style.

### SUBJECT — panel_glyphs

grimdark painted sci-fi, semi-realistic weathered metal, harsh directional rim light from upper-left with a thin cold pale steel rim tracing shadow-side silhouettes, subtle film grain over the whole image, top-down orthographic view. Fixed palette: gunmetal mid #3A3F46, gunmetal dark #2B2F35, iron black #232629, steel highlight #565C63, rusted ochre #6E5B4A, dry rust #8A6A50, grimy umber #4A423B, void black #0A0E14, deep void blue #111823, void haze #1A2230, burnt ember #C8461B, ember glow #E8703A, panel black #15181D, panel steel #2A2E35, ash text #8D939B, bone text #C9CDD2. Metal colour is desaturated gunmetal and rusted steel, dark and tired, with scratches, oil stains, hull grime, rust streaks, pitted metal, scorch marks and battle damage. Glow colours are burnt ember #C8461B and ember glow #E8703A only, small and hot, used exclusively for engines, weapons and warning lights; no other glow or accent colour exists anywhere in the image. Backgrounds are near-black blue void, void black #0A0E14 to deep void blue #111823, sparse faint stars, desaturated throughout, no saturated colours, no chrome, no neon, no gloss, no clean surfaces, moody and menacing.

flat vector icon sheet for a dark sci-fi spaceship interface, nine interface glyph icons on a 3x3 grid of three columns and three rows, arranged left to right and top to bottom. Render this as a flat vector icon sheet and not as painted metal: every icon is a solid single-colour iron black #232629 silhouette with clean uniform strokes on a plain solid pure white background, with no weathering, no rust, no scratches, no rim light, no film grain, no shading, no gloss, no glow, no ember highlights, no stars and no dark background. Row one: settings gear in the first cell, close X in the second cell, zoom in in the third cell. Row two: zoom out in the first cell, credits symbol in the second cell, shield in the third cell. Row three: hull integrity in the first cell, ammo in the second cell, logout in the third cell. All nine icons have identical visual mass, uniform stroke weight and generous even gaps between them. Icon one, settings gear: eight-tooth cog with a square centre hole, flat top-down view. No wrench overlay, no double gears, no rounded teeth, no shine, no screwdriver. Icon two, close: two crossing bars of equal length forming a square X. No circle around it, no rounded stroke ends, no drop shadow, no arrowhead. Icon three, zoom in: square magnifier outline with a plus built from two crossing bars inside. No handle shine, no circle lens, no rounded handle, no map behind, no gradient. Icon four, zoom out: the same square magnifier outline with a single horizontal bar inside. No plus remnant, no circle lens, no rounded handle, no eye symbol, no gradient. Icon five, credits: hexagonal coin outline with a plain vertical bar struck through its centre. No dollar sign, no currency letter, no shine, no stack of coins, no glow. Icon six, shield: flat heater-shield outline with a single vertical centre seam. No crest, no cross, no wings, no shine, no damage cracks, no rounded base. Icon seven, hull integrity: angular ship-hull plate outline with two rivet notches and one crack line. No heart, no wrench, no ship silhouette, no gauge, no warning triangle. Icon eight, ammo: three parallel vertical cartridge slugs of equal height, flat tips. No bullets in flight, no magazine, no gun, no flame, no rounded tips, no shell casings. Icon nine, logout: door-frame outline with an arrow exiting through its right side. No power symbol, no padlock, no user figure, no rounded arrow, no keyhole. Every icon is drawn as a single-colour flat silhouette in iron black #232629 with clean uniform strokes, isolated object, no shadows, no glow, no grid lines, no labels, no text, no watermark.

flat vector icon sheet, 3x3 grid (three columns and three rows), generous even gaps between icons, plain solid pure white background, no grid lines, no labels, no text, no watermark, isolated objects, no shadows, no glow, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style.

## Cut-to-name mapping

### panel_weapons — split count 5 = expected 5, order left-to-right, top-to-bottom (verified against the master panel)

| Cut | Subject | 16 px | 48 px |
|---|---|---|---|
| `…asset-01` | laser | `icon_weapon_laser_16.png` | `icon_weapon_laser_48.png` |
| `…asset-02` | cannon | `icon_weapon_cannon_16.png` | `icon_weapon_cannon_48.png` |
| `…asset-03` | rocket | `icon_weapon_rocket_16.png` | `icon_weapon_rocket_48.png` |
| `…asset-04` | mine | `icon_weapon_mine_16.png` | `icon_weapon_mine_48.png` |
| `…asset-05` | plasma | `icon_weapon_plasma_16.png` | `icon_weapon_plasma_48.png` |

The sixth row-three cell is blank white in the master, as specified. Every accepted cut matched the master panel's own content box exactly (object boxes 753x259, 785x390, 779x306, 557x523, 708x442), so no mapping guess was needed.

### panel_cargo — split count 6 = expected 6, reading order

| Cut | Subject | 16 px | 48 px |
|---|---|---|---|
| `…asset-01` | ore | `icon_cargo_ore_16.png` | `icon_cargo_ore_48.png` |
| `…asset-02` | crate | `icon_cargo_crate_16.png` | `icon_cargo_crate_48.png` |
| `…asset-03` | container | `icon_cargo_container_16.png` | `icon_cargo_container_48.png` |
| `…asset-04` | fuel cell | `icon_cargo_fuel_cell_16.png` | `icon_cargo_fuel_cell_48.png` |
| `…asset-05` | salvage | `icon_cargo_salvage_16.png` | `icon_cargo_salvage_48.png` |
| `…asset-06` | data core | `icon_cargo_data_core_16.png` | `icon_cargo_data_core_48.png` |

Order and identity were confirmed by matching each cut against the master panel (content boxes 573x513, 611x383, 658x372, 240x556, 593x468, 424x433). Two cuts came out of the splitter unusable and were re-cut from the master panel image itself (Notes 2): the container (split cut was clipped on all four sides, 639x355 against a true 658x372) and the fuel cell (split cut lost the bottom base foot, 240x455 against a true 240x556). The re-cut files are `20260917-183446/cargo_container_recut.png` and `20260917-183446/cargo_fuel_cell_recut.png`; both are the accepted masters for their icons.

### panel_glyphs — split count 11 against an expected 9: mapping established from the master panel, not guessed

No cut is missing, but `--split` returned 11 fragments because three icons are drawn as disjoint parts. Each fragment was inspected individually and matched to its cell in the master panel (the master's own content boxes confirmed each match). Documented mapping:

| Split fragment | Fragment content | Master cell | Icon | 16 px | 48 px |
|---|---|---|---|---|---|
| `…asset-01` | eight-tooth cog | row 1 col 1 | gear | `icon_gear_16.png` | `icon_gear_48.png` |
| `…asset-02` | crossing bars | row 1 col 2 | close | `icon_close_16.png` | `icon_close_48.png` |
| `…asset-03` | magnifier with plus | row 1 col 3 | zoom plus | `icon_zoom_plus_16.png` | `icon_zoom_plus_48.png` |
| `…asset-04` | magnifier with bar | row 2 col 1 | zoom minus | `icon_zoom_minus_16.png` | `icon_zoom_minus_48.png` |
| `…asset-05` | hexagon with bar | row 2 col 2 | credits | `icon_credits_16.png` | `icon_credits_48.png` |
| `…asset-06` | shield with seam | row 2 col 3 | shield | `icon_shield_16.png` | `icon_shield_48.png` |
| `…asset-07` | hull plate, crack, two holes | row 3 col 1 | hull | `icon_hull_16.png` | `icon_hull_48.png` |
| `…asset-08` | left cartridge slug | row 3 col 2 | ammo (part) | – | – |
| `…asset-09` | centre cartridge slug | row 3 col 2 | ammo (part) | – | – |
| `…asset-10` | right cartridge slug | row 3 col 2 | ammo (part) | – | – |
| `…asset-11` | door frame with arrow | row 3 col 3 | logout | `icon_logout_16.png` | `icon_logout_48.png` |

`…asset-08/09/10` are the three slugs of the single `icon_ammo` subject, and the splitter dropped each slug's base rim (small members below its own 42 px / 8388 px cut filters). The accepted ammo master is therefore the master-panel re-cut `20260917-183722/glyphs_ammo_recut.png` (object 401x420, three slugs with rims), which produced `icon_ammo_16.png` and `icon_ammo_48.png`.

## Post-processing

- 48 px and 16 px variants are produced from the same accepted cut with Pillow 12.1.0 / LANCZOS on the template interpreter: trim to the object's alpha bounding box, centre on a transparent square canvas sized to the object's longest edge (no aspect distortion), then resize to 48 and 16.
- Every exported cut was verified to have zero opaque pixels on its crop border (no clipping) and to match the master panel's content box for that cell.
- 43 deliverables: `panel_weapons.png`, `panel_cargo.png`, `panel_glyphs.png` (2K 1:1 masters, 2048x2048), their three `panel_<name>.job.json` manifests, and 20 icons x 2 sizes. The four timestamped run folders are kept as provenance (raw 2K renders, alpha PNGs, split assets).

## 16 px legibility check (per ICONS_SPEC §6)

Measured on the exported 16 px cuts: connected-component and enclosed-hole counts at 50 % alpha, compared with the source cut. No icon gained components or lost its outer silhouette: no 1.5 px-equivalent stroke broke into disconnected islands, and no mitred corner rounded into a detached blob. All 16 px cuts are legible silhouettes of their subject.

Detail loss at 16 px (cut-line detail closing, not a break) — reported, not regenerated:

- `icon_weapon_laser`: the forward emissive slit closes and the barrel reads solid (1 hole at 48 px, 0 at 16 px).
- `icon_weapon_plasma`: 3 of the 6 negative-space cuts close; the coil ring and core still read, the two side vents grey out.
- `icon_cargo_crate`: the lid seam and clamp cut lines merge; the box reads solid.
- `icon_cargo_container`: the central seam stops being a hole at 16 px; the corner brackets survive at 48 px and merge into the body at 16 px.
- `icon_hull`: one of the two rivet holes fills in (2 holes at 48/16 px -> 1 at 16 px); the crack line survives.
- Outline-weight glyphs (`icon_zoom_plus`, `icon_zoom_minus`, `icon_credits`, `icon_shield`) carry ~1.4 px-equivalent strokes at 16 px, so their outlines render at fractional coverage (grey rather than solid black) but stay continuous. Filling them further is a stroke-weight decision for a future batch; per the spec they must not be hand-blurred or anti-aliased.

## Notes and deviations

1. **Style-block ordering (command template deviation).** The brief's template passes the style block through `--style-file`, but `kie_generate.py` appends that text *after* `--prompt`, which inverts ICONS_SPEC §5 ("each panel prompt = the verbatim contents of style-block.txt, followed by the panel's flat-vector subject block and this fixed framing sentence"). Run 18:31:09 used the template verbatim and came back as painted weathered metal with ember-glow slits on a near-black starfield void: the flat-vector override in the framing sentence lost to the trailing style block, violating §1 (single-colour flat silhouettes in iron black on pure white) and the weapons' negative lists (no glow, no beam). The accepted runs therefore carry the style block verbatim at the *start* of `--prompt` and omit `--style-file`, which reproduces the spec's prescribed order exactly (verified in each `job.json`: `input.prompt` starts with the style block and ends with the framing sentence). No other part of the template changed; aspect, resolution, `--strip-bg local`, `--split` and the output directory are as briefed.
2. **Parentheses in prompt text.** No unbalanced or decorative parentheses and no double-quote characters were introduced anywhere in the prompt text; the only parentheses are the balanced ones inside the ICONS_SPEC §5 framing sentence, which the brief requires copied verbatim ("2x3 grid (icons arranged in two columns and three rows)" and, for panel 3, "3x3 grid (three columns and three rows)").
3. **Splitter reliability.** `--split` mis-cut 4 of the 22 fragments across the batch (container clipped, fuel cell truncated, three ammo slugs unmerged and rim-less). All were repaired from the master panel image, which is also how each fragment's identity was established. Panel 1 needed no repair.
4. **Subject deviations observed in the accepted masters (not regenerated).** `icon_ammo`: the three slugs have chamfered tips rather than perfectly flat tips and a thin rim bar under each, where §4 asks for flat tips and no shell casings. `icon_hull`: the two rivet notches read as two round rivet holes. `icon_weapon_rocket`: two tail fins are clearly visible where §2 asks for three. Everything else matches its spec subject and negative list, including both mine and laser/cannon profiles and the empty weapons cell.
5. **State colour.** No generated file contains a state colour; all 16/48 px PNGs are iron-black art with alpha, ready for engine-side modulate per §1.

### Audit follow-up 2026-09-17 19:09 — icon manifest derivation
- The 40 icon_<name>_16.png / icon_<name>_48.png finals are local Pillow derivatives (LANCZOS) of the three 2K master panels; they carry no kie.ai job of their own by design. Provenance: panel_weapons.job.json fc9fc1465f203a3b56c48f98792f0b7c, panel_cargo.job.json 04e356b4b7f8c74d2fdd3a5fcf4f3dcd, panel_glyphs.job.json 65a81be9653c5ac502644e75ea8466e2 plus the per-cut mapping documented above.
