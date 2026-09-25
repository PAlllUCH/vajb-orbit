# S14 — Four asteroid sizes, debris splits (wave brief)

**Wave:** S14 (code lane, item 21 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S14-debris-splits/`
**Baseline:** gate **834/0**; `python3 staging/verify_wave.py snapshot --name s14_start` before the first dispatch.
**Owner ask (2026-09-25, verbatim):** "right now we have 3 tiers of asteroids.
i want 4, each should split to random ones ... XL>L>M>S sizes, XL split to few
L, few M, few S so that it looks more like debris, then each L from split does
split to M and S etc".

## 1. The law to read, in order

1. `slices/S14-debris-splits/SLICE.md` — scope, ACs, your file-set row.
2. `docs/gameplay/02_minerals.md` §5.2 (this wave's pin) + §5.1 Rule A.
3. `vajb-orbit/game/asteroid.gd` + `asteroid_field.gd` — the code you change
   (`SIZE_*` :102-105, `FRAGMENT_SPLIT` :115-119, `_cleave`
   `asteroid_field.gd:374-428`, `_roll_look` `asteroid.gd:463-467`,
   `LOOK_TEXTURES`/`LOOK_WIDTHS` `asteroid.gd:172-194`).

## 2. Pinned interface (verbatim)

```gdscript
# game/ore_tuning.gd gains two fields (keys are the integer size classes:
# XL 3, L 2, M 1, S 0 — matching Asteroid.SIZE_*; test_s14_splits asserts it):
static var split_mix: Dictionary = {
    3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
    2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
    1: {0: Vector2i(1, 3)},
    0: {},
}
static var spawn_size_weights: Dictionary = {0: 40, 1: 32, 2: 20, 3: 8}
```

Rules that fix every ambiguity:

1. **Child roll:** at a shatter, for each `(child_kind, range)` in
   `split_mix[parent_kind]`, roll `count = rng.randi_range(range.x, range.y)`
   on the **field's own seeded rng** and spawn that many children of that kind.
   A child is always strictly smaller than its parent. `FRAGMENT_SPLIT` and
   `_fragment_size` are replaced by this table (keep the old consts only if a
   frozen row still reads them; otherwise delete).
2. **S13's conservation is untouchable** (02 §5.1 Rule A): a mining shatter's
   children share the parent's reserve — Σ child `_bore_ore` == the reserve,
   split across the whole mixed child set by `_unit_shares` (sizes never weight
   the split); a gun shatter's children carry no ore; nothing re-rolls. The
   family realises ≤ root `_bore_ore` + 1 however the dice fall.
3. **Size classes:** `SIZE_XL := 3` beside the existing three. `LOOK_TEXTURES`
   gains one row of 3 entries reusing the L silhouettes; `LOOK_WIDTHS` gains
   `180.0`. `_roll_look` becomes size-first: the spawn rolls the size from
   `spawn_size_weights`, then a look uniformly inside that size.
4. **Spawn:** `asteroid_field.gd`'s `_spawn_rock` rolls the size from
   `spawn_size_weights` (today it passes `SIZE_ANY` and the look roll is
   uniform over all 9 — `asteroid_field.gd:252`, `asteroid.gd:463-467`).
   `FIELD_ROCKS_MIN/MAX` and `tier_weights` are unchanged.
5. **The dev overlay keeps working:** `to_dict`/`from_dict` carry both new
   fields; sliders for them are optional (report if skipped).
6. **Numbers live in `OreTuning`** beside S13's — no re-declared literals in
   new code; the anti-drift test asserts the defaults equal the table above.

## 3. Tests that move (pinned; a row not listed here may not change)

- `tests/test_engine2_cleaving.gd` — the `FRAGMENT_SPLIT` constant pins
  (:332-338) and the child-size rows ("L→M, M→S"; `_fragment_size`) become the
  new table's rows.
- `tests/test_s13_caps.gd` — the reserve-split-across-count rows (the child
  count is now a rolled mix; keep the conservation assertion).
- `tests/probe_rock_cleave_a2.gd:670-671, 696-699` — child yield band rows
  follow the mixed child sets.
- `tests/probe_s12_field_budget.gd`, `tests/probe_s12_rock_rate.gd` — the
  cascade rows (rocks spawned, out/in per leg) follow the new splits; keep
  `failures=0`.
- New: `tests/test_s14_splits.gd` — AC1-AC5 + the anti-drift table assertion.
- **Not moved:** `test_s2_6_burst.gd`'s ejection physics rows,
  `test_combat_repair_c5.gd`, `test_engine2_cleaving.gd:302` (chip arithmetic),
  any S13 gate row not listed above. Pre-grep every row you touch and report
  it; an unlisted row changed is a HIGH finding at review.

## 4. Hard rules

- No `project.godot`, no `docs/`, no `ui/`, no `addons/`, no `autoload/`.
- Shell edits forbidden (the hook's gap) — edit tools only.
- Bounded Godot runs (`--quit-after`), self-quitting probes, scratch
  `XDG_DATA_HOME` per run; never write the profile or a live `user://`.
- A worker who believes a pinned number is wrong reports it and leaves it.

## 5. Output contract

Report `slices/S14-debris-splits/S14-B1_report.md` (REPORT template, ≤120
lines): the pre-grep table, per-AC measured values (the 200-shatter distribution
table, the conservation re-measurement, the 1000-roll mix), the gate
`[SUMMARY]` before/after, every deviation.

## 6. Skills (read by path when you need Godot idiom)

The shared Godot skill library referenced by `crushrc` resolves on this host
under `~/.local/share/crush/additional-skills/godot/`. Useful here:
`godot-master/godot-gdscript-mastery/SKILL.md` (static typing, signal
conventions), `godot-best-practices/SKILL.md`, and
`godot-master/godot-testing-patterns/SKILL.md` (test structure). Project rules
that override anything you read there: signals travel UP and calls travel DOWN
(the Layer Cake), and cross-file scripts are reached by preload path, never the
global class table.

## 7. Run order

**B1 → R1 → F1 only on HIGH/MED.** R1 re-measures every AC itself (W8's
byte-identical replay), diffs against 02 §5.2 (not this brief), greps the moved
rows against §3's list, updates `CONTRACTS.md` §9/§10 with the next free rows
read at write time, and appends LOW rows at the next free ids.

## 8. Close-out (the orchestrator)

1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s14_start --forbidden
   vajb-orbit/project.godot docs/gameplay/18_engine_spec.md
   docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md
   docs/gameplay/04_refinery.md docs/design/ ui/ addons/ --tests
   --expect-reports .agents/gen/slices/S14-debris-splits/S14-B1_report.md
   .agents/gen/slices/S14-debris-splits/S14-R1_review.md`
   (the parallel S15 lane's touched files are attributed, never reverted).
3. WAVEBOARD + `dispatch_coder.md` one-liners; MASTER_REPORT §6 recap.
4. Wave-boundary commit; the spawn-mix number goes to the owner as a tick.
