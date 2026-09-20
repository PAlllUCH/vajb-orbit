# P1h task — REFINERY station panel (STATION_HUB amendment 5.7, doc 04)

Worker: coder. Wave: P1 economy core, panels. Deliverables, exactly two new
files:

1. `vajb-orbit/ui/station/refinery_panel.tscn`
2. `vajb-orbit/ui/station/refinery_panel.gd`

Do not touch any other file (the shell `ui/screens/station.gd` already lists
your panel in `MODULE_FILES`; it loads it by name). No MCP tools. Do not run
the editor. Do not edit `addons/`, `project.godot`, docs, the theme, or any
other script or scene.

## Read first

- `docs/design/STATION_HUB.md` — §3.1 (the measured grid you must reuse),
  §5.7 (your spec), §5.6 (refusal path), §12.3/§12.4 (constants and data
  wiring). Section 5.7 is the contract; do not invent measurements.
- `docs/gameplay/04_refinery.md` — §5 (panel contract), §2/§3 (math behind
  the module you call).
- `vajb-orbit/ui/station/outfitting_panel.tscn` + `.gd` — the row-table
  pattern to copy (pane construct, row anatomy, status strip, focus, tween
  bookkeeping, `_profile()` / `_token()` / `_format_int()` helpers).
- `vajb-orbit/ui/station/launch_panel.tscn` + `.gd` — the 360 px deck-control
  column and the brief value rows you copy for `RefineBox`.
- `vajb-orbit/ui/screens/station.gd` — the panel duck-typed contract:
  `signal status_requested(message, danger)`, `func refresh_profile(key)`,
  `func focus_primary()`, optional `func disarm() -> bool`.
- `vajb-orbit/game/refinery.gd` — read-only contract: `stacks(profile)`,
  `convertible(profile, mineral_id)`, `fee_for(n)`, `refine(profile, id, n)`,
  `refine_all(profile)`.
- `vajb-orbit/game/mineral_catalog.gd` — `TIER_TINTS`, icon paths.

## Panel contract

- Root `VBoxContainer` named `Refinery`, separation 12, no theme baked (the
  shell's live theme must reach every text node). Unique names must match the
  §5.7 sketch: `PaneHeader` (icon, `PaneTitle` `REFINERY`, subtitle
  `ORE PROCESSING`, tag), `RefineryTable` (header strip, `RefineryScroll` →
  `RefineryRows`), `RefineBox`, `PaneFooter`.
- Rows: toggle `Button`s, `custom_minimum_size.y = 76`, separation 6, row
  inner margin 12/8, columns icon 40 / title expand / `ORE` 130 /
  `INGOTS` 110 / `FEE` 160 (section 3.1 widths). One row per
  `Refinery.stacks()` entry; the row stores the mineral id.
- `RefineBox` (min 360, separation 12): caption `CONVERSION`, selected name,
  stepper row (`-` / `"<n> CONVERSIONS"` / `+` with 48 px buttons), totals
  rows (value column 220 right aligned) `ORE IN`, `INGOTS OUT`, `FEE`, then
  `REFINE N` (88 px), `REFINERY ALL` (56 px), `CANCEL` (56 px). Stepper range
  1..`Refinery.convertible`; a selection with fewer than 3 ore never happens
  (rows only exist for convertible stacks).
- Actions: `REFINE N` -> `Refinery.refine(profile, id, n)`;
  `REFINERY ALL` -> `Refinery.refine_all(profile)`. Success -> status strip
  `REFINED · <NAME> · <n> INGOTS · <fee> CR FEE` via `status_requested`,
  refresh rows and credits. Refusal -> the §5.6 path: strip
  `REFUSED · NOT ENOUGH CREDITS · <fee> NEEDED` with `danger = true` and the
  credits-housing pulse is the shell's job only for `purchase_failed`; here
  write the strip text yourself. Nothing is confirmed twice: the button press
  is the confirm (04 §5).
- Empty state (no convertible stack): one disabled caption row `NO ORE TO
  REFINE`, `RefineBox` controls disabled, footer `BRING RAW ORE FROM THE
  BELT`. Default footer: `3 ORE = 1 INGOT · FEE 15 CR PER CONVERSION`.
- Data wiring: `_profile()` via `get_node_or_null(^"PlayerProfile")`; never
  compute prices or fees yourself — every number comes from `Refinery` /
  `MineralCatalog`. `refresh_profile(key)`: rebuild rows on `&"cargo"`, update
  affordability on `&"credits"`.
- `focus_primary()`: focus the first row, else `REFINE N`, else `REFINERY ALL`.
- `disarm()`: clear the selection, reset the stepper, return true when
  something was cleared (used by the shell's `ui_cancel` step 2).
- Audio: reuse `AudioManager.play_ui(AudioManager.UiCue.CLICK)` on row select,
  `CONFIRM` on a successful refine, `DENIED` on refusal, `SCROLL` on stepper
  (mirror outfitting_panel's call sites). No new cues.

## Probe (required)

Probe scene `res://tools/_probe_p1h.tscn` + `_probe_p1h.gd` that boots
`res://ui/screens/station.tscn` headless. Steps:

1. `var profile := get_node("/root/PlayerProfile")`; set
   `profile.save_path = "user://p1h_probe_profile.cfg"` **before** any
   mutation; seed cargo (`add_cargo(&"mineral_iron", 12)`,
   `add_cargo(&"mineral_gold", 8)`) and `EconomyLog.log_path =
   "user://p1h_probe_log.txt"`.
2. Switch to the REFINERY module by emitting `pressed` on the rail entry
   named `RefineryEntry`.
3. Assert: 2 rows exist, counts and fees match `Refinery.stacks()`; geometry
   equivalent to the other panes (row width fills the pane, no overflow).
4. Press `REFINE N` for the gold stack (2 conversions): cargo becomes 0
   `mineral_gold` + 2 `ingot_gold`, credits drop by 30, the gold row
   disappears, the status strip carries the success text.
5. `REFINERY ALL` with the remaining iron stack: converts and refreshes.
6. Empty state: after all ore is converted, the single `NO ORE TO REFINE`
   row and disabled controls are present.
7. Print `PROBE OK`; quit. Delete the probe files and any `.uid` sidecars they
   got, plus `user://p1h_probe_*`, before you finish.
8. Also run once with zero seeded cargo to prove the empty state boots with
   no SCRIPT ERROR.

Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1h.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, no `SCRIPT ERROR`. Do NOT
use `--check-only --script`. **Never** let the probe touch
`user://profile.cfg` (always redirect `save_path` first).

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — no `$` in PowerShell.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1h_report.md`: deliverables, commands + observed output,
every probe assertion with its result, measured geometry evidence, and
anything a reviewer should look at. Under 120 lines.
