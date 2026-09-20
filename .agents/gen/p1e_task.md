# P1e task — refinery module (docs 04, 01 §7)

Worker: coder. Wave: P1 economy core. Deliverable: exactly one new file:

`vajb-orbit/game/refinery.gd`

Do not touch any other file. No MCP tools. Do not run the editor. Do not edit
`addons/`, `project.godot`, docs, or any existing script.

Depends on files that may land around the same time (read them if present):
- `game/mineral_catalog.gd` — `class_name MineralCatalog`; `mineral()`,
  `ore_id()`, `ingot_id()`, rows with `name`, `ingot_value`.
- `game/economy_log.gd` — `EconomyLog.append(event, item, qty, delta, balance)`.
- `autoload/player_profile.gd` — `cargo_qty`, `remove_cargo`, `add_cargo`,
  `spend`, `credits`.

## Read first

- `docs/gameplay/04_refinery.md` — ALL. §2 is the conversion rule, §3 the fee
  schedule, §5 the interaction contract.
- `docs/gameplay/01_economy_core.md` — §7 (ordering + log).
- `docs/gameplay/17_coder_handoff.md` — §5, §6 (the "3 Iron ore + 15 CR fee
  -> 1 Iron ingot" assertion).

## Contract

`class_name Refinery extends RefCounted`. Preload dependencies by path; do not
reference autoload identifiers. Header cites 04.

Constants (04 §3):

- `const FEE_PER_UNIT := 5`
- `const ORE_PER_INGOT := 3`
- `const FEE_PER_CONVERSION := 15` (derive it from the two above)

API:

- `static func fee_for(conversions: int) -> int` — 0 for <= 0.
- `static func convertible(profile: Node, mineral_id: StringName) -> int` —
  `profile.cargo_qty(ore_id) / ORE_PER_INGOT` (integer division), 0 for an
  unknown mineral.
- `static func stacks(profile: Node) -> Array[Dictionary]` — read-only helper
  for the panel: one entry per mineral with at least one conversion
  available, in catalogue order: `{&"mineral_id": StringName, &"entry":
  Dictionary, &"ore_qty": int, &"conversions": int, &"fee": int}`.
- `static func refine(profile: Node, mineral_id: StringName, conversions: int)
  -> Dictionary` — one batch transaction:
  - verify: mineral known (`unknown_mineral`), `conversions >= 1`
    (`invalid_count`), `cargo_qty(ore_id) >= 3 * conversions`
    (`insufficient_ore`), `credits() >= fee` (`insufficient_credits`).
  - failure returns `{&"ok": false, &"reason": reason, ...}` and touches
    nothing.
  - take -> pay -> give (verify, then `remove_cargo(ore_id, 3n)`, then
    `spend(fee)`, then `add_cargo(ingot_id, n)`). If the defensive
    `remove_cargo`/`spend` steps fail anyway, restore what was taken
    (`add_cargo` the ore back; `add_credits` the fee back) and return the
    refusal — no partial state may survive.
  - log: `EconomyLog.append("REFINE", ore_id, 3 * conversions, -fee,
    profile.credits())` (01 §7; the doc 05 §8 line shape, event REFINE).
  - success returns `{&"ok": true, &"mineral_id": ..., &"conversions":
    int, &"ore_taken": int, &"ingots": int, &"fee": int}`.
- `static func refine_all(profile: Node) -> Dictionary` — the 04 §5 REFINERY
  ALL action: compute every convertible stack, total fee; verify credits >=
  total (`insufficient_credits`); execute the whole batch as one confirmed
  action. Returns `{&"ok": bool, &"reason": StringName, &"conversions": int,
  &"ingots": int, &"fee": int, &"minerals": Array[StringName]}`. If the total
  fee is 0 (nothing convertible) refuse with `nothing_to_refine`. Per-stack
  execution uses the same take -> pay step as `refine` (a single log line per
  mineral, or one combined line for the batch — choose one and document it in
  the header; combined is preferred).

## Known doc conflict (do not resolve silently)

`04_refinery.md` §5 says `remove_cargo(mineral_id, 4n)` while §2 and the
17 §6 test fix the ratio at 3 ore -> 1 ingot. Implement **3n** (04 §2 and
17 §6 agree) and say so in the header comment and the report.

## Constraints

- Deterministic: no randomness anywhere in this module (04 §3).
- Integers only; never mutate the profile through anything but its public
  API; no `print()`; typed GDScript, tabs, house header.

## Parse gate (required)

Probe scene `res://tools/_probe_p1e.tscn` + `_probe_p1e.gd`, off-tree profile
with `profile.save_path = "user://p1e_probe.cfg"` before any mutation. Assert
with printed evidence:

1. `fee_for(1) == 15`, `fee_for(3) == 45`, `fee_for(0) == 0`.
2. Give 3 `mineral_iron` + credits 1000 -> `refine(iron, 1)` -> ok, cargo is
   exactly 1 `ingot_iron` and no `mineral_iron`, credits 985, one REFINE line
   in `user://p1e_probe_log.txt` (via `EconomyLog.log_path`).
3. Give 8 `mineral_gold`: `convertible == 2`; `refine(gold, 2)` leaves 2 ore
   and adds 2 ingots (partial stacks untouched, 04 §2).
4. Refusals: 2 ore -> `insufficient_ore` (nothing moved); credits 10 ->
   `insufficient_credits` (nothing moved); unknown mineral -> `unknown_mineral`.
5. `refine_all` with two convertible stacks converts both with one total fee
   and returns the summary; with nothing convertible -> `nothing_to_refine`.
6. `stacks` lists only convertible minerals with right counts and fees.

Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1e.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, no `SCRIPT ERROR`. Do NOT
use `--check-only --script`. Delete the probe files and any `.uid` sidecars
they got, and the probe cfg/log files in `user://`, before you finish.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — no `$` in PowerShell.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1e_report.md`: deliverables, exact commands + observed
output, every probe assertion with its result, the 04 §5 conflict note, and
anything a reviewer should look at. Under 100 lines.
