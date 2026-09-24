---
slice: S3
worker: S3-K3
model: ""             # the orchestrator fills what actually ran
status: actionable    # the Follow-ups table is LOW only; K4 tickets it (T-93+)
gate: "482/0 → 491/0 (exit 0 both runs; live profile.cfg md5 unchanged)"
---

# S3-K3 report — rolled identity everywhere a fit is read, and the instance-true round trip

## Result

Every surface that reads a fit now reads the **instance**: FITTING's OWNED MODULES rows
aggregate by `base_id` with `OWNED ×<n>` summed over the bag's own keys and gain a `▸`
expander whose sub-rows are the instances (15 §7's rolled name, the rarity tint, the
instance's own ACTION); the pane's hover/selection line carries the rolled name in its
tint with 15 §7's two-line stat block under it; the shipyard's plate hover does the same
and adds the block to its own stat column. Install/swap/remove are instance-true through
the §13 transactions (the cell holds the instance id, REMOVE/SWAP hand the same record
back at `count` 0 → 1 with its affixes intact, two same-base instances stay
distinguishable), and every legality read in the pane goes through
`PlayerProfile.base_fit` first.

Measured by the house gate, this machine, twice:

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=491 failed=0          (exit 0, run 1 and run 2)
```

Before: the K2 closing figure `passed=482 failed=0`. The delta is exactly arithmetic:
**+7** are `tests/test_p2b_fitting_panel.gd` (20 → 27, its four moved name expectations
plus seven new instance tests) and **+2** are `tests/test_p2b_services.gd` (12 → 14);
`482 + 9 = 491`. Per suite: `test_p2b_fitting_panel` **27/0**, `test_p2b_services`
**14/0**, both together **41/0**.

**The live account is untouched (T-93).** `md5(user://profile.cfg)` before the first
gate run and after the last: `9182b34ffe0e51dc2ea8fa3051de4ae2` /
`9182b34ffe0e51dc2ea8fa3051de4ae2`; `md5(user://economy_log.txt)`:
`38b05767f005bafab286e4bbe8ed1764` / `38b05767f005bafab286e4bbe8ed1764` (both identical
to K2's closing readings). This pass ran **no bespoke probe**: every measurement below is
a house-gate suite (whose scratch store the runner owns), so nothing here boots the live
path — the only `user://` reader is `headless_runner.tscn`, as the rule allows. No probe
file was created, so none is left in the tree.

Nothing outside the declared set was edited: `git status` shows the four files below plus
the two files already modified/deleted when this pass opened (`S3_prompts.md`,
`RCLONE_TEST`) and the pre-existing untracked root strays. `project.godot`,
`docs/gameplay/18_engine_spec.md`, `vajb-orbit/assets/`, `addons/` and the theme are
untouched, no `.tscn` was edited, `player_profile.gd` needed no change (below), and no
affix reaches a flight stat: the only flight bridge, `game.gd:_profile_fit`
(`game.gd:351-375`), already resolves every entry through `base_module_id`, and no file
in that path is in this diff.

## What the nine new tests pin

`tests/test_p2b_fitting_panel.gd` (+7):

| Method | What it measures |
|---|---|
| `test_the_owned_rows_expand_into_one_subrow_per_instance` | one aggregate row per base id; `OWNED ×2` summed over the bag's two keys while `module_count(base_id)` reads **0**; a multi-instance row keeps the catalogue's name; the expander's two glyphs; two sub-rows with their own rolled names (`Keen Plasma Coil of the Whale` is asserted literally), their own tint tokens and their own ACTION; an empty cell of the right type turns both into `FIT` |
| `test_a_single_instance_row_carries_its_rolled_name_and_no_expander` | the pin's single-instance rule: no expander, no sub-row, and the row itself carries the instance's rolled name in its tint |
| `test_pressing_a_subrow_fits_that_instance_and_keeps_the_other` | the cell holds **that instance's id**, its record survives at `count` 0, its sibling stays in the bag, the aggregate follows the bag, and the footer names the rolled instance |
| `test_remove_and_swap_hand_back_the_same_instance` | L80 through the pane: the displaced instance comes back with the same id, rarity, prefix rows and suffix ids (`count` 0 → 1), and REMOVE returns the fitted one the same way |
| `test_the_selection_line_and_block_read_the_fitted_instance` | the rolled name in the Magic token; the block equals `BASE DRAW 2 · SHIELD +200 · REGEN +4` / `STURDY · SHIELD +15 %` / `OF THE WHALE · +50 max hull structure` literally; the cell keeps the instance id while `base_fit` gives `s_light`, and the judged fit's power budget equals the delivered fit's (no affix moves a draw) |
| `test_the_meter_reads_an_instance_fit_through_its_base_ids` | the translation (K0 H6): the idle meter reads the base-id judgement, and the Lancer's second plasma **instance** is refused with 09 §2's over-by wording — a draw-0 misread would have accepted it |
| `test_the_focus_order_carries_the_expander_and_its_subrows` | the walk is cells → row → expander → sub-rows → footer, and the ring still enters at the top-left cell |

`tests/test_p2b_services.gd` (+2):

| Method | What it measures |
|---|---|
| `test_the_hover_line_and_block_read_a_rolled_instance` | the hover line carries `Keen Laser MkII of the Whale` and the base id's held total, the block equals the literal three-line block, an empty cell stays `EMPTY` with a blank block, and the cell keeps the instance id while `module_count(base_id)` still cannot see it |
| `test_the_hover_block_is_the_panes_own_and_follows_the_plate` | the block is a node of the pane's own stats column: shown on hover, hidden on exit, and the plate (its size, its disabled state) and the grid are untouched by it |

Moved expectations (same counts, nothing padded): FITTING's four name assertions now read
15 §7's rolled name (`_rolled(...)` / the catalogue's own casing) instead of the
upper-cased catalogue name — `test_the_footer_line_reads_the_selected_cell`,
`test_an_unfit_hulls_first_install_through_the_pane_succeeds`,
`test_a_per_cell_install_lands_on_the_cell_it_was_given`,
`test_a_successful_swap_does_not_leave_the_refusals_line` — and the services suite's three
(`_display_name` replaces `_module_name`, and the aggregate is read through the suite's own
`_owned_total`, the pane's rule). `test_p2b_services.gd`'s hover-line loop derives its
expected count from that aggregate now, which is the assertion that caught the delivered
laser's three base-keyed units sitting beside the new instance.

## What the pane's own write/read discipline still holds

- The pane still requests through the two composed calls only
  (`test_the_pane_writes_only_through_the_two_composed_calls` is unchanged and green);
  every new id it reads (`instance`, `instances_of`, `base_fit`, `base_module_id`) is a
  read, and `module_count` is no longer used to count a base id.
- The shipyard still reads and never writes (`test_the_shipyard_reads_the_fit_without_ever_writing_it`).
- `OWNED ×<n>` is a sum over the bag's own keys through `base_module_id` in both panes
  (`fitting_panel._owned_total`, `shipyard_panel._owned_total`), which is the bucket-1 fix
  K1's report named: no §15 accessor was added and `player_profile.gd` is untouched.
- `base_fit` hands out plain Arrays while `fit_for` hands out typed ones (K1's API note):
  nothing in this pass compares the two — every judgement goes through `fit_legal`, and the
  one fit the tests compare is compared by its **power dictionary** and its cell values,
  never with `==` against a typed array.
- K2's note on `ModuleCatalog.rarity_mult` / the price helpers: neither pane has a price
  column (FITTING's §5.3 anatomy carries icon / name / `OWNED ×<n>` / ACTION, and the
  shipyard's hover line carries no price), so the price helpers have no caller here; the
  rarity work this pass does is the **tint**, through `Auction.rarity_token` /
  `rarity_fallback` (the same three tokens §5.10 names).

## Deviations from SLICE.md / the brief

Every one is bucket 1 (inside a pinned acceptance) unless marked; none changes a pinned
number or wording, a `VAJB_WORKER_FILES` set, the tests-that-move list or any `docs/` text.

1. **The rolled name's case.** The selection line and the shipyard hover now print 15 §7's
   rolled name verbatim (title case, `Laser MkII`), where they used to upper-case the
   catalogue name (`LASER MKII`). §7's grammar is title case and the AUCTION's rows already
   print it so (`auction_panel` renders `name` unmodified); the alternation would have been
   two cases for one name. Reversal: `.to_upper()` at the two `_instance_name` call sites
   (and the four moved expectations move back).
2. **The aggregate row's own ACTION acts on the base id's first held instance.** §5.3 says
   the row keeps `OWNED ×<n>` "as today" and gains the expander, but not which instance a
   press takes when the base id owns several. Taking the bag's first is deterministic, and
   for a base-keyed record (every pre-v6 fixture) it *is* the base id, so the pre-instance
   surface is byte-identical. Reversal: one guard refusing the aggregate press when the base
   id owns more than one instance.
3. **A single-instance row carries the rolled name.** The pin says a base id owning exactly
   one instance "shows no expander, so today's single-instance surface is unchanged in
   shape" — the shape is unchanged (no expander, no sub-row), and the *name* is unchanged
   for a Common (which is what the v5 migration mints: 15 §7's Common name is the plain 09
   name), so a migrated account sees exactly what it saw before; only a rolled Magic/Rare
   drop now reads its own name on the row. Reversal: print the catalogue name on the
   aggregate row whenever the base id owns any instance (one line).
4. **The stat block's format is this pass's (proposed).** The docs delegate it: 15 §7 says
   "the UI panel spec will lay out the two-line stat block", and §5.3 names only its
   contents ("the base module's catalogue stats plus one line per rolled affix"). Built,
   mechanically from the catalogue: base line `BASE DRAW <n>` plus one token per `effects`
   entry (`shield_add` 200 → `SHIELD +200`, `damage_add` 0.15 → `DAMAGE +15 %`,
   `speed_mult` 1.15 → `SPEED ×1.15`); a prefix line `KEEN · DAMAGE +12 %` from 15 §3's own
   `stat`/`unit` and the value the record rolled; a suffix line `OF THE WHALE · +50 max hull
   structure` with 15 §4's perk prose verbatim. A row with no `effects` (every weapon row)
   shows its draw alone. Reversal: one formatter per pane.
5. **The block is a script-built `Label`, not a scene node.** `fitting_panel.tscn` and
   `shipyard_panel.tscn` are outside this worker's set (and frozen for K3): FITTING's block
   is added under `%SelectionLine` inside `%PaneFooter`, the shipyard's under
   `%HardpointSlots` inside `%ShipStats`, both in `_ready`. This is the pane's own existing
   precedent (the rows and their cells are built in script). Reversal: move both nodes into
   the scene files and delete `_mount_stat_block` / `_mount_hover_block`.
6. **The stat formatter is duplicated between the two panes** (~70 lines: `stat_line`,
   `stat_label`, `signed_percent`, `signed_number`, `_affix_lines`, `_rows_of`,
   `_row_id_of`). A shared `ui/station/` helper would be better and **is a file outside this
   worker's set** — the same shape as K2's deviation 6 for the header-fit machinery, and the
   repo's precedent sanctions a byte-equivalent copy. Reversal: one import, two deletions.
7. **The shipyard's block is the pane's own node, not a second line in the shell's strip.**
   The shell's `status_requested` channel carries a `String` plus a danger flag: no tint and
   no second line, so the block cannot travel up it without changing the channel contract.
   Reversal: append the block's lines to the status string (the strip's `Label` renders `\n`
   only if the layout grows for it).
8. **`player_profile.gd` is untouched.** The two aggregates are summed in the panes (see
   above), so the §13/§15 API gained nothing. Reversal: none owed — the file is in the set
   but the work did not need it.
9. **Both suites hand back `_instance_counter`** (a field the pre-existing borrowed-field
   lists do not carry), the way `test_s3_auction.gd` does, because these suites mint
   instances; no later suite sees a number this pass spent. Reversal: two lines.
10. **No `.tscn`, no theme, no `docs/` edit.** STATION_HUB §5.3's tick and CONTRACTS §9's
    figure are the developer session's and K4's; the number to write is the measured **491**.

## Evidence

```bash
# the full gate, twice, exit 0 both runs
... headless_runner.tscn -> [SUMMARY] passed=491 failed=0
... headless_runner.tscn -> [SUMMARY] passed=491 failed=0

# per suite (full basename, the L95/L99 rule)
... --suite=test_p2b_fitting_panel -> passed=27 failed=0
... --suite=test_p2b_services      -> passed=14 failed=0
... --suite=test_p2b_services --suite=test_p2b_fitting_panel -> passed=41 failed=0

# the live account (T-93), before the first run and after the last
md5(user://profile.cfg)     9182b34ffe0e51dc2ea8fa3051de4ae2  (unchanged)
md5(user://economy_log.txt) 38b05767f005bafab286e4bbe8ed1764  (unchanged)

# four full runs' exit-time ledger - the warning is noisy run-to-run and pre-existing
# (K2's own closing reading was 38 leaked / 18 resources)
22 ObjectDB instances leaked / 10 resources still in use
84 / 36
52 / 20
38 / 18     # identical to the pre-pass ledger
```

## Files touched

- `vajb-orbit/ui/station/fitting_panel.gd` — the instance surface: `_owned_total` /
  `_instances_of`, the `_row_signature` rebuild key (an existing base id whose instances
  moved rebuilds the rows), the aggregate row's single/multi name rule, `_make_expander`
  and `_on_expander_pressed` with the `_expanded` set, `_build_subrows` + the three
  sub-row handlers, `_instance_record` / `_instance_name` / `_rarity_token` /
  `_rarity_color`, the script-built stat block (`_mount_stat_block`,
  `_refresh_stat_block`, `_stat_block_of`, the `stat_line` formatter), the translated
  `_base_fit` / `_candidate_slot` on every legality read, and the tinted selection line
- `vajb-orbit/ui/station/shipyard_panel.gd` — `hover_line` reads the rolled name and the
  base id's held total (`_hover_entry`, `_hover_name`, `_instance_record`,
  `_owned_total`), the pane's own hover stat block (`_mount_hover_block`,
  `_refresh_hover_block`, `_clear_hover_block`, `hover_block_text`, the duplicated
  formatter), and `_set_layout_grid` clears a block whose plates are gone
- `vajb-orbit/tests/test_p2b_fitting_panel.gd` — 20 → 27 tests; the fixture mints through
  `add_instance`; the four moved name expectations; `_instance_counter` handed back
- `vajb-orbit/tests/test_p2b_services.gd` — 12 → 14 tests; `_display_name` /
  `_owned_total` / `_block`; the three moved expectations; `_instance_counter` handed back

**Untouched:** `vajb-orbit/autoload/player_profile.gd` (in the set, not needed),
`ui/screens/station.gd`, both `.tscn` files, the theme, `docs/`, and every frozen path.

## Follow-ups

LOW only; the brief gives K4 the LOW rows (next free `T-93`).

| Item | Kind | Where |
|---|---|---|
| The stat formatter and the affix-line reader are duplicated between the two panes (~70 lines each); a shared `ui/station/` helper would remove the drift risk, but that file is outside this worker's set | LOW (duplication) | `vajb-orbit/ui/station/fitting_panel.gd:1395-1520`, `vajb-orbit/ui/station/shipyard_panel.gd:570-700` |
| The `▸` expander is a `Button` nested inside the row `Button`, relying on the child's own `MOUSE_FILTER_STOP` winning the hit test; it works, but a sibling wrapper would be structurally safer and would change the rows' node shape for probes | LOW (structure) | `vajb-orbit/ui/station/fitting_panel.gd:821` |
| The expander carries no theme variation (the row `Button` carries none either); if a chrome pass gives FITTING's rows a variation, the expander should follow | LOW (chrome) | `vajb-orbit/ui/station/fitting_panel.gd:821-833` |
| The exit-time ObjectDB/resource ledger is noisy run-to-run (22/38/52/84 and 10/18/20/36 across four full runs) and grows with any suite that rebuilds rows in a single frame — the pane frees rebuilt rows with `queue_free`, which never drains in a one-frame suite. Not a gameplay leak (a real frame drains it); K4 may want to measure whether the wave's own suites are the only source | LOW (gate ledger) | `vajb-orbit/ui/station/fitting_panel.gd:745` |
| `tests/probe_w3_services.gd` prints its own upper-cased labels (`_module_name(...).to_upper()`) and reports `module_count(base_id)` as the "owned" figure, which is now the wrong accessor for an instance-keyed bag; it asserts nothing, so nothing fails, but its output is stale evidence | LOW (stale probe) | `vajb-orbit/tests/probe_w3_services.gd:147-210` |
