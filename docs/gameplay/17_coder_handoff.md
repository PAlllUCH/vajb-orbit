# 17 — Coder Handoff: Implementation Order and Contracts

**Status:** Ready to code.
**Purpose:** one page that tells a coder what to build, in what order, where
each piece lives, and how to verify it. The numbered gameplay docs remain
the source of truth for every number; this document is the build plan.

---

## 1. Implementation phases

Each phase is independently shippable and leaves the game playable. Do not
start a phase before the previous one is verified (tests + a live editor
run, per AGENTS.md tooling).

| Phase | Docs | Delivers |
|-------|------|----------|
| **P1 — Economy core** | 01, 02, 04, 05 | mineral/component catalogues, mining yields, refinery panel, exchange module, repairs, transaction log |
| **P2 — Ships** | 08, 09, 10 | class table, module catalogue, power budget, fitting panel, auction + shipyard modules |
| **P3 — Space** | 11, 13, 06 | sector registry, gates/corridors, anomalies, derelicts, heat + hunters, loot tables |
| **P4 — Services** | 12, 14, 15 | factions/standing, contracts, insurance, vaults, arenas, affix rolls |
| **P5 — Crafting** | 07 | blocked: requires user sign-off on 07 §4's open questions first |

## 2. File map (new code, one owner per file)

| File | Owns | Doc |
|------|------|-----|
| `game/mineral_catalog.gd` | 20 minerals, ore/ingot pairs, static helpers | 02 |
| `game/component_catalog.gd` | 18 components, static helpers | 03 |
| `game/module_catalog.gd` | 30 modules + affix tables (15) as data | 09, 15 |
| `game/sector_registry.gd` | 7 sectors: owner, tiers, neighbours, gates, densities | 11 |
| `game/faction_registry.gd` | 3 factions: demand biases, discounts, exclusives | 12 |
| `game/contract_registry.gd` | 5 contract types, parameterised | 14 |
| `game/loot_tables.gd` | drop tables per hull band | 06 |
| `game/refinery.gd`, `game/exchange.gd`, `game/shipyard.gd` | pure transaction functions over `PlayerProfile` | 04, 05, 10 |
| `autoload/world_clock.gd` | the 20-minute accumulator (5 consumers: 05 bands, 10 rotation, 14 contracts/arena, 11 respawn) | all |
| `game/ship_fit.gd` | stats resolution order (09 §5), power-budget validation | 09 |

No file touches `addons/godot_ai/` (AGENTS.md). Station panel scenes land
under `ui/station/` next to the planned station modules; their pixel specs
amend `STATION_HUB.md` panel by panel.

### 2.1 Icon consumption (resolution standard)

Icons ship as `_{16,48,96,192}.png` cuts from retained masters (ICONS_SPEC §9,
16_art_design_brief P0.5). Consumption rule:

- `_16` only for micro chips; `_48` for legacy references (never silently
  re-pointed); `_96` is the default for all new consumers; `_192` for detail
  surfaces that can render >96 physical px (hover/inspect panes) and for 4K +
  UI-scale headroom.
- New code references the size band it needs directly; switching an existing
  `_48` reference is a documented amendment, not a side effect of this phase.
- Project texture filter must be set to Linear Mipmap (with mipmaps generated
  on `_96`/`_192` imports) via the `PROJECT_SETTINGS_PATCH.md` route; otherwise
  downscaled icons alias.

**Amendment 2026-09-18 (F.1 — the quartet is shipped and measured).**

- All 139 icon families now ship `_16`/`_48`/`_96`/`_192` from one retained master,
  cut aspect-preserving contain-fit (`ICONS_SPEC.md` §9.6). Consequence for code: a
  cut is a square frame whose *longest* ink axis fills it and whose other axis is
  proportional, so a fixed-size cell must keep the texture's aspect (no assumption
  that the glyph fills the box in both axes).
- The tint stencil set grew 278 → 556 (`assets/icons/tint/`, glob
  `_{16,48,96,192}`); `_96` stencils are what new consumers tint.
- Import facts are applied for the 293 `_96`/`_192`/`@2x` art files and their 278
  tint stencils: mipmaps on, lossless, 3D detection off. **Still open:** the project
  canvas texture filter is the default Linear, not Linear Mipmap, so the mips are
  generated but not sampled until that setting lands (this file, §2.1 above).
- Chrome `@2x` cuts exist for the twelve slot plates, the bar caps, the minimap
  bezel and the panel frame (`UI_CHROME_ASSETS_SPEC.md` §10). The four
  `ui_button_plate_*` `@2x` cuts are pending a regeneration run (estimate in §10).
- `ui_panel_frame.png` is 96×96 and its painted band now equals the nine-slice margin
  (30 of 32 px, `ICONS_SPEC.md` §9.8 C1), so **`PANEL_FRAME_MARGIN` stays 32** and no
  theme margin change is needed; the `@2x` cut (192×192) takes **64** when the coder
  wires it. No scene consumes `PanelRaised` yet.

**Amendment 2026-09-18 (F.2 — the batch residue, all five items closed).**

