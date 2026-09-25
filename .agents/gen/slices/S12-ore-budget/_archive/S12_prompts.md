# S12_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (DeepSeek API direct, owner ruling
2026-09-24; fallback `opencode-go/deepseek-v4.1-flash`) on `--reasoning-effort high`. Both
probes are read-only measurements, so nothing here is a `max`-effort job; R1 is `high`.

Every line sets `VAJB_SLIM=1` (the standing rule) and `VAJB_WORKER_FILES` to that worker's
own set **plus its report path**. Hosts: `$VAJB_WORKSPACE`, `$VAJB_PROJ`, `$GODOT_CONSOLE`
and the interpreter name come from `crushrc` / `environment.d`; if your shell has not
sourced them, substitute the workspace root for `$VAJB_WORKSPACE` (the only host-specific
value these lines need).

**Before the first dispatch** (docs are already amended in the working tree by the owner's
session; this stages *only* the wave's own files — any other dirty file in the tree belongs
to another lane and is left alone):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s12_start \
  && git add docs/gameplay/01_economy_core.md docs/gameplay/02_minerals.md \
       .agents/gen/slices/S12-ore-budget .agents/gen/dispatch_coder.md \
       .agents/gen/_state/WAVEBOARD.md \
  && git commit -m "docs: rule that shooting rocks may never out-earn mining" \
  && git tag s12_start
```

## Run order

**S12-K0 ∥ S12-K1** (disjoint files) → **S12-R1**. A fixer pass only if the review
leaves HIGH or MED, and for this wave it may touch probe files only.

## Wave 1 — the two probes

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/probe_s12_field_budget.gd,.agents/gen/slices/S12-ore-budget/S12-K0_report.md' \
     crush run "You are worker S12-K0 on the Vajb Orbit workspace, wave S12. Read .agents/gen/slices/S12-ore-budget/S12_BRIEF.md end to end first — its section 4 is the pinned measurement contract and its section 8 the hard rules, and both bind every line you write. Then .agents/gen/slices/S12-ore-budget/S12-K0_BRIEF.md, and vajb-orbit/tests/probe_s2_6_burst.gd for the house probe shape. Task: create vajb-orbit/tests/probe_s12_field_budget.gd, a standalone 'extends SceneTree' probe that measures how much ore a seeded field holds and how much each depletion path realises from it. Three legs per section 4 — LASER, GUN3, GUNMAX — each on a freshly seeded field with FIELD_CONFIG exactly as pinned (tier_weights {1: 100}, rocks 6, seed 12061), plus the same three legs on a T3 field ({3: 100}, same rocks and seed). For each leg print: the field's sum yield_units when it is first built, the sum delivered ore units by section 4's per-leg definition (LASER counts apply_work returns; GUN legs count the amount field of the field's own pickup-group children), the out/in factor, the total rocks the field ever spawned, the steps taken, and the seconds the leg's rate implies. Print every constant of section 4's table with the value you read from its owner file — never re-declare a number: GUN_CHIP_RATE, shot_damage/interval_of for w_cannon, WORK_PER_UNIT, MINE_CYCLE, TIER_BASE_YIELD, FRAGMENT_SPLIT, PICKUP_BURST, the pickup group name, and the Vanguard's cargo from ShipFit.HULLS. Prefix every line [S12K0], end with [S12K0] done failures=N and exit 1 when N is above zero. Bound every leg (MAX_STEPS, MAX_SECONDS) and print a failure row rather than truncating silently. Do not edit any production file, the profile, or a live user:// — run every Godot command with its own XDG_DATA_HOME scratch store. Run the probe twice and confirm the output is byte-identical, then run the universal gate once and record the [SUMMARY] line. Write .agents/gen/slices/S12-ore-budget/S12-K0_report.md with the two runs' output, the how-to-run line, the budget table and both gate/probe lines." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s12_k0.log 2>&1
```

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/probe_s12_rock_rate.gd,.agents/gen/slices/S12-ore-budget/S12-K1_report.md' \
     crush run "You are worker S12-K1 on the Vajb Orbit workspace, wave S12. Read .agents/gen/slices/S12-ore-budget/S12_BRIEF.md end to end first — its section 4 is the pinned measurement contract and its section 8 the hard rules, and both bind every line you write. Then .agents/gen/slices/S12-ore-budget/S12-K1_BRIEF.md, docs/gameplay/01_economy_core.md section 5.6, and vajb-orbit/tests/probe_s2_6_burst.gd for the house probe shape. Task: create vajb-orbit/tests/probe_s12_rock_rate.gd, a standalone 'extends SceneTree' probe that measures delivered ore per second and per rock for the three legs of section 4 (LASER, GUN3, GUNMAX) on the same pinned seeded field (tier_weights {1: 100}, rocks 6, seed 12061). Use section 4's definitions verbatim: the LASER leg counts apply_work returns at one unit per MINE_CYCLE; the GUN legs apply shot_damage(w_cannon) times GUN_CHIP_RATE per shot and count only the pickup-group units the field's Small-end burst pays, with one shot's share of the wall clock being interval_of divided by the barrel count. Print per leg: delivered units/s, delivered units/rock, seconds to empty the field, total rocks spawned, and the mining-versus-gunning ratio against LASER; plus one single-rock row giving a seeded rock's yield_units in, the units each leg realises out of it, and its own seconds. Also print every constant section 4's table names with the value read from its owner file, the Vanguard's cargo and the maximum cargo over ShipFit.HULLS — never re-declare a number. Prefix every line [S12K1], end with [S12K1] done failures=N and exit 1 when N is above zero, and bound every leg with a printed failure row rather than a silent truncation. Do not edit any production file, the profile, or a live user:// — run every Godot command with its own XDG_DATA_HOME scratch store. Run the probe twice and confirm byte-identical output, then run the universal gate once and record the [SUMMARY] line. Write .agents/gen/slices/S12-ore-budget/S12-K1_report.md with both runs' output, the how-to-run line and the rate table." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s12_k1.log 2>&1
