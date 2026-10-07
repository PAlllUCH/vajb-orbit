---
slice: S21
reviewer: S21-R1
verdict: passed-with-followups   # 1 HIGH (bucket 2, list edit — no revert) + 1 MED (fixer cure)
gate: "917/0 baseline → 941/0 scratch = 941/0 live-account copy; 941/0 re-read after the flips"
---

# S21-R1 review

Measured 2026-09-29, everything on scratch `XDG_DATA_HOME` stores (L229). The builders' reports
were not the yardstick: every acceptance line below was re-measured (13 temporary value flips on
the s21 suite — all 13 flipped rows FAILed, so every asserted row executes; the engine contact
probe re-run; two full gates plus a third after the flips were reverted; one station boot-md5
run; the moved-file and moved-row diffs against `s21_start`/HEAD).

## Acceptance list
- **A1 — pass.** `test_s21_stability.gd:138` (24 held-thrust death frames: `applied_force()==ZERO`,
  torque 0, momentum bounded; flip → FAIL), `:184` (wreck monitor charges neither side), `:214`
  (order fx → pickups → route, route from an inert hull); `player_ship.gd:576-623,700` state +
  guards (`take_damage`, `_unhandled_input`), `game.gd:2641-2655` order (`die` before drop).
- **A2 — pass.** `:263` drop lifetime = `DROP_WINDOW` 300 through `Pickup.setup`'s `window` arg
  (flip → FAIL), absolute ledger expiry, 300th second frees, `:311` respawn route + crossing
  re-materialise with `expires-now` and prune when late, `:362` collection clears the entry;
  `pickup.gd:74-115`, `game.gd:2704-2790`.
- **A3 — pass.** My re-run of `probe_s21_contacts.tscn`: `pairs=player:1 npc:1
  row15=93.789474 player_loss=93.789474 npc_loss=93.789474` (each half exactly once — no
  double-charge), ROCK `pairs=1 loss=186.179104 credited=18.617910`. Masks now both
  rock|ship (`player_ship.tscn:18`, `npc_ship.gd:71`); rows `:393/:419/:482/:518` (flip →
  FAIL); the non-authority monitor stands down and the authority charges both halves.
- **A4 — pass.** My own boot-only run: `station.tscn` on a copy of the live store leaves
  `profile.cfg`'s md5 **and mtime** identical (only `logs/` appears); row `:872` (flip → FAIL);
  `_transit_destination` clears at `:558` (flip → FAIL); `game.gd:427-437,1106,1265,2820`.
- **A5 — pass.** Gate **941/0** on a fresh store **and 941/0 on a copy of the live account's
  store** — identical; baseline row-set diff (HEAD == `s21_start` for tests): no suite lost,
  added or renamed a row anywhere except `s19` +1 and `s21` +23, and every suite's executed
  count equals its `func test_` count. Fixtures stage their own fit/packs and read
  `_state.weapons` (dock `:254`, fixes `:569`, wiring `:339`).
