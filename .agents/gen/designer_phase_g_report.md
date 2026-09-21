# Designer report — Phase G lane (2026-09-21, night run)

Work order: `.agents/gen/dispatch_designer.md`. Driver: `staging/phase_g/wave_g.py`
(registry of every run), keying: `staging/phase_g/key_new.py`, shipping:
`staging/phase_g/ship_batch_g.py`, review pages: `staging/phase_g/build_review.py`.
Model: **`gpt-image-2-5-flare-text-to-image` (`flare`)**, 2K, aspect 1:1, style block as the prompt
preamble (STYLE_BIBLE §8: the block goes first, and `--style-file` appends it after the subject).

## What shipped into the game (no owner gate needed — all new file names)

| Batch | Files | Review page |
|---|---|---|
| Alien hulls, **Swarmer** (dispatch priority: slice-2 W3 gates its visual pass on it) | `assets/ships/ship_swarmer_{front,three_quarter,side,back}.png` | `staging/phase_g/_review/g_ships_ship_swarmer.jpg` |
| Alien hulls, Sibelon | `assets/ships/ship_sibelon_{front,three_quarter,side,back}.png` | `_review/g_alien2.jpg` |
| Alien hulls, Apex | `assets/ships/ship_apex_{front,three_quarter,side,back}.png` | `_review/g_alien2.jpg` |
| **Human hull rework, core five** (owner-approved 2026-09-21: "look good, go ahead") | `assets/ships/ship_{vanguard,fighter,corvette,freighter,miner}_{front,three_quarter,side,back}.png` — replaces the old art | `_review/g_human_a/b.jpg`, `g_fighter.jpg` |
| **Human hull rework, the rest of the roster** (ASSET_EXPANSION_SPEC §3 classes 7–15) | `assets/ships/ship_{interceptor,gunship,destroyer,drone_swarm,trader,patrol,bomber,mine_layer}_{front,three_quarter,side,back}.png` and `ship_turret_platform.png` (radially symmetric, one centred render) | `_review/g_roster.jpg`, `g_turret.jpg` |
| Phase G FX (FX_SPEC §7.2) | `assets/fx/fx_{bio_plasma,acid_burn,smoke_plume,arc_spark,dust_streak,dash_charge,lock_channel}.png` — 7 files | `_review/g_fx.jpg` |
| Phase G FX, retired before shipping | `fx_shield_shatter` — the owner ruled 2026-09-21 that it duplicates the shipped `fx_shield_break.png` (which FX_SPEC §7.1 already names for that event). Generated, reviewed, dropped from the project and from the log; the render stays in `staging/phase_g/fx/` as provenance, and FX_SPEC §7.2 now carries the ruling | - |

65 files shipped in total (the family log `assets/ships/generation_log_phase_g.md` has a row per
file), all imported in the editor.

**The rework now covers 14 human hulls of the roster** (the five core classes plus classes 7–15 of
`ASSET_EXPANSION_SPEC.md` §3). Still on the old art, untouched by this lane: the MMO/faction
liveries (`ship_*_mmo`, `_concord`, `_meridian`, `_choir`), the six boss hulls and
`ship_vanguard_damaged`. Those are i2i re-liveries rather than new renders, and the naming
overhaul the owner has planned lands first.

## Awaiting the naming overhaul

Nothing is left unshipped: the five core hulls were approved ("look good, go ahead"), and every
other sheet this lane generated is additive art that replaced its own old file. What remains is
the owner's planned naming overhaul of the hull set (the MMO/faction liveries and the six boss
hulls still carry the previous art, and those are i2i re-liveries rather than fresh renders).

## Facts the next agent needs

