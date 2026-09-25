# S8-Q2 report — physics defer, exchange quote/name, copy bundle, warning ledger

Worker: S8-Q2. Tree: `f041186` (Q1's `761/0` + §21's dispositions). Method: the shipped
scenes/probes on **scratch stores** (`XDG_DATA_HOME=$(mktemp -d)`; the suite repoints
`save_path`). Gate ran **twice**, `[SUMMARY] passed=770 failed=0` on each (761 + this
suite's 9), 0 failed, live `profile.cfg` (mtime 17:41, md5 `a58c9b4a…`) / `economy_log.txt`
(15:27, `af78309a…`) untouched. The Q0 ram probe re-run: **0 refusals** (was 32: 24
`body_set_shape_as_one_way_collision` + 8 `body_set_shape_disabled`), fragments spawn.

## M1 — the fragment's shape is taken outside the flush

- `game/asteroid.gd:` `setup(..., size_class := SIZE_ANY, defer_shape := false)`;
  `_build_look(size_class, defer_shape)` computes `_radius` and either calls
  `_install_shape.call_deferred()` or `_install_shape()` directly. `_install_shape`
  creates + adds the `CollisionShape2D` (the old `add_child(_shape)` line, Q0's exact seam:
  `asteroid.gd:347 _build_look`). `world_radius()` returns `_radius` while the node is
  pending, so the cleave's placement math and the collision radius are known before the node.
- `asteroid_field.gd:_new_rock` threads `defer_shape`; `_cleave` passes `true`, so every
  fragment is born deferred. A **physics-frame call defers even without the flag**
  (`Engine.is_in_physics_frame()`), so a rock spawned from any physics path is safe too.
- Why not `add_child.call_deferred(_shape)`: it leaks the orphan shape's RID whenever the
  body is freed before the flush (the gate leaked **7282 `GodotShape2D` RIDs**). Deferring
  the *install method* leaks nothing; a freed body's callable is skipped.
- Measured: a rock built outside the flush carries `Shape` at once (radius 42.000 on the Q0
  medium); a fragment is born with `Shape` absent and `world_radius() > 0`; `_install_shape`
  then adds a circle of exactly that radius. The engine's own refusal count is the probe's
  (0, above) — the runner is synchronous and cannot run frames, so the suite pins the
  deferral that removes them, not the stderr count.

## M2 — display names in sale copy

- `ui/station/exchange_panel.gd:554 _confirm_text` and `:656 _announce_sale` now print
  `_item_name(...)` (the hold rows' own resolver), not `String(id).to_upper()`.
- Measured (Q0 exchange probe): strip `SELL 1 CHROMIUM ORE — GROSS 25 · FEE 10 · YOU GET 15`,
  SOLD `SOLD · 1 CHROMIUM ORE · +15 CR`; no `MINERAL_CHROMIUM` anywhere in the copy.
  `CONFIRM_FORMAT`'s shape is unchanged (only the name/numbers inside it).

## M3 — the confirm quote is honored

- `game/exchange.gd:sell(profile, item_id, qty, now, rng = null, quoted_total := -1)`.
  `-1` is today's path, byte-identical. `>= 0` takes the **gross total the strip showed**,
  then re-derives `fee`/`paid` through `commission_for` (the one pricing function owns the
  arithmetic), so the preview's gross/fee/paid all commit. (The parameter is one int; gross is
  the only figure from which the strip's other two reconstruct through the pricing family.)
- `exchange_panel.gd` captures the quote at preview in `_quoted` (`_refresh_trade`) and
  passes `_quoted[&"gross"]` at press.
- Measured (Q0 exchange probe, demand re-rolled to 0.6 between preview and press):
  credits **6001 → 6016, credited 15 = the promised `YOU GET` 15** (was `+5`).

## O1/O2 — nothing built (bucket 3, the owner's UX call)

Q0 measured the ARMORY drag committing (`drag_inventory → can_drop → drop` →
`set_battery_groups`, probe `[[0]]` → `[[0,1]]`) and FITTING declaring zero drag handlers.
Per §21 ("owner UX call; no FITTING drag code in S8") and the task's own instruction, **no
production code was added for O1/O2**; `fitting_panel.gd` is untouched. The suite pins the
commit through the direct handlers and the empty FITTING handler list.

## Copy law

- `ui/station/refinery_panel.gd`: `_conversions_text(count)` returns `1 CONVERSION` at 1,
  `0 CONVERSIONS` at 0, `%d CONVERSIONS` otherwise; used by the stepper (`_refresh_box`) and
  the `STATUS_READY` strip (`_on_row_focused`, format now `%s`). `TAG_FORMAT`'s plural was not
  in the QA's `stepper/status` finding and is left.
- Catalogue spelling: no `Mk1`/`MK1` exists in `ui/` or the catalogues (Q0: not reproduced);
  the suite guards `module_catalog.module(&"w_cannon").name == "Cannon MkI"`. Nothing to fix.
- `NEXT RESTOCK <m:ss>`, `REFINERY ALL` and every `.tscn` untouched (no `.tscn`/`hud.gd` write).

## Warning ledger

- `game/module_catalog.gd:636/643/651`: the three `INTEGER_DIVISION` rows now carry
  `@warning_ignore("integer_division")`, the project's own idiom (`refinery.gd:55`,
  `auction.gd:406`, `world_clock.gd:38`). **Deviation (bucket 1 mechanism):** the brief said
  `intdiv`, but 4.7.2's GDScript has no `intdiv` global or `int` method (verified: parse
  error), so the annotation is the only zero-behaviour-change cure. Measured 3 → 0 warnings.
