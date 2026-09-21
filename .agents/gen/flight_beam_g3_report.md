# G3 — warning sweep report (wave: flight feel & beam polish)

Date: 2026-09-21. Worker: G3 (coder, warning sweep).
Law: `.agents/gen/flight_beam_wave_task.md` (hard rules, worker table), then `AGENTS.md`
and `docs/CONTRACTS.md` §9.

**Deliverable status.** All eight shadowing warnings in G3's file set are cleared, by
rename only; behaviour byte-identical. The proof is **source-level** (`probe_g3_shadow.gd`,
25/25, cache- and parse-independent) plus a rename-only `git diff`. The `--headless --debug`
ledger corroborates in a **healthy** run: it printed zero `at:` rows for G3's five scripts,
against eight before. The closing gate is `passed=288 failed=1` (289 tests, up from the
wave's 277) with **zero failures in any suite that exercises G3's files**; the one red is
G1's new strafe assertion in G1's own suite (§9).

**Two things the orchestrator must read:**

1. **The ledger can under-report.** A parse error anywhere upstream silently deletes the
   warning rows of every file that depends on it (§3). Ledger *zeros* are not proof; the
   static guard is. Two files outside G3's set (`npc_brain.gd`, `npc_ship.gd`) kept their
   shadowing constructs yet stopped warning, which is the measured demonstration.
2. **A parse error was observed in G2's tree mid-wave** — `game/weapons.gd:641`,
   `Parser Error: Static function "spawn_chip_sparks()" not found in base "Projectile".`
   It took down the warning coverage of every file in its dependency chain (`sector.gd`
   among them), which is how the false-negative mode in §3 was measured. **G2 has since
   resolved it** — `projectile.gd` now defines `spawn_chip_sparks`, the ledger is healthy
   again, and `weapons.gd` has reached 0 rows. It is recorded because the *mechanism* is
   what a reviewer must guard against, not the break. G3's gate numbers below were measured
   on a consistent tree.

---

## 1. What G3 owns, and what it wrote

| Path | Written by G3 |
|---|---|
| `vajb-orbit/ui/station/exchange_panel.gd` | yes |
| `vajb-orbit/ui/station/shipyard_panel.gd` | yes |
| `vajb-orbit/ui/station/launch_panel.gd` | yes |
| `vajb-orbit/ui/components/slot_button.gd` | yes |
| `vajb-orbit/game/sector.gd` | yes |
| `vajb-orbit/tests/` | yes |

New files, all under `vajb-orbit/tests/` (none is discovered by the gate: `headless_runner.gd`
discovers `test_*` only, and these are `probe_*`):

| File | Role |
|---|---|
| `tests/probe_g3_lint.gd` / `.tscn` | the runtime warning ledger (corroborating evidence) |
| `tests/probe_g3_shadow.gd` / `.tscn` | the static guard, 25 checks (primary evidence) |

No `assets/**`, no theme, no `project.godot`, no `addons/**`, no `docs/**`. `git status`
shows only the five scripts above modified by G3.

## 2. The instrument, and how its output must be attributed

`docs/CONTRACTS.md` §9 (fifth harness limit) names the instrument: `--headless --debug`
attaches the local stdout debugger and prints every GDScript warning.
`tests/probe_w5_lint.gd` is the reference implementation; `tests/probe_g3_lint.gd` is this
wave's instance, loading one file at a time with `CACHE_MODE_IGNORE` between printed
`[G3-LINT]` markers.

```
godot --headless --debug --path vajb-orbit res://tests/probe_g3_lint.tscn --quit-after 600
```

**Attribution.** Marker bracketing alone over-attributes: when a file is loaded for the
first time, its *dependencies* compile inside that block and their warnings land between the
markers. The same run shows it: `res://game/weapons.gd` contributes an identical 22-row
block inside `sector.gd`'s bracket *and* inside its own positive-control bracket (44
at-lines for 22 distinct warnings — the file compiled twice), and naive per-block counting
makes `game/sector.gd` look like **45** warnings when it has **2**.

