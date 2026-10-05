# S34_BRIEF — the refinery queue: timed refining, job slots, inventory

## §0 Owner note verbatim (2026-10-05)

"refinery needs to take time to refine, different per resource. maybe make it
so that it has slots (upgradable) and inventory (for output and input)".

## §1 Law to read in order

1. This brief (the pinned interface, the acceptance list).
2. `docs/gameplay/04_refinery.md` §7 (the model, values R1–R8, the panel
   contract — the wave's whole law) + §1–§3 (standing: 3:1, fee 5 CR/ore-unit,
   deterministic no-failure) + §4 (as amended: "instant in-play" is dead).
3. `docs/design/STATION_HUB.md` §21.3 (P42/P43) + §5.7 (the superseded pixel
   spec) + §12.4 (data-wiring law) + §19.4 (empty-state idiom).
4. `docs/design/UI_SPEC.md` §8 (buttons) + §11.1 (A5.5/N24) + §3.10 A5.
5. `docs/gameplay/01_economy_core.md` §7 (verify → take → pay → emit) + §3 K3
   (the fee sink) + §6 cap law.

## §2 Measured facts (file:line)

- `game/refinery.gd` today is static + instant: `fee_multiplier` :57,
  `fee_for` :77, `convertible` :85, `stacks` :95, `refine` :118,
  `refine_all` :159, `_restore` :201, `_refusal` :206, `_batch` :218.
- `ui/station/refinery_panel.gd` wires `_refine_button`/`_refine_all_button`/
  `_cancel_button`/`_stepper_more` + row hover/press (docs/CODE_MAP.md:359-367).
- Profile door idiom: `player_profile.gd:1178-1353` (the battery doors show the
  pattern: public static-style doors, `profile_changed(key)` emissions).
- `tests/test_p1_refinery.gd` = 6 rows; **:192 (the hide-sub-convertible-stacks
  row) must not move** (the sealed row). `tests/test_s23_content.gd` and
  `tests/probe_s23_r1.gd` call the old `Refinery.refine/refine_all` API and
  move with it.

## §3 Pinned interface (new `game/refinery.gd` surface + profile keys)

```gdscript
# game/refinery.gd (static, RefCounted) - the S34 surface
const BASE_SLOTS := 2            # R3
const MAX_SLOTS := 5             # R3
const SLOT_UPGRADE_COST := 3000  # R4
const INPUT_CAP := 60            # R5, ore units
const OUTPUT_CAP := 60           # R5, ingot units
static func resource_seconds(mineral_id: StringName) -> int   # R1: clamp(round(ingot_value/10), 10, 60)
static func queue(profile, mineral_id: StringName, conversions: int) -> Dictionary
static func queue_all(profile) -> Dictionary
static func cancel(profile, job_id: int) -> Dictionary
static func settle(profile) -> int            # completes ready jobs -> refinery_output
static func load_ore(profile, mineral_id: StringName, units: int) -> Dictionary
static func collect_all(profile) -> Dictionary
static func upgrade_slots(profile) -> Dictionary
static func jobs(profile) -> Array[Dictionary]
static func fee_for(conversions: int, mult: float = 1.0) -> int   # stands from today
static func fee_multiplier(profile) -> float                      # stands
```

```gdscript
# autoload/player_profile.gd - new persisted keys (defaults for old saves)
var refinery_slots: int = 2
var refinery_input: Dictionary = {}    # mineral_id -> ore units (cap INPUT_CAP)
var refinery_output: Dictionary = {}   # mineral_id -> ingot units (cap OUTPUT_CAP)
var refinery_jobs: Array = []          # [{id:int, mineral_id:StringName, conversions:int, ready_at:int, state:StringName}]
var refinery_next_job_id: int = 1
# job state: "pending" | "running" | "done"; ready_at = unix seconds (Time.get_unix_time_from_system)
# every mutation emits profile_changed(&"refinery"); refunds via the existing credits door
```

Rules that fix ambiguity: `queue()` is all-or-nothing (verify fee → spend fee →
take ore from input → job; on any step failing, restore and return a refusal);
`cancel()` refunds the fee through the credits door and returns the ore to
input (cap check: if input is full the ore goes to the hold, then input);
`settle()` moves done jobs' conversions into `refinery_output` (cap-checked;
jobs whose output does not fit stay `done` until collected);
`collect_all()` fills the hold, overflow stays (R8); jobs run station-side on
wall-clock `ready_at` (R6) — settle on load, on pane refresh, and on a 1 Hz
tick while the pane is open. Numbers come only from `MineralCatalog` + the
constants above.

## §4 Spec extract (verbatim) + acceptance list

