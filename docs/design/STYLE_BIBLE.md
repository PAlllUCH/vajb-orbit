# Vajb Orbit — Visual Style Bible

**Status:** Single source of truth. Every future AI image generation prompt and every UI spec in Vajb Orbit must copy its wording, palette, and rules from this document verbatim.

**Style name:** Grimdark painted sci-fi.

**One-line summary:** Semi-realistic weathered metal, harsh directional rim light, film grain texture, desaturated base palette with exactly one danger accent colour.

---

## 1. Core Principles

1. **Grimdark, not heroic.** Surfaces are tired, scarred, and maintained by necessity, not pride. No chrome shine, no neon optimism, no clean factory finishes.
2. **Painted, not photoreal.** Semi-realistic painterly rendering: visible brushwork energy, softened edges where light falls off, hard edges only on silhouettes and panel breaks.
3. **One accent only.** The entire world is desaturated gunmetal, rust, and void blue-black. Exactly one danger accent colour — burnt orange-red — carries all urgency, all glow, all threat. If a second accent appears anywhere in a render or UI spec, the asset is wrong.
4. **Light does the storytelling.** A single harsh directional key light with a cold rim edge tells shape and mood; the danger accent is the only emissive colour permitted.
5. **Grain everywhere.** Every rendered image, from ships to menu background, carries a subtle film grain layer so the whole game reads as one painted frame.

---

## 2. Fixed Hex Palette

The palette is fixed. Do not invent intermediate tones; pick from these and blend between them.

### 2.1 Base metals — gunmetal to rusted steel

| Hex | Name | Use |
|-----|------|-----|
| `#3A3F46` | Gunmetal Mid | Primary hull tone, mid-light metal |
| `#2B2F35` | Gunmetal Dark | Hull shadow side, recessed panels |
| `#232629` | Iron Black | Deepest metal shadow, engine intakes |
| `#565C63` | Steel Highlight | Rim-lit edges of hull plates |
| `#6E5B4A` | Rusted Ochre | Heavy rust patches, oxidised plating |
| `#8A6A50` | Dry Rust | Scattered rust streaks, older ships |
| `#4A423B` | Grimy Umber | Hull grime washes, dirty panel seams |

### 2.2 Void backgrounds — near-black blue

| Hex | Name | Use |
|-----|------|-----|
| `#0A0E14` | Void Black | Deep space base, outermost background |
| `#111823` | Deep Void Blue | Starfield wash, background nebula base |
| `#1A2230` | Void Haze | Mid-depth background, dust veils |

### 2.3 Danger accent — the single accent

| Hex | Name | Use |
|-----|------|-----|
| `#C8461B` | Burnt Ember | Core danger accent: weapons fire, warning lights, hostile markers, engine flare |
| `#E8703A` | Ember Glow | Emissive rim of the accent, glow halos, hot inner core of energy effects |

### 2.4 UI panel and text tones

| Hex | Name | Use |
|-----|------|-----|
| `#15181D` | Panel Black | UI panel backgrounds, HUD trays |
| `#2A2E35` | Panel Steel | Panel borders, button bodies, dividers |
| `#8D939B` | Ash Text | Primary body text, inactive labels |
| `#C9CDD2` | Bone Text | Headings, key values, focused labels |

Total: 16 colours. No others are permitted.

### 2.5 Alien entity palettes (sanctioned exception — owner ruling 24, 2026-09-20)

The sixteen colours above are the **human** world. The three alien families
break it deliberately — organic, chitinous geometries with their own
bioluminescent energy signatures — under the GRAPHICS_IDEAS sanction the owner
approved. These hexes exist **only on alien hulls and alien FX**; they never
appear on human ships, stations, UI or HUD, where the ember pair stays the
only accent.

| Hex | Name | Family use |
|-----|------|------------|
| `#1A281F` | Corrosive Dark | Swarmer hull shadow, chitin plate gaps |
| `#3D6E49` | Chitin Green | Swarmer plate mid-tone |
| `#4AE86C` | Bioluminescent Green | Swarmer energy signature — glow only |
| `#1C1F2B` | Abyssal Void | Sibelon hull shadow |
| `#3A4B6E` | Deep Teal | Sibelon pod plating mid-tone |
| `#2BE8E8` | Corrupted Plasma Cyan | Sibelon energy signature — glow only |
| `#2B1A28` | Warp Purple | Apex hull shadow |
| `#6E3A63` | Mutated Violet | Apex tendril/tissue mid-tone |
| `#E82BE8` | Void Magenta | Apex energy signature — glow only |

