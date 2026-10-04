---
slice: S30
worker: S30-B2
model: hyper/deepseek-v4.1-flash
status: actionable
gate: "1079/0 → 1089/0"
---

# S30-B2 report

## Result
The station is shell v2: header (TERMINAL · identity plate · credits housing) / one body pane at
full width / footer status strip, the `ModuleRail` and the `Inspector` band **deleted**, the
TERMINAL drawer over the body band, OVERVIEW landing on dock with its five blocks, and P20's
six-pane cycle. Gate **1079/0 → 1089/0**, twice on fresh `XDG_DATA_HOME` stores.

## Acceptance list answers
- **A1 — DONE.** `ui/screens/station.tscn`: header `TerminalButton` (96×32, N25) + `StationPlate`
  (flat Tokens box + `PlateMargin` 12/8 + glyph 48 + `StationName`/`StationLocation`, A5.4-1) +
  `CreditsPanel`; `Body` holds only `ModuleHost` (full width, P15); the footer `HintLabel` is P29's
  line. The `ModuleRail` subtree and the `Inspector` subtree are gone (§18's supersession ledger,
  P6 retired). The faction glyph/border resolve in `_apply_identity` `station.gd:670`.
- **A2 — DONE.** Drawer built in `_build_drawer` `station.gd:390`: a full-rect overlay on layer 20,
  the §5.2 scrim over the Body band only (N40; `BODY_TOP`/`BODY_BOTTOM` = 163/1022, `:132`), the
  plate at R-S30-1's 272 content box (`DRAWER_ENTRY_WIDTH`, entries built `:491`), 0.18/0.12 s
  `TRANS_CUBIC` `EASE_OUT` on `position.x` + scrim `color:a` (`_animate_drawer` `:855`), the focus
  trap (`_input` `:293` + `_move_drawer_focus` `:890`), and P19's topmost-first `ui_cancel`
  (`_handle_cancel` `:1208`: sheet → drawer → disarm → confirm → open). Close paths: TERMINAL
  toggle, ESC, entry press, scrim press (N38), a cycle press (N38).
- **A3 — DONE.** `ui/station/overview_panel.{gd,tscn}`: block 1 identity plate (`:152`), block 2 the
  3×2 tiles min 300×140 (`:189`, P23 captions verbatim), block 3 hull + repair with `REPAIR` →
  SHIPYARD (`:291`; `focus_repair` `ui/station/shipyard_panel.gd:286`), block 4 the U2 services rows
  (`:328`), block 5 the flavour line (`:381`); P22's vertical `ScrollContainer` wraps the stack.
- **A4 — DONE.** P20 cycle over the six service panes, wrapping from anywhere (`_cycle_module`
  `:942`; from OVERVIEW it enters at ARMORY/LAUNCH). LOG OUT's confirm flow is unchanged. Raw-key
  fallbacks: `T` TERMINAL (`TERMINAL_KEY` `:183`, `_unhandled_input` `:304`), `E` `station_inspect`,
  PageUp/PageDown + pad shoulders prev/next. InputMap registration is close-out's (`project.godot`
  is outside my set).
- **A5 — DONE.** New `tests/test_s30_shell.gd` (12 rows: landing, header, drawer toggle/ESC/entry
  navigation/focus trap, OVERVIEW five blocks/services/tile navigation/REPAIR deep link, cycle wrap,
  cycle-from-OVERVIEW). Moved rows disclosed below; the frozen-clock fixture is T-105's.
- **A6 — DONE.** Two fresh-store runs, both `[SUMMARY] passed=1089 failed=0`.

