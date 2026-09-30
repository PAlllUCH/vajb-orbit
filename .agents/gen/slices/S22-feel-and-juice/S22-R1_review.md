---
slice: S22
reviewer: S22-R1
verdict: blocked
gate: "941/0 (baseline copy of 93d6afb) → 971/0 (HEAD, fresh scratch store)"
---

# S22-R1 review

Independent re-measurement: two full gates (baseline reconstructed from `93d6afb` in
`/tmp/s22base`, HEAD in the live tree), and a 29-check probe
(`vajb-orbit/tests/probe_s22r1_review.gd` + `.tscn`, self-quitting, `XDG_DATA_HOME` scratch,
L229) whose log is `/tmp/s22r1_probe4.log`. Every Godot run carried `--quit-after`.

## Acceptance list
- **A1 — pass.** One signal, both sinks (`weapons.gd:1894,1901` beams; the shot reports
  through `_note_projectile_hit`, `weapons.gd:1258` + `projectile.gd:995-997`); HUD answers any
  hull (`hud.gd:596-608`). Probe `hit_landed_seam`: stub hull → 1 delivery `(stub, 10)`, marker
  true; `poll_retired`: `game.gd` has no `pools_seen`; gate rows a1×3 green.
- **A2 — pass.** Both monitors cue (hull/rock) + one `spawn_chip_sparks` at `_contact_point`
  (`player_ship.gd:1188-1194`, `npc_ship.gd:643-651`); probe `contact_point`: (30,0) on the
  line at the hull's radius 30, not the midpoint; gate rows a2×3 green.