Rules, per family: hull plates stay near-black desaturated (the family shadow
and mid-tone above), weathering vocabulary unchanged, and **exactly one glow
colour per family** — the energy signature — applied where the human rules
apply ember (engines, weapons, warning lamps). Human-side FX, HUD and hostile
markers never borrow these colours. The 16-colour count in §2 reads "human
world"; the alien set is a second, entity-scoped palette, not an extension of
the UI one.

---

## 3. Lighting Rules

- **Key light direction:** fixed upper-left of frame, approximately 135 degrees azimuth relative to the ship's facing, so the top-left hull edge catches light and the lower-right falls to iron-black shadow.
- **Rim light:** a cold, pale steel rim (drawn from Steel Highlight `#565C63`) traces the shadow-side silhouette of every ship and hard object. It is thin — 2 to 4 pixels at gameplay resolution — and always brighter than the adjacent hull by a clear step, so shapes separate from the void background.
- **Intensity:** harsh and directional, high contrast between lit and shadow faces. Lit faces reach Steel Highlight; shadow faces drop to Iron Black `#232629`. No soft ambient fill that erases the shadow side.
- **Emission:** only Burnt Ember `#C8461B` and Ember Glow `#E8703A` are allowed to glow. Glows are small, hot, and contained — engine nozzles, weapon muzzles, warning lamps — never ambient scene glow. **Sanctioned exceptions (amended 2026-09-17):** (1) the shield hit ripple glows in Steel Highlight `#565C63` — the shield is not a danger state (mirrors UI_SPEC §3.1); (2) frame-1 flash frames of muzzle flash and explosion FX may read as a brightened/desaturated Ember Glow `#E8703A` hot core (the "white-hot" read is engine-side bloom over `#E8703A`, not a new palette colour). The 6 px menu hover bloom (§7.3 amendment) is the only other sanctioned glow. **Amendment 2026-09-17 (Phase D):** the field repair pulse `fx_repair_pulse.png` also glows in Steel Highlight `#565C63`, since a repair is not a danger state — see `FX_SPEC.md` §0. **Amendment 2026-09-18 (Phase F):** the two reward anomalies — `fx_anomaly_shimmer.png` (ore bloom) and `fx_anomaly_grave_glow.png` (grave cache) — glow in Steel Highlight `#565C63` with unlit Deep Void Blue `#111823`/Void Haze `#1A2230` halos, because neither is a danger state; `#C8461B` and `#E8703A` stay reserved for threat, so the third anomaly (`fx_anomaly_rift.png`, a pure hazard) carries the ember pair alone — see `FX_SPEC.md` §0. Anomalies introduce **no new palette colour**, only a new sanctioned non-ember glow site. **Amendment 2026-09-20 (alien families):** each alien family's single signature colour (§2.5) is a sanctioned glow **on that family's hulls and FX only** — Bioluminescent Green `#4AE86C` for swarmers, Corrupted Plasma Cyan `#2BE8E8` for Sibelon, Void Magenta `#E82BE8` for Apex. Human assets are untouched by this exception.
- **Atmosphere:** deep-space scenes are unlit voids; any environmental light is a distant cold source from the upper-left, consistent with the key light.

---

## 4. Weathering and Grain Vocabulary

Use these terms — and only these terms — in prompts and specs so weathering stays consistent:

- **scratches** — fine light scored lines through paint to bare steel, along motion direction.
- **battle damage** — dents, torn plate edges, scorch-blackened craters, weld beads over repairs.
- **oil stains** — dark greasy smears running from panel seams and engine housings.
- **hull grime** — broad dull umber film over large plate areas, heavier toward trailing edges.
- **rust streaks** — thin vertical or motion-direction rust bleed from rivets and seams.
- **pitted metal** — micro-dotted erosion on older plates, catching rim light as speckle.
- **scorch marks** — sooty black gradients radiating from muzzle ports and vents.
- **film grain** — subtle uniform photographic grain over the entire image, all assets without exception.

