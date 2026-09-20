# Vajb Orbit — UI Chrome Assets Spec

**Status:** final Phase-A asset spec. This is the generated-art half of `UI_SPEC.md` (theme architecture §2, texture states §3.2, nine-patch pattern §5.3). Sizes match `UI_SPEC.md` §6 exactly. Hover states follow `MAIN_MENU_SPEC.md` §4. Palette and wording are copied verbatim from `STYLE_BIBLE.md` (§2 palette, §7.3 UI panel rules).

**Deliverable:** generated PNG art only. The engine wiring (StyleBoxTexture, NinePatchRect, TextureButton state assignment) is the Phase-C coding pass, described here only where it constrains the art.

---

## 1. Universal Rules

Every image in this spec is generated from `vajb-orbit/assets/style-block.txt`, passed unchanged to the generator on every run, prepended to the asset-specific prompt.

1. **Grid panels.** Multi-state assets are generated as ONE image: a 2×2 grid at 2048×2048, 1:1, with generous gaps between the four cells and **no grid lines, no borders around the grid, no labels or text of any kind** on the panel. The four cells are exported after generation as individual files (naming in §9), so the gaps must be clean.
2. **Backgrounds.** All chrome pieces sit on a **plain solid pure white background** so they split cleanly to transparency. Two exceptions: the game logo lockup and the loading backdrop, which get their own background treatment (§7, §8).
3. **Palette.** Only the 14 fixed STYLE_BIBLE colours. UI chrome is drawn from: panel black `#15181D`, panel steel `#2A2E35`, gunmetal dark `#2B2F35`, gunmetal mid `#3A3F46`, iron black `#232629`, steel highlight `#565C63`, ash text `#8D939B`, bone text `#C9CDD2`, burnt ember `#C8461B`, ember glow `#E8703A`.
4. **Panel look (STYLE_BIBLE §7.3, verbatim):** "Panel backgrounds Panel Black `#15181D` with 1 px Panel Steel `#2A2E35` borders and subtle inner shadow; corners slightly bevelled, never rounded-friendly or glossy. Text in Ash Text `#8D939B` for body and Bone Text `#C9CDD2` for headings/values. Film grain applies to panels at reduced opacity. The only colour permitted in UI is Burnt Ember `#C8461B` for warnings, hostile indicators, and critical values — never as decoration. Hover/selection states brighten the border to Ash Text, not to the accent."
5. **Hover-glow policy (MAIN_MENU_SPEC §4):** ember glow is a **menu-screen privilege only**. The 6 px soft outer halo on hover (`#E8703A`, 60 % alpha) is **drawn by the engine as a StyleBoxFlat underlay, never baked into any atlas**. The only ember baked into generated art is the faint under-light inside the hover button plate (§3). HUD slots never glow: their hover state is a brightened plate only.
6. **Weathering/grain.** Subtle film grain on every image (reduced opacity on panels). No battle damage, rust streaks, or oil stains on chrome — chrome is maintained, not veteran; scratches at most faint. No glossy, clean, or chrome-shine finishes.
7. **No text anywhere** in generated chrome, except the logo lockup (§7), which is the one deliberate text-as-art exception.

---

## 2. Nine-Patch Metal Panel Frame

**File:** `ui_panel_frame.png` — single texture, **96×96 source, 32 px frame width**.

Generated description:

- A square metal panel frame, top-down orthographic feel, grimdark painted sci-fi: weathered gunmetal plate border surrounding a recessed panel black `#15181D` interior fill.
- Border face is panel steel `#2A2E35` with a 1 px steel highlight `#565C63` inner edge catch and iron black `#232629` outer edge, giving a shallow bevelled read.
- **Corners slightly bevelled, never rounded** — chamfered 45° corner cuts, not arcs. Each corner carries a **riveted corner detail**: two or three small rivet heads (pitted metal speckle, steel highlight catch) set into a slightly denser corner plate.
- Subtle film grain at reduced opacity; faint hull grime toward the frame, no rust streaks, no oil stains.
- The recessed interior is panel black `#15181D` with a very subtle inner shadow just inside the frame edge.

