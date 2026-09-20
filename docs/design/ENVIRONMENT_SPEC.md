# Vajb Orbit — Environment Art Spec

**Status:** Phase-A art spec. Depends on `STYLE_BIBLE.md` (palette, lighting, weathering vocabulary) and `MAIN_MENU_SPEC.md` (what the menu background must support). Generated art is produced from `vajb-orbit/assets/style-block.txt` (verbatim copy of STYLE_BIBLE STYLE BLOCK).

---

## 1. Style rules (copied verbatim from STYLE_BIBLE)

### 1.1 Section 7.2 — Environment (asteroids, stations, debris, nebulae)

> Same metal and rock vocabulary, but larger scale weathering: cracked rock faces, welded station platework with heavy hull grime and rust streaks, debris fields with battle damage. Environment reads one value step darker than ships so ship silhouettes always dominate. No emissive on environment except hostile station warning lamps in Burnt Ember. Backgrounds use Deep Void Blue `#111823` and Void Haze `#1A2230` washes with sparse faint stars; nebulas stay desaturated blue-grey with at most a whisper of ember where battle occurred.

### 1.2 Section 7.4 — Main Menu Background

> A wide cinematic top-down vista: a wreck-strewn battlefield drifting in Deep Void Blue, painted in the same lighting (harsh upper-left key, cold steel rims), heavy film grain, drifting dust veils in Void Haze. One distant, small ember glow (a burning wreck) as the single accent point — it must stay small and off-centre so foreground UI owns the frame. Desaturated, dark overall; the menu must never compete with text legibility.

### 1.3 Environment value rule (restated)

Environment reads **one value step darker than ships** so ship silhouettes always dominate. **No emissive on environment** except:

1. station warning lamps in Burnt Ember `#C8461B` (the single permitted env lamp emissive), and
2. the one menu-background burning wreck glow (ember, small and contained).

Nothing else in any environment asset may glow.

---

## 2. Main menu background — hero deliverable (`env_menu_bg.png`)

- **Format:** single 16:9 render at 2K wide (2560×1440). **No grid split** — delivered as one image.
- **Projection:** wide cinematic top-down vista (same top-down family as gameplay, composed cinematically, no perspective tilt).
- **Subject:** a wreck-strewn battlefield drifting in Deep Void Blue `#111823` — scattered torn hull fragments, debris shards, faint pitted-metal wreckage shapes half-lost in shadow, drifting dust veils in Void Haze `#1A2230`, sparse faint stars. Harsh upper-left key light with cold steel rims (Steel Highlight `#565C63`) on fragment edges; heavy film grain over the whole frame.
- **Single accent:** exactly **one** distant, small burning wreck with a small ember glow (Burnt Ember `#C8461B` core, faint Ember Glow `#E8703A` halo). It stays **small and distant**, positioned **off-centre, in the lower-right third** of the frame. No other ember, glow, or accent anywhere in the image.
- **Composition / negative space requirement (explicit):** the **left side of the frame and the centre-left must stay quiet, dark, low-detail negative space** — this is where the title lockup (top-left ~8 %/12 %) and the button stack (left, ~58 % height) sit per `MAIN_MENU_SPEC.md` §3. The busiest wreckage detail lives lower-right, around and behind the burning wreck; detail density must fall off toward the left and upper-left so foreground UI owns the frame and text stays legible at 100 % background opacity.
- **Brightness cap:** dark overall, desaturated; the menu must never compete with text legibility. Background sits in the `#0A0E14`–`#111823` value band with lit debris edges only one step brighter.
- **Animation support (per MAIN_MENU_SPEC §5):**
  1. **Dust drift:** the background must tolerate a slow 96 px / 20 s UV offset wrap (wider-than-screen texture or region scroll) without visible seam popping at the frame edge — avoid hard subject detail touching the extreme frame edges; keep edge zones as void/dust.
  2. **Wreck ember pulse:** the burning wreck must be a small, isolated, locatable point (lower-right third) so the controller can overlay a looping `ember_pulse` radial glow sprite on it (alpha 0.25↔0.45, 8 s period).
