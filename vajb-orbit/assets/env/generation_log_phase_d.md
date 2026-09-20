# Phase D wave 1 - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`, `flare-i2i` for edits), 2K. Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file`.
Spec: `docs/design/ASSET_EXPANSION_SPEC.md`. Price basis $0.05 per 2K run (user-verified); the script's printed 30-credit estimate is the stale hint.
Alpha: `--transparent` native first, `--strip-bg local` fallback; splitting via the alpha channel (`--split-only`). AI-generated art is not CC0 (AGENTS.md).

---

## panel_pickups

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1e5843bc528d51267b0994c1361237a0`
- Run folder: `20260917-213619` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A10`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=69.8% and fully-opaque=24.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_pickup_bonus_box.png, env_pickup_repair_pod.png, env_pickup_shield_pod.png, env_pickup_speed_pod.png, env_pickup_ammo_pod.png, env_pickup_ore_pod.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> game pickup props sheet, six separate small cargo and supply objects in an evenly spaced 2x3 grid (two columns, three rows) with generous gaps, left to right then top to bottom, each object isolated on a plain solid pure white background with empty white margins between objects so they can be cut apart, no grid lines, no labels, no text, no shadows on the background. Every object is a top-down orthographic painted render, one step darker than ships, weathered gunmetal and rusted steel, scratches, hull grime, oil stains, pitted metal, cold steel highlight #565C63 rim on the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Subjects in reading order: 1 sealed ordnance crate with banded reinforcement and one small burnt ember #C8461B lamp; 2 maintenance pod with an external tool rack and one burnt ember #C8461B lamp; 3 emitter pod with a steel highlight #565C63 aperture ring and no ember; 4 slim boost pod with two rear vent slots and one burnt ember #C8461B lamp; 5 drum-shaped ammunition canister with a lift lug and no glow; 6 ore container with rusted ochre #6E5B4A and dry rust #8A6A50 ore veins visible at the seam. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_planet_moon

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `94752520b12d3423c4fad8ec1db3f202`
- Run folder: `20260917-213437` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F7F7F8`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=52.0% and fully-opaque=47.2%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_planet_moon.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Airless dead moon, one single centred top-down orthographic render of a spherical rock body, the disc occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars behind it. Surface: cracked grey rock faces in gunmetal dark #2B2F35 and gunmetal mid #3A3F46, one value step darker than ships, heavy cratering with iron black #232629 core shadows, rusted ochre #6E5B4A and dry rust #8A6A50 mineral seams running through the cracks, pitted metal speckle catching the cold steel highlight #565C63 rim along the shadow-side limb, harsh directional key light from the upper left, subtle film grain. No atmosphere, no clouds, no haze, no terminator glow, no emissive light anywhere, no rings. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_jump_gate

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0750fef3d7c8f405cff5461ca353bce7`
- Run folder: `20260917-213508` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03060B`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=75.9% and fully-opaque=19.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_jump_gate.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Jump gate structure, one single centred top-down orthographic render, the structure occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Structure: two heavy anchor pylons joined by a segmented open ring, welded station platework with visible panel seams and rivet lines in gunmetal mid #3A3F46 and gunmetal dark #2B2F35, heavy hull grime films, rust streaks bleeding from the seams, pitted metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember #C8461B warning lamps only, a handful of lamp points along the hull, no ember glow halo, no energy field, no glowing aperture, no interior glow, no beam. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=33.7% and fully-opaque=55.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_nebula_veil

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `18f53944e4ba5824fc9d586a27d4ab2d`
- Run folder: `20260917-213632` (job.json kept alongside the sprites)
- Alpha: kept RGB on void black, no keying (additive blend asset)
- Final files: env_nebula_veil.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Deep space nebula veil, a single square full-frame painterly wash, seamless and tileable in both X and Y with no visible seam, no hard feature touching the frame border. Content: soft drifting washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue grey only, extremely low contrast, faint dust veils and thin wispy structure, subtle film grain over the whole frame. Absolutely no stars, no planets, no ships, no wrecks, no ember or orange of any kind, no bright nebula, no saturated colour, no glow. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## panel_pickups

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1e5843bc528d51267b0994c1361237a0`
- Run folder: `20260917-213619` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A10`, threshold 16, 7x7 median plus tiny-island removal (217 specks dropped), 0.8 px feather; achieved alpha0=70.5% and fully-opaque=24.6%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_pickup_bonus_box.png, env_pickup_repair_pod.png, env_pickup_shield_pod.png, env_pickup_speed_pod.png, env_pickup_ammo_pod.png, env_pickup_ore_pod.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> game pickup props sheet, six separate small cargo and supply objects in an evenly spaced 2x3 grid (two columns, three rows) with generous gaps, left to right then top to bottom, each object isolated on a plain solid pure white background with empty white margins between objects so they can be cut apart, no grid lines, no labels, no text, no shadows on the background. Every object is a top-down orthographic painted render, one step darker than ships, weathered gunmetal and rusted steel, scratches, hull grime, oil stains, pitted metal, cold steel highlight #565C63 rim on the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Subjects in reading order: 1 sealed ordnance crate with banded reinforcement and one small burnt ember #C8461B lamp; 2 maintenance pod with an external tool rack and one burnt ember #C8461B lamp; 3 emitter pod with a steel highlight #565C63 aperture ring and no ember; 4 slim boost pod with two rear vent slots and one burnt ember #C8461B lamp; 5 drum-shaped ammunition canister with a lift lug and no glow; 6 ore container with rusted ochre #6E5B4A and dry rust #8A6A50 ore veins visible at the seam. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_planet_moon

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `94752520b12d3423c4fad8ec1db3f202`
- Run folder: `20260917-213437` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F7F7F8`, threshold 16, 7x7 median plus tiny-island removal (15 specks dropped), 0.8 px feather; achieved alpha0=52.0% and fully-opaque=47.2%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_planet_moon.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Airless dead moon, one single centred top-down orthographic render of a spherical rock body, the disc occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars behind it. Surface: cracked grey rock faces in gunmetal dark #2B2F35 and gunmetal mid #3A3F46, one value step darker than ships, heavy cratering with iron black #232629 core shadows, rusted ochre #6E5B4A and dry rust #8A6A50 mineral seams running through the cracks, pitted metal speckle catching the cold steel highlight #565C63 rim along the shadow-side limb, harsh directional key light from the upper left, subtle film grain. No atmosphere, no clouds, no haze, no terminator glow, no emissive light anywhere, no rings. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_jump_gate

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0750fef3d7c8f405cff5461ca353bce7`
- Run folder: `20260917-213508` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03060B`, threshold 16, 7x7 median plus tiny-island removal (155 specks dropped), 0.8 px feather; achieved alpha0=76.5% and fully-opaque=19.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_jump_gate.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Jump gate structure, one single centred top-down orthographic render, the structure occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Structure: two heavy anchor pylons joined by a segmented open ring, welded station platework with visible panel seams and rivet lines in gunmetal mid #3A3F46 and gunmetal dark #2B2F35, heavy hull grime films, rust streaks bleeding from the seams, pitted metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember #C8461B warning lamps only, a handful of lamp points along the hull, no ember glow halo, no energy field, no glowing aperture, no interior glow, no beam. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:45 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 15x15 median plus tiny-island removal (855 specks dropped), 0.8 px feather; achieved alpha0=42.0% and fully-opaque=54.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_nebula_veil