**Nine-slice requirement (must be stated in the prompt and verified after generation):** the frame is **uniform on each side** — the left edge band is identical top-to-bottom, the top edge band identical left-to-right, and likewise right and bottom — so it stretches cleanly when the 32 px edge bands (patch margins 32 on all four sides, per UI_SPEC §5.3) are tiled over a larger panel. The riveted corner details live entirely inside the four 32×32 corner squares and must not bleed into the edge bands.

---

## 3. Menu Button Plate Atlas

**Files:** one 2×2 grid panel generated per rule §1.1, exported as `ui_button_plate_normal.png`, `ui_button_plate_hover.png`, `ui_button_plate_pressed.png`, `ui_button_plate_disabled.png`. Each state is a **280×56 plate** (MAIN_MENU_SPEC §3), scaled within its grid cell.

All four states are the same plate: a painted gunmetal metal plate with a 1 px border, slight bevelled edges, two small rivets (one per short side), subtle film grain. **Cell letterboxing (must be stated in every grid prompt):** each 2×2 cell is a square; the 280×56 plate is centred inside its cell with clean pure-white letterbox margins on all sides (roughly 60 percent of cell width), so the splitter cuts on empty space and the plate exports un-clipped.

- **Normal:** body gunmetal dark `#2B2F35` with a 1 px panel steel `#2A2E35` border; bevel highlight steel highlight `#565C63` along top/left, iron black `#232629` shadow along bottom/right; restrained grain.
- **Hover:** body brightened one step to gunmetal mid `#3A3F46`, border to ash text `#8D939B` per STYLE_BIBLE §7.3 hover rule, **plus a faint ember under-light baked into the lower bevel in ember glow `#E8703A` at low intensity** — a thin warm inner glow rising from the bottom edge of the plate only, small and contained, reading as heat behind the metal. This is the single sanctioned baked use of the accent (§1.5).
- **Pressed:** inset bevel with **borders flipped** — the bevel highlight `#565C63` moves to bottom/right, the shadow `#232629` to top/left — body darkened to iron black `#232629` blending toward gunmetal dark `#2B2F35` (fixed-palette hexes only; engine theme tokens such as `void_panel_raised` never appear in generation prompts) so the plate reads pushed in.
- **Disabled:** unused in v1 (MAIN_MENU_SPEC §4) but generated anyway from the same family: body gunmetal dark `#2B2F35`, border gunmetal dark, details desaturated and flatter, no bevel catch, no ember.

**Division of labour (explicit):** the **6 px soft outer hover halo in ember glow `#E8703A` at 60 % alpha is engine-drawn** (StyleBoxFlat underlay with `expand_margin_* = 6` behind the plate, per MAIN_MENU_SPEC §4 and UI_SPEC §2.2). It is **not in this atlas**. Only the under-light on the plate itself (hover state, above) is baked art. The atlas must contain no outer glow, no bloom, no halo pixels on any state.

---

## 4. Weapon Slot Plates

**Files:** one 2×2 grid panel per §1.1, exported as `ui_slot_weapon_normal.png`, `ui_slot_weapon_hover.png`, `ui_slot_weapon_pressed.png`, `ui_slot_weapon_disabled.png`. Each state is a **48×48 slot**, matching UI_SPEC §3.2 texture states and §6 sizing.

A square recessed gunmetal slot plate, 1 px border, hard corners, subtle grain; inside each plate, a **weapon silhouette in steel highlight `#565C63`** — a clean painted shape reading as a laser/blaster hardpoint form, drawn as flat rim-lit geometry, no glow, no ember.