- `game/projectile.gd`: `trail_read`'s `source` param → `origin`, its `scale` local →
  `quad_scale`, `_shape_trail`'s `material` local → `particle_material` (3 rows, QA's
  1485/1489/1759; Q0 had measured 2). Measured 3 → 0 warnings. Renames only.
- `game/player_state.gd:33-35`: the stale "ammo-slot order `weapons.gd` reads" comment now
  names Q1's resolution (`_launch_ammo_slot` against the launched fit; §21 H1).
- **BLOCKED — `game/weapons.gd` (bucket 2, file-set gap).** The task orders the five S7
  `position` → `barrel` param renames, but `weapons.gd` is **not** in Q2's
  `VAJB_WORKER_FILES` (it is Q1's file; the hook refused the edit, measured). Ready to apply:
  `_barrel_affixes:1886`, `_slot_of_barrel:1902` (its local `barrel` at `:1905` must become
  `ordinal`), `_ammo_available_at:2041`, `_consume_ammo_at:2071`, `_barrel_interval:2094`.
  The file carries 37 warnings at HEAD; R1 must read this as the wave's unmet AC8 half.
- Note: `weapons.gd`'s ledger may also carry the `position` params Q1's H1 added
  (`_launch_ammo_slot`, `_ammo_available`); a set-grown rename pass should sweep all 15
  `position`-parameter functions, not only the S7 five, if AC8 is read against HEAD.

## Tests

- New: `tests/test_s8_qa_fixes.gd` (+ `.uid`), 9 rows — M1 (deferral, radius, installer),
  M2 (strip + SOLD names, no raw id), M3 (panel quote under a forced re-roll; the default
  `-1` path; a direct quoted-gross sale), the `1 CONVERSION`/`2 CONVERSIONS` stepper, the
  catalogue spelling, the ARMORY direct-handler commit + FITTING's zero handlers, and the
  three ledger files' `--check-only` (nested engine, exit 0).
- None of the existing 761 rows moved; `test_p1_refinery.gd:192` untouched.

## Notes for R1 / the orchestrator

1. **Bucket 2 — grow Q2's set or hand `weapons.gd` to F1.** Nothing else in AC8 is missing.
2. `@warning_ignore` vs the brief's `intdiv` (bucket 1) — please record the deviation.
3. Gate leak delta +6 ObjectDB / +2 resources vs the stashed baseline (32/12 vs 26/10), from
   the deferred installs queued in synchronous tests (no shape RID leak); ambient and benign.
4. The runner is synchronous, so M1's "collides next step" is pinned as deferral + known
   radius + the installer's circle; the Q0 ram probe is the 0-refusal measurement.
5. Untouched by design: O3 (no factor in §21), O4/O5, the station scene, `REFINERY ALL`,
   `NEXT RESTOCK`, every `.tscn`, `hud.gd`, and `fitting_panel.gd`.

Files touched: `game/asteroid.gd`, `game/asteroid_field.gd`, `game/exchange.gd`,
`game/exchange_panel.gd` (ui/station), `ui/station/refinery_panel.gd`,
`game/module_catalog.gd`, `game/projectile.gd`, `game/player_state.gd`,
`tests/test_s8_qa_fixes.gd` (+`.uid`).
