# P1h report — REFINERY station panel (STATION_HUB §5.7, doc 04)

Worker: coder (P1h). 2026-09-18. Godot 4.7.2 stable, `--headless` only, no MCP tool, editor never
launched, the brief's exact run command used throughout.

## Deliverables — exactly two files, nothing else touched

1. `vajb-orbit/ui/station/refinery_panel.tscn` — new, 211 lines, 35 nodes.
2. `vajb-orbit/ui/station/refinery_panel.gd` — new, 699 lines (530 code / 60 comment / 109 blank), 49 funcs.

The shell already lists `refinery` in `MODULE_FILES`, so no other file needed a change. Unique names follow
the §5.7 sketch: `PaneHeader` (`PaneIcon`, `PaneTitle` REFINERY, `PaneSubtitle` ORE PROCESSING, `PanelTag`),
`RefineryTable` (`HeaderMargin` → `RefineryHeader`, `RefineryScroll` → `RefineryRows`), `RefineBox`
(`SelectedName`, `StepperLess`/`StepperValue`/`StepperMore`, `OreInValue`/`IngotsOutValue`/`FeeValue`,
`RefineButton`/`RefineAllButton`/`CancelButton`), `PaneFooter`. The other workers' panels (`exchange_panel.*`,
`repairs_panel.*`) were present and were not touched. `tools/_probe_p1h.tscn` + `.gd` were created, run and
deleted; no `.uid` sidecar was ever produced (no editor ran). `user://p1h_probe_profile.cfg` /
`p1h_probe_log.txt` deleted. Kept evidence logs: `.agents/gen/p1h_run8.txt`, `p1h_run_empty8.txt`,
`p1h_run_hashed.txt`.

## Commands and observed output

`"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" …`

- `res://tools/_probe_p1h.tscn --quit-after 300` → `EXIT=0`, 79 stdout lines, **70 checks / 0 failed**, ends `PROBE OK`, 0 `SCRIPT
  ERROR`, 0 `WARNING`, 0 leaked instances.
- `res://tools/_probe_p1h.tscn --quit-after 300 -- --p1h-empty` (step 8, zero seeded cargo) → `EXIT=0`, 20 lines, **14 checks / 0
  failed**, `PROBE OK`, 0 `SCRIPT ERROR`, clean exit.
- `res://ui/screens/station.tscn --quit-after 300` after cleanup → `EXIT=0`, 3 lines, no errors.

`profile.cfg` SHA256 `abdbe3b9…bf468` (723 B) identical before and after a probe run, and every run prints
`user://profile.cfg mtime … (unchanged: true)`. The probe redirects `save_path` before any mutation, so the
autoload's exit flush lands in the scratch file.

## Assertions (84, all PASS — one `[P1h] PASS`/`FAIL` line per check in the kept logs)

- **Boot/contract (7):** autoload present; station instantiates; REFINERY is the real scene (not the `station_placeholder` fallback);
  panel carries `status_requested`/`refresh_profile`/`focus_primary`/`disarm`; nothing armed before a row is chosen; OUTFITTING laid
  out for the width comparison; REFINERY visible after the rail press.
