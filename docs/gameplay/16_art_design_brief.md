# 16 — Art & Design Brief (Graphics Designer Deliverables)

**Status:** Ready to work.
**Sources of style:** `STYLE_BIBLE.md`, `ICONS_SPEC.md` (§1 colour law),
`SHIPS_SPEC.md` (framing constant, §3 hull entries), `ASSET_EXPANSION_SPEC.md`
(generation rules, roster), `UI_CHROME_ASSETS_SPEC.md` (slot/panel chrome).
**Covers:** every asset gameplay docs 02–15 imply. The catalog
(`ASSET_CATALOG.md`) gets a new family section per deliverable when shipped.

---

## 1. Global rules (unchanged, repeated once)

- Every generation run copies `assets/style-block.txt` verbatim; framing
  constant and §6 negative lists from SHIPS_SPEC apply to any new hull.
- Icons are flat single-colour iron-black glyphs in the ICONS_SPEC §1 rules:
  no glow, no gradients; **ember `#C8461B` only for danger/armed states**.
- Generated art is not CC0: generation log (prompt/model/date) ships beside
  the assets, per AGENTS.md.
- Phase pipeline: generate 2K → stage → `staging/phase_d/reprocess.py` for
  alpha → cut → downscale → move into `assets/` → editor reimport. Review
  sheets via `build_review.py`; catalog via `build_catalog.py`.
- **Resolution law (amended 2026-09-18):** every icon family cuts
  `_{16,48,96,192}.png` from the retained master; `_16` is micro-only, `_48`
  legacy, `_96` the default for new consumers, `_192` detail and 4K/UI-scale
  headroom. Details: `ICONS_SPEC.md` §9.
- **Masters are never deleted.** The unsuffixed `icon_<name>.png` per icon
  (and the 2K panels for legacy families) is the permanent re-cut source.
  Phase F complies; legacy families re-split from
  `panel_{weapons,cargo,glyphs,boosters,status}.png`.

## 2. Deliverables by priority

### P0 — blocks code (needed by the economy phase)

**Status 2026-09-18: delivered by Phase F** — ore/ingot, module and slot panels
were generated and split to 16/48 (`assets/icons/generation_log_phase_f.md`).
The open item is the resolution upgrade and integrity fixes, specced as P0.5.

| Deliverable | Spec | Notes |
|-------------|------|-------|
| **Mineral icon sheet** | 5×4 grid, 20 minerals in tier order, per 02 §2; both ore and ingot reads per mineral (ore = raw faceted chunk, ingot = stamped bar) | cut to `icon_mineral_<name>_{16,48}.png` + `icon_ingot_<name>_{16,48}.png`; ICONS_SPEC §1 silhouette law; per-tier tint fallback lives in code until cut |
| **Module icons, 30** | one glyph per 09 §3 module, family-grouped like ICONS_SPEC §3 | 16/48 px each, same tint pipeline; weapons reuse existing 5 weapon glyphs where they exist |
| **Slot-type icons, 8** | ENGINE, POWER, W, S, H, C, B, U — for the fitting panel's slot headers | gunmetal silhouette + label; ember only on the empty-mandatory-slot warning state |

### P0.5 — Resolution and integrity fix pass (current work order, 2026-09-18)

The 4K standard (`ICONS_SPEC.md` §9): icons ship 16/48/96/192; the page below
is quoted verbatim into the designer work order.

| # | Fix | Source of the rule | Acceptance |
|---|-----|--------------------|------------|
| 1 | Re-cut every icon family at `_96` and `_192` from retained masters / 2K panels | ICONS_SPEC §9.2 | all four cuts present; stroke chain verified at 16 and 96 |
| 2 | `icon_cargo_data_core_16.png` redraw (coverage 0.98, edge collision) | ASSET_AUDIT C2 | silhouette clears the frame margin; reads at 16 |
| 3 | Outline-weight 16 px glyphs thickened at master (`zoom_plus`, `zoom_minus`, `credits`, `shield`) | generation_log.md | 16 px cut thresholds to solid iron black |
| 4 | White matte fringe on 13 files re-keyed/regenerated | ASSET_AUDIT C3 | clean outer alpha edge check |
| 5 | `ui_panel_frame.png` regenerated: painted band = 32 px margin, plus `@2x` 192×192 (64 px margins) | ASSET_AUDIT C1 | nine-patch preview at station sizes without rivet bleed |
| 6 | Reconcile `staging/phase_f/` output into `assets/` (miner hull, liveries, bosses, sector bgs, gate ring, arena props, anomaly FX, contract/service/insignia icons) with reimport + catalog | this brief, Phase F log | every staged family either shipped or listed with a reason |
| 7 | UI chrome `@2x` assessment (button plates, slot plates, bar caps, bezel) | ICONS_SPEC §9.4 note | re-cuts produced where masters allow; otherwise a cost estimate, no spend without approval |