```

`crush run` prints only narration, so a silent log is normal. Poll with
`pgrep -af 'worker S12-K'` and read each report when its process exits; never end the
session while a worker is in flight.

## Wave 2 — the replay review (written at review-prep)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/probe_s12_r1_constants.gd,.agents/gen/slices/S12-ore-budget/S12-R1_review.md' \
     crush run "You are worker S12-R1 on the Vajb Orbit workspace, wave S12, in the reviewer role. Read .agents/gen/slices/S12-ore-budget/S12_BRIEF.md end to end, then SLICE.md, then both probes and both reports, then docs/CONTRACTS.md section 5 lines 345-375. Review by measurement, never by trusting a report, and use the W8 method the WAVEBOARD pins. One: replay both probes twice each on a detached worktree at the s12_start baseline commit and diff their output against the pasted output in the reports — any byte difference is HIGH. Two: re-read independently, by grepping the owner file, every constant section 4 of the brief names, and check the probes' printed values against yours; create vajb-orbit/tests/probe_s12_r1_constants.gd only if you need a second reading, and say so in the review if you create nothing. Three: diff the probes' mirror sites line by line against game/mining_laser.gd lines 195-202, game/projectile.gd lines 769-773 and game/asteroid_field.gd lines 400-420 — a drifted mirror is HIGH even when the printed number still looks right. Four: grep both probes for a re-declared number (0.10, 1.2, 45, 0.6, 6/5/4/3, 40, 27) and for any user:// write, and report every hit. Five: recompute the docs' claims from the probes' own numbers and say which hold and which fail — 13.5 units/s of three-cannon depletion, 0.83 units/s of laser extraction, and a fully worked T1 Large rock realising about 100 units from its own 6. Six: prove no production file was touched and that the gate reads 807/0 on the probe commit. Write .agents/gen/slices/S12-ore-budget/S12-R1_review.md from the review template, 150 lines maximum, findings as S12-K0/F## or S12-K1/F## with a tier and one evidence line each; append any LOW findings to .agents/gen/_state/LOW_BACKLOG.md as L184 onwards following the file's own row shape and never deleting a row; and publish the ratio table in the review, because the number tables are this wave's deliverable and the owner reads the review rather than the logs. Make no fixes." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s12_r1.log 2>&1
```
