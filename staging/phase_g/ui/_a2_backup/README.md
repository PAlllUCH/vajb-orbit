# D7-A2 backup — the A1 armory console plate (UI_SPEC §3.10 Amendment 2 re-render)

Wave `D7`, worker `D7-A2`, task `.agents/gen/slices/D7-cockpit-rework/D7_prompts.md`'s D7-A2 block
+ `D7_BRIEF.md`; `docs/design/UI_SPEC.md` §3.10 **Amendment 2** (the D7-R1 MED-1 ruling) and
`docs/design/UI_CHROME_ASSETS_SPEC.md` §12 **Amendment 2**. Taken **before** the first A2 write,
2026-09-24.

## What this is

A1's shipped console plate and the whole staging chain it was cut from, so the A2 re-render (the
ruled 872×956 canvas → 1744×1912 master, replacing A1's retired 872×908 → 1744×1816) is fully
reversible. `MANIFEST.md5` holds every file's md5.

| File | A1 md5 | Notes |
|---|---|---|
| `ui/ui_armory_console.png` | `a8382b40` | A1's flat plate on the **retired** box 1744×1816 |
| `icons/panel_armory.png` | `aa2fc8df` | A1's provenance render (the A1 flat console run) |
| `renders/panel_armory_console_flat.png` | `aa2fc8df` | the A1 flat render the cut came from |
| `cuts/ui_armory_console.png` | `eedc6aa1` | A1's staging cut (keyed, trimmed, centred) 1987×1991 |
| `masters/ui_armory_console.png` | `a8382b40` | A1's fitted master (contain, 1744×1816) |
| `generation_log_d7.md.a1` | — | A1's generation log (before A2 rewrote it) |
| `ship_report_d7.json.a1` | — | A1's ship report |

A1's render run folders (`staging/phase_g/ui/20260924-110240`, `-110550`, `-110922`) were never
overwritten and stay as the original provenance; so do its `_cells/<run>/` keyed crops.

## Reversal (one command per file)

```
cp -p staging/phase_g/ui/_a2_backup/ui/*.png       vajb-orbit/assets/ui/
cp -p staging/phase_g/ui/_a2_backup/icons/*.png    vajb-orbit/assets/icons/
cp -p staging/phase_g/ui/_a2_backup/renders/*.png  staging/phase_g/ui/
cp -p staging/phase_g/ui/_a2_backup/cuts/*.png     staging/phase_g/ui/
cp -p staging/phase_g/ui/_a2_backup/masters/*.png  staging/phase_g/ui/_masters/
cp -p staging/phase_g/ui/_a2_backup/generation_log_d7.md.a1  vajb-orbit/assets/ui/generation_log_d7.md
cp -p staging/phase_g/ui/_a2_backup/ship_report_d7.json.a1   staging/phase_g/ui/ship_report_d7.json
```

then reimport the two changed assets (`filesystem_manage scan` + `reimport`, or a headless
`--import` with the editor closed) so the import cache matches the restored bytes, and revert the
staging constants (`wave_g.UI_D7_LOGICAL/UI_D7_MASTER`, `qc_d7.BOXES`, `qc_d7_a1.WELL_UNIONS`,
`reconcile_d7.TABLE`) to the retired 872×908 / 1744×1816 pair.
