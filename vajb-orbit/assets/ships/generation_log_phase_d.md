# Phase D wave 1 - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`, `flare-i2i` for edits), 2K. Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file`.
Spec: `docs/design/ASSET_EXPANSION_SPEC.md`. Price basis $0.05 per 2K run (user-verified); the script's printed 30-credit estimate is the stale hint.
Alpha: `--transparent` native first, `--strip-bg local` fallback; splitting via the alpha channel (`--split-only`). AI-generated art is not CC0 (AGENTS.md).

---

## ship_interceptor

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `c9e6b173e199f9a7beb1f931905d3be5`
- Run folder: `20260917-213427` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#060B11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=93.7% and fully-opaque=4.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Interceptor enemy hull rotation sheet, a hostile fast-attack raider. Silhouette: narrow needle hull, visibly the slimmest and longest hull of the roster, with two prongs swept forward at the bow forming a fork, no dorsal mass and no wings. Class markers: forward-swept twin prongs and a single central engine nozzle, clearly different from a dart-like twin-engine fighter hull. Weathering density: moderate-plus, scratches, hull grime, oil stains, light pitted metal. Engines and glow: 1 engine, one recessed tail nozzle, burnt ember C8461B flare with a small hot ember glow E8703A halo, small and hot, no other glow. Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 hull with cold steel highlight #565C63 rim. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_gunship

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e1cccd1876850a723052950cc60440c6`
- Run folder: `20260917-213510` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03070C`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=76.0% and fully-opaque=17.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Gunship enemy hull rotation sheet, a hostile mid-tier warship. Silhouette: broad and short hull, clearly the widest hostile hull short of the boss, with two oversized blocky broadside weapon pods flanking a squat central core and two recessed stern nozzles side by side. Class markers: the twin broadside pods dominate the outline; no spine ridges, no cargo blocks. Weathering density: heavy, battle damage with dents and scorch-blackened craters, scorch marks radiating from the pod muzzles, rust streaks, hull grime, oil stains. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_destroyer

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `3f43157f53505f712f1d7aa40ebc0727`
- Run folder: `20260917-213554` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030B11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=85.7% and fully-opaque=10.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Destroyer enemy hull rotation sheet, a hostile capital ship. Silhouette: long wedge hull, the largest hostile hull below the bosses, with a row of three dorsal turret blocks along the centreline and a flared squared stern carrying four nozzles in two paired blocks. Class markers: the dorsal turret row and the flared stern; no thorned protrusions on this hull. Weathering density: heaviest of the line hulls, battle damage, torn plate edges, weld beads over repairs, rust streaks, pitted metal, hull grime, oil stains. Engines and glow: 4 engines in two paired stern blocks, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_drone_swarm

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `535ee8f0b78107e45d439028df941a86`
- Run folder: `20260917-213637` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#FCFCFC`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=69.1% and fully-opaque=14.8%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, immediately readable as smaller than every other hull. Weathering density: light, scratches and hull grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. The drone is drawn small inside each cell, occupying about 40 percent of its cell width. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_trader

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0707aac292f16618d9704a16cd4bb0f3`
- Run folder: `20260917-213439` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.2% and fully-opaque=13.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Trader hull rotation sheet, a neutral civilian cargo vessel, clearly not a warship. Silhouette: boxy segmented hull with external container racks running along both flanks, four identical containers per side, a blunt squared bow and two engines side by side in the stern block. Class markers: the external container racks are the primary read; no weapon mounts, no thorned protrusions. Weathering density: heavy hull grime toward the trailing edges, rust streaks, oil stains, scratches, pitted metal, but no battle damage. Engines and glow: 2 engines, dim burnt ember C8461B flares with a faint ember glow E8703A halo, civilian throttle, small and contained, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_patrol

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e85e06da671dd53d1a33b10f47b7221c`
- Run folder: `20260917-213521` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040A10`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=86.3% and fully-opaque=10.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Patrol cutter hull rotation sheet, a neutral law-enforcement vessel. Silhouette: mid-length hull, noticeably shorter than a corvette and longer than a fighter, with one forward lance mount at the bow, a single tall dorsal fin and clean flat plated sides. Class markers: forward lance plus one dorsal fin; no asymmetric mounts, no thorned protrusions. Weathering density: moderate, scratches, hull grime, oil stains, well maintained. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_thorn

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `de03105199eed4150ce48f01ba2ea2ea`
- Run folder: `20260917-213607` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040B12`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=68.1% and fully-opaque=25.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_thorn.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Hive-mother boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a huge broad carapace hull with short thorned protrusions radiating from the bow and both flanks, each thorn large enough to catch the rim light on its edge, four spore vent blocks along the dorsal line, and a visible ember core glowing through a split in the forward plating. Class markers: hostile hull with thorned protrusions and a visible ember core. Weathering density: heaviest in the roster, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, pitted metal, hull grime, oil stains, scratches. Engines and glow: 2 recessed stern nozzles with burnt ember C8461B flares and small hot ember glow E8703A halos; the exposed ember core glows ember glow E8703A over a burnt ember C8461B heart, the largest single contained glow in the image, local to the core gap, never ambient scene glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_spire

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `546c01120e82888cc3003bae53db363f`
- Run folder: `20260917-213650` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03090F`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.7% and fully-opaque=11.6%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_spire.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Relay leviathan boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a very long spine of stacked rectangular plate segments forming a tall central ridge, with two heavy flank outriggers projecting sideways, each carrying a weapon block, and thorned nodes along the ridge. Class markers: hostile hull with thorned protrusions and a visible ember core burning inside a stern cavity. Weathering density: heaviest, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines and glow: 2 engines at the stern with burnt ember C8461B flares and small hot ember glow E8703A halos; the stern core glows ember glow E8703A over a burnt ember C8461B heart, small and contained, no other glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_vanguard

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `f9489227b4578b6535ce440cc96fe2e2`
- Run folder: `20260917-213447` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#000305`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=76.7% and fully-opaque=18.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same Vanguard cutter player ship, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows stacked across the hull with chevron weld seams running along the flanks, industrial mining-company refit look. Weathering: extra hull grime film and industrial dust over the standard scratches and oil stains. Keep the asymmetric weapon mount pods, the twin trailing engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `7d2ae0ecdd739c0c830aee5af0e69878`
- Run folder: `20260917-213536` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#010406`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.6% and fully-opaque=14.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: long continuous plate bands wrapping the hull with sparse rivet lines and very few panel seams, the cleanest of the company refits. Weathering: only scratches and oil stains, light hull grime, no battle damage, no rust streaks. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_corvette

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `00592aef1f1faeab97cfd1ddd3b2e1fb`
- Run folder: `20260917-213627` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#02070A`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=85.5% and fully-opaque=11.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy corvette hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: dense pitted metal with weld-bead patch repairs, tally notches cut into the plating and mismatched replacement plates. Weathering: heaviest rust streaks and battle damage over the standard scratches, hull grime and oil stains. Keep the long hull with its dorsal spine ridges and the recessed stern exhaust block exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_interceptor

