---
slice: S16
reviewer: S16-R1
verdict: passed-with-followups
gate: "859/0 -> 866/0"
---

# S16-R1 review — fragment re-splits

Diff targets: `docs/gameplay/02_minerals.md` **§5.2 ter** (the pin) and **§5.1 Rule
A** (conservation) — never the brief. Every number below was re-measured by this
review on the shipped tree; nothing is copied from `S16-B1_report.md`.

## Per-AC re-measurement (W8 replay)

| AC | Requirement (02 §5.2 ter / §5.1) | Re-measured | Verdict |
|---|---|---|---|
| AC1 | a shot XL's L/M/S children cleave per their own class into strictly smaller children, ending at S | `[S16] AC1 shatters=18 passes=3 children_of_root=7`; mixed set carries L+M+S, each child `<` parent, S leaves nothing | pass |
| AC2 | every shatter in a shot chain pays 0 and no pickup spawns from owed 0 | `[S16] AC2 root_paid=1 fragment_shatters=18 total_paid=1`; every fragment `bore_ore == 0.0` | pass |
| AC3-gun | a fully shot family ≤ `GUN_BURST_SHARE × root bore + 1` | `[S16] AC3-gun root_bore=32.0 bound=4.200 realised=1 steps=19`; independently `probe_s12_field_budget` T1/T3 GUN3/GUNMAX `failures=0`, all legs `delivered ≤ cap` | pass |
| AC3-mine | a fully mined family at root bore ±1 (S14's row untouched, green) | `[S16] AC3-mine root_bore=32.0 family_realised=32 steps=76 rocks_spawned=53`; S14's own row reads the same `family_realised=32` | pass |
| AC4 | a yield-0 original still cleaves into nothing | `[S16] AC4 bare_cleaves=false marked_cleaves=true`; `test_engine2_cleaving.gd:627` (field-built original) green; `probe_rock_cleave` `BARE cleaves=false fragments=0` | pass |
| AC5 | every chain terminates; a fully shot XL leaves no live family rock | `[S16] AC5 passes=4 family_rocks=19 live_after=0`; `rocks().size()==0` | pass |
| AC6 | gate at baseline + the new rows, twice, hermetic, zero failures; no tunable moved | `[SUMMARY] passed=866 failed=0` twice on fresh `XDG_DATA_HOME`; `[S16] AC6 gun_share=0.10 core_share=0.25 mix_pinned=true marker_runtime_only=true` | pass |

Route greps (AC2/AC3):
- `_pay_burst` call sites are only `asteroid_field.gd:427` and `:431`, both inside
  `_cleave`; a 0-bore fragment's `owed = minf(reserve 0.0, 0.10 × 0.0) = 0.0`, so
  `_pay_burst` returns at `:506` before `_ore_credit` is touched. No minting path.
- `_rolled_yield` has exactly one caller, `asteroid_field.gd:237` (the field's own
  spawn roll). No shatter-side roll survives; the marker does not re-roll anything.
- `mark_cleave_child` has one definition (`asteroid.gd:409`) and one production
  call site (`asteroid_field.gd:460`); only `_cleave` marks, so a field spawn, a POI
  roll (`poi.gd:591`) and every `setup` fixture stay originals.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S16-B1/F1 | LOW | `docs/gameplay/02_minerals.md:278-282` | The pin's "a fully shot family realises **exactly** the root's capped burst" overstates the code: `_pay_burst` caps each burst by the tuned `pickup_burst` (1-2) and strands the remainder in `_ore_credit`, so a lone shot family realises **1** of the 3.2 cap. §5.1 Rule A's "at most" is the accurate wording. Evidence: `[S16] AC3-gun root_bore=32.0 bound=4.200 realised=1`. | bucket 2 (docs) → `T-…`/**L212** |
| S16-B1/F2 | LOW | `vajb-orbit/tests/test_s14_splits.gd:240` | S14's AC3 row prints a longer path under S16 (`steps 42→48`, `rocks_spawned 17→23`) because mining shatters now also split their 0-bore descendants; the asserted `family_realised=32` is byte-identical and the row is green. The file is on brief §3's candidate list, so **not** HIGH; recorded so the next W8 replay does not read the drift as a regression. | — (**L213**, already reported by B1) |
| S16-B1/F3 | LOW | `vajb-orbit/tests/test_s16_resplits.gd` | The new suite ships with no `.uid` (same class as L205/L211); the headless gate never writes one. Evidence: `ls vajb-orbit/tests/test_s16_resplits.gd*` → only `.gd`. | wave close-out (**L214**) |
| S16-B1/F4 | LOW | `vajb-orbit/game/asteroid.gd:247,289` | `setup` resets `_shatter_mining` but not `_cleave_child`, so a future reuse of an already-marked instance (a re-`setup`) would keep splitting at bore 0. No shipped path reuses one (`AsteroidScript.new` only in `_new_rock` and `poi.gd:588`, both fresh). | next `asteroid.gd` owner (**L215**) |

No HIGH and no MED: the implementation matches §5.2 ter on every bullet — parentage
(not ore) gates the cleave, only `_cleave` marks, no arithmetic or tunable changed
(`ore_tuning.gd` untouched, `split_mix` pinned by AC6), money stays under the cap,
and every chain terminates at S.

## Verified fixes
None — the review leaves 0 HIGH / 0 MED, so no fixer pass is triggered.

## Gate
`[SUMMARY] passed=859 failed=0` (S16_BRIEF §0 baseline, D8's close) → **`passed=866
failed=0`** twice on two fresh scratch stores (`XDG_DATA_HOME=$(mktemp -d)`, exit 0,
identical counts, zero `failed`; the only non-benign-looking line is the pre-existing
L61 `SCRIPT ERROR` at `test_weapon_fx_f4.gd:178`, unrelated to rocks and green).
Growth is exactly **+7** = `test_s16_resplits.gd`'s AC1-AC6 rows; no other suite's
`func test_` count moved.

Mandated verify: `staging/verify_wave.py verify --baseline s16_start --forbidden
vajb-orbit/project.godot docs/ vajb-orbit/ui/ vajb-orbit/addons/
vajb-orbit/autoload/ vajb-orbit/game/ore_tuning.gd --tests --expect-reports
…S16-B1_report.md …S16-R1_review.md` → **`"problems": []`**, exit 0 (gate run inside
it reads 866/0). Negative controls / independent probes:
- `probe_rock_cleave` → `[RC] done failures=2`, the two rows L202 already owns (the
  `BARE` yield-0 row and every CONST row pass); `probe_rock_cleave_a2` →
  `failures=0`; `probe_s12_field_budget` and `probe_s12_rock_rate` → both
  `failures=0`. S16 introduced no new probe red.

Two hand-checked observations (not findings against B1):
1. `--forbidden` is exact-string membership, so its directory entries (`docs/`,
   `ui/`, …) can never match a changed path — already **L206**. By hand: no
   `project.godot`, `ui/`, `addons/`, `autoload/` or `ore_tuning.gd` path is in the
   diff. `docs/gameplay/02_minerals.md` and `18_engine_spec.md` **are** modified
   inside the `s16_start` window, but by content (the S14 spawn-mix tick and the
   S13/S16 cleaving rewording), by the worker file-set hook, and now by commit
   `6e5c7e8` ("apply the owner's answers across the open decisions", docs/state
   only), they are the developer session's docs-first edits, not B1's;
   `S16-B1_report.md` names only `game/asteroid.gd`, `game/asteroid_field.gd` and
   the new suite.
2. `staging/compare/task.md` (the BOUNTY BOARD design task) was added in the same
   window by the parallel designer lane, not by S16.