- **Normal:** plate gunmetal dark `#2B2F35`, border panel steel `#2A2E35`, silhouette `#565C63`.
- **Hover:** plate brightened one step to gunmetal mid `#3A3F46` (border to ash text `#8D939B`); silhouette unchanged. No ember, no glow — HUD policy (§1.5).
- **Pressed:** plate darkened to iron black `#232629` (fixed-palette hex only); silhouette unchanged.
- **Disabled:** silhouette at **40 percent alpha**, plate gunmetal dark `#2B2F35` (weapon not owned / on cooldown; the cooldown sweep wedge is script-drawn at runtime, not in art).

The same four state descriptions apply verbatim to §5 by swapping the plate size and the interior subject.

---

## 5. Cargo and Inventory Slot Plates

Two separate 2×2 grid panels, same state system as §4 (normal / hover / pressed / disabled):

- **Cargo:** `ui_slot_cargo_normal.png`, `ui_slot_cargo_hover.png`, `ui_slot_cargo_pressed.png`, `ui_slot_cargo_disabled.png` — each state a **40×40 slot** (UI_SPEC §3.4, §6). Interior subject: a generic cargo crate/box silhouette in steel highlight `#565C63`, same rendering rules as the weapon silhouette.
- **Inventory:** `ui_slot_inventory_normal.png`, `ui_slot_inventory_hover.png`, `ui_slot_inventory_pressed.png`, `ui_slot_inventory_disabled.png` — each state a **56×56 slot** (UI_SPEC §5.4, §6). Interior subject: a generic item silhouette (module/equipment form) in steel highlight `#565C63`.

State colours, borders, hover-no-glow rule, and 40 % alpha disabled rule are identical to §4. The active-weapon ember frame and the drag-invalid ember border are script-drawn at runtime (UI_SPEC §3.2, §5.4) — never baked.

---

## 6. Progress Bar End Caps and Minimap Bezel

**One generated panel** (not a grid; a single composition with two clearly separated subjects, exported as two files):

- `ui_bar_caps.png` — **left and right end caps for the 14 px tall progress bars** (UI_SPEC §3.1 bar height, §6). Two small caps on the panel: 14 px tall, 20 px wide each, painted gunmetal plate ends with a panel steel `#2A2E35` border and one rivet each, designed to bookend a 260×14 bar whose fill/body are engine styleboxes. The caps sit on the plain white background with generous separation.
- `ui_minimap_bezel.png` — **a 200×200 square frame with a 16 px frame width** for nine-slicing (UI_SPEC §3.3 minimap panel chrome). Same material family as the nine-patch panel frame (§2): panel steel `#2A2E35` border face over a recessed interior of precisely panel black `#15181D` with bevelled chamfered corners and a lighter riveted corner treatment (smaller rivets, one per corner). **Frame uniform on each side** so 16 px patch margins slice cleanly. Interior fill panel black `#15181D` with subtle inner shadow; the minimap dots/lines are drawn by script at runtime, so the interior stays empty.

---

## 7. Game Logo Lockup

**File:** `logo_vajb_orbit.png` — single art piece, **2048×2048, 1:1**. **Safe content bounding box:** the wordmark sits inside a centred horizontal band, roughly 1800×500 px, leaving generous void margins on all sides for boot-title cropping; keep all letterforms inside that band.

Generated description:

- The word **VAJB ORBIT** as painted title art, **not** a font render: a Blaec-like **blackletter titling style** — dense, angular gothic letterforms with sharp terminal spikes, hand-painted brushwork energy, softened edges where light falls off, hard edges only on the letter silhouettes.
- Letters in **bone text `#C9CDD2`**, harsh upper-left key light, thin cold steel highlight tracing the top-left edges, iron black `#232629` drop shadow toward the lower-right.
- **Exactly one ember accent element:** a small, hot ember glow `#E8703A` (burnt ember `#C8461B` core) integrated into a single letterform — a crack in one letter or the dot of a ligature — small and contained, never a bloom across the wordmark.
- Subtle film grain over the whole image.

