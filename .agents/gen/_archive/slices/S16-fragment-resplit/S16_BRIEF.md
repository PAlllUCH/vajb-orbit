# S16 — Fragment re-splits: debris keeps splitting (wave brief)

**Wave:** S16 (code lane, item 23 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S16-fragment-resplit/`
**Baseline:** gate **859/0** (D8's close, 2026-09-25); `python3 staging/verify_wave.py snapshot --name s16_start` before the first dispatch.
**Owner ask (2026-09-25, verbatim):** "right now they split correctly, but the
once split asteroid doesnt split further. this need to change."

## 1. The law to read, in order

1. `slices/S16-fragment-resplit/SLICE.md` — scope, ACs, your file-set row.
2. `docs/gameplay/02_minerals.md` §5.2 ter (this wave's pin) + §5.2 (the
   split table) + §5.1 Rule A (conservation).
3. `vajb-orbit/game/asteroid.gd` + `asteroid_field.gd` — the three seams
   below (`cleaves` `asteroid.gd:399-402`, `_cleave` `asteroid_field.gd:415-469`,
   `_pay_burst` `asteroid_field.gd:499-501`).

## 2. Pinned interface (verbatim — the defect and the fix shape)

Today's gate (`asteroid.gd:399-402`) — ruling 17's yield-0 law, one line:

```gdscript
## Ruling 17's "a yield-0 rock still cracks and despawns without fragments": only a
## rock that rolled ore cleaves. The field asks this before spawning anything.
func cleaves() -> bool:
	return _bore_ore > 0.0
```

Today's gun-child construction (`asteroid_field.gd:444-454`) — the 0-bore
birth that makes shot debris inert:

```gdscript
	for index in count:
		var units: int = int(shares[index]) if from_mining else 0
		var fragment := _new_rock(
			"Fragment%d" % (_spawned + 1),
			mineral_id,
			tier,
			units,
			int(children[index]),
			true,
			float(units)
		)
```

The pinned fix shape (a parentage marker; nothing else changes):

```gdscript
# game/asteroid.gd — gains:
var _cleave_child := false

## S16 (02 §5.2 ter): a rock born of a cleave splits per its own size class
## whatever its bore; an original keeps ruling 17's yield-0 law.
func mark_cleave_child() -> void:
	_cleave_child = true

func cleaves() -> bool:
	return _bore_ore > 0.0 or _cleave_child

# game/asteroid_field.gd — _cleave marks every fragment it builds,
# immediately after the _new_rock call:
		fragment.call(&"mark_cleave_child")
```

Rules that fix every ambiguity:

1. **Parentage, not ore, gates a fragment's cleave.** Every rock `_cleave`
   builds is marked, whatever its units. No caller outside `_cleave` may
   mark: a field spawn, a POI roll and any test fixture built through
   `setup` is an original and stays unmarked.
2. **No arithmetic changes.** `OreTuning.split_mix`, `_unit_shares`,
   `GUN_BURST_SHARE`, `FRAGMENT_CORE_SHARE`, the ejection cone/kick and the
   burst roll are untouched. A 0-bore fragment pays nothing at every
   shatter — `_pay_burst` already returns on `owed <= 0.0`; if any path can
   reach a burst with owed > 0 on a 0-bore fragment, that is a HIGH finding,
   not something to fix.
3. **The break read stays unconditional** (`_on_rock_cracked` runs
   `_break_read` before `_cleave`): a shot fragment explodes exactly as it
   does today; only its children are new.
4. **No new tunables, no re-declared literals** in new code; `ore_tuning.gd`
   and the dev overlay are untouched.
5. **The mining route must not change behaviour.** Its children already
   cleave (bore > 0); marking them changes no observable number. S14's AC3
   stays green byte-identical.
6. **The marker is runtime-only** — never persisted, no profile or save
   format change.

## 3. Tests that move (pinned)

- **New:** `tests/test_s16_resplits.gd` — SLICE.md's AC1–AC6, seeded on the
  field's own rng (S14's suite is the pattern).
- **No existing gate row moves.** The rows that read cleaving today are
  mining-route or original-rock rows and stay green. Pre-grep and report
  every candidate BEFORE editing: `test_engine2_cleaving.gd` (its
  bare/yield-0 row `:627-653` builds an original through the field and must
  stay false-cleaving; its VARIETY/count rows are mining originals),
  `test_s13_caps.gd` (the gun legs `:156,:173,:228,:292` measure units paid,
  not rocks — but check the respawn-boundary row `:212-217` for its
  consumption route), `test_s13_mining_batteries.gd`, `test_s14_splits.gd`,
  `test_s2_6_burst.gd`. Any row that must change is a **bucket-2 pause:
  report it, do not edit it.**
- **Probes are not the gate and stay frozen:** `probe_rock_cleave.gd`,
  `probe_rock_cleave_a2.gd` (L202 owns their stale rows), `probe_s12_*.gd`.

## 4. Hard rules

- No `project.godot`, no `docs/`, no `ui/`, no `addons/`, no `autoload/`, no
  `ore_tuning.gd`.
- Shell edits forbidden (the hook's gap) — edit tools only.
- Bounded Godot runs (`--quit-after`), self-quitting probes, scratch
  `XDG_DATA_HOME` per run; never write the profile or a live `user://`.
- A worker who believes a pinned number is wrong reports it and leaves it.

## 5. Output contract

Report `slices/S16-fragment-resplit/S16-B1_report.md` (REPORT template, ≤120
lines): the pre-grep table (every candidate row, its route, its verdict),
the per-AC measured values, the gate `[SUMMARY]` before/after, every
deviation.

## 6. Skills (read by path when you need Godot idiom)

The shared Godot skill library referenced by `crushrc` resolves on this host
under `~/.local/share/crush/additional-skills/godot/`. Useful here:
`godot-master/godot-gdscript-mastery/SKILL.md` (static typing, signal
conventions), `godot-best-practices/SKILL.md`, and
`godot-master/godot-testing-patterns/SKILL.md` (test structure). Project
rules that override anything you read there: signals travel UP and calls
travel DOWN (the Layer Cake), and cross-file scripts are reached by preload
path, never the global class table.

## 7. Run order

**B1 → R1 → F1 only on HIGH/MED.** R1 re-measures every AC itself (W8's
byte-identical replay), diffs against 02 §5.2 ter (not this brief), greps the
moved rows against §3's list, updates `CONTRACTS.md` §9/§10 with the next
free rows read at write time (the `cleaves` pin's new sentence rides §5),
and appends LOW rows at the next free ids.

## 8. Close-out (the orchestrator)

1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s16_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/ui/ vajb-orbit/addons/
   vajb-orbit/autoload/ vajb-orbit/game/ore_tuning.gd --tests
   --expect-reports .agents/gen/slices/S16-fragment-resplit/S16-B1_report.md
   .agents/gen/slices/S16-fragment-resplit/S16-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; MASTER_REPORT §6 recap.
4. Wave-boundary commit.
