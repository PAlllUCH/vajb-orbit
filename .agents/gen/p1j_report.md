# P1j report — REPAIRS station panel (STATION_HUB §5.9, 01 §6/§7)

Deliverables, exactly two new files, nothing else touched:

1. `vajb-orbit/ui/station/repairs_panel.tscn` — 119 lines: root `VBoxContainer` `Repairs`
   (separation 12, no theme baked) with `PaneHeader` (`REPAIRS` / `HULL AND SHIELD`
   / `PanelTag`), `RepairsBody` (`DamageReportBox` min 560 | expanding spacer |
   `RepairBox` min 360), and `PaneFooter`. The four §5.9 unique names resolve
   (`PaneHeader`, `DamageReportBox`, `RepairBox`, `PaneFooter`), pre-flagged
   `unique_name_in_owner`.
2. `vajb-orbit/ui/station/repairs_panel.gd` — 305 lines, `extends VBoxContainer`.
   Contract surface: `signal status_requested`, `refresh_profile(key)`,
   `focus_primary()`. No `disarm()` (the brief marks it optional and this panel has no
   armed beat). The shell already lists `repairs` in `MODULE_FILES`, so it loads by name.

## Commands and observed output

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1j.tscn --quit-after 300
```

EXIT=0; stdout carries `PROBE OK` and `[P1j] 76 passed, 0 failed`; 0 `FAIL`, 0 `ABORT`,
and no `SCRIPT ERROR`, `ERROR` or `WARNING` line carries a `repairs_panel` path or frame
(two sibling-panel `SCRIPT ERROR` groups do appear — reviewer note 1). The run ends with
`WARNING: 12 ObjectDB instances were leaked at exit` / `ERROR: 6 resources still in use at
exit`, the engine's exit-time accounting for the probe scene it is tearing down; the exit
code is still 0. No `--check-only --script` was used.

Probe plumbing: `EconomyLog.log_path = user://p1j_probe_log.txt` and
`PlayerProfile.save_path = user://p1j_probe_profile.cfg` are set before any mutation,
then `PlayerProfile.reset_to_defaults()` pins the start state to credits 10000, active
`ship_vanguard`, no vitals record (the real `user://profile.cfg` was left untouched —
mtime 1789722008.8081996, unchanged). The REPAIRS module is entered by emitting `pressed`
on `RepairsEntry` (station.gd:239). The probe pins the root viewport to 1920x1080 so the
measurement matches §3.1. Probe files, their `.uid` sidecars and `user://p1j_probe_*`
were removed after the run.

## Probe assertions (76 checks, all passed)

| Step | Assertions | Result |
|---|---|---|
| 1 structure | pane is the loaded scene (not the placeholder group); root named `Repairs`; separation 12; `theme == null`; the four §5.9 unique names resolve; title `REPAIRS`; subtitle `HULL AND SHIELD`; footer = the fee rule; `RepairBox` min/measured 360; `DamageReportBox` min/measured 560; report column left of the control column; `REPAIR` 88 tall, `StationButton`, text `REPAIR`; value column 220 wide, right aligned, flush with the report box; button fills the control column | PASS x21 |
| 2 no report | `ACTIVE HULL` = `VANGUARD`; `HULL`/`SHIELD`/`MISSING`/`FEE` = `NOT REPORTED`; button disabled; caption `UNDOCK AND DOCK TO FILE A DAMAGE REPORT`; strip `NO DAMAGE REPORT`; disabled button takes no ring and the shell falls back to `RepairsEntry` (station.gd:401-410) | PASS x11 |
| 3 damage 200/300 | rows `200 / 1000`, `300 / 600`, `800 HULL · 300 SHIELD`, `500 CR`; button enabled; strip `REPAIR AVAILABLE · 500 CR`; no `accent_danger` override while affordable; press -> credits 10000 -> 9500 (-500), vitals `{hull: 1000, shield: 600}`, rows back to maxima (`1000 / 1000`, `600 / 600`, `0 HULL · 0 SHIELD`, `0 CR`), strip + shell status `REPAIRED · 500 CR · ALL SYSTEMS NOMINAL`, UI cue `ui_confirm_01.ogg`, exactly one log line `2026-09-18T09:41:01, REPAIR, ship_vanguard, 0, -500, 9500` | PASS x18 |
| 4 nominal | strip `ALL SYSTEMS NOMINAL`, button disabled, vitals untouched | PASS x3 |
| 5 exemption 1000/570 | fee `0 CR`, button enabled, strip `SHIELD TOP-UP · NO FEE`, `focus_primary()` puts the ring on the `REPAIR` button, press -> shield 600, credits 9500 -> 9500, strip `REPAIRED · 0 CR · ALL SYSTEMS NOMINAL`, confirm cue, second log line `, REPAIR, ship_vanguard, 0, +0, 9500` | PASS x10 |
| 6 insufficient | balance spent down to 499; `FEE` `500 CR` with the `font_color` override (danger); strip `REPAIR AVAILABLE · 500 CR`; press -> strip and shell status `REFUSED · NOT ENOUGH CREDITS · 500 NEEDED`, shell status drawn in `Tokens/accent_danger`, vitals still 200/300, credits still 499, log still 2 lines, cue `ui_denied_01.ogg` | PASS x13 |

