---
slice: S11
worker: S11-R1
role: reviewer
status: ready
tier: deepseek-direct        # owner's ruling; high reasoning
---

# S11-R1 — review wave S11 (never fix)

## Read in this order

1. `docs/CONTRACTS.md` **§23** in full — this is the yardstick, not the brief. §22 and §14's
   amended flight-feel bullet are part of it.
2. `docs/CONTRACTS.md` **§9** (how the gate is run, what the expected line is) and **§10**
   (the changelog row you will add).
3. `slices/S11-legibility-gunnery-feel/S11_BRIEF.md` — the four workers' contracts and the
   tests-that-move list.
4. Each builder's report: `S11-B1_report.md`, `S11-B2_report.md`, `S11-B3_report.md`,
   `S11-B4_report.md`.
5. `AGENTS.md` — the gate command and the worker rules.

## What you owe

Re-measure **everything yourself** on the shipped tree; a builder's number is a claim, not
evidence. For each acceptance criterion in `SLICE.md`:

- **AC1/AC2 (inspector)** — drive a real hover (`Input.parse_input_event` on a row, or the
  live game via `godot-ai` if the editor is up) and read the shell block's title/body text;
  prove the clear on unhover; prove `describe`'s base-id resolution, its `""` for a
  description-less row and its affix-perk join; prove no existing status string was reworded
  (diff each pane's string table against `HEAD`).
- **AC3 (descriptions)** — spot-check the 35 `MODULES` rows against §23.2's table yourself,
  character by character on at least a third of them and name which; confirm every other key
  of every row is unchanged.
- **AC4 (credits)** — read the HUD block's value against the profile's real credits, move the
  balance, prove the update follows `profile_changed`, and prove nothing writes the profile
  (the live `profile.cfg` md5 before/after, plus a source read of the new code path).
- **AC5 (ranges)** — read the four families' `range` through `Weapons.range_of` and confirm
  rocket `900.0` / mine `0.0` unmoved; confirm `projectile.gd`'s fizzle contract and
  `game.gd`'s readout are byte-identical to `HEAD`.
- **AC6 (inertia)** — run the new stop suite and the three re-derived suites; then measure the
  owner's complaint **yourself**: release a commanded forward+strafe and report the velocity
  direction drift and the speed envelope as numbers. Confirm the commanded strafe still
  reaches the class rate, and confirm `LATERAL_DAMP_MULT` is genuinely unread.
- **AC7** — gate twice on two fresh scratch stores, identical counts, `failed=0`; the live
  store's md5s before/after with any movement attributed (the owner plays — a moved profile
  is not drift); `staging/verify_wave.py verify --baseline s11_start` with a captured exit
  code and `"problems": []`.
- **AC8** — the diff scope: every changed file inside its worker's declared set, no shell
  residue, no `git add -A`, no reformat-only churn. Report any edit outside a set as a
  finding.

## The wave's own hazards (measure these specifically)

- **The inspector must not be a second writer of the status strip.** A hover that overwrites
  a refusal line is a defect; prove the two are independent.
- **The credits block must not become a second source of truth** — it reads the profile, it
  never caches a balance across a write.
- **The one-vector decay must not slow the commanded strafe** — a fix that unifies the decay
  by weakening the commanded compensation would pass the stop test and break the strafe.
- **`NEAR_INFINITE_RANGE` must not reach the rocket or the mine**, and the beam's `reach` must
  still shorten a shot by the ray's own hit point (a beam drawn through a target it did not
  reach its cap on is a defect).
- **T3 is held**: nothing may implement `STRAFE_RATE_MULT`.

## Deliverable — `S11-R1_review.md`, ≤150 lines

- Header: the tree you measured (`git log -1 --format=%h`), the gate lines, the live-store
  md5s, the editor session id if you used it.
- Findings tiered **HIGH / MED / LOW**, each with `file:line`, the measured value, the §23
  row it violates and one line of evidence route. No source pasting.
- Verdict line, then: `docs/CONTRACTS.md` **§9** (the expected `passed=N failed=0` with the
  `775 → N` attribution) and **§10** (the next free row — read it from the file; D11 may have
  landed first, in which case sequence after it, never revert).
- LOW rows appended to `_state/LOW_BACKLOG.md` at the **next free ids read from that file**
  (never reserved in advance — D11 and the D12 lane are live).
- Close with `problems: []` and anything you could not measure.

## Hard rules

- Never fix. Never edit a source file, a brief or another report. `docs/CONTRACTS.md`,
  `_state/LOW_BACKLOG.md` and your own review file are your only writes.
- Bound every Godot run; never leave a background command; use a scratch `XDG_DATA_HOME` for
  every gate and probe.
- Never touch `slices/D11-station-scene/**`, `dispatch_designer.md`, `staging/**`,
  `assets/**` or `docs/archive/**`.