- **Table rows, step 3 (14):** `Refinery.stacks` reports 2 stacks; one toggle row per stack; rows named `OreIron`/`OreGold`;
  `toggle_mode` + 76 px min; catalogue name; meta `12 ORE HELD`/`8 ORE HELD`; ORE `12`/`8`; INGOTS `4`/`2`; FEE `60 CR`/`30 CR` (each
  equal to the module's own number); a mineral below 3 ore has no row; tag `2 STACKS · 6 CONVERSIONS READY`; footer `3 ORE = 1 INGOT ·
  FEE 15 CR PER CONVERSION`; row icon is the tint stencil; icon carries `TIER_TINTS[1]` at the 0.72 idle alpha.
- **Geometry, step 3 (13):** row fills the table column with no overflow; rows VBox spans the scroll content box; scroll spans the
  table column; table + 16 gap + RefineBox spans the pane; pane = host content box (HostMargin 20/side); row ≥ 76 tall; row inner
  margin 12/8; icon column 40; value columns 130/110/160; title column absorbs the slack; pane width == OUTFITTING pane width; table
  column == OUTFITTING row − (16 + 360); RefineBox exactly 360.
- **Stepper (7):** row press arms with the whole stack (`GOLD`, `2 CONVERSIONS`, `REFINE 2`); totals 6/2/30 CR; `+` disabled at
  maximum; `−` → 1 conversion, totals 3/1/15 CR; `−` disabled at minimum; `+` restores; an affordable fee is not painted danger.
- **REFINE N, step 4 (7):** takes the whole gold stack (8 ore → 6 taken, 2 left: whole conversions only, and that remainder is under
  the 3-ore row threshold); charges 30 CR once; the gold row left the table (1 row remains); strip `REFINED · GOLD · 2 INGOTS · 30 CR
  FEE` (positive); tag rebuilt to `1 STACKS · 4 CONVERSIONS READY`; selection cleared and `REFINE 1` disabled; exactly one log line
  `…, REFINE, mineral_gold, 6, -30, 1970`.
- **Refusal path, §5.6 (9):** with 10 CR, the totals FEE and the row's own FEE cell are painted `accent_danger` before the press; the
  press is still offered (presentation only); strip `REFUSED · NOT ENOUGH CREDITS · 60 NEEDED` in danger; nothing moved (credits 10,
  iron 12, no ingot); table and selection intact; no log line; `REFINERY ALL` still armed; balance restored to 2000.
- **REFINERY ALL, step 5 (5):** converts the remaining stack (12 ore → 4 ingots); one fee for the batch (60 CR); strip `REFINED · ALL
  ORE · 4 INGOTS · 60 CR FEE`; one combined log line `…, REFINE, all, 12, -60, 1910`.
- **Empty state, step 6 (9):** one `NO ORE TO REFINE` caption row and no payload rows; the caption row is `FOCUS_NONE`; every
  RefineBox control disabled; footer `BRING RAW ORE FROM THE BELT`; tag `NO CONVERTIBLE STACKS`; totals `0`/`0`/`0 CR` with no danger
  colour; `disarm()` false; `REFINERY ALL` refuses (`REFUSED · NO ORE TO REFINE`, danger) without spending or logging.
- **Zero-cargo boot, step 8 (14):** the same empty-state set on a hot boot with no seeded cargo, plus `focus_primary` hands the ring
  to `REFINE_ALL` (the brief's third branch) and nothing is written.

## Measured geometry (verbatim; window 1920×1080, host content 1480×879)

```
pane (1440.0, 839.0) @(20.0, 20.0) | table (1064.0, 749.0) @(0.0, 0.0) | scroll (1064.0, 710.0) @(0.0, 39.0)
rows (1062.0, 164.0) @(1.0, 1.0)  | row (1062.0, 76.0) @(0.0, 0.0)      | box (360.0, 749.0) @(1080.0, 0.0)
icon (40.0, 60.0) @(0.0, 0.0) | title (550.0, 46.0) @(52.0, 7.0) | ore (130.0, 26.0) @(614.0, 17.0)
ingots (110.0, 26.0) @(756.0, 17.0) | fee (160.0, 26.0) @(878.0, 17.0)
OUTFITTING pane (1440.0, 839.0) @(20.0, 20.0) | OUTFITTING row width 1438.0
```

`1062 = 1438 − 16 − 360`: the refinery table column is the OUTFITTING row minus the deck column, and the 2 px
difference from `scroll` (1064) is the ScrollContainer's own 1 px panel inset per side (the same reason the
reference widths are 1440/1438, not 1080-derived numbers). Row arithmetic is exact: 12 + 40 + 12 + 550 + 12 +
130 + 12 + 110 + 12 + 160 + 12 = 1062.

## Deviations and reviewer notes

1. **Brief step 4 vs 04 §2.** The brief expects `REFINE N` on 8 gold ore to leave `0 mineral_gold`; 8 ore is 2 conversions (6 ore) and
   04 §2 keeps the leftover 2 units, so the probe asserts the module's contract (2 ore left, below the 3-ore row threshold, so the row
   disappears) while every ingot, fee and credit number the brief names holds. A seed that is a multiple of 3 makes that line exact.
2. **`focus_primary` third branch.** In the empty state both `REFINE 1` and `REFINERY ALL` are disabled, yet Godot still lets
   `grab_focus()` take the ring, so it lands on `REFINERY ALL` rather than falling back to the rail entry (the shell sees a descendant
   and keeps it). That is the brief's prescribed order; dropping the two fallback branches is the whole change if the owner prefers
   the rail fallback instead.
3. **Cues.** §5.7 lists CLICK for row select, so a row plays CLICK only when the selection actually changes (focus or press), with no
   HOVER cue; the icon hover tween is kept. Stepper ticks play SCROLL (plus the scroll cue outfitting already has), success CONFIRM,
   refusal DENIED. No new cues.
4. **`_profile()` anchor.** The brief names `get_node_or_null(^"PlayerProfile")`, which resolves against the panel rather than
   `/root`, so the house pattern is used (`get_tree().root.get_node_or_null(&"PlayerProfile")`), as `station.gd:496-506` and the P1f
   report document.
5. **Rebuild during a transaction.** `Refinery.refine` emits `profile_changed(&"cargo")`/`(&"credits")` while it runs, so the shell
   forwards a refresh into the panel inside its own button handler, and a rebuild there would free the row the signal chain is
   walking. A `&"cargo"` refresh seen mid-transaction is therefore deferred to one rebuild right after the call returns, and the
   handler captures name/count/fee first; `&"credits"` only re-colours affordability.
6. **Stepper plates.** 48 px per §5.7/§12.3, but `StationButton` rather than `SlotButtonWeapon`: the slot variations are
   `TextureButton`s with no text item, and the stepper carries `-`/`+` and needs a focus ring.
7. **Totals.** `FEE` = `Refinery.fee_for(n)`, `ORE IN` = `n × Refinery.ORE_PER_INGOT`, `INGOTS OUT` = `n` (the module exposes no
   ingot-count accessor; 1 ingot per conversion is its fixed yield, 04 §3). No price, fee or ratio is hardcoded, including the footer,
   built from `ORE_PER_INGOT`/`FEE_PER_CONVERSION`.
8. **Wording §5.7 leaves open** (owner may reword): tag `"%d STACKS · %d CONVERSIONS READY"` / `NO CONVERTIBLE STACKS`; idle box `NO
   STACK SELECTED` + `0 CONVERSIONS`; CANCEL strip `REFINERY IDLE · SELECT A STACK`; row hint `READY · <NAME> · <n> CONVERSIONS ·
   <fee> FEE`; the non-credit refusals (`NOT ENOUGH ORE`, `NO CONVERSIONS SELECTED`, `NO ORE TO REFINE`, `UNKNOWN MINERAL`); the
   middle header cell reads `MINERAL`.
9. **Icons and the spacer.** The pane icon is `tint/icon_cargo_ore_48.png` modulated with `text_primary` (shipyard's pattern, matches
   the rail entry); rows draw the tint stencil under `TIER_TINTS[tier]` at the 0.72 idle alpha, the hover tween lifting alpha to 1.0
   (ICONS_SPEC §8.6), and painted `icon_ore` art (a future §8.1 mineral glyph) is drawn unflattened when no stencil exists for it.
   `RefineSpacer` sits between the totals and the actions (`ActionSpacer` precedent, §3.3) so the primary action stays bottom-aligned;
   the empty state disables all five box controls, CANCEL included.
10. **Environment, not this panel.** `res://ui/screens/station.tscn` alone leaks `amb_station_room_01.ogg` (4 instances / 2 resources)
    in 2 of 3 runs — the shell's looping ambience held at exit; this panel only calls `play_ui`, and the probe stops the ambience
    before quitting, so its own exit is clean. Separately, runs from 11:41–11:46 were flooded by `SCRIPT ERROR: Invalid call.
    Nonexistent 'int' constructor.` from `ui/station/exchange_panel.gd:343` (a key missing from its board payload) — the P1i worker's
    file, still being written, none from `refinery_panel.gd`; after its 11:48 write the final runs are byte-clean.