**Background treatment:** transparent-capable — generated on plain white like the chrome pieces, but after splitting it is shipped as a **transparent PNG**; no backdrop, no panel, no vignette behind the letters.

**Engine note (must be stated):** engine text uses the **real Blaec font**; this lockup is the painted art version used for the boot sequence and main menu title only (MAIN_MENU_SPEC §1, §3). It never appears in gameplay HUD.

---

## 8. Splash and Loading Backdrop (parked — fallback only)

**Decision 2026-09-17:** `env_loading_bg.png` (ENVIRONMENT_SPEC §3, wreck vista at 40 % opacity) owns the loading-screen background. This section is **parked, not generated**: `ui_loading_backdrop.png` is produced only if the vista fails legibility review. Kept for reference:

**File:** `ui_loading_backdrop.png` — single image, 2048×2048, 1:1.

Generated description:

- A dark, simple, mostly featureless plate: **mostly void black `#0A0E14`** across the entire frame, with **faint panel steel `#2A2E35` detail at the edges** — a whisper of brushed metal framing, hairline seams, and sparse rivet speckle hugging the image border, vignetting into the void centre.
- No stars, no ships, no wrecks, no ember glow, no logos, no text. It must never compete with the centred "ENTERING SECTOR" label or the progress bar drawn over it (MAIN_MENU_SPEC §2 uses it at 40 % opacity over `void_base`).
- Subtle film grain.

**Background treatment:** this piece **is** the background; it ships opaque, no transparency, no white backdrop split.

---

## 9. File Naming Summary

Snake_case, under `vajb-orbit/assets/ui/`:

| File | Origin |
|---|---|
| `ui_panel_frame.png` | §2 single texture |
| `ui_button_plate_normal.png` / `_hover` / `_pressed` / `_disabled` | §3 2×2 grid, sliced |
| `ui_slot_weapon_normal.png` / `_hover` / `_pressed` / `_disabled` | §4 2×2 grid, sliced |
| `ui_slot_cargo_normal.png` / `_hover` / `_pressed` / `_disabled` | §5 2×2 grid, sliced |
| `ui_slot_inventory_normal.png` / `_hover` / `_pressed` / `_disabled` | §5 2×2 grid, sliced |
| `ui_bar_caps.png` | §6 panel export |
| `ui_minimap_bezel.png` | §6 panel export |
| `logo_vajb_orbit.png` | §7, transparent PNG |
| `ui_loading_backdrop.png` | §8, opaque, **parked fallback — do not generate by default** |
| `ui_insignia_mmo.png` / `ui_insignia_mic.png` / `ui_insignia_ven.png` / `ui_insignia_neutral.png` | **Amendment 2026-09-17:** company emblems, generated as one 2×2 panel per `docs/design/ASSET_EXPANSION_SPEC.md` §5; transparent PNG, painted per §7.3, no letterforms |

**Sizing cross-check against UI_SPEC §6:** button plate 280×56, weapon slot 48×48, cargo slot 40×40, inventory slot 56×56, bar cap 14 px tall, minimap bezel 200×200 with 16 px frame width, panel frame 96×96 with 32 px frame width. Any mismatch with the final UI_SPEC is a spec error — fix here first, then regenerate.

---

## 10. `@2x` Chrome Cuts (amendment, 2026-09-18)

Same layout law, twice the pixels. Every chrome texture whose consumer can occupy
wider than its logical box also ships a 2× cut, so a 4K screen (canvas 2× physical,
up to 2.5× with UI scale — `ICONS_SPEC.md` §9.1) does not upscale painted chrome.
**Display size stays logical**: the §9 sizes are unchanged, the coder points the
theme/slot variant at the `@2x` file and renders it at half scale.

