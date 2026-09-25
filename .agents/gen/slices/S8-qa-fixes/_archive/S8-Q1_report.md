# S8-Q1 report — the accounting family (H1 / H2 / M4) + the range copy

Worker: S8-Q1. Tree: `8c91716` + S8-Q0's dispositions. Method: the shipped scenes driven
headlessly on scratch stores (`XDG_DATA_HOME=$(mktemp -d)`, suite repoints `save_path`); the
full gate ran **five** times, `[SUMMARY] passed=761 failed=0` on each, and the live
`profile.cfg` / `economy_log.txt` md5s are byte-identical before and after (measured).
Built: H1 (spend/gate + briefing), H2 (rack ordinal), M4 (denominators), the `m`→`u` copy.
**O3 skipped**: my clause (4) was conditional on §21 carrying a proposed factor; §21's Q0 row
(`docs/CONTRACTS.md:2538`) writes none ("a factor would ship an unreachable path"), so
`player_ship.gd` / `impact.gd` are untouched and nothing about collision moved.

## H1 — the launch's own cells are the ammo space

- `game/weapons.gd:2013-2026` `_launch_ammo_slot(weapon, position = -1)`: resolves a family
  against `_state.weapons` (the launched fit's cell list `_seed_ammo` filled), the barrel's own
  cell preferred when it carries that family, else the family's own cell, else the shipped
  const `ammo_slot` (`:2419`, value unchanged, now the fallback for a rig `set_fitted` without
  `set_weapons`). `_ammo_available` / `_consume_ammo` took an optional `position`;
  `_ammo_available_at` / `_consume_ammo_at` (`:2041-2090`) pass the releasing barrel's own.
  No new constant.
- `ui/station/launch_panel.gd:623-659` `_fit_weapons` / `_ammo_total` / `_weapon_count`: the
  strip sums the launched fit's cells' packs and counts its cells (was: all six
  `Catalog.AMMO_PACKS` summed + the constant 6).
- Measured (fixture: every pack 300, QA fit `[w_cannon, w_railgun, w_mining]`): strip
  `600 ROUNDS ACROSS 3 WEAPONS`; the old formula on the same fixture reads
  `1 800 ROUNDS ACROSS 6 WEAPONS`; `state.weapons = [cannon, railgun, ""]`,
  `state.ammo = _ammo_seed = [300, 300, 0]`, Σ slots = 600 = the strip, and each
  family-bearing slot reads its own pack. Q0's live strip was `1 941 … ACROSS 6`.
- Firing, measured: a **cannon-only** fit with its pack stocked → 3 shots, projectiles ≥1,
  `ammo[0]` 300→297 (Q0: dry, 0 shots, `ammo_slot("cannon")`=1 ≥ `ammo.size()`=1). The QA fit
  with the cannon drained → the fired family is `railgun` **only**, `ammo = [0, 297, 0]`
  (Q0: the cannon fired and spent the railgun's pack).
- The seed path, `_file_ammo_report` and the HUD's pushed `position` needed no change (Q0's
  reading; re-measured slot-by-slot).

## H2 — the ordinal lives in the barrel-position space

- `game/game.gd:2075-2100` `_hull_slot_cells` now reads `_weapon_barrel_positions` and hands
  `_rack_ordinal` (`:2114`) the cell's **barrel position**, not its layout index.
- Measured: `[w_mining, w_laser, ""]` → `W1 · Mining Laser | W2 · B1 · Laser MkII` (Q0:
  `W1 · B1 · Mining Laser | W2 · B0 · Laser MkII`). Rack record `[[0],[1],[2]]` on the QA fit
  → B1/B2/B0; `[[0,1]]` → B1/B1/B0 — a family-less cell claims no rack and is not selectable.
- The status payload itself was correct (Q0) and stays: my suite compares the pane's W rows
  cell-for-cell against the fit and the FITTING pane's own occupancy on three fits (the QA's,
  `[w_mining, w_laser, ""]`, `[w_cannon, w_mining, w_laser]`), one W row per fitted cell, no
  W row carrying a non-weapon module.

## M4 — one denominator, resolve's

- `ui/station/repairs_panel.gd:352-373` `_pool_maxima`: `ShipFit.resolve(hull,
  base_fit(resolved_fit), affix_summary)`, the pair `game.gd:_apply_ship_maxima` seeds; the
  catalogue row survives only as the unknown-hull fallback (`:178-179`). The two currents are
  read at the resolved ceiling (`:177-184`) so the pin's "no pane may show current > max" holds
  even for a vitals record filed by a heavier fit.