- **Text legibility:** Ash Text `#8D939B` and Bone Text `#C9CDD2` UI must read directly on the left-side background with no scrim; therefore the left third is the darkest, emptiest region of the image.

## 3. Loading screen backdrop (`env_loading_bg.png`)

- **Loading-backdrop ownership (decision 2026-09-17):** this spec owns the loading backdrop (`env_loading_bg.png`). UI_CHROME's plain-plate `ui_loading_backdrop.png` is parked as an engine-side fallback and is **not generated** unless this vista fails review.

- **A — darker crop variant:** a darker, tighter crop of the same menu vista (recentered toward the wreck/debris mass, graded ~20 % darker), 16:9 at 2K wide, same rules as §2 but with the burning wreck **absent or fully extinguished** (loading screen carries no accent) — rendered to sit at **40 % intended opacity** over `void_base` per `MAIN_MENU_SPEC.md` §2.
- **B — second render:** a second 16:9 2K-wide render of the same vista family, same grade, at 40 % intended opacity.

In both cases the art is authored knowing it will be displayed at 40 % opacity: contrast and silhouette edges must survive a half-opacity composite over `#0A0E14`. No accent, no ember, no lamps.

---

## 4. Asteroid field grid (`env_asteroid_L1..L3`, `M1..M3`, `S1..S3`)

- **Panel:** one **3×3 grid panel** at **2K 1:1 (2048×2048)**, generated on **flat Void Black `#0A0E14` background** (cells separate on clean void margins for splitting), then **split** into 9 individual sprites with transparent cells. Row 1 = large, row 2 = medium, row 3 = small; three asteroids per tier.
- **Look:** mineable — visible **ore veins** in Rusted Ochre `#6E5B4A` and Dry Rust `#8A6A50` running through cracked rock faces; **pitted metal** micro-dotted erosion catching the rim light as speckle; cracked rock faces and battle-damage dents per §7.2 vocabulary; large-scale weathering.
- **Rock body:** desaturated gunmetal-grey rock in the `#2B2F35`–`#3A3F46` range, one value step darker than ships; upper-left key light, cold steel rim on shadow-side edges, Iron Black `#232629` core shadow.
- **Tiers:** large ≈ dominant mass filling its cell, medium ≈ mid-mass with clear silhouette variety, small ≈ compact shatter fragments. All nine silhouettes must differ at a glance.
- **No emissive.** Background cells transparent after split.
---

## 5. Wreck hulk prop (`env_wreck_hulk.png`)

- Single prop, top-down orthographic, **generated on flat Void Black `#0A0E14` background then cut out to transparent** (generators cannot author true transparency), delivered at 2K 1:1; final asset trimmed to content.
- Subject: one **torn hull segment** of a dead capital ship — ripped-open plating with bent, torn plate edges, scorch-blackened craters, weld beads over old repairs, exposed ribs, battle damage as the dominant vocabulary. Oil stains and hull grime washes heavier toward trailing edges; rust streaks bleeding from seams.
- Lighting: same harsh upper-left key, cold steel rim on the torn edges so the silhouette reads against void.
- **No emissive.** Value: one step darker than ships.

---

## 6. Station exterior prop (`env_station.png`)

- Single prop, top-down orthographic, **generated on flat Void Black `#0A0E14` background then cut out to transparent**, 2K 1:1.
- Subject: hostile station exterior — **welded platework** in gunmetal mid/dark, panel seams and rivet lines, **heavy hull grime** films, **rust streaks** from seams and rivets, pitted metal on older plates.
- **Emissive (the one exception):** warning lamps in **Burnt Ember `#C8461B` only** — small, hot, contained lamp points along the hull. No other glow anywhere on the station; no Ember Glow halo bloom beyond the lamp points themselves.
- Value: one step darker than ships; cold steel rim traces the shadow-side silhouette.

---

## 7. Starfield and dust layers (`env_stars_layer1.png` – `env_stars_layer3.png`)