## Moved gate rows (every one disclosed)
| Suite | Row | Change |
|---|---|---|
| `test_s11_inspector.gd` | `test_the_block_sits_above_the_status_strip`, `test_the_block_carries_the_pinned_nodes`, `test_the_block_reserves_the_a4_4_height` | retired; replaced by `test_the_inspector_band_is_retired:266` (−2 rows) |
| `test_s20_chrome_unify.gd` | `test_ac5_the_inspector_reserves_a_constant_height` | repointed to `test_ac5_the_inspector_band_is_retired_and_the_pane_fills_the_body:421` (A4.4 superseded) |
| `test_s3_auction.gd` | `test_the_shell_mounts_the_auction_pane_behind_its_rail_entry:947` | reads `drawer_entries()`; AUCTION is entry 4 (P16) |
| `test_p2b_fitting_panel.gd` | `test_the_rail_folds_to_six_entries_and_the_fitting_tile_retires:409` | drawer entry count = `MODULE_LABELS.size()+1` |
| `test_s5_batteries_v2.gd` | `test_the_rail_says_armory_and_loads_the_renamed_pane:313` | `PaneTitle` read via `find_child` (B1's reported latent test bug: the title nests under `PaneHeader/TitleBox`) |
| `test_s21_stability.gd` | `test_booting_the_station_writes_nothing_to_user:872` | the two L18/L122 clock rows are now **exact-equality** on a frozen clock (`ClockScript.set_override(FAKE_NOW)` `:881`), T-105's ruling |
| `test_s29_station_panels.gd` | `test_the_shipyard_and_launch_fill_the_band_when_idle` | **no move needed** — `_panels` stays the six service panes, so `panels.size()==6` and the tooltip sink reads hold |

## Deviations / bucket-1 judgements (each with its reversal)
1. **`_panels` stays the six service panes.** OVERVIEW (deck 6) and SERVICES (deck 7) are separate
   nodes, so B1's `_panels.size()==6` rows hold. Reversal: fold OVERVIEW into `_panels` and retarget
   those rows.
2. **R-S30-1 arithmetic:** 272 content + 2×12 `RailMargin` + 2×33 `PanelRaised` inset = a **362** px
   plate (`DRAWER_SLIDE_WIDTH` `:132`), so the content box is x 69..341, not the pin's 68..340 — the
   1 px is §3.4's frame `expand_margin`. Reversal: 254-wide plates in the 270 box.
3. **The drawer's LOG OUT opens the leave confirm (P16), then closes instantly** so the confirm
   (layer 0) is not hidden behind the overlay (`_on_drawer_logout`). Reversal: the shipped direct
   route.
4. **The OVERVIEW identity keeps the shipped scene strings** (`station.tscn`'s name/character line) —
   no station registry exists to resolve §15.5's nine places; the plate chrome + faction glyph/border
   are §15's treatment. Reversal: a registry keyed by `docked_faction`.
5. **SERVICES is a placeholder** (`_make_placeholder`, deck 7): P26's deep-link target has no panel
   this wave (§15.2–§15.4 are S25/S26's). Reversal: drop the SERVICES slot.
6. **The services readouts:** CONTRACTS `%d/3` from `contracts()`, INSURANCE from `insured()`, VAULTS
   `THIS VAULT — %d / %d UNITS` with capacity **40** (U14 base, PROPOSED) and units summed across the
   `vaults` store (no station registry to key it). Reversal: the docked station's own record.
7. **`TERMINAL_KEY = T`** is PROPOSED (no doc pins it). Reversal: the button / `ui_accept` only.
8. **Fixed B1's latent crash** `armory_panel.gd:1728` (`payload[&"icon"]` → `payload.get(&"icon")`):
   a cell hover with no icon key aborted `_on_cell_hovered` (the gate logged it on
   `test_the_cell_tooltips_name_the_cell`). Reversal: revert the guard.
9. **`shipyard_panel.gd` gains `focus_repair()`** (P24's deep link). Reversal: the hull list's first
   row focused.
10. **The three-plate clusters' seat (§8 P1 tokens + §19.3 arithmetic).** REFINERY (`REFINE N` ·
    `REFINERY ALL` · `CANCEL`) and EXCHANGE (`SELL ALL RAW` · `CANCEL` · `SELL`) each hold three
    `ActionPrimary`/`ActionSecondary` 360×56 plates: 3×360 + 2×16 gutter = **1112 px**, right-aligned
    in the 1765 px foot band (x 77..1842) → the cluster seats at **x 730..1842**, the `PaneFooter`
    hint cell (`size_flags_horizontal = 3`) taking x 77..714. **No box is widened, so no fresh P id.**
    LAUNCH's foot cluster is the single 360 `LAUNCH` plate (its `REFUEL`/`RECHARGE` ride the DECK
    CONTROL body box, §3.1); SERVICES has no panel this wave. Reversal: a two-plate cluster.

## Evidence
- `XDG_DATA_HOME=/tmp/s30b2-fA godot --headless --path $VAJB_PROJ res://tests/headless_runner.tscn
  --quit-after 1200` → `[SUMMARY] passed=1089 failed=0`
- the same on `/tmp/s30b2-fB` → `[SUMMARY] passed=1089 failed=0`
- `--check-only` on `ui/screens/station.gd`, `ui/station/overview_panel.gd` → no parse errors
  (autoload identifiers report only in isolation)
- `test_wiring_map.gd` (every scene loads, every `res://` resolves) passes.

## Files touched
- `ui/screens/station.tscn` — header re-lay, body one pane, footer hint; rail + band deleted
- `ui/screens/station.gd` — the drawer, the deck model, OVERVIEW wiring, identity, P19/P20/raw keys
- `ui/station/overview_panel.gd` / `.tscn` — new OVERVIEW pane (the five blocks)
- `ui/station/shipyard_panel.gd` — `focus_repair()`
- `ui/station/armory_panel.gd` — the cell-hover icon guard
- `tests/test_s30_shell.gd` — new suite (12 rows)
- `tests/test_s11_inspector.gd`, `test_s20_chrome_unify.gd`, `test_s3_auction.gd`,
  `test_p2b_fitting_panel.gd`, `test_s5_batteries_v2.gd`, `test_s21_stability.gd` — moved rows above

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| a station registry to resolve §15.5's nine places + the vault key | feature (S24/S26) | `ui/screens/station.gd` `_apply_identity`, `overview_panel.gd` `_vault_units` |
| the SERVICES pane (§15.1 strip + §15.2–§15.4) | feature (S25/S26) | `ui/station/services_panel.*` |
| `TERMINAL_KEY`'s InputMap row + `station_inspect`/prev/next rows | close-out (T-101/T-110) | `project.godot` |
