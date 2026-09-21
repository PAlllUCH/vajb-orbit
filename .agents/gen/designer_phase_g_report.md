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
| Phase G FX (FX_SPEC §7.2) | `assets/fx/fx_{bio_plasma,acid_burn,shield_shatter,smoke_plume,arc_spark,dust_streak,dash_charge,lock_channel}.png` | `_review/g_fx.jpg` |

Generation logs: `vajb-orbit/assets/ships/generation_log_phase_g.md` and
`vajb-orbit/assets/fx/generation_log_phase_g.md` (prompt, job id, alpha route per file).
All 20 files are imported in the editor (`.import` sidecars present, `filesystem_manage scan` run).

## What is staged and awaiting your approval (nothing overwritten)

The human rework sheets, each 4 views at 2K, tight-trimmed to the hull like the shipped set:

| Hull | Files staged | Review page |
|---|---|---|
| Vanguard (player) | `staging/phase_g/ships/ship_vanguard_{front,three_quarter,side,back}.png` | `_review/g_human_a.jpg` |
| Fighter | `…ship_fighter_…` | `_review/g_fighter.jpg` |
| Corvette | `…ship_corvette_…` | `_review/g_human_b.jpg` |
| Freighter | `…ship_freighter_…` | `_review/g_human_b.jpg` |
| Delver miner | `…ship_miner_…` | `_review/g_human_b.jpg` |

They are marked `review_only` in the run registry, so `ship_batch_g.py` refuses to copy them.
Approve (or reject) and I run `ship_batch_g.py ships --only …`-style shipping for them.

## Facts the next agent needs

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
- **Two overlaps to rule on**: `fx_shield_shatter` (FX_SPEC §7.2) covers the same event as the
  shipped `fx_shield_break.png`, which §7.1 says to reuse; and `fx_arc_spark` sits beside the
  shipped `fx_emp_arc.png`. The §7.2 table is what this lane generated against.
- **One palette deviation to look at**: `fx_arc_spark`'s arcs render rust-red rather than steel
  highlight `#565C63` with only a core flash (FX_SPEC §7.2 / §1.2). The ember core is sanctioned;
  the whole arc reading ember is not. Re-prompt on request.
- **Alien hull names are new.** `ship_{swarmer,sibelon,apex}_<view>` follows the shipped
  `<hull>_<view>` shape but no spec sanctions it yet — the naming pass should adopt or correct it.

## Spend

18 generation runs (8 FX + 10 ship sheets/singles) at the console's 10-credit = $0.05 / 2K basis
≈ **$0.90**, plus 10 recraft keying calls (1 credit each) ≈ **$0.05**. The script's printed
estimate (30 credits / $0.15) is the stale hint and `usage-ledger.jsonl` over-reports 3×.

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
