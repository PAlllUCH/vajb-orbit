# Phase F - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`; `flare-i2i` for reference edits), 2K.
Work order: `docs/gameplay/16_art_design_brief.md`. Style law: `docs/design/STYLE_BIBLE.md`, `docs/design/ICONS_SPEC.md` (section 1 + section 8 amendment), `docs/design/SHIPS_SPEC.md` (section 1 framing constant, sections 3.7-3.9).
Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file` on every run.
Price basis: 10 credits = $0.05 per 2K run (kie.ai console, user-verified); the script's printed 30-credit estimate is the stale hint and the `usage-ledger.jsonl` total over-reports 3x.
Alpha: `--transparent` native first, local matte fallback (`staging/phase_d/reprocess.py`). FX stay RGB on void black for additive blending and are never alpha-keyed (FX_SPEC 0.1).
AI-generated art is not CC0 (AGENTS.md).

---

## ship_miner

- Date/time: 2026-09-18 11:16 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `bd336e1f691f269d8308dceecfa0b762` (elapsed 37.7s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: local matte bg=#040A12 alpha0=73% dropped=147, component split; run folder `20260918-111643` keeps `job.json`
- Final files: ship_miner_front.png, ship_miner_three_quarter.png, ship_miner_side.png, ship_miner_back.png
- Status: success

Full SUBJECT text:

> Delver miner hull rotation sheet, a player mining ship. Framing: top-down orthographic, facing right, ship occupies about 60 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required. Silhouette: the central hull is the largest mass and is a broad flat slab, clearly wider than it is long, the flattest and widest hull in the roster. A ventral cutter bar projects below the centreline along the mid-hull carrying a row of cutting teeth large enough to catch the rim light on their tips, a boxed lidded dorsal ore bin rides above the mid-hull, and twin blunt engine pods flank the stern clear of the slab so their edges read. No weapon mounts, no thorns, no wings. Class markers: the ventral cutter bar plus the dorsal ore bin, a low wide working platform that cannot be mistaken for a boxy segmented freighter, an elongated spine-ridged corvette or a pod-flanked gunship. Weathering density: heavy industrial, hull grime toward the trailing edges, ore dust staining over the slab and the bin lid, oil stains around the engine pods, rust streaks from the rivet seams, pitted metal on the cutter bar, scratches, light battle damage on the forward plate only. Gunmetal mid #3A3F46 and gunmetal dark #2B2F35 hull with a cold steel highlight #565C63 rim. Engines and glow: 2 engines in the twin outboard side pods, dim civilian burnt ember C8461B flares with a faint small ember glow E8703A halo, small and contained, no other glow. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_boneyard

- Date/time: 2026-09-18 11:24 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `717430c0dbbbb4c646a23cecf0b4ba6d` (elapsed 48.0s)
- Style block: `style-block.txt` verbatim
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\ship_gunship_side.png
- Alpha: local matte bg=#F4F4F4 alpha0=77% dropped=1; run folder `20260918-112453` keeps `job.json`
- Final files: ship_boss_boneyard.png
- Status: success

Full SUBJECT text:

> Same gunship-band hull, identical silhouette massing, identical proportions, identical framing, identical camera and identical lighting; re-render only the weathering and the boss core. Framing: top-down orthographic, facing right, ship occupies about 60 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required. Keep the two oversized blocky broadside weapon pods flanking the squat core and the twin recessed stern nozzles exactly as in the reference. New boss feature: the forward plate is split open to expose one wide horizontal ember core slot across the bow shoulder, glowing ember glow E8703A over a burnt ember C8461B heart, contained to the slot and never ambient; two short thorned protrusions project from the bow beside the core slot. Weathering: heaviest in the roster, battle damage with dents, torn plate edges and scorch-blackened craters, weld beads over repairs, scorch marks radiating from the pods and the core slot, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines: burnt ember C8461B flares with small hot ember glow E8703A halos. Keep the render isolated on a fully transparent background with no backdrop and no ground shadow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## ship_boss_pyre

- Date/time: 2026-09-18 11:25 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `17e82022ea43e130e7a0c7fdc847d44d` (elapsed 32.5s)
- Style block: `style-block.txt` verbatim
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\ship_patrol_side.png
- Alpha: local matte bg=#F8F7F8 alpha0=88% dropped=130; run folder `20260918-112531` keeps `job.json`
- Final files: ship_boss_pyre.png
- Status: success

Full SUBJECT text:

> Same frigate-band patrol hull, identical silhouette massing, identical proportions, identical framing, identical camera and identical lighting; re-render only the weathering and the boss core. Framing: top-down orthographic, facing right, ship occupies about 60 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required. Keep the mid-length hull, the forward lance mount at the bow and the clean flat plated sides exactly as in the reference. New boss feature: the single dorsal fin is replaced by a tall stacked altar of three stepped plate segments carrying a vertical ember core in a recessed channel down its face, glowing ember glow E8703A over a burnt ember C8461B heart, contained to the channel and never ambient; short thorned nodes stand along both flanks. Weathering: heaviest in the roster, battle damage with dents, torn plate edges and scorch-blackened craters, weld beads over repairs, scorch marks radiating from the core channel, rust streaks, oil stains, hull grime, pitted metal, scratches. Engines: burnt ember C8461B flares with small hot ember glow E8703A halos. Keep the render isolated on a fully transparent background with no backdrop and no ground shadow. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter_concord

- Date/time: 2026-09-18 11:26 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `eec67686ed1cf7bd608bd811d6587ed5` (elapsed 48.0s)
- Style block: `style-block.txt` verbatim
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\20260917-183314\fighter-enemy-hull-rotation-sheet-four-1-alpha.png
- Alpha: local matte bg=#010408 alpha0=83% dropped=128, component split; run folder `20260918-112624` keeps `job.json`
- Final files: ship_fighter_concord_front.png, ship_fighter_concord_three_quarter.png, ship_fighter_concord_side.png, ship_fighter_concord_back.png
- Status: success

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. This is the Concord of Iron bounty-hunter livery. New plate pattern: heavy horizontal riveted plate rows stacked across the hull with squared weld seams and stamped serial bands along the flanks, regulation naval refit, uniform and maintained. Weathering: extra hull grime film and heavy oil staining over the standard scratches, no battle damage, dented forward plate only. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter_meridian

- Date/time: 2026-09-18 11:27 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `b8fafd637a66c5a512477f15b8065e24` (elapsed 50.3s)
- Style block: `style-block.txt` verbatim
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\20260917-183314\fighter-enemy-hull-rotation-sheet-four-1-alpha.png
- Alpha: local matte bg=#000001 alpha0=82% dropped=112, component split; run folder `20260918-112721` keeps `job.json`
- Final files: ship_fighter_meridian_front.png, ship_fighter_meridian_three_quarter.png, ship_fighter_meridian_side.png, ship_fighter_meridian_back.png
- Status: success

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. This is the Meridian Free Ports bounty-hunter livery. New plate pattern: long continuous plate bands wrapping the hull with sparse rivet lines, very few panel seams and mismatched replacement plates swapped in around the engine block, company-town patchwork. Weathering: scratches, oil stains and busy handling scuffing, hull grime along the seams, no battle damage. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter_choir

- Date/time: 2026-09-18 11:28 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `5c10df73ba7db9c318956a80490ff0be` (elapsed 42.8s)
- Style block: `style-block.txt` verbatim
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\20260917-183314\fighter-enemy-hull-rotation-sheet-four-1-alpha.png
- Alpha: local matte bg=#F7F7F7 alpha0=81% dropped=1, component split; run folder `20260918-112813` keeps `job.json`
- Final files: ship_fighter_choir_front.png, ship_fighter_choir_three_quarter.png, ship_fighter_choir_side.png, ship_fighter_choir_back.png
- Status: success

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. This is the Ember Choir bounty-hunter livery. New plate pattern: dense pitted metal scored with soot-blackened ritual seam grooves cut in a radial pattern over the hull, tally notches cut into the plating and crude weld-bead patch repairs. Weathering: heaviest rust streaks and battle damage over the front plating, scorch marks around the engine block, pitted metal. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter_concord

- Date/time: 2026-09-18 11:48 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `8bc854a475c4440e4f72789ddc015510` (elapsed 43.3s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\20260917-183314\fighter-enemy-hull-rotation-sheet-four-1-alpha.png
- Alpha: local matte bg=#03060A alpha0=84% dropped=148, component split; run folder `20260918-114850` keeps `job.json`
- Final files: ship_fighter_concord_front.png, ship_fighter_concord_three_quarter.png, ship_fighter_concord_side.png, ship_fighter_concord_back.png
- Note: framing constant added verbatim to the livery prompts so acceptance item 4 (framing constant on every hull render) holds for the liveries too, not just the new hulls; the run is repeated so the shipped art matches the logged prompt.
- Status: success

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. Framing constant, per cell: top-down orthographic, facing right, ship occupies about 60 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required. This is the Concord of Iron bounty-hunter livery. New plate pattern: heavy horizontal riveted plate rows stacked across the hull with squared weld seams and stamped serial bands along the flanks, regulation naval refit, uniform and maintained. Weathering: extra hull grime film and heavy oil staining over the standard scratches, no battle damage, dented forward plate only. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter_meridian

- Date/time: 2026-09-18 11:49 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `a77541cb6e78bb26233104fc34f9352e` (elapsed 53.4s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\20260917-183314\fighter-enemy-hull-rotation-sheet-four-1-alpha.png
- Alpha: local matte bg=#02070D alpha0=83% dropped=80, component split; run folder `20260918-114951` keeps `job.json`
- Final files: ship_fighter_meridian_front.png, ship_fighter_meridian_three_quarter.png, ship_fighter_meridian_side.png, ship_fighter_meridian_back.png
- Note: framing constant added verbatim to the livery prompts so acceptance item 4 (framing constant on every hull render) holds for the liveries too, not just the new hulls; the run is repeated so the shipped art matches the logged prompt.
- Status: success

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. Framing constant, per cell: top-down orthographic, facing right, ship occupies about 60 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required. This is the Meridian Free Ports bounty-hunter livery. New plate pattern: long continuous plate bands wrapping the hull with sparse rivet lines, very few panel seams and mismatched replacement plates swapped in around the engine block, company-town patchwork. Weathering: scratches, oil stains and busy handling scuffing, hull grime along the seams, no battle damage. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## livery_fighter_choir

- Date/time: 2026-09-18 11:50 local
- Model: `gpt-image-2-5-flare-image-to-image` (`flare-i2i`), 2K, 1:1
- Job id: `74ce2105c27d9014922e3e9b49d76552` (elapsed 47.9s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit\assets\ships\20260917-183314\fighter-enemy-hull-rotation-sheet-four-1-alpha.png
- Alpha: local matte bg=#03080C alpha0=83% dropped=132, component split; run folder `20260918-115046` keeps `job.json`
- Final files: ship_fighter_choir_front.png, ship_fighter_choir_three_quarter.png, ship_fighter_choir_side.png, ship_fighter_choir_back.png
- Note: framing constant added verbatim to the livery prompts so acceptance item 4 (framing constant on every hull render) holds for the liveries too, not just the new hulls; the run is repeated so the shipped art matches the logged prompt.
- Status: success

Full SUBJECT text:

> Same 2x2 rotation sheet of the same enemy fighter hull, identical silhouette, identical proportions, identical framing, identical camera, identical lighting and identical engine glow; re-render only the hull plate pattern and the weathering distribution. Framing constant, per cell: top-down orthographic, facing right, ship occupies about 60 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required. This is the Ember Choir bounty-hunter livery. New plate pattern: dense pitted metal scored with soot-blackened ritual seam grooves cut in a radial pattern over the hull, tally notches cut into the plating and crude weld-bead patch repairs. Weathering: heaviest rust streaks and battle damage over the front plating, scorch marks around the engine block, pitted metal. Keep the short dart-like hull, the twin close-set engines and the burnt ember C8461B engine flares exactly as in the reference, keep the four cells on a fully transparent background with empty transparent margins, and keep the same reading order: front, three-quarter, side, back. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## f2_drone_swarm

- Date/time: 2026-09-18 13:31 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `a882721ca5520cd50cc2727585136096` (elapsed 27.4s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: none (text-to-image)
- Alpha: local matte bg=#F9F9F9 alpha0=85% dropped=2593, component split; run folder `20260918-133108` keeps `job.json`
- Final files: ship_drone_swarm_front.png, ship_drone_swarm_three_quarter.png, ship_drone_swarm_side.png, ship_drone_swarm_back.png
- Status: success

Full SUBJECT text:

> Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, immediately readable as smaller than every other hull. Weathering density: light, scratches and hull grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. The drone is drawn small inside each cell, occupying about 40 percent of its cell width. THE HULL CARRIES NO PALE VALUE ANYWHERE: no white, no cream, no pale grey, no bright specular highlight, no rim light and no white or light-grey shard, spike, sliver, chip or speck anywhere on the hull or along its silhouette; the brightest colour anywhere on the ship is the palette's cold steel highlight #565C63 and even that is used only as a thin edge catch, never as a large or bright area. Every silhouette edge is a crisp dark edge against empty transparent space, with no white anti-aliased fringe, no pale halo, no white glow and no bright outline tracing the hull. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---

## f2_drone_swarm - post-only re-cut

- Date/time: 2026-09-18 13:35 local
- Reason: free local re-cut of the stored master (split method change, no API call).
- Master: `20260918-133108`
- Reference: none (text-to-image)
- Alpha: local matte bg=#F9F9F9 alpha0=85% dropped=2593, component split; run folder `20260918-133108` keeps `job.json`
- Final files: ship_drone_swarm_front.png, ship_drone_swarm_three_quarter.png, ship_drone_swarm_side.png, ship_drone_swarm_back.png
- Status: success

Full SUBJECT text:

> Swarm drone enemy hull rotation sheet, a tiny hostile autonomous shard. Silhouette: small angular shard-shaped body, barely wider than a missile, one stubby thruster at the tail, two minimal side nubs, no cockpit canopy and no windows. Class markers: shard-like compact body with a single engine, immediately readable as smaller than every other hull. Weathering density: light, scratches and hull grime only, no battle damage. Engines and glow: 1 engine, small hot burnt ember C8461B flare only. The drone is drawn small inside each cell, occupying about 40 percent of its cell width. THE HULL CARRIES NO PALE VALUE ANYWHERE: no white, no cream, no pale grey, no bright specular highlight, no rim light and no white or light-grey shard, spike, sliver, chip or speck anywhere on the hull or along its silhouette; the brightest colour anywhere on the ship is the palette's cold steel highlight #565C63 and even that is used only as a thin edge catch, never as a large or bright area. Every silhouette edge is a crisp dark edge against empty transparent space, with no white anti-aliased fringe, no pale halo, no white glow and no bright outline tracing the hull. four separate views of one and the same ship in an evenly spaced 2x2 grid with generous gaps, the four ships isolated on a fully transparent background with completely empty transparent margins separating the cells so they can be cut apart, no background colour, no backdrop, no ground shadow, no grid lines, no labels. All four views top-down orthographic with no tilt and no perspective. Top-left cell: front view, bow pointing up. Top-right cell: three-quarter view, bow rotated 45 degrees. Bottom-left cell: side view, bow pointing right. Bottom-right cell: back view, bow pointing down. Framing per cell: the ship occupies about 60 percent of its own cell width, centroid at its cell centre. Identical proportions, identical palette and identical lighting in all four cells. no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.

---


## f2 drone swarm post-passes (C3) - free, local, no API call

- Date/time: 2026-09-18 13:58 local
- `staging/phase_d/defringe_edges.py --apply` rewrote the soft outer band (34 325 px, band
  mean luminance 206.6 -> 122.3).
- `silhouette_clean.py --apply` (new in F.2) recoloured the model's near-white silhouette
  needles to their nearest dark hull pixel - alpha untouched, ember-adjacent pixels protected
  so the engine flare survives. Visible pale pixels in the front view: 4 934 -> 0.
- A second defringe pass resolved the band against the now-dark needles (6 188 px).
- Result (qc_f1/qc_f2 fringe): band mean luminance 49.7-58.2 and 0-33 bright pixels of about
  5 500 band px per view (was 139-158 and 822-1 103); all four views PASS. The raw cuts stay
  reproducible with `wave_f.py f2_drone_swarm --post-only`, the post-defringe state is in
  `staging/phase_d/_fringe_backup/`.
