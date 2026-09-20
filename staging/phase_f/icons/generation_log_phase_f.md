# Phase F - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`; `flare-i2i` for reference edits), 2K.
Work order: `docs/gameplay/16_art_design_brief.md`. Style law: `docs/design/STYLE_BIBLE.md`, `docs/design/ICONS_SPEC.md` (section 1 + section 8 amendment), `docs/design/SHIPS_SPEC.md` (section 1 framing constant, sections 3.7-3.9).
Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file` on every run.
Price basis: 10 credits = $0.05 per 2K run (kie.ai console, user-verified); the script's printed 30-credit estimate is the stale hint and the `usage-ledger.jsonl` total over-reports 3x.
Alpha: `--transparent` native first, local matte fallback (`staging/phase_d/reprocess.py`). FX stay RGB on void black for additive blending and are never alpha-keyed (FX_SPEC 0.1).
AI-generated art is not CC0 (AGENTS.md).

---

## p0_minerals_ore

- Date/time: 2026-09-18 11:02 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `b56f16aebe83ac92c75e4efc48c815aa` (elapsed 39.5s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#04090D alpha0=76% dropped=403, grid split; run folder `20260918-110236` keeps `job.json`
- Final files: icon_mineral_iron.png, icon_mineral_copper.png, icon_mineral_chromium.png, icon_mineral_silicon.png, icon_mineral_aluminium.png, icon_mineral_titanium.png, icon_mineral_nickel.png, icon_mineral_cobalt.png, icon_mineral_tungsten.png, icon_mineral_silver.png, icon_mineral_gold.png, icon_mineral_platinum.png, icon_mineral_neodymium.png, icon_mineral_iridium.png, icon_mineral_osmium.png, icon_mineral_palladium.png, icon_mineral_cerulite.png, icon_mineral_emberite.png, icon_mineral_voidglass.png, icon_mineral_krilium.png (+ 40 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 5x4 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 raw iron ore, a heavy blocky chunk with three flat fracture faces, squat and dense; 2 raw copper ore, a chunky lump with a curled shard edge peeling off one side; 3 raw chromium ore, a slim elongated shard with one sharp tapered tip; 4 raw silicon ore, a flat wide wedge with one broad planar cleaved face and a knife edge; 5 raw aluminium ore, a thin wide flake with a feathered folded rim; 6 raw titanium ore, a stout nugget with five clean facets meeting at a single ridge; 7 raw nickel ore, an oblong lump carrying one flat band across its face; 8 raw cobalt ore, a small rounded lobe of mineral still locked in a square host-rock corner; 9 raw tungsten ore, a dense cube-faced chunk with one corner sheared away square; 10 raw silver ore, a pointed chunk sprouting three short needle crystals; 11 raw gold ore, a lumpy nugget with one rounded drooping edge read as sagging metal; 12 raw platinum ore, a layered flake-plate chunk with a stepped bright top face; 13 raw neodymium ore, a blocky matrix chunk holding one dark angular inclusion block; 14 raw iridium ore, a dense jagged shard barbed with short spikes on every side; 15 raw osmium ore, a squat heavy chunk with a chipped flat rim; 16 raw palladium ore, a slatted crystal chunk of three flat parallel blades; 17 raw cerulite ore, a shard cluster split by one raised vein ridge running its length; 18 raw emberite ore, a chunk cut through by a single deep internal fissure crack; 19 raw voidglass ore, a smooth curved shell shard with one hooked lip, glassier and rounder than every other ore; 20 raw krilium ore, an irregular asymmetric chunk with one long spike, visibly refusing the geometry of the others. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_minerals_ingot

- Date/time: 2026-09-18 11:03 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `7f86e24f7bfa4acdf0b3740bdef00f04` (elapsed 29.0s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#04070C alpha0=76% dropped=213, component split; run folder `20260918-110318` keeps `job.json`
- Final files: icon_ingot_iron.png, icon_ingot_copper.png, icon_ingot_chromium.png, icon_ingot_silicon.png, icon_ingot_aluminium.png, icon_ingot_titanium.png, icon_ingot_nickel.png, icon_ingot_cobalt.png, icon_ingot_tungsten.png, icon_ingot_silver.png, icon_ingot_gold.png, icon_ingot_platinum.png, icon_ingot_neodymium.png, icon_ingot_iridium.png, icon_ingot_osmium.png, icon_ingot_palladium.png, icon_ingot_cerulite.png, icon_ingot_emberite.png, icon_ingot_voidglass.png, icon_ingot_krilium.png (+ 40 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 5x4 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 refined iron ingot, a single stamped metal bar with a flat top face, a wide squat bar with one chiselled end; 2 refined copper ingot, a single stamped metal bar with a flat top face, a bar with a rounded end and one raised ridge line along the top; 3 refined chromium ingot, a single stamped metal bar with a flat top face, a slim long bar tapered at one end; 4 refined silicon ingot, a single stamped metal bar with a flat top face, a flat wide slab bar with a stepped top face; 5 refined aluminium ingot, a single stamped metal bar with a flat top face, a small neat bar with one folded corner tab; 6 refined titanium ingot, a single stamped metal bar with a flat top face, a stout bar struck twice with two parallel vertical marks; 7 refined nickel ingot, a single stamped metal bar with a flat top face, an oblong bar with one chamfered top corner; 8 refined cobalt ingot, a single stamped metal bar with a flat top face, a bar with a banded waist pinched at the middle; 9 refined tungsten ingot, a single stamped metal bar with a flat top face, a near-cubic heavy bar with one chiselled side notch; 10 refined silver ingot, a single stamped metal bar with a flat top face, a bar with a single fine hairline seam down the middle; 11 refined gold ingot, a single stamped metal bar with a flat top face, a bar carrying one lone centre punch mark; 12 refined platinum ingot, a single stamped metal bar with a flat top face, a bar with a stepped double top face; 13 refined neodymium ingot, a single stamped metal bar with a flat top face, a bar with a pair of crossed grooves cut across its top; 14 refined iridium ingot, a single stamped metal bar with a flat top face, a bar with one barbed end notch; 15 refined osmium ingot, a single stamped metal bar with a flat top face, a thick squat bar with a heavy chamfer on all four long edges; 16 refined palladium ingot, a single stamped metal bar with a flat top face, a bar with a lattice-pierced top face; 17 refined cerulite ingot, a single stamped metal bar with a flat top face, a bar with a single central ridge running its full length; 18 refined emberite ingot, a single stamped metal bar with a flat top face, a bar with a chiselled V groove notch cut into one end; 19 refined voidglass ingot, a single stamped metal bar with a flat top face, a bar with a concave scoop taken out of one end, glassier and rounder than the rest; 20 refined krilium ingot, a single stamped metal bar with a flat top face, a bar with a visibly warped irregular profile and one barb, refusing the geometry of the others. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_a

- Date/time: 2026-09-18 11:04 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `672f15bb4323b5707a4877452ae51549` (elapsed 39.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#030A10 alpha0=73% dropped=79, component split; run folder `20260918-110409` keeps `job.json`
- Final files: icon_module_w_railgun.png, icon_module_w_mining.png, icon_module_s_light.png, icon_module_s_heavy.png, icon_module_s_ion.png, icon_module_h_plate_light.png, icon_module_h_plate_heavy.png, icon_module_h_composite.png, icon_module_p_std.png (+ 18 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 railgun hardpoint, a squared housing holding two long parallel rails that project forward past the muzzle, with a heavy rear breech block, shown right-facing in profile; 2 mining laser hardpoint, a short thick barrel ending in a three-pronged emitter claw, right-facing in profile; 3 light shield generator, a thin arc emitter half-ring sitting on two small anchor lugs; 4 heavy shield generator, a thick arc emitter half-ring with a doubled concentric band and four anchor lugs; 5 ion shield generator, an arc emitter half-ring carrying three short inner coil bars; 6 light armour plate, one flat rectangular plate with a rivet notch cut at two opposite corners; 7 heavy armour plate, two stacked flat plates offset from each other with a bolted edge seam between them; 8 composite armour plate, one flat plate inset with a diagonal lattice weave of bars; 9 standard reactor core, a rectangular housing with three vertical coil slats on its face and a base mount plate. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_b

- Date/time: 2026-09-18 11:05 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `972927870352ca746b36b233bdd14c7e` (elapsed 39.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#030910 alpha0=69% dropped=309, component split; run folder `20260918-110458` keeps `job.json`
- Final files: icon_module_p_mk2.png, icon_module_p_core.png, icon_module_e_std.png, icon_module_e_ion.png, icon_module_e_vector.png, icon_module_b_afterburner.png, icon_module_b_fold.png, icon_module_c_target.png, icon_module_c_scanner.png (+ 18 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 upgraded reactor core, the same rectangular housing with five vertical coil slats and a raised cap block on top; 2 high-output power core, a hexagonal housing around a square core block with four bolt notches; 3 standard drive nozzle, a truncated cone with one plain ring around its throat; 4 ion drive nozzle, a truncated cone with a doubled ring around its throat and one short vane on each side; 5 vector drive nozzle, a truncated cone held in a gimbal yoke with two projecting actuator arms; 6 afterburner booster, a vent block with three stacked chevron slats across its face; 7 fold drive booster, a square plate cut through by a folded arrow-shaped notch; 8 targeting computer, a square boresight reticle with a cross struck through it and one ranging tick on the lower edge; 9 scanner computer, a dish arc on a short stem with two concentric return arcs behind it. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_c

- Date/time: 2026-09-18 11:05 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `4dff98a783307a2270dbc33195013272` (elapsed 39.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#010910 alpha0=73% dropped=216, component split; run folder `20260918-110547` keeps `job.json`
- Final files: icon_module_c_twin.png, icon_module_c_ewar.png, icon_module_c_nexus.png, icon_module_u_cargo.png, icon_module_u_salvage.png, icon_module_u_refine.png, icon_module_u_drones.png, icon_module_u_tractor.png, icon_module_u_holds.png (+ 18 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 twin targeting stack, two square reticle frames stacked one above the other and joined by a side bracket; 2 electronic warfare suite, a square board with three radiating jam bars projecting from its right edge; 3 nexus computer, a square board with one central node linked by straight traces to three corner nodes; 4 cargo expander, an open crate with a raised lid held on one latch; 5 salvage rig, a clamp claw with one straight handle and a severed hook curling from its jaw; 6 ore refiner, a hopper funnel sitting on a squat drum with one output spout at the base; 7 drone bay, an open bay slot with two small arrowhead drones racked side by side inside it; 8 tractor emitter, a cone emitter projecting three parallel field bars from its mouth; 9 hold expander, two stacked container blocks joined by a single linking rail down one side. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_slots

- Date/time: 2026-09-18 11:06 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `3c1922202eaf820a7b4af55a636903fd` (elapsed 44.9s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#04070B alpha0=76% dropped=219, component split; run folder `20260918-110642` keeps `job.json`
- Final files: icon_slot_engine.png, icon_slot_power.png, icon_slot_w.png, icon_slot_s.png, icon_slot_h.png, icon_slot_c.png, icon_slot_b.png, icon_slot_u.png (+ 16 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 4x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 an engine slot socket: one trapezoidal nozzle block on a flat mount plate; 2 a power slot socket: a reactor core block with three vertical coil bars on its face; 3 a weapon slot socket: a hardpoint mount plate with two clamp jaws gripping a socket mouth; 4 a shield slot socket: an arc emitter half-ring set into a flat base plate; 5 an armour slot socket: three flat plates stacked in an offset step; 6 a computer slot socket: a square board with one raised central node block; 7 a booster slot socket: a vent block carrying a single bold chevron burst; 8 a utility slot socket: an open pod socket with a latch bracket across its mouth. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_slots

- Date/time: 2026-09-18 11:09 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `490c19cc79df0d63f6c7eccebc611fe9` (elapsed 40.5s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#03090E alpha0=79% dropped=122, component split; run folder `20260918-110921` keeps `job.json`
- Final files: icon_slot_engine.png, icon_slot_power.png, icon_slot_w.png, icon_slot_s.png, icon_slot_h.png, icon_slot_c.png, icon_slot_b.png, icon_slot_u.png (+ 16 16/48 splits)
- Note: style regen: the first pass returned painted 3D metal objects with ember glow on void black (ICONS_SPEC section 1 violation); the flat-vector override block was added to the subject side and the run repeated.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 4x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 an engine slot socket: one trapezoidal nozzle block on a flat mount plate; 2 a power slot socket: a reactor core block with three vertical coil bars on its face; 3 a weapon slot socket: a hardpoint mount plate with two clamp jaws gripping a socket mouth; 4 a shield slot socket: an arc emitter half-ring set into a flat base plate; 5 an armour slot socket: three flat plates stacked in an offset step; 6 a computer slot socket: a square board with one raised central node block; 7 a booster slot socket: a vent block carrying a single bold chevron burst; 8 a utility slot socket: an open pod socket with a latch bracket across its mouth. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_slots

- Date/time: 2026-09-18 11:10 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `8b4cf1e8daec2d2ce80b786523ac3812` (elapsed 39.7s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-111044` keeps `job.json`
- Final files: icon_slot_engine.png, icon_slot_power.png, icon_slot_w.png, icon_slot_s.png, icon_slot_h.png, icon_slot_c.png, icon_slot_b.png, icon_slot_u.png (+ 16 16/48 splits)
- Note: style regen 2: style block moved to the prompt preamble (still copied verbatim from style-block.txt) so the ICONS_SPEC section 5 flat-vector sentence is read last; pass 1 and pass 2 both returned painted renders with ember glow.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 4x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 an engine slot socket: one trapezoidal nozzle block on a flat mount plate; 2 a power slot socket: a reactor core block with three vertical coil bars on its face; 3 a weapon slot socket: a hardpoint mount plate with two clamp jaws gripping a socket mouth; 4 a shield slot socket: an arc emitter half-ring set into a flat base plate; 5 an armour slot socket: three flat plates stacked in an offset step; 6 a computer slot socket: a square board with one raised central node block; 7 a booster slot socket: a vent block carrying a single bold chevron burst; 8 a utility slot socket: an open pod socket with a latch bracket across its mouth. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_minerals_ore

