# P1k report — headless runner + catalogue/pricing/refinery suites

## Deliverables (five new files, nothing else touched)

| File | Lines | Role |
|---|---|---|
| `vajb-orbit/tests/headless_runner.gd` | 130 | headless runner (plain `Node`) |
| `vajb-orbit/tests/headless_runner.tscn` | 8 | runner scene, root `Node` + script |
| `vajb-orbit/tests/test_p1_catalogues.gd` | 10 tests | 02/03/11 catalogue data + rolls |
| `vajb-orbit/tests/test_p1_pricing.gd` | 5 tests | 05 §3 table, §5 worked examples, routing |
| `vajb-orbit/tests/test_p1_refinery.gd` | 6 tests | 04 §2/§3 conversions, refusals, log |

All three suites: `@tool`, `extends McpTestSuite`, `suite_name()` = `p1_catalogues` /
`p1_pricing` / `p1_refinery`, scripts preloaded by path, no scene, no editor API, no MCP.

## Gate evidence

Command (unchanged from the brief; default runs the whole directory):

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn

My three suites, scoped with the runner's optional flag (`-- --suite=<basename>`, repeatable):

| Command suffix | `[SUMMARY]` | exit |
|---|---|---|
| `-- --suite=test_p1_catalogues` | `[SUMMARY] passed=10 failed=0` | 0 |
| `-- --suite=test_p1_pricing` | `[SUMMARY] passed=5 failed=0` | 0 |
| `-- --suite=test_p1_refinery` | `[SUMMARY] passed=6 failed=0` | 0 |
| all three flags at once | `[SUMMARY] passed=21 failed=0` | 0 |

No `SCRIPT ERROR`, no `WARNING`, no `ObjectDB instances leaked` in those runs.

Whole-directory run (last, after all my files landed): `[SUMMARY] passed=25
failed=3`, exit 1. The 25 passes are my 21 plus p1l's `test_p1_clock_log.gd`
(4). The three failures are **not** mine — see "Sibling suites" below.

## Per-suite test counts

- **catalogues (10):** mineral shape (20, 4×5, unique), the full 20-row value
  table, `ore_units`/`ingot_units == 1`, id derivation + `is_ore`/`is_ingot`
  policy (40-item round trip), `SECTOR_TIER_MIX` vs 11 §1.1 for sectors 1..7,
  `TIER_BASE_YIELD` 6/5/4/3 + variance 0.5/1.5, seeded tier/yield/mineral rolls,
  component shape (18, 6 families × 3 grades), the full 18-row value table,
  grade sums 112/280/675 and their 19/47/113 integer means.
- **pricing (5):** `unit_net` table (Iron 64/38/102, Titanium 159/95/254, Gold
  387/232/619, Krillium 2117/1270/3387), Gold batch 4740/95/4645, component
  11 / gross 11 / fee 10 / paid 1, commission floor (`commission_for(0) == 0`,
  every positive gross < 500 → 10, 501 → 11), price routing (ore and ingot via
  `unit_net`, component via `component_unit_price` ignoring demand, bare and
  unknown ids → 0) plus `baseline_of`.
- **refinery (6):** the 17 §6 item verbatim (3 ore + 15 CR → 1 ingot, credits
  −15, exactly one `REFINE` line whose text is asserted), 8 ore → 2 conversions
  with 2 ore left, three refusals (`insufficient_ore`, `insufficient_credits`,
  `unknown_mineral`) each leaving credits/cargo/log untouched, `refine_all`
  (3 conversions, one 45 CR fee, one combined `all` log line), `nothing_to_refine`,
  `stacks()` filtering + counts/fees + constants.

## Reviewer notes

1. **`@tool` is required.** `test_handler.gd::_discover_suites` skips any script
   whose `can_instantiate()` is false, which in the editor means every non-tool
   script. The suites carry `@tool` so the same files pass the editor's
   `test_run` and the headless runner. The brief did not mention it.
2. **Runner deviation (deliberate).** A `test_*.gd` that fails to load or cannot
   be instantiated is printed as `[FAIL] <file>: …` and counted. My first draft
   only checked `script == null`, so a parse-broken suite was *silently skipped*
   and the run still reported `failed=0`. A broken suite must fail the gate, so
   the check is now `is GDScript` + `can_instantiate()` + non-null `new()`.
3. **Runner addition (optional).** `-- --suite=<file basename>` filters the
   discovery; no flag keeps the exact behaviour the brief specifies. It exists
   so one worker can produce a clean gate while siblings' files are mid-flight.
4. **Sibling suites (not touched).** `test_p1_market.gd`, `test_p1_profile.gd`
   and `test_p1_repairs.gd` (worker p1l) were written into `res://tests/` while
   this task ran and currently fail to parse:
   `Cannot infer the type of "profile" variable because the value doesn't have a
   set type` — `var profile := _fresh()` where the helper has no declared return
   type (12 sites in market, 12 in profile, 5 in repairs). They are the only
   reason the whole-directory run exits 1. p1l's `test_p1_clock_log.gd` loads
   and passes 4 tests.
5. **05 §2 raw-ore aside.** The doc's parenthetical prints Iron ore at demand
   1.0 as 17; `unit_net(18, 1.0)` is `round(17.64) == 18`. `exchange.gd`'s header
   calls the aside a typo (P1d report), so the suite asserts 18 and never 17.
6. **Two rounding bases.** Gold ingot at demand 1.2 is 465 per unit but 464.5 per
   unit inside the 10-unit batch (gross 4740, paid 4645). Both are documented in
   `exchange.gd`'s header; the suite asserts each in its own test.
7. **No state leaks.** `user://` after every run holds no `test_p1_*.cfg` and no
   `test_p1_log.txt`; `profile.cfg` mtime is unchanged (11:00:08, from earlier
   work) and `economy_log.txt` was never created. Profiles are freed in
   `teardown()`, so the runner never needs `_free_tracked()`.
