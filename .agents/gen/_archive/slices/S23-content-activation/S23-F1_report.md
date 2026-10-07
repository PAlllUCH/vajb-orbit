---
slice: S23
worker: S23-F1
model: glm-5.3-flash (hyper)
status: informational
gate: "1030/0 ×2 fresh scratch, exit 0 both, pass lists identical (one interposed 1029/1 — the seal re-pin, Deviations 1)"
---

# S23-F1 report

## Result
Both HIGH/MED findings fixed; the A1 row now executes its whole body with the
keyed draws and the landed V1 pack/ceiling tail. Gate `[SUMMARY] passed=1030
failed=0` twice on fresh scratch stores — the count is flat against R1's own
after-gate (1030), and the suite's script error is gone.

## Finding disposition
- **F1 (HIGH) — fixed.** `&"draw": 12.0` keyed into the proton family row
  (`game/weapons.gd:201`) and `&"draw": 8.0` into the flak row
  (`game/weapons.gd:220`), exactly the P3 pins R-S23-1/2; the row comments that
  quoted them now have their keys. No consumption edit: the only two readers of
  `draw` are the dry readout (`weapons.gd:878`) and the instant per-frame spend
  (`weapons.gd:1203`), so the travelling rows still pay nothing per frame — the
  key merely exists as pinned. The suite's A1 draw asserts
  (`tests/test_s23_content.gd:92`, `:102`) now read keyed values; suite-alone
  run: `[SUMMARY] passed=12 failed=0`, exit 0, **zero** `SCRIPT ERROR` lines in
  the log — R1's negative control (silent abort at `:92`) no longer reproduces.
- **F2 (MED) — fixed.** The staged-pack tail
  (`tests/test_s23_content.gd:113-127`) now asserts the landed V1 values: the
  proton pack 40 rounds / 400 CR and the flak pack 300 / 260 through
  `StationCatalogScript.ammo_pack` (the rows at `game/station_catalog.gd:83-98`),
  and the AMMO_MAX ceilings **60 / 300** through the profile's `ammo_max` API
  (the autoload via the suite's own `_host()` idiom, the skip guard the suite
  already uses; the rows at `autoload/player_profile.gd:237-238`). The stale
  "staged (bucket 2)" comment block is gone with the asserts it described.
  Row count flat: the suite still carries its 12 `func test_` rows.
- **F3 — not this worker's** (the developer landed the §8 list amendment before
  this dispatch). **F4/F5/F6 — LOW, ticketed L264/L265/L266** — untouched, per
  the dispatch.

## Deviations
1. **The `test_s19_quadrants.gd` forbidden-file seal re-pinned** — the S21/S22
   procedure, not a scope grab: the fixer is now `weapons.gd`'s last editor, so
   the pin is re-taken from the finished tree. The first full-gate run went
   `1029/1` (`test_s19_quadrants.gd.test_the_four_forbidden_files_are_byte_identical:
   res://game/weapons.gd is byte-identical` — the seal working as built);
   re-pinned `6be8034e…` → `6848270a0a0c0952173546ab88492aa9dc3e1c0f0256611e81db41d288429f50`
   at `test_s19_quadrants.gd:123`, with the S23-F1 comment block at `:118-122`
   naming this report. Then the two clean runs below. The S19-era pin inside the
   review probe (`tests/probe_s19r1_review.gd:696`) predates the wave's own
   re-pin and is not a gate row — untouched.

## Evidence
- Suite alone, fresh scratch (`rm -rf user://_gate_scratch` first):
  `$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn
  --quit-after 1200 -- --suite=test_s23_content` → `[SUMMARY] passed=12
  failed=0`, exit 0, `SCRIPT ERROR` count 0.
- Gate run A (before the re-pin): `[SUMMARY] passed=1029 failed=1`, the seal row
  the single failure — recorded above.
- Gate run 1 (after): `[SUMMARY] passed=1030 failed=0`, exit 0.
- Gate run 2 (fresh scratch again): `[SUMMARY] passed=1030 failed=0`, exit 0;
  `[PASS]` lists of both runs diff-identical (1030 lines).

## Files touched
- `vajb-orbit/game/weapons.gd` — the two pinned `draw` keys (F1).
- `vajb-orbit/tests/test_s23_content.gd` — the A1 tail flipped to the V1 pack
  and ceiling values (F2).
- `vajb-orbit/tests/test_s19_quadrants.gd` — the weapons.gd seal re-pin
  (Deviations 1).

## Follow-ups
None owed — F4–F6 are already ticketed (L264, L265, L266) and everything this
pass touched is disclosed above.