- Date/time: 2026-09-17 21:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `c9e6b173e199f9a7beb1f931905d3be5`
- Run folder: `20260917-213427` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#060B11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=93.7% and fully-opaque=4.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_interceptor_front.png, ship_interceptor_three_quarter.png, ship_interceptor_side.png, ship_interceptor_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Interceptor enemy hull rotation sheet, a hostile fast-attack raider. Silhouette: narrow needle hull, visibly the slimmest and longest hull of the roster, with two prongs swept forward at the bow forming a fork, no dorsal mass and no wings. Class markers: forward-swept twin prongs and a single central engine nozzle, clearly different from a dart-like twin-engine fighter hull. Weathering density: moderate-plus, scratches, hull grime, oil stains, light pitted metal. Engines and glow: 1 engine, one recessed tail nozzle, burnt ember C8461B flare with a small hot ember glow E8703A halo, small and hot, no other glow. Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 hull with cold steel highlight #565C63 rim. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_gunship

- Date/time: 2026-09-17 21:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e1cccd1876850a723052950cc60440c6`
- Run folder: `20260917-213510` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03070C`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=76.0% and fully-opaque=17.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_gunship_front.png, ship_gunship_three_quarter.png, ship_gunship_side.png, ship_gunship_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Gunship enemy hull rotation sheet, a hostile mid-tier warship. Silhouette: broad and short hull, clearly the widest hostile hull short of the boss, with two oversized blocky broadside weapon pods flanking a squat central core and two recessed stern nozzles side by side. Class markers: the twin broadside pods dominate the outline; no spine ridges, no cargo blocks. Weathering density: heavy, battle damage with dents and scorch-blackened craters, scorch marks radiating from the pod muzzles, rust streaks, hull grime, oil stains. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_destroyer

- Date/time: 2026-09-17 21:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `3f43157f53505f712f1d7aa40ebc0727`
- Run folder: `20260917-213554` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030B11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=85.7% and fully-opaque=10.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_destroyer_front.png, ship_destroyer_three_quarter.png, ship_destroyer_side.png, ship_destroyer_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Destroyer enemy hull rotation sheet, a hostile capital ship. Silhouette: long wedge hull, the largest hostile hull below the bosses, with a row of three dorsal turret blocks along the centreline and a flared squared stern carrying four nozzles in two paired blocks. Class markers: the dorsal turret row and the flared stern; no thorned protrusions on this hull. Weathering density: heaviest of the line hulls, battle damage, torn plate edges, weld beads over repairs, rust streaks, pitted metal, hull grime, oil stains. Engines and glow: 4 engines in two paired stern blocks, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_drone_swarm

