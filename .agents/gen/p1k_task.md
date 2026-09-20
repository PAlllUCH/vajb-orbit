# P1k task — headless test runner + catalogue/pricing/refinery suites

Worker: coder. Wave: P1 economy core, tests. Deliverables, exactly five new
files:

1. `vajb-orbit/tests/headless_runner.tscn` + `vajb-orbit/tests/headless_runner.gd`
2. `vajb-orbit/tests/test_p1_catalogues.gd`
3. `vajb-orbit/tests/test_p1_pricing.gd`
4. `vajb-orbit/tests/test_p1_refinery.gd`

Do not touch any other file. No MCP tools. Do not run the editor.

## Read first

- `vajb-orbit/addons/godot_ai/testing/test_suite.gd` — `McpTestSuite` base
  class: `suite_name()`, `suite_setup(ctx)`, `setup()`, `teardown()`,
  `suite_teardown()`, `_reset()`, and the `assert_*` methods. Suites subclass
  it; the same files must run under the editor's `test_run` tool AND the
  headless runner you write.
- `docs/gameplay/17_coder_handoff.md` — §6 is the test checklist your suites
  implement (02/05 pricing, 04 refinery).
- `docs/gameplay/05_exchange.md` — §3 and §5 (exact expected numbers).
- `docs/gameplay/04_refinery.md` — §2/§3.
- `vajb-orbit/game/mineral_catalog.gd`, `game/component_catalog.gd`,
  `game/exchange.gd`, `game/refinery.gd`, `game/economy_log.gd`,
  `autoload/player_profile.gd`, `autoload/world_clock.gd` — read the static
  API contracts before writing assertions.

## The headless runner

`headless_runner.gd` is a plain `Node` script (not a suite). In `_ready()`:

- `DirAccess.open("res://tests")`, collect files matching `test_*.gd`.
- For each: `load(path)`, `new()`, skip anything that is not a
  `McpTestSuite`; for every method whose name begins with `test_` (use
  `get_method_list()`), run it: `suite.call("_reset")`, `suite.setup()`,
  `suite.call(method)`, `suite.teardown()`.
- After each test read `suite.get("_failed")` and `suite.get("_message")`;
  print `[PASS] <File>.<method>` or `[FAIL] <File>.<method>: <message>`.
- Call `suite_setup({})` once per suite, `suite_teardown()` at the end.
- Print a final `[SUMMARY] passed=<n> failed=<n>`, then
  `get_tree().quit(1 if failed > 0 else 0)`.
- No editor APIs (this must run headless), no `EditorInterface` usage.

Run command (both this runner and the suites must stay compatible):

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn

(No `--quit-after`: the runner quits itself; use `--quit-after 1200` as a
safety net only if you must.)

## Suite rules (all three files)

- `extends McpTestSuite`, `suite_name()` returns a short lower-case id.
- **Never touch `user://profile.cfg` or `user://economy_log.txt`.** Every
  profile instance is `load("res://autoload/player_profile.gd").new()` with
  `save_path = "user://test_p1_<suite>.cfg"` set **before** any mutation;
  `EconomyLog.log_path = "user://test_p1_log.txt"`. Delete these files in
  `suite_teardown()` (and before the first test).
- Pure logic only: no scene instancing, no editor dependencies, no MCP.
- Each test method is independent; create fresh profiles per test.
- Seeds: use `RandomNumberGenerator` with `seed` set for deterministic rolls.

## Suite 1 — `test_p1_catalogues.gd`

- 20 minerals, 4 tiers x 5; 18 components, 6 families x 3 grades.
- Exact value table for all 20 minerals (ore/ingot) copied from 02 §2, plus
  `ore_units == ingot_units == 1`.
- Id derivation: `ore_id("iron") == &"mineral_iron"`,
  `ingot_id("gold") == &"ingot_gold"`, `mineral_id_of_item` round-trips all
  40 item ids, `is_ore`/`is_ingot` policy per the catalogue header.
- `SECTOR_TIER_MIX` equals 11 §1.1 for sectors 1..7; `TIER_BASE_YIELD` is
  6/5/4/3; `YIELD_VARIANCE_MIN/MAX` 0.5/1.5.
- Component values from 03 §3 for all 18; assert the per-grade sums
  (112 / 280 / 675 for grades I / II / III, the integer form of 03 §3.1's
  19 / 47 / 113 averages).

## Suite 2 — `test_p1_pricing.gd`

Implement exactly the 17 §6 assertions:

- `Exchange.unit_net` reproduces the 05 §3 table for Iron (65), Titanium
  (162), Gold (395) and Krillum (2160) ingots at demand 1.0 / 0.6 / 1.6:
  64/38/102, 159/95/254, 387/232/619, 2117/1270/3387.
- `Exchange.sale_quote(395, 1.2, 10)` -> gross 4740, fee 95, paid 4645.
- Component worked example: `component_unit_price(12) == 11`;
  `sale_quote(11, 1.0, 1)` -> gross 11, fee 10, paid 1.
- Commission floor: any positive gross below 500 pays fee 10; `gross == 0`
  pays fee 0 (no sale); `commission_for(0) == 0`.
- `exchange_price` for an ore equals `unit_net(ore_value, demand)`; for a
  component equals `component_unit_price`; unknown id -> 0.

## Suite 3 — `test_p1_refinery.gd`

- The 17 §6 checklist item verbatim: 3 `mineral_iron` + 15 CR fee -> exactly
  1 `ingot_iron`, credits minus 15, one REFINE log line (log path redirected).
- Partial stack: 8 gold ore -> 2 conversions; after refining 2, 2 ore remain,
  2 ingots held.
- Refusals leave everything untouched: 2 ore (`insufficient_ore`), credits
  below fee (`insufficient_credits`), unknown mineral (`unknown_mineral`).
- `refine_all` converts two stacks with one combined fee; `nothing_to_refine`
  when no stack has 3 ore.
- `stacks()` returns only convertible minerals with correct counts/fees.

## Gate

Run the runner once after each suite lands and once at the end; evidence in
the report: exact command, `[SUMMARY]` line, exit code. Requirements:
`failed=0`, exit 0, no `SCRIPT ERROR`. Do NOT use `--check-only --script`.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — no `$` in PowerShell.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1k_report.md`: deliverables, command + `[SUMMARY]` output,
per-suite test counts, and anything a reviewer should look at. Under 100
lines.