Import settings for `_96`/`_192`: mipmaps on, lossless, 3D detection off
(coder wires the project filter via `17_coder_handoff.md` §2.1).

### P1 — needed by the map phase

**Status 2026-09-18: staged/delivered by Phase F** — `ship_miner_*`,
fighter liveries (Concord/Meridian/Choir), `ship_boss_boneyard/pyre`, seven
`env_sector_*_bg`, `env_jump_gate_ring`, arena props and the anomaly FX trio all
exist in `staging/phase_f/` and/or `assets/`. Confirm each is moved, imported and
catalogued (P0.5 #6).

| Deliverable | Spec | Notes |
|-------------|------|-------|
| **Miner hull `ship_miner`** | 08 §4 spec line; full SHIPS_SPEC §3 entry format (silhouette: wide flat mining frame, ventral cutter bar, dorsal ore bin, twin side engines; heavy weathering; 2 engines, dim civilian ember) | the only missing player hull; generate with the §1 framing constant |
| **Sector backdrops, 7** | 2048×1152 opaque, per 11 §1's sector feel (Halcyon orderly, Maw Belt hostile) | extends ENVIRONMENT_SPEC; two shared with existing env assets may be tinted instead — designer's call, documented |
| **Jump gate ring** | large radial structure, 4 engine blocks or none per 11 §2.1; top-down orthographic | also needs a small minimap gate glyph (16 px) |
| **Anomaly FX trio** | shimmer (bloom), grave glow (cache), rift distortion (void) — RGB on void black, additive-blend law per FX_SPEC §1 | |
| **Arena props** | nav-pylon ring, barricade plates, 2 arena bosses are re-liveries of existing hull classes (gunship/frigate band) with unique cores | bosses need their own SHIPS_SPEC §3 entries (add as amendments) |
| **Hunter/pirate liveries** | i2i recolours of fighter/corvette/gunship band, following ASSET_EXPANSION_SPEC §4's livery wave format | hunters get a Concord/Ports/Choir livery each |

### P2 — UI panels (with the station amendment)

**Status 2026-09-18:** contract/service/insignia icons delivered (Phase F); the
station panel previews exist under `staging/phase_f/_preview/`. Open items: the
`@2x` chrome assessment (P0.5 #7) and the coder's theme variant work when 2×
chrome ships.

| Deliverable | Spec |
|-------------|------|
| SERVICES / EXCHANGE / REFINERY / AUCTION / SHIPYARD panel chrome | reuse existing `ui_panel_frame.png` nine-patch; one review sheet per panel |
| Faction insignia, 3 | hexagonal emblems per 12 §1 identity, single-colour, tintable |
| Contract-type icons, 5 | haul/hunt/gather/escort/expedition glyphs |
| Vault, insurance, bounty glyphs | 3 service glyphs for the services deck |
| Cargo glyph tint table | per-tier tints for ore/container fallback (02 §6, 03 §4.1): T1 steel `#565C63`, T2 gunmetal-bright, T3 ochre `#8A6A50`, T4 desaturated ember-adjacent — **never `#C8461B`** |

## 3. What the designer should NOT do

- No new weapon silhouettes beyond the module sheet (the five existing HUD
  weapon sprites carry v1; `w_proton`/`w_flak`/`w_railgun` share family
  silhouettes with plasma/cannon until a Phase F icon pass).
- No hand-editing of generated assets; pipeline edits only (AGENTS.md).
- No new currency or resource icons — credits are the only currency and its
  icon exists.
- No animation work in this phase; FX stay single-frame additive sprites.

## 4. Acceptance checklist (per deliverable)

1. Silhouette reads at 48 px *and* 16 px (ICONS_SPEC §2 standard).
2. Palette within STYLE_BIBLE §2 fixed palette; accent discipline held.
3. Alpha: sprites keyed to >90 % clean edges; FX stay RGB-on-black.
4. Ship framing constant verbatim on every hull render.
5. Catalog entry added in `ASSET_CATALOG.md` with alpha + size facts.
6. **All four icon cuts exist** (`_16/_48/_96/_192`); stroke chain verified at 16
   and 96 px (ICONS_SPEC §9.3); masters retained.
7. **4K check:** a composite of the affected screen at 2× physical scale (or a
   standalone 3840×2160 run) shows no visible upscaling on any icon surface.
8. **Import facts recorded:** mipmaps on for 96/192, lossless, 3D detection off.
