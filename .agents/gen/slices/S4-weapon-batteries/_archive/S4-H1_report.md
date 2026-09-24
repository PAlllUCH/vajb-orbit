---
slice: S4
worker: S4-H1
model: deepseek/deepseek-v4-flash
status: actionable
gate: "493/0 → 508/0 (the new suite's 15 tests; the p2b1 suite's own count is unchanged at 11)"
---

# S4-H1 report — the battery strip and the two bulk transactions

## Result

OUTFITTING's FITTED WEAPONS strip is a **battery list** (STATION_HUB §5.1's 2026-09-23
amendment): one row per battery of identical weapons grouped by `base_id` in first-cell order,
reading `3× LASER MKII · W1·W2·W3 · OWNED ×<n>`, then one read-only `W<n> — EMPTY` line per
empty W cell; each battery row carries `▸` / `FIT ALL` / `REMOVE ALL` / `SWAP ALL` (that focus
order) and a per-barrel expander that restores the P2-B1 single-cell lines with their own
REMOVE. `PlayerProfile.fit_battery` / `clear_battery` (CONTRACTS §16 rules 7-8) implement the
batch: `instances_of(base_id)` in creation order paired into ascending W cells, one
`fit_module_at` / `clear_fit_slot` per cell, atomic over the fit **and** the bag.

**Gate: 508/0, twice, identical** (S3's 493 + the new suite's 15). The live `profile.cfg` md5
is `3e6ee8d7e7145c4e37bbd8dc90f62f9b` and the live `economy_log.txt` md5 is
`eef2929404d1b3b2a4f30565e7b183b2` — both unchanged from the wave-start record after every
run.

## What was built, with the numbers

| Deliverable | Where | Measured |
|---|---|---|
| `fit_battery(ship_id, base_id, indices)` | `vajb-orbit/autoload/player_profile.gd:947` | 3-cell batch over 3 instances; refuses (false, nothing written) for a hull outside the nine / a W-less hull (`slot_capacity == 0`; **no player hull is W-less** — measured over `ShipFit.SLOT_GRIDS`: every one of the nine carries at least one `W`), an index outside `0..capacity-1`, a repeated index, an empty list, and a bag shorter than the cell list |
| `clear_battery(ship_id, base_id)` | `autoload/player_profile.gd:983` | empties exactly the cells whose **stored** entry resolves through `base_module_id`; a hull holding a laser and a cannon keeps the cannon fitted (measured in `test_clear_battery_empties_only_the_named_bases_cells`) |
| the rollback | `autoload/player_profile.gd:1012` (`_restore_fit_and_bag`) | `fit_for` + `modules()` snapshotted before cell 1, restored whole through `set_fit` / `set_modules` on any refusal |
| the strip | `ui/station/outfitting_panel.gd:660-1042` | 7 pre-built rows (`_max_weapon_cells()`), 36 nodes each — **253 measured**, never added to or freed |
| grouping | `outfitting_panel.gd:823` | `[w_laser, w_cannon, w_laser]` → `["battery w_laser [0, 2]", "battery w_cannon [1]"]` (printed by the suite) |
| bulk actions | `outfitting_panel.gd:1081/1104/1126` | `FIT ALL` = battery cells then empty W cells, cut to `min(owned, cells)`; `SWAP ALL` = the battery's own index list; `REMOVE ALL` = `clear_battery` |
| refusal copy | `outfitting_panel.gd:142-144` | the three literals byte-equal to `fitting_panel.gd:147-149` (asserted by preload, not by eye) |
| overload line | measured | `11 / 8 PWR — OVER BY 3` (`fit_legal` draw 11, out 8) rendered for a railgun battery on the Vanguard, with the fit and the bag byte-identical afterwards |
| catch-all | measured | reachable through `SWAP ALL`: a 3-barrel battery with 2 bag instances renders `REFUSED · FIT ILLEGAL` and writes nothing |
| new suite | `tests/test_s4_batteries.gd` | 15 tests: grouping (2), the bag figure (1), the bulk round-trip and its two refusals (4: `FIT ALL`+`REMOVE ALL`, `SWAP ALL`, a base with no row, a bag too short for the battery), the batch's atomicity and guards (2), the clear transaction (1), the refusal copy (2: byte-equality + the rendered overload line), the expander (1), the fixed node set (1), the focus order (1) |