- **A3 — pass** (tick T-feel-4's intent, amendment 8). `nose_point()` = the `HARDPOINTS` bow
  band average × sprite scale (probe: (29.37,-0.30), `thruster_points=2`); flash mouth lands on
  the converted anchor (probe `flash_anchor`); spawn line unchanged (`weapons.gd:1261`,
  probe `spawn_pin`); the mapped-hull desync row is green in my gate.
- **A4 — verify-only, pass.** Shipped intact at the ticked value; gate line
  `A4 chip burst=4 cue=true world=40.0 fps=20.0` (my run), no edit.
- **A5 — pass.** `_push_status` pushes `set_quadrants` (`hud.gd:862-870`); probe through a real
  breach: `STBD 0 / 313`, peers `313 / 313`, hull 937.5 of 1250 (the fallback would print 234).
- **A6 — pass.** 20 ms double-trigger refused, next accepted at 35 ms takes 02
  (probe `antiflam_20ms`); 4 weapon voices active → 5th refused, an impact still plays
  (`antiflam_cap`); skip-last 01→explicit 02→03; constants 30 / 4 / 6 / 1 / 2.
- **A7 — pass.** `sfx_weapon_mine_drop` in `FIRE_CUES`, takes 01/02 = **0.351 / 0.359 s** ≤ 0.5
  (probe, re-measured via `AudioStream.get_length`); CC0 qubodup rows in
  `generation_log_audio.md`, `ASSET_MANIFEST.json` (`allowed_public_domain`), `CREDITS.md`;
  detonation keeps `sfx_weapon_explosion`.
- **A8 — verify-only, pass.** 1.6/2.6 + seed 20260921; probe 4 arcs, every draw in band,
  varied; gate row fired 6 (1.6605–2.5711 s); the 4.0 proposal does not ship.
- **A9 — pass.** 80.0 u / 6.0 s shipped; probe: proxy fires at 70 u (180 dealt), expiry at
  6.0 s, dumb-fire has no fuze; NPC drag mirrored (my gate: `npc t_10=0.900 = player 0.900`);
  ramp kept (axial = lateral 2.367 s); T3 struck; §14/`ship_fit.gd` disclosures intact.
  The fuze delivery reading is tabulated as **L253** below.
- **A10 — pass.** Fee 692 = (1050/2)+(500/3) on the resolved 1250/800; probe's own vector:
  missing 950/400 → fee 609, service maxima == pane `_pool_maxima` == transaction maxima;
  gate row `A10 figure hull=1250 shield=800 fee=692`.
- **A11 — pass.** 400 on `[200,100,0,0]` lands 300 and kills (gate row + probe); probe vectors
  `[40,120,0,140]` hit 150 → `[20,60,0,70]` proportional, and 600-on-`[50,50]` → hull 0,
  `died` once, `hull == sum(pools)` exact. R-S22-3/R-S22-4 dispositions tabled, no code
  (`_seed_ammo` untouched).
- **A12 — pass.** Tool slot reads `ModuleCatalog` ("Mining Laser"), a firing family keeps
  "Laser MkII" (probe `module_label`); `damage.gd` byte-identical (`5cabf3d9…`, probe
  `seal_hashes` + empty `git diff` since `93d6afb`).
- **A13 — verify-only, pass.** Probe measured every pin: trail 12/loop/48, mine 22, plume
  16/1.4/0.6/14/25/8–24/0.5–1.1, chip 40 @ 20 (4 cells), arc 40, bolt 64 / slug 96.
- **A14 — pass.** Pool 01–03, take 04 on disk (staged trim); cycle 01,02,03,01; skip-last at
  N = 3.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S22-B3/F1 | **HIGH** (bucket 2) | `S22_BRIEF.md` §8; `tests/test_s19_quadrants.gd:573-605` | an **unlisted moved row**: `test_a_repair_restores_the_pools_and_keeps_the_fee_law` moved with R-S22-1 (fee 500→**692**, `hull_max` 1000→**1250**, credits 9500→**9308**); §8 named only the spill row, amendment 13 the hull-sum row + rename, amendment 14 only `test_p1_repairs`. Row is correct as built — the list owes the row (L246/L238 precedent); no revert | developer/designer list edit → **L252** |
| S22-B3/F2 | LOW | `game/projectile.gd:682-687` | the 6 s fuze expiry delivers to the lock with **no distance gate**: probe detonated at 6.0 s and dealt 180 at **5423 u** (the 80 u proxy never opened) — the tick's "orbiting not blessed" supports it, but a guaranteed eventual hit is the owner's call (amendment 16) | owner confirm → **L253** |
| S22-B2/F1 | LOW | `autoload/audio_manager.gd:395-396` vs `:414-419` | the docstring says a dropped trigger advances no cursor, but a **cap**-dropped trigger has already advanced `_pool_next` (the pick precedes the fresh-voice gate — B2's own deviation 3); no §4.1 rule broken, the comment overclaims | next audio owner → **L254** |

No findings against S22-B1: its deviations (b)–(f) all land inside pinned acceptances or
amendments 7/8/9 and were re-measured (A3 values above).

## Verified fixes
None — no fixer pass has run. The single HIGH is a bucket-2 list edit, so F1 is the
orchestrator's call under the brief's §8 rule (fixer on HIGH/MED).

**Discharged 2026-09-30 by the developer session (orchestrator), not by a fixer:**
S22-B3/F1 (**L252**) — §8's `test_s19_quadrants.gd` line now names all three moved
rows (the spill, the hull-sum row + rename, and the repair row at `:573-605`), and
brief amendment 18 records the discharge. No code changed, so the row stands as
built; a bucket-2 finding whose artefact is the brief belongs to its owner under
the escalation ladder. 0 MED remained and the two LOWs stay ticketed
(**L253**/**L254**), so no F1 pass ran and this wave closes with no code debt
beyond those two tickets.

## Gate
- **Baseline replay, `93d6afb` reconstructed in `/tmp/s22base`, fresh scratch store:
  `[SUMMARY] passed=941 failed=0`, exit 0.** HEAD, fresh scratch store: **`passed=971
  failed=0`**, exit 0; zero `[FAIL]`/`[SKIP]` in both.
- **Growth is only the three new suites** (11 + 7 + 12 = 30 = 971 − 941); every other
  suite's executed count is identical baseline→HEAD, and each new suite's pass count equals
  its `func test_` count (11/7/12, no silent abort).
- **Moved rows:** row-name diff shows exactly two renames — `test_s19_quadrants.gd`'s
  `…_spills_its_remainder_evenly` → `…_spills_proportionally` (amendment 13) and
  `test_weapon_fx_f1.gd`'s `test_the_mine_drops_with_no_cue` →
  `…_with_the_mine_pools_own_cue` (amendment 9, §8's "rows updated") — plus the 30 additions.
  Function-attributed diffs add `test_engine2_cleaving.gd`'s one row and
  `test_engine2_wiring.gd`'s marker row (both §8/amendment 7,9) and the s19 repair row
  (**F1 above**). §8's expected NPC-skid move is the new suite's row — no existing suite
  pinned the NPC skid, and none moved.
- **S19 seal is green again and equals the finished tree**: probe re-computed
  `npc_ship 12ab0ae2…`, `weapons 6f95a9c2…` = the re-pinned strings, `damage 5cabf3d9…`,
  `npc_brain e39440bf…` unmoved (4/4 pins).
- The known benign `ShipFit` `_power_arithmetic` WARNING prints in both runs (scratch and
  baseline alike) — not a finding.
- Close-out note: `tests/test_s22_balance.gd.uid` is not yet on disk (B3's disclosed
  housekeeping; the §12.2 editor import generates it).