- Date/time: 2026-09-18 11:12 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `cae92391bca7aa9a23e89ed43c7a87c1` (elapsed 65.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-111209` keeps `job.json`
- Final files: icon_mineral_iron.png, icon_mineral_copper.png, icon_mineral_chromium.png, icon_mineral_silicon.png, icon_mineral_aluminium.png, icon_mineral_titanium.png, icon_mineral_nickel.png, icon_mineral_cobalt.png, icon_mineral_tungsten.png, icon_mineral_silver.png, icon_mineral_gold.png, icon_mineral_platinum.png, icon_mineral_neodymium.png, icon_mineral_iridium.png, icon_mineral_osmium.png, icon_mineral_palladium.png, icon_mineral_cerulite.png, icon_mineral_emberite.png, icon_mineral_voidglass.png, icon_mineral_krilium.png (+ 40 16/48 splits)
- Note: style regen 2: style block moved to the prompt preamble (still copied verbatim from style-block.txt) so the ICONS_SPEC section 5 flat-vector sentence is read last; pass 1 returned painted renders with ember glow on void black.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 5x4 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 raw iron ore, a heavy blocky chunk with three flat fracture faces, squat and dense; 2 raw copper ore, a chunky lump with a curled shard edge peeling off one side; 3 raw chromium ore, a slim elongated shard with one sharp tapered tip; 4 raw silicon ore, a flat wide wedge with one broad planar cleaved face and a knife edge; 5 raw aluminium ore, a thin wide flake with a feathered folded rim; 6 raw titanium ore, a stout nugget with five clean facets meeting at a single ridge; 7 raw nickel ore, an oblong lump carrying one flat band across its face; 8 raw cobalt ore, a small rounded lobe of mineral still locked in a square host-rock corner; 9 raw tungsten ore, a dense cube-faced chunk with one corner sheared away square; 10 raw silver ore, a pointed chunk sprouting three short needle crystals; 11 raw gold ore, a lumpy nugget with one rounded drooping edge read as sagging metal; 12 raw platinum ore, a layered flake-plate chunk with a stepped bright top face; 13 raw neodymium ore, a blocky matrix chunk holding one dark angular inclusion block; 14 raw iridium ore, a dense jagged shard barbed with short spikes on every side; 15 raw osmium ore, a squat heavy chunk with a chipped flat rim; 16 raw palladium ore, a slatted crystal chunk of three flat parallel blades; 17 raw cerulite ore, a shard cluster split by one raised vein ridge running its length; 18 raw emberite ore, a chunk cut through by a single deep internal fissure crack; 19 raw voidglass ore, a smooth curved shell shard with one hooked lip, glassier and rounder than every other ore; 20 raw krilium ore, an irregular asymmetric chunk with one long spike, visibly refusing the geometry of the others. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_minerals_ingot

- Date/time: 2026-09-18 11:12 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `7cfa9fb037d54f3c0f4871b893ad3f9e` (elapsed 29.1s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-111243` keeps `job.json`
- Final files: icon_ingot_iron.png, icon_ingot_copper.png, icon_ingot_chromium.png, icon_ingot_silicon.png, icon_ingot_aluminium.png, icon_ingot_titanium.png, icon_ingot_nickel.png, icon_ingot_cobalt.png, icon_ingot_tungsten.png, icon_ingot_silver.png, icon_ingot_gold.png, icon_ingot_platinum.png, icon_ingot_neodymium.png, icon_ingot_iridium.png, icon_ingot_osmium.png, icon_ingot_palladium.png, icon_ingot_cerulite.png, icon_ingot_emberite.png, icon_ingot_voidglass.png, icon_ingot_krilium.png (+ 40 16/48 splits)
- Note: style regen 2: style block moved to the prompt preamble (still copied verbatim from style-block.txt) so the ICONS_SPEC section 5 flat-vector sentence is read last; pass 1 returned painted renders with ember glow on void black.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 5x4 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 refined iron ingot, a single stamped metal bar with a flat top face, a wide squat bar with one chiselled end; 2 refined copper ingot, a single stamped metal bar with a flat top face, a bar with a rounded end and one raised ridge line along the top; 3 refined chromium ingot, a single stamped metal bar with a flat top face, a slim long bar tapered at one end; 4 refined silicon ingot, a single stamped metal bar with a flat top face, a flat wide slab bar with a stepped top face; 5 refined aluminium ingot, a single stamped metal bar with a flat top face, a small neat bar with one folded corner tab; 6 refined titanium ingot, a single stamped metal bar with a flat top face, a stout bar struck twice with two parallel vertical marks; 7 refined nickel ingot, a single stamped metal bar with a flat top face, an oblong bar with one chamfered top corner; 8 refined cobalt ingot, a single stamped metal bar with a flat top face, a bar with a banded waist pinched at the middle; 9 refined tungsten ingot, a single stamped metal bar with a flat top face, a near-cubic heavy bar with one chiselled side notch; 10 refined silver ingot, a single stamped metal bar with a flat top face, a bar with a single fine hairline seam down the middle; 11 refined gold ingot, a single stamped metal bar with a flat top face, a bar carrying one lone centre punch mark; 12 refined platinum ingot, a single stamped metal bar with a flat top face, a bar with a stepped double top face; 13 refined neodymium ingot, a single stamped metal bar with a flat top face, a bar with a pair of crossed grooves cut across its top; 14 refined iridium ingot, a single stamped metal bar with a flat top face, a bar with one barbed end notch; 15 refined osmium ingot, a single stamped metal bar with a flat top face, a thick squat bar with a heavy chamfer on all four long edges; 16 refined palladium ingot, a single stamped metal bar with a flat top face, a bar with a lattice-pierced top face; 17 refined cerulite ingot, a single stamped metal bar with a flat top face, a bar with a single central ridge running its full length; 18 refined emberite ingot, a single stamped metal bar with a flat top face, a bar with a chiselled V groove notch cut into one end; 19 refined voidglass ingot, a single stamped metal bar with a flat top face, a bar with a concave scoop taken out of one end, glassier and rounder than the rest; 20 refined krilium ingot, a single stamped metal bar with a flat top face, a bar with a visibly warped irregular profile and one barb, refusing the geometry of the others. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_a

- Date/time: 2026-09-18 11:13 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `adb6bf0bd0a18a9eeb6170347d5d301b` (elapsed 39.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-111327` keeps `job.json`
- Final files: icon_module_w_railgun.png, icon_module_w_mining.png, icon_module_s_light.png, icon_module_s_heavy.png, icon_module_s_ion.png, icon_module_h_plate_light.png, icon_module_h_plate_heavy.png, icon_module_h_composite.png, icon_module_p_std.png (+ 18 16/48 splits)
- Note: style regen 2: style block moved to the prompt preamble (still copied verbatim from style-block.txt) so the ICONS_SPEC section 5 flat-vector sentence is read last; pass 1 returned painted renders with ember glow on void black.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 railgun hardpoint, a squared housing holding two long parallel rails that project forward past the muzzle, with a heavy rear breech block, shown right-facing in profile; 2 mining laser hardpoint, a short thick barrel ending in a three-pronged emitter claw, right-facing in profile; 3 light shield generator, a thin arc emitter half-ring sitting on two small anchor lugs; 4 heavy shield generator, a thick arc emitter half-ring with a doubled concentric band and four anchor lugs; 5 ion shield generator, an arc emitter half-ring carrying three short inner coil bars; 6 light armour plate, one flat rectangular plate with a rivet notch cut at two opposite corners; 7 heavy armour plate, two stacked flat plates offset from each other with a bolted edge seam between them; 8 composite armour plate, one flat plate inset with a diagonal lattice weave of bars; 9 standard reactor core, a rectangular housing with three vertical coil slats on its face and a base mount plate. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_b

- Date/time: 2026-09-18 11:14 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `f9dbb1a105a92105a92b30dcdc9f2178` (elapsed 39.5s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-111411` keeps `job.json`
- Final files: icon_module_p_mk2.png, icon_module_p_core.png, icon_module_e_std.png, icon_module_e_ion.png, icon_module_e_vector.png, icon_module_b_afterburner.png, icon_module_b_fold.png, icon_module_c_target.png, icon_module_c_scanner.png (+ 18 16/48 splits)
- Note: style regen 2: style block moved to the prompt preamble (still copied verbatim from style-block.txt) so the ICONS_SPEC section 5 flat-vector sentence is read last; pass 1 returned painted renders with ember glow on void black.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 upgraded reactor core, the same rectangular housing with five vertical coil slats and a raised cap block on top; 2 high-output power core, a hexagonal housing around a square core block with four bolt notches; 3 standard drive nozzle, a truncated cone with one plain ring around its throat; 4 ion drive nozzle, a truncated cone with a doubled ring around its throat and one short vane on each side; 5 vector drive nozzle, a truncated cone held in a gimbal yoke with two projecting actuator arms; 6 afterburner booster, a vent block with three stacked chevron slats across its face; 7 fold drive booster, a square plate cut through by a folded arrow-shaped notch; 8 targeting computer, a square boresight reticle with a cross struck through it and one ranging tick on the lower edge; 9 scanner computer, a dish arc on a short stem with two concentric return arcs behind it. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_c

- Date/time: 2026-09-18 11:14 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d68bd36303a74e25127e13ecea1e5fc5` (elapsed 34.3s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-111450` keeps `job.json`
- Final files: icon_module_c_twin.png, icon_module_c_ewar.png, icon_module_c_nexus.png, icon_module_u_cargo.png, icon_module_u_salvage.png, icon_module_u_refine.png, icon_module_u_drones.png, icon_module_u_tractor.png, icon_module_u_holds.png (+ 18 16/48 splits)
- Note: style regen 2: style block moved to the prompt preamble (still copied verbatim from style-block.txt) so the ICONS_SPEC section 5 flat-vector sentence is read last; pass 1 returned painted renders with ember glow on void black.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 twin targeting stack, two square reticle frames stacked one above the other and joined by a side bracket; 2 electronic warfare suite, a square board with three radiating jam bars projecting from its right edge; 3 nexus computer, a square board with one central node linked by straight traces to three corner nodes; 4 cargo expander, an open crate with a raised lid held on one latch; 5 salvage rig, a clamp claw with one straight handle and a severed hook curling from its jaw; 6 ore refiner, a hopper funnel sitting on a squat drum with one output spout at the base; 7 drone bay, an open bay slot with two small arrowhead drones racked side by side inside it; 8 tractor emitter, a cone emitter projecting three parallel field bars from its mouth; 9 hold expander, two stacked container blocks joined by a single linking rail down one side. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_contracts

- Date/time: 2026-09-18 11:29 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `b8625c193816adcb1c6ff1685f24df70` (elapsed 39.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-112903` keeps `job.json`
- Final files: icon_contract_haul.png, icon_contract_hunt.png, icon_contract_gather.png, icon_contract_escort.png, icon_contract_expedition.png (+ 10 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 haul contract: a closed crate sitting on a two-wheeled pallet bar; 2 hunt contract: a crosshair reticle centred on a downward pointing chevron target; 3 gather contract: a two-jaw claw gripping a faceted rock chunk; 4 escort contract: two chevrons travelling in column inside a squared bracket; 5 expedition contract: a ring with one bold arrow projecting outward from its rim; 6 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_service_glyphs

- Date/time: 2026-09-18 11:29 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `94ebda934873b867dcaf7e053719128d` (elapsed 39.8s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#050A10 alpha0=79% dropped=122, component split; run folder `20260918-112946` keeps `job.json`
- Final files: icon_service_vault.png, icon_service_insurance.png, icon_service_bounty.png (+ 6 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 vault service: a heavy door slab carrying a three-spoke wheel at its centre; 2 insurance service: a flat shield plate crossed by one horizontal seam with a rivet notch below it; 3 bounty service: a plain circular coin outline struck through by a notched band; 4 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_faction_insignia

- Date/time: 2026-09-18 11:30 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `51ea84126b4a14d3f01e2b15b7512164` (elapsed 34.8s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#03070C alpha0=76% dropped=140, grid split; run folder `20260918-113028` keeps `job.json`
- Final files: icon_insignia_concord.png, icon_insignia_meridian.png, icon_insignia_choir.png (+ 6 16/48 splits)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 Concord of Iron emblem: a hex plate carrying three stacked horizontal plate bars; 2 Meridian Free Ports emblem: a hex plate split by one diagonal dock seam with a small pod block docked on the seam; 3 Ember Choir emblem: a hex plate carrying a three-tongued radial flame; 4 an empty blank white cell, leave the last cell completely blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_service_glyphs

- Date/time: 2026-09-18 11:34 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1dd2eac59f5586257b05bf74589d7c0f` (elapsed 29.2s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-113357` keeps `job.json`
- Final files: icon_service_vault.png, icon_service_insurance.png, icon_service_bounty.png (+ 6 16/48 splits)
- Note: flat-vector regen: the first P2 pass omitted the ICON_STYLE_FIRST preamble and returned painted rust-textured plates with warm pixels (ICONS_SPEC section 1 violation); the bounty coin also read as a prohibition sign and was re-worded.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 vault service: a heavy door slab carrying a three-spoke wheel at its centre; 2 insurance service: a flat shield plate crossed by one horizontal seam with a rivet notch below it; 3 bounty service: a thick circular coin outline with a small square notch cut out of its rim and one short vertical tally mark cut inside it, unambiguously a coin and not a prohibition sign; 4 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_faction_insignia

- Date/time: 2026-09-18 11:34 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `2fc63f093f03fc8efb2442f9e73c3348` (elapsed 34.8s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-113435` keeps `job.json`
- Final files: icon_insignia_concord.png, icon_insignia_meridian.png, icon_insignia_choir.png (+ 6 16/48 splits)
- Note: flat-vector regen: the first P2 pass omitted the ICON_STYLE_FIRST preamble and returned painted rust-textured plates with warm pixels (ICONS_SPEC section 1 violation); the bounty coin also read as a prohibition sign and was re-worded.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 Concord of Iron emblem: a hex plate carrying three stacked horizontal plate bars; 2 Meridian Free Ports emblem: a hex plate split by one diagonal dock seam with a small pod block docked on the seam; 3 Ember Choir emblem: a hex plate carrying a three-tongued radial flame; 4 an empty blank white cell, leave the last cell completely blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_a

- Date/time: 2026-09-18 11:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `f0788ee212e636829b8e7b9ee4864fb9` (elapsed 39.4s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114107` keeps `job.json`
- Final files: icon_module_w_railgun.png, icon_module_w_mining.png, icon_module_s_light.png, icon_module_s_heavy.png, icon_module_s_ion.png, icon_module_h_plate_light.png, icon_module_h_plate_heavy.png, icon_module_h_composite.png, icon_module_p_std.png (+ 18 16/48 splits)
- Note: 16 px readability regen: 12 glyphs collapsed to nearly solid squares at 16 px (alpha0 under 10 percent, h_plate_light and slot_c at 0) because their cut detail was a solid mass rather than an opening. The subject wording now specifies wide open slots and large negative-space openings so the silhouette survives the 16 px cut.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 railgun hardpoint, a squared housing holding two long parallel rails that project forward past the muzzle, with a heavy rear breech block, shown right-facing in profile; 2 mining laser hardpoint, a short thick barrel ending in a three-pronged emitter claw, right-facing in profile; 3 light shield generator, a thin arc emitter half-ring sitting on two small anchor lugs; 4 heavy shield generator, a thick arc emitter half-ring with a doubled concentric band and four anchor lugs; 5 ion shield generator, an arc emitter half-ring carrying three short inner coil bars; 6 light armour plate, one flat rectangular plate seen square on with two large square notches cut out of its top and bottom edges and one wide diagonal slot cut right through the plate, so the shape reads as a plate and never as a filled square; 7 heavy armour plate, two stacked flat plates with a wide open gap cut between the two layers and three bold round rivet holes cut right through the upper plate; 8 composite armour plate, one flat plate cut through by a bold diagonal lattice of wide crossing bars, leaving large open square holes between them; 9 standard reactor core, a rectangular housing with three wide vertical slots cut right through its face and a stepped base mount plate. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_b

- Date/time: 2026-09-18 11:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `4c921accc8c0826a0da6492c49e2cb0b` (elapsed 44.5s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-114156` keeps `job.json`
- Final files: icon_module_p_mk2.png, icon_module_p_core.png, icon_module_e_std.png, icon_module_e_ion.png, icon_module_e_vector.png, icon_module_b_afterburner.png, icon_module_b_fold.png, icon_module_c_target.png, icon_module_c_scanner.png (+ 18 16/48 splits)
- Note: 16 px readability regen: 12 glyphs collapsed to nearly solid squares at 16 px (alpha0 under 10 percent, h_plate_light and slot_c at 0) because their cut detail was a solid mass rather than an opening. The subject wording now specifies wide open slots and large negative-space openings so the silhouette survives the 16 px cut.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 upgraded reactor core, a rectangular housing with five wide vertical slots cut right through its face, a bold open cap block on top and a stepped base mount plate; 2 high-output power core, a hexagonal housing around one large open square core opening with four bold bolt notches cut at the corners; 3 standard drive nozzle, a truncated cone with one plain ring around its throat and a wide open mouth cut at the exhaust end; 4 ion drive nozzle, a truncated cone with a doubled ring around its throat, one bold short vane projecting from each side and a wide open mouth at the exhaust end; 5 vector drive nozzle, a truncated cone held in a gimbal yoke with two bold projecting actuator arms and a wide open mouth at the exhaust end; 6 afterburner booster, a vent block with three wide open chevron slots cut straight through its face; 7 fold drive booster, a square plate cut by one bold wide folded arrow-shaped slot straight through it, leaving a clear arrow-shaped opening; 8 targeting computer, a square boresight reticle frame with one large open square cut through its centre, a cross struck across the opening and one bold ranging tick on the lower edge; 9 scanner computer, a bold dish arc on a short stem with two wide concentric return arcs behind it. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_c

- Date/time: 2026-09-18 11:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `2cf3db016805601375aacd94980a2ee4` (elapsed 39.5s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-114240` keeps `job.json`
- Final files: icon_module_c_twin.png, icon_module_c_ewar.png, icon_module_c_nexus.png, icon_module_u_cargo.png, icon_module_u_salvage.png, icon_module_u_refine.png, icon_module_u_drones.png, icon_module_u_tractor.png, icon_module_u_holds.png (+ 18 16/48 splits)
- Note: 16 px readability regen: 12 glyphs collapsed to nearly solid squares at 16 px (alpha0 under 10 percent, h_plate_light and slot_c at 0) because their cut detail was a solid mass rather than an opening. The subject wording now specifies wide open slots and large negative-space openings so the silhouette survives the 16 px cut.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 twin targeting stack, two square reticle frames with large open centres stacked one above the other and joined by one bold side bracket; 2 electronic warfare suite, a square board with one large open square cut through its centre and three bold radiating jam bars projecting from its right edge; 3 nexus computer, a square board with one large open central square and four wide straight slots cut from its corners to its edges; 4 cargo expander, an open crate with a thick raised lid held on one bold latch and a wide open interior gap; 5 salvage rig, a heavy clamp claw with one straight handle and a bold open hook curling from its jaw; 6 ore refiner, a wide hopper funnel sitting on a squat drum with one bold output spout at the base and a large open funnel mouth; 7 drone bay, an open bay slot with two bold arrowhead drones racked side by side inside a wide open frame; 8 tractor emitter, a bold cone emitter projecting three wide parallel field bars from its open mouth; 9 hold expander, two stacked container blocks with a wide open rectangular gap cut between them and three bold vertical slots cut through each block. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_slots

- Date/time: 2026-09-18 11:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `48f81d0a6e1b385f551a1708ebc901a5` (elapsed 39.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-114324` keeps `job.json`
- Final files: icon_slot_engine.png, icon_slot_power.png, icon_slot_w.png, icon_slot_s.png, icon_slot_h.png, icon_slot_c.png, icon_slot_b.png, icon_slot_u.png (+ 16 16/48 splits)
- Note: 16 px readability regen: 12 glyphs collapsed to nearly solid squares at 16 px (alpha0 under 10 percent, h_plate_light and slot_c at 0) because their cut detail was a solid mass rather than an opening. The subject wording now specifies wide open slots and large negative-space openings so the silhouette survives the 16 px cut.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 4x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 an engine slot socket: one bold trapezoidal nozzle block on a flat mount plate with a wide open mouth cut at the exhaust end; 2 a power slot socket: a reactor core block with three wide vertical coil slots cut right through its face; 3 a weapon slot socket: a hardpoint mount plate with a wide open U-shaped jaw cut through its top edge and two bold side lugs; 4 a shield slot socket: a bold arc emitter half-ring set into a flat base plate, the arc open at the bottom; 5 an armour slot socket: three flat plates stacked in a clearly offset step with wide open gaps between the layers; 6 a computer slot socket: a square board frame with one large open square cut right through its centre and two bold corner notches; 7 a booster slot socket: a vent block carrying one bold open chevron burst cut right through it; 8 a utility slot socket: an open pod socket with a wide open mouth and a bold latch bracket across it. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_service_glyphs

- Date/time: 2026-09-18 11:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `14258c496e3f8e4edc4d99d98ac1d579` (elapsed 28.9s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_service_vault.png, icon_service_insurance.png, icon_service_bounty.png (+ 6 16/48 splits)
- Note: 16 px readability regen: 12 glyphs collapsed to nearly solid squares at 16 px (alpha0 under 10 percent, h_plate_light and slot_c at 0) because their cut detail was a solid mass rather than an opening. The subject wording now specifies wide open slots and large negative-space openings so the silhouette survives the 16 px cut.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 vault service: a heavy vault door slab carrying a bold open three-spoke wheel with the spaces between the spokes cut right through as large openings; 2 insurance service: a flat shield plate crossed by one horizontal seam with a rivet notch below it; 3 bounty service: a thick circular coin outline with a small square notch cut out of its rim and one short vertical tally mark cut inside it, unambiguously a coin and not a prohibition sign; 4 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_minerals_ore - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_mineral_iron.png, icon_mineral_copper.png, icon_mineral_chromium.png, icon_mineral_silicon.png, icon_mineral_aluminium.png, icon_mineral_titanium.png, icon_mineral_nickel.png, icon_mineral_cobalt.png, icon_mineral_tungsten.png, icon_mineral_silver.png, icon_mineral_gold.png, icon_mineral_platinum.png, icon_mineral_neodymium.png, icon_mineral_iridium.png, icon_mineral_osmium.png, icon_mineral_palladium.png, icon_mineral_cerulite.png, icon_mineral_emberite.png, icon_mineral_voidglass.png, icon_mineral_krilium.png (+ 40 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 5x4 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 raw iron ore, a heavy blocky chunk with three flat fracture faces, squat and dense; 2 raw copper ore, a chunky lump with a curled shard edge peeling off one side; 3 raw chromium ore, a slim elongated shard with one sharp tapered tip; 4 raw silicon ore, a flat wide wedge with one broad planar cleaved face and a knife edge; 5 raw aluminium ore, a thin wide flake with a feathered folded rim; 6 raw titanium ore, a stout nugget with five clean facets meeting at a single ridge; 7 raw nickel ore, an oblong lump carrying one flat band across its face; 8 raw cobalt ore, a small rounded lobe of mineral still locked in a square host-rock corner; 9 raw tungsten ore, a dense cube-faced chunk with one corner sheared away square; 10 raw silver ore, a pointed chunk sprouting three short needle crystals; 11 raw gold ore, a lumpy nugget with one rounded drooping edge read as sagging metal; 12 raw platinum ore, a layered flake-plate chunk with a stepped bright top face; 13 raw neodymium ore, a blocky matrix chunk holding one dark angular inclusion block; 14 raw iridium ore, a dense jagged shard barbed with short spikes on every side; 15 raw osmium ore, a squat heavy chunk with a chipped flat rim; 16 raw palladium ore, a slatted crystal chunk of three flat parallel blades; 17 raw cerulite ore, a shard cluster split by one raised vein ridge running its length; 18 raw emberite ore, a chunk cut through by a single deep internal fissure crack; 19 raw voidglass ore, a smooth curved shell shard with one hooked lip, glassier and rounder than every other ore; 20 raw krilium ore, an irregular asymmetric chunk with one long spike, visibly refusing the geometry of the others. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_minerals_ingot - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_ingot_iron.png, icon_ingot_copper.png, icon_ingot_chromium.png, icon_ingot_silicon.png, icon_ingot_aluminium.png, icon_ingot_titanium.png, icon_ingot_nickel.png, icon_ingot_cobalt.png, icon_ingot_tungsten.png, icon_ingot_silver.png, icon_ingot_gold.png, icon_ingot_platinum.png, icon_ingot_neodymium.png, icon_ingot_iridium.png, icon_ingot_osmium.png, icon_ingot_palladium.png, icon_ingot_cerulite.png, icon_ingot_emberite.png, icon_ingot_voidglass.png, icon_ingot_krilium.png (+ 40 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 5x4 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 refined iron ingot, a single stamped metal bar with a flat top face, a wide squat bar with one chiselled end; 2 refined copper ingot, a single stamped metal bar with a flat top face, a bar with a rounded end and one raised ridge line along the top; 3 refined chromium ingot, a single stamped metal bar with a flat top face, a slim long bar tapered at one end; 4 refined silicon ingot, a single stamped metal bar with a flat top face, a flat wide slab bar with a stepped top face; 5 refined aluminium ingot, a single stamped metal bar with a flat top face, a small neat bar with one folded corner tab; 6 refined titanium ingot, a single stamped metal bar with a flat top face, a stout bar struck twice with two parallel vertical marks; 7 refined nickel ingot, a single stamped metal bar with a flat top face, an oblong bar with one chamfered top corner; 8 refined cobalt ingot, a single stamped metal bar with a flat top face, a bar with a banded waist pinched at the middle; 9 refined tungsten ingot, a single stamped metal bar with a flat top face, a near-cubic heavy bar with one chiselled side notch; 10 refined silver ingot, a single stamped metal bar with a flat top face, a bar with a single fine hairline seam down the middle; 11 refined gold ingot, a single stamped metal bar with a flat top face, a bar carrying one lone centre punch mark; 12 refined platinum ingot, a single stamped metal bar with a flat top face, a bar with a stepped double top face; 13 refined neodymium ingot, a single stamped metal bar with a flat top face, a bar with a pair of crossed grooves cut across its top; 14 refined iridium ingot, a single stamped metal bar with a flat top face, a bar with one barbed end notch; 15 refined osmium ingot, a single stamped metal bar with a flat top face, a thick squat bar with a heavy chamfer on all four long edges; 16 refined palladium ingot, a single stamped metal bar with a flat top face, a bar with a lattice-pierced top face; 17 refined cerulite ingot, a single stamped metal bar with a flat top face, a bar with a single central ridge running its full length; 18 refined emberite ingot, a single stamped metal bar with a flat top face, a bar with a chiselled V groove notch cut into one end; 19 refined voidglass ingot, a single stamped metal bar with a flat top face, a bar with a concave scoop taken out of one end, glassier and rounder than the rest; 20 refined krilium ingot, a single stamped metal bar with a flat top face, a bar with a visibly warped irregular profile and one barb, refusing the geometry of the others. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_a - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_module_w_railgun.png, icon_module_w_mining.png, icon_module_s_light.png, icon_module_s_heavy.png, icon_module_s_ion.png, icon_module_h_plate_light.png, icon_module_h_plate_heavy.png, icon_module_h_composite.png, icon_module_p_std.png (+ 18 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 railgun hardpoint, a squared housing holding two long parallel rails that project forward past the muzzle, with a heavy rear breech block, shown right-facing in profile; 2 mining laser hardpoint, a short thick barrel ending in a three-pronged emitter claw, right-facing in profile; 3 light shield generator, a thin arc emitter half-ring sitting on two small anchor lugs; 4 heavy shield generator, a thick arc emitter half-ring with a doubled concentric band and four anchor lugs; 5 ion shield generator, an arc emitter half-ring carrying three short inner coil bars; 6 light armour plate, one flat rectangular plate seen square on with two large square notches cut out of its top and bottom edges and one wide diagonal slot cut right through the plate, so the shape reads as a plate and never as a filled square; 7 heavy armour plate, two stacked flat plates with a wide open gap cut between the two layers and three bold round rivet holes cut right through the upper plate; 8 composite armour plate, one flat plate cut through by a bold diagonal lattice of wide crossing bars, leaving large open square holes between them; 9 standard reactor core, a rectangular housing with three wide vertical slots cut right through its face and a stepped base mount plate. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_b - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_module_p_mk2.png, icon_module_p_core.png, icon_module_e_std.png, icon_module_e_ion.png, icon_module_e_vector.png, icon_module_b_afterburner.png, icon_module_b_fold.png, icon_module_c_target.png, icon_module_c_scanner.png (+ 18 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 upgraded reactor core, a rectangular housing with five wide vertical slots cut right through its face, a bold open cap block on top and a stepped base mount plate; 2 high-output power core, a hexagonal housing around one large open square core opening with four bold bolt notches cut at the corners; 3 standard drive nozzle, a truncated cone with one plain ring around its throat and a wide open mouth cut at the exhaust end; 4 ion drive nozzle, a truncated cone with a doubled ring around its throat, one bold short vane projecting from each side and a wide open mouth at the exhaust end; 5 vector drive nozzle, a truncated cone held in a gimbal yoke with two bold projecting actuator arms and a wide open mouth at the exhaust end; 6 afterburner booster, a vent block with three wide open chevron slots cut straight through its face; 7 fold drive booster, a square plate cut by one bold wide folded arrow-shaped slot straight through it, leaving a clear arrow-shaped opening; 8 targeting computer, a square boresight reticle frame with one large open square cut through its centre, a cross struck across the opening and one bold ranging tick on the lower edge; 9 scanner computer, a bold dish arc on a short stem with two wide concentric return arcs behind it. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_c - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_module_c_twin.png, icon_module_c_ewar.png, icon_module_c_nexus.png, icon_module_u_cargo.png, icon_module_u_salvage.png, icon_module_u_refine.png, icon_module_u_drones.png, icon_module_u_tractor.png, icon_module_u_holds.png (+ 18 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 twin targeting stack, two square reticle frames with large open centres stacked one above the other and joined by one bold side bracket; 2 electronic warfare suite, a square board with one large open square cut through its centre and three bold radiating jam bars projecting from its right edge; 3 nexus computer, a square board with one large open central square and four wide straight slots cut from its corners to its edges; 4 cargo expander, an open crate with a thick raised lid held on one bold latch and a wide open interior gap; 5 salvage rig, a heavy clamp claw with one straight handle and a bold open hook curling from its jaw; 6 ore refiner, a wide hopper funnel sitting on a squat drum with one bold output spout at the base and a large open funnel mouth; 7 drone bay, an open bay slot with two bold arrowhead drones racked side by side inside a wide open frame; 8 tractor emitter, a bold cone emitter projecting three wide parallel field bars from its open mouth; 9 hold expander, two stacked container blocks with a wide open rectangular gap cut between them and three bold vertical slots cut through each block. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_slots - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_slot_engine.png, icon_slot_power.png, icon_slot_w.png, icon_slot_s.png, icon_slot_h.png, icon_slot_c.png, icon_slot_b.png, icon_slot_u.png (+ 16 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 4x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 an engine slot socket: one bold trapezoidal nozzle block on a flat mount plate with a wide open mouth cut at the exhaust end; 2 a power slot socket: a reactor core block with three wide vertical coil slots cut right through its face; 3 a weapon slot socket: a hardpoint mount plate with a wide open U-shaped jaw cut through its top edge and two bold side lugs; 4 a shield slot socket: a bold arc emitter half-ring set into a flat base plate, the arc open at the bottom; 5 an armour slot socket: three flat plates stacked in a clearly offset step with wide open gaps between the layers; 6 a computer slot socket: a square board frame with one large open square cut right through its centre and two bold corner notches; 7 a booster slot socket: a vent block carrying one bold open chevron burst cut right through it; 8 a utility slot socket: an open pod socket with a wide open mouth and a bold latch bracket across it. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_contracts - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_contract_haul.png, icon_contract_hunt.png, icon_contract_gather.png, icon_contract_escort.png, icon_contract_expedition.png (+ 10 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 haul contract: a closed crate sitting on a two-wheeled pallet bar; 2 hunt contract: a crosshair reticle centred on a downward pointing chevron target; 3 gather contract: a two-jaw claw gripping a faceted rock chunk; 4 escort contract: two chevrons travelling in column inside a squared bracket; 5 expedition contract: a ring with one bold arrow projecting outward from its rim; 6 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_service_glyphs - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_service_vault.png, icon_service_insurance.png, icon_service_bounty.png (+ 6 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 vault service: a heavy vault door slab carrying a bold open three-spoke wheel with the spaces between the spokes cut right through as large openings; 2 insurance service: a flat shield plate crossed by one horizontal seam with a rivet notch below it; 3 bounty service: a thick circular coin outline with a small square notch cut out of its rim and one short vertical tally mark cut inside it, unambiguously a coin and not a prohibition sign; 4 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_faction_insignia - post-only re-cut

- Date/time: 2026-09-18 11:45 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_insignia_concord.png, icon_insignia_meridian.png, icon_insignia_choir.png (+ 6 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 Concord of Iron emblem: a hex plate carrying three stacked horizontal plate bars; 2 Meridian Free Ports emblem: a hex plate split by one diagonal dock seam with a small pod block docked on the seam; 3 Ember Choir emblem: a hex plate carrying a three-tongued radial flame; 4 an empty blank white cell, leave the last cell completely blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_minerals_ore - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-111209`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-111209` keeps `job.json`
- Final files: icon_mineral_iron.png, icon_mineral_copper.png, icon_mineral_chromium.png, icon_mineral_silicon.png, icon_mineral_aluminium.png, icon_mineral_titanium.png, icon_mineral_nickel.png, icon_mineral_cobalt.png, icon_mineral_tungsten.png, icon_mineral_silver.png, icon_mineral_gold.png, icon_mineral_platinum.png, icon_mineral_neodymium.png, icon_mineral_iridium.png, icon_mineral_osmium.png, icon_mineral_palladium.png, icon_mineral_cerulite.png, icon_mineral_emberite.png, icon_mineral_voidglass.png, icon_mineral_krilium.png (+ 40 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 5x4 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 raw iron ore, a heavy blocky chunk with three flat fracture faces, squat and dense; 2 raw copper ore, a chunky lump with a curled shard edge peeling off one side; 3 raw chromium ore, a slim elongated shard with one sharp tapered tip; 4 raw silicon ore, a flat wide wedge with one broad planar cleaved face and a knife edge; 5 raw aluminium ore, a thin wide flake with a feathered folded rim; 6 raw titanium ore, a stout nugget with five clean facets meeting at a single ridge; 7 raw nickel ore, an oblong lump carrying one flat band across its face; 8 raw cobalt ore, a small rounded lobe of mineral still locked in a square host-rock corner; 9 raw tungsten ore, a dense cube-faced chunk with one corner sheared away square; 10 raw silver ore, a pointed chunk sprouting three short needle crystals; 11 raw gold ore, a lumpy nugget with one rounded drooping edge read as sagging metal; 12 raw platinum ore, a layered flake-plate chunk with a stepped bright top face; 13 raw neodymium ore, a blocky matrix chunk holding one dark angular inclusion block; 14 raw iridium ore, a dense jagged shard barbed with short spikes on every side; 15 raw osmium ore, a squat heavy chunk with a chipped flat rim; 16 raw palladium ore, a slatted crystal chunk of three flat parallel blades; 17 raw cerulite ore, a shard cluster split by one raised vein ridge running its length; 18 raw emberite ore, a chunk cut through by a single deep internal fissure crack; 19 raw voidglass ore, a smooth curved shell shard with one hooked lip, glassier and rounder than every other ore; 20 raw krilium ore, an irregular asymmetric chunk with one long spike, visibly refusing the geometry of the others. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_minerals_ingot - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-111243`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-111243` keeps `job.json`
- Final files: icon_ingot_iron.png, icon_ingot_copper.png, icon_ingot_chromium.png, icon_ingot_silicon.png, icon_ingot_aluminium.png, icon_ingot_titanium.png, icon_ingot_nickel.png, icon_ingot_cobalt.png, icon_ingot_tungsten.png, icon_ingot_silver.png, icon_ingot_gold.png, icon_ingot_platinum.png, icon_ingot_neodymium.png, icon_ingot_iridium.png, icon_ingot_osmium.png, icon_ingot_palladium.png, icon_ingot_cerulite.png, icon_ingot_emberite.png, icon_ingot_voidglass.png, icon_ingot_krilium.png (+ 40 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 5x4 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 refined iron ingot, a single stamped metal bar with a flat top face, a wide squat bar with one chiselled end; 2 refined copper ingot, a single stamped metal bar with a flat top face, a bar with a rounded end and one raised ridge line along the top; 3 refined chromium ingot, a single stamped metal bar with a flat top face, a slim long bar tapered at one end; 4 refined silicon ingot, a single stamped metal bar with a flat top face, a flat wide slab bar with a stepped top face; 5 refined aluminium ingot, a single stamped metal bar with a flat top face, a small neat bar with one folded corner tab; 6 refined titanium ingot, a single stamped metal bar with a flat top face, a stout bar struck twice with two parallel vertical marks; 7 refined nickel ingot, a single stamped metal bar with a flat top face, an oblong bar with one chamfered top corner; 8 refined cobalt ingot, a single stamped metal bar with a flat top face, a bar with a banded waist pinched at the middle; 9 refined tungsten ingot, a single stamped metal bar with a flat top face, a near-cubic heavy bar with one chiselled side notch; 10 refined silver ingot, a single stamped metal bar with a flat top face, a bar with a single fine hairline seam down the middle; 11 refined gold ingot, a single stamped metal bar with a flat top face, a bar carrying one lone centre punch mark; 12 refined platinum ingot, a single stamped metal bar with a flat top face, a bar with a stepped double top face; 13 refined neodymium ingot, a single stamped metal bar with a flat top face, a bar with a pair of crossed grooves cut across its top; 14 refined iridium ingot, a single stamped metal bar with a flat top face, a bar with one barbed end notch; 15 refined osmium ingot, a single stamped metal bar with a flat top face, a thick squat bar with a heavy chamfer on all four long edges; 16 refined palladium ingot, a single stamped metal bar with a flat top face, a bar with a lattice-pierced top face; 17 refined cerulite ingot, a single stamped metal bar with a flat top face, a bar with a single central ridge running its full length; 18 refined emberite ingot, a single stamped metal bar with a flat top face, a bar with a chiselled V groove notch cut into one end; 19 refined voidglass ingot, a single stamped metal bar with a flat top face, a bar with a concave scoop taken out of one end, glassier and rounder than the rest; 20 refined krilium ingot, a single stamped metal bar with a flat top face, a bar with a visibly warped irregular profile and one barb, refusing the geometry of the others. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_a - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114107`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114107` keeps `job.json`
- Final files: icon_module_w_railgun.png, icon_module_w_mining.png, icon_module_s_light.png, icon_module_s_heavy.png, icon_module_s_ion.png, icon_module_h_plate_light.png, icon_module_h_plate_heavy.png, icon_module_h_composite.png, icon_module_p_std.png (+ 18 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 railgun hardpoint, a squared housing holding two long parallel rails that project forward past the muzzle, with a heavy rear breech block, shown right-facing in profile; 2 mining laser hardpoint, a short thick barrel ending in a three-pronged emitter claw, right-facing in profile; 3 light shield generator, a thin arc emitter half-ring sitting on two small anchor lugs; 4 heavy shield generator, a thick arc emitter half-ring with a doubled concentric band and four anchor lugs; 5 ion shield generator, an arc emitter half-ring carrying three short inner coil bars; 6 light armour plate, one flat rectangular plate seen square on with two large square notches cut out of its top and bottom edges and one wide diagonal slot cut right through the plate, so the shape reads as a plate and never as a filled square; 7 heavy armour plate, two stacked flat plates with a wide open gap cut between the two layers and three bold round rivet holes cut right through the upper plate; 8 composite armour plate, one flat plate cut through by a bold diagonal lattice of wide crossing bars, leaving large open square holes between them; 9 standard reactor core, a rectangular housing with three wide vertical slots cut right through its face and a stepped base mount plate. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_b - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114156`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114156` keeps `job.json`
- Final files: icon_module_p_mk2.png, icon_module_p_core.png, icon_module_e_std.png, icon_module_e_ion.png, icon_module_e_vector.png, icon_module_b_afterburner.png, icon_module_b_fold.png, icon_module_c_target.png, icon_module_c_scanner.png (+ 18 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 upgraded reactor core, a rectangular housing with five wide vertical slots cut right through its face, a bold open cap block on top and a stepped base mount plate; 2 high-output power core, a hexagonal housing around one large open square core opening with four bold bolt notches cut at the corners; 3 standard drive nozzle, a truncated cone with one plain ring around its throat and a wide open mouth cut at the exhaust end; 4 ion drive nozzle, a truncated cone with a doubled ring around its throat, one bold short vane projecting from each side and a wide open mouth at the exhaust end; 5 vector drive nozzle, a truncated cone held in a gimbal yoke with two bold projecting actuator arms and a wide open mouth at the exhaust end; 6 afterburner booster, a vent block with three wide open chevron slots cut straight through its face; 7 fold drive booster, a square plate cut by one bold wide folded arrow-shaped slot straight through it, leaving a clear arrow-shaped opening; 8 targeting computer, a square boresight reticle frame with one large open square cut through its centre, a cross struck across the opening and one bold ranging tick on the lower edge; 9 scanner computer, a bold dish arc on a short stem with two wide concentric return arcs behind it. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_panel_modules_c - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114240`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114240` keeps `job.json`
- Final files: icon_module_c_twin.png, icon_module_c_ewar.png, icon_module_c_nexus.png, icon_module_u_cargo.png, icon_module_u_salvage.png, icon_module_u_refine.png, icon_module_u_drones.png, icon_module_u_tractor.png, icon_module_u_holds.png (+ 18 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 twin targeting stack, two square reticle frames with large open centres stacked one above the other and joined by one bold side bracket; 2 electronic warfare suite, a square board with one large open square cut through its centre and three bold radiating jam bars projecting from its right edge; 3 nexus computer, a square board with one large open central square and four wide straight slots cut from its corners to its edges; 4 cargo expander, an open crate with a thick raised lid held on one bold latch and a wide open interior gap; 5 salvage rig, a heavy clamp claw with one straight handle and a bold open hook curling from its jaw; 6 ore refiner, a wide hopper funnel sitting on a squat drum with one bold output spout at the base and a large open funnel mouth; 7 drone bay, an open bay slot with two bold arrowhead drones racked side by side inside a wide open frame; 8 tractor emitter, a bold cone emitter projecting three wide parallel field bars from its open mouth; 9 hold expander, two stacked container blocks with a wide open rectangular gap cut between them and three bold vertical slots cut through each block. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p0_slots - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114324`
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-114324` keeps `job.json`
- Final files: icon_slot_engine.png, icon_slot_power.png, icon_slot_w.png, icon_slot_s.png, icon_slot_h.png, icon_slot_c.png, icon_slot_b.png, icon_slot_u.png (+ 16 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 4x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 an engine slot socket: one bold trapezoidal nozzle block on a flat mount plate with a wide open mouth cut at the exhaust end; 2 a power slot socket: a reactor core block with three wide vertical coil slots cut right through its face; 3 a weapon slot socket: a hardpoint mount plate with a wide open U-shaped jaw cut through its top edge and two bold side lugs; 4 a shield slot socket: a bold arc emitter half-ring set into a flat base plate, the arc open at the bottom; 5 an armour slot socket: three flat plates stacked in a clearly offset step with wide open gaps between the layers; 6 a computer slot socket: a square board frame with one large open square cut right through its centre and two bold corner notches; 7 a booster slot socket: a vent block carrying one bold open chevron burst cut right through it; 8 a utility slot socket: an open pod socket with a wide open mouth and a bold latch bracket across it. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_contracts - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-112903`
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-112903` keeps `job.json`
- Final files: icon_contract_haul.png, icon_contract_hunt.png, icon_contract_gather.png, icon_contract_escort.png, icon_contract_expedition.png (+ 10 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 haul contract: a closed crate sitting on a two-wheeled pallet bar; 2 hunt contract: a crosshair reticle centred on a downward pointing chevron target; 3 gather contract: a two-jaw claw gripping a faceted rock chunk; 4 escort contract: two chevrons travelling in column inside a squared bracket; 5 expedition contract: a ring with one bold arrow projecting outward from its rim; 6 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_service_glyphs - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-114358`
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-114358` keeps `job.json`
- Final files: icon_service_vault.png, icon_service_insurance.png, icon_service_bounty.png (+ 6 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 vault service: a heavy vault door slab carrying a bold open three-spoke wheel with the spaces between the spokes cut right through as large openings; 2 insurance service: a flat shield plate crossed by one horizontal seam with a rivet notch below it; 3 bounty service: a thick circular coin outline with a small square notch cut out of its rim and one short vertical tally mark cut inside it, unambiguously a coin and not a prohibition sign; 4 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_faction_insignia - post-only re-cut

- Date/time: 2026-09-18 11:46 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-113435`
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-113435` keeps `job.json`
- Final files: icon_insignia_concord.png, icon_insignia_meridian.png, icon_insignia_choir.png (+ 6 16/48 splits)
- Note: free re-cut of the stored master: panels now split on their declared grid (deterministic, ICONS_SPEC section 5) instead of component splitting, which had fragmented the twin reticle glyph into a 102 px sliver. Re-run after find_master was corrected to match the whole subject.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 Concord of Iron emblem: a hex plate carrying three stacked horizontal plate bars; 2 Meridian Free Ports emblem: a hex plate split by one diagonal dock seam with a small pod block docked on the seam; 3 Ember Choir emblem: a hex plate carrying a three-tongued radial flame; 4 an empty blank white cell, leave the last cell completely blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## p2_contracts

- Date/time: 2026-09-18 11:47 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `5e74383dbfc657642d766bb1d8a64ff2` (elapsed 39.4s)
- Style block: `style-block.txt` verbatim as the prompt preamble (see the ICONS_SPEC section 8 note)
- Reference: none (text-to-image)
- Alpha: native-alpha, component split; run folder `20260918-114723` keeps `job.json`
- Final files: icon_contract_haul.png, icon_contract_hunt.png, icon_contract_gather.png, icon_contract_escort.png, icon_contract_expedition.png (+ 10 16/48 splits)
- Note: style-first pass: p2_contracts was first generated before the flat icon sheets moved the style block to the prompt preamble, so the run is repeated to keep the stored prompt, the log and the shipped art in agreement.
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 haul contract: a closed crate sitting on a two-wheeled pallet bar; 2 hunt contract: a crosshair reticle centred on a downward pointing chevron target; 3 gather contract: a two-jaw claw gripping a faceted rock chunk; 4 escort contract: two chevrons travelling in column inside a squared bracket; 5 expedition contract: a ring with one bold arrow projecting outward from its rim; 6 an empty blank white cell, leave the last cell completely empty and blank. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## f1_data_core

- Date/time: 2026-09-18 12:31 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `a7fa11816006729766a91ba486226f48` (elapsed 40.1s)
- Style block: `style-block.txt` verbatim as the prompt preamble (see the ICONS_SPEC section 8 note)
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-123143` keeps `job.json`
- Final files: icon_cargo_data_core.png (+ 4 size cuts)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 1x1 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: a single data core slab, frontal flat view: a plain square slab drawn as a THIN OUTLINE with a uniform 1.5 px-equivalent stroke, one small square inset centred inside it drawn the same weight with a wide clear gap of white between the inset and the outer slab edge, and two small rectangular notches cut out of the slab's top-left and bottom-right corners. Only two interior cuts in total, large open negative space, the whole silhouette clear of the cell edges with a generous even white margin on every side so the glyph reads as an outline square at 16 px and never as a solid block. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## f1_glyph_outline

- Date/time: 2026-09-18 12:32 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `9f6de4288d168281622a9aedf7283ac7` (elapsed 29.1s)
- Style block: `style-block.txt` verbatim as the prompt preamble (see the ICONS_SPEC section 8 note)
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-123214` keeps `job.json`
- Final files: icon_zoom_plus.png, icon_zoom_minus.png, icon_credits.png, icon_shield.png (+ 16 size cuts)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 a zoom-in glyph: a square magnifier outline with a plus built from two crossing bars inside, 2 a zoom-out glyph: the same square magnifier outline with a single horizontal bar inside, 3 a credits glyph: a hexagonal coin outline with a plain vertical bar struck through its centre, 4 a shield glyph: a flat heater-shield outline with a single vertical centre seam. Every stroke of every glyph is drawn at a uniform THICK weight of at least 2 px at 16 px final size, that is about three times the stroke of the thinnest hairlines, so each stroke still thresholds to solid iron black when the sheet is reduced to 16 px, with no grey or broken hairlines anywhere. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---

## f2_glyph_heavy

- Date/time: 2026-09-18 13:30 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `40396362cb7bb685c213b7159bb5ab7d` (elapsed 29.9s)
- Style block: `style-block.txt` verbatim as the prompt preamble (see the ICONS_SPEC section 8 note)
- Reference: none (text-to-image)
- Alpha: native-alpha, grid split; run folder `20260918-133035` keeps `job.json`
- Final files: icon_zoom_plus.png, icon_zoom_minus.png, icon_credits.png, icon_shield.png (+ 16 size cuts)
- Status: success

Full SUBJECT text:

> flat vector icon sheet, 2x2 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 a zoom-in glyph: a square magnifier outline with a plus built from two crossing bars inside, 2 a zoom-out glyph: the same square magnifier outline with a single horizontal bar inside, 3 a credits glyph: a hexagonal coin outline with a plain vertical bar struck through its centre, 4 a shield glyph: a flat heater-shield outline with a single vertical centre seam. EVERY STROKE IS HEAVY AND CHUNKY: each stroke is a bold bar at least 3 px wide at 16 px final size, that is about one fifth of the glyph's own width, drawn like a heavy stencil or a bold road sign; the strokes are as thick as the negative space they enclose, the enclosed white gaps stay wide and open, corners are hard mitred, no taper and no rounded ends FINAL STROKE OVERRIDE - for this sheet only, ignore every 1.5 px-equivalent, thin, hairline or fine-line stroke instruction anywhere above, including the 1.5 px-equivalent sentence inside the flat-vector override block: on THIS sheet every stroke, outline and bar of every glyph is a HEAVY BOLD BAR at least 3 px wide at 16 px final size, about one fifth of the glyph's own width and roughly twice a normal outline pictogram, drawn like a heavy stencil or a bold road sign. The strokes are as thick as the white negative space they enclose, every weight is uniform along its length, corners are hard mitred, no taper and no rounded ends. This heavy weight is the point of the sheet: when it is reduced to 16 px every stroke must still cover whole pixels and read as solid iron black, never as a grey, broken or hairy line.. STRICT FLAT-VECTOR OVERRIDE - this overrides every painted, realistic, metallic or photographic instruction anywhere in this prompt: this is a FLAT 2D VECTOR STENCIL SHEET, not a render, not a photograph, not a 3D object and not painted metal. Every icon is ONE FLAT SINGLE-COLOUR SILHOUETTE in iron black #232629 on a PLAIN PURE SOLID WHITE background, exactly like a pictogram set or a stencil sheet. Absolutely no lighting, no shading, no gradient, no bevel, no emboss, no specular highlight, no reflection, no material texture, no scratches, no weathering, no grime, no rust, no rivet texture, no 3D depth, no cast or drop shadow, no film grain, no glow, no ember, no orange, no burnt ember #C8461B, no ember glow #E8703A and no warm colour of any kind anywhere in the image. The background is pure white #FFFFFF and never black, never void, never a space scene and never starry. Interior detail is expressed only as flat negative-space cut-outs and uniform 1.5 px-equivalent straight strokes. Hard mitred corners, corner radius zero, no rounded corners, no rounded stroke ends, no tapering. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour, no rounded corners, no rounded stroke ends, no tapering strokes.

---


## f2 post-passes (C2b) - free, local, no API call

- Date/time: 2026-09-18 13:58 local
- `thicken_master.py` dilated the four F.2 glyph masters by a disk until the 16 px cut's
  measured stroke reached 2.5 px: zoom_plus r=10 (2.5 px, solid 0.473, enclosed hole 16 px),
  zoom_minus r=12 (3.5 px, 0.500, 28), credits r=23 (3.0 px, 0.488, 24), shield r=12
  (3.0 px, 0.420, 28). Radii that would close the negative space below a 4x4 opening or push
  coverage past 0.85 were refused and are listed in `thicken_report.json`.
- `recut_quartet.py --families icon_zoom_plus,icon_zoom_minus,icon_credits,icon_shield --apply`
  re-cut the quartet (contain-fit) from the thickened masters; the replaced cuts are in
  `_f2_backup/` (their F.1 predecessors in `_cut_backup/`).
- `tools/derive_icon_tints.gd` re-derived all 556 tint stencils (16 of them changed).
- Import: the 16 cuts and their 16 stencils were reimported. Outcomes: ICONS_SPEC section 9.8.