- **A repaired sheet cuts three cells, and `cells` is the authority.** Two more defects the owner
  caught on 2026-09-21, after the panel-order fix:
  1. **The model draws the front twice.** On a 2×2 sheet the bottom-right cell is often a *second
     front view* and no rear exists at all — measured by silhouette IoU against the front cut:
     `ship_miner_back` **0.91**, `ship_sibelon_back` **0.83** (the swarmer and fighter sheets had
     the same flaw and were already repaired that way). A legal front/rear pair of a boxy hull
     scores 0.74–0.78, so 0.80 is the line, and `refit_panels.py` now reports any pair above it
     instead of shipping (it runs the check on the cuts it just wrote).
  2. **A stale `cuts` list can plan a file twice.** `ship_batch_g.py` showed
     `ship_sibelon_back.png` twice — once from the sheet's old four-name list, once from its own
     `*_back_single` run. `cuts` is now always derived from `cells`, so a dropped view cannot come
     back.
  Both hulls now have four distinct views (`miner` front/side 0.77, `sibelon` front/side 0.76, all
  pairs under the line) and the rear of each is its own run: `ship_sibelon_back_single`,
  `ship_miner_back_single`. The alien set was re-shipped and reimported.
- **Panel order is law, and the first pass got it wrong.** The owner caught two defects on
  2026-09-21, both now fixed and both measurable:
  1. **Panel-level keying eats objects.** `recraft/remove-background` on a whole 2×2 render picks
     the strongest subject and trims the rest — on `ship_apex_sheet` it deleted the bottom 299 px
     of the bottom-right hull (ink box height 933 px, keyed alpha height 634 px, alpha fill 17 %
     against 50-70 % on the other cells), so `ship_apex_back` shipped without its tail.
  2. **Objects cross the quadrant midlines.** The apex and sibelon sheets each hold a hull whose
     ink starts left of x = 1024 and runs to x = 1121, so the 2×2 grid cut truncated it: that is
     the clipped `ship_apex_side`.
  The repair is `staging/phase_g/panels.py` (find the objects, group the ink into the four cells
  **by pixel mass inside a quadrant**, crop each object with its neighbours blacked out) plus
  `staging/phase_g/refit_panels.py <run-id>`, which keys each crop on its own and **verifies the
  keyed alpha box against the ink box**, restoring an ember engine flame the matte trimmed as one
  connected component when the box comes up short. All eight sheets were rebuilt this way and all
  twelve alien hulls re-shipped: every cell now verifies (e.g. `ship_apex_back` ink 473×933 →
  alpha 475×935; `ship_apex_side` ink 1090×373 → alpha 1092×373; the vanguard's two cells needed
  the flame restore, 8348 and 11525 px).
- **`flare` never returns native alpha on this project.** 15 of 15 ship renders came back opaque
  RGB, exactly as STYLE_BIBLE §9 predicts (the block names a void background and wins). The route
  is: `--transparent` → if opaque, `key_new.py <file>` (recraft/remove-background, 1 credit,
  cached by source md5 under `_keying/recraft/`), then `wave_g.py <run> --post-only` to cut.
- **`key_new.py` caches by content, not by name.** The generator's slug is built from the prompt's
  first words, which are the shared style block, so four different hulls came back as
  `grimdark-painted-sci-fi-semi-realistic-1.png`. The first version of the script keyed its cache
  and its `submitted` map by file name and silently collapsed four paid submissions onto one key
  (4 credits ≈ $0.02 lost, no art). Fixed: `cache_key()` = stem + md5 prefix.
- **The 2×2 sheet's cell order is a prompt request, not a guarantee.** The swarmer sheet came back
  front (top-left), three-quarter (top-right), side (bottom-left), **front again** (bottom-right).
  Each sheet's cell plan is therefore read off the render and recorded as `cells=` in `wave_g.py`
  (index, name, rotate). A missing view is generated as its own single run (`ship_swarmer_back_single`).
  The swarmer's front also rendered bow-down and is rotated 180° to the SHIPS_SPEC §4.1 convention.