- Date/time: 2026-09-17 21:45 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `18f53944e4ba5824fc9d586a27d4ab2d`
- Run folder: `20260917-213632` (job.json kept alongside the sprites)
- Alpha: kept RGB on void black, no keying (additive blend asset)
- Final files: env_nebula_veil.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Deep space nebula veil, a single square full-frame painterly wash, seamless and tileable in both X and Y with no visible seam, no hard feature touching the frame border. Content: soft drifting washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue grey only, extremely low contrast, faint dust veils and thin wispy structure, subtle film grain over the whole frame. Absolutely no stars, no planets, no ships, no wrecks, no ember or orange of any kind, no bright nebula, no saturated colour, no glow. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:47 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 21x21 median plus tiny-island removal (269 specks dropped), 0.8 px feather; achieved alpha0=42.5% and fully-opaque=54.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:47 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 21x21 median plus tiny-island removal (269 specks dropped), 0.8 px feather; achieved alpha0=42.5% and fully-opaque=54.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:47 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 21x21 median plus tiny-island removal (269 specks dropped), 0.8 px feather; achieved alpha0=44.6% and fully-opaque=52.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:48 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 21x21 median plus tiny-island removal (269 specks dropped), 0.8 px feather; achieved alpha0=45.1% and fully-opaque=50.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_nebula_veil

