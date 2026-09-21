# Designer generation backlog — 2026-09-21

Compiled for the graphics lane while the FX alpha redo runs. Sources:
`LOW_BACKLOG.md` (L34/L48/L52/L57/L58/L65), `ui_chrome_regression.md` (R8,
B2-1/B2-2), `WAVEBOARD.md` §Queued item 6, `designer_slots_report.md` /
`designer_chrome_recovery_report.md`, `docs/gameplay/03_components.md`,
`docs/gameplay/10_ship_acquisition.md` §3, `docs/design/FX_SPEC.md` §0/§0.1/§1.8,
`ASSET_CATALOG.md`. Every "shipped" claim was checked against
`vajb-orbit/assets/` on this date.

**Update 2026-09-21 (FX re-cut pass, executed):** items 0, 3, 4 and 9 are done, and §4's
four-frame instruction was carried out in the same pass. Evidence:
`staging/cut/_fx_review/fx_deploy_all.jpg` (the four alpha files, route per file),
`staging/cut/_fx_review/fx_new_all.jpg` (the regenerated mining/bolt sheets and the mine),
`staging/cut/_fx_ship_report.json` (the files that moved), numbers from
`staging/cut/qc_fx_alpha.py`, and the eyes of `staging/cut/verify_fx_alpha.py`
(deepseek-chat, majority of three reads). Full write-up: `.agents/gen/designer_fx_recut_report.md`.

## 0. The FX alpha redo — DONE

The coder's need was real but **narrow**: only the effects that render *non-additively* broke as
RGB-on-void-black. Everything else is correct as shipped and was not regenerated.

| Needs alpha (4) | Route that shipped | Why |
|---|---|---|
| `fx_smoke_plume.png` | `recraft/remove-background` | non-emissive `#232629` smoke drawn as particles: opacity follows density, not brightness |
| `fx_acid_burn.png` | `recraft/remove-background` | FX_SPEC's only `MIX`-blend effect (a stain, not light) |
| `fx_dust_streak.png` | `recraft/remove-background` | §7.1: "never additively blown" — camera-space, low alpha |
| `fx_hull_critical_vignette.png` | `staging/cut/key_luminance.py` | §1.8's overlay wants its background discarded and its centre transparent; the paid matte kept 99.7% of the frame and left the centre black (measured 4 179 224 of 4 194 304 px opaque) |

Both routes were run for all four and compared (`fx_alpha_all.jpg`): the matte won the smoke, the
acid and the streak (deepseek read each at 3-of-3 pass), the luminance key won the vignette. The
same pass added `fx_mine.png`, which is also alpha (a solid object cannot be drawn additively).

**Doc ticks done with it:** FX_SPEC §0.1 carries the dated carve-out; `AGENTS.md`'s "never key FX"
lines carry the same exception and point at the two QC tools.

## 1. Re-cuts and fixes owed (existing masters)

| # | Item | Status |
|---|---|---|
| 1 | `_48` cuts of `icon_zoom_plus` / `icon_zoom_minus` + import settings | **owed** — HUD renders the `_96` into 28 px boxes = 3.43 texels/px, no mips (`ui_chrome_regression.md`, `MASTER_REPORT.md`) |
| 2 | Tint-stencil import-settings pass (1 080 files, mipmaps on / lossless / 3D off) | **owed** — lost in the 00:17 re-cut; `apply_import_settings.py --only` (T1) scopes it |
| 3 | `fx_laser_bolt` + slug re-cut fatter to 4:1 / 6:1 (L57) | **done** — `fx_laser_bolt_v2.png`; frames measure 3.2:1 and 6.4:1 against v1's 16.4:1 and 9.4:1, and `fx_laser_bolt_v3.png` supersedes it as the four-frame sheet |
| 4 | `fx_mining_beam` chip-spark sheet to the spec's 4 frames (L52/L65) | **done** — `fx_mining_beam_v2.png`, four cells resolving 4 of 4, cut to `fx_mining_beam_f1..f4.png` (v1's fourth cell was grain) |
| 5 | `ship_vanguard_damaged` — on disk, zero consumers | **owed** — decide: wire it into the damage states, commission the missing damage tiers, or park it |

