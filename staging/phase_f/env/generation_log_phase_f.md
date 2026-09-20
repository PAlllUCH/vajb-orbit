# Phase F - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`; `flare-i2i` for reference edits), 2K.
Work order: `docs/gameplay/16_art_design_brief.md`. Style law: `docs/design/STYLE_BIBLE.md`, `docs/design/ICONS_SPEC.md` (section 1 + section 8 amendment), `docs/design/SHIPS_SPEC.md` (section 1 framing constant, sections 3.7-3.9).
Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file` on every run.
Price basis: 10 credits = $0.05 per 2K run (kie.ai console, user-verified); the script's printed 30-credit estimate is the stale hint and the `usage-ledger.jsonl` total over-reports 3x.
Alpha: `--transparent` native first, local matte fallback (`staging/phase_d/reprocess.py`). FX stay RGB on void black for additive blending and are never alpha-keyed (FX_SPEC 0.1).
AI-generated art is not CC0 (AGENTS.md).

---

## sector_1_bg

- Date/time: 2026-09-18 11:17 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `caa7b00db93c54710efa50cbf664de1e` (elapsed 34.8s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-111724` keeps `job.json`
- Final files: env_sector_1_bg.png
- Status: success

Full SUBJECT text:

> Sector backdrop plate, a wide 16:9 cinematic top-down orthographic painted plate for a space playfield background, no interface elements baked in, no markers, no nodes, no lines, no text, no logos, no ships, no wreck hulks, no stations, no asteroids in the frame centre. Subject: Halcyon Reach, ordered home space under Concord of Iron law: a tidy, orderly outer-system vista: a faint distant star band along the very top edge, sparse even starfield, a single distant small patrol beacon lamp, calm flat deep void blue #111823 wash with almost no dust structure, everything quiet, empty and legible, absolutely nothing crossing the centre of the frame. Composition: extremely low contrast, one value step darker than ships, the centre of the frame stays the quietest and darkest region so gameplay and interface read on top of it, with all interest pushed toward the frame edges and corners. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## sector_2_bg

