# asset-library

**Search here first for any art.** This folder is the home of every generated asset and is
not part of the Godot project — nothing here is imported by the engine. `vajb-orbit/assets/`
holds only what a feature has actually pulled in.

## Where things are

| Path | What it holds | State |
|---|---|---|
| `<family>/<name>__raw.png` | The untouched 2048px render exactly as the API returned it | 163 sheets, immutable |
| `<family>/<name>__keyed.png` | The same sheet after the old v1 matte, kept as a record | 74 sheets, reference only |
| `_cuts/<family>/<sprite>.png` | **The repaired, ready-to-use sprites** | 314 files: ships 92, env 66, ui 27, icons 129 |
| `_originals_manifest.json` | Provenance for every run: job id, model, exact prompt, shipped assets, md5, `superseded_by` | — |
| `_repair_report.json` | Per-sprite repair record: background, mode, pixels restored, residual review list | — |
| `_deleted_manifest.json` | What the prune removed, and the raw sheet each sprite derives from | — |

`<name>` is, in order of reliability: the shipped asset the run produced, the run key in the
owning wave driver's `RUNS` table, or the generator's own filename slug. Where a name repeats
(a regeneration), the run stamp is appended, e.g. `ui_panel_frame__20260918-133002__raw.png`.

Browse without opening files: `staging/review/_preview/originals_o1_<family>.jpg`.

## Pulling sprites into the project

Sprites are not restored in bulk. Copy what the work needs:

```
py -3.14 staging/assetpipe/pull.py --status                    what exists where
py -3.14 staging/assetpipe/pull.py --list env                  what a family holds
py -3.14 staging/assetpipe/pull.py ships --pattern "ship_bomber_*"
py -3.14 staging/assetpipe/pull.py ui --all
py -3.14 staging/assetpipe/pull.py icons icon_credits.png icon_hull.png
```

Each pulled sprite gets a `.job.json` recording its run (job id, model, prompt, raw sheet),
so provenance survives the copy. Then reimport: `filesystem_manage reimport` in the editor,
or a headless `--editor --quit` with the editor closed.

## The alpha history, in one paragraph

The v1 matte (`staging/phase_d/reprocess.py`) keyed every pixel within a distance of 16 of
the estimated background. Measured against the raw renders, **51–76% of the area it keyed out
was rendered artwork, not background** — a hull's shadowed plating sits inside that distance —
so it punched blotches through every ship, prop and icon. Because v1 only ever wrote the alpha
channel, the RGB under those transparent pixels still held the full render, so
`staging/assetpipe/repair.py` rebuilt each sprite's alpha from its own preserved RGB with
threshold 8, leaving geometry and filenames untouched. Contract:
`docs/design/ASSET_PIPELINE_V2.md`.

## Derived sets are not repaired, they are regenerated

A quartet, a tint or a chrome `@2x` has had its transparent RGB overwritten (a quartet's
transparent pixels are 56–89% pure black, a tint's are uniform white), so there is no render
left to rebuild from. Regenerate them from the repaired parent:

| Set | Tool |
|---|---|
| `*_{16,48,96,192}` quartets | `staging/phase_f/recut_quartet.py` (`--fit contain` is the law) |
| `icons/tint/` | `vajb-orbit/tools/derive_icon_tints.gd` (headless `--script`) |
| chrome `@2x` | `staging/phase_f/chrome_2x.py` |
| then | `staging/phase_f/apply_import_settings.py`, reimport, `staging/phase_d/build_catalog.py` |

## Other contents

- `.previews/` — assetmcp preview cache.

`ASSET_MANIFEST.json` and `CREDITS.md` (assetmcp's record of sourced CC0 assets) are not
present right now; regenerate them with assetmcp if sourced assets are re-introduced.