- Measured: pane `hull=1250 / 1250`, `shield=800 / 800`, `missing=0 HULL · 0 SHIELD` (Q0:
  `1250/1000`, `800/600`); a filed 1000/700 → `1000 / 1250`, `700 / 800`,
  `250 HULL · 100 SHIELD`; a stale 1250/800 against a plate-less fit → `1000 / 1000`,
  `600 / 600`. Footer (already correct, re-measured): `HULL 1250 / 1250`, `SHLD 800 / 800`.

## Copy

- `ui/hud/hud.gd:126-130` `DISTANCE_FORMAT` `"%s m"` → `"%s u"`; measured
  `860 u  OUT OF RANGE` and `860 u  IN RANGE`.
- Moved rows, exactly as dispositioned: `tests/test_engine2_hud.gd:142/144/150`.

## Tests

- New: `tests/test_s8_launch_ammo.gd` (+ its `.uid`), 8 rows — H1 (strip/slots/packs/seed, an
  instance-id fit, a stocked family firing, a dry family never spending another's),
  H2 (cell-for-cell vs the FITTING pane, the barrel-position ordinals), M4 (both panes, the
  damaged and the clamped reading), the `u` copy.
- Watch list stayed green with no edit: `test_s5_batteries_v2.gd:605,673`,
  `test_s7_weapon_affixes.gd:386/404/422-423`, `test_s5_ammo_cargo.gd:317`,
  `test_engine2_weapons.gd:224-237` (the static `ammo_slot` is untouched),
  `test_p1_refinery.gd:192` untouched.
- Gate `761 = 753 + 8`, zero failed, twice-identical; live store md5s unchanged.

## Notes for R1 / the orchestrator (not fixed here)

1. **`game/repairs.gd` still resolves the maxima off the station row** (`:64-65` fee, `:89-90`
   repair, `:107-108` result) while the panes now print resolve's pair. Measured after a station
   repair on the plated Vanguard: the ship files at `1000/600`, the pane reads
   `hull=1000 / 1250`, `shield=600 / 800`, `missing=250 HULL · 200 SHIELD`, `fee=0 CR` — a
   repaired hull reading as damaged. The file is in no S8 worker's set, so the cure (the same
   `ShipFit.resolve` pair) needs a set growth or a follow-up row. **Bucket 2.**
2. **A launched same-family battery now spends both its seed slots.** `_launch_ammo_slot`
   prefers the barrel's own cell, which is the only rule that keeps
   `test_s7_weapon_affixes.gd:414-425`'s pinned per-cell spend green, so a twin-cell fit
   (`_seed_ammo` seeds both slots from the one family pack) fires up to 600 rounds where the
   const index spent one slot's 300. Measured on a launched twin-cannon fit
   (`seed=[300, 300]`, `racks=[[0,1]]`): 30 s of fire spent 50 rounds from **each** slot
   (`ammo=[250, 250]`), so both slots are live. This is §20's D1 / L90 terrain
   (`docs/CONTRACTS.md:2403`), superseded by §21's H1 row — recording it as your call.
   **Bucket 2.**
3. `game/player_state.gd:33-35`'s comment ("the ammo-slot order `game/weapons.gd` reads") is
   now stale. The file is not in Q1's `VAJB_WORKER_FILES` and the PreToolUse hook refused the
   edit, so it is reported, not written. **Bucket 1, one line.**
4. `docs/CONTRACTS.md:1731` (§16) still describes `ammo_slot` as the live spend's resolution;
   §21's H1 row is the live rule now (R1's §9/§10 pass).
5. Untouched by design: the trailing-rack reading (an empty `_batteries` record racks every
   fitted weapon together, so every W cell prints B1 — §21's owner tick), O4/O5's flight
   numbers, the station scene, `REFINERY ALL`, and every `.tscn` / `docs/` / `assets/` file.

Files touched: `game/game.gd`, `game/weapons.gd`, `ui/station/launch_panel.gd`,
`ui/station/repairs_panel.gd`, `ui/hud/hud.gd`, `tests/test_engine2_hud.gd`,
`tests/test_s8_launch_ammo.gd` (+`.uid`).