04 §7.1: "A confirmed batch becomes one job {mineral_id, conversions} on one
slot; wall duration = conversions × RESOURCE_SECONDS(mineral). A job never
fails and never yields differently." / "RESOURCE_SECONDS (R1):
clamp(round(ingot_value_cr / 10), 10, 60) seconds per conversion" / "Slots
(R3/R4): refinery_slots jobs run in parallel: 2 base, bought +1 at the panel
for 3,000 CR flat, hardcap 5" / "Inventory (R5): Input ore lives in
refinery_input (cap 60 ore units), output ingots in refinery_output (cap 60
ingot units)" / "Queue (R7): QUEUE N (was REFINE N) … QUEUE ALL (was
REFINERY ALL) queues one job per convertible mineral" / "Time (R6): … settle
finished jobs on load, on pane refresh, and on a 1 Hz tick while the pane is
open."
STATION_HUB §21.3 P42/P43: the three-block pane (LEFT hold + input tagged
LOADED; CENTRE stepper + ORE IN · INGOTS OUT · FEE · TIME + QUEUE N / QUEUE
ALL / CANCEL + LOAD / COLLECT ALL; RIGHT the job list with mm:ss countdowns),
SLOTS readout in the header band, catalogue-only numbers.

Acceptance (the report answers each):
1. R1 exact (probe: Iron ≈ 10 s, Gold ≈ 40 s per conversion, clamped 10..60; formula cited).
2. `queue()` all-or-nothing (probe each failure path restores state) and duration = conversions × RESOURCE_SECONDS; jobs never fail.
3. Slots: 2 base; upgrade +1 for 3,000 CR; hardcap 5 refuses; parallel jobs; QUEUE ALL = one job per mineral with FIFO pending beyond free slots.
4. Inventory: LOAD hold→input and COLLECT ALL output→hold with caps enforced (over-cap refused / overflow stays); CANCEL refunds the fee + returns ore.
5. `settle()` completes ready jobs into `refinery_output` driven by wall-clock `ready_at` — verified on load, pane refresh and a 1 Hz tick (fake-ready probe).
6. Panel per P42/P43: three blocks, header SLOTS readout + UPGRADE, the exact action words, `mm:ss` countdowns, empty-state idiom, no hardcoded prices/durations (grep).
7. Gate green ×2 + moved rows disclosed; `test_p1_refinery.gd:192` unchanged.

## §5 Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S34-B1 | builder — `hyper/deepseek-v4.1-flash` @ xhigh | `vajb-orbit/game/,vajb-orbit/autoload/,vajb-orbit/ui/,vajb-orbit/tests/` | code + tests → `S34-B1_report.md` |
| S34-R1 | reviewer — `hyper/glm-5.3-flash` @ max | `vajb-orbit/tests/,.agents/gen/slices/S34-refinery-queue/` | `S34-R1_review.md` |
| S34-F1 | fixer — as B1 (**only if HIGH/MED**) | as B1 | `S34-F1_report.md` |

## §6 Run order
B1 → R1 → (F1). S34 runs strictly **after S33 closes** (both land rows in
`vajb-orbit/tests/`; the whole-tree verify baselines must not see each other's
diffs).

## §7 Tests that move

`tests/test_p1_refinery.gd`: the instant-conversion rows restate as
queue/settle/collect rows (exact mapping chosen by B1, each disclosed);
**:192 must not move**; the fee-arithmetic rows stand (fees unchanged).
`tests/test_s23_content.gd` refinery rows and `tests/probe_s23_r1.gd`'s
`Refinery.refine/refine_all` calls move to the new API (disclosed; probes are
evidence scripts, keep them runnable). New suite
`tests/test_s34_refinery_queue.gd`: R1 formula values; queue all-or-nothing;
cancel refund + ore return; the slot ladder (2 → 5, 3,000 CR, refusal at 5);
cap refusals (input/output); settle completes a fake-ready job (wall clock);
QUEUE ALL FIFO pending; COLLECT overflow stays; save round-trip of the new
keys with old-save defaults.

## §8 Hard rules
File set above only (never docs/, addons/). This brief is law: a pinned number
you believe wrong gets reported and left at the closest value — never silently
changed. All profile mutations go through `player_profile.gd` doors (new doors
are the pinned §3 names — invent nothing). `test_p1_refinery.gd:192` must not
move. A5.5/N24 govern hover/focus.

## §9 Staged / deferred
`u_refine` synergy (R3's reversal — module-granted slots) and 04 §6's balance
tuning ride the next economy pass; `CONTRACTS.md`'s row updates (the
`REFINERY ALL` wording, gate counts) happen at the review wave's docs pass.

## §11 Tick sheet
| Tick | The call | Default if silent |
|---|---|---|
| **T-133** | the R1–R8 value pack (time formula, fee at queue, 2→5 slots at 3,000 CR, caps 60/60, wall-clock jobs, QUEUE ALL FIFO, COLLECT overflow) | as PROPOSED (04 §7.2) |

## §12 Close-out
Gate ×2 fresh scratch → `verify_wave.py verify --baseline s34_start` →
`staging/build_code_map.py` → TICKS (T-133 leaves when decided or defaults) →
WAVEBOARD row + `MASTER_REPORT.md` §6 → wave commit.
