---
slice: S41
worker: S41-B5
model: "hyper/deepseek-v4.1-flash"   # the session model this worker ran on
status: informational
gate: "1327/0 → 1330/0 twice on fresh scratch XDG_DATA_HOME stores (identical counts)"
---

# S41-B5 report — the completion builder

## Result
**F8 complete**: the AUCTION's shelf chrome carries one caption+band at a time — the section whose
rows own the top of the scroll — so every band sits over the rows it labels and the fold can still
only cut rows. **F15's services half**: the SERVICES segments wear the chip row's 32 px height, its
`StationValue` ink and its C3 chrome, so the two switch families read as one. **The A3 tidy**: the
confirm title wears the theme's own `DialogTitle` size token, no inline `font_size`. Gate **1330/0**
twice (1327 + 3 rows here); §6's suites unmoved.

## Acceptance list answers
- **A1** — fixed at their named sites: F8 `auction_panel.gd:403-428,437-481,1319-1330,1408-1414`;
  F15 services `station.gd:119-127,1143-1147,1208-1211`; the tidy `station.gd:540-543`. Nothing
  dropped; `auction_panel.tscn` needed no edit (B2's chrome nodes are already there).
- **A2** — no `position`/`offset_*` write, no `size_flags_vertical = 3` added. New writes are
  `visible` on the three chrome `MarginContainer`s and the two filtered row hosts (containers), plus
  `custom_minimum_size`/theme overrides on buttons; the one geometry read
  (`rows.position.y + rows.size.y`, `:462`) only decides which chrome shows.
- **A3** — no colour added or changed (`build_theme.gd` / `vajb_theme.tres` untouched, both outside
  this worker's set); the chip ink is read off the theme (`get_theme_font_size(&"font_size",
  &"StationValue")`, `station.gd:1209`), never retyped.
- **A4 / A5 / A6** — not this worker's: F1 is B2's, F14 B3's and B4's, T-177 B1's.
- **A7** — every new row is load-bearing, one revert at a time: F8 whole (`git checkout HEAD --
  ui/station/auction_panel.gd`) → `passed=4 failed=2` (the ALL-tab legend assertion + the new row's
  first); F8's scroll pass alone → `passed=5 failed=1` on "scrolled past the hull rows the chrome
  follows to the module section"; F15 (56 px, no ink, no chip) → `passed=13 failed=1` on "wears the
  chip row's height (F15)"; the tidy (inline override back) → `passed=13 failed=1` on the dialog-title
  variation. Reads use `get()`/properties; the one `call()` is `select_family`.
- **A8** — no §6 row moved: 1330 = 1327 + 3, zero failures both runs, and the per-suite counts off
  the log are the pins unchanged (`s40_legibility` 8, `d7_status` 8, `d7_cockpit` 18, `p2b_services`
  15, `s25_contracts` 26, `s27_catalog` 25, `ui_slot_layout` 12, `s32_armory_modes` 23).

## Deviations from SLICE.md / the pinned reading
- **F8's chrome is a sticky band, not a tab-only swap.** A filtered tab shows one section, so the
  chrome is that section's block; under ALL (all three at once) it follows the section whose rows own
  the top of the scroll, so the MODULES and SELL MODULES bands stay reachable. Reversal: the checkout.
- **F8 also hides a filtered section's whole row host** (`:412-413`): the filter hid the payload rows
  but not the host's empty-state line, so a filtered section still answered "shows rows". Reversal:
  hide only the payload rows again.
- **F15's services half mirrors B4's shipyard half** — the same three levers (height, theme-read ink,
  `apply_chip`) — so the two families cannot drift. Reversal: the three F15 lines.
- **The tidy owed no new token**: `DialogTitle` is already the theme's own 18 px dialog-title size
  (`build_theme.gd:153`, `ui/dialogs/dialog.tscn:53`), so `build_theme.gd` stays untouched.

## PROPOSED values (every new number, with its reversal)
| Value | Where | Why | Reversal |
|---|---|---|---|
| `SERVICES_STRIP_HEIGHT := 32.0` (was 56.0) | `station.gd:123` | F15: the chip row's own height (`auction_panel.gd`'s `TAB_MIN_HEIGHT`), the value B4 gave the SHIPYARD plates | the shipped `56.0` |
| the segments' ink = the theme's `StationValue` size (18) | `station.gd:1143,1208` | F15: the chip row's own ink, read from the theme so it cannot be retyped | drop the override (base `Button` 14) |
| the segments' C3 chip plate (`apply_chip`) | `station.gd:1146` | F15: the chip family's chrome, the SHIPYARD plates' and ARMORY chips' own plate | drop the call (the base `Button` plate) |
| the chrome shows the topmost section still showing rows | `auction_panel.gd:437-481` | F8: one band over its own rows, never a three-block legend | the B2 hoist (all three blocks visible) |

## Evidence
- Gate ×2, fresh stores, `--quit-after 2400`: `XDG_DATA_HOME=$(mktemp -d) "$GODOT_CONSOLE"
  --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn` → `passed=1330 failed=0` twice
  (`/tmp/s41_b5_gate{1,2}.log`); alone: `test_s41_panels_a` 6/0, `test_s41_shell` 14/0.
- F8's row needs a staged shelf: a bare autoload lists nothing, so the pane's body measured 252 px in
  a 756 px pane and `scroll_vertical` could not leave 0 (measured; fixed by `_stage_full_shelf`,
  `test_s41_panels_a.gd:261-281`, `test_s3_auction.gd`'s harness).
- The four revert proofs (`/tmp/b5_revert_f8{,b,c}.log`, `/tmp/b5_revert_f15.log`,
  `/tmp/b5_revert_tidy.log`); every file restored byte-for-byte (`md5sum` checked). No probe here: the
  render + visual re-audit is brief §7 step 3's, R1's / the orchestrator's.

## Files touched
- `ui/station/auction_panel.gd` — F8: `_sell_margin` in the section table, the row-host filter, the
  `_sync_shelf_chrome` set and the scroll-bar wiring; `ui/screens/station.gd` — F15's services half
  and the confirm title's `DialogTitle` token.
- `tests/test_s41_panels_a.gd` — the chrome row, the ALL-tab row's legend assertion, the harness; `tests/test_s41_shell.gd` — the F15 services row and the dialog-title row.

## Follow-ups
- The AUCTION's sticky band is in no render yet: the probe re-render + visual re-check is the
  close-out's (brief §7 step 3), verification owed to R1 / the orchestrator.
