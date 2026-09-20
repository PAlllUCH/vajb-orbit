# Vajb Orbit — assets/env generation log

Append-only log for every generated environment asset. AI-generated art is not CC0. One section per batch; the styles come from vajb-orbit/assets/style-block.txt passed via --style-file and are appended verbatim by the generator script, so each subject text below is the asset-specific part only.

## G2 — asteroids + props (2026-09-17, batch worker G2)

Common settings for all three runs: model `gpt-image-2-5-flare-text-to-image` (alias `flare`), `--aspect 1:1 --resolution 2K`, `--strip-bg local`, `--style-file vajb-orbit/assets/style-block.txt` appended verbatim to every subject, no retries needed. Price basis per GENERATION_PLAN.md: 10 tokens = $0.05 per 2K request. AI art is not CC0.

### Run 1 — asteroid 3x3 panel — success

- Date/time: 2026-09-17 18:30 +0200 (submitted), split 18:31
- Job id: `e6777d57e4e9c3b1b47b75161423bbfe`
- Raw run folder: `vajb-orbit/assets/env/20260917-183047/` (master `one-3-by-3-grid-panel-of-nine-separate-a-1.png`, alpha `...-1-alpha.png`, 9 cuts, `job.json`)
- Final files (9): `env_asteroid_L1.png`, `env_asteroid_L2.png`, `env_asteroid_L3.png`, `env_asteroid_M1.png`, `env_asteroid_M2.png`, `env_asteroid_M3.png`, `env_asteroid_S1.png`, `env_asteroid_S2.png`, `env_asteroid_S3.png`
- Manifest: the run `job.json` is copied beside every final file as `<final>.job.json`
- Status: master 2048x2048, flat void black background keyed out (corner alpha 0), `--split` returned exactly 9 cuts, splitter orders top-to-bottom then left-to-right, so the auto-order matches the required row-major naming with no manual remap. Verified visually on a labeled contact sheet: 01-03 are the large tier (649x676, 555x642, 636x649), 04-06 medium (522x482, 499x552, 539x519), 07-09 small compact shatter fragments (314x329, 370x361, 336x340); all nine silhouettes read as distinct. Ore veins in rusted ochre `#6E5B4A` / dry rust `#8A6A50`, pitted metal speckle, cracked faces and battle-damage dents visible; no emissive, no glow.
- Cut mapping: `-asset-01` -> `env_asteroid_L1.png`, `-asset-02` -> `env_asteroid_L2.png`, `-asset-03` -> `env_asteroid_L3.png`, `-asset-04` -> `env_asteroid_M1.png`, `-asset-05` -> `env_asteroid_M2.png`, `-asset-06` -> `env_asteroid_M3.png`, `-asset-07` -> `env_asteroid_S1.png`, `-asset-08` -> `env_asteroid_S2.png`, `-asset-09` -> `env_asteroid_S3.png`
- Subject text:

```
One 3 by 3 grid panel of nine separate asteroids on a flat void black #0A0E14 background, three rows of three, each asteroid centered in its own cell with wide clean empty void margins between the cells, no grid lines, no labels, no text, no stars. Row 1: three large asteroids, each filling most of its cell as a dominant irregular mass. Row 2: three medium asteroids with clear silhouette variety. Row 3: three small compact shatter fragments. Mineable asteroids: visible ore veins in rusted ochre #6E5B4A and dry rust #8A6A50 running through cracked rock faces, pitted metal speckle catching the rim light as micro-dotted erosion, cracked faces and battle-damage dents, large-scale weathering. Rock body is desaturated gunmetal-grey rock one value step darker than ships, harsh upper-left key light, thin cold steel rim on shadow-side edges, iron black #232629 core shadow. All nine silhouettes differ at a glance. No emissive, no glow, the background stays flat void black.
```

### Run 2 — wreck hulk prop — success

