# Phase G - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, aspect 1:1.
Work order: `.agents/gen/dispatch_designer.md`. Style law: `docs/design/STYLE_BIBLE.md` section 9 (human block, `vajb-orbit/assets/style-block.txt`) and section 9.1 (alien addendum, `vajb-orbit/assets/style-block-alien.txt`), both passed verbatim as the prompt preamble. Alien palettes: STYLE_BIBLE section 2.5. FX inventory: `docs/design/FX_SPEC.md` section 7.2.
Price basis: 10 credits = $0.05 per 2K run (kie.ai console, user-verified); the script's printed estimate is the stale hint.
Alpha: `--transparent` native first; an opaque render is keyed by `staging/phase_g/key_new.py` through recraft/remove-background (the 2026-09-20 route). FX stay RGB on void black for additive blending and are never keyed (FX_SPEC sections 0 and 0.1).
AI-generated art is not CC0 (AGENTS.md).

---

## fx_bio_plasma

- Date/time: 2026-09-21 01:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `f96ed6fb11b0c2d1b581804d277f00d2` (elapsed 48.1s)
- Style: `style-block-alien.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-014400` keeps `job.json`
- Review-only: False
- Final files: fx_bio_plasma.png
- Status: success

Full prompt:

> single game FX sprite, one object centred: a pulsing organic plasma orb with a ragged living outline, trailing a short comet of falling bio-spore motes behind it, bioluminescent green #4AE86C hot glow over a corrosive dark #1A281F organic mass, small and hot, isolated on flat void black #0A0E14, nothing else in frame. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

## fx_acid_burn

- Date/time: 2026-09-21 01:44 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `152dd454142db0a9e8e129d7e581ad4f` (elapsed 37.9s)
- Style: `style-block-alien.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-014439` keeps `job.json`
- Review-only: False
- Final files: fx_acid_burn.png
- Status: success

Full prompt:

> single game FX sprite, one object centred: a dissolving puff of bio-acid wisps drifting upward in a spreading stain, chitin green #3D6E49 body with a few hot bioluminescent green #4AE86C flecks, matte stain-looking corrosion, not light, isolated on flat void black #0A0E14, nothing else in frame. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

## fx_shield_shatter

- Date/time: 2026-09-21 01:45 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `d5557007004e2f6e7950b520c58c9183` (elapsed 53.7s)
- Style: `style-block.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: 4-frame 2x2 sheet, RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-014534` keeps `job.json`
- Review-only: False
- Final files: fx_shield_shatter.png
- Status: success

Full prompt:

> a 2x2 animation sheet of a shield shatter burst in four evenly spaced frames, generous gaps of flat void black between frames, no grid lines, no labels: top-left frame the shards still hold a curved plate shape, top-right frame they spread outward, bottom-left frame they scatter as separate shards, bottom-right frame empty of shards with only faint dust. Cold pale steel highlight #565C63 glass-like shards only, no ember, no orange, no other colour, isolated on flat void black #0A0E14. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

## fx_smoke_plume

- Date/time: 2026-09-21 01:49 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `080e1117b5b6de983c2d48aaebed4abd` (elapsed 220.6s)
- Style: `style-block.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-014916` keeps `job.json`
- Review-only: False
- Final files: fx_smoke_plume.png
- Status: success

Full prompt:

> single game FX sprite, one object centred: one painterly black smoke puff, a soft irregular column of soot with soft alpha edges, iron black #232629 core with gunmetal dark #2B2F35 highlight on the lit side, non-emissive, no glow at all, isolated on flat void black #0A0E14, nothing else in frame. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

## fx_arc_spark

- Date/time: 2026-09-21 01:52 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `876f6c95cc9be43b73944220ebcb7077` (elapsed 199.6s)
- Style: `style-block.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: 4-frame 2x2 sheet, RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-015236` keeps `job.json`
- Review-only: False
- Final files: fx_arc_spark.png
- Status: success

Full prompt:

> a 2x2 animation sheet of a jagged electrical arc snapping in four evenly spaced frames, generous gaps of flat void black between frames, no grid lines, no labels: each frame a different crooked forked arc between the same two invisible contact points. Cold pale steel highlight #565C63 arc with one small hot brightened ember core flash at its middle, no other colour, isolated on flat void black #0A0E14. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

## fx_dust_streak

- Date/time: 2026-09-21 01:56 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `1c64e0d57c15310c1ea098b9f204c76f` (elapsed 204.8s)
- Style: `style-block.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-015602` keeps `job.json`
- Review-only: False
- Final files: fx_dust_streak.png
- Status: success

Full prompt:

> single game FX sprite, one object centred: one thin horizontal micro streak of dust, a short soft smear no thicker than a hair with soft fading ends, void haze #1A2230 fading to nothing at both tips, very low contrast, non-emissive, no glow, isolated on flat void black #0A0E14, nothing else in frame. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

## fx_dash_charge

- Date/time: 2026-09-21 01:56 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `31ca5962c1da5a1d07d292736de0403c` (elapsed 38.0s)
- Style: `style-block.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-015641` keeps `job.json`
- Review-only: False
- Final files: fx_dash_charge.png
- Status: success

Full prompt:

> single game FX sprite, one centred ring: a circular charge ring with a burst of short streaks breaking outward from its rim, burnt ember #C8461B rim with a hot ember glow #E8703A inner edge, small and hot, an engine charge state, isolated on flat void black #0A0E14, nothing else in frame, symmetric, seen face-on. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

## fx_lock_channel

- Date/time: 2026-09-21 01:57 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `c23052233226a2b0ad0be0b2c264253d` (elapsed 32.3s)
- Style: `style-block.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-015715` keeps `job.json`
- Review-only: False
- Final files: fx_lock_channel.png
- Status: success

Full prompt:

> single game FX sprite, one centred ring: a thin circular progress arc, a single clean curved stroke running about three quarters around a circle with a clearly cut end, even thickness, cold pale steel highlight #565C63 only, no glow, no ticks, no numbers, isolated on flat void black #0A0E14, nothing else in frame, seen face-on. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

## fx_arc_spark

- Date/time: 2026-09-21 07:04 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `36bc1aa57fca071f023c04c7775290c8` (elapsed 29.9s)
- Style: `style-block.txt` verbatim as the prompt preamble (STYLE_BIBLE section 8)
- Alpha: 4-frame 2x2 sheet, RGB on void black, never alpha-keyed (FX_SPEC 0.1); run folder `20260921-070446` keeps `job.json`
- Review-only: False
- Final files: fx_arc_spark.png
- Status: success

Full prompt:

> a 2x2 animation sheet of a jagged electrical arc snapping in four evenly spaced frames, generous gaps of flat void black between frames, no grid lines, no labels: each frame a different crooked forked arc between the same two invisible contact points. The arc is cold pale steel highlight #565C63, thin and hard-edged, pale and desaturated exactly like brushed steel, and only its very middle carries one small hot brightened ember core flash; the rest of the arc is never ember, never orange, never rust-red, and no other glow colour exists anywhere in the frame. Isolated on flat void black #0A0E14. no text, no watermark, no grid lines, no labels, no border, no frame, no vignette, no lens flare, no bokeh, no second glow colour

---