- Date/time: 2026-09-18 11:18 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `587f8ab1c2e2ef9d26ed39a5f8dd97a5` (elapsed 63.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-111829` keeps `job.json`
- Final files: env_sector_2_bg.png
- Status: success

Full SUBJECT text:

> Sector backdrop plate, a wide 16:9 cinematic top-down orthographic painted plate for a space playfield background, no interface elements baked in, no markers, no nodes, no lines, no text, no logos, no ships, no wreck hulks, no stations, no asteroids in the frame centre. Subject: Iron Marches, the industrial belt: an industrial belt backdrop: a very faint distant ore-dust haze band low across the frame, a wide drifting veil of grimy umber #4A423B dust pushed to the lower left corner, faint long straight shadow bands read as the edge of a distant rock field, deep void blue #111823 and void haze #1A2230 washes, workmanlike and drab. Composition: extremely low contrast, one value step darker than ships, the centre of the frame stays the quietest and darkest region so gameplay and interface read on top of it, with all interest pushed toward the frame edges and corners. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## sector_3_bg

- Date/time: 2026-09-18 11:19 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `e645a71102c99c2d8883122933a22dac` (elapsed 27.1s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-111858` keeps `job.json`
- Final files: env_sector_3_bg.png
- Status: success

Full SUBJECT text:

> Sector backdrop plate, a wide 16:9 cinematic top-down orthographic painted plate for a space playfield background, no interface elements baked in, no markers, no nodes, no lines, no text, no logos, no ships, no wreck hulks, no stations, no asteroids in the frame centre. Subject: Meridian Span, the trade crossroads: a crossroads backdrop: one wide very faint grey-blue nebula wash drifting across the upper right corner, a sparse lane of slightly brighter stars running diagonally as if a well travelled route, faint dust veils in void haze #1A2230 over deep void blue #111823, mild and open, no focal shapes. Composition: extremely low contrast, one value step darker than ships, the centre of the frame stays the quietest and darkest region so gameplay and interface read on top of it, with all interest pushed toward the frame edges and corners. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## sector_4_bg

- Date/time: 2026-09-18 11:19 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `6aaa2fb7b389726d801487aacc607019` (elapsed 27.0s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-111927` keeps `job.json`
- Final files: env_sector_4_bg.png
- Status: success

Full SUBJECT text:

> Sector backdrop plate, a wide 16:9 cinematic top-down orthographic painted plate for a space playfield background, no interface elements baked in, no markers, no nodes, no lines, no text, no logos, no ships, no wreck hulks, no stations, no asteroids in the frame centre. Subject: Ashveil Expanse, the contested edge: a contested frontier backdrop: a torn veil of dark ash-grey dust drifting in bands across the frame with ragged frayed edges, a faint ashen haze in void haze #1A2230 and grimy umber #4A423B over void black #0A0E14, faint cinder-dark smoke wisps far off in the lower right, unsettled and scuffed, no ships, no fire. Composition: extremely low contrast, one value step darker than ships, the centre of the frame stays the quietest and darkest region so gameplay and interface read on top of it, with all interest pushed toward the frame edges and corners. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## sector_5_bg

- Date/time: 2026-09-18 11:19 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `0078d4160a6e62b3e0f6388bb700be4b` (elapsed 27.4s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-111956` keeps `job.json`
- Final files: env_sector_5_bg.png
- Status: success

Full SUBJECT text:

> Sector backdrop plate, a wide 16:9 cinematic top-down orthographic painted plate for a space playfield background, no interface elements baked in, no markers, no nodes, no lines, no text, no logos, no ships, no wreck hulks, no stations, no asteroids in the frame centre. Subject: Cinder Verge, exotic territory: an exotic verge backdrop: warm rusted ochre #6E5B4A and dry rust #8A6A50 mineral dust drifting in a broad low arc across the lower third of the frame, faint cracked-rock sheen suggested at the extreme left and right edges only, deep void blue #111823 base with void haze #1A2230 veils, strange and warm but never glowing, absolutely no ember or orange light anywhere. Composition: extremely low contrast, one value step darker than ships, the centre of the frame stays the quietest and darkest region so gameplay and interface read on top of it, with all interest pushed toward the frame edges and corners. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## sector_6_bg

- Date/time: 2026-09-18 11:20 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `c965e52c750baf72f8f20d679d131f42` (elapsed 27.1s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-112024` keeps `job.json`
- Final files: env_sector_6_bg.png
- Status: success

Full SUBJECT text:

> Sector backdrop plate, a wide 16:9 cinematic top-down orthographic painted plate for a space playfield background, no interface elements baked in, no markers, no nodes, no lines, no text, no logos, no ships, no wreck hulks, no stations, no asteroids in the frame centre. Subject: The Hollows, the deep exotic belt: a deep-belt backdrop: a heavy very dark dust density with long slow veils of void haze #1A2230 and faint grimy umber #4A423B, sparse stars almost extinguished, one very faint cold pale steel highlight #565C63 sheen along the top-left corner reading as a distant hard-lit body limb with no atmosphere, oppressive and close, extremely low contrast, nothing in the frame centre. Composition: extremely low contrast, one value step darker than ships, the centre of the frame stays the quietest and darkest region so gameplay and interface read on top of it, with all interest pushed toward the frame edges and corners. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## sector_7_bg

- Date/time: 2026-09-18 11:20 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `adbcf38a7e0c23974da0ea4548fbdf1a` (elapsed 27.1s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-112053` keeps `job.json`
- Final files: env_sector_7_bg.png
- Status: success

Full SUBJECT text:

> Sector backdrop plate, a wide 16:9 cinematic top-down orthographic painted plate for a space playfield background, no interface elements baked in, no markers, no nodes, no lines, no text, no logos, no ships, no wreck hulks, no stations, no asteroids in the frame centre. Subject: Maw Belt, unaligned, no law, the arena: a lawless arena belt backdrop: a scarred battlefield void, torn plating silhouettes and debris shards suggested only as near-black iron black #232629 shapes hugging the frame edges and corners, faint scorch smudging and soot-blackened streaks, broken hull ribs half swallowed by the dark, the rest deep void black #0A0E14 and deep void blue #111823, hostile and abandoned, the frame centre completely empty and dark, absolutely no emissive light, no glow, no ember and no warm colour anywhere. Composition: extremely low contrast, one value step darker than ships, the centre of the frame stays the quietest and darkest region so gameplay and interface read on top of it, with all interest pushed toward the frame edges and corners. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## env_jump_gate_ring

- Date/time: 2026-09-18 11:21 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `c89cb9178ce21eab4b677a706291a814` (elapsed 37.7s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#030A10 alpha0=75% dropped=181; run folder `20260918-112132` keeps `job.json`
- Final files: env_jump_gate_ring.png
- Status: success

Full SUBJECT text:

> Jump gate ring, one single centred top-down orthographic render of a large radial gate structure, the structure occupying about 70 percent of the frame width, radially symmetric, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Structure: a very large segmented open ring of heavy welded platework, the ring visibly built from bolted arc segments with wide plate seams and rivet lines, and four massive square engine blocks clamped to the ring at the four diagonal stations, each block carrying a deep recessed vent grille, so the silhouette reads as four heavy masses ringing an open aperture. The aperture interior is completely empty: no energy field, no glow, no beam, no portal, no fill. Platework in gunmetal mid #3A3F46 and gunmetal dark #2B2F35 with heavy hull grime films, rust streaks bleeding from the segment seams, pitted metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember #C8461B warning lamps only, a handful of lamp points along the ring and one on each engine block, no ember glow halo, no aperture glow. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## env_arena_props

- Date/time: 2026-09-18 11:24 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1077d533734006972d8f7dd4cdf06c9e` (elapsed 34.3s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#02070D alpha0=85% dropped=161, grid split; run folder `20260918-112357` keeps `job.json`
- Final files: env_arena_nav_pylon.png, env_arena_barricade.png
- Status: success

Full SUBJECT text:

> Arena prop sheet, two separate structures in an evenly spaced 1x2 grid (two columns, one row) with a generous gap, left to right, each structure isolated on a plain solid pure white background with empty white margins between them so they can be cut apart, no grid lines, no labels, no text, no shadows on the background, the two structures never touching. Every structure is a top-down orthographic painted render, one value step darker than ships, weathered gunmetal and rusted steel with scratches, hull grime, oil stains, rust streaks, pitted metal, cold steel highlight #565C63 rim on the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Subjects in reading order: 1 an arena nav pylon, a short heavy pylon post on a wide anchor base with a stacked ring beacon head at its top and small hot burnt ember #C8461B lamps set in the ring, a single isolated pylon with no fence and no wire; 2 an arena barricade, a run of three bolted armour plates on two short posts with a segmented top rail and hazard-scored diagonal weld seams across the plate faces, no lamps, no glow, no ember. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## sector_1_bg

- Date/time: 2026-09-18 11:31 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `060d16b8dd2d42f5a6db9ebf77283493` (elapsed 27.7s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-113137` keeps `job.json`
- Final files: env_sector_1_bg.png
- Note: backdrop regen: pass 1 (sectors 1/2/4/7) returned focal objects despite the negative list (sector 1 a docked station and ships, sector 2 a strongly lit body limb, sector 4 an over-warm dust band, sector 7 a large structure crossing the frame). The subject was rewritten as a near-empty plate whose identity is colour and haze density only.
- Status: success

Full SUBJECT text:

> Sector backdrop plate for a space playfield, a single wide 16:9 full-frame painterly wash of empty deep space. The plate is ALMOST EMPTY: soft drifting haze, dust veils and a sparse faint starfield only, spread across the whole frame, with no focal point anywhere. Absolutely no stations, no ships, no wrecks, no debris, no asteroids, no planets, no moons, no atmospheric limbs, no rings, no structures, no silhouettes, no hard shapes and no objects of any kind; nothing crosses the frame and nothing sits centred or off-centre as a subject. Extremely low contrast, one value step darker than ships and never brighter than a whisper, so gameplay and interface elements read on top of it; the frame centre is the quietest and darkest region. Sector identity is carried only by colour and haze density: Halcyon Reach, ordered home space under Concord of Iron law: even, calm and orderly - a uniform very dark deep void blue #111823 field with a sparse even faint starfield and almost no dust structure at all, one very faint cool steel-grey wash toward the upper edge. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures. no space station, no docking ring, no ship, no hull, no wreck, no planet, no moon, no body limb, no torch light, no lamp and no glowing point of any kind.

---

## sector_2_bg

- Date/time: 2026-09-18 11:32 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `4af81e6667bde196511f8ee283544e23` (elapsed 27.2s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-113206` keeps `job.json`
- Final files: env_sector_2_bg.png
- Note: backdrop regen: pass 1 (sectors 1/2/4/7) returned focal objects despite the negative list (sector 1 a docked station and ships, sector 2 a strongly lit body limb, sector 4 an over-warm dust band, sector 7 a large structure crossing the frame). The subject was rewritten as a near-empty plate whose identity is colour and haze density only.
- Status: success

Full SUBJECT text:

> Sector backdrop plate for a space playfield, a single wide 16:9 full-frame painterly wash of empty deep space. The plate is ALMOST EMPTY: soft drifting haze, dust veils and a sparse faint starfield only, spread across the whole frame, with no focal point anywhere. Absolutely no stations, no ships, no wrecks, no debris, no asteroids, no planets, no moons, no atmospheric limbs, no rings, no structures, no silhouettes, no hard shapes and no objects of any kind; nothing crosses the frame and nothing sits centred or off-centre as a subject. Extremely low contrast, one value step darker than ships and never brighter than a whisper, so gameplay and interface elements read on top of it; the frame centre is the quietest and darkest region. Sector identity is carried only by colour and haze density: Iron Marches, the industrial belt: industrial and drab - a broad soft veil of grimy umber #4A423B dust hung low across the lower half only, grey and brown and fully desaturated, drifting in thin uncounted layers, over a sparse even faint starfield. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures. no space station, no docking ring, no ship, no hull, no wreck, no planet, no moon, no body limb, no torch light, no lamp and no glowing point of any kind.

---

## sector_4_bg

- Date/time: 2026-09-18 11:32 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `774e189d42cc6ca71a4a5ae022438a18` (elapsed 42.7s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-113251` keeps `job.json`
- Final files: env_sector_4_bg.png
- Note: backdrop regen: pass 1 (sectors 1/2/4/7) returned focal objects despite the negative list (sector 1 a docked station and ships, sector 2 a strongly lit body limb, sector 4 an over-warm dust band, sector 7 a large structure crossing the frame). The subject was rewritten as a near-empty plate whose identity is colour and haze density only.
- Status: success

Full SUBJECT text:

> Sector backdrop plate for a space playfield, a single wide 16:9 full-frame painterly wash of empty deep space. The plate is ALMOST EMPTY: soft drifting haze, dust veils and a sparse faint starfield only, spread across the whole frame, with no focal point anywhere. Absolutely no stations, no ships, no wrecks, no debris, no asteroids, no planets, no moons, no atmospheric limbs, no rings, no structures, no silhouettes, no hard shapes and no objects of any kind; nothing crosses the frame and nothing sits centred or off-centre as a subject. Extremely low contrast, one value step darker than ships and never brighter than a whisper, so gameplay and interface elements read on top of it; the frame centre is the quietest and darkest region. Sector identity is carried only by colour and haze density: Ashveil Expanse, the contested edge: unsettled and cold - soft ragged bands of dark ash-grey haze in void haze #1A2230 and grimy umber #4A423B drifting in loose frayed layers with no hard edge anywhere, greyer and distinctly colder than the warm sectors, no brown glow and no warm tint. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures. no space station, no docking ring, no ship, no hull, no wreck, no planet, no moon, no body limb, no torch light, no lamp and no glowing point of any kind.

---

## sector_7_bg

- Date/time: 2026-09-18 11:33 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 16:9
- Job id: `0d49c85e117aaa970beed49dcd852a89` (elapsed 27.3s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: opaque, no alpha key; run folder `20260918-113320` keeps `job.json`
- Final files: env_sector_7_bg.png
- Note: backdrop regen: pass 1 (sectors 1/2/4/7) returned focal objects despite the negative list (sector 1 a docked station and ships, sector 2 a strongly lit body limb, sector 4 an over-warm dust band, sector 7 a large structure crossing the frame). The subject was rewritten as a near-empty plate whose identity is colour and haze density only.
- Status: success

Full SUBJECT text:

> Sector backdrop plate for a space playfield, a single wide 16:9 full-frame painterly wash of empty deep space. The plate is ALMOST EMPTY: soft drifting haze, dust veils and a sparse faint starfield only, spread across the whole frame, with no focal point anywhere. Absolutely no stations, no ships, no wrecks, no debris, no asteroids, no planets, no moons, no atmospheric limbs, no rings, no structures, no silhouettes, no hard shapes and no objects of any kind; nothing crosses the frame and nothing sits centred or off-centre as a subject. Extremely low contrast, one value step darker than ships and never brighter than a whisper, so gameplay and interface elements read on top of it; the frame centre is the quietest and darkest region. Sector identity is carried only by colour and haze density: Maw Belt, unaligned, no law, the arena: hostile and abandoned - near-black void black #0A0E14 with faint soot-black smudges and a thin scatter of dark iron black #232629 grit suspended in the haze, completely cold and empty, no light source and no warm colour anywhere. Subtle film grain. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures. no space station, no docking ring, no ship, no hull, no wreck, no planet, no moon, no body limb, no torch light, no lamp and no glowing point of any kind.

---

## f1_ice_moon

- Date/time: 2026-09-18 12:32 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `2277ee06f1b8187f0871c5db852f945b` (elapsed 27.2s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: none (text-to-image)
- Alpha: local matte bg=#03090F alpha0=49% dropped=604; run folder `20260918-123247` keeps `job.json`
- Final files: env_body_ice_moon.png
- Status: success

Full SUBJECT text:

> Airless ice moon, a dead spherical body seen from above with no atmosphere, top-down orthographic, the moon occupies about 70 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required. Surface: a desaturated ice-crusted crust TWO value steps darker than ships, a dark grey-blue ice in the #2B2F35 to #3A3F46 range with only sparse pale frost speckle, cracked into polygonal plates with a cold steel highlight #565C63 rim catching along the cracks, ancient impact craters with raised rims, dirty streaks of grey rock between the ice fields, no blue tint, no atmosphere, no clouds, no terminator glow, no emissive, no glow of any kind. The moon surface fills the frame edge to edge with the round limb of the body visible. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---

## f2_ice_moon

- Date/time: 2026-09-18 13:32 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1678960300953320e556aad0d6989bc9` (elapsed 27.9s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: none (text-to-image)
- Alpha: local matte bg=#060A0E alpha0=70% dropped=1606; run folder `20260918-133217` keeps `job.json`
- Final files: env_body_ice_moon.png
- Status: success

Full SUBJECT text:

> Airless ice moon, a dead spherical body seen from above with no atmosphere, top-down orthographic, the moon occupies about 70 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required. Surface: a very dark desaturated ice-crusted crust THREE value steps darker than the ships family, a near-black grey-blue ice in the #171A1F to #24282E range with only sparse and faint pale frost speckle at a low opacity, cracked into polygonal plates with a dim cold steel highlight #565C63 caught along the cracks and no brighter highlight anywhere, ancient impact craters with raised rims, dirty streaks of grey rock between the ice fields, the whole surface reading aggressively dark and low-key with nothing at full white, no bright specular catch, no blue tint, no atmosphere, no clouds, no terminator glow, no emissive, no glow of any kind. The moon surface fills the frame edge to edge with the round limb of the body visible. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, no ships, no figures.

---


## f2 ice moon post-pass (C4) - verification only, no local edit

- Date/time: 2026-09-18 13:58 local
- No local pass was needed: the run alone lands the value (subject mean luminance 49.6, p95
  113.6, against a ships-family mean of 56.2; the F.1 cut measured 58.0 / 144.2). The file was
  imported and the pre-F.2 bytes are in `_f2_backup/`.