## 2. Decisions owed (generation may follow the pick)

| # | Decision | Gate |
|---|---|---|
| 6 | **B2-1 hover direction** (flicker / directional glow / ember on the tick band) | owner picks after a standalone 1080p/1440p look; may add a soft-halo art pass (`UI_SPEC` §2.2) |
| 7 | **Station panel backplates** — evaluate the asset-library background plates | owner-endorsed direction; review sheet owner-gated |
| 8 | **The four `ui_slot_inventory_*` plates** — ship, re-cut, or drop | L34: 882×870 plates with no consumer |
| 9 | **A dedicated mine sprite** (L58) | **done** — `fx_mine.png` keyed and centred (1784², centre offset 0.0); FX_SPEC §7.2 carries its row and the `fx_ember_pulse` crop is superseded |
| 10 | **4K 2× backdrop cuts** (one per family) | gated on B2-2: is the display target 1080p-only or 1440p/4K? |
| 11 | **Swap the two v1 masters** (`fx_laser_bolt.png`, `fx_mining_beam.png`) | routed to the coder lane 2026-09-21: the v2/v3 art is better, but `projectile.gd`'s `SHEETS`/`FEEDBACK` region tables were measured against v1, so the swap is a wiring change first |

## 3. New generation for upcoming waves (not in any queue yet)

| # | Item | Why |
|---|---|---|
| 12 | **18 component icons** (`comp_scrap_1..3`, `comp_mech_1..3`, `comp_weap_1..3`, `comp_ore_1..3`, `comp_elec_1..3`, `comp_pow_1..3` per `03_components.md` §3) | `10_ship_acquisition.md` §3's shipyard recipes and the crafting phase (P5) consume them; **no icon family exists** (`assets/icons/` has no component folder). Needed the moment the SHIPYARD build path shows materials |
| 13 | **Mine-drop audio cue** | L48: the deployable family has no S-row and no asset — an owner ruling plus one CC0 cue (audio lane, not art) |
| 14 | Optional, owner-decision: faction station liveries (P4 factions), extra damage-state hulls beyond the Vanguard | not specced anywhere; listed so they stay conscious deferrals |

## 4. Frames for every FX — DONE (owner instruction 2026-09-21)

"i want all fx to have at least 4 frames like explosion." Every FX the game draws now has four or
more frames as separate PNGs: 22 cycle sheets were generated on `gpt-image-2-5-flare-text-to-image`
(2K, 1:1), cut by `staging/cut/split_fx.py` to `fx_<name>_f1..f4.png` and centred on a shared
per-sheet canvas. The seven sheets that already had frames (explosion 5, muzzle flash 4, mining
chip sparks 4, missile trail 4, shield break 4, arc 4, secondary explosion 4) stay as they are;
`fx_laser_bolt` gained two more (light bright/dimming, medium bright/dimming). Five of the cycle
sheets render non-additively and were keyed frame by frame (`fx_acid_burn`, `fx_smoke_plume`,
`fx_dust_streak`, `fx_hull_critical_vignette`, `fx_mine`). FX_SPEC §7.2 records the ruling and
names the rows it supersedes.

## 5. Already shipped — do not re-brief

Checked on disk 2026-09-21: the six boss hulls (`ship_boss_{boneyard,leviathan,maw,pyre,spire,thorn}`),
the MMO liveries, the three faction fighter liveries, the alien family hulls
(swarmer/sibelon/apex), the miner hull (doc 08 §4's gap is closed), the Phase G FX set, all 27
module icons, the 8 slot glyphs, the 7 sector backdrops, the POI/prop/pickup sets, the
insignia/contract/service glyphs and the cargo tint table. `WAVEBOARD.md` §Queued item 6's
"Later: MMO/faction liveries, six boss hulls, `ship_vanguard_damaged`" line is stale on the first
two and is covered by item 5 above for the third.

**Nothing in this backlog gates slice 2.5 (in flight) or wave P2-A (queued)** — both are
art-complete.
