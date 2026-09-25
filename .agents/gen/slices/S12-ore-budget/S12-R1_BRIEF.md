---
slice: S12
worker: S12-R1
role: reviewer
status: ready
tier: paid
---

# S12-R1 — replay review of the two probes

Read: `S12_BRIEF.md` (whole), `SLICE.md` (AC1–AC5), both probes, both reports,
`docs/CONTRACTS.md` §5 lines 345-375, and `01 §5.6` / `02 §5.1`.

## Task
Review by measurement (the W8 method the WAVEBOARD pins: re-run the builder's
probe byte-identically; never trust a report).

1. **Replay.** On a detached worktree at this slice's baseline commit, run both
   probes twice each and diff against the reports' pasted output. Any byte
   difference is HIGH.
2. **Constants.** Re-read independently every constant §4's table names, by
   grepping the owner file, and check the probes' printed values against it. Use
   `probe_s12_r1_constants.gd` only if you need a second reading; say so in the
   review if you do not create it.
3. **The mirror.** Diff the probes' two mirror sites line by line against
   `game/mining_laser.gd:195-202`, `game/projectile.gd:769-773` and
   `game/asteroid_field.gd:400-420`. A mirror that has drifted (a number, an
   order, a unit) is HIGH even when the number it prints still looks right.
4. **AC4 grep.** Grep both probes for a re-declared number (0.10, 1.2, 45, 0.6,
   6/5/4/3, 40, 27) and for a `user://` write; report every hit.
5. **The arithmetic.** Recompute the docs' claims from the probes' own numbers
   and say which hold and which fail: 13.5 units/s of 3-cannon depletion, 0.83
   units/s of laser extraction, ≈16.75 rocks and ≈100 units from a fully worked
   T1 Large rock.
6. **Scope.** Prove no production file was touched (`git status --short` is
   evidence) and that the gate reads 807/0 on the probe commit.

## Output contract
- Review: `.agents/gen/slices/S12-ore-budget/S12-R1_review.md` (≤150 lines, from
  `_templates/REVIEW.md`), findings as `<WorkerID>/F##` with HIGH/MED/LOW, one
  evidence line each.
- LOW rows appended to `.agents/gen/_state/LOW_BACKLOG.md` as `L184+`, following
  the file's row shape; never delete a row.
- No fixes. A fixer pass is a separate dispatch, and for this wave it may touch
  probe files only.
- Publish the ratio table in the review: the number tables are this wave's
  deliverable, and the owner reads the review, not the logs.