## Deviations from SLICE.md / the brief

1. **`refresh_profile` also follows `&"modules"`** (`outfitting_panel.gd:217`). The battery
   row's `OWNED ×<n>` and its two spending actions read the bag (§5.1), so a bag write must
   move them; before this wave the strip ignored that key (it read the fit alone). The p2b1
   refresh test's last assertion therefore **inverted** (it asserted the opposite), and a
   mutation run (dropping the key) turns it red — that is the acceptance the move was for.
   *Reversal: drop the key and the strip shows a stale bag count.*
2. **`SWAP ALL` passes the battery's whole index list**, with no `min(owned, cells)` — §5.1
   gives the `min` to `FIT ALL` only. A bag that cannot cover every barrel is therefore
   refused with the catch-all rather than re-seating part of the battery. *Reversal: cut the
   list like `FIT ALL`, or disable `SWAP ALL` below `cells` instances; one line.*
3. **Two success lines are this pane's own copy.** The pin words the three refusals and not
   the successes: `STATUS_FIT_ALL := "FITTED ×%d · %s"` and
   `STATUS_SWAP_ALL := "SWAPPED ×%d · %s"` (`outfitting_panel.gd:128-129`); `REMOVE ALL`
   reuses the existing `STATUS_REMOVED`. *Reversal: one constant each.*
4. **`OWNED ×<n>` is `instances_of(base_id).size()`**, the brief's own pin. Measured
   divergence, reported not resolved: a bag record that **stacks** (`count` 2 from two
   `add_module` calls) is one instance and one cell's worth — the row reads `OWNED ×1` while
   `module_count` reads 2 and FITTING's `owned_total` (which sums counts) would say 2. The
   strip's figure is exactly the number of cells one batch can pair, so the actions agree with
   the reading; a v6 bag is instance-keyed (`migrate_module_instances` splits count-N records)
   and the two readings coincide there. *Reversal: sum the counts and cap the batch's index
   list at the pair-able instances.*
5. **`fit_battery` refuses a repeated index** (a cell is one barrel). The pin names an index
   outside capacity but not a duplicate; refusing writes nothing and is the conservative
   reading. *Reversal: dedupe instead.*
6. **The rollback restores an absent stored fit through `clear_fit`** rather than writing an
   all-empty one back (`_restore_fit_and_bag`). The pin names `set_fit`; a hull that held no
   fit would otherwise gain an empty `fits` entry, which `fit_for` hides but `fits()` and the
   save file would show. The pane always seeds first, so the strip's own path takes the
   `set_fit` branch. *Reversal: always `set_fit`.*
7. **The `.tscn` is unchanged.** §16 rule 10 makes the strip's node set script-built (it was
   already), so `outfitting_panel.tscn` gained nothing; the file stays in the set because the
   deliverable was allowed to touch it.
8. **`.uid` sidecar added** for the new suite (`tests/test_s4_batteries.gd.uid`), generated by
   a headless `--editor --import --quit` pass (no editor was running). No other tracked file
   moved in that pass.

## Tests that moved

| File | Move |
|---|---|
| `tests/test_p2b1_outfitting_panel.gd` | the four per-cell strip tests now read battery rows: the row helpers are `_strip_row`/`_strip_main`/`_strip_text`/`_strip_control`/`_cell_line`; `REMOVE` becomes `REMOVE ALL`; **the empty-cell assertions stayed** (`W2 — EMPTY`, `W3 — EMPTY`, and the emptied `W1 — EMPTY`, now also asserting the line carries no visible control). The refresh test's `modules` assertion inverted (deviation 1). Test count unchanged: 11 → 11 |
| `tests/test_s4_batteries.gd` | new, 15 tests |
| `tests/test_engine2_wiring.gd`, `tests/test_engine2_weapons.gd` | untouched — `fitted()` is H2's seam and no S4-H1 file touches it |

