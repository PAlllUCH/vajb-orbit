---
slice: S11
worker: S11-B5
role: coder (continuation — the wave's tests and probes)
status: ready
tier: deepseek-direct        # owner's ruling; high reasoning
---

# S11-B5 — re-derive the rows the ticked constants reach (tests + probes only)

## Why this worker exists

B3 and B4 landed their code inside their sets, but three of the wave's consequences fell
outside those sets and the gate went red at **788/3**. §23.6's tests-that-move list is
amended to name them (it already did for `test_engine2_weapons.gd` in the brief's table and
did not for `test_s7_affixes.gd` — a planner omission, recorded in §23.6). Your job is the
rows, nothing else.

## Read first

1. `docs/CONTRACTS.md` **§23.4**, **§23.5** and the amended **§23.6** (the list you are
   closing) — the yardstick.
2. `slices/S11-legibility-gunnery-feel/S11-B3_report.md` and `S11-B4_report.md` — every row
   they measured and could not edit, with `file:line`.
3. `docs/CONTRACTS.md` **§9** for how the gate is run.

## Tasks

1. **`tests/test_engine2_weapons.gd:141-145`** — the four families' `range` reads
   `30000.0` (assert against `WeaponScript.NEAR_INFINITE_RANGE`, not a second literal) and
   `rocket` stays `900.0`. **Weaken no bound.**
2. **`tests/test_s7_affixes.gd`** — the three rows that resolve a `coast_time` against the
   *old* multiplier (B4 names `:71` wanting `2.625`, `:365`, `:375`). Prefer reading
   `ShipFit.COAST_TIME_MULT` so the row follows the pin instead of hardcoding a second copy;
   keep every other assertion identical.
3. **The probes' printed rows and prose** — `tests/probe_s2_6_flight.gd` (its lateral rows
   now equal the axial ones; the `LATERAL_DAMP_MULT` key list at `:45` and the prose at
   `:295-353` still describe the retired lateral drag), `tests/probe_g1_flight_feel.gd` (its
   spin-down rows move with T2), and `tests/probe_c3_flight_decay.gd` (see task 4). Update
   what the wave moved and the prose that now lies about it; change no constant the pin did
   not move.
4. **`tests/probe_c3_flight_decay.gd` — establish ownership before touching it.** B4 reports
   `cases=4 failures=4`, all four dying in the *accelerate* leg ("never reached 406.600 u/s"),
   which no file of this wave touches. Prove or disprove that it pre-dates the wave: create a
   worktree at the wave's pre-dispatch commit (`4c19812`) and run the probe there on a scratch
   store. **If it fails at the baseline too, it is not this wave's** — leave the file
   untouched and report it as a finding with both outputs. If it is green at the baseline,
   fix it inside your set.
5. **Report** `S11-B5_report.md`: the gate line (twice, fresh scratch stores), the exact rows
   you moved with before/after, and the probe-ownership verdict with both runs' evidence.

## Hard rules

- Write **only** `tests/test_engine2_weapons.gd`, `tests/test_s7_affixes.gd`,
  `tests/probe_s2_6_flight.gd`, `tests/probe_g1_flight_feel.gd`,
  `tests/probe_c3_flight_decay.gd` and your report. No game file, no `docs/`, no brief.
- Never weaken a bound to make a row pass; re-derive it to the ticked constant.
- Every Godot run: fresh `XDG_DATA_HOME=$(mktemp -d)`, `--quit-after`, stdout to a log.
  Never write the live profile. Never leave a background command.
- A row that still fails for a reason the pin does not explain is a **finding**, not a
  weakened assertion.
- The ARMORY's type sizes and colours and every pane's status strings are not yours
  (the D12 graphics lane and the pin respectively).
