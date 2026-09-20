# P1b report — world clock + economy log

## Deliverables

| File | Owns | Contract |
|---|---|---|
| `vajb-orbit/autoload/world_clock.gd` | the one 20-minute accumulator: `BAND_SECONDS`, static `now()` / `bands_between()` / `set_override()` / `clear_override()` / `has_override()`; no `class_name`, no `_process`, no Timer | 17 §4, 14 §9, 01 §7 |
| `vajb-orbit/game/economy_log.gd` | `class_name EconomyLog extends RefCounted`: `DEFAULT_PATH`, static `log_path`, static `append(event, item, qty, credits_delta, balance)`; append-only, warns instead of failing a transaction | 01 §7, 17 §5 |

Nothing else touched: no edit to `project.godot`, `addons/`, docs or any existing script. No MCP tools used, editor never launched (an editor session was already listening on 6005; the probe ran headless in a separate process).

## Commands and observed output

Probe run (the §"Parse gate" command, verbatim):

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1b.tscn --quit-after 300

    Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
    [godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
    LINE1 <2026-09-18T09:17:36, TEST, comp_scrap_1, 2, +22, 10022>
    LINE2 <2026-09-18T09:17:36, SELL, ore_iron, 3, -15, 10007>
    PROBE OK
    EXIT=0

Exit 0, `PROBE OK` on stdout, no `SCRIPT ERROR` anywhere. `--check-only --script` was not used.

## Probe evidence

`tools/_probe_p1b.gd` + `.tscn` (created, run, then deleted along with any `.uid`):
`EconomyLog.log_path` pointed at `user://p1b_probe_log.txt`, file pre-removed, two appends
(`TEST/comp_scrap_1/2/+22/10022` and `SELL/ore_iron/3/-15/10007`), read back and asserted:
exactly two lines, six `, `-separated fields each, ISO timestamp (`length >= 19`, contains `T`),
event/item/qty/balance literal, signed `+22` and `-15` formatting, second line present proves
append does not truncate. Temp file removed afterwards; restored `log_path` to `DEFAULT_PATH`.
Clock: `BAND_SECONDS == 1200`; `bands_between(0, 5000) == 0`; negative stamp `== 0`;
reversed range `== 0`; `(1000, 2199) == 0`; `(1000, 2200) == 1`; `(1000, 3400) == 2`;
`has_override() == false` then `now() > 0`; `set_override(5000)` → `now() == 5000` and
`bands_between(5000, 6200) == 1`; `clear_override()` → `has_override() == false`.
The gate fails loudly: the first run (before the fix below) printed `PROBE FAIL` and exited 1.

## Deviations a reviewer should look at

1. **`FileAccess.READ_WRITE` does not create a missing file on 4.7.2.** The contract's open
   mode is kept as the primary path, but the very first line of a fresh log file needed a
   fallback. Evidence from a scratch diagnostic (also deleted):
   `READ_WRITE_fresh: OPEN FAILED error=7` (= `ERR_FILE_CANT_OPEN`), `WRITE_fresh: ok`,
   `WRITE_READ_fresh: ok`; then create-then-`READ_WRITE` appends verified:
   `content=<A|B|>` (no truncation). `_open_for_append()` therefore opens `READ_WRITE`, and
   only when the file does not exist creates it with `WRITE` and reopens `READ_WRITE`. Append
   semantics, `seek(get_length())` and "close via the handle going out of scope" are unchanged;
   any other failure still `push_warning`s and returns (error 7 was observed and survived the
   first probe run without crashing the caller).
2. **Pre-existing noise, not mine.** Every headless run logs 8 `ERROR` lines from
   `autoload/player_profile.gd:498-579` (`Couldn't find the given section "profile" and key
   "modules"/"fits"/"market"/"heat"/"standing"/"contracts"/"vaults"/"vitals"`): the saved
   `user://profile.cfg` predates the new v2 keys. That file is P1a's (17 §3 migration); it is
   not touched here and is not caused by these two scripts.
3. **No `.uid` sidecars** were emitted for the two new scripts (headless run, no import step);
   the editor's next reimport produces them, like the other scripts in those folders.
4. `tools/_probe_p1a.gd` / `.tscn` belong to the P1a worker and were left untouched.
