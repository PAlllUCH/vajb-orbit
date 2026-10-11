---
slice: S41
worker: S41-B4
model: "hyper/deepseek-v4.1-flash"
status: informational
gate: "1300/0 → 1327/0 (B4's suite +6; the wave's four suites +27)"
---

# S41-B4 report

## Result
The services-side composition findings are fixed at their named sites and proved by six
load-bearing rows. Gate, twice on fresh scratch `XDG_DATA_HOME` stores: **1327/0** and **1327/0**
(`test_s41_panels_b` 6/6 in both). The pre-change gate was **1300/0** (1327 − 27: the four S41
suites' rows), so §6's "+ the three new suites' rows only" holds.

## Acceptance list answers
- A1 — F5 fixed (`refinery_panel.gd:68,371,411`); F10 fixed (`shipyard_panel.gd:104,834-848`);
  F11 fixed (`launch_panel.tscn:82`, the spacer deleted); F13 fixed (`contracts_panel.gd:367-398`);
  F14 (refinery) fixed (`refinery_panel.tscn:283-311`); F15 (shipyard half) fixed
  (`shipyard_panel.tscn:53-85`, `shipyard_panel.gd:285-288`). F15's services half **NOT DONE**:
  the segment strip is built in `ui/screens/station.gd:1119-1135` (`SERVICES_STRIP_HEIGHT := 56`,
  `:119`), outside B4's file set (§3's file-set note).
- A2 — no `position`/`offset_*` from code, no visual box gained a layout-filler flag. One new
  `SIZE_EXPAND_FILL`, on a container that owns the slack: `CardEscrow` (`contracts_panel.gd:376`,
  the VBox pushing the CANCEL chip right). F11 **removes** a filler (`BriefSpacer`).
- A3 — **no colour added or changed**; `build_theme.gd` and `vajb_theme.tres` are untouched by
  B4. The only chrome reuse is `ChromeFamily.apply_chip` (no new literal).
- A4 — NOT B4's: F1 is S41-B2's (`overview_panel.*`, brief §3). A6 — NOT B4's: T-177 rides W1.
- A5 — F14 proved: the three moved plates are `Vector2(360, 56)` `StationButton`s inside
  `PaneFoot/ActionsRow` (`refinery_panel.tscn:283-311`), the anchor EXCHANGE uses
  (`exchange_panel.tscn:190-218`), QUEUE rightmost.
- A7 — every row fails on its own revert; measured, one revert at a time (Evidence). A8 — no gate
  row outside §6's list moved: the final pair is 1327/0 and B4's suite is B4's only delta (two
  sibling in-flight regressions were seen mid-wave, both gone in the final pair).

## Deviations from SLICE.md
- **F11's reading.** The brief's words ("move `BRIEF_NOTE` into the briefing column's last
  row") describe the audit's misreading: `BriefNote` is already a `BriefBox` child
  (`launch_panel.tscn:82`) — what put it in the foot region was the `BriefSpacer`
  (`size_flags_vertical = 3`) above it, pushing the note to the column's bottom. The fix deletes
  the spacer: the note is still the column's last row, now under `CargoList`; the foot band keeps
  the footer + the live confirm line. Reversal: restore the spacer.
- **F14's cluster set.** The brief names QUEUE / LOAD / COLLECT (as the audit's F14 row does) and
  those three moved; QUEUE ALL and CANCEL stay in the centre conversion column
  (`refinery_panel.tscn:222-240`). §19.4/§5.7 name the cluster as REFINE N + REFINERY ALL +
  CANCEL, so pin and brief disagree on which three; the brief is law. The band fits three 360 px
  plates plus the footer (1112 ≤ 1765); five would not (1864). Reversal: move all five, or swap
  to the §19.4 set.
- **Incidental fix (not a finding).** `FOOTER_FORMAT` (`refinery_panel.gd:94`) carried `%d` for
  a `_format_int` **string**, so `_refresh_footer` (`:677`) threw "String formatting error: a
  number is required" and blanked the footer whenever the input was queueable; B4's F5 row is
  the first gate row to reach that state. `%d` → `%s`. Reversal: back to `%d`.
- **F10's mechanism.** The fraction feeds the frame's minimum chain, so a mount that does not
  lay the pane out (a bare `Control` host) grows it; the shipped shell is slack-driven
  (`station.tscn:191` `ModuleHost`, v/h 3) and converges (min ≈ 0.6H + 90 < H for H ≥ 225). The
  F10 row reads sizes and never writes `frame.size`.

## PROPOSED values (numbers, not colours)
| Value | Where | Reversal |
|---|---|---|
| `PREVIEW_FRACTION := 0.60` (the audit's "about 60 % of the box") | `shipyard_panel.gd:104` | the retired constant `PREVIEW_BOX` 240×180 (`:107`) |
| the four mode plates at height **32** (the chip row's `TAB_MIN_HEIGHT`, `auction_panel.gd:114`) | `shipyard_panel.tscn:55,63,71,79` | the shipped 44 px plate |
| the four mode plates' ink at **18** (the chip row's `StationValue` size, `vajb_theme.tres:538`) | `shipyard_panel.tscn:58,66,74,82` | the shipped `StationButton` 22 px ink |

## Evidence
- Gate twice, fresh stores: `XDG_DATA_HOME=$(mktemp -d) "$GODOT_CONSOLE" --headless --path
  "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 2400` → `[SUMMARY] passed=1327
  failed=0` and `[SUMMARY] passed=1327 failed=0`. B4's suite alone
  (`-- --suite=test_s41_panels_b`) → `passed=6 failed=0`.
- Revert proofs (each reverts one fix, one suite run, then restored; md5 checked): F5 → `the
  input inventory carries its own sub-header row`; F10 → `the box is 0.60 of the frame
  ((240.0, 180.0) vs (156.0, 90.6))`; F11 → `no expanding spacer pushes it…`; F13 → `the card is
  exactly two stack rows`; F14 → `the cluster is an HBox in the foot band`; F15 → `ModeHangar
  wears the chip row's height`. Each run failed only its own row.
- Sibling observations (not B4's, both gone in the final pair): `test_s30_shell.gd:237`
  (`P25: three rows`) while S41-B2's `ServiceSlack` child sat in `ServiceRows` (F1);
  `test_s41_armory.gd` (S41-B3's own row) mid-edit.

## Files touched
- `ui/station/refinery_panel.gd` — F5's sub-header + `HEADER_INPUT`; the footer format fix
- `ui/station/refinery_panel.tscn` — F14: the three plates into `PaneFoot/ActionsRow`
- `ui/station/launch_panel.tscn` — F11: `BriefSpacer` deleted
- `ui/station/contracts_panel.gd` — F13: the two-row active card
- `ui/station/shipyard_panel.gd` / `.tscn` — F10's fraction; F15: 32 px plates, chip chrome/ink
- `tests/test_s41_panels_b.gd` — six load-bearing rows
## Follow-ups
| Item | Kind | Where |
|---|---|---|
| F15's services half (the segment tabs at 56 px, not the chip row's 32) | ticket | `ui/screens/station.gd:1119-1135` (B1's set) |