- Date/time: 2026-09-17 18:32 +0200
- Job id: `5ea6bcdc7e0f066549333c2fa7539397`
- Raw run folder: `vajb-orbit/assets/env/20260917-183215/`
- Final files: `env_wreck_hulk.png` (trimmed to content, 1877x1487, alpha kept) + `env_wreck_hulk.png.job.json`
- Post: `--strip-bg local` only (no split), then trimmed to content per ENVIRONMENT_SPEC §5; corner alpha 0 on the source render.
- Status: torn hull segment with ripped-open plating, bent torn plate edges, scorch-blackened craters, weld beads, exposed ribs, oil stains and grime heavier toward the trailing edges, rust streaks from seams, cold steel rim on the torn edges. No emissive.
- Subject text:

```
Single prop asset on a flat void black #0A0E14 background, top-down orthographic view: one torn hull segment of a dead capital ship, centered with a clean empty void margin all around it, no text, no labels, no stars. Ripped-open plating with bent and torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed structural ribs, battle damage as the dominant vocabulary. Oil stains and hull grime washes, heavier toward the trailing edges, rust streaks bleeding from seams, pitted metal. Harsh upper-left key light with a thin cold pale steel rim tracing the torn edges so the silhouette reads against the void. Value one step darker than ships. No emissive, no glow, the background stays flat void black.
```

### Run 3 — station prop — success

- Date/time: 2026-09-17 18:32 +0200
- Job id: `8ef438c650c70ace5f034bdda794b9c1`
- Raw run folder: `vajb-orbit/assets/env/20260917-183246/`
- Final files: `env_station.png` (2048x2048 RGBA, alpha kept, untouched 2K 1:1 per ENVIRONMENT_SPEC §6, which asks for no trim) + `env_station.png.job.json`
- Post: `--strip-bg local` only (no split); corner alpha 0 verified.
- Status: welded platework in gunmetal mid/dark, panel seams and rivet lines, heavy hull grime, rust streaks from seams and rivets, pitted metal on older plates; warning lamps in burnt ember #C8461B only, small and contained with no glow halo beyond the lamp points; no other glow, no text, no stars.
- Subject text:

```
Single prop asset on a flat void black #0A0E14 background, top-down orthographic view: one hostile station exterior, centered with a clean empty void margin all around it, no text, no labels, no stars. Welded platework in gunmetal mid and gunmetal dark, panel seams and rivet lines, heavy hull grime films, rust streaks running from seams and rivets, pitted metal on the older plates, battle-damage dents. Warning lamps in burnt ember #C8461B only: small, hot, contained lamp points along the hull, with no ember glow halo beyond the lamp points themselves. Harsh upper-left key light with a cold steel rim tracing the shadow-side silhouette. Value one step darker than ships. No other glow anywhere, the background stays flat void black.
```

### G2 batch summary

- Runs: 3/3 succeeded, 0 failures, 0 retries (no `sunburst` fallback needed).
- Spend: 3 x $0.05 = $0.15 per GENERATION_PLAN.md price basis (the script printed a stale $0.15/30-credit hint per run; ignored).
- Files delivered: 11 finals in `vajb-orbit/assets/env/` (9 asteroids + wreck hulk + station) plus 11 `<final>.job.json` manifests.
- Review notes: the master asteroid panel render carries a faint blue-black vignette rather than a mathematically flat void, so the keyer leaves a thin dark halo and a small amount of partial alpha around object edges; silhouettes read cleanly and corners are fully transparent. Station lamps are contained ember points only. No file from G1 was touched; log appended, not overwritten.
## G1 — environments (2026-09-17, batch worker G1)

Common settings for every G1 run: primary model `gpt-image-2-5-flare-text-to-image` (alias `flare`), retry fallback `gpt-image-2-5-sunburst-text-to-image` (alias `sunburst`); `--style-file vajb-orbit/assets/style-block.txt` appended verbatim to every subject by the generator script (so each subject text below is the asset-specific part only); no `--strip-bg`, no `--split` — these are full-bleed background layers. Price basis per GENERATION_PLAN.md: 10 tokens = $0.05 per 2K request. AI art is not CC0.

