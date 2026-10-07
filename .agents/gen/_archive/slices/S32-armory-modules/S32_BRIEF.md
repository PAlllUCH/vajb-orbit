---
slice: S32
worker: S32-B1 (→ S32-R1 → S32-F1 if HIGH/MED)
role: coder
status: ready
tier: paid — roster owner-pinned: code `hyper/deepseek-v4.1-flash`, review `hyper/glm-5.3-flash`
---

# S32_BRIEF — the ARMORY two-module rework (2026-10-04)

## The law to read, in order
1. `docs/design/STATION_HUB.md` **§20.1** (pins P32–P37 — your only numbers) + **§19** (the pane skeleton)
2. `docs/design/UI_SPEC.md` **§13.1** (N45's trim law) + **§11.1** (A5.5/N24) + **§3.10** Amendment 5 (the ARMORY = the worked example of the container law)
3. `docs/gameplay/09_ship_slots_modules.md` **§10–§12** (L555-746 — what a battery is; the 5×4 hardcap)
4. `slices/D20-station-playtest/D20_synthesis.md` **§3** (grounding: the profile doors and what exists today)

## The owner's request (verbatim, 2026-10-03, note 2)
> in armory the "modules owned and buyable" shifts out of screen. make the armory more like 2 separate modules not all on 1 screen. first module where i select cell and get info what the cell is, what i have that can be slotted there and select/drag fit items. second to create battery configurations based on fitted weapons.

Ticks decided at the owner's go 2026-10-04: **T-125 = two full-screen modes** (one at a time), **T-126 = rack regrouping + SALVO/cycle readout only** (no presets). Runs after S31 (both rewrite `ui/station/`).

## Spec extract (verbatim — `STATION_HUB.md` §20.1; the Reversal column is the not-taken path)
| Pin | Law | Reversal |
|---|---|---|
| **P32** | ARMORY is one pane with **two full-screen modes** — `FIT CELLS` and `BATTERY CONFIG` — behind a two-entry mode switch (P2 `ActionInline` pair, UI_SPEC §8) in the pane's header band; exactly one mode is visible at a time and switching is a pure visibility operation under A5.5 | two side-by-side halves (the shipped single screen) |
| **P33** | **FIT CELLS** carries three blocks: (1) the shipped cell grid (23 cells + 3 engines) with a real **CELL INFO block** replacing the one-line SelectionLine — cell id + family, power draw, fitted module or `EMPTY`, and the legality line (`armory_panel.gd:86-90`'s refusal strings wired as proactive hints); (2) **FITS HERE** — everything the profile owns that can slot in the selected cell (family + `fit_legal` filtered), each row select-to-fit and drag-to-fit; (3) **BUYABLE THAT FITS** — the browser's buy side filtered to the selected cell, with `BUY` + `INSPECT` | the family-tab browser as the only filter; the one-line SelectionLine |
| **P34** | **BATTERY CONFIG** is the rack editor over **fitted weapons only**: B1–B5 racks (09 §12's hardcap), drag between racks writes `set_battery_groups`, empty cells read-only `W<n> — EMPTY` (09 §10's idiom); each rack shows its SALVO pip meters and its `battery_cycle` (the slowest member's cooldown) | fit/unfit-only racks welded to the one screen |
| **P35** | no loadout presets (T-126): the editor composes the live fit only | saved battery sets |
| **P36** | AMMUNITION and the PWR meter live in a shared foot band on both modes — the 264 px BodyScroll fold and T-122's dead space die with the rework | the below-fold console band |
| **P37** | both modes' lists are full-width columns of the mode (UI_SPEC §13.1 N45's trim law applies to every row) — no list is ever a 490 px half | a split half-list |

## Task
Rewrite `ui/station/armory_panel.gd` + `.tscn` into the two modes (the pane keeps its public seams — the drag contract (right-click pulls, keys 1–5 select racks), the foot hints, whatever `tests/` calls). Battery writes go ONLY through the existing profile doors (`set_fit`/`fit_battery`/`clear_battery`/`set_battery_groups`) — never a new profile shape. `battery_cycle` = the slowest member's cooldown (read the catalogue rows; `weapons.gd` already computes it). The mode switch is pure visibility (A5.5). N45's 160 px ellipsis trim applies to every row of both modes.

## Acceptance list (the report answers each with `file:line` / measured numbers)
1. P32: two modes + the switch; exactly one visible (probe: toggling hides the other).
2. P33: CELL INFO block shows cell id + family + draw + fitted/`EMPTY` + legality for the selected cell; FITS HERE lists exactly the legal owned candidates (probe against `fit_legal`); select-to-fit and drag-to-fit both work; BUYABLE THAT FITS filters to the cell and `BUY` works.
3. P34: B1–B5 racks over fitted weapons only; a drag between racks persists through `set_battery_groups` (probe the profile after a move); `W<n> — EMPTY` read-only rows; SALVO pip meters + `battery_cycle` per rack (correct = the slowest member's).
4. P35: no preset/save UI anywhere (grep evidence).
5. P36: AMMUNITION + PWR in the foot band on both modes; no BodyScroll fold remains.
6. P37: every row's controls within 1920×1080 (measured rects, longest names included).
7. Gate before/after `[SUMMARY]` lines; every moved test row disclosed; gate green.

## Hard constraints
- File set: `vajb-orbit/ui, vajb-orbit/tests` (hook-enforced). No `docs/`, `game/`, `autoload/`, `addons/`.
- A5.5/N24 + §3.10 A5 (containers + relative positioning, never coordinates; chrome via theme stylebox or sibling node).
- Never silently change a pin: disclose at the closest value with a one-line reversal.
- Every Godot run bounded (`--quit-after`); never leave a background command.

## Tests that move (heavy)
`tests/test_p2b1_outfitting_panel.gd` (panel structure → the two modes), `tests/test_s5_batteries_v2.gd` (rack drag/regroup seams), `tests/test_s20_chrome_unify.gd` (chips/bands), `tests/test_s30_shell.gd` (census/skeleton rows). New rows: the mode-switch visibility law, CELL INFO contents, FITS HERE + BUYABLE THAT FITS filtering, rack regroup → `set_battery_groups`, `W<n> — EMPTY`, the shared foot band. Failures stay 0; counts move with disclosure.

## Output contract
- Report: `slices/S32-armory-modules/S32-B1_report.md` (≤120 lines, `_templates/REPORT.md` shape).
- Gate: `XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 2>&1 | grep -E '\[SUMMARY\]|SCRIPT ERROR'` — before and after, ×2 fresh scratch after; always grep `[SUMMARY]`.

## Run order
S32-B1 (`hyper/deepseek-v4.1-flash` @ xhigh) → S32-R1 (`hyper/glm-5.3-flash` @ max) → S32-F1 (as B1) **only if HIGH or MED**. Then close-out (gate ×2, `verify --baseline s32_start`, `build_code_map`, TICKS/WAVEBOARD/`MASTER_REPORT.md` §6, commit).

## Owner tick list
None open — T-125/T-126 decided at the go. If the build discovers the owner's note implies something these pins miss: report it, don't re-pin.