Standard weathering density: moderate — every ship shows scratches, hull grime, and oil stains; battle damage, rust streaks, pitted metal, and scorch marks appear on veteran/hostile hulls in particular but may appear lightly on any ship.

---

## 5. Camera Framing Constant

- **Projection:** top-down orthographic. No perspective, no tilt.
- **Ship occupancy:** ships occupy approximately **60 percent of frame width** in every standalone ship render. The remaining margin is void background.
- **Orientation:** ships face right in all sprite/reference renders.
- **Centre point:** ship's centroid sits at frame centre; the margin is split evenly.

---

## 6. Silhouette Rules for Ship Design

A ship must be identifiable by its blacked-out outline alone, before any surface detail is read.

1. **One glance, one read.** Each hull class and faction has a distinct primary silhouette: overall length-to-width ratio, nose shape, wing/pod arrangement, and engine count must differ visibly between classes.
2. **Mass at the core.** Central hull is the largest mass; appendages (pods, pylons, fins) project clearly so they add to the read.
3. **Asymmetric detail, symmetric base.** Base plan is broadly bilaterally symmetric for readability; asymmetry comes from damage, pods, and weapon mounts, which must not break the primary outline.
4. **Rim-light dependent shapes.** Any protrusion must be large enough to catch the rim light on its edge; micro-detail that cannot read at gameplay size is forbidden on the silhouette level.
5. **Class markers:** fighters are short, dart-like, twin engine; corvettes elongated with spine ridges; freighters boxy and segmented; hostile hulls carry thorned protrusions and a visible ember core. **Alien markers (ruling 24, 2026-09-20):** swarmer hulls are jagged chitin-plate clusters with insectoid mandible silhouettes; Sibelon pods curve bio-mechanically with glowing eye-clusters; Apex leviathans are massive multi-tendril hulls whose tendrils must read as part of the outline (no detached wisps).

---

## 7. Treatment Rules by Asset Type

### 7.1 Ships

Top-down orthographic, facing right, ~60 percent frame width. Gunmetal base in the `#2B2F35`–`#3A3F46` range with Steel Highlight rim on the shadow-side silhouette. Weathering per Section 4. Only engine nozzles, weapon ports, and warning lamps emit, in Burnt Ember/Ember Glow. Background is flat Void Black `#0A0E14` (transparent where a sprite is required).

### 7.2 Environment (asteroids, stations, debris, nebulae)

Same metal and rock vocabulary, but larger scale weathering: cracked rock faces, welded station platework with heavy hull grime and rust streaks, debris fields with battle damage. Environment reads one value step darker than ships so ship silhouettes always dominate. No emissive on environment except hostile station warning lamps in Burnt Ember. Backgrounds use Deep Void Blue `#111823` and Void Haze `#1A2230` washes with sparse faint stars; nebulas stay desaturated blue-grey with at most a whisper of ember where battle occurred.

### 7.3 UI Panels

Panel backgrounds Panel Black `#15181D` with 1 px Panel Steel `#2A2E35` borders and subtle inner shadow; corners slightly bevelled, never rounded-friendly or glossy. Text in Ash Text `#8D939B` for body and Bone Text `#C9CDD2` for headings/values. Film grain applies to panels at reduced opacity. The only colour permitted in UI is Burnt Ember `#C8461B` for warnings, hostile indicators, and critical values — never as decoration. Hover/selection states brighten the border to Ash Text, not to the accent.

**Amendment 2026-09-17 (menu hover-glow policy):** Menu and screen-level buttons (main menu, loading, dialogs outside gameplay) may additionally carry a small **Ember Glow `#E8703A` bloom on hover** — a 6 px soft outer halo plus a faint ember under-light baked into the hover plate art. This is the single sanctioned decorative use of the accent. Inside the in-game HUD the strict rule stands unchanged: hover/selection brightens the border to Ash Text only, and the ember palette remains reserved for danger semantics. The 1 px keyboard focus ring in `accent_danger_bright` (UI_SPEC §2.1) is sanctioned state colouring, not decoration.