**Size deviation from ENVIRONMENT_SPEC (needs an orchestrator decision).** Every G1 render came back at the model 2K tier maximum long edge of 2048 px: 2048x1152 for the 16:9 renders, 2048x2048 for the 1:1 layers — not the 2560x1440 that ENVIRONMENT_SPEC §2/§3 names for 2K-wide 16:9. The G1 brief forbids resizing, so the native renders are delivered unchanged. Reaching 2560x1440 would need a 4K render (4096x2304, one extra $0.05 run each) plus a downscale; not done here.

**Subject-authoring note.** The three starfield layers must be object-free textures, but the shared style block opens with weathered-metal wording (hull grime, rust streaks, battle damage, engines/weapons glow). On the first attempt all three layers came back as painted *spacecraft* scenes instead of textures. The retries that succeeded front-load an explicit genre tag (seamless tileable texture / abstract flat 2D background plate, not a scene, no objects of any kind) plus explicit object negatives; that wording is what made the difference and should be reused for any future texture-layer work in this project.

### Run 1 — `env_menu_bg.png` (16:9) — success

- Date/time: 2026-09-17 18:31 +0200
- Model: `gpt-image-2-5-flare-text-to-image` (flare)
- Job id: `a31c34c580e9a84faeeb76e48021c1af`
- Raw run folder: `vajb-orbit/assets/env/20260917-183105/`
- Final files: `env_menu_bg.png` (2048x1152) + `env_menu_bg.png.job.json`
- Aspect / resolution: 16:9, 2K
- Status: one small burning wreck only, ember core and halo confined to a single warm cluster at x 76-82 %, y 58-66 % (lower-right third); horizontal-third luma 7.6 / 8.9 / 12.6, so the left third is the darkest, quietest region for the title and button stack; no second accent anywhere in the frame; edge zones stay void/dust for the UV scroll wrap.
- Subject text:

```
Wide cinematic top-down orthographic vista of a wreck-strewn battlefield drifting in deep void blue, no perspective tilt. Scattered torn hull fragments and debris shards, faint pitted-metal wreckage shapes half lost in shadow, drifting dust veils in void haze, sparse faint stars. Harsh upper-left key light with cold steel highlight rims on fragment edges, heavy film grain over the whole frame. Exactly one small distant burning wreck, off-centre in the lower-right third, burnt ember core with a faint ember glow halo, no other accent or glow anywhere. Composition: the left side and centre-left stay quiet, dark, low-detail negative space for a title lockup and a button stack, busiest wreckage detail sits lower-right around and behind the burning wreck, detail density falling off toward the left and upper-left, edge zones kept as void and dust so a slow UV scroll wraps cleanly. Dark overall and desaturated, background sits in the void black to deep void blue value band with lit debris edges only one step brighter. No planets, no bright nebula, no saturated colour, no second accent colour, no text, no watermark, no grid lines.
```

### Run 2 — `env_loading_bg.png` (16:9) — success

- Date/time: 2026-09-17 18:31 +0200 (downloaded 18:31:53)
- Model: `gpt-image-2-5-flare-text-to-image` (flare)
- Job id: `c43e2aca50adb6a9d91bef547913491c`
- Raw run folder: `vajb-orbit/assets/env/20260917-183150/`
- Final files: `env_loading_bg.png` (2048x1152) + `env_loading_bg.png.job.json`
- Aspect / resolution: 16:9, 2K
- Status: darker recentered crop of the same vista family (mean luma 9/14/19 versus 10/16/23 for the menu render, roughly the requested grade); no ember, no lamp and no warm pixel anywhere in the frame (warm-pixel test over the full render returned none), so it composites at 40 % opacity over void black without carrying an accent. Review note: the brightest mass sits centre-right rather than right; acceptable for a backdrop that is shown at 40 % opacity behind a centred loading readout.
- Subject text:

```
Darker, tighter, recentered crop of the same wide cinematic top-down orthographic wreck battlefield vista family, no perspective tilt, recentered toward the wreck and debris mass and graded about twenty percent darker. Scattered torn hull fragments and debris shards, faint pitted-metal wreckage shapes half lost in shadow, drifting dust veils in void haze, sparse faint stars. Harsh upper-left key light with cold steel highlight rims on fragment edges, heavy film grain. The burning wreck is absent or fully extinguished: no ember, no glow, no accent and no lamps anywhere in the frame. Authored to be displayed at forty percent opacity over void black, so silhouette edges and contrast must stay readable at half opacity. Edge zones kept as void and dust so a slow UV scroll wraps cleanly. Dark overall and desaturated, background sits in the void black to deep void blue value band with lit debris edges only one step brighter. No planets, no bright nebula, no saturated colour, no second accent colour, no text, no watermark, no grid lines.
```

### Run 3 — `env_stars_layer1.png` (1:1) — success on retry

- Date/time: 2026-09-17 18:37 +0200 (first attempt 18:32)
- Model: `gpt-image-2-5-flare-text-to-image` (flare)
- Job id: `b491dbf4316f5e4dabbda8a9fa700119` (first attempt `21f7518742233d5a6249b86cde0c1687`, rejected as off-subject)
- Raw run folder: `vajb-orbit/assets/env/20260917-183757/` (first attempt `20260917-183242/`)
- Final files: `env_stars_layer1.png` (2048x2048) + `env_stars_layer1.png.job.json`
- Aspect / resolution: 1:1, 2K
- Status: sparse faint star points on near-black void, low density, no colour beyond faint white/pale grey; bright-pixel (luma > 80) coverage 0.08 %, no warm pixel anywhere. Tile wrap check: left-column versus right-column mean difference 0.71 and top-row versus bottom-row 0.85 against a 0.82 interior-column baseline, i.e. the wrap seam is as smooth as the interior; zero bright pixels touch the outer two-pixel border, so no star is cut by the tile edge.
- Subject text:

```
Seamless tileable starfield texture, abstract procedural noise, not a scene, no objects of any kind. Flat void black base covered with sparse faint tiny dim desaturated star points, low density, never bright, never clustered, no colour beyond faint white and pale blue-grey. Nothing else exists in the image: no spaceships, no hardware, no debris pieces, no planets, no nebula, no dust motes, no glow, no lens flare, no vignette, no directional gradient. Perfectly even density across the whole square with even margins, and no star or speck touching or cut by the frame border, so the texture tiles seamlessly in both X and Y. No text, no watermark, no grid lines, no border.
```

### Run 4 — `env_stars_layer2.png` (1:1) — success on second retry

- Date/time: 2026-09-17 18:40 +0200 (first attempt 18:33, second 18:38)
- Model: `gpt-image-2-5-sunburst-text-to-image` (sunburst fallback)
- Job id: `ed608bbeeffa8a53871d804a8c8bc237` (first attempt `2a598499ec43495ded934f2215da9586` on flare and flare retry `e299bb82522aaf72bc3d9238dc3ec375` both rejected as off-subject)
- Raw run folder: `vajb-orbit/assets/env/20260917-184004/` (earlier attempts `20260917-183315/`, `20260917-183847/`)
- Final files: `env_stars_layer2.png` (2048x2048) + `env_stars_layer2.png.job.json`
- Aspect / resolution: 1:1, 2K
- Status: soft drifting washes of deep void blue and void haze, desaturated blue-grey only, extremely low contrast, no stars, no nebula colour, no object of any kind; zero pixels above luma 80 and zero warm pixels. Tile wrap check: left-versus-right mean difference 2.01 and top-versus-bottom 1.42 against a 0.62 interior baseline — a low-frequency wash cannot wrap as tightly as a speckle field numerically, but the tiled preview shows the wash continuing across all four edges with no visible seam or hard line.
- Subject text:

```
Seamless repeating pattern wallpaper texture, an abstract flat 2D background plate, not a scene, not an object render, no focal point. The whole square is soft drifting washes of deep void blue and void haze, desaturated blue-grey only, extremely low contrast, blurry and featureless like a smoky atmosphere layer. There is no ship, no hull, no spacecraft, no metal object, no hardware, no debris, no planet, no star, no light source, no glow, no vignette, no directional gradient and no sharp edge anywhere in the image, and the metal, hull grime, rust and battle damage wording of the style block does not apply to this flat atmosphere texture. Even density across the whole square, and the wash continues across all four borders with no visible seam, so the texture tiles seamlessly in both X and Y. No text, no watermark, no grid lines, no border.
```

### Run 5 — `env_stars_layer3.png` (1:1) — success on second retry

- Date/time: 2026-09-17 18:42 +0200 (first attempt 18:33, second 18:40)
- Model: `gpt-image-2-5-flare-text-to-image` (flare)
- Job id: `024007ca42cfb96830a8167dd9e7803e` (first attempt `3302c620a4f2ef705946795007974533` rejected as off-subject; sunburst retry `05a2d4471f5ccf94fa6780e1ec308cd6` was object-free but came back as a dense uniform speckle field, denser than layer 1 and so in breach of the sparser-than-layer-1 clause, and is kept only as a fallback under `20260917-184059/`)
- Raw run folder: `vajb-orbit/assets/env/20260917-184230/` (earlier attempts `20260917-183347/`, `20260917-184059/`)
- Final files: `env_stars_layer3.png` (2048x2048) + `env_stars_layer3.png.job.json`
- Aspect / resolution: 1:1, 2K
- Status: loose individual dust motes in steel highlight at low alpha on near-black void, softly lit rather than bright — 0.09 % of pixels above luma 40 and 0.0002 % above luma 80, so the layer is sparser than `env_stars_layer1.png` (0.16 % above luma 40) and reads as foreground drift without adding starfield density; no warm pixel anywhere. Tile wrap check: left-versus-right 0.80 and top-versus-bottom 0.66 against a 0.64 interior baseline; zero bright pixels on the outer border.
- Subject text:

```
Seamless repeating pattern wallpaper texture, an abstract flat 2D background plate, not a scene, not an object render, no focal point, mostly empty void black. Very few specks: only a couple of dozen loose individual dust motes in steel highlight #565C63 at low alpha, clearly separated with generous empty black space between them, each mote distinctly larger than a star point and slightly soft. Sparse and quiet, never uniform noise, never dense speckle, never a dust cloud, never a fog. There is no ship, no hull, no spacecraft, no metal object, no hardware, no planet, no glow, no bright star, no cloud, no streak, no clump, no vignette, no directional gradient and no focal cluster anywhere in the image. No speck touches or is cut by the frame border, and the mote pattern continues across all four borders at the same very low density, so the texture tiles seamlessly in both X and Y. No text, no watermark, no grid lines, no border.
```

### Failed first attempts (logged, kept on disk, not delivered)

| Original run | Job id | Model | Raw folder | Rejection reason |
|---|---|---|---|---|
| `env_stars_layer1.png` attempt 1 | `21f7518742233d5a6249b86cde0c1687` | flare | `20260917-183242/` | Returned a lit spacecraft scene against a starfield instead of an empty texture (1.59 % of pixels above luma 80, 0.33 % warm). |
| `env_stars_layer2.png` attempt 1 | `2a598499ec43495ded934f2215da9586` | flare | `20260917-183315/` | Same failure mode: a void-haze prompt returned a fleet scene on a hazy background (1.63 % above luma 80, 0.18 % warm). |
| `env_stars_layer2.png` attempt 2 | `e299bb82522aaf72bc3d9238dc3ec375` | flare | `20260917-183847/` | Off-subject again: one spacecraft on haze (1.46 % above luma 80, 0.13 % warm); prompt rewritten to lead with the texture genre before the sunburst retry. |
| `env_stars_layer3.png` attempt 1 | `3302c620a4f2ef705946795007974533` | flare | `20260917-183347/` | Off-subject: spacecraft scene (2.49 % above luma 80, 0.31 % warm). |
| `env_stars_layer3.png` attempt 2 | `05a2d4471f5ccf94fa6780e1ec308cd6` | sunburst | `20260917-184059/` | Object-free and usable, but a dense uniform speckle field denser than layer 1 (0.92 % above luma 40); superseded by the sparse flare retry. |