The authority is the line the engine prints under each warning,
``at: GDScript::reload (res://<file>:<line>)``. That path/line is the offending occurrence,
provable three ways:

1. it reproduces the owner's own console row for row
   (`~/.local/share/godot/app_userdata/Vajb Orbit/logs/godot2026-09-21T17.18.43.log`, a game
   run with no probe markers at all — bracketing played no part there);
2. `game/sector.gd` is 448 lines with no function past line 443, yet its block carried
   "shadowing an already-declared function at line 561 / 1317 / 1406" — those classes belong
   to `npc_registry.gd`, `weapons.gd` and `npc_ship.gd`, and the `at:` line names exactly
   those files;
3. every cure below made its `at:` line disappear.

All counts here are grouped by the `at:` path, not by the block. `probe_w5_lint.gd` belongs
to another wave and was left alone; the correction is recorded for G4 and the orchestrator.

## 3. Two measured limits of the ledger (read before trusting any zero)

**3.1 A parse error upstream deletes downstream warning rows.** GDScript cannot emit
warnings for a file whose parse failed, and everything that loads that file inherits the
failure. Measured on the current tree, where G2 is mid-edit in `weapons.gd`:

| Run | parse/script errors | warnings | `weapons.gd` block | G3 files' rows |
|---|---|---|---|---|
| `g3_before.log` (before the sweep) | 0 / 0 | 75 | 23 | 8 |
| `g3_after2.log` (after the sweep) | 0 / 0 | 65 | 22 | **0** |
| degraded runs, G2's break in place | 6 / 6 | 12 | 0 | 0 (meaningless) |
| `g3_check.log` (G2's break resolved) | 0 / 0 | 15 | 0 | **0** |

In the last row, `weapons.gd:641` fails with
`Parser Error: Static function "spawn_chip_sparks()" not found in base "Projectile".` and
the runs stop reporting warnings for `npc_ship.gd`, `npc_brain.gd`, `player_ship.gd` and
`sector.gd` — the whole `weapons.gd` dependency chain. **A run must be health-checked
(positive controls firing, zero parse errors) before a zero is cited from it.**

**3.2 Warning rows can vanish while the source is unchanged.** With G2's break in place,
`game/npc_brain.gd:104` (`archetype: StringName, row: Dictionary` against `func archetype()`
at 155 and `func row()` at 159) and `game/npc_ship.gd:168`
(`archetype: StringName, stats: ShipStats, hull_id: StringName` against `func archetype()` at
755 and `func hull_id()` at 759) still contain their shadowing constructs, and both files are
unmodified in `git status` — yet the degraded runs emit no warning for either. The healthy
before-run did emit them. So a falling ledger count is **not** by itself evidence of a fix,
and this report does not rest on it.

**Consequence for this pass:** the sweep is proven at the source level (§5), not by the
ledger. The ledger's contribution is that in the healthy post-pass run it printed no `at:`
row for any of G3's five scripts, against eight before.

## 4. Re-derivation of the full list (before trusting the brief)

Healthy before-run, grouped by `at:` path, shadowing class (`SHADOWED_VARIABLE` /
`SHADOWED_VARIABLE_BASE_CLASS` / `SHADOWED_GLOBAL_IDENTIFIER`):

| File | unique rows before | in G3's set |
|---|---|---|
| `ui/station/exchange_panel.gd` | 2 | **2** |
| `ui/station/shipyard_panel.gd` | 1 | **1** |
| `ui/station/launch_panel.gd` | 1 | **1** |
| `ui/components/slot_button.gd` | 2 | **2** |
| `game/sector.gd` | 2 | **2** |
| `game/weapons.gd` | 23 | — (G2's set) |
| `game/projectile.gd` | 6 | — (G2's set) |
| `game/asteroid.gd` | 3 | — (no worker) |
| `game/npc_brain.gd` | 3 | — |
| `game/npc_registry.gd` | 3 | — |
| `game/npc_ship.gd` | 4 | — |
| `ui/hud/minimap.gd` | 1 | — |
| **total unique** | **51** | **8** |

The independently re-derived list for G3's files is **exactly the eight rows the editor log
names**, and the owner's log confirms it row for row (`exchange_panel.gd:24,25` ·
`shipyard_panel.gd:321` · `launch_panel.gd:246` · `slot_button.gd:95,96` · `sector.gd:125,309`).

Because ledger zeros are untrustworthy (§3), the **completeness** of that list was then
confirmed the cache-independent way: `probe_g3_shadow.gd` checks each of the five files for
the retired declarations, and the eight renames are exhaustive over them (there is no third
declaration of any of the eight names in any of the five files — the guard's absence checks
would catch it). No ninth row hides in these files.

## 5. The eight findings and their cures

| # | File:line | Class | Construct | Cure |
|---|---|---|---|---|
| 1 | `exchange_panel.gd:24` | `SHADOWED_GLOBAL_IDENTIFIER` | `const MineralCatalog := preload("res://game/mineral_catalog.gd")` vs global class `MineralCatalog` (`mineral_catalog.gd:1`) | renamed `MineralCatalogScript`, all 20 member uses updated |
| 2 | `exchange_panel.gd:25` | `SHADOWED_GLOBAL_IDENTIFIER` | `const ComponentCatalog := preload(...)` vs `ComponentCatalog` (`component_catalog.gd:1`) | renamed `ComponentCatalogScript`, all 9 member uses updated |
| 3 | `shipyard_panel.gd:321` | `SHADOWED_VARIABLE_BASE_CLASS` | `_make_plate(..., size: float)` vs `Control.size` | parameter renamed `plate_size` |
| 4 | `launch_panel.gd:246` | `SHADOWED_VARIABLE_BASE_CLASS` | same | parameter renamed `plate_size` |
| 5 | `slot_button.gd:95` | `SHADOWED_VARIABLE_BASE_CLASS` | `var pressed` in `_apply_plates` vs `BaseButton.pressed` (signal) | local renamed `pressed_plate` |
| 6 | `slot_button.gd:96` | `SHADOWED_VARIABLE_BASE_CLASS` | `var disabled` vs `BaseButton.disabled` | local renamed `disabled_plate` |
| 7 | `sector.gd:125` | `SHADOWED_VARIABLE` | `var fields` in `populate` vs the `fields()` method (line 204) | local renamed `rolled_fields` |
| 8 | `sector.gd:309` | `SHADOWED_VARIABLE_BASE_CLASS` | `_add_field(position: Vector2, ...)` vs `Node2D.position` | parameter renamed `field_position` |

Every change is a rename of a parameter, a local, or a private preload const. No method,
signal, exported property or scene contract was touched.

## 6. Pinned-surface check (done before renaming anything)

Read first: `docs/CONTRACTS.md`, `docs/design/IMPLEMENTATION_PLAN.md`,
`docs/design/STATION_HUB.md`, and the project's own prior cure, `tests/probe_w3_lint.gd`.

- **No doc pins either constant name.** Neither contract document mentions
  `MineralCatalog`/`ComponentCatalog` as *panel* symbols; `STATION_HUB.md` §5.9's mention is
  a reference to the **global class** the panel reads, unchanged.
- **The `*Script` suffix is this project's recorded cure for exactly this pair.**
  `probe_w3_lint.gd:68-69` asserts `const MineralCatalogScript := preload(` /
  `const ComponentCatalogScript := preload(` at `game/exchange.gd:45-46`, and 90-91 assert
  the unsuffixed pair is absent from that file. `exchange_panel.gd` was the same cure not yet
  applied; it now matches `exchange.gd`, `mining_laser.gd`, `pickup.gd`, `loot_tables.gd`,
  `sector_registry.gd`, `asteroid_field.gd` and `test_engine2_loot.gd`.
- **The parameter/local renames are invisible to callers by construction.** GDScript has no
  named arguments, so a parameter label cannot be observed at a call site. Both `_make_plate`
  call sites (one per panel) pass positionally, and neither `_make_plate` nor `_add_field` is
  called from any other file (only their definitions, their own call sites, and one comment
  at `tests/test_ui_slot_layout.gd:44`).
- **The two constants reach the outside only through a script preload** of
  `ui/station/exchange_panel.gd`, and the only reference to that script anywhere is its own
  `exchange_panel.tscn` (as a script `ext_resource`). Nothing reads
  `ExchangePanelScript.MineralCatalog`.
- `Sector.populate(row, random_seed)`, `Sector.fields()`, `Sector.spawn_plan()` and the
  `_plan` key string `&"fields"` are unchanged — only the local holding the rolled value was
  renamed.

## 7. Before / after ledger

| File | unique before | unique after (healthy run) |
|---|---|---|
| `ui/station/exchange_panel.gd` | 2 | **0** |
| `ui/station/shipyard_panel.gd` | 1 | **0** |
| `ui/station/launch_panel.gd` | 1 | **0** |
| `ui/components/slot_button.gd` | 2 | **0** |
| `game/sector.gd` | 2 | **0** |
| **G3 subtotal** | **8** | **0** |
| `game/weapons.gd` | 23 | 21 (G2, in flight) |
| `game/projectile.gd` | 6 | 6 (G2) |
| `game/asteroid.gd` | 3 | 3 |
| `game/npc_brain.gd` | 3 | 3 |
| `game/npc_registry.gd` | 3 | 3 |
| `game/npc_ship.gd` | 4 | 4 |
| `ui/hud/minimap.gd` | 1 | 1 |
| **whole-log total (unique)** | **51** | **41** |
| raw warning lines | 75 | 65 |
| of which shadowing-class | 74 | 62 |
| parse / script errors | 0 / 0 | 0 / 0 |

The whole-log fall is **−10 unique**: G3's 8, plus 2 from G2's in-flight `weapons.gd` pass
(23 → 21; the doubling in the raw count is that file compiling once as a dependency of
`sector.gd`'s chain and once under its own marker).

**Health of both cited runs, checked:** `g3_before.log` and `g3_after2.log` each contain
zero `Parser Error` and zero `SCRIPT ERROR` lines, and the positive controls fire in both
(`weapons.gd` 23 then 22, `minimap.gd` 1 in each). The negative control
(`autoload/world_clock.gd`) is silent in both. A blind run was therefore not mistaken for a
clean one. The later runs (`g3_final.log`, `g3_rep2.log`) are degraded by §3.1 and are cited
nowhere as evidence.

Siblings have continued since: G2's `weapons.gd` sweep has reached a state with no warning
rows at all, and `projectile.gd`'s rows remain with their lines shifted (+12), which is how
that file's edits show up.

## 8. Behaviour is byte-identical — the evidence

1. **Static guard, source-level, cache- and parse-independent: 25 / 25, exit 0.**
   ```
   godot --headless --path vajb-orbit res://tests/probe_g3_shadow.tscn --quit-after 600
   [G3] passed=25 failed=0
   ```
   5 compile checks (no parse error introduced), 8 line checks (each named line now holds the
   renamed construct), 10 absence checks (no retired declaration survives), 2 resolve checks.
   This is the primary proof precisely because it does not depend on the ledger's health.
2. **The renamed consts still resolve to the same scripts** — measured, not argued. The
   guard reads `exchange_panel.gd`'s script constant map and compares each renamed constant's
   `resource_path` against a fresh load of the catalog file:
   `MineralCatalogScript -> res://game/mineral_catalog.gd`,
   `ComponentCatalogScript -> res://game/component_catalog.gd`. Every
   `MineralCatalogScript.x` call is therefore the identical static call `MineralCatalog.x` was.
3. **The diff is rename-only.** `git diff -U0` over the five scripts, with the renamed tokens
   normalised, contains no line that is not the same line with an identifier renamed;
   `46 insertions / 46 deletions`, and no value, literal, condition, argument order, comment
   or line count changed. `sector.gd`'s `_plan` key `&"fields"` (a string literal) is
   untouched; only its value expression changed name.
4. **The suites that exercise these files are green.** The runner takes `--suite=` scoping
   (`tests/headless_runner.gd:33-43`); the set covering G3's files — `test_ui_slot_layout`
   (instantiates `slot_button.tscn`, `shipyard_panel.tscn`, `launch_panel.tscn` and asserts
   the plate sizes and panel growth, i.e. exactly the `plate_size` rename and the two locals),
   `test_engine2_wiring` (drives `Sector.populate` / `fields()` / `blips()`),
   `test_engine2_dock`, `test_p1_market`, `test_engine2_fixes`:
   ```
   [SUMMARY] passed=52 failed=0     (exit 0)
   ```
5. **The universal gate grew and holds zero failures in G3's suites.** Full gate at the
   close of this pass on a consistent tree:
   ```
   [SUMMARY] passed=288 failed=1     (289 tests; 277 before the wave)
   ```
   **Zero `[FAIL]` lines belong to any suite that exercises G3's files**
   (`ui_slot_layout`, `engine2_wiring`, `engine2_dock`, `p1_market`, `engine2_fixes`). The
   count is *higher* than the wave's starting measurement, as the brief requires, and G3
   added none of it. The one red is G1's in-flight work; the A/B that clears G3 of it is §9.
   An intermediate run at `passed=276 failed=1` (277 tests) predates G1's new suite and G2's
   `weapons.gd` sweep; both it and the A/B run agreed, which is what §9's isolation rests on.

## 9. The gate reds, and why none is G3's

**At the close of this pass:**

```
[SUMMARY] passed=288 failed=1
[FAIL] test_flight_feel_g1.gd.test_the_command_is_lateral_and_ceiling_clamped_with_no_invented_fraction:
       ship_vanguard: W alone is the old command to the digit (406.600 u/s)
```

That is G1's brand-new strafe suite and G1's `player_ship.gd` work, in G1's own file set.
No `[FAIL]` line names a suite that exercises G3's files.

**The red G3 was asked to account for** was earlier and different:

```
[FAIL] test_combat_repair_c5.gd.test_the_coast_column_is_the_retuned_half_of_the_section_13_rows:
       turn_rate is still 3.0
```

That is `tests/test_combat_repair_c5.gd:288`,
`assert_true(_near(float(vanguard[&"turn_rate"]), 3.0), ...)`, reading
`ShipFitScript.HANDLING[&"ship_vanguard"]`. G1 landed the owner's `turn_rate × 0.50` ruling
in `game/ship_fit.gd` (`ship_vanguard` became `1.5` at `ship_fit.gd:180`), so the
pre-existing C-wave guard of the *unretuned* value flipped. **G1 has since updated that
assertion** — the red is gone from the closing run above.

Two proofs it was never caused by this pass:

- **File disjointness.** `test_combat_repair_c5.gd` preloads `asteroid.gd`, `weapons.gd`,
  `npc_ship.gd`, `ship_fit.gd`, `player_ship.gd`, `player_ship.tscn`. None of G3's five
  scripts is in that closure, and the assertion reads a literal dictionary in `ship_fit.gd`.
- **A/B measurement.** With G3's five files stashed back to `HEAD`
  (`git stash push --` those five paths) and everything else left in place, the gate gave the
  identical result: `[SUMMARY] passed=276 failed=1`, same test, same message. The stash was
  popped immediately and the tree verified restored. G3's changes are gate-neutral: the red
  existed with and without them.

Neither red was fixed here, deliberately: both are in another worker's file set.

## 10. Residual, out of scope, and observations for G4

- **14 shadowing rows remain project-wide in the latest healthy run, and none is in G3's
  files:** `npc_ship.gd` 4, `asteroid.gd` 3, `npc_brain.gd` 3, `npc_registry.gd` 3,
  `minimap.gd` 1. `weapons.gd` and `projectile.gd` (G2's set) have reached 0. **No worker
  owns any of these five files** under this wave's table, so the owner's console will keep
  showing them after the wave closes. That is a scoping gap for the orchestrator, not a G3
  finding — and the number can only be read from a **healthy** ledger run, per §3.
- At the close of G3's own pass the project-wide figure was **41** unique shadowing rows
  (51 before), of which G3's 8 were the whole of its file set.
- The brief's "~30 rows" is an undercount of the ledger's **51** unique healthy rows; the
  owner's console showed fewer because a game run compiles a subset of the tree.
- **A different warning class, left alone by design.** `npc_brain.gd:477` is
  `INT_AS_ENUM_WITHOUT_CAST` ("Integer used when an enum value is expected"), not shadowing,
  and outside G3's files. `docs/CONTRACTS.md` §9 records the three equivalent casts the D5
  sweep made in `settings_manager.gd`; a later wave can treat this one the same way.
- **Pre-existing harness noise, identical in both A/B runs:** one
  `SCRIPT ERROR: Cannot call method 'call' on a previously freed instance` at
  `tests/test_weapon_fx_f4.gd:176` (the test still passes), plus `28 ObjectDB instances were
  leaked at exit` and `12 resources still in use at exit`. Untouched by G3.
- **Reproducing this pass:** run both probe scenes from the project root with
  `--path vajb-orbit`, and health-check the ledger output before citing it (zero parse errors,
  positive controls firing). `probe_g3_shadow.gd` is a guard, so it *fails* on `HEAD`'s
  versions of the five scripts and passes on the shipped ones. Nothing here needs an editor
  session, the Godot AI plugin or the LSP; every measurement is a bounded headless run
  (`--quit-after`) with stdout redirected to a log.

## 11. Evidence files

| Path | Contents |
|---|---|
| `/tmp/g3_before.log` | ledger before the sweep — healthy: 75 raw, 74 shadowing, 0 parse errors |
| `/tmp/g3_after2.log` | ledger after the sweep — healthy: 65 raw, 62 shadowing, 0 parse errors, 0 rows for G3's files |
| `/tmp/g3_static.log` | `probe_g3_shadow` — `[G3] passed=25 failed=0` |
| `/tmp/g3_scoped.log` | scoped gate — `[SUMMARY] passed=52 failed=0` |
| `/tmp/g3_gate2.log` | full gate with G3's files — `passed=276 failed=1` |
| `/tmp/g3_gate_ab.log` | full gate with G3's files stashed to `HEAD` — `passed=276 failed=1`, same red |
| `/tmp/g3_final.log`, `/tmp/g3_rep2.log` | degraded runs, G2's `weapons.gd:641` parse error; cited only as §3 evidence |
| `/tmp/g3_check.log` | latest healthy run, G2's break resolved: 0 parse errors, 15 raw, 0 rows for G3's files, 14 remaining project-wide |
| `/tmp/g3_gate_final.log` | closing full gate — `[SUMMARY] passed=288 failed=1`, zero G3-suite failures |