- Date/time: 2026-09-17 21:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `535ee8f0b78107e45d439028df941a86`
- Run folder: `20260917-213637` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#FCFCFC`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=69.1% and fully-opaque=14.8%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_drone_swarm_front.png, ship_drone_swarm_three_quarter.png, ship_drone_swarm_side.png, ship_drone_swarm_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, immediately readable as smaller than every other hull. Weathering density: light, scratches and hull grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. The drone is drawn small inside each cell, occupying about 40 percent of its cell width. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_trader

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0707aac292f16618d9704a16cd4bb0f3`
- Run folder: `20260917-213439` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.2% and fully-opaque=13.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_trader_front.png, ship_trader_three_quarter.png, ship_trader_side.png, ship_trader_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Trader hull rotation sheet, a neutral civilian cargo vessel, clearly not a warship. Silhouette: boxy segmented hull with external container racks running along both flanks, four identical containers per side, a blunt squared bow and two engines side by side in the stern block. Class markers: the external container racks are the primary read; no weapon mounts, no thorned protrusions. Weathering density: heavy hull grime toward the trailing edges, rust streaks, oil stains, scratches, pitted metal, but no battle damage. Engines and glow: 2 engines, dim burnt ember C8461B flares with a faint ember glow E8703A halo, civilian throttle, small and contained, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_patrol

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e85e06da671dd53d1a33b10f47b7221c`
- Run folder: `20260917-213521` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040A10`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=86.3% and fully-opaque=10.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_patrol_front.png, ship_patrol_three_quarter.png, ship_patrol_side.png, ship_patrol_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Patrol cutter hull rotation sheet, a neutral law-enforcement vessel. Silhouette: mid-length hull, noticeably shorter than a corvette and longer than a fighter, with one forward lance mount at the bow, a single tall dorsal fin and clean flat plated sides. Class markers: forward lance plus one dorsal fin; no asymmetric mounts, no thorned protrusions. Weathering density: moderate, scratches, hull grime, oil stains, well maintained. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_vanguard

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `f9489227b4578b6535ce440cc96fe2e2`
- Run folder: `20260917-213447` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#000305`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=76.7% and fully-opaque=18.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_vanguard_mmo_front.png, ship_vanguard_mmo_three_quarter.png, ship_vanguard_mmo_side.png, ship_vanguard_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same Vanguard cutter player ship, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows stacked across the hull with chevron weld seams running along the flanks, industrial mining-company refit look. Weathering: extra hull grime film and industrial dust over the standard scratches and oil stains. Keep the asymmetric weapon mount pods, the twin trailing engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `7d2ae0ecdd739c0c830aee5af0e69878`
- Run folder: `20260917-213536` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#010406`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.6% and fully-opaque=14.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_fighter_mmo_front.png, ship_fighter_mmo_three_quarter.png, ship_fighter_mmo_side.png, ship_fighter_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: long continuous plate bands wrapping the hull with sparse rivet lines and very few panel seams, the cleanest of the company refits. Weathering: only scratches and oil stains, light hull grime, no battle damage, no rust streaks. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_corvette

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `00592aef1f1faeab97cfd1ddd3b2e1fb`
- Run folder: `20260917-213627` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#02070A`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=85.5% and fully-opaque=11.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_corvette_mmo_front.png, ship_corvette_mmo_three_quarter.png, ship_corvette_mmo_side.png, ship_corvette_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy corvette hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: dense pitted metal with weld-bead patch repairs, tally notches cut into the plating and mismatched replacement plates. Weathering: heaviest rust streaks and battle damage over the standard scratches, hull grime and oil stains. Keep the long hull with its dorsal spine ridges and the recessed stern exhaust block exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_interceptor

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `c9e6b173e199f9a7beb1f931905d3be5`
- Run folder: `20260917-213427` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#060B11`, threshold 16, 7x7 median plus tiny-island removal (108 specks dropped), 0.8 px feather; achieved alpha0=93.9% and fully-opaque=4.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_interceptor_front.png, ship_interceptor_three_quarter.png, ship_interceptor_side.png, ship_interceptor_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Interceptor enemy hull rotation sheet, a hostile fast-attack raider. Silhouette: narrow needle hull, visibly the slimmest and longest hull of the roster, with two prongs swept forward at the bow forming a fork, no dorsal mass and no wings. Class markers: forward-swept twin prongs and a single central engine nozzle, clearly different from a dart-like twin-engine fighter hull. Weathering density: moderate-plus, scratches, hull grime, oil stains, light pitted metal. Engines and glow: 1 engine, one recessed tail nozzle, burnt ember C8461B flare with a small hot ember glow E8703A halo, small and hot, no other glow. Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 hull with cold steel highlight #565C63 rim. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_gunship

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e1cccd1876850a723052950cc60440c6`
- Run folder: `20260917-213510` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03070C`, threshold 16, 7x7 median plus tiny-island removal (398 specks dropped), 0.8 px feather; achieved alpha0=77.1% and fully-opaque=17.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_gunship_front.png, ship_gunship_three_quarter.png, ship_gunship_side.png, ship_gunship_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Gunship enemy hull rotation sheet, a hostile mid-tier warship. Silhouette: broad and short hull, clearly the widest hostile hull short of the boss, with two oversized blocky broadside weapon pods flanking a squat central core and two recessed stern nozzles side by side. Class markers: the twin broadside pods dominate the outline; no spine ridges, no cargo blocks. Weathering density: heavy, battle damage with dents and scorch-blackened craters, scorch marks radiating from the pod muzzles, rust streaks, hull grime, oil stains. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_destroyer

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `3f43157f53505f712f1d7aa40ebc0727`
- Run folder: `20260917-213554` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030B11`, threshold 16, 7x7 median plus tiny-island removal (222 specks dropped), 0.8 px feather; achieved alpha0=86.3% and fully-opaque=10.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_destroyer_front.png, ship_destroyer_three_quarter.png, ship_destroyer_side.png, ship_destroyer_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Destroyer enemy hull rotation sheet, a hostile capital ship. Silhouette: long wedge hull, the largest hostile hull below the bosses, with a row of three dorsal turret blocks along the centreline and a flared squared stern carrying four nozzles in two paired blocks. Class markers: the dorsal turret row and the flared stern; no thorned protrusions on this hull. Weathering density: heaviest of the line hulls, battle damage, torn plate edges, weld beads over repairs, rust streaks, pitted metal, hull grime, oil stains. Engines and glow: 4 engines in two paired stern blocks, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_drone_swarm

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `535ee8f0b78107e45d439028df941a86`
- Run folder: `20260917-213637` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#FCFCFC`, threshold 16, 7x7 median plus tiny-island removal (3930 specks dropped), 0.8 px feather; achieved alpha0=88.3% and fully-opaque=10.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_drone_swarm_front.png, ship_drone_swarm_three_quarter.png, ship_drone_swarm_side.png, ship_drone_swarm_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, immediately readable as smaller than every other hull. Weathering density: light, scratches and hull grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. The drone is drawn small inside each cell, occupying about 40 percent of its cell width. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_trader

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0707aac292f16618d9704a16cd4bb0f3`
- Run folder: `20260917-213439` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A11`, threshold 16, 7x7 median plus tiny-island removal (111 specks dropped), 0.8 px feather; achieved alpha0=82.6% and fully-opaque=13.8%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_trader_front.png, ship_trader_three_quarter.png, ship_trader_side.png, ship_trader_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Trader hull rotation sheet, a neutral civilian cargo vessel, clearly not a warship. Silhouette: boxy segmented hull with external container racks running along both flanks, four identical containers per side, a blunt squared bow and two engines side by side in the stern block. Class markers: the external container racks are the primary read; no weapon mounts, no thorned protrusions. Weathering density: heavy hull grime toward the trailing edges, rust streaks, oil stains, scratches, pitted metal, but no battle damage. Engines and glow: 2 engines, dim burnt ember C8461B flares with a faint ember glow E8703A halo, civilian throttle, small and contained, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_patrol

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e85e06da671dd53d1a33b10f47b7221c`
- Run folder: `20260917-213521` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040A10`, threshold 16, 7x7 median plus tiny-island removal (113 specks dropped), 0.8 px feather; achieved alpha0=86.6% and fully-opaque=10.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_patrol_front.png, ship_patrol_three_quarter.png, ship_patrol_side.png, ship_patrol_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Patrol cutter hull rotation sheet, a neutral law-enforcement vessel. Silhouette: mid-length hull, noticeably shorter than a corvette and longer than a fighter, with one forward lance mount at the bow, a single tall dorsal fin and clean flat plated sides. Class markers: forward lance plus one dorsal fin; no asymmetric mounts, no thorned protrusions. Weathering density: moderate, scratches, hull grime, oil stains, well maintained. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_thorn

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `de03105199eed4150ce48f01ba2ea2ea`
- Run folder: `20260917-213607` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040B12`, threshold 16, 7x7 median plus tiny-island removal (163 specks dropped), 0.8 px feather; achieved alpha0=68.5% and fully-opaque=25.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_thorn.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Hive-mother boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a huge broad carapace hull with short thorned protrusions radiating from the bow and both flanks, each thorn large enough to catch the rim light on its edge, four spore vent blocks along the dorsal line, and a visible ember core glowing through a split in the forward plating. Class markers: hostile hull with thorned protrusions and a visible ember core. Weathering density: heaviest in the roster, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, pitted metal, hull grime, oil stains, scratches. Engines and glow: 2 recessed stern nozzles with burnt ember C8461B flares and small hot ember glow E8703A halos; the exposed ember core glows ember glow E8703A over a burnt ember C8461B heart, the largest single contained glow in the image, local to the core gap, never ambient scene glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_spire

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `546c01120e82888cc3003bae53db363f`
- Run folder: `20260917-213650` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03090F`, threshold 16, 7x7 median plus tiny-island removal (297 specks dropped), 0.8 px feather; achieved alpha0=83.8% and fully-opaque=11.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_spire.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Relay leviathan boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a very long spine of stacked rectangular plate segments forming a tall central ridge, with two heavy flank outriggers projecting sideways, each carrying a weapon block, and thorned nodes along the ridge. Class markers: hostile hull with thorned protrusions and a visible ember core burning inside a stern cavity. Weathering density: heaviest, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines and glow: 2 engines at the stern with burnt ember C8461B flares and small hot ember glow E8703A halos; the stern core glows ember glow E8703A over a burnt ember C8461B heart, small and contained, no other glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_vanguard

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `f9489227b4578b6535ce440cc96fe2e2`
- Run folder: `20260917-213447` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#000305`, threshold 16, 7x7 median plus tiny-island removal (260 specks dropped), 0.8 px feather; achieved alpha0=77.1% and fully-opaque=18.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_vanguard_mmo_front.png, ship_vanguard_mmo_three_quarter.png, ship_vanguard_mmo_side.png, ship_vanguard_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same Vanguard cutter player ship, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows stacked across the hull with chevron weld seams running along the flanks, industrial mining-company refit look. Weathering: extra hull grime film and industrial dust over the standard scratches and oil stains. Keep the asymmetric weapon mount pods, the twin trailing engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `7d2ae0ecdd739c0c830aee5af0e69878`
- Run folder: `20260917-213536` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#010406`, threshold 16, 7x7 median plus tiny-island removal (104 specks dropped), 0.8 px feather; achieved alpha0=82.8% and fully-opaque=14.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_fighter_mmo_front.png, ship_fighter_mmo_three_quarter.png, ship_fighter_mmo_side.png, ship_fighter_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: long continuous plate bands wrapping the hull with sparse rivet lines and very few panel seams, the cleanest of the company refits. Weathering: only scratches and oil stains, light hull grime, no battle damage, no rust streaks. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_corvette

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `00592aef1f1faeab97cfd1ddd3b2e1fb`
- Run folder: `20260917-213627` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#02070A`, threshold 16, 7x7 median plus tiny-island removal (143 specks dropped), 0.8 px feather; achieved alpha0=85.7% and fully-opaque=11.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_corvette_mmo_front.png, ship_corvette_mmo_three_quarter.png, ship_corvette_mmo_side.png, ship_corvette_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy corvette hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: dense pitted metal with weld-bead patch repairs, tally notches cut into the plating and mismatched replacement plates. Weathering: heaviest rust streaks and battle damage over the standard scratches, hull grime and oil stains. Keep the long hull with its dorsal spine ridges and the recessed stern exhaust block exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---



