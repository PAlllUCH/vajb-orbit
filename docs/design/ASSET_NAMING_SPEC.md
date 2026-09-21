# Asset Naming Spec

**Status:** proposed, awaiting owner sign-off on the open decisions in section 10.
**Applies to:** every file in `asset-library/raw/` and `asset-library/cut/`, and every path a
feature loads from `res://assets/`.
**Executed by:** `staging/cut/naming_assignments.py` (the decisions, as data) and the rename
engine. The full per-file table is `staging/cut/_naming/assignments.tsv`.

This spec exists because the names in the library come from generation runs, not from a scheme.
**198 of the 540 cut files** and **55 of the 170 raw sheets** cannot keep their name, 9 of the
remainder actively lie about what they show, and 34 code files hold 201 literal asset paths that
a rename must move with it.

## 1. The grammar

```
<family>_<subject>[_<qualifier>][_<variant>][_<index>]
```

- Characters: lowercase `a` to `z`, digits `0` to `9`, underscore. Nothing else.
- No dots, no capitals, no spaces, no timestamps, no run ids, no version markers such as `_v2`.
- `<family>` is one of the prefixes in section 2, always present, always first.
- `<subject>` is what the thing is, in one or two words: `bomber`, `mineral`, `jump_gate`.
- `<qualifier>` narrows the subject: `ship_fighter_concord` (a fighter in Concord livery).
- `<variant>` is from the closed list in section 4.
- `<index>` is a trailing digit only where a family is genuinely numbered: asteroid size bands,
  star layers, sectors.

## 2. Families and folders

| Prefix | Folder | Holds | Master |
|---|---|---|---|
| `ship_` | `assets/ships/` | hulls, bosses, liveries, turret platforms | one file per view |
| `icon_` | `assets/icons/` | flat single-colour glyphs | one file per glyph, no suffix |
| `env_` | `assets/env/` | scenery, bodies, POIs, pickups, props, backdrops, tiling layers | one file per object or plate |
| `ui_` | `assets/ui/` | chrome, insignia, backdrops, slots, button plates | one file per state |
| `fx_` | `assets/fx/` | combat and screen effects, RGB on void black | one file per effect |
| `panel_` | `assets/icons/` | the 2K panel a family of glyphs was cut from | one file per panel |
| `logo_` | `assets/ui/` | the wordmark | `logo_vajb_orbit` |

`panel_` masters are provenance-grade: they ship as whole atlases because the game reads regions
out of them with `AtlasTexture`, and they are also cut into the glyphs they contain. Both uses
are sanctioned and both must keep working.

`audio/` is out of scope: 95 CC0 files with their own cue names, untouched by this spec.

## 3. Containers

`icons/` holds 288 files, so a reader needs one more level. Containers are matched by prefix, so
the rule is mechanical rather than a judgement:

| Container | Prefix | Contains |
|---|---|---|
| `icons/mineral/` | `icon_mineral_` | 20 ore glyphs |
| `icons/ingot/` | `icon_ingot_` | 20 ingot glyphs |
| `icons/cargo/` | `icon_cargo_`, `icon_credits` | hold items and currency |
| `icons/contract/` | `icon_contract_` | mission types |
| `icons/map/` | `icon_map_` | starmap nodes, routes, bookmarks |
| `icons/booster/` | `icon_booster_` | consumables |
| `icons/equip/` | `icon_equip_` | fitted equipment |
| `icons/module/` | `icon_module_` | ship modules |
| `icons/weapon/` | `icon_weapon_`, `icon_ammo_` | weapons and ammunition |
| `icons/insignia/` | `icon_insignia_` | faction marks |
| `icons/service/` | `icon_service_` | station services |
| `icons/slot/` | `icon_slot_` | slot sockets |
| `icons/status/` | `icon_status_` | state markers |
| `icons/alt/` | `icon_alt_` | declared alternates: renderable art that no spec orders, parked rather than named as if sanctioned |
| `icons/hud/` | everything else under `icon_` | `icon_gear`, `icon_hull`, `icon_shield`, `icon_close`, `icon_logout`, `icon_zoom_*` |

`env/` splits the same way: `env/backdrop/` (`_bg`, `_plate`), `env/body/` (moons, planets),
`env/poi/` (bases, outposts, stations, gates, mines), `env/prop/` (wrecks, debris, ice fields,
ore clusters), `env/pickup/`, `env/tile/` (tiling and seamless layers).

## 4. The closed variant vocabulary

Nothing outside this list may appear as a variant. A new variant means amending this spec.

