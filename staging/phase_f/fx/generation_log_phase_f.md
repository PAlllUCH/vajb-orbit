# Phase F - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`; `flare-i2i` for reference edits), 2K.
Work order: `docs/gameplay/16_art_design_brief.md`. Style law: `docs/design/STYLE_BIBLE.md`, `docs/design/ICONS_SPEC.md` (section 1 + section 8 amendment), `docs/design/SHIPS_SPEC.md` (section 1 framing constant, sections 3.7-3.9).
Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file` on every run.
Price basis: 10 credits = $0.05 per 2K run (kie.ai console, user-verified); the script's printed 30-credit estimate is the stale hint and the `usage-ledger.jsonl` total over-reports 3x.
Alpha: `--transparent` native first, local matte fallback (`staging/phase_d/reprocess.py`). FX stay RGB on void black for additive blending and are never alpha-keyed (FX_SPEC 0.1).
AI-generated art is not CC0 (AGENTS.md).

---

## fx_anomaly_shimmer

- Date/time: 2026-09-18 11:22 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `4ad2cb115ff81e8f1137ebde84adb00c` (elapsed 37.5s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: RGB on void black, not alpha-keyed (FX_SPEC 0.1); run folder `20260918-112214` keeps `job.json`
- Final files: fx_anomaly_shimmer.png
- Status: success

Full SUBJECT text:

> Single ore-bloom anomaly shimmer effect, one isolated object centred in the frame, flat void black #0A0E14 background that is NOT white. A wide thin cold refraction ring drawn in cold pale steel highlight #565C63, its edge broken into short wavy refraction bands as if light is bending through it, the ring completely hollow and empty in the middle, a handful of suspended non-glowing ore flecks in rusted ochre #6E5B4A and dry rust #8A6A50 caught inside the wavy bands, cold and clinical with no warmth and no ember anywhere, absolutely no burnt ember #C8461B, no ember glow #E8703A, no orange, the ring thin and contained, subtle film grain, effects only, no ship parts, no rock body, no panel, no frame. no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark, no grid lines, no frames, no UI chrome, no ship parts. no orange glow except where ember is named, nothing may be more than one accent colour.

---

## fx_anomaly_grave_glow

- Date/time: 2026-09-18 11:22 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `4564aff0a1d0f8ab80a90a30034a0bc8` (elapsed 37.6s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: RGB on void black, not alpha-keyed (FX_SPEC 0.1); run folder `20260918-112253` keeps `job.json`
- Final files: fx_anomaly_grave_glow.png
- Status: success

Full SUBJECT text:

> Single grave-cache anomaly glow effect, one isolated object centred in the frame, flat void black #0A0E14 background that is NOT white. A small dense cold point glow in cold pale steel highlight #565C63 at the centre of a soft unlit halo of deep void blue #111823 and void haze #1A2230, with a slow column of pale non-glowing motes rising from the point and a thin dark iron black #232629 ring of debris haze settled flat around its base, sombre and cold, absolutely no burnt ember #C8461B, no ember glow #E8703A, no orange, no warm colour anywhere, the glow small and contained, subtle film grain, effects only, no ship parts, no wreck hull, no panel, no frame, no gravestone shape. no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark, no grid lines, no frames, no UI chrome, no ship parts. no orange glow except where ember is named, nothing may be more than one accent colour.

---

## fx_anomaly_rift

- Date/time: 2026-09-18 11:23 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `976eb3554b66efa94f69a3eda1e45e7d` (elapsed 27.1s)
- Style block: `style-block.txt` verbatim
- Reference: none (text-to-image)
- Alpha: RGB on void black, not alpha-keyed (FX_SPEC 0.1); run folder `20260918-112322` keeps `job.json`
- Final files: fx_anomaly_rift.png
- Status: success

Full SUBJECT text:

> Single void-rift anomaly effect, one isolated object centred in the frame, flat void black #0A0E14 background that is NOT white. A vertical tear in space: a ragged torn slit of pure void with hard iron black #232629 jaw edges, the tear rim burning in burnt ember #C8461B with a thin ember glow #E8703A line only along the very edge of the tear, short crooked ember stress cracks radiating outward from both ends of the slit, a few dark shards caught in the tear, the interior of the tear completely black and empty, dangerous and thin, no fill glow, no beam, no field, no blue, no purple, no white core, painterly heat striations along the rim, subtle film grain, effects only, no ship parts, no panel, no frame. no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark, no grid lines, no frames, no UI chrome, no ship parts. no orange glow except where ember is named, nothing may be more than one accent colour.

---