---

# Phase D wave 2 - generation log

Same model, style block, alpha pipeline and price basis as wave 1 (see `docs/design/ASSET_EXPANSION_SPEC.md`).

---

## ship_interceptor

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `c9e6b173e199f9a7beb1f931905d3be5`
- Run folder: `20260917-213427` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#060B11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=93.7% and fully-opaque=4.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Interceptor enemy hull rotation sheet, a hostile fast-attack raider. Silhouette: narrow needle hull, visibly the slimmest and longest hull of the roster, with two prongs swept forward at the bow forming a fork, no dorsal mass and no wings. Class markers: forward-swept twin prongs and a single central engine nozzle, clearly different from a dart-like twin-engine fighter hull. Weathering density: moderate-plus, scratches, hull grime, oil stains, light pitted metal. Engines and glow: 1 engine, one recessed tail nozzle, burnt ember C8461B flare with a small hot ember glow E8703A halo, small and hot, no other glow. Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 hull with cold steel highlight #565C63 rim. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_gunship

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e1cccd1876850a723052950cc60440c6`
- Run folder: `20260917-213510` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03070C`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=76.0% and fully-opaque=17.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Gunship enemy hull rotation sheet, a hostile mid-tier warship. Silhouette: broad and short hull, clearly the widest hostile hull short of the boss, with two oversized blocky broadside weapon pods flanking a squat central core and two recessed stern nozzles side by side. Class markers: the twin broadside pods dominate the outline; no spine ridges, no cargo blocks. Weathering density: heavy, battle damage with dents and scorch-blackened craters, scorch marks radiating from the pod muzzles, rust streaks, hull grime, oil stains. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_destroyer

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `3f43157f53505f712f1d7aa40ebc0727`
- Run folder: `20260917-213554` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030B11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=85.7% and fully-opaque=10.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Destroyer enemy hull rotation sheet, a hostile capital ship. Silhouette: long wedge hull, the largest hostile hull below the bosses, with a row of three dorsal turret blocks along the centreline and a flared squared stern carrying four nozzles in two paired blocks. Class markers: the dorsal turret row and the flared stern; no thorned protrusions on this hull. Weathering density: heaviest of the line hulls, battle damage, torn plate edges, weld beads over repairs, rust streaks, pitted metal, hull grime, oil stains. Engines and glow: 4 engines in two paired stern blocks, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_drone_swarm

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `535ee8f0b78107e45d439028df941a86`
- Run folder: `20260917-213637` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#FCFCFC`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=69.1% and fully-opaque=14.8%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, immediately readable as smaller than every other hull. Weathering density: light, scratches and hull grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. The drone is drawn small inside each cell, occupying about 40 percent of its cell width. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_trader

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0707aac292f16618d9704a16cd4bb0f3`
- Run folder: `20260917-213439` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.2% and fully-opaque=13.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Trader hull rotation sheet, a neutral civilian cargo vessel, clearly not a warship. Silhouette: boxy segmented hull with external container racks running along both flanks, four identical containers per side, a blunt squared bow and two engines side by side in the stern block. Class markers: the external container racks are the primary read; no weapon mounts, no thorned protrusions. Weathering density: heavy hull grime toward the trailing edges, rust streaks, oil stains, scratches, pitted metal, but no battle damage. Engines and glow: 2 engines, dim burnt ember C8461B flares with a faint ember glow E8703A halo, civilian throttle, small and contained, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_patrol

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e85e06da671dd53d1a33b10f47b7221c`
- Run folder: `20260917-213521` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040A10`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=86.3% and fully-opaque=10.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Patrol cutter hull rotation sheet, a neutral law-enforcement vessel. Silhouette: mid-length hull, noticeably shorter than a corvette and longer than a fighter, with one forward lance mount at the bow, a single tall dorsal fin and clean flat plated sides. Class markers: forward lance plus one dorsal fin; no asymmetric mounts, no thorned protrusions. Weathering density: moderate, scratches, hull grime, oil stains, well maintained. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_thorn

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `de03105199eed4150ce48f01ba2ea2ea`
- Run folder: `20260917-213607` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040B12`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=68.1% and fully-opaque=25.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_thorn.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Hive-mother boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a huge broad carapace hull with short thorned protrusions radiating from the bow and both flanks, each thorn large enough to catch the rim light on its edge, four spore vent blocks along the dorsal line, and a visible ember core glowing through a split in the forward plating. Class markers: hostile hull with thorned protrusions and a visible ember core. Weathering density: heaviest in the roster, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, pitted metal, hull grime, oil stains, scratches. Engines and glow: 2 recessed stern nozzles with burnt ember C8461B flares and small hot ember glow E8703A halos; the exposed ember core glows ember glow E8703A over a burnt ember C8461B heart, the largest single contained glow in the image, local to the core gap, never ambient scene glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_spire

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `546c01120e82888cc3003bae53db363f`
- Run folder: `20260917-213650` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03090F`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.7% and fully-opaque=11.6%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_spire.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Relay leviathan boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a very long spine of stacked rectangular plate segments forming a tall central ridge, with two heavy flank outriggers projecting sideways, each carrying a weapon block, and thorned nodes along the ridge. Class markers: hostile hull with thorned protrusions and a visible ember core burning inside a stern cavity. Weathering density: heaviest, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines and glow: 2 engines at the stern with burnt ember C8461B flares and small hot ember glow E8703A halos; the stern core glows ember glow E8703A over a burnt ember C8461B heart, small and contained, no other glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_vanguard

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `f9489227b4578b6535ce440cc96fe2e2`
- Run folder: `20260917-213447` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#000305`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=76.7% and fully-opaque=18.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same Vanguard cutter player ship, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows stacked across the hull with chevron weld seams running along the flanks, industrial mining-company refit look. Weathering: extra hull grime film and industrial dust over the standard scratches and oil stains. Keep the asymmetric weapon mount pods, the twin trailing engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `7d2ae0ecdd739c0c830aee5af0e69878`
- Run folder: `20260917-213536` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#010406`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.6% and fully-opaque=14.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: long continuous plate bands wrapping the hull with sparse rivet lines and very few panel seams, the cleanest of the company refits. Weathering: only scratches and oil stains, light hull grime, no battle damage, no rust streaks. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_corvette

