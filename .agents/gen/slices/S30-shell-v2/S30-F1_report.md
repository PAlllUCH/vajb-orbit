---
slice: S30
worker: S30-F1
model: hyper/deepseek-v4.1-flash
status: actionable
gate: "1093/0 → 1093/0"
---

# S30-F1 report (fixer, HIGH/MED only)

## Result
All ten HIGH/MED findings cured at their named `file:line`; the F1–F3 geometry re-measures at
the fixed values (Layout 1920×1080, Header y 24, Footer y 1038; drawer plate 362×859 with
`offset_bottom` 0; sheet root 1920×1080 with the panel centred). F11–F14 (T-114–T-117)
untouched. Gate **1093/0** twice on fresh scratch `XDG_DATA_HOME` stores.

## Disposition

**F1 — FIXED (HIGH).** The shipyard's 741 px stats column is now a vertical `ScrollContainer`
(`shipyard_panel.tscn:118` `StatsBox` → `ScrollContainer`, inner `StatsStack` VBox), so
`ShipyardBody`'s minimum is 331 (was 741) and the pane's is 452 (was 862) — inside the pinned
753 px content box. Measured: Layout 1920×1080 at all three docked decks, Header y 24..146,
Footer y 1038..1056. Reversal: the flat `VBoxContainer` column.

**F2 — FIXED (HIGH).** `station.gd:464` writes the plate's full-rect anchors/offsets
explicitly *after* `add_child` (no `set_anchors_and_offsets_preset` out of tree), and
`_reset_plate_box()` (`:864`, called `:858`, deferred `:859`) re-writes the vertical box on
every open, because the build-time zero-height parent left the plate's 648 px minimum as
`offset_bottom`. Measured: PLATE 362×859, offsets all 0; LOG OUT g 68,922..274,978 (on
screen at 1920×1080). Reversal: the preset call.

**F3 — FIXED (HIGH).** `inspect_sheet.gd:167,177`'s two `reset_size()` calls now size
`_content`, never the anchor-laid-out root. Measured: SHEET_ROOT 1920×1080 at 0,0; SHEET_PANEL
486×564 centred at 717,258. Reversal: `reset_size()` on the root.