- **A6 — pass.** Row `:991` (instance-keyed bag: `module_count(&"w_laser")==0` while
  `instances_of` lists 3; stacked record 2 → **one** cell; take is key-exact; FITTING counts
  units, armory counts records; flip → FAIL), `:1048` (lost fitted instance → one row keyed by
  the fit's id, `OWNED ×0`); law stated at `player_profile.gd:562-609,610-618`.
- **A7 — pass.** Arithmetic re-derived and executed (flip → FAIL): `commission_for_item` ammo
  2→0 / 60→1, a 1-unit sale nets 2, 30 units fee 1 net 59, `commission_for` keeps the 10 CR
  floor for every other kind; reload 295+1 unit → 300 with 5 banked, 297 against bank 6 → bank
  3, remainder persists and is drawn first; LAUNCH strip reads 240 without spending
  (`launch_panel.gd:645-680`).
- **A8 — pass.** Row `:1199` (flip → FAIL): owned row disabled with `OWNED`; unowned stays live
  `BUY`; direct `buy_hull` still refuses with the pinned wording.
- **A9 — pass.** Rows `:619` heat bank static (flip → FAIL), `:655` three cancels (zone exit /
  damage / death), `:700` funds rung then Outlaw first (flip → FAIL), `:747` `respawn(now)`'s
  stamp reaches the yield roll with its wall-clock control (flip → FAIL), `:791`
  `_cleave_child` reset (L215), `:818` MOVED name read before the write (flip → FAIL).
- **A10 — pass.** Flip proof re-run by me: `test_weapon_fx_f4.gd:183` expected 2 →
  `[FAIL] … (read 1)`, 5/1, **no** `SCRIPT ERROR`; restored → 6/0. The s19 CTX row `:665` is a
  direct const equality (+1 gate row).
- **A11 — pass.** `damage.gd` sha256 `5cabf3d9…` = HEAD blob = seal (`git diff HEAD` empty);
  `npc_ship.gd` `a694170c…` = the re-pin; `npc_brain.gd` `e39440bf…`, `weapons.gd`
  `fcdc549f…` unchanged; `verify_wave.py verify --baseline s21_start` → `"problems": []`,
  moved = exactly the wave's 27 modified + 8 added files. **One drift, filed as F1 below:** two
  suites' moved *values* were off §8's list.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S21-B2/F1 | HIGH (bucket 2) | `tests/test_s5_ammo_cargo.gd:465-489,538-544`; `tests/test_s5_commerce.gd:493-497` | §8's candidate table missed both suites, whose pinned fee/paid (10→1, 50→59, 46→55) and action-plate (BUY→OWNED iff owned) expectations moved with R-S21-1/R-S21-3. Counts unchanged; rows correct as built, the **list** is stale — list amendment, never a revert (`L246`). | developer/designer session |
| S21-R1/F1 | MED | `tests/test_s20_chrome_unify.gd:276` | `panel.call(&"slot_plate_rect", …)` cannot reach the inner class's static from an instance, so the function aborts and every assertion below (plate centring/size, BUY/X family, **L236's 24×29 closure**) never runs while `[PASS]` prints. Measured, not assumed: flipping `:306` to `Vector2(0,0)` still prints 7/0. S20's own miss (file untouched by S21), disclosed in the prompts; one-line call-site cure. | S21-F1 |
| S21-B1/F1 | LOW | `tests/probe_s2_5_review.gd` (`dead=` print) | Reads `not is_physics_processing()`, which A1's dead state keeps true-on, so it calls a dead ship live; disclosed as B1's deviation (e); not a gate row. | → `L247` |
| S21-B2/F2 | LOW | `ui/station/exchange_panel.gd:164-207` | Edited though off §7's B2 region list (A4a forced it; deviation (d)); no pin moved, no collision. Region-list amendment owed. | → `L248` |
| S21-B2/F3 | LOW | `tests/probe_w3_services.gd:208` | Prints `module_count` as "owned" under A6's record-read law; probe only. | → `L249` |

**S21-B3 — no findings.** Its deviations are adjudicated below.

## Adjudication notes (bucket 2 — developer/owner, not the fixer)
- **The S19 byte-seal re-pin is accepted as shipped**: the pin carries the finished tree's
  `a694170c…`; the interim `728268c5…` could not survive B3's own mask edit and survives as the
  chain in the pin's comment (`test_s19_quadrants.gd:95-100`); the brief's amendment 3 records
  the final value, so no yardstick edit remains owed.
- **B1's A2 ledger (deviation (a))** is new machinery beyond the named `setup` seam, but it
  introduces no new number (`DROP_WINDOW` 300 stands) and carries a complete reversal; accepted.
- **The live profile** was written in the wave window (now `3940cdef…`, mtime 2026-09-29 19:33 —
  a windowed Vulkan run with the editor's debugger helper, consistent with the owner's parallel
  playtest, not a headless probe); all three review gates ran on copies and left it untouched.

## Verified fixes
n/a — pre-fix review; F1's MED goes to the fixer, F1's HIGH to the developer session.

## Gate
`[SUMMARY] passed=941 failed=0`, exit 0 — fresh scratch store, then a copy of the live account's
store (identical counts), then fresh again after the flips were reverted. Baseline `917/0`
re-derived from HEAD (80 suites); one `SCRIPT ERROR` in the log (S21-R1/F1's row); zero
`[FAIL]`/`[SKIP]`. Evidence logs: `/tmp/s21_r1/gate_scratch.log`, `gate_live.log`, `gate_final.log`.