- Date/time: 2026-09-17 21:40 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `00592aef1f1faeab97cfd1ddd3b2e1fb`
- Run folder: `20260917-213627` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#02070A`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=85.5% and fully-opaque=11.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: front.png, three_quarter.png, side.png, back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy corvette hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: dense pitted metal with weld-bead patch repairs, tally notches cut into the plating and mismatched replacement plates. Weathering: heaviest rust streaks and battle damage over the standard scratches, hull grime and oil stains. Keep the long hull with its dorsal spine ridges and the recessed stern exhaust block exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_interceptor

- Date/time: 2026-09-17 21:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `c9e6b173e199f9a7beb1f931905d3be5`
- Run folder: `20260917-213427` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#060B11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=93.7% and fully-opaque=4.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_interceptor_front.png, ship_interceptor_three_quarter.png, ship_interceptor_side.png, ship_interceptor_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Interceptor enemy hull rotation sheet, a hostile fast-attack raider. Silhouette: narrow needle hull, visibly the slimmest and longest hull of the roster, with two prongs swept forward at the bow forming a fork, no dorsal mass and no wings. Class markers: forward-swept twin prongs and a single central engine nozzle, clearly different from a dart-like twin-engine fighter hull. Weathering density: moderate-plus, scratches, hull grime, oil stains, light pitted metal. Engines and glow: 1 engine, one recessed tail nozzle, burnt ember C8461B flare with a small hot ember glow E8703A halo, small and hot, no other glow. Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 hull with cold steel highlight #565C63 rim. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_gunship

- Date/time: 2026-09-17 21:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e1cccd1876850a723052950cc60440c6`
- Run folder: `20260917-213510` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03070C`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=76.0% and fully-opaque=17.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_gunship_front.png, ship_gunship_three_quarter.png, ship_gunship_side.png, ship_gunship_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Gunship enemy hull rotation sheet, a hostile mid-tier warship. Silhouette: broad and short hull, clearly the widest hostile hull short of the boss, with two oversized blocky broadside weapon pods flanking a squat central core and two recessed stern nozzles side by side. Class markers: the twin broadside pods dominate the outline; no spine ridges, no cargo blocks. Weathering density: heavy, battle damage with dents and scorch-blackened craters, scorch marks radiating from the pod muzzles, rust streaks, hull grime, oil stains. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_destroyer

- Date/time: 2026-09-17 21:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `3f43157f53505f712f1d7aa40ebc0727`
- Run folder: `20260917-213554` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030B11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=85.7% and fully-opaque=10.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_destroyer_front.png, ship_destroyer_three_quarter.png, ship_destroyer_side.png, ship_destroyer_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Destroyer enemy hull rotation sheet, a hostile capital ship. Silhouette: long wedge hull, the largest hostile hull below the bosses, with a row of three dorsal turret blocks along the centreline and a flared squared stern carrying four nozzles in two paired blocks. Class markers: the dorsal turret row and the flared stern; no thorned protrusions on this hull. Weathering density: heaviest of the line hulls, battle damage, torn plate edges, weld beads over repairs, rust streaks, pitted metal, hull grime, oil stains. Engines and glow: 4 engines in two paired stern blocks, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_drone_swarm

