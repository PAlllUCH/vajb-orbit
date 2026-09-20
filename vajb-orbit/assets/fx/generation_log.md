# FX generation log (G5)

Batch: G5 FX, 9 runs (plus 4 retries), per `docs/design/FX_SPEC.md` §1 and `docs/design/GENERATION_PLAN.md`.
Date: 2026-09-17 (local, times below are the run folders' `YYYYMMDD-HHMMSS` stamps).
Primary model: `gpt-image-2-5-flare-text-to-image` (alias `flare`), aspect 1:1, resolution 2K. Retry model: `gpt-image-2-5-sunburst-text-to-image` (alias `sunburst`).
Every run appended the project style block (`vajb-orbit/assets/style-block.txt`) verbatim as the prompt preamble via `--style-file`, per FX_SPEC §0.1. The SUBJECT text below is the spec's prompt-notes wording plus the FX addendum: `flat black #0A0E14 background, NOT white — emissive effect for additive blending` and the §0.1 negative list.
Raw downloads and their `job.json` manifests are kept in the timestamped subfolders next to this file (including superseded attempts); the shipped master is the copy at the final filename, with the matching attempt's `job.json` as `<final-file>.job.json`.
No `--strip-bg` and no `--split` were used: sheets ship as masters and Godot slices them with `AtlasTexture`. No resizing: 2K 1:1 is the shipped size.

AI-generated art is **not CC0**. Generator: kie.ai (`gpt-image-2-5-flare-text-to-image`, retries `gpt-image-2-5-sunburst-text-to-image`). Seeds are not exposed by these models, so none are recorded (kie.ai returned no seed field in any payload). Cost basis $0.05 per 2K request (kie.ai console, user-verified); the script's printed estimate ($0.15 / 30 credits, `price_source: hint`) is a stale hint and was ignored for budgeting.

---

## 1. `fx_laser_bolt.png`

- Date/time: 2026-09-17 18:31:34
- Model: `gpt-image-2-5-flare-text-to-image`
- Job id: `643ddccf6162af3ce40c64628fb2d3c5`
- Run folder: `20260917-183134/` (`single-elongated-energy-bolt-horizontal-1.png`)
- Status: OK
- SUBJECT: `single elongated energy bolt, horizontal, burnt ember #C8461B core with ember glow #E8703A halo, isolated on flat void black #0A0E14 background, 2K, 1:1, one sheet with two bolt tiers separated by clean void margins: a light thin bolt tier and a medium bolt tier, both stretched along the travel direction facing right, slight painterly hot-tip at the head, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`

## 2. `fx_muzzle_flash.png`

- Date/time: 2026-09-17 18:32:23
- Model: `gpt-image-2-5-flare-text-to-image`
- Job id: `5784ae585dc471707f7087ff3dccb3cd`
- Run folder: `20260917-183223/` (`4-frame-horizontal-sprite-sheet-of-a-wea-1.png`)
- Status: OK
- SUBJECT: `4-frame horizontal sprite sheet of a weapon muzzle flash: frame 1 brightened pale-ember hot starburst core, frame 2 burnt ember #C8461B and ember glow #E8703A flare, frame 3 ember flare with iron black #232629 smoke, frame 4 dark smoke dissipating, frame 1 is brightened desaturated ember #E8703A with no pure white pixels, isolated effects only, flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`

## 3. `fx_engine_trail.png`

- Attempt 1 — Date/time: 2026-09-17 18:33:34, model `gpt-image-2-5-flare-text-to-image`, job id `caa650e39520976faa37df50b3874bac`, run folder `20260917-183334/` (`single-thin-horizontal-ember-streak-bur-1.png`), **status: rejected** — the render returned a complete spacecraft with an engine plume instead of an isolated streak (violates FX_SPEC §0.1 "no ship parts, isolated effects only").
- Attempt 2 (retry) — Date/time: 2026-09-17 18:40:22, model `gpt-image-2-5-sunburst-text-to-image`, job id `8f5e47b5a2edc5d9f064da76e5c45c05`, run folder `20260917-184022/` (`single-thin-horizontal-ember-streak-bur-1.png`), **status: OK — this is the shipped master**.
- SUBJECT (attempt 2): `single thin horizontal ember streak, burnt ember #C8461B core fading to ember glow #E8703A and transparent tail, isolated on flat void black #0A0E14 background, 2K, 1:1, one isolated effect only, no ship parts, no spacecraft, no vehicle, no hull, no cockpit, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`
- SUBJECT (attempt 1, superseded): `single thin horizontal ember streak, burnt ember #C8461B core fading to ember glow #E8703A and transparent tail, isolated on flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`

## 4. `fx_explosion.png`

- Date/time: 2026-09-17 18:34:24
- Model: `gpt-image-2-5-flare-text-to-image`
- Job id: `157af1959dad8f5aa373008001592c9e`
- Run folder: `20260917-183424/` (`sprite-sheet-2-by-3-grid-5-frames-of-a-1.png`)
- Status: OK
- SUBJECT: `sprite sheet, 2 by 3 grid, 5 frames of a space explosion sequence: brightened pale-ember hot flash, burnt ember #C8461B bloom with ember glow #E8703A rim, ember and iron black #232629 smoke cloud, dissolving gunmetal #2B2F35 debris streaks, last cell empty, frame 1 is brightened desaturated ember #E8703A with no pure white pixels, isolated effects only, no grid lines, no labels, flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`

## 5. `fx_shield_ripple.png`

- Date/time: 2026-09-17 18:35:06
- Model: `gpt-image-2-5-flare-text-to-image`
- Job id: `e04ba85984b2e6df67a34ee5166bf499`
- Run folder: `20260917-183506/` (`single-expanding-energy-ripple-ring-col-1.png`)
- Status: OK
- SUBJECT: `single expanding energy ripple ring, cold pale steel highlight #565C63 only, thin rim, faint inner haze, no orange, no ember, isolated on flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no orange glow, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`
- Note: §1.5 sanctioned exception applied — steel highlight `#565C63` only, and `no orange glow` was added to the negative list explicitly. Pixel audit: no ember hues present; the only blue-dominant pixels are the steel rim itself.

## 6. `fx_mining_beam.png`

- Date/time: 2026-09-17 18:35:40
- Model: `gpt-image-2-5-flare-text-to-image`
- Job id: `98b6910b88fbd5bd91027fa2762c2b9d`
- Run folder: `20260917-183540/` (`4-frame-horizontal-sprite-sheet-of-minin-1.png`)
- Status: OK
- SUBJECT: `4-frame horizontal sprite sheet of mining chip sparks: frame 1 small angular spark burst, burnt ember #C8461B and ember glow #E8703A sparks radiating from a point, frames 2 to 4 the sparks dissipate outward and fade, frame 4 nearly empty, isolated effects only, flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`

## 7. `fx_cargo_pulse.png`

- Attempt 1 — Date/time: 2026-09-17 18:36:28, model `gpt-image-2-5-flare-text-to-image`, job id `af72160d6f10eef76fa9440b772e5179`, run folder `20260917-183628/` (`single-small-energy-ring-burnt-ember-c-1.png`), **status: shipped, with drift** — correct ring geometry, correct ember inner glow, no ship, no text; but the ring is rendered as an industrial metal torus (grey/rust casing) rather than a pure energy ring, against the brief's `no metal casing`.
- Attempt 2 (retry) — Date/time: 2026-09-17 18:42:16, model `gpt-image-2-5-sunburst-text-to-image`, job id `18579f2f3921ba34f773dc5e579ab2d2`, run folder `20260917-184216/` (`single-small-energy-ring-burnt-ember-c-1.png`), **status: worse** — same metal-torus layout, heavier corrosion and more saturated rust, so attempt 1 is the shipped master (per brief: retry once, log, continue).
- SUBJECT (attempt 1, shipped): `single small energy ring, burnt ember #C8461B with ember glow #E8703A inner glow, isolated on flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`
- SUBJECT (attempt 2, superseded): `single small energy ring, burnt ember #C8461B with ember glow #E8703A inner glow, isolated on flat void black #0A0E14 background, 2K, 1:1, one isolated effect only, no ship parts, no spacecraft, no vehicle, no hull, no machinery, no metal casing, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`

## 8. `fx_hull_critical_vignette.png`

- Attempt 1 — Date/time: 2026-09-17 18:37:34, model `gpt-image-2-5-flare-text-to-image`, job id `b7bedcfffe6cfaa67f245fc4eca3a9f0`, run folder `20260917-183734/` (`full-screen-vignette-burnt-ember-c8461-1.png`), **status: rejected** — a capital ship occupied the centre of the frame and the ember gradient was legible only behind it (violates "transparent empty centre, isolated overlay only").
- Attempt 2 (retry) — Date/time: 2026-09-17 18:41:02, model `gpt-image-2-5-sunburst-text-to-image`, job id `a3db7d8cd66a1839f3a6ae7a982fe7d0`, run folder `20260917-184102/` (`full-screen-vignette-burnt-ember-c8461-1.png`), **status: OK — this is the shipped master**.
- SUBJECT (attempt 2): `full-screen vignette, burnt ember #C8461B dark gradient glowing inward from all screen edges, corners heaviest, iron black #232629 smoke texture within the ember, transparent empty centre with nothing in it, isolated overlay only, no ship parts, no spacecraft, no vehicle, no hull, flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`
- SUBJECT (attempt 1, superseded): `full-screen vignette, burnt ember #C8461B dark gradient glowing inward from all screen edges, corners heaviest, iron black #232629 smoke texture within the ember, transparent empty centre, isolated overlay only, flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`
- Note: FX_SPEC §1.8 — the Void Black background is discarded on import; the centre keys out fully black in the shipped master.

## 9. `fx_ember_pulse.png`

- Attempt 1 — Date/time: 2026-09-17 18:38:24, model `gpt-image-2-5-flare-text-to-image`, job id `af940742216c9a216125d61e34f39b49`, run folder `20260917-183824/` (`small-radial-ember-glow-orb-soft-radial-1.png`), **status: rejected** — a full spacecraft with ember running lights instead of a radial glow orb.
- Attempt 2 (retry) — Date/time: 2026-09-17 18:41:37, model `gpt-image-2-5-sunburst-text-to-image`, job id `8135db111f461bba0768486edffb6527`, run folder `20260917-184137/` (`small-radial-ember-glow-orb-soft-radial-1.png`), **status: OK — this is the shipped master**.
- SUBJECT (attempt 2, per MAIN_MENU_SPEC §5): `small radial ember glow orb, soft radial glow, burnt ember #C8461B core with ember glow #E8703A halo, compact and contained, isolated on flat void black #0A0E14 background, 2K, 1:1, one isolated effect only, no ship parts, no spacecraft, no vehicle, no hull, no cockpit, no machinery, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`
- SUBJECT (attempt 1, superseded): `small radial ember glow orb, soft radial glow, burnt ember #C8461B core with ember glow #E8703A halo, compact and contained, isolated on flat void black #0A0E14 background, 2K, 1:1, flat black #0A0E14 background, NOT white — emissive effect for additive blending, no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark`

---

## Visual verification

One contact sheet of all nine shipped masters, plus a four-up crop review of the assets that missed on first pass, was inspected before the batch was closed. Findings:

- **Laser bolt:** two tiers separated by clean void margins, both facing right with hot tips. Measured: upper tier 1822 × 58 px (thin, reads as the light bolt), lower tier 1709 × 106 px (bolder, reads as the medium bolt). Drift: the art fills nearly the full sheet width instead of the spec's stated 4:1 / 6:1 regions, so the `AtlasTexture` crop must be set from these measured boxes rather than from §1.1's nominal 64×16 / 96×16. Palette is ember only.
- **Muzzle flash:** four evenly spaced frames, horizontal, frame 1 a brightened desaturated-ember starburst, frame 4 nearly spent. No grid lines.
- **Engine trail:** single thin horizontal streak, hot head to transparent tail, isolated. Measured content bounding box 1336 × 67 px inside the 2048² sheet (~20:1), i.e. a wide, thin element as specified.
- **Explosion:** 2×3 grid, frames read f1 (TL) pale-ember flash, f2 (TR) ember bloom, f3 (ML) ember + iron-black smoke, f4 (MR) dissolving gunmetal debris streaks, f5 (BL) residual debris, last cell (BR) empty as the brief requires. No grid lines.
- **Shield ripple:** single cold steel ring, no orange, no ember — §1.5 exception is clean. (This asset reads as the intended cold non-danger state; its pale steel is the only blue-dominant content in the batch, which is sanctioned.)
- **Mining beam:** 4 frames, angular ember sparks radiating from a point, dissipating to a nearly empty frame 4.
- **Cargo pulse:** ember ring with ember inner glow, centred, no ship/text. Drift: industrial metal torus casing rather than a pure energy ring (see §7 above).
- **Hull-critical vignette:** ember/smoke gradient heaviest at the corners, fully clear black centre, no content in the middle. 2048², single frame. Measured: corner region mean luma 38.4, edge bands 30-33, centre 7.6 (film grain only), so the centre is legible-black and the falloff runs inward from all four edges.
- **Ember pulse:** small, compact radial ember orb with a soft halo, isolated on void black. Measured content bounding box 439 × 445 px inside the 2048² sheet, i.e. compact and contained.

Pixel audit of all nine masters (2048², RGB):

| File | near-white pixels (R,G,B > 235) | green-dominant | notes |
|---|---|---|---|
| `fx_laser_bolt.png` | 35 (0.0008 %) | 0 | stray film-grain specks along the bolt |
| `fx_muzzle_flash.png` | 12 (0.0003 %) | 0 | specks in frames 2-4 only; frame 1 core has no white |
| `fx_engine_trail.png` | 0 | 0 | |
| `fx_explosion.png` | 56 (0.0013 %) | 0 | all warm/pale-ember (e.g. 254,249,237), i.e. the sanctioned brightened desaturated ember, not neutral white |
| `fx_shield_ripple.png` | 25 (0.006 %) | 0 | steel-highlight glints only |
| `fx_mining_beam.png` | 0 | 0 | |
| `fx_cargo_pulse.png` | 2341 (0.056 %) | 0 | metal-casing specular glints, part of the noted drift |
| `fx_hull_critical_vignette.png` | 0 | 0 | |
| `fx_ember_pulse.png` | 0 | 0 | |

No purple, blue, teal, green or yellow glow was found in any master; the only non-ember glow across the batch is the sanctioned steel `#565C63` of the shield ripple (and metal greys in the cargo-pulse drift).

---

## Summary

| # | Final file | Shipped attempt | Job id | Status |
|---|---|---|---|---|
| 1 | `fx_laser_bolt.png` | 1 (flare) | `643ddccf6162af3ce40c64628fb2d3c5` | OK |
| 2 | `fx_muzzle_flash.png` | 1 (flare) | `5784ae585dc471707f7087ff3dccb3cd` | OK |
| 3 | `fx_engine_trail.png` | 2 (sunburst retry) | `8f5e47b5a2edc5d9f064da76e5c45c05` | OK (attempt 1 rejected: contained a ship) |
| 4 | `fx_explosion.png` | 1 (flare) | `157af1959dad8f5aa373008001592c9e` | OK |
| 5 | `fx_shield_ripple.png` | 1 (flare) | `e04ba85984b2e6df67a34ee5166bf499` | OK |
| 6 | `fx_mining_beam.png` | 1 (flare) | `98b6910b88fbd5bd91027fa2762c2b9d` | OK |
| 7 | `fx_cargo_pulse.png` | 1 (flare) | `af72160d6f10eef76fa9440b772e5179` | shipped with drift (metal casing); retry no better |
| 8 | `fx_hull_critical_vignette.png` | 2 (sunburst retry) | `a3db7d8cd66a1839f3a6ae7a982fe7d0` | OK (attempt 1 rejected: ship in centre) |
| 9 | `fx_ember_pulse.png` | 2 (sunburst retry) | `8135db111f461bba0768486edffb6527` | OK (attempt 1 rejected: contained a ship) |

Runs: 9 first attempts + 4 retries = 13 submissions, 13 succeeded at the API, 0 API failures, 3 content rejections fixed by retry, 1 content drift accepted (`fx_cargo_pulse.png`).
Spend: 13 × $0.05 = **$0.65** ($0.45 batch + $0.20 retries, inside the plan's ~$0.30 contingency for failed runs). `--usage` after the batch reads 57 generations / 1635 credits / **$8.18** for the shared ledger, which other parallel G-batches also write to and which is priced from the script's stale 30-credit hint; on the plan's verified 10-token = $0.05 basis the same figure is $2.85, and this batch's share is the $0.65 above.

Open items for the orchestrator:

1. `fx_cargo_pulse.png` is the only asset whose content drifts from spec: both `flare` and `sunburst` rendered a metal torus for "energy ring", keeping a grey/rust casing that will read as a dim grey ring under additive blending. Palette-safe and usable, but an i2i cleanup pass is the cheap fix if a pure energy ring is required.
2. `fx_laser_bolt.png` needs its `AtlasTexture` regions taken from the measured tier boxes (upper 1822 × 58, lower 1709 × 106), not from §1.1's nominal 64×16 / 96×16.
3. `fx_explosion.png` f5 (bottom-left) carries residual debris rather than being fully empty; the required empty last cell (bottom-right) is present, so playback is still correct at 5 frames.

## 2026-09-17 18:59 — fix-ups by orchestrator
- fx_muzzle_flash.png — flare-i2i from prior master, prompt: remove gun silhouettes, isolated flash only. Replaced shipped master; old master preserved in G5 run folder. status ok
- fx_cargo_pulse.png — flare t2i regen with anti-torus wording: thin soft painterly ember ring, no metal. Replaced prior metal-torus render. status ok

### Audit follow-up 2026-09-17 19:09 — fix-up backfill (job ids + full prompts)
- fx_muzzle_flash.png — job b588514cc4569d204940da371a92878a, flare-i2i from prior master. Full prompt: identical 4-frame horizontal sprite sheet of a weapon muzzle flash in identical positions, remove every gun and weapon silhouette and all hardware, each frame contains only the isolated muzzle flash effect, frame 1 brightened pale-ember hot starburst core, frame 2 burnt ember #C8461B and ember glow #E8703A flare, frame 3 ember flare with iron black #232629 smoke, frame 4 dark smoke dissipating, no weapon, no ship, no hardware, isolated effects only, flat void black #0A0E14 background, emissive effect for additive blending, 2K, 1:1. Supersedes summary-table id 5784ae585dc471707f7087ff3dccb3cd. Waiver note: prompt uses the wording flat void black #0A0E14 background, emissive effect for additive blending without the literal NOT-white clause; output verified on void black, no white background — waived, no regen.
- fx_cargo_pulse.png — job 48939c8e5d883c136430f69be588a510, flare t2i. Full prompt: small glowing ring of ember light seen face-on, thin soft painterly ring of burnt ember #C8461B fire glow with ember glow #E8703A inner warmth, a rippling halo of flame light, completely non solid, no metal, no machinery, no torus, no solid objects, no structure, isolated effects only, flat void black #0A0E14 background, emissive effect for additive blending, 2K, 1:1. Supersedes summary-table id af72160d6f10eef76fa9440b772e5179. Same NOT-white wording waiver as above; output on void black.
- fx_muzzle_flash.png + fx_explosion.png: 89 and 33 near-white pixels clamped to luma 240 hue-preserving, locally, per FX_SPEC no-pure-white rule.