### 7.4 Main Menu Background

A wide cinematic top-down vista: a wreck-strewn battlefield drifting in Deep Void Blue, painted in the same lighting (harsh upper-left key, cold steel rims), heavy film grain, drifting dust veils in Void Haze. One distant, small ember glow (a burning wreck) as the single accent point — it must stay small and off-centre so foreground UI owns the frame. Desaturated, dark overall; the menu must never compete with text legibility.

---

## 8. Prompt Rules

- Every image prompt begins with the verbatim STYLE BLOCK (Section 9) content, then adds the asset-specific subject.
- Use only the colour names and hex codes from Section 2; never introduce new colour words.
- Use only the weathering vocabulary from Section 4.
- Always include "top-down orthographic, facing right, ship occupies about 60 percent of frame width" for ship assets and "subtle film grain" for everything.
- Forbidden in prompts: chrome, neon, rainbow, saturated colours, cheerful, glossy, clean, vibrant, second accent colours (purple, green, teal, yellow), lens flare bloom beyond a small ember glow.
- **Alien-family exception (ruling 24, 2026-09-20):** assets for the three alien families use the **alien style block addendum** (below, §9.1) instead of the human style block — the human block's "no green/no purple" wording would kill the sanctioned alien palettes. Human-family assets never use the addendum.

---

## STYLE BLOCK

The following text is the fixed style wording. Save it verbatim as a plain text file `style-block.txt`; it is passed unchanged to the image generator on every asset run in this project. Everything between the markers below (markers not included in the file) is the exact file content.

```
grimdark painted sci-fi, semi-realistic weathered metal, harsh directional rim light from upper-left with a thin cold pale steel rim tracing shadow-side silhouettes, subtle film grain over the whole image, top-down orthographic view. Fixed palette: gunmetal mid #3A3F46, gunmetal dark #2B2F35, iron black #232629, steel highlight #565C63, rusted ochre #6E5B4A, dry rust #8A6A50, grimy umber #4A423B, void black #0A0E14, deep void blue #111823, void haze #1A2230, burnt ember #C8461B, ember glow #E8703A, panel black #15181D, panel steel #2A2E35, ash text #8D939B, bone text #C9CDD2. Metal colour is desaturated gunmetal and rusted steel, dark and tired, with scratches, oil stains, hull grime, rust streaks, pitted metal, scorch marks and battle damage. Glow colours are burnt ember #C8461B and ember glow #E8703A only, small and hot, used exclusively for engines, weapons and warning lights; no other glow or accent colour exists anywhere in the image. Backgrounds are near-black blue void, void black #0A0E14 to deep void blue #111823, sparse faint stars, desaturated throughout, no saturated colours, no chrome, no neon, no gloss, no clean surfaces, moody and menacing.
```

### 9.1 Alien style block addendum (sanctioned — owner ruling 24, 2026-09-20)

For alien-family assets the fixed subject block above is replaced by the
addendum below (preamble rules, weathering and framing sentences unchanged).
Everything else in §8 stays law.

```
grimdark painted sci-fi alien bioform, semi-realistic weathered chitin plating, harsh directional rim light from upper-left with a thin cold pale steel rim tracing shadow-side silhouettes, subtle film grain over the whole image, top-down orthographic view. Fixed palette per family — swarmer: corrosive dark #1A281F, chitin green #3D6E49, bioluminescent green #4AE86C glow; sibelon: abyssal void #1C1F2B, deep teal #3A4B6E, corrupted plasma cyan #2BE8E8 glow; apex: warp purple #2B1A28, mutated violet #6E3A63, void magenta #E82BE8 glow. Chitin plates are near-black desaturated and organic — jagged swarmer plates, curved bio-mechanical Sibelon pods, massive tendril-backed Apex leviathan hulls. Exactly one glow colour per family (the signature above), small and hot, used for engines, weapons and warning lamps; no ember, no orange anywhere on an alien asset. Backgrounds are near-black blue void, void black #0A0E14 to deep void blue #111823, sparse faint stars, desaturated throughout, no chrome, no neon, no gloss, no clean surfaces, moody and menacing.
```
