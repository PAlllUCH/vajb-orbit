# Phase D wave 1 - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`, `flare-i2i` for edits), 2K. Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file`.
Spec: `docs/design/ASSET_EXPANSION_SPEC.md`. Price basis $0.05 per 2K run (user-verified); the script's printed 30-credit estimate is the stale hint.
Alpha: `--transparent` native first, `--strip-bg local` fallback; splitting via the alpha channel (`--split-only`). AI-generated art is not CC0 (AGENTS.md).

---

## panel_equipment

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d1abce5c2ab7ec9c2d9817c1839a7e7b`
- Run folder: `20260917-213441` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030910`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=72.7% and fully-opaque=21.1%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: icon_equip_generator.png, icon_equip_shield_gen.png, icon_equip_engine.png, icon_equip_extra.png, icon_equip_module.png, icon_equip_drone.png, icon_equip_pet.png, icon_ammo_laser.png, icon_ammo_rocket.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 generator core, a rectangular housing with three vertical coil slats and a base mount; 2 shield generator, a circular emitter ring on a square base plate with two anchor lugs; 3 drive nozzle, a truncated cone with an inner combustion ring and two flanking stabiliser fins; 4 utility pod, a boxy module with a side latch bracket and a top connector stub; 5 upgrade module, stacked dual-slab boards with three edge connector teeth on one side; 6 combat drone, a small arrowhead body with two side thruster nubs and no cockpit; 7 pet unit, a rounded shell body with one forward sensor notch and three underside clamps; 8 laser ammo cell, a vertical cylinder with a banded waist and a squared charge terminal on top; 9 rocket magazine, a rectangular rack holding two upright ordnance rounds. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour.

---

## panel_map_markers

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `f9e0be972effed65497a1a74782890f6`
- Run folder: `20260917-213529` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#070A10`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.0% and fully-opaque=14.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: icon_map_node_home.png, icon_map_node_neutral.png, icon_map_node_pvp.png, icon_map_node_danger.png, icon_map_node_asteroid.png, icon_map_node_station.png, icon_map_node_gate.png, icon_map_bookmark.png, icon_map_route.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 hex node with a solid inner dot (home sector); 2 plain hex node with an empty centre (neutral sector); 3 hex node crossed by a single diagonal bar (pvp sector); 4 hex node with one downward barb under it (danger sector); 5 irregular angular rock cluster node (asteroid field); 6 hexagonal ring node (station); 7 twin-arc gate node with a gap in the middle (jump gate); 8 pennant flag with a notched tail (bookmark); 9 broken path line with three waypoint ticks (plotted route). no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour.

---

## panel_equipment

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d1abce5c2ab7ec9c2d9817c1839a7e7b`
- Run folder: `20260917-213441` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030910`, threshold 16, 7x7 median plus tiny-island removal (268 specks dropped), 0.8 px feather; achieved alpha0=73.5% and fully-opaque=21.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: icon_equip_generator.png, icon_equip_shield_gen.png, icon_equip_engine.png, icon_equip_extra.png, icon_equip_module.png, icon_equip_drone.png, icon_equip_pet.png, icon_ammo_laser.png, icon_ammo_rocket.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 generator core, a rectangular housing with three vertical coil slats and a base mount; 2 shield generator, a circular emitter ring on a square base plate with two anchor lugs; 3 drive nozzle, a truncated cone with an inner combustion ring and two flanking stabiliser fins; 4 utility pod, a boxy module with a side latch bracket and a top connector stub; 5 upgrade module, stacked dual-slab boards with three edge connector teeth on one side; 6 combat drone, a small arrowhead body with two side thruster nubs and no cockpit; 7 pet unit, a rounded shell body with one forward sensor notch and three underside clamps; 8 laser ammo cell, a vertical cylinder with a banded waist and a squared charge terminal on top; 9 rocket magazine, a rectangular rack holding two upright ordnance rounds. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour.

---

## panel_map_markers

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `f9e0be972effed65497a1a74782890f6`
- Run folder: `20260917-213529` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#070A10`, threshold 16, 7x7 median plus tiny-island removal (156 specks dropped), 0.8 px feather; achieved alpha0=82.7% and fully-opaque=13.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: icon_map_node_home.png, icon_map_node_neutral.png, icon_map_node_pvp.png, icon_map_node_danger.png, icon_map_node_asteroid.png, icon_map_node_station.png, icon_map_node_gate.png, icon_map_bookmark.png, icon_map_route.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 hex node with a solid inner dot (home sector); 2 plain hex node with an empty centre (neutral sector); 3 hex node crossed by a single diagonal bar (pvp sector); 4 hex node with one downward barb under it (danger sector); 5 irregular angular rock cluster node (asteroid field); 6 hexagonal ring node (station); 7 twin-arc gate node with a gap in the middle (jump gate); 8 pennant flag with a notched tail (bookmark); 9 broken path line with three waypoint ticks (plotted route). no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour.

---



---

# Phase D wave 2 - generation log

Same model, style block, alpha pipeline and price basis as wave 1 (see `docs/design/ASSET_EXPANSION_SPEC.md`).

---