- Date/time: 2026-09-17 21:42 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `535ee8f0b78107e45d439028df941a86`
- Run folder: `20260917-213637` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#FCFCFC`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=69.1% and fully-opaque=14.8%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_drone_swarm_front.png, ship_drone_swarm_three_quarter.png, ship_drone_swarm_side.png, ship_drone_swarm_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, immediately readable as smaller than every other hull. Weathering density: light, scratches and hull grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. The drone is drawn small inside each cell, occupying about 40 percent of its cell width. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_trader

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0707aac292f16618d9704a16cd4bb0f3`
- Run folder: `20260917-213439` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A11`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.2% and fully-opaque=13.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_trader_front.png, ship_trader_three_quarter.png, ship_trader_side.png, ship_trader_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Trader hull rotation sheet, a neutral civilian cargo vessel, clearly not a warship. Silhouette: boxy segmented hull with external container racks running along both flanks, four identical containers per side, a blunt squared bow and two engines side by side in the stern block. Class markers: the external container racks are the primary read; no weapon mounts, no thorned protrusions. Weathering density: heavy hull grime toward the trailing edges, rust streaks, oil stains, scratches, pitted metal, but no battle damage. Engines and glow: 2 engines, dim burnt ember C8461B flares with a faint ember glow E8703A halo, civilian throttle, small and contained, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_patrol

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e85e06da671dd53d1a33b10f47b7221c`
- Run folder: `20260917-213521` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040A10`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=86.3% and fully-opaque=10.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_patrol_front.png, ship_patrol_three_quarter.png, ship_patrol_side.png, ship_patrol_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Patrol cutter hull rotation sheet, a neutral law-enforcement vessel. Silhouette: mid-length hull, noticeably shorter than a corvette and longer than a fighter, with one forward lance mount at the bow, a single tall dorsal fin and clean flat plated sides. Class markers: forward lance plus one dorsal fin; no asymmetric mounts, no thorned protrusions. Weathering density: moderate, scratches, hull grime, oil stains, well maintained. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_vanguard

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `f9489227b4578b6535ce440cc96fe2e2`
- Run folder: `20260917-213447` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#000305`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=76.7% and fully-opaque=18.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_vanguard_mmo_front.png, ship_vanguard_mmo_three_quarter.png, ship_vanguard_mmo_side.png, ship_vanguard_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same Vanguard cutter player ship, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows stacked across the hull with chevron weld seams running along the flanks, industrial mining-company refit look. Weathering: extra hull grime film and industrial dust over the standard scratches and oil stains. Keep the asymmetric weapon mount pods, the twin trailing engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `7d2ae0ecdd739c0c830aee5af0e69878`
- Run folder: `20260917-213536` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#010406`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.6% and fully-opaque=14.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_fighter_mmo_front.png, ship_fighter_mmo_three_quarter.png, ship_fighter_mmo_side.png, ship_fighter_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: long continuous plate bands wrapping the hull with sparse rivet lines and very few panel seams, the cleanest of the company refits. Weathering: only scratches and oil stains, light hull grime, no battle damage, no rust streaks. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_corvette

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `00592aef1f1faeab97cfd1ddd3b2e1fb`
- Run folder: `20260917-213627` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#02070A`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=85.5% and fully-opaque=11.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_corvette_mmo_front.png, ship_corvette_mmo_three_quarter.png, ship_corvette_mmo_side.png, ship_corvette_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy corvette hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: dense pitted metal with weld-bead patch repairs, tally notches cut into the plating and mismatched replacement plates. Weathering: heaviest rust streaks and battle damage over the standard scratches, hull grime and oil stains. Keep the long hull with its dorsal spine ridges and the recessed stern exhaust block exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_interceptor

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `c9e6b173e199f9a7beb1f931905d3be5`
- Run folder: `20260917-213427` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#060B11`, threshold 16, 7x7 median plus tiny-island removal (108 specks dropped), 0.8 px feather; achieved alpha0=93.9% and fully-opaque=4.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_interceptor_front.png, ship_interceptor_three_quarter.png, ship_interceptor_side.png, ship_interceptor_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Interceptor enemy hull rotation sheet, a hostile fast-attack raider. Silhouette: narrow needle hull, visibly the slimmest and longest hull of the roster, with two prongs swept forward at the bow forming a fork, no dorsal mass and no wings. Class markers: forward-swept twin prongs and a single central engine nozzle, clearly different from a dart-like twin-engine fighter hull. Weathering density: moderate-plus, scratches, hull grime, oil stains, light pitted metal. Engines and glow: 1 engine, one recessed tail nozzle, burnt ember C8461B flare with a small hot ember glow E8703A halo, small and hot, no other glow. Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 hull with cold steel highlight #565C63 rim. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_gunship

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e1cccd1876850a723052950cc60440c6`
- Run folder: `20260917-213510` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03070C`, threshold 16, 7x7 median plus tiny-island removal (398 specks dropped), 0.8 px feather; achieved alpha0=77.1% and fully-opaque=17.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_gunship_front.png, ship_gunship_three_quarter.png, ship_gunship_side.png, ship_gunship_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Gunship enemy hull rotation sheet, a hostile mid-tier warship. Silhouette: broad and short hull, clearly the widest hostile hull short of the boss, with two oversized blocky broadside weapon pods flanking a squat central core and two recessed stern nozzles side by side. Class markers: the twin broadside pods dominate the outline; no spine ridges, no cargo blocks. Weathering density: heavy, battle damage with dents and scorch-blackened craters, scorch marks radiating from the pod muzzles, rust streaks, hull grime, oil stains. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_destroyer

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `3f43157f53505f712f1d7aa40ebc0727`
- Run folder: `20260917-213554` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030B11`, threshold 16, 7x7 median plus tiny-island removal (222 specks dropped), 0.8 px feather; achieved alpha0=86.3% and fully-opaque=10.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_destroyer_front.png, ship_destroyer_three_quarter.png, ship_destroyer_side.png, ship_destroyer_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Destroyer enemy hull rotation sheet, a hostile capital ship. Silhouette: long wedge hull, the largest hostile hull below the bosses, with a row of three dorsal turret blocks along the centreline and a flared squared stern carrying four nozzles in two paired blocks. Class markers: the dorsal turret row and the flared stern; no thorned protrusions on this hull. Weathering density: heaviest of the line hulls, battle damage, torn plate edges, weld beads over repairs, rust streaks, pitted metal, hull grime, oil stains. Engines and glow: 4 engines in two paired stern blocks, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_drone_swarm

- Date/time: 2026-09-17 21:43 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `535ee8f0b78107e45d439028df941a86`
- Run folder: `20260917-213637` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#FCFCFC`, threshold 16, 7x7 median plus tiny-island removal (3930 specks dropped), 0.8 px feather; achieved alpha0=88.3% and fully-opaque=10.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_drone_swarm_front.png, ship_drone_swarm_three_quarter.png, ship_drone_swarm_side.png, ship_drone_swarm_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, immediately readable as smaller than every other hull. Weathering density: light, scratches and hull grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. The drone is drawn small inside each cell, occupying about 40 percent of its cell width. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_trader

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0707aac292f16618d9704a16cd4bb0f3`
- Run folder: `20260917-213439` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A11`, threshold 16, 7x7 median plus tiny-island removal (111 specks dropped), 0.8 px feather; achieved alpha0=82.6% and fully-opaque=13.8%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_trader_front.png, ship_trader_three_quarter.png, ship_trader_side.png, ship_trader_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Trader hull rotation sheet, a neutral civilian cargo vessel, clearly not a warship. Silhouette: boxy segmented hull with external container racks running along both flanks, four identical containers per side, a blunt squared bow and two engines side by side in the stern block. Class markers: the external container racks are the primary read; no weapon mounts, no thorned protrusions. Weathering density: heavy hull grime toward the trailing edges, rust streaks, oil stains, scratches, pitted metal, but no battle damage. Engines and glow: 2 engines, dim burnt ember C8461B flares with a faint ember glow E8703A halo, civilian throttle, small and contained, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_patrol

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e85e06da671dd53d1a33b10f47b7221c`
- Run folder: `20260917-213521` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040A10`, threshold 16, 7x7 median plus tiny-island removal (113 specks dropped), 0.8 px feather; achieved alpha0=86.6% and fully-opaque=10.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_patrol_front.png, ship_patrol_three_quarter.png, ship_patrol_side.png, ship_patrol_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Patrol cutter hull rotation sheet, a neutral law-enforcement vessel. Silhouette: mid-length hull, noticeably shorter than a corvette and longer than a fighter, with one forward lance mount at the bow, a single tall dorsal fin and clean flat plated sides. Class markers: forward lance plus one dorsal fin; no asymmetric mounts, no thorned protrusions. Weathering density: moderate, scratches, hull grime, oil stains, well maintained. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_thorn

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `de03105199eed4150ce48f01ba2ea2ea`
- Run folder: `20260917-213607` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040B12`, threshold 16, 7x7 median plus tiny-island removal (163 specks dropped), 0.8 px feather; achieved alpha0=68.5% and fully-opaque=25.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_thorn.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Hive-mother boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a huge broad carapace hull with short thorned protrusions radiating from the bow and both flanks, each thorn large enough to catch the rim light on its edge, four spore vent blocks along the dorsal line, and a visible ember core glowing through a split in the forward plating. Class markers: hostile hull with thorned protrusions and a visible ember core. Weathering density: heaviest in the roster, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, pitted metal, hull grime, oil stains, scratches. Engines and glow: 2 recessed stern nozzles with burnt ember C8461B flares and small hot ember glow E8703A halos; the exposed ember core glows ember glow E8703A over a burnt ember C8461B heart, the largest single contained glow in the image, local to the core gap, never ambient scene glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_spire

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `546c01120e82888cc3003bae53db363f`
- Run folder: `20260917-213650` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03090F`, threshold 16, 7x7 median plus tiny-island removal (297 specks dropped), 0.8 px feather; achieved alpha0=83.8% and fully-opaque=11.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_spire.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Relay leviathan boss dreadnought, a single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a very long spine of stacked rectangular plate segments forming a tall central ridge, with two heavy flank outriggers projecting sideways, each carrying a weapon block, and thorned nodes along the ridge. Class markers: hostile hull with thorned protrusions and a visible ember core burning inside a stern cavity. Weathering density: heaviest, battle damage, torn plate edges, scorch-blackened craters, weld beads, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines and glow: 2 engines at the stern with burnt ember C8461B flares and small hot ember glow E8703A halos; the stern core glows ember glow E8703A over a burnt ember C8461B heart, small and contained, no other glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_vanguard

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `f9489227b4578b6535ce440cc96fe2e2`
- Run folder: `20260917-213447` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#000305`, threshold 16, 7x7 median plus tiny-island removal (260 specks dropped), 0.8 px feather; achieved alpha0=77.1% and fully-opaque=18.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_vanguard_mmo_front.png, ship_vanguard_mmo_three_quarter.png, ship_vanguard_mmo_side.png, ship_vanguard_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same Vanguard cutter player ship, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows stacked across the hull with chevron weld seams running along the flanks, industrial mining-company refit look. Weathering: extra hull grime film and industrial dust over the standard scratches and oil stains. Keep the asymmetric weapon mount pods, the twin trailing engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `7d2ae0ecdd739c0c830aee5af0e69878`
- Run folder: `20260917-213536` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#010406`, threshold 16, 7x7 median plus tiny-island removal (104 specks dropped), 0.8 px feather; achieved alpha0=82.8% and fully-opaque=14.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_fighter_mmo_front.png, ship_fighter_mmo_three_quarter.png, ship_fighter_mmo_side.png, ship_fighter_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: long continuous plate bands wrapping the hull with sparse rivet lines and very few panel seams, the cleanest of the company refits. Weathering: only scratches and oil stains, light hull grime, no battle damage, no rust streaks. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_corvette

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `00592aef1f1faeab97cfd1ddd3b2e1fb`
- Run folder: `20260917-213627` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#02070A`, threshold 16, 7x7 median plus tiny-island removal (143 specks dropped), 0.8 px feather; achieved alpha0=85.7% and fully-opaque=11.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_corvette_mmo_front.png, ship_corvette_mmo_three_quarter.png, ship_corvette_mmo_side.png, ship_corvette_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy corvette hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: dense pitted metal with weld-bead patch repairs, tally notches cut into the plating and mismatched replacement plates. Weathering: heaviest rust streaks and battle damage over the standard scratches, hull grime and oil stains. Keep the long hull with its dorsal spine ridges and the recessed stern exhaust block exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_freighter