| File | Logical box | `@2x` box |
|---|---|---|
| `ui_panel_frame@2x.png` | 96×96, 32 px border band | 192×192, 64 px border band |
| `ui_button_plate_{normal,hover,pressed,disabled}@2x.png` | 280×56 | 560×112 |
| `ui_slot_weapon_{normal,hover,pressed,disabled}@2x.png` | 48×48 | 96×96 |
| `ui_slot_cargo_{normal,hover,pressed,disabled}@2x.png` | 40×40 | 80×80 |
| `ui_slot_inventory_{normal,hover,pressed,disabled}@2x.png` | 56×56 | 112×112 |
| `ui_bar_caps@2x.png` | 42×14 (two 20×14 caps, 2 px gap) | 84×28 (two 40×28 caps, 4 px gap) |
| `ui_minimap_bezel@2x.png` | 200×200, 16 px frame | 400×400, 32 px frame |

- Produced by re-running the **original resize chain on the retained 2K source
  cut** at twice the target box — never by upscaling the shipped 1× file.
- Inventory slots are included by the same rule even though the F.1 work order
  listed only the weapon and cargo plate families: one slot class cannot ship two
  geometry conventions.
- Godot 4 has **no** `@2x` import convention (no importer auto-scaling, unlike
  Godot 3's `texture_set_shrink_all_x2_on_set_data`), so the suffix is a
  bookkeeping name only: the coder must scale explicitly.
- `ui_panel_frame@2x.png` comes from the F.2 frame regeneration plus the local re-band
  (`ICONS_SPEC.md` §9.8 C1), which makes the painted border band equal the nine-slice margin:
  32 px at 96, 64 px on the `@2x` (`ICONS_SPEC.md` §9.4 item 4).

**Status 2026-09-18 (F.1 + F.2).** All **19** `@2x` cuts in the table above ship
(`staging/phase_f/chrome_2x_report.json`, `plates_report.json`). F.1 cut 15 of them by
re-running the G6 chain at 2× on the retained 2K sources, each proven by re-running the same
chain at 1× and comparing with the shipped file — the twelve slots and the bezel reproduce byte
for byte, the bar caps within 3 levels on seam pixels.

The four `ui_button_plate_*` were **blocked, not cut** at F.1: no retained run reproduces the
shipped plates (mean absolute channel error 26-32 against every candidate source and filter,
worst 255; shipped alpha mean 218 versus 246 for the same source resized, i.e. a post-resize
keying step whose recipe is not recorded — a uniform-alpha-scale hypothesis was tested at F.2
and fails at 29 levels of error). F.2 therefore spent the estimated run: a new 2x2 plate panel
(job `fedb0cff…`), from which `plates_cut.py` cuts **both** boxes out of the same cell by the
same rule, so the two scales are the same art by construction (the `@2x` downscaled to the
logical box differs from the 1× by <= 0.44 levels; each pair fills its box identically, so the
four button states swap without a shift).

**One look change to be aware of:** the shipped 1× plates come from that F.2 panel and read
darker and flatter than the previous set, which was glossier than `STYLE_BIBLE.md` §2 allows
(no chrome, no clean surfaces). Shipping the pair is the only way to satisfy the same-art rule
above; restoring the four 1× files from `staging/phase_f/_f2_backup/` would keep the old look
with a mismatched `@2x`.

**Frame margin — resolved.** The band and the margin now agree, so the 32 px margin law
stands unchanged. The F.2 frame is re-banded locally from the model's 19 % band
(`reband_frame.py`): a drawn nine-patch panel measures a painted band of **30 px of the 32 px
margin** at 96 (12 px before) and **59 of 64 px** at 192 (25 before), the residue being the
art's own near-black inner catch line inside the band. `tools/build_theme.gd`'s
`PANEL_FRAME_MARGIN` and `vajb_theme.tres` keep **32** for the 1× texture; the `@2x` variant
takes **64** when the coder wires it (`ICONS_SPEC.md` §9.8, C1). No scene consumes
`PanelRaised` yet, so the wiring can land with the station hub.