## panel_equipment

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d1abce5c2ab7ec9c2d9817c1839a7e7b`
- Run folder: `20260917-213441` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030910`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=72.7% and fully-opaque=21.1%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: icon_equip_generator.png, icon_equip_shield_gen.png, icon_equip_engine.png, icon_equip_extra.png, icon_equip_module.png, icon_equip_drone.png, icon_equip_pet.png, icon_ammo_laser.png, icon_ammo_rocket.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 generator core, a rectangular housing with three vertical coil slats and a base mount; 2 shield generator, a circular emitter ring on a square base plate with two anchor lugs; 3 drive nozzle, a truncated cone with an inner combustion ring and two flanking stabiliser fins; 4 utility pod, a boxy module with a side latch bracket and a top connector stub; 5 upgrade module, stacked dual-slab boards with three edge connector teeth on one side; 6 combat drone, a small arrowhead body with two side thruster nubs and no cockpit; 7 pet unit, a rounded shell body with one forward sensor notch and three underside clamps; 8 laser ammo cell, a vertical cylinder with a banded waist and a squared charge terminal on top; 9 rocket magazine, a rectangular rack holding two upright ordnance rounds. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour.

---

## panel_map_markers

- Date/time: 2026-09-17 21:41 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `f9e0be972effed65497a1a74782890f6`
- Run folder: `20260917-213529` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#070A10`, threshold 16, 7x7 median for starfield speckle, 0.8 px feather; achieved alpha0=82.0% and fully-opaque=14.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: icon_map_node_home.png, icon_map_node_neutral.png, icon_map_node_pvp.png, icon_map_node_danger.png, icon_map_node_asteroid.png, icon_map_node_station.png, icon_map_node_gate.png, icon_map_bookmark.png, icon_map_route.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 hex node with a solid inner dot (home sector); 2 plain hex node with an empty centre (neutral sector); 3 hex node crossed by a single diagonal bar (pvp sector); 4 hex node with one downward barb under it (danger sector); 5 irregular angular rock cluster node (asteroid field); 6 hexagonal ring node (station); 7 twin-arc gate node with a gap in the middle (jump gate); 8 pennant flag with a notched tail (bookmark); 9 broken path line with three waypoint ticks (plotted route). no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour.

---

## panel_equipment

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d1abce5c2ab7ec9c2d9817c1839a7e7b`
- Run folder: `20260917-213441` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#030910`, threshold 16, 7x7 median plus tiny-island removal (268 specks dropped), 0.8 px feather; achieved alpha0=73.5% and fully-opaque=21.0%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: icon_equip_generator.png, icon_equip_shield_gen.png, icon_equip_engine.png, icon_equip_extra.png, icon_equip_module.png, icon_equip_drone.png, icon_equip_pet.png, icon_ammo_laser.png, icon_ammo_rocket.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 generator core, a rectangular housing with three vertical coil slats and a base mount; 2 shield generator, a circular emitter ring on a square base plate with two anchor lugs; 3 drive nozzle, a truncated cone with an inner combustion ring and two flanking stabiliser fins; 4 utility pod, a boxy module with a side latch bracket and a top connector stub; 5 upgrade module, stacked dual-slab boards with three edge connector teeth on one side; 6 combat drone, a small arrowhead body with two side thruster nubs and no cockpit; 7 pet unit, a rounded shell body with one forward sensor notch and three underside clamps; 8 laser ammo cell, a vertical cylinder with a banded waist and a squared charge terminal on top; 9 rocket magazine, a rectangular rack holding two upright ordnance rounds. no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour.

---

## panel_map_markers

- Date/time: 2026-09-17 21:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `f9e0be972effed65497a1a74782890f6`
- Run folder: `20260917-213529` (job.json kept alongside the sprites)
- Alpha: local matte, background estimated `#070A10`, threshold 16, 7x7 median plus tiny-island removal (156 specks dropped), 0.8 px feather; achieved alpha0=82.7% and fully-opaque=13.9%. `--transparent` was requested but the rendered void background won, so the matte is derived locally (free).
- Final files: icon_map_node_home.png, icon_map_node_neutral.png, icon_map_node_pvp.png, icon_map_node_danger.png, icon_map_node_asteroid.png, icon_map_node_station.png, icon_map_node_gate.png, icon_map_bookmark.png, icon_map_route.png
- Status: success (reprocessing pass)

Full SUBJECT text:

> flat vector icon sheet, 3x3 grid (icons arranged left to right, top to bottom), generous even gaps between icons, plain solid pure white background, isolated objects, icons drawn as single-colour flat silhouettes in iron black #232629 with clean uniform strokes, hard mitred corners, corner radius zero. For this sheet only, the flat vector interpretation overrides the painted metal style. Subjects in reading order: 1 hex node with a solid inner dot (home sector); 2 plain hex node with an empty centre (neutral sector); 3 hex node crossed by a single diagonal bar (pvp sector); 4 hex node with one downward barb under it (danger sector); 5 irregular angular rock cluster node (asteroid field); 6 hexagonal ring node (station); 7 twin-arc gate node with a gap in the middle (jump gate); 8 pennant flag with a notched tail (bookmark); 9 broken path line with three waypoint ticks (plotted route). no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, no shadows, no text, no watermark, no grid lines, no labels, no multicolour.

---