- Date/time: 2026-09-17 21:59 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `fb35ca150ec27a93dd20029bf27c2287` (elapsed 32.8s)
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\20260917-183532\freighter-enemy-hull-rotation-sheet-fou-1-alpha.png
- Alpha: local-keyed; run folder `20260917-215857` keeps `job.json`
- Final files: ship_freighter_mmo_front.png, ship_freighter_mmo_three_quarter.png, ship_freighter_mmo_side.png, ship_freighter_mmo_back.png
- Status: success

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy freighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows crossing the three hull blocks with chevron weld seams along the flanks, industrial mining-company refit. Weathering: extra hull grime film and industrial dust over the standard scratches, rust streaks and oil stains, no new battle damage. Keep the bow, cargo and engine blocks, the external container racks and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_bomber

- Date/time: 2026-09-17 21:59 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e937fc4ad4678b3536354790996b1e67` (elapsed 38.1s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-215858` keeps `job.json`
- Final files: ship_bomber_front.png, ship_bomber_three_quarter.png, ship_bomber_side.png, ship_bomber_back.png
- Status: success

Full SUBJECT text:

> Bomber enemy hull rotation sheet, a hostile ordnance ship. Silhouette: fat deep-bodied fuselage, clearly the deepest hull of the roster, with a wide underslung ordnance bay recessed into the belly and two short stub wings projecting just far enough to catch the rim light, twin recessed nozzles at the tail. Class markers: the underslung bay and the stub wings; no spine ridges, no thorned protrusions. Weathering density: heavy, scorch marks radiating from the bay mouth, oil stains, battle damage, hull grime, pitted metal. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_mine_layer