**F4 — FIXED (MED).** `tooltip.tscn:3-8` and `inspect_sheet.tscn:3-14` carry the theme at
their roots (dialog.tscn:14's idiom); `station.gd:406` sets the code-built drawer's theme
(`_drawer.theme = theme`). Measured: `%SheetPanel` resolves `StyleBoxTexture` (was
`StyleBoxFlat`), `TooltipPanel`/`PanelRaised` resolve, the drawer plate's panel is
`StyleBoxTexture` with `ui_panel_frame.png` — matching ModuleHost; the plate's content box is
R-S30-1's 272 (RailBox min 272). Reversal: resolve Tokens by hand.

**F5 — FIXED (MED).** `publish_idle_summary()` is deleted from both panes. The
unhover/pane-show path now publishes the chain's clear (`inspect_requested.emit("", "",
false)` — `shipyard_panel.gd:242,983,1166,1352`, `launch_panel.gd:222`), so the N27 tooltip
opens on a real hover only (N33's unhover dismissal restored). §18's ledger: the idle fill is
retired with the band. Reversal: the idle fill behind a fixed pane-internal slot.

**F6 — FIXED (MED).** `_set_layout_grid` (`shipyard_panel.gd:548`) gains a same-hull
short-circuit (`_grid_hull`/`_grid_built`, `:216-217`): a focus move onto the hull already on
the grid never touches the tree. Measured: a repeat `_on_row_focused` leaves the grid's
children identical. Reversal: the per-call rebuild.

**F7 — FIXED (MED).** The hand-positioned rows carry the inline INSPECT chip: the ammo card
(`armory_panel.gd:1657`, positioned `:1469`) and the inventory row (`:2303`, positioned
`_position_inventory_item` `:1388`). The card reserves the trailing 96 px cell (Held 174 wide,
BUY moved to x 146, Status raised to y 11); the inventory row stacks Name/Status left of the
chip. Measured: card `InspectChip` 96×32 at 218,34; row `InspectChip` 96×32 at 218,18, no
overlap. Reversal: `station_inspect` on the focused row alone.

**F8 — FIXED (MED).** ARMORY gains the shared `PaneFoot` band
(`armory_panel.tscn:206`, min 0×56): the §19.4 hint `MeterLabel` left (h3, v7) and the §8 P2
`ActionsRow` cluster right — measured band 1068×56, meter 76..964, cluster 980..1844.
Reversal: `ActionsRow` as a direct child.

**F9 — FIXED (MED).** LAUNCH's band is the §19.3 box and the legacy `ConfirmStrip` folds into
it (`launch_panel.tscn:143`): `PaneFooter` (P29 hint) + `ConfirmStrip` + `ActionsRow` (the
§19.4 REFUEL/RECHARGE/LAUNCH set, built `launch_panel.gd:387-390`). Measured: band
1374×56 at 914..970, the pane's last region; ConfirmStrip inside it. Reversal: the separate
strip row.

**F10 — FIXED (MED).** `station.gd:401`: the drawer's full-rect root is
`MOUSE_FILTER_IGNORE`; the Body-band scrim and the plate are the two STOP surfaces, so
TERMINAL (and the footer) stay live while the drawer is up (N40). Measured:
`_drawer.mouse_filter` = 2. Reversal: the STOP root.

## Tests moved / added (disclosed)
| Suite | Row | Change |
|---|---|---|
| `test_s29_station_panels.gd` | `test_the_shipyard_and_launch_fill_the_band_when_idle` → `test_the_shipyard_and_launch_idle_paths_never_arm_the_tooltip:332` | F5 retired the fill, so the row now proves the clear (the old assertion proved the removed behaviour) |
| `test_p2b_services.gd` | `test_hovering_a_plate_publishes_its_line_and_costs_the_plate_nothing:492` (leave assertion `:526`) | the leave assertion now reads `""` (F5), was "contains VANGUARD" |
| `test_s30_shell.gd` | +4 rows `test_the_shipyard_stats_column_scrolls_and_cannot_reflow_the_shell` (F1), `..._drawer_plate_carries_no_minimum_size_offset` (F2), `..._sheet_fit_never_resets_the_root` (F3), `..._popup_layers_resolve_the_theme` (F4) | 12 → 16 rows |
| `test_s11_inspector.gd` | two doc comments only | the "idle summaries" wording (F5) |
| `tests/probe_s30_review{,2,3,4}.gd` | deleted | their assertions folded into the four new `test_s30_shell.gd` rows (no loose probes left) |

## Evidence
- `XDG_DATA_HOME=/tmp/s30f1-z1 godot --headless --path $VAJB_PROJ
  res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=1093 failed=0`, exit 0
- the same on `/tmp/s30f1-z2` → `[SUMMARY] passed=1093 failed=0`, exit 0
- geometric re-measure (throwaway probe, deleted): Layout 1920×1080 + Header 24..146 +
  Footer 1038..1056 at decks 0/4/5; plate 362×859 `offs_b` 0; sheet root 1920×1080, panel
  717,405..1203,675; tooltip/sheet/drawer themes non-null, plate sb `StyleBoxTexture`
- `--suite=test_s30_shell` → `passed=16 failed=0`

## Files touched
- `ui/screens/station.gd` — F2, F4, F10
- `ui/station/shipyard_panel.gd` / `.tscn` — F1, F5, F6
- `ui/station/launch_panel.gd` / `.tscn` — F5, F9
- `ui/station/armory_panel.gd` / `.tscn` — F7, F8
- `ui/components/inspect_sheet.gd` / `.tscn`, `ui/components/tooltip.tscn` — F3, F4
- `tests/test_s30_shell.gd`, `test_s29_station_panels.gd`, `test_p2b_services.gd`,
  `test_s11_inspector.gd` — moved/added rows above; `probe_s30_review{,2,3,4}.gd` deleted

## Notes (bucket-1 judgements, no pause)
1. **F7 positions the chips by hand** (the A5.2(i) pass B1 deferred). The 320×68 card cannot
   hold a 96×32 chip beside its four lines, so the card reserves the trailing cell and the
   inventory row stacks its two text lines. Reversal: the deferred positioning pass.
2. **F8 keeps `SelectionLine` in the content split**: §19.4 names only the power meter as
   ARMORY's foot-band hint, so the meter moves to the band and the cell's own caption stays a
   content line. Reversal: move it into the band as a second cell.
3. **F9 keeps both the P29 hint and the live `ConfirmStrip`** in the band (the static hint is
   §19.4's; the strip is §5.4's arm copy and keeps `test_p2b_services`' `%ConfirmStrip`).
   Reversal: one cell.
4. No pinned value changed; R-S30-1/R-S30-2 stand; Tokens only, no new art; docs read-only.