First-attempt subject texts for the three layers (before the genre-first rewrite):

```
Seamless tileable starfield layer, a flat void black base with sparse faint tiny dim desaturated star points, low density, never bright, never clustered, no colour beyond faint white and pale blue-grey. Perfectly even across the whole square, no vignette, no directional gradient, no glow, no haze, no dust motes, no nebula, no planets. No star or speck is cut by the tile border: every point sits fully inside the frame with even margins, and the pattern continues across all four edges so the layer tiles seamlessly in both X and Y. No text, no watermark, no grid lines.
```

```
Seamless tileable void haze layer, soft drifting washes of deep void blue and void haze, desaturated blue-grey only, extremely low contrast, no nebula colour, no bright nebula, no stars, no glow. Soft cloudy structure with no hard edges, no vignette, no directional gradient, and nothing cut by the tile border: the wash continues across all four edges so the layer tiles seamlessly in both X and Y. Near-black and quiet overall, no saturated colour, no text, no watermark, no grid lines.
```

```
Seamless tileable foreground dust layer, fine near-field dust specks and micro debris motes in steel highlight at low alpha, sparser and slightly larger than a base starfield layer, so it reads as foreground drift. Mottled even speckle across the whole square, no clumps, no streaks, no vignette, no directional gradient, no haze, no stars, no glow, no nebula. Nothing is cut by the tile border: every speck sits fully inside the frame with even margins, and the speckle continues across all four edges so the layer tiles seamlessly in both X and Y. No text, no watermark, no grid lines.
```

### G1 batch summary

- Runs: 5 delivered assets from 10 submissions (5 first attempts, 5 retries) — 2 first attempts accepted as-is (`env_menu_bg`, `env_loading_bg`), 3 rejected as off-subject and regenerated (all three starfield layers, one of them twice). No server-side failure, no timeout, no reject-by-API; every submission returned code 200 and downloaded on the first poll.
- Spend: 10 x $0.05 = $0.50 per GENERATION_PLAN.md price basis (the script printed a stale $0.15 / 30-credit hint per run and was ignored; rate is $0.05 per 2K request per the user-verified console figure). The batch estimate was $0.25, so the off-subject retries cost an extra $0.25 — within the plan contingency of about $0.30.
- Files delivered: 5 finals in `vajb-orbit/assets/env/` (`env_menu_bg.png`, `env_loading_bg.png`, `env_stars_layer1.png`, `env_stars_layer2.png`, `env_stars_layer3.png`) plus 5 `<final>.job.json` manifests. Raw run folders, including the rejected attempts, are left in place for the audit trail; the scratch previews inside them (`preview*.png`, `preview*.jpg`, `check*.jpg`, `compare_l3.jpg`, `crop_compare.jpg`, `stack_normal.jpg`, `contact_stars.jpg`) are review artefacts, not deliverables.
- Open items for the orchestrator: (1) the 2048x1152 versus 2560x1440 size gap on the two 16:9 backgrounds; (2) whether the retained sunburst speckle variant under `20260917-184059/` is wanted as a denser layer-3 alternative; (3) i2i touch-ups, if any, belong to the post-batch pass per GENERATION_PLAN rule 6, not to more regen loops.