- Date/time: 2026-09-17 21:59 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `dd92c63a7b10733f5e1922d5390da134` (elapsed 37.8s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-215942` keeps `job.json`
- Final files: ship_mine_layer_front.png, ship_mine_layer_three_quarter.png, ship_mine_layer_side.png, ship_mine_layer_back.png
- Status: success

Full SUBJECT text:

> Mine layer enemy hull rotation sheet, a hostile support ship. Silhouette: slim central hull with a blunt squared bow, a single low dorsal rail and a wide flat stern rack holding six empty mine cradles along its trailing edge, each cradle a clear open notch. Class markers: the stern mine rack is the whole read; no wings, no thorned protrusions. Weathering density: heavy, rust streaks, battle damage, hull grime, oil stains, pitted metal. Engines and glow: 2 engines inside the stern block, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_maw

- Date/time: 2026-09-17 21:59 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `23d22b81087a541896ee38395fcfa3b5` (elapsed 42.8s)
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\20260917-183626\maw-dreadnought-boss-ship-single-centre-1-alpha.png
- Alpha: local-keyed; run folder `20260917-215948` keeps `job.json`
- Final files: ship_boss_maw_mmo.png
- Status: success

Full SUBJECT text:

> Same maw dreadnought boss, identical silhouette, identical proportions, identical framing, identical camera and identical lighting; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows laid over the carapace with chevron weld seams between the thorn roots, industrial mining-company refit. Weathering: extra hull grime film and industrial dust over the existing battle damage and scorch marks. Keep every thorn, the spore vents, the exposed ember core through the split plate and the stern nozzles exactly as in the reference, keep the render isolated on a fully transparent background with no backdrop and no ground shadow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_turret_platform

- Date/time: 2026-09-17 22:00 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `5ec8a57774f5c4633e9a0a73d20bc11b` (elapsed 38.2s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-220025` keeps `job.json`
- Final files: ship_turret_platform.png
- Status: success

Full SUBJECT text:

> Hostile turret platform, one single centred top-down orthographic render, the emplacement occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a radially symmetric hexagonal armoured emplacement with no bow and no stern, one long barrel on a central pivot ring projecting to the right, three armoured stabiliser legs spaced evenly around the base, and a low sensor drum at the hub centre. Class markers: radial symmetry, no hull axis. Weathering density: heavy, pitted metal, scorch marks around the barrel base, rust streaks, hull grime, battle damage. Emissive: small hot burnt ember C8461B warning lamps only on the hub ring, three lamp points, no ember glow halo, no muzzle glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_leviathan

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0b6320060758cd8efa560ce03ea4eca3` (elapsed 37.9s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-220108` keeps `job.json`
- Final files: ship_boss_leviathan.png
- Status: success

Full SUBJECT text:

> Leviathan boss dreadnought, one single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a blunt hammerhead fore-section wider than the rest of the hull, joined to a long ribbed hull with visible exposed structural ribs along both flanks and thorned protrusions at the stern, with two exposed drive cores recessed into the flanks and a visible ember core burning in a forward cavity behind the hammerhead. Class markers: hostile hull with thorned protrusions and a visible ember core. Weathering density: heaviest, battle damage, torn plate edges, scorch-blackened craters, weld beads over repairs, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines and glow: 2 engine blocks at the stern with burnt ember C8461B flares and small hot ember glow E8703A halos; the two exposed drive cores glow ember glow E8703A over burnt ember C8461B hearts, contained and local, no other glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_bomber

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `e937fc4ad4678b3536354790996b1e67`
- Run folder: `20260917-215858` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#050A11`, threshold 16, 7x7 median plus tiny-island removal (254 specks dropped), 0.8 px feather; achieved alpha0=80.8% and fully-opaque=15.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_bomber_front.png, ship_bomber_three_quarter.png, ship_bomber_side.png, ship_bomber_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Bomber enemy hull rotation sheet, a hostile ordnance ship. Silhouette: fat deep-bodied fuselage, clearly the deepest hull of the roster, with a wide underslung ordnance bay recessed into the belly and two short stub wings projecting just far enough to catch the rim light, twin recessed nozzles at the tail. Class markers: the underslung bay and the stub wings; no spine ridges, no thorned protrusions. Weathering density: heavy, scorch marks radiating from the bay mouth, oil stains, battle damage, hull grime, pitted metal. Engines and glow: 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_mine_layer

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `dd92c63a7b10733f5e1922d5390da134`
- Run folder: `20260917-215942` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#050A11`, threshold 16, 7x7 median plus tiny-island removal (82 specks dropped), 0.8 px feather; achieved alpha0=87.2% and fully-opaque=10.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_mine_layer_front.png, ship_mine_layer_three_quarter.png, ship_mine_layer_side.png, ship_mine_layer_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Mine layer enemy hull rotation sheet, a hostile support ship. Silhouette: slim central hull with a blunt squared bow, a single low dorsal rail and a wide flat stern rack holding six empty mine cradles along its trailing edge, each cradle a clear open notch. Class markers: the stern mine rack is the whole read; no wings, no thorned protrusions. Weathering density: heavy, rust streaks, battle damage, hull grime, oil stains, pitted metal. Engines and glow: 2 engines inside the stern block, burnt ember C8461B flares with small hot ember glow E8703A halos, small and hot, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_turret_platform

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `5ec8a57774f5c4633e9a0a73d20bc11b`
- Run folder: `20260917-220025` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#02070C`, threshold 16, 7x7 median plus tiny-island removal (363 specks dropped), 0.8 px feather; achieved alpha0=76.5% and fully-opaque=17.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_turret_platform.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Hostile turret platform, one single centred top-down orthographic render, the emplacement occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a radially symmetric hexagonal armoured emplacement with no bow and no stern, one long barrel on a central pivot ring projecting to the right, three armoured stabiliser legs spaced evenly around the base, and a low sensor drum at the hub centre. Class markers: radial symmetry, no hull axis. Weathering density: heavy, pitted metal, scorch marks around the barrel base, rust streaks, hull grime, battle damage. Emissive: small hot burnt ember C8461B warning lamps only on the hub ring, three lamp points, no ember glow halo, no muzzle glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_leviathan

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0b6320060758cd8efa560ce03ea4eca3`
- Run folder: `20260917-220108` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030910`, threshold 16, 7x7 median plus tiny-island removal (259 specks dropped), 0.8 px feather; achieved alpha0=79.9% and fully-opaque=14.8%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_leviathan.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Leviathan boss dreadnought, one single centred top-down orthographic render, bow pointing right, no tilt and no perspective, the hull occupies about 60 percent of the frame width with its centroid at the frame centre, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Silhouette: a blunt hammerhead fore-section wider than the rest of the hull, joined to a long ribbed hull with visible exposed structural ribs along both flanks and thorned protrusions at the stern, with two exposed drive cores recessed into the flanks and a visible ember core burning in a forward cavity behind the hammerhead. Class markers: hostile hull with thorned protrusions and a visible ember core. Weathering density: heaviest, battle damage, torn plate edges, scorch-blackened craters, weld beads over repairs, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines and glow: 2 engine blocks at the stern with burnt ember C8461B flares and small hot ember glow E8703A halos; the two exposed drive cores glow ember glow E8703A over burnt ember C8461B hearts, contained and local, no other glow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_freighter

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `fb35ca150ec27a93dd20029bf27c2287`
- Run folder: `20260917-215857` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#010407`, threshold 16, 7x7 median plus tiny-island removal (223 specks dropped), 0.8 px feather; achieved alpha0=83.2% and fully-opaque=13.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_freighter_mmo_front.png, ship_freighter_mmo_three_quarter.png, ship_freighter_mmo_side.png, ship_freighter_mmo_back.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy freighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows crossing the three hull blocks with chevron weld seams along the flanks, industrial mining-company refit. Weathering: extra hull grime film and industrial dust over the standard scratches, rust streaks and oil stains, no new battle damage. Keep the bow, cargo and engine blocks, the external container racks and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_maw

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `23d22b81087a541896ee38395fcfa3b5`
- Run folder: `20260917-215948` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#02080E`, threshold 16, 7x7 median plus tiny-island removal (163 specks dropped), 0.8 px feather; achieved alpha0=69.8% and fully-opaque=24.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: ship_boss_maw_mmo.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Same maw dreadnought boss, identical silhouette, identical proportions, identical framing, identical camera and identical lighting; re-render only the hull plate pattern and the weathering distribution. New plate pattern: heavy horizontal riveted plate rows laid over the carapace with chevron weld seams between the thorn roots, industrial mining-company refit. Weathering: extra hull grime film and industrial dust over the existing battle damage and scorch marks. Keep every thorn, the spore vents, the exposed ember core through the split plate and the stern nozzles exactly as in the reference, keep the render isolated on a fully transparent background with no backdrop and no ground shadow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

