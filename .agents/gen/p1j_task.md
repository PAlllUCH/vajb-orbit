# P1j task — REPAIRS station panel (STATION_HUB amendment 5.9, doc 01 §6)

Worker: coder. Wave: P1 economy core, panels. Deliverables, exactly two new
files:

1. `vajb-orbit/ui/station/repairs_panel.tscn`
2. `vajb-orbit/ui/station/repairs_panel.gd`

Do not touch any other file (the shell already lists your panel in
`MODULE_FILES`; it loads it by name). No MCP tools. Do not run the editor. Do
not edit `addons/`, `project.godot`, docs, the theme, or any other script or
scene.

## Read first

- `docs/design/STATION_HUB.md` — §3.1 (measured grid), §5.9 (your spec),
  §5.6 (refusal path), §12.3/§12.4.
- `docs/gameplay/01_economy_core.md` — §6 (fee, example, 90 % exemption),
  §7 (order + log).
- `vajb-orbit/ui/station/launch_panel.tscn` + `.gd` — the brief value rows
  and the 360 px deck control your panel copies; also the status-strip and
  focus patterns.
- `vajb-orbit/ui/station/outfitting_panel.gd` — helpers and tween
  bookkeeping.
- `vajb-orbit/ui/screens/station.gd` — the panel duck-typed contract
  (`status_requested`, `refresh_profile`, `focus_primary`, optional
  `disarm`).
- `vajb-orbit/game/repairs.gd` — read-only contract: `fee(profile, ship_id)`,
  `repair(profile, ship_id)`, `is_repairable(profile, ship_id)`.
- `vajb-orbit/game/station_catalog.gd` — `ship(id)` maxima.

## Panel contract

- Root `VBoxContainer` named `Repairs`, separation 12, no theme baked. Unique
  names per §5.9: `PaneHeader` (`REPAIRS`, subtitle `HULL AND SHIELD`),
  `DamageReportBox`, `RepairBox`, `PaneFooter`.
- Body: `DamageReportBox` (min 560) | `RepairBox` (min 360) in a HBox.
- `DamageReportBox` value rows (value column 220 right aligned):
  `ACTIVE HULL` (catalogue name), `HULL` `"200 / 1000"`, `SHIELD`
  `"300 / 600"`, `MISSING` `"800 HULL · 300 SHIELD"`, `FEE` `"500 CR"`
  (`accent_danger` when above the balance). Every number comes from
  `Repairs.fee`, `PlayerProfile.vitals_of(active_ship)` and
  `StationCatalog.ship(active_ship)`; the panel computes no fee itself.
- `RepairBox`: `REPAIR` button (88 px) + caption `OPTIONAL · A DAMAGED HULL
  LAUNCHES FROM THE LAUNCH DECK`. States per §5.9: no vitals record ->
  `NOT REPORTED` rows + disabled button + caption `UNDOCK AND DOCK TO FILE A
  DAMAGE REPORT`; everything at maximum -> `ALL SYSTEMS NOMINAL`, disabled;
  the 90 % shield exemption -> button enabled, strip on focus
  `SHIELD TOP-UP · NO FEE`, press restores for 0 CR.
- Action: `REPAIR` -> `Repairs.repair(profile, active_ship)`. Success ->
  strip `REPAIRED · <fee> CR · ALL SYSTEMS NOMINAL`, credits animate/refresh,
  report rows show maxima. Refusal -> §5.6 (`insufficient_credits` wording)
  or the `no_damage`/`no_damage_report` captions from §5.9.
- Refresh: `refresh_profile(key)` reacts to `&"credits"` (fee colour) and
  `&"ships"` (active ship switch). Vitals mutations are silent by contract
  (17 §3), so the panel refetches after its own repairs and on `ui_cancel`
  disarm — read the active ship fresh every rebuild, never cache it.
- `focus_primary()`: the `REPAIR` button when enabled, else the first report
  row's label focusable? (labels are not focusable: fall back to the rail —
  the shell handles that when nothing inside takes focus). Return nothing.
- `disarm()`: not needed; omit (optional contract).
- Audio: CONFIRM on a successful repair, DENIED on refusal
  (`AudioManager.play_ui`), matching the other panels. No new cues.

## Probe (required)

Probe scene `res://tools/_probe_p1j.tscn` + `_probe_p1j.gd` that boots
`res://ui/screens/station.tscn` headless:

1. Redirect `PlayerProfile.save_path` to `user://p1j_probe_profile.cfg` and
   `EconomyLog.log_path` to `user://p1j_probe_log.txt` **before** any
   mutation. Switch to REPAIRS by emitting `pressed` on `RepairsEntry`.
2. No record case: report rows read `NOT REPORTED`, button disabled.
3. `set_vitals(&"ship_vanguard", 200, 300)` -> FEE row `"500 CR"`, button
   enabled; press `REPAIR`: credits drop by 500, vitals become
   `{hull: 1000, shield: 600}`, strip shows the success text, one REPAIR log
   line.
4. Full case: all at maximum -> `ALL SYSTEMS NOMINAL`, button disabled.
5. Exemption case: `set_vitals(&"ship_vanguard", 1000, 570)` -> fee 0, button
   enabled, press -> shield 600, zero credits spent.
6. Insufficient credits: `set_vitals` damaged + set a low balance (spend down
   to below the fee), press -> refusal strip, vitals unchanged.
7. Print `PROBE OK`; quit. Delete probe files, their `.uid` sidecars, and
   `user://p1j_probe_*` before you finish. **Never** touch
   `user://profile.cfg`.

Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1j.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, no `SCRIPT ERROR`. Do NOT
use `--check-only --script`.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — no `$` in PowerShell.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1j_report.md`: deliverables, commands + observed output,
every probe assertion with its result, measured geometry evidence, and
anything a reviewer should look at. Under 110 lines.