| Applies to | Variants |
|---|---|
| ship views | `_front`, `_three_quarter`, `_side`, `_back` |
| UI states | `_normal`, `_hover`, `_pressed`, `_disabled` |
| asteroid size bands | `_L1` `_L2` `_L3`, `_M1` `_M2` `_M3`, `_S1` `_S2` `_S3`, `_b1` to `_b6` |
| animation frames | `_f1`, `_f2`, ... (FX_SPEC section 3) |
| star layers | `_layer1`, `_layer2`, `_layer3` |
| sectors | `_1_bg` to `_7_bg` |

## 5. Derived suffixes are not part of a name

`_16`, `_48`, `_96`, `_192` and `@2x` are produced by **appending to a master name**, never
carried by a master. This is a hard constraint: `vajb-orbit/tools/derive_icon_tints.gd` derives
the tint set by appending, and `staging/phase_f/recut_quartet.py` cuts the quartet by appending.
A master whose name ends in a derived suffix breaks both.

Presentation rules, for reference: `_16` is micro-only, `_48` legacy, `_96` the default for new
consumers, `_192` detail headroom; `@2x` is a chrome plate cut at double resolution.

## 6. Five name shapes that must not survive

| Shape | Count | Rule |
|---|---|---|
| `<family>_sheet_<cols>x<rows>_<stamp>[__pNN]` | 188 | A placeholder. Renamed from evidence (section 7) or, where no evidence exists, from the render's own description. Never kept. |
| `<name>__<stamp>` where `<name>` exists | 13 | A second render colliding with a live name. Owner ruling: **the twin is dropped**, the plain name survives. The drop is listed in `_naming/assignments.tsv` and in the pull report, never silent. |
| `<name>__<stamp>` where `<name>` does not exist | 5 | The stamp is **spurious**: the plain name never existed, so the sheet is the only owner of that art. It takes the real panel name (`panel_modules_a`, `panel_modules_b`, `panel_modules_c`). Nothing is dropped. |
| the generator's filename, e.g. `grimdark-painted-sci-fi-semi-realistic__20260918-111044` | 32 | Renamed to what the file is. For a sheet, that is the panel name where a spec names one, otherwise the stem its own cut sprites share, so raw and cut crosscheck by construction. |
| a phase prefix, `f1_`, `p2_` | 5 | Folded into the family grammar unless a doc cites the exact string. |

A sixth shape was found and is separate: a **name that contradicts its own picture**, 9 files.
The rename does not silently fix these; each is listed with what the file actually shows, because
the fix may be to drop the render rather than name it.

## 7. Where a name may come from

A name is admissible only with one of these as its evidence. The `evidence` column of
`assignments.tsv` records which.

| Evidence | Scope |
|---|---|
| `icons-spec-7` | the twenty sanctioned flat-icon names |
| `icons-spec-8.1` | the twenty minerals and ingots, in tier order |
| `icons-spec-8.2` | `panel_modules_a/b/c`, nine cells each, in reading order |
| `icons-spec-8.3` | `panel_slots`, eight cells, reading order `engine power w s h c b u` |
| `icons-spec-8.4` | `panel_contracts` and `panel_service_glyphs` |
| `icons-spec-8.5` | `panel_faction_insignia`: `concord`, `meridian`, `choir` |
| `fx-spec-3` | the frame splits `fx_muzzle_flash_f1..f4`, `fx_explosion_f1..f5` |
| `catalog` | a name `ASSET_CATALOG.md` already files under that folder |
| `matches-<n>` | the pixels: `find_matches.py` scores this sheet against already-named art |
| `stamp-absent` | the stamp is spurious and no file holds the plain name |
| `shipped-manifest` | `_deleted_manifest.json` records this name shipping from a given sheet, so that sheet's cell owns it |
| `icons-spec-8` | the sheet is the panel master `ICONS_SPEC` section 8 names for the glyph set it produced |
| `owner` | only the owner can settle it |

**A name may never be invented.** No mineral, module, booster, contract, faction or service name
that appears in no brief is admissible, and no sanctioned-looking name may be put on art whose
panel no spec orders.

## 8. Collisions

Two siblings may never resolve to the same name.

1. A name is reserved if any file on disk holds it, or if `canonical.txt` lists it.
2. A second render of art that already has a name does **not** take the sanctioned name. It is
   either dropped or parked as an alternate. Measured duplicates are the 44 files in the
   `drop-pending` bucket, the strongest scoring 0.996 against the sanctioned art.
3. Where a sheet's panels would collide with a live set, the sheet is the duplicate, not the
   live set: the live set is what the game already reads.
4. Qualifiers resolve real siblings only, e.g. `ship_fighter`, `ship_fighter_concord`,
   `ship_fighter_meridian`, `ship_fighter_choir`.

## 9. The blast radius

A rename that ignores these leaves the game loading files that are not there.