- The four outline glyphs (`icon_zoom_plus`, `icon_zoom_minus`, `icon_credits`,
  `icon_shield`) carry a heavier master weight (ICONS_SPEC §1, the 16 px legibility
  band): stroke 2.5-3.5 px and solid-ink share 0.42-0.50 at 16 px, against the set's
  0.29 median. Nothing in code changes; the `_16` band of those four simply reads
  solid now. Their quartet and tint stencils were re-cut/re-derived and reimported.
- The four `ui_button_plate_*` now ship a `@2x` cut (560×112) alongside the logical
  280×56, both cut from the same F.2 cell (same-art diff ≤ 0.44 levels), so the pair
  is safe to swap between scales. The shipped 1× plates are a new generation and read
  darker/flatter than the previous set (`UI_CHROME_ASSETS_SPEC.md` §10) — the theme's
  texture references do not change, only the bytes behind them.
- All four `ship_drone_swarm_*` carry a clean outer edge now (band mean luminance
  50-58, was 139-158) and `env_body_ice_moon` sits below the ships family mean.
- Import state audited: every one of the 1445 imported assets has an `.ctex` matching
  its current source. The import cache needed a touch + headless `--import` pass to
  notice F.2's rewritten bytes; a plain `scan`/`reimport` reports success against a
  stale `.ctex` (worth remembering for any future asset pass).
- **Still open, unchanged:** the project canvas texture filter is Linear, not Linear
  Mipmap, so the `_96`/`_192` mip chains stay unsampled until that setting lands.

## 3. Persistence (one save migration, one flag day)

`PlayerProfile` save_version 1 → 2. New persisted state, all through the
existing debounced `ConfigFile`:

| Key | Shape | Doc |
|-----|-------|-----|
| `modules` | `module_instance_id -> {base_id, rarity, prefixes, suffixes, count}` | 15 §6 |
| `fits` | `ship_id -> {slot_type -> module_instance_id}` | 09 §4 |
| `market` | `mineral_id -> demand float`, `component_id -> stock`, timestamps | 05 §2/§4 |
| `heat` | `faction_id -> int` | 13 |
| `standing` | `faction_id -> int` | 12 §4 |
| `contracts` | active list (max 3) | 14 §2 |
| `vaults` | `station_id -> {tier, contents}` | 14 §4 |
| `insured`, `mercy_used` | flags | 14 §3 |
| `vitals` | `ship_id -> {hull int, shield int}` | 01 §6 — amendment 2026-09-18 (P1): the repairs panel needs the active ship's current hull and shield; `game.gd` files a damage report into this key when docking, and the station's REPAIRS module restores it (owner-approved extension) |

New `profile_changed` keys: `&"modules"`, `&"fits"`, `&"standing"` —
following the existing signal pattern (STATION_SPEC §3). Migration rule:
v1 profiles load with every new key at its default (01 §5.5-shaped zero
state); no data loss, no version bump drama beyond the version field.

## 4. The one-timer rule

Everything periodic in the station (exchange band re-roll, auction rotation,
contract refresh, arena cooldown, sector respawn bookkeeping) consumes
**one** 20-minute accumulator owned by `world_clock.gd`, evaluated at
station entry and at each transaction. No per-consumer Timers, no drift
between systems' clocks (14 §9).

## 5. Transaction law (applies to every new function)

1. Verify → charge/take → pay/give → emit → log. All-or-nothing per confirm.
2. Only `PlayerProfile` mutates credits/cargo; panels only request.
3. Integers only; no negative balances; every economy event writes a
   `user://economy_log.txt` line (01 §7).
4. Prices come from catalogue data through the one pricing function (05 §8);
   no UI math.

## 6. Test checklist (headless-assertable)

- **02/05:** price function reproduces the 05 §3 table at demand 1.0/0.6/1.6
  and the 05 §5 worked examples exactly.
- **04:** 3 Iron ore + 15 CR fee → 1 Iron ingot; partial stacks unconverted.
- **06:** expected-value assertions per hull class (±5 %) and the grade-cap
  assert against the catalogue at load (06 §6).
- **09:** power-budget validator accepts/rejects the 09 §6 reference fits;
  stats resolution reproduces the frozen Vanguard stats from the standard
  fit (09 §7).
- **10:** Corvette build total = 15 445 CR with the §4 recipe.
- **13:** heat gains/decays match §2; Outlaw tier refuses dock/gate.
- **Persistence:** save→reload round-trip for every §3 key; v1 profile
  loads clean under migration.
- **Assets:** spot-check a panel using `_96`/`_192` icons at 4K (a standalone
  run — window-mode/resolution settings are inert in editor-embedded runs,
  AGENTS.md); verify imports carry mipmaps and lossless compression.

## 7. Known deferrals (do not implement)

- Crafting (07) — design-gated.
- Buy-side exchange (02 §9, 03 §6) — amendment path defined.
- Bounties-as-missions (01 §3), fuel, quality rerolls (15 §6), FOW beyond
  soft reveal (11 §3.3) — all later-phase by design, not omissions.
- UI chrome `@2x` variant wiring (theme/store variant switching) — files come
  from the P0.5 #7 art pass; the coder work is a separate approved task.