## Measured geometry (headless, root viewport pinned to 1920x1080)

```
[P1j] geometry viewport=(1920.0, 1080.0) station=(1920.0, 1080.0) host=(1496.0, 895.0)
      pane=(1440.0, 839.0) @428 body=(1440.0, 749.0) report=(560.0, 749.0) @428
      repair=(360.0, 749.0) @1508 button=(360.0, 88.0) value_col=220
```

The report column starts at the pane's left edge (428) and is exactly its 560 px minimum;
the control column ends at the pane's right edge (1508 + 360 = 1868) and is exactly its
360 px minimum, so the two §5.9 columns hold and the spacer absorbs the slack, the way
LAUNCH's brief/deck-control split does. `ModuleHost` measures 1496x895 against §3.1's
1497x858: the 37 px delta is the header band (this run's `StationName`/logo stack is
shorter than the mockup's), below the host, not inside this panel. Row heights, the 220
value column and the report's right-aligned values were confirmed against the theme
(`StationCaption`/`StationValue`/`SectionHeader`/`StationButton`, all present in
`vajb_theme.tres`).

## Reviewer notes

1. **The two `SCRIPT ERROR` groups in the probe stdout are sibling files, not this
   panel.** `refinery_panel.gd:480` (`a number is required in operator %`, parse error;
   `refinery_panel.gd:477` in the previous run) and `exchange_panel.gd:343`
   (`Nonexistent 'int' constructor`, 54 hits, from `_refresh_board_component`) are the
   in-flight P1h/P1i deliverables; `station.gd:280` loads them because `MODULE_FILES`
   lists them. No error line carries a `repairs_panel.*` path or frame. My two files
   produce none. The strict "no SCRIPT ERROR" criterion cannot be met while those two
   are broken; re-run once P1h/P1i land.
2. **`NOT REPORTED` covers the four damage rows; `ACTIVE HULL` still names the hull.**
   §5.9 says "report rows read `NOT REPORTED`"; the active hull is a `StationCatalog`
   read, not a vitals read, so the row keeps the catalogue name (`VANGUARD`) and only
   `HULL`/`SHIELD`/`MISSING`/`FEE` read `NOT REPORTED`. Easy to flip if the owner wants
   the whole column inert.
3. **Report rows print plain digits** (`200 / 1000`, never `200 / 1 000`): §5.9 fixes
   those strings literally, so this panel does not use the grouped `_format_int` the
   credits/price columns use. `REPAIRED · <fee> CR` therefore reads `REPAIRED · 0 CR ·
   ALL SYSTEMS NOMINAL` for the free shield top-up (the §5.9 success format with the
   §5.9 zero fee); say the word if `NO FEE` is wanted there instead.
4. **Refetch triggers.** Vitals writes are silent (17 §3), so the panel re-reads the
   active ship and its report on `_ready`, on `refresh_profile(&"credits")` /
   `(&"ships")`, after its own repair, and on `NOTIFICATION_VISIBILITY_CHANGED` when the
   pane becomes visible (the module switch). Without `disarm()` that visibility hook is
   the "re-read on every entry" the brief asks for; the active ship id is never cached.
5. **Refusal copy.** `insufficient_credits` uses §5.6's wording and the danger colour;
   `no_damage` / `no_damage_report` cannot be reached by a press (the button is disabled
   in both states) but are handled with the §5.9 captions (`ALL SYSTEMS NOMINAL`,
   `UNDOCK AND DOCK TO FILE A DAMAGE REPORT`) and stay neutral, because they report a
   state rather than refuse a payment.
6. **Audio.** HOVER on focus, CLICK on press, CONFIRM on a successful repair, DENIED on
   a refusal, plus the §5.6 four-step `modulate.a` pulse on the FEE cell. No new cues;
   `Repairs.repair` never emits `purchase_failed`, so the shell does not double a cue.
7. **Probe cleanup.** The probe deletes `user://p1j_probe_*` itself, but a mutation in
   phase 6 leaves the profile dirty, so `PlayerProfile`'s exit-tree `flush()` re-creates
   `user://p1j_probe_profile.cfg` after the probe quits; it was deleted from the shell
   afterwards and the user directory now holds only the pre-existing `profile.cfg`,
   `settings.cfg` and engine caches.