- Date/time: 2026-09-17 21:49 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `eb795ca5dbcff18c8c9444ebbd0611a5` (elapsed 27.7s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-214913` keeps `job.json`
- Final files: env_nebula_veil.png
- Status: success

Full SUBJECT text:

> Deep space haze texture, a single square full-frame painterly wash, seamless and tileable in both X and Y with no visible seam and no hard feature touching the frame border. Content is only soft drifting washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue grey only, extremely low contrast, uniform and featureless, mild cloud-like mottling and thin dust veils, subtle film grain over the whole frame. This is a background layer, not a scene: absolutely no stars, no starfield, no ships, no wrecks, no debris, no stations, no asteroids, no planets, no focal point, no silhouettes, no hard shapes, no ember or orange anywhere, no glow, no bright nebula, no saturated colour. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_nebula_veil

- Date/time: 2026-09-17 21:49 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `eb795ca5dbcff18c8c9444ebbd0611a5`
- Run folder: `20260917-214913` (job.json kept alongside the sprites)
- Alpha: kept RGB on void black, no keying (additive blend asset)
- Final files: env_nebula_veil.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Deep space haze texture, a single square full-frame painterly wash, seamless and tileable in both X and Y with no visible seam and no hard feature touching the frame border. Content is only soft drifting washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue grey only, extremely low contrast, uniform and featureless, mild cloud-like mottling and thin dust veils, subtle film grain over the whole frame. This is a background layer, not a scene: absolutely no stars, no starfield, no ships, no wrecks, no debris, no stations, no asteroids, no planets, no focal point, no silhouettes, no hard shapes, no ember or orange anywhere, no glow, no bright nebula, no saturated colour. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---



---

# Phase D wave 2 - generation log

Same model, style block, alpha pipeline and price basis as wave 1 (see `docs/design/ASSET_EXPANSION_SPEC.md`).

---

## panel_pickups

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1e5843bc528d51267b0994c1361237a0`
- Run folder: `20260917-213619` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A10`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=69.8% and fully-opaque=24.7%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_pickup_bonus_box.png, env_pickup_repair_pod.png, env_pickup_shield_pod.png, env_pickup_speed_pod.png, env_pickup_ammo_pod.png, env_pickup_ore_pod.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> game pickup props sheet, six separate small cargo and supply objects in an evenly spaced 2x3 grid (two columns, three rows) with generous gaps, left to right then top to bottom, each object isolated on a plain solid pure white background with empty white margins between objects so they can be cut apart, no grid lines, no labels, no text, no shadows on the background. Every object is a top-down orthographic painted render, one step darker than ships, weathered gunmetal and rusted steel, scratches, hull grime, oil stains, pitted metal, cold steel highlight #565C63 rim on the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Subjects in reading order: 1 sealed ordnance crate with banded reinforcement and one small burnt ember #C8461B lamp; 2 maintenance pod with an external tool rack and one burnt ember #C8461B lamp; 3 emitter pod with a steel highlight #565C63 aperture ring and no ember; 4 slim boost pod with two rear vent slots and one burnt ember #C8461B lamp; 5 drum-shaped ammunition canister with a lift lug and no glow; 6 ore container with rusted ochre #6E5B4A and dry rust #8A6A50 ore veins visible at the seam. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_planet_moon

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `94752520b12d3423c4fad8ec1db3f202`
- Run folder: `20260917-213437` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F7F7F8`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=52.0% and fully-opaque=47.2%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_planet_moon.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Airless dead moon, one single centred top-down orthographic render of a spherical rock body, the disc occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars behind it. Surface: cracked grey rock faces in gunmetal dark #2B2F35 and gunmetal mid #3A3F46, one value step darker than ships, heavy cratering with iron black #232629 core shadows, rusted ochre #6E5B4A and dry rust #8A6A50 mineral seams running through the cracks, pitted metal speckle catching the cold steel highlight #565C63 rim along the shadow-side limb, harsh directional key light from the upper left, subtle film grain. No atmosphere, no clouds, no haze, no terminator glow, no emissive light anywhere, no rings. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_jump_gate

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0750fef3d7c8f405cff5461ca353bce7`
- Run folder: `20260917-213508` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03060B`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=75.9% and fully-opaque=19.5%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_jump_gate.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Jump gate structure, one single centred top-down orthographic render, the structure occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Structure: two heavy anchor pylons joined by a segmented open ring, welded station platework with visible panel seams and rivet lines in gunmetal mid #3A3F46 and gunmetal dark #2B2F35, heavy hull grime films, rust streaks bleeding from the seams, pitted metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember #C8461B warning lamps only, a handful of lamp points along the hull, no ember glow halo, no energy field, no glowing aperture, no interior glow, no beam. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=33.7% and fully-opaque=55.3%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_nebula_veil

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `18f53944e4ba5824fc9d586a27d4ab2d`
- Run folder: `20260917-213632` (job.json kept alongside the sprites)
- Alpha: kept RGB on void black, no keying (additive blend asset)
- Final files: env_nebula_veil.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Deep space nebula veil, a single square full-frame painterly wash, seamless and tileable in both X and Y with no visible seam, no hard feature touching the frame border. Content: soft drifting washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue grey only, extremely low contrast, faint dust veils and thin wispy structure, subtle film grain over the whole frame. Absolutely no stars, no planets, no ships, no wrecks, no ember or orange of any kind, no bright nebula, no saturated colour, no glow. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## panel_pickups

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1e5843bc528d51267b0994c1361237a0`
- Run folder: `20260917-213619` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030A10`, threshold 16, 7x7 median plus tiny-island removal (217 specks dropped), 0.8 px feather; achieved alpha0=70.5% and fully-opaque=24.6%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_pickup_bonus_box.png, env_pickup_repair_pod.png, env_pickup_shield_pod.png, env_pickup_speed_pod.png, env_pickup_ammo_pod.png, env_pickup_ore_pod.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> game pickup props sheet, six separate small cargo and supply objects in an evenly spaced 2x3 grid (two columns, three rows) with generous gaps, left to right then top to bottom, each object isolated on a plain solid pure white background with empty white margins between objects so they can be cut apart, no grid lines, no labels, no text, no shadows on the background. Every object is a top-down orthographic painted render, one step darker than ships, weathered gunmetal and rusted steel, scratches, hull grime, oil stains, pitted metal, cold steel highlight #565C63 rim on the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Subjects in reading order: 1 sealed ordnance crate with banded reinforcement and one small burnt ember #C8461B lamp; 2 maintenance pod with an external tool rack and one burnt ember #C8461B lamp; 3 emitter pod with a steel highlight #565C63 aperture ring and no ember; 4 slim boost pod with two rear vent slots and one burnt ember #C8461B lamp; 5 drum-shaped ammunition canister with a lift lug and no glow; 6 ore container with rusted ochre #6E5B4A and dry rust #8A6A50 ore veins visible at the seam. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_planet_moon

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `94752520b12d3423c4fad8ec1db3f202`
- Run folder: `20260917-213437` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F7F7F8`, threshold 16, 7x7 median plus tiny-island removal (15 specks dropped), 0.8 px feather; achieved alpha0=52.0% and fully-opaque=47.2%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_planet_moon.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Airless dead moon, one single centred top-down orthographic render of a spherical rock body, the disc occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars behind it. Surface: cracked grey rock faces in gunmetal dark #2B2F35 and gunmetal mid #3A3F46, one value step darker than ships, heavy cratering with iron black #232629 core shadows, rusted ochre #6E5B4A and dry rust #8A6A50 mineral seams running through the cracks, pitted metal speckle catching the cold steel highlight #565C63 rim along the shadow-side limb, harsh directional key light from the upper left, subtle film grain. No atmosphere, no clouds, no haze, no terminator glow, no emissive light anywhere, no rings. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_jump_gate

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `0750fef3d7c8f405cff5461ca353bce7`
- Run folder: `20260917-213508` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03060B`, threshold 16, 7x7 median plus tiny-island removal (155 specks dropped), 0.8 px feather; achieved alpha0=76.5% and fully-opaque=19.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_jump_gate.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Jump gate structure, one single centred top-down orthographic render, the structure occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Structure: two heavy anchor pylons joined by a segmented open ring, welded station platework with visible panel seams and rivet lines in gunmetal mid #3A3F46 and gunmetal dark #2B2F35, heavy hull grime films, rust streaks bleeding from the seams, pitted metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember #C8461B warning lamps only, a handful of lamp points along the hull, no ember glow halo, no energy field, no glowing aperture, no interior glow, no beam. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:45 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 15x15 median plus tiny-island removal (855 specks dropped), 0.8 px feather; achieved alpha0=42.0% and fully-opaque=54.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_nebula_veil

- Date/time: 2026-09-17 21:45 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `18f53944e4ba5824fc9d586a27d4ab2d`
- Run folder: `20260917-213632` (job.json kept alongside the sprites)
- Alpha: kept RGB on void black, no keying (additive blend asset)
- Final files: env_nebula_veil.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Deep space nebula veil, a single square full-frame painterly wash, seamless and tileable in both X and Y with no visible seam, no hard feature touching the frame border. Content: soft drifting washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue grey only, extremely low contrast, faint dust veils and thin wispy structure, subtle film grain over the whole frame. Absolutely no stars, no planets, no ships, no wrecks, no ember or orange of any kind, no bright nebula, no saturated colour, no glow. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:47 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 21x21 median plus tiny-island removal (269 specks dropped), 0.8 px feather; achieved alpha0=42.5% and fully-opaque=54.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:47 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 21x21 median plus tiny-island removal (269 specks dropped), 0.8 px feather; achieved alpha0=42.5% and fully-opaque=54.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:47 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 21x21 median plus tiny-island removal (269 specks dropped), 0.8 px feather; achieved alpha0=44.6% and fully-opaque=52.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_debris_field

- Date/time: 2026-09-17 21:48 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `820dc3ecfad139f047b75cf5a2f1217d`
- Run folder: `20260917-213550` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#F6F6F6`, threshold 16, 21x21 median plus tiny-island removal (269 specks dropped), 0.8 px feather; achieved alpha0=45.1% and fully-opaque=50.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_debris_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Space debris field, one single top-down orthographic render of a loose cluster of torn hull fragments, panel shards and shattered plating, the cluster occupying about 70 percent of the frame width and clearly separated with empty gaps between the pieces, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow, no stars. Every fragment is dead metal one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime washed toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. The fragments never touch or overlap. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_nebula_veil

- Date/time: 2026-09-17 21:49 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `eb795ca5dbcff18c8c9444ebbd0611a5` (elapsed 27.7s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-214913` keeps `job.json`
- Final files: env_nebula_veil.png
- Status: success

Full SUBJECT text:

> Deep space haze texture, a single square full-frame painterly wash, seamless and tileable in both X and Y with no visible seam and no hard feature touching the frame border. Content is only soft drifting washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue grey only, extremely low contrast, uniform and featureless, mild cloud-like mottling and thin dust veils, subtle film grain over the whole frame. This is a background layer, not a scene: absolutely no stars, no starfield, no ships, no wrecks, no debris, no stations, no asteroids, no planets, no focal point, no silhouettes, no hard shapes, no ember or orange anywhere, no glow, no bright nebula, no saturated colour. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_nebula_veil

- Date/time: 2026-09-17 21:49 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `eb795ca5dbcff18c8c9444ebbd0611a5`
- Run folder: `20260917-214913` (job.json kept alongside the sprites)
- Alpha: kept RGB on void black, no keying (additive blend asset)
- Final files: env_nebula_veil.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Deep space haze texture, a single square full-frame painterly wash, seamless and tileable in both X and Y with no visible seam and no hard feature touching the frame border. Content is only soft drifting washes of deep void blue #111823 and void haze #1A2230 over a void black #0A0E14 base, desaturated blue grey only, extremely low contrast, uniform and featureless, mild cloud-like mottling and thin dust veils, subtle film grain over the whole frame. This is a background layer, not a scene: absolutely no stars, no starfield, no ships, no wrecks, no debris, no stations, no asteroids, no planets, no focal point, no silhouettes, no hard shapes, no ember or orange anywhere, no glow, no bright nebula, no saturated colour. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_station_mmo

- Date/time: 2026-09-17 21:59 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `9496a64d40d163f8ecc4478b28224ada` (elapsed 37.6s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-215900` keeps `job.json`
- Final files: env_station_mmo.png
- Status: success

Full SUBJECT text:

> Faction mining station exterior, one single centred top-down orthographic render, the station occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Subject: a heavy industrial station of welded platework with heavy horizontal riveted plate rows and chevron weld seams, a central hexagonal hub, two docking arms ending in open clamp frames, ore silo drums along one flank and a squared cargo wing, all in gunmetal mid #3A3F46 and gunmetal dark #2B2F35, one value step darker than ships, with heavy hull grime films, rust streaks from the seams, pitted metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember C8461B warning lamps only, a handful of lamp points along the hull, no ember glow halo, no window glow, no interior light. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_station_ruined

- Date/time: 2026-09-17 21:59 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d7ad0528520841a1e6f6bdd2ddb9030d` (elapsed 37.6s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-215943` keeps `job.json`
- Final files: env_station_ruined.png
- Status: success

Full SUBJECT text:

> Gutted hostile station wreck, one single centred top-down orthographic render, the structure occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Subject: a torn-open station ring, the outer ring snapped and bent, plating ripped away to expose dark ribs and decks, scorch-blackened craters, weld beads over old repairs, one docking arm sheared off and drifting clear of the hull in the same frame, heavy rust streaks and hull grime, pitted metal, everything one value step darker than ships, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. Emissive: two small hot burnt ember C8461B warning lamps only, dying, no ember glow halo, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_ice_field

- Date/time: 2026-09-17 22:00 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `22ab3b3d75176b8fddfe5c19431b2e06` (elapsed 37.7s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-220025` keeps `job.json`
- Final files: env_ice_field.png
- Status: success

Full SUBJECT text:

> Frozen fragment field, one single top-down orthographic render of a cluster of ice-crusted rock shards, the cluster occupying about 70 percent of the frame width with clear empty gaps between the shards, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Every shard is desaturated death-cold rock in gunmetal dark #2B2F35 and iron black #232629 one value step darker than ships, encrusted with a pale crust that catches the cold steel highlight #565C63 rim as frost speckle, cracked faces, battle-damage dents, pitted metal, no colour beyond the fixed palette, no blue tint, no transparency, no glow. Shards never touch. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## panel_props

- Date/time: 2026-09-17 22:00 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d4172bdc7def537cfe370780a62e75ec` (elapsed 39.7s)
- Reference: none (text-to-image)
- Alpha: provided-alpha; run folder `20260917-220029` keeps `job.json`
- Final files: env_prop_hull_nose.png
- Status: success

Full SUBJECT text:

> Dead hull debris props sheet, six separate wreck fragments in an evenly spaced 2x3 grid (three columns, two rows) with generous gaps, left to right then top to bottom, each fragment isolated on a plain solid pure white background with empty white margins between fragments so they can be cut apart, no grid lines, no labels, no text, no shadows on the background, fragments never touching or overlapping. Every fragment is a top-down orthographic painted render one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. Subjects in reading order: 1 a torn bow section with a crushed prow; 2 a mid-hull cargo block with a ripped container rack; 3 a stern section with two cold dead nozzles; 4 a detached hull plate section with rivet rows; 5 a torn drive core housing with exposed rings; 6 a cluster of bent structural ribs. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_ore_cluster

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1e0cfa6d6128b0b08e9a7c1e96a327c0` (elapsed 37.5s)
- Reference: none (text-to-image)
- Alpha: local-keyed; run folder `20260917-220107` keeps `job.json`
- Final files: env_ore_cluster.png
- Status: success

Full SUBJECT text:

> Dense mineable asteroid cluster, one single top-down orthographic render of three large rock bodies joined into a single mass, the cluster occupying about 70 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Rock body is desaturated gunmetal-grey stone in the #2B2F35 to #3A3F46 range, one value step darker than ships, with cracked rock faces, iron black #232629 core shadows, rich ore veins in rusted ochre #6E5B4A and dry rust #8A6A50 running through the cracks and glowing nowhere, dense pitted metal speckle catching the cold steel highlight #565C63 rim, harsh directional key light from the upper left, subtle film grain, no emissive, no glow of any kind. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## panel_props

- Date/time: 2026-09-17 22:01 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d4172bdc7def537cfe370780a62e75ec`
- Run folder: `20260917-220029` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#01060C`, threshold 16, 7x7 median plus tiny-island removal (332 specks dropped), 0.8 px feather; achieved alpha0=66.6% and fully-opaque=24.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_prop_hull_nose.png, env_prop_hull_mid.png, env_prop_hull_stern.png, env_prop_plate_section.png, env_prop_drive_core.png, env_prop_rib_cluster.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Dead hull debris props sheet, six separate wreck fragments in an evenly spaced 2x3 grid (three columns, two rows) with generous gaps, left to right then top to bottom, each fragment isolated on a plain solid pure white background with empty white margins between fragments so they can be cut apart, no grid lines, no labels, no text, no shadows on the background, fragments never touching or overlapping. Every fragment is a top-down orthographic painted render one value step darker than ships: ripped-open plating with bent torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, rust streaks bleeding from seams, hull grime toward trailing edges, oil stains, pitted metal, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. Subjects in reading order: 1 a torn bow section with a crushed prow; 2 a mid-hull cargo block with a ripped container rack; 3 a stern section with two cold dead nozzles; 4 a detached hull plate section with rivet rows; 5 a torn drive core housing with exposed rings; 6 a cluster of bent structural ribs. No emissive, no glow, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_station_mmo

- Date/time: 2026-09-17 22:02 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `9496a64d40d163f8ecc4478b28224ada`
- Run folder: `20260917-215900` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040B12`, threshold 16, 7x7 median plus tiny-island removal (363 specks dropped), 0.8 px feather; achieved alpha0=78.7% and fully-opaque=15.8%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_station_mmo.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Faction mining station exterior, one single centred top-down orthographic render, the station occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Subject: a heavy industrial station of welded platework with heavy horizontal riveted plate rows and chevron weld seams, a central hexagonal hub, two docking arms ending in open clamp frames, ore silo drums along one flank and a squared cargo wing, all in gunmetal mid #3A3F46 and gunmetal dark #2B2F35, one value step darker than ships, with heavy hull grime films, rust streaks from the seams, pitted metal on the older plates, cold steel highlight #565C63 rim tracing the shadow-side silhouette, harsh directional key light from the upper left, subtle film grain. Emissive: small hot burnt ember C8461B warning lamps only, a handful of lamp points along the hull, no ember glow halo, no window glow, no interior light. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_station_ruined

- Date/time: 2026-09-17 22:02 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d7ad0528520841a1e6f6bdd2ddb9030d`
- Run folder: `20260917-215943` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#040A10`, threshold 16, 7x7 median plus tiny-island removal (591 specks dropped), 0.8 px feather; achieved alpha0=78.3% and fully-opaque=15.1%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_station_ruined.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Gutted hostile station wreck, one single centred top-down orthographic render, the structure occupying about 60 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Subject: a torn-open station ring, the outer ring snapped and bent, plating ripped away to expose dark ribs and decks, scorch-blackened craters, weld beads over old repairs, one docking arm sheared off and drifting clear of the hull in the same frame, heavy rust streaks and hull grime, pitted metal, everything one value step darker than ships, cold steel highlight #565C63 rim on the torn edges, harsh directional key light from the upper left, subtle film grain. Emissive: two small hot burnt ember C8461B warning lamps only, dying, no ember glow halo, no fire, no smoke. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_ice_field

- Date/time: 2026-09-17 22:02 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `22ab3b3d75176b8fddfe5c19431b2e06`
- Run folder: `20260917-220025` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#03090F`, threshold 16, 7x7 median plus tiny-island removal (402 specks dropped), 0.8 px feather; achieved alpha0=61.8% and fully-opaque=27.4%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_ice_field.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Frozen fragment field, one single top-down orthographic render of a cluster of ice-crusted rock shards, the cluster occupying about 70 percent of the frame width with clear empty gaps between the shards, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Every shard is desaturated death-cold rock in gunmetal dark #2B2F35 and iron black #232629 one value step darker than ships, encrusted with a pale crust that catches the cold steel highlight #565C63 rim as frost speckle, cracked faces, battle-damage dents, pitted metal, no colour beyond the fixed palette, no blue tint, no transparency, no glow. Shards never touch. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

## env_ore_cluster

- Date/time: 2026-09-17 22:02 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1e0cfa6d6128b0b08e9a7c1e96a327c0`
- Run folder: `20260917-220107` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#050B10`, threshold 16, 7x7 median plus tiny-island removal (609 specks dropped), 0.8 px feather; achieved alpha0=66.2% and fully-opaque=25.6%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: env_ore_cluster.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> Dense mineable asteroid cluster, one single top-down orthographic render of three large rock bodies joined into a single mass, the cluster occupying about 70 percent of the frame width, no tilt and no perspective, isolated on a fully transparent background, no background colour, no backdrop, no ground shadow. Rock body is desaturated gunmetal-grey stone in the #2B2F35 to #3A3F46 range, one value step darker than ships, with cracked rock faces, iron black #232629 core shadows, rich ore veins in rusted ochre #6E5B4A and dry rust #8A6A50 running through the cracks and glowing nowhere, dense pitted metal speckle catching the cold steel highlight #565C63 rim, harsh directional key light from the upper left, subtle film grain, no emissive, no glow of any kind. no planets with atmospheres, no clouds, no bright nebula, no saturated colours, no second accent colour, no chrome, no neon, no text, no watermark, no grid lines.

---

