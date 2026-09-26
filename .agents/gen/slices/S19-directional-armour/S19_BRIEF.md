# S19 — Directional armour & breach malfunctions (wave brief)

**Wave:** S19 (code lane, item 25 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S19-directional-armour/`
**Baseline:** gate **887/0** (S18 close + owner fix, 2026-09-26); `python3 staging/verify_wave.py snapshot --name s19_start` before the first dispatch.
**Owner go (2026-09-26):** "gameplay needs implementation, balance can be done later" — ruling 23 (2026-09-20) is the feature; P1–P8 ship as playtest-tunable initials.

## 1. The law to read, in order

1. `slices/S19-directional-armour/SLICE.md` — scope, ACs, your file-set row.
2. `docs/gameplay/09_ship_slots_modules.md` §3.3's **2026-09-26 amendment**
   (this wave's pin: mechanics, P1–P8 with reversals) and
   `docs/gameplay/01_economy_core.md` §6's 2026-09-26 amendment (repairs).
3. `docs/gameplay/18_engine_spec.md` §4.2 item 5 + §4.5 + ruling 23 (read-only
   context; the amendments above are the operative text).
4. The seams in §2 below: `player_state.gd`, `player_ship.gd`, `repairs.gd`,
   `repairs_panel.gd`, `ship_status_screen.gd`; `damage.gd` is read-only —
   you must not touch it.

## 2. Pinned interface (verbatim — what stands and what changes shape)

The routing target (`player_state.gd:227-234`, the one function that grows
quadrant logic — the absorb order and the no-carry-over rule stand):

```gdscript
func damage(amount: float, bypass_shield: bool = false, ctx: Dictionary = {}) -> void:
	_last_damage_ctx = ctx
	if amount <= 0.0:
		return
	if not bypass_shield and shield > 0.0:
		set_shield(shield - amount)
		return
	set_hull(hull - amount)
```

The sum invariant's home (`player_state.gd:209-214`; `hull` stays the sum of
the four pools — `set_hull` redistributes proportionally, evenly when all are
zero, and `died` fires exactly as today):

```gdscript
func set_hull(value: float) -> void:
	var was_alive := hull > 0.0
	hull = clampf(value, 0.0, hull_max)
	hull_changed.emit(hull, hull_max)
	if was_alive and hull <= 0.0:
		died.emit()
```

The context contract that stands byte-identical (`damage.gd:43-45`,
`:126-137` — `damage.gd` is a **forbidden file**; `direction` is a signed
angle over `[-PI, PI]`, 0.0 dead ahead, `+PI/2` off the right flank, dead
astern reads `-PI`, half-open at `+PI`; a quadrant comparison reads
`absf(direction)`):

```gdscript
const CTX_DIRECTION: StringName = &"direction"
const CTX_IMPULSE: StringName = &"impulse"
const CTX_FAMILY: StringName = &"family"
```

```gdscript
static func bearing(target_position: Vector2, heading: float, source_position: Vector2) -> float:
	return wrapf((source_position - target_position).angle() - heading, -PI, PI)
```

The sink that forwards unchanged (`player_ship.gd:516-519`) and the two flight
seams the malfunctions hook (`player_ship.gd:800-809`; the flicker joins the
thrust-ignore gate the Emergency Flight Mode already uses — `player_state.gd`
`:261-265`: "the hull ignores thrust input (it reads this flag)"):

```gdscript
func _step_turn(desired_turn: float, delta: float) -> void:
	if _body == null or delta <= 0.0:
		return
	var spin_rate := _spin_rate()
	var omega := _body.angular_velocity
	var alpha := clampf((desired_turn - omega) / delta, -spin_rate, spin_rate)
	var torque := _angular_inertia() * (alpha + _angular_damp() * omega)
	if is_zero_approx(torque):
		return
	_apply_torque(torque)
```

The repair seam (`repairs.gd:82`, `repair(profile, ship_id)`) restores the
four pools to `hull_max / 4` inside the same call that restores the hull sum;
`repairs_panel.gd:146`, `_build_report_rows()`, gains the four per-quadrant
lines; `ship_status_screen.gd` appends four rows after its existing ones.

Rules that fix every ambiguity:

1. **`hull` == sum(pools) is an invariant.** Totals drop exactly as today for
   every hit (a direction-less hit is ×1.0 into prow), so no existing gate row
   is expected to move — by construction, not by luck. Death flow, signals and
   clamps are unchanged.
2. **A missing or zero `direction` reads 0.0 (dead ahead → prow → ×1.0).**
   Never a rear-arc default, never a scatter — that is what keeps every
   existing damage number standing.
3. **Shield-first absorb is untouched** (no carry-over). The stern ×1.6 (P3)
   multiplies the incoming amount *before* that absorb; the quadrant pool
   takes what the shield did not.
4. **Malfunctions are derived state** (pool at 0 ⇒ its effect runs; pool above
   0 ⇒ it ends). No flags, no timers that outlive the pool. The flicker roll
   is seeded/injectable so tests are deterministic; a fresh fixture never
   malfunctions. The drift is a torque impulse through `_apply_torque`
   (`player_ship.gd:585-589`), positive = clockwise like every turn there.
5. **Exactly the consts named in P1–P8** (each one line to reverse); no new
   tunable beyond them, and `damage.gd`, `npc_ship.gd`, `npc_brain.gd`,
   `weapons.gd` stay **byte-identical** (forbidden files).

## 3. Existing rows (pre-grep before any edit; no unlisted row may move)

Candidate rows that touch hull damage, pools, flight response or repairs, and
the expected verdict. "unchanged" = the row's numbers cannot move under the
§2 invariants.

| Row (`file:line`) | Route | Verdict |
|---|---|---|
| `test_engine2_damage.gd:41` ctx/damage rows | pipeline absorb, direction-less hits | unchanged |
| `test_engine2_damage.gd:136-144` astern shielded hit | real ctx, astern `±PI`, shielded | **moves (L240, corrected by S19-F1):** inside P3's rear arc, so the shield absorbs 144 (90 × 1.6), not 90 — the row reads `SHIELD_MAX - 90 * PlayerState.STERN_DAMAGE_MULT` |
| `test_engine2_pools.gd` pool rows | sums/clamps; sum invariant holds | unchanged |
| `test_engine_c3_flight_decay.gd`, `test_flight_feel_g1.gd`, `test_s2_6_flight.gd` | flight response on fresh fixtures (no breach) | unchanged |
| `test_p1_repairs.gd` fee/repair rows | repair restores the same hull sum | unchanged |
| `test_combat_repair_c5.gd` in-flight repair | heals the sum via `set_hull` | unchanged |
| `test_d6_status.gd` screen rows | append-only rows (P8) | unchanged — a row-count assertion that must move is a bucket-2 pause |
| `probe_c2_weapons.gd:118` sink stub | the 2-arg/3-arg `take_damage` forms | unchanged |
| `test_engine2_fixes.gd` damage-adjacent rows | fixtures carry no rear-arc `direction` | unchanged |

Expected gate growth: **baseline + `test_s19_quadrants.gd`'s rows**, with
`test_engine2_damage.gd` holding its own 20 (one corrected row above, L240) — a
hermetic `[SUMMARY]` with any *other* suite's count moved is a red. Measured
after the L240 correction: **914/0**. Any other row that must move is a
**bucket-2 pause**: report it, leave it, stop.

## 4. Hard rules

- Docs are read-only for you (the amendments are already applied); any number
  you believe is wrong is reported, never edited.
- `--forbidden` at verify: `vajb-orbit/game/damage.gd`,
  `vajb-orbit/game/npc_ship.gd`, `vajb-orbit/game/npc_brain.gd`,
  `vajb-orbit/game/weapons.gd` (plus the standing set).
- Bounded Godot runs (`--quit-after`), self-quit probes, scratch
  `XDG_DATA_HOME` per run (L229 — never boot the live profile); never write a
  live `user://`.
- Signals travel UP, calls travel DOWN (Layer Cake); cross-file scripts by
  preload path, never the global class table.

## 5. Output contract

Report `slices/S19-directional-armour/S19-B1_report.md` (REPORT template,
≤120 lines): the pre-grep table (every candidate row, route, verdict), the
per-AC measured values (routing at interior + boundary angles, the ×1.6 both
sides of 100°, pool/spill arithmetic with the sum invariant after each step,
each malfunction with its seeded roll, the repair restore and both readouts),
the P1–P8 const table with reversals, the gate `[SUMMARY]` before/after,
every deviation.

## 6. Skills (read by path when you need Godot idiom)

The shared Godot skill library resolves on this host under
`~/.local/share/crush/additional-skills/godot/`. Useful here:
`godot-master/godot-gdscript-mastery/SKILL.md`, `godot-best-practices/SKILL.md`,
`godot-master/godot-testing-patterns/SKILL.md`. Project rules override
anything you read there (Layer Cake; preload paths).

## 7. Run order

**B1 → R1 → F1 only on HIGH/MED.** R1 re-measures every AC itself (W8's
byte-identical replay, seeded rolls), diffs against 09 §3.3's 2026-09-26
amendment (not this brief), greps the moved rows against §3's list, verifies
the four forbidden files are byte-identical, updates `CONTRACTS.md` §8.1
(PlayerState additions: the pools, the routing, the breach readers) and §18
(status screen rows) plus §9/§10 at the next free rows read at write time,
and appends LOW rows at the next free ids.

## 8. Close-out (the orchestrator)

1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s19_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/ vajb-orbit/autoload/
   vajb-orbit/game/damage.gd vajb-orbit/game/npc_ship.gd
   vajb-orbit/game/npc_brain.gd vajb-orbit/game/weapons.gd --tests
   --expect-reports .agents/gen/slices/S19-directional-armour/S19-B1_report.md
   .agents/gen/slices/S19-directional-armour/S19-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; MASTER_REPORT §6 recap.
4. Wave-boundary commit.
