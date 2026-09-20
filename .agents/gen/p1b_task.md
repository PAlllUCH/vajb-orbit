# P1b task — world clock + economy log (docs 17 §2/§4, 01 §7, 14 §9)

Worker: coder. Wave: P1 economy core. Deliverables, exactly two new files:

1. `vajb-orbit/autoload/world_clock.gd`
2. `vajb-orbit/game/economy_log.gd`

Do not touch any other file. No MCP tools. Do not run the editor. Do not edit
`project.godot`, `addons/`, docs, or any existing script. The autoload
registration for `world_clock.gd` is done by the orchestrator later — your job
is only the script.

## Read first

- `docs/gameplay/17_coder_handoff.md` — §2 (file map), §4 (the one-timer
  rule), §5 (transaction law).
- `docs/gameplay/01_economy_core.md` — §7 only (transaction log format).
- `docs/gameplay/14_station_services.md` — §9 only.
- `docs/gameplay/05_exchange.md` — §2 and §4 for what consumes the clock.
- `vajb-orbit/autoload/settings_manager.gd` and
  `vajb-orbit/autoload/player_profile.gd` — house style for autoload scripts
  (typed GDScript, tabs, header comment, `push_warning` on failures, no
  `print`).

## Contract — `autoload/world_clock.gd`

`extends Node`, **no `class_name`** (an autoload with a matching class_name is
refused by Godot — house gotcha). Header comment: the one 20-minute clock;
five consumers (exchange bands 05, auction rotation 10, contract re-roll 14,
arena cooldowns 14, sector respawn 11); evaluated lazily at station entry and
at each transaction; no per-consumer Timers, ever.

Design decision to document in the header: the clock is the system Unix time
in whole seconds, so persisted "last evaluated" stamps survive process
restarts; a band is any 20-minute window since the consumer's stamp. The
static API exists so callers can preload the script and use the same math
without touching the autoload node.

Exact API:

- `const BAND_SECONDS := 1200`
- `static var _override := -1` (private)
- `static func now() -> int` — override when set, else
  `int(Time.get_unix_time_from_system())`.
- `static func bands_between(from_timestamp: int, to_timestamp: int) -> int` —
  `0` when either stamp is `<= 0` or `to <= from`; else integer
  `(to - from) / BAND_SECONDS`.
- `static func set_override(timestamp: int) -> void`,
  `static func clear_override() -> void`,
  `static func has_override() -> bool`.

Keep the instance side empty (no `_process`, no Timer). The autoload node's
only job is to exist.

## Contract — `game/economy_log.gd`

`class_name EconomyLog extends RefCounted`. Header: append-only debug log
(01 §7), one line per economy event, never shown in UI.

- `const DEFAULT_PATH := "user://economy_log.txt"`
- `static var log_path: String = DEFAULT_PATH` — documented test override.
- `static func append(event: String, item: StringName, qty: int,
  credits_delta: int, balance: int) -> void` — appends one line:
  `timestamp, event, item, qty, credits_delta, balance`
  - timestamp: `Time.get_datetime_string_from_system(true)` (ISO, UTC).
  - credits_delta: signed, `+1117` / `-15` style formatting.
  - Open with `FileAccess.open(log_path, FileAccess.READ_WRITE)`, seek to
    `get_length()` before writing, close via the local handle going out of
    scope. If the open fails, `push_warning` and return (never crash a
    transaction because the log is unwritable).
  - The function never emits signals, never touches the profile.

## Parse gate (required)

Create a probe scene `res://tools/_probe_p1b.tscn` + `_probe_p1b.gd` that in
`_ready()`:
- preloads both scripts; calls `EconomyLog.append("TEST", &"comp_scrap_1", 2,
  +22, 10022)` with `EconomyLog.log_path` pointed at
  `user://p1b_probe_log.txt`; reads the file back and asserts the line shape;
  deletes the temp file.
- asserts `Clock.bands_between(0, X) == 0`, `bands_between(1000, 2199) == 0`,
  `bands_between(1000, 2200) == 1`, `bands_between(1000, 3400) == 2`.
- prints `PROBE OK`; then `get_tree().quit()`.

Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1b.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, no `SCRIPT ERROR`. Do NOT
use `--check-only --script`. Delete the probe files and any `.uid` sidecars
they got before you finish.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — write PowerShell with
  no `$`.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1b_report.md`: deliverables table, exact commands with
observed output, probe evidence, and anything a reviewer should look at.
Under 80 lines.
