---
slice: S27
worker: S27-F1
model: "deepseek-v4.1-flash"
status: actionable
gate: "1299/0 → 1300/0 ×2 (fresh scratch XDG_DATA_HOME stores)"
---

# S27-F1 report

## Result
Both MED findings closed. F1: a Rare's two prefixes now always bend different
properties (`roll_prefixes` dedupes by `stat`), proven by a new 5k seeded row.
F2: the Pyre's ring gates on the victim's **pre-blow** hull share, so a
full-hull one-shot no longer fires it and a below-quarter finish does. Gate
grew by exactly the one new suite row: **1300/0**, twice.

## Finding-by-finding disposition
- **S27-B1/F1 (MED) — fixed.** `module_catalog.gd:roll_prefixes` picked distinct
  **ids** from a family pool that carries two rows per stat (`keen`/`dense` =
  `damage_add`; `rapid`/`quickwarm` = `fire_rate_mult`), so a Rare weapon could
  roll one property twice. The walk now drops every remaining pool row whose
  `stat` equals the just-picked row's, one pick per property; the count stays
  `min(affixes, pool)` and a family with fewer distinct properties contributes
  what it has (armour's single row still yields one for a Rare). Suite row
  `test_s27_catalog.gd:test_a1_a_rare_never_pairs_one_property_twice` seeds 5k
  Rare weapons over four weapon bases and asserts the two stats differ. Not a
  real gate before the fix: ~13 % of rare weapon rolls pair same-stat rows.
- **S27-B2/F2 (MED) — fixed.** `_detonate_pyre_ring` read `hull_fraction()` at
  the killing blow (always 0.0), so the ring fired on every kill. `npc_ship.gd`
  now records `_pre_hit_hull_fraction` (default `1.0`) at the top of
  `take_damage`, after its no-hit early returns and before `set_hull`, and
  exposes `pre_hit_hull_fraction()` beside `hull_fraction()`; `game.gd` reads
  that accessor. `test_s27_catalog.gd:test_a2_pyre_ring_fires_on_a_kill_in_flight`
  now proves a `pre_hit = 1.0` one-shot pays no ring, a `pre_hit = 0.10` finish
  pays the 50, and no-Pyre pays nothing.
- **S19 seal (F2's mandated re-pin).** `npc_ship.gd` is one of
  `test_s19_quadrants.gd`'s four sealed files, so this edit moved its SHA-256:
  the `res://game/npc_ship.gd` row of `FORBIDDEN_FILES` re-pinned
  `31f5ac42… → 754a261f…` with a one-line disclosure comment naming S27-F1
  (the S22 procedure, per §8's second `test_s19_quadrants.gd` row).
  `test_the_four_forbidden_files_are_byte_identical` passes.
- **No LOW items touched** (F3 rides T-178). `game/weapons.gd` untouched — its
  seal was already re-pinned by B2.

## Deviations from SLICE.md / the brief
- None. No pinned value changed except the one S19 seal this fix mandates, and
  no other gate row moved (`test_s3_instances.gd`'s pinned outcomes are all
  Magic/Common, so the prefix dedupe does not shift them; `test_s27_catalog.gd`'s
  A1 5k probe asserts family/band/count, unchanged).

## Evidence
- `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 2400` →
  `[SUMMARY] passed=1300 failed=0` (run 1, fresh store).
- Same command, second fresh store → `[SUMMARY] passed=1300 failed=0`.
- Targeted `-- --suite=test_s27_catalog --suite=test_s19_quadrants` →
  `passed=45 failed=0`, including `test_a1_a_rare_never_pairs_one_property_twice`,
  `test_a2_pyre_ring_fires_on_a_kill_in_flight` and
  `test_the_four_forbidden_files_are_byte_identical`.
- `sha256sum vajb-orbit/game/npc_ship.gd` → `754a261f…` (the new pin).

## Files touched
- `vajb-orbit/game/module_catalog.gd` — `roll_prefixes` dedupes by `stat`; doc updated
- `vajb-orbit/game/npc_ship.gd` — `_pre_hit_hull_fraction` + `pre_hit_hull_fraction()`, recorded in `take_damage`
- `vajb-orbit/game/game.gd` — `_detonate_pyre_ring` reads the pre-blow accessor
- `vajb-orbit/tests/test_s27_catalog.gd` — new F1 row; Pyre row proves the real gate; StubHull carries `pre_hit`
- `vajb-orbit/tests/test_s19_quadrants.gd` — `npc_ship.gd` seal re-pinned + S27-F1 disclosure

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| None new (F3 already ticketed T-178) | — | — |