Three **separate tileable** layers for parallax stacking (deep→near). Each delivered at 2K 1:1 (2048×2048), **each must tile seamlessly in both X and Y** — no visible seam when region-repeated; author edge-safe (no star or speck cut by the tile border).

1. **Layer 1 — base starfield:** Void Black `#0A0E14` base with **sparse faint stars** — tiny, dim, desaturated points; low density, never bright or clustered.
2. **Layer 2 — void haze veil:** soft drifting washes of Deep Void Blue `#111823` and Void Haze `#1A2230`, desaturated blue-grey only, no nebula colour, extremely low contrast.
3. **Layer 3 — dust speck layer:** fine near-field dust specks and micro-debris motes in Steel Highlight `#565C63` at low alpha, sparser and slightly larger than layer 1 stars; reads as foreground drift.

No emissive, no accent, no bright nebula in any layer.

---

## 8. Generation plan

| Asset | Source | Size / split |
|---|---|---|
| `env_menu_bg.png` | style-block.txt | single 16:9 2K-wide render, **no split** |
| `env_loading_bg.png` | style-block.txt | 16:9 2K-wide, single render (darker crop variant preferred) |
| `env_asteroid_L1..L3_M1..M3` grid | style-block.txt | 2K 1:1 (2048×2048) 3×3 grid, then split into 9 files |
| `env_wreck_hulk.png` | style-block.txt | 2K 1:1 render, cut out to transparent |
| `env_station.png` | style-block.txt | 2K 1:1 render, cut out to transparent |
| `env_stars_layer1.png` … `env_stars_layer3.png` | style-block.txt | 2K 1:1 each, tileable |

- All prompts begin with the verbatim STYLE BLOCK from `vajb-orbit/assets/style-block.txt`, then the asset-specific subject above.
- **Amendment 2026-09-17:** `docs/design/ASSET_EXPANSION_SPEC.md` §6 and §8 extend this family with `env_planet_moon.png` (airless dead moon: no atmosphere, no clouds, no terminator glow, so §9's negative list is respected), `env_jump_gate.png` (ember warning lamps only, the station-lamp exception), `env_debris_field.png`, `env_nebula_veil.png`, four wave-2 props and three opaque 16:9 screen backdrops (`ui_backdrop_hangar/starmap/login.png`).
- AI-generated art is **not CC0** — record the generator's usage terms before shipping and keep a generation log (prompt/seed/model/date) next to each file under `vajb-orbit/assets/`, per AGENTS.md.
- **Naming:** `env_menu_bg.png`, `env_loading_bg.png`, `env_asteroid_L1.png`–`L3`, `env_asteroid_M1.png`–`M3`, `env_asteroid_S1.png`–`S3`, `env_wreck_hulk.png`, `env_station.png`, `env_stars_layer1.png`–`layer3`. Snake_case, exactly as listed.

---

## 9. Negative list (applies to every environment render)

- No planets with atmospheres.
- No bright nebulas (nebulas stay desaturated blue-grey at most; here: none at all beyond the void haze veil).
- No saturated colours.
- No second accent colour (Burnt Ember/Ember Glow are the only accent; purple, green, teal, yellow forbidden).
- No text, no watermark, no grid lines (the 3×3 asteroid grid is a generation layout only — no visible grid lines in the render; cells separate on clean rock/void boundaries for splitting).

---

## 10. Acceptance checklist

- [ ] `env_menu_bg.png`: 16:9 @ 2560×1440, one small ember wreck in the lower-right third, left side quiet and dark, dust drift + ember pulse points supported.
- [ ] `env_loading_bg.png`: 40 % opacity composite survives over `#0A0E14`; no accent.
- [ ] Asteroid grid splits into 9 clean sprites; ore veins in `#6E5B4A`/`#8A6A50`; mineable read.
- [ ] Wreck hulk and station carry only §7.2/§4 battle-damage vocabulary; station ember lamps only.
- [ ] All three starfield layers tile seamlessly in X and Y.
- [ ] Environment everywhere reads one value step darker than ships; no emissive except station lamps + menu wreck glow.
- [ ] Negative list clean on every delivered file.
