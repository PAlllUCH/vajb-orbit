# D7-A1 backup — A0's three console-panel bytes (UI_CHROME §12 Amendment 2 re-render)

Wave `D7`, worker `D7-A1`, task `.agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md` (Mockup
v6/v7 amendment) + `UI_CHROME_ASSETS_SPEC.md` §12 **Amendment 2**. Taken **before** the first
A1 write, 2026-09-24.

## What this is

A0's shipped bytes for the three console panels, plus the provenance panels and the whole
staging sources they were cut from, so the A1 re-render is fully reversible. `MANIFEST.md5`
holds every file's md5.

| File | A0 md5 | Notes |
|---|---|---|
| `ui/ui_cockpit_panel.png` | `184674c3` | A0's *well-bearing* cockpit plate (§12 run 1) |
| `ui/ui_armory_console.png` | `f2b3db46` | A0's well-bearing console (§12 run 3) |
| `ui/ui_status_panel.png` | `2f8e315d` | A0's well-bearing status plate (§12 run 5) |
| `icons/panel_cockpit.png` | `e1c59630` | provenance render, A0's cockpit run |
| `icons/panel_armory.png` | `b8f017a2` | provenance render, A0's armory console run |
| `icons/panel_status.png` | `51a0ece6` | provenance render, A0's status run |
| `renders/panel_cockpit.png` | `e1c59630` | the opaque white render A0 shipped from |
| `renders/panel_armory_console.png` | `b8f017a2` | the opaque white render A0 shipped from |
| `renders/panel_status.png` | `51a0ece6` | the opaque white render A0 shipped from |
| `masters/ui_cockpit_panel.png` | `184674c3` | A0's fitted master (contain) |
| `masters/ui_armory_console.png` | `f2b3db46` | A0's fitted master (contain) |
| `masters/ui_status_panel.png` | `2f8e315d` | A0's fitted master (contain) |
| `cuts/ui_cockpit_panel.png` | `0b489bfa` | A0's staging cut (keyed, trimmed, centred) 2141x1192 |
| `cuts/ui_armory_console.png` | `449cf660` | A0's staging cut 1334x2100 |
| `cuts/ui_status_panel.png` | `bb02168e` | A0's staging cut 2112x1318 |
| `generation_log_d7.md.a0` | — | A0's generation log (before A1 rewrote it for six rows) |

`ship_report_d7.json` was rewritten by the A1 ship step (it now carries all six masters, the three
unchanged ones byte-identical); A0's three rows for the replaced panels are in `D7-A0_report.md`'s
own table.

## Reversal (one command per file)

```
cp -p staging/phase_g/ui/_a1_backup/ui/*.png            vajb-orbit/assets/ui/
cp -p staging/phase_g/ui/_a1_backup/icons/*.png         vajb-orbit/assets/icons/
cp -p staging/phase_g/ui/_a1_backup/renders/*.png       staging/phase_g/ui/
cp -p staging/phase_g/ui/_a1_backup/cuts/*.png          staging/phase_g/ui/
cp -p staging/phase_g/ui/_a1_backup/masters/*.png       staging/phase_g/ui/_masters/
cp -p staging/phase_g/ui/_a1_backup/generation_log_d7.md.a0 vajb-orbit/assets/ui/generation_log_d7.md
```

then reimport the six changed assets in the editor (`filesystem_manage reimport`) so the import
cache matches the restored bytes. A0's render run folders
(`staging/phase_g/ui/20260924-102629`, `-102746`, `-102913`) were never overwritten and stay as
the original provenance; so do A0's `_cells/<run>/` keyed crops.