- **Trim convention:** tight to the alpha box plus a 4% pad, not a square canvas — the shipped set
  is trimmed the same way and the game draws these centred on a node. `keep_main()` drops stray
  fragments before trimming: a cell boundary can carry a sliver of its neighbour's tail, and a
  sliver survives a trim and ships as if it were part of the hull.
- **`fx_shield_shatter` is retired — the shipped `fx_shield_break.png` is the asset** (owner
  ruling 2026-09-21). The sheet was generated, reviewed and dropped: out of `assets/fx/`, out of
  the family log, and its FX_SPEC §7.2 row now records the ruling instead of ordering a render.
  `RUNS["fx_shield_shatter"]["ships"] = False` keeps every downstream tool from copying it again,
  and `build_review.py` reads that flag so the review page matches what shipped (7 FX, not 8).
- **`fx_arc_spark` was regenerated to the documentation** (owner ruling 2026-09-21): the first
  render's arcs were rust-red end to end, while FX_SPEC §7.2 wants a steel highlight `#565C63` arc
  with only a brightened-ember core flash. The new prompt says exactly that and the second render
  is pale steel with a hot core. Reshipped with `--replace` and reimported.
- **`fx_arc_spark` sits beside the shipped `fx_emp_arc.png`** (both are arcs, different events:
  hull damage versus an EMP burst). Left as generated; the §7.2 table is the inventory.
- **Alien hull names follow the owner's ship law** (restated 2026-09-21, now written into
  `docs/design/ASSET_NAMING_SPEC.md` section 1): `ship_<hull>[_<qualifier>][_<angle>]`, e.g.
  `ship_fighter_front.png` or `ship_fighter_concord_back.png`, where the angle is always one of
  `front`, `three_quarter`, `side`, `back` and is always last. `ship_swarmer_*`, `ship_sibelon_*`
  and `ship_apex_*` obey it, so they are legal names rather than provisional ones. A reworked hull
  replaces its own file: no `_v2`, no version markers.

## Spend

33 generation runs at the console's 10-credit = gosh.05 / 2K basis ≈ **.65**, plus **83 keyed
files** through recraft/remove-background (1 credit each) ≈ **gosh.42**. The script's printed
estimate (30 credits / gosh.15) is the stale hint and  over-reports 3×.

## Same night, outside this lane

- **Headless gate: `passed=77 failed=1`**, and the one failure is not this lane's:
  `test_p1_profile.gd.test_v2_round_trip_for_every_key` ("writes always persist v2") broke when a
  concurrent slice-0 worker raised `SAVE_VERSION` to 3 in `vajb-orbit/autoload/player_profile.gd`
  at 01:48; the test still asserts 2. It passed 78/0 before that edit.
- Fixed the asset-path blast radius the naming pass left behind — twice, because the rename
  rewrote names but not the folder prefix it introduced: `staging/cut/refile_asset_paths.py`
  re-pointed 96 icon references in 12 files at their group folders (`icons/mineral/`, `icons/hud/`,
  …) and then 14 env references in 6 files (`env/backdrop/`, `env/tile/`, `env/poi/`,
  `env/pickup/`). The scanner resolves every `res://assets/...png` against the real tree; it now
  reports 187 correct, 0 to move (the 5 hits it cannot resolve are `%s` templates).
  The tint set stays flat by design (`TINT_DIR + name.get_file()`), and
  `tools/derive_icon_tints.gd` now recurses into the group folders — 1080 stencils regenerated.
- `asset-library`: `raw/`, `cut/` and `_dropped/` are zipped into `_archive/` and the loose copies
  are gone (1.26 GB of PNG; the zips are the same size, so the gain is a tidy tree, not disk);
  `staging/cut/archive.py --restore raw|cut` puts them back in seconds.
  `build_library.py` refuses to index an emptied tree rather than overwrite the index.
- Deleted the night's trash: 33 `desktop.ini` files the mount scattered into the project's asset
  folders, the run logs and scratch images in `staging/cut/`, and the superseded
  `key_check_local_p*.jpg` pages.