| What | Where | Action |
|---|---|---|
| 201 literal `res://assets/...` paths | 34 files under `vajb-orbit/` | rewritten by exact match from the rename map |
| the one-level tree the rename introduced | `icons/<group>/`, `env/<group>/` | **found late (2026-09-21)**: the rename rewrote names but not the folder prefix, so code still said `res://assets/icons/icon_gear_48.png` and `res://assets/env/env_sector_1_bg.png` while the files sat one level down. `staging/cut/refile_asset_paths.py --check|--apply` resolves every `res://assets/...png` reference against the real tree and rewrites the ones that moved: 96 icon refs in 12 files, then 14 env refs in 6 files; it now reports 187 correct and none to move |
| path built by concatenation | `ui/station/launch_panel.gd`, `refinery_panel.gd`, `exchange_panel.gd`, `outfitting_panel.gd`, `ui/hud/hud.gd` build `res://assets/icons/<name>_48.png` | the base names in those tables are rewritten too |
| names cited by prose | `ASSET_CATALOG.md`, `ICONS_SPEC.md`, `SHIPS_SPEC.md`, `UI_CHROME_ASSETS_SPEC.md`, `ASSET_WIRING_HANDOFF.md`, `MAIN_MENU_V2.md`, `IMPLEMENTATION_PLAN.md`, `docs/CONTRACTS.md`, `asset-library/README.md`, `AGENTS.md` | amended in the same change |
| the catalog itself | `docs/design/ASSET_CATALOG.md` | regenerated, never hand-edited |

Dependency direction, per `AGENTS.md`: **docs first, then code, then tests.** The check is the
headless gate, `[SUMMARY] passed=53 failed=0`.

**`logo_vajb_orbit` and its geometry are frozen.** `MAIN_MENU_V2.md` wires
`AtlasTexture(logo_vajb_orbit, Rect2(44,707,1961,615))`, so the file name and that rectangle
survive any rename.

## 10. The rulings, and what happened

The owner settled all six on 2026-09-20. The rename was applied in three passes, each validated
before the next: **732 moves, 0 conflicts, and `validate_names.py --library` now reports that
every name the specs and the code require is present.**

| Ruling | Applied as |
|---|---|
| 1. The off-brief icon sheets are parked, not named | 17 sheets to `panel_alt_<subject>`, their 138 cells to `icon_alt_<subject>` under `icons/alt/`, each named from what its own render shows |
| 2. Second renders are dropped | 79 files moved to `_dropped/`; nothing deleted. `p2_contracts` scored 0.996 against `icon_contract` |
| 3. The sector plates extend the roster | `env_sector_8_bg` to `env_sector_11_bg`, sheet and cut both |
| 4. The F.1 ice moon wins its name | `f1_ice_moon` is now `env_body_ice_moon`; the older render is kept as `env_body_ice_moon_prev` |
| 5. The lying names and the odd sprites | 8 star-ship renders that defied their brief dropped; the ember ring, its alternate and the starfield (`env_stars_layer4`) kept and named; `fx_muzzle_flash_f1` to `_f4` adopted from the 4-frame sheet |
| 6. The bar caps | still one sprite: splitting it is a re-cut, not a rename, and remains open |

### Two corrections the crosscheck forced

`validate_names.py --library` caught both, and neither was visible in the plan:

1. **Four sanctioned glyphs were filed as alternates.** `icon_credits`, `icon_shield`,
   `icon_zoom_plus` and `icon_zoom_minus` had been moved to `icons/alt/` because their sheet
   looked off-brief. `_deleted_manifest.json` records all four shipping from that sheet's cells,
   so the sheet is the panel master, not an alternate. Restored, and the shipped manifest is now
   an evidence source in its own right.
2. **The panel masters had no file.** Renaming a sheet after its content lost the master names
   `ICONS_SPEC` section 8 gives it. `panel_minerals_ore`, `panel_slots`, `panel_modules_a/b/c` and
   ten more now name the sheets that produced those glyph sets, so a doc that says
   "panel_slots is the master of `icon_slot_*`" is true of this library too.

### What is still open

- **Splitting `ui_bar_caps`** into a left and a right sprite: a re-cut of one sheet.
- **Keying.** 484 sprites still carry their render backdrop. The 30 plates and the 18 FX files are
  excluded, and FX must never be keyed: they are RGB on void black for additive blending.
- **`cut_sheets.py` writes a flat `cut/`.** Re-cutting after this rename would need `apply_names.py`
  run again to re-file, which is the documented order: cut, then name, then file.
- **The three painted sheets** (`ui_insignia`, `env_pickup`, `env_prop`) deliberately keep
  content-based names rather than the `panel_*` names some docs use for their atlas regions,
  because their cells are painted sprites whose stems must stay aligned with the sheet.