## Evidence

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=508 failed=0        (run A)
[SUMMARY] passed=508 failed=0        (run B, identical)
[s4-batteries] mixed fit rows=["battery w_laser [0, 2]", "battery w_cannon [1]"]
[s4-batteries] overload line=11 / 8 PWR — OVER BY 3 (fit_legal draw=11 out=8, over by 3) | cells=["w_railgun", "", ""]
[s4-batteries] fixed strip: 7 rows, 253 nodes (36 per row)

$ md5sum ".../Vajb Orbit/profile.cfg"      # before and after every run
3e6ee8d7e7145c4e37bbd8dc90f62f9b           # = the wave-start record
$ md5sum ".../Vajb Orbit/economy_log.txt"
eef2929404d1b3b2a4f30565e7b183b2           # unchanged
```

**Scratch-store rule (T-93, the S3 incident).** **No `--script` probe was run at all** — every
measurement above came from `headless_runner.tscn`, whose `_seed_scratch_store` repoints
`save_path` at `user://_gate_scratch/profile.cfg` and calls `reset_to_defaults` + `flush`
before the first suite loads (including the `--suite=` runs), and whose suites then repoint
`save_path` at their own scratch file in `suite_setup` and hand it back after a flush in
`suite_teardown`. The two live-store md5s were read before the first run and after the last.

Mutation check (the tests bite): dropping `or key == &"modules"` from `refresh_profile` makes
`test_p2b1_outfitting_panel.gd.test_profile_changed_drives_the_refresh` fail
(`a modules write moved the battery's bag figure`) and nothing else; restored immediately and
re-verified at 508/0.

One pre-existing error line, **not mine and not fixed**: `SCRIPT ERROR: Cannot call method
'call' on a previously freed instance` at `tests/test_weapon_fx_f4.gd:178` (the suite still
passes; `game/weapons.gd` is H2's file).

## Files touched

- `vajb-orbit/autoload/player_profile.gd` — `WEAPON_SLOT`, `fit_battery`, `clear_battery`,
  `_restore_fit_and_bag` (+ the header note)
- `vajb-orbit/ui/station/outfitting_panel.gd` — the strip's constants, the fixed row set
  (`_build_strip_row`/`_build_cell_line`/`_make_expander`/`_make_strip_action`), the rewrite
  pass (`_refresh_strip` and the `_show_*`/`_hide_*` helpers), the grouping helpers, the three
  bulk actions, the read-backs (`strip_rows`, `battery_row_index`, `expanded`,
  `toggle_expander`), `focus_primary`, and the `&"modules"` refresh key
- `vajb-orbit/tests/test_p2b1_outfitting_panel.gd` — the strip tests moved to battery rows
- `vajb-orbit/tests/test_s4_batteries.gd` (+ `.uid`) — new, 15 tests
- `vajb-orbit/ui/station/outfitting_panel.tscn` — **unchanged** (deviation 7)

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| Nine stale probes read the pre-S4 strip node shape (`get_child(i) as HBoxContainer` + `^"Remove"`): `probe_p2b1_panel_fit.gd`, `probe_r1_p2b1_edge.gd`, `probe_r1_p2b1_edge2.gd`, `probe_r1_p2b1_edge3.gd`, `probe_r1_p2b1_fit.gd`, `probe_r1_p2b1_layout.gd`, `probe_r1_p2b1_persist.gd`, `probe_r1_p2b1_review.gd`, `probe_w5_layout.gd`. They are not in the gate and are historical repro instruments (L78/L80 cite two of them), so H1 did not rewrite them; each needs its strip reads moved to `Main/Text` + `Main/<control>` and the cell lines, or a LOW row saying they are spent | [HARNESS] | `vajb-orbit/tests/probe_*.gd` |
| `SWAP ALL`'s short-bag refusal (deviation 2) is a reading the owner may want to overrule — a partial re-seat, or a plate disabled below `cells` instances | [SPEC] | `ui/station/outfitting_panel.gd:1104`, `docs/design/STATION_HUB.md:417` |
| The `OWNED ×<n>` divergence (deviation 4) — §5.1's "the same reading §5.3's rows show" holds only for an instance-keyed bag | [SPEC] | `ui/station/outfitting_panel.gd:860`, `docs/design/STATION_HUB.md:404-406` |
