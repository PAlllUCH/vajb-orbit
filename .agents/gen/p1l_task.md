# P1l task — market/profile/repairs/clock-log test suites

Worker: coder. Wave: P1 economy core, tests. Deliverables, exactly four new
files:

1. `vajb-orbit/tests/test_p1_market.gd`
2. `vajb-orbit/tests/test_p1_profile.gd`
3. `vajb-orbit/tests/test_p1_repairs.gd`
4. `vajb-orbit/tests/test_p1_clock_log.gd`

Do not touch any other file. No MCP tools. Do not run the editor. The
`tests/headless_runner.tscn` runner is written by a sibling worker (P1k); if
it exists when you finish, run it; if not, run each suite through your own
temporary probe scene (create/delete it) and say so in the report.

## Read first

- `vajb-orbit/addons/godot_ai/testing/test_suite.gd` — `McpTestSuite` base
  class (assertions, lifecycle). Suites subclass it and must run under the
  editor `test_run` tool and the headless runner.
- `docs/gameplay/17_coder_handoff.md` — §3 (persistence), §6 (checklist:
  persistence round-trip, v1 migration; heat is P3, not here).
- `docs/gameplay/05_exchange.md` — §2/§4 (demand, stock, queue).
- `docs/gameplay/01_economy_core.md` — §6 (repairs), §7 (log).
- The module sources: `game/exchange.gd`, `autoload/player_profile.gd`,
  `game/repairs.gd`, `autoload/world_clock.gd`, `game/economy_log.gd`,
  `game/mineral_catalog.gd`, `game/component_catalog.gd`,
  `game/station_catalog.gd`.

## Suite rules (all four files)

- `extends McpTestSuite`, `suite_name()` short lower-case id.
- **Never touch `user://profile.cfg` or `user://economy_log.txt`.** Profiles
  are `load("res://autoload/player_profile.gd").new()` with
  `save_path = "user://test_p1_<suite>.cfg"` set **before** any mutation;
  `EconomyLog.log_path = "user://test_p1_log.txt"`. Delete the test files in
  `suite_teardown()` and at suite start.
- Pure logic only; no scene instancing; no editor dependencies.
- Deterministic: seed every `RandomNumberGenerator`; use
  `WorldClock.set_override()` for time and `clear_override()` in teardown.
- Each test method independent; fresh profile per test.

## Suite 1 — `test_p1_market.gd` (Exchange)

- **Init:** first `evaluate_market(profile, now)` stamps `last_band = now`,
  fills every component stock with its quota (I 40, II 15, III 4), applies
  no drift, returns 0.
- **One band:** with a seeded RNG, `now + 1200` applies exactly one drift;
  every demand stays within [0.6, 1.6]; `trend` is -1/0/+1 consistent with
  the seeded step; the stamp advances.
- **Three bands:** one call with `now + 3600` returns 3 and leaves demands in
  range.
- **Drift bounds:** force demand to 1.55 with a positive-step seed, run one
  band, assert <= 1.6; same at 0.65 with a negative step, assert >= 0.6.
- **Mineral sale:** 10 `mineral_iron` at demand 1.0 -> quote gross 180, fee
  10, paid 170; after `sell`, cargo empty, credits +170, demand 0.9 (one
  trade impact of 0.10), one `SELL` log line.
- **Sale demand floor:** sell enough to push demand below 0.6 -> stored
  demand is exactly 0.6.
- **Component sale with quota:** 50 `comp_scrap_1` -> sellable 40, queued 10,
  credits += the 40-unit quote (unit 11, gross 440, fee 10, paid 430);
  `stock` 0, `queue` 10.
- **Queue payout:** after one band, the queue flushes (stock reset 40, 10
  sold, credits += the 10-unit quote gross 110 fee 10 paid 100; queue 0) and
  a `QUEUE_BUY` line is logged.
- **Queue with empty stock:** selling into a 0-stock item queues everything
  and pays 0.
- **sell_all:** ore + components sell, ingots are skipped, totals equal the
  sum of the lines.
- **Refusals:** invalid qty, unknown item, insufficient cargo -> no cargo,
  credits or market change.

## Suite 2 — `test_p1_profile.gd` (save v2)

- Fresh defaults: credits 10000, market shape complete, vitals empty, no
  file created.
- **v1 migration (17 §6):** write a v1 `ConfigFile` fixture
  (`save_version=1`, credits 1234, owned ships, cargo, ammo) to the test
  path, `reload()`, assert old values preserved and every new key at its
  default; the file on disk still says `save_version = 1`.
- **v2 round trip for every 17 §3 key:** set non-trivial values on
  `modules`, `fits`, `market`, `heat`, `standing`, `contracts`, `vaults`,
  `insured`, `mercy_used`, `vitals`; `save()`; second instance; `reload()`;
  deep equality; the file says `save_version = 2`.
- Getter copies cannot mutate state; equal sets emit nothing.
- Signals: `set_modules`/`set_fits`/`set_standing` emit exactly one
  `profile_changed` with their key; `set_market`/`set_heat`/`set_vitals` and
  the other silent setters emit nothing.
- Existing API unregressed: `add_credits`/`spend`/`add_cargo`/`remove_cargo`
  emit their keys, `spend` over balance refuses.

## Suite 3 — `test_p1_repairs.gd` (Repairs + vitals)

- 01 §6 example: Vanguard vitals 200/1000 hull, 300/600 shield -> `fee ==
  500`; a repair spends exactly 500 and sets vitals to 1000/600; one REPAIR
  log line with -500.
- Full pools -> `fee == 0`, `is_repairable == false`, `repair` returns
  `no_damage`.
- 90 % exemption: hull 1000, shield 570 -> `fee == 0`, `is_repairable ==
  true`; repair costs nothing and tops the shield to 600.
- No vitals record -> `no_damage_report`, nothing changes.
- Credits below fee -> `insufficient_credits`, vitals and credits untouched.

## Suite 4 — `test_p1_clock_log.gd` (WorldClock + EconomyLog)

- `BAND_SECONDS == 1200`; `bands_between` edges: (1000, 2199) = 0,
  (1000, 2200) = 1, (1000, 3400) = 2, zero/negative/reversed -> 0.
- Override: `set_override(5000)` -> `now() == 5000`;
  `bands_between(5000, 6200) == 1`; `clear_override()` restores.
- Log line shape: `append("SELL", &"ingot_gold", 10, 1117, 101117)` produces
  one line with six `, `-separated fields, an ISO timestamp, signed
  `+1117`, and a second append does not truncate the first.
- Failed open (point `log_path` at an unwritable path) warns and does not
  crash — assert the call returns normally.

## Gate

Run the suites (through P1k's runner when present) until `failed=0`, exit 0,
no `SCRIPT ERROR`. Evidence: exact command + summary lines. Do NOT use
`--check-only --script`.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — no `$` in PowerShell.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1l_report.md`: deliverables, command + summary output,
per-suite test counts, deviations, and anything a reviewer should look at.
Under 100 lines.
