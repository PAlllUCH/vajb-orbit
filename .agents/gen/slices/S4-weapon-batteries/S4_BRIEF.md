# S4_BRIEF — Weapon batteries (group weapon systems in OUTFITTING)

Wave `S4`, slice `S4-weapon-batteries`. Read in this order before working:
1. `AGENTS.md` (rules; the folder law; the worker-file enforcement)
2. `docs/gameplay/09_ship_slots_modules.md` **§10** (the battery law — the owner's
   rulings verbatim) and §4 (the transactions it loops)
3. `docs/design/STATION_HUB.md` §5.10 (the strip rows) and §5.1
4. `docs/CONTRACTS.md` **§16** (this wave's pin), §13 (the transactions) and
   §8.2 (where the fire side lives)
5. this brief end to end

## Owner requests, verbatim

- "in outfitting there should be option to group weapon systems. Like 3 lasers
  together, 3 bolters together etc. Its pointless to have each weapon on separate slot."
- (asked directly how a group sits in the mounts — the ruling this wave is built on)
  **N barrels keep N W mounts**: the battery is one row and one trigger; 08's W
  counts stay the barrel cap.

## What is already measured (do not re-derive, do verify)

- OUTFITTING's FITTED WEAPONS strip today manages one cell per row
  (`ui/station/outfitting_panel.gd` — P2-B1's strip, L78's `module_action` at
  `:873-882`, REMOVE per fitted cell); the FITTING pane (`ui/station/fitting_panel.gd`)
  is the per-cell surface and stays it.
- The fit is one instance per W cell (`fit_module_at`/`clear_fit_slot`,
  CONTRACTS §13; layout indices 09 §4.5) — **this wave changes no fit shape**.
- `WeaponComponent` (`game/weapons.gd`) already groups fire through
  `selected_group`/`fitted()` (§8.2; `test_engine2_wiring.gd:243-246` reads the
  seam). Whether a trigger already discharges multiple barrels is a **measure
  first** item: if the volley already works per family, H2 reduces to the strum
  and the seam's `battery()` read — report, do not re-implement.
- After S3, fitted cells hold `instance_id`s and the strip's rows aggregate by
  `base_id` with `OWNED ×<n>`.

## The pinned interface (CONTRACTS §16 is the source of truth; nothing here may drift)

```gdscript
# PlayerProfile — bulk wrappers over the §13 composed transactions. Loops over
# cells; a failed cell rolls the batch back to its starting fit.
fit_battery(ship_id: StringName, base_id: StringName, indices: Array) -> bool
clear_battery(ship_id: StringName, base_id: StringName) -> bool
# WeaponComponent — the volley seam
fitted() -> Array                       # unchanged, per barrel
battery(base_id: StringName) -> Array   # this battery's W indices
const BATTERY_STRUM_MS := 40            # per-barrel release offset, 0–40 ms; reversal 0
```

Rules that fix every ambiguity:
- **Grouping is a view + bulk actions + fire aggregation over unchanged storage.**
  One trigger discharges the whole battery: one round per barrel (the ammo slot
  each barrel already owns), per-barrel damage, the strum offset per barrel.
- The strip row reads `3× LASER MKII · W1·W2·W3 · OWNED ×<n>` per STATION_HUB
  §5.10; `FIT ALL` fills min(owned, free) of the module's own type in layout
  order, `REMOVE ALL` empties exactly the battery's cells (mandatory cells refuse
  with §13's pinned `MANDATORY CELL — SWAP ONLY, NEVER EMPTY`), `SWAP ALL` swaps
  each barrel in place with the displaced instances returning to inventory.
- A batch that fails any cell rolls back to its starting fit and the footer names
  the §13 refusal (`13 / 11 PWR — OVER BY 2` or `REFUSED · FIT ILLEGAL`).
- The per-barrel expander (`▸`) restores the existing single-cell actions
  unchanged (L78's ACTION precedence stays as ticked).
- The FITTING pane, the fit shape, prices and stats do not move.

## Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| S4-H0 | docs drift check | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S4-H0_report.md`: 09 §10/STATION_HUB §5.10/§16 read against the tree, including the measure-first item on the existing volley; contradictions at file:line |
| S4-H1 | battery strip + bulk transactions | `vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | §5.10's grouped rows + `fit_battery`/`clear_battery` with batch rollback; `tests/test_s4_batteries.gd` (AC1/AC3) |
| S4-H2 | volley + strum | `vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/tests/` | `battery()` + one-trigger discharge + `BATTERY_STRUM_MS` (AC2); extend `tests/test_engine2_weapons.gd` with volley coverage |
| S4-H3 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S4-H3_review.md` + LOW rows in `_state/LOW_BACKLOG.md` |
| S4-H4 | fixer | the union of H1+H2 sets + `docs/CONTRACTS.md` | only if H3 leaves HIGH/MED |

**Run order:** H0 → H1 → H2 → H3 → (H4 only on HIGH/MED). H1 and H2 are
disjoint-safe but run sequential anyway (H2's `battery()` is what H1's rows read
if H0 finds the fire side needs the seam first).

## Tests that move, and why

- `test_p2b1_outfitting_panel.gd` — the strip's per-cell row tests rewrite to the
  battery rows (the expander keeps the single-cell assertions alive).
- `test_engine2_weapons.gd` (29) — additions only (volley, rounds per barrel,
  strum bound); existing family tests hold.
- New: `tests/test_s4_batteries.gd` (grouping, bulk round-trip, batch rollback,
  strum bound). Expected gate: **S3's figure + ~10**; the measured number at
  close-out goes into CONTRACTS §9.

## Hard rules

- Frozen: `project.godot`, `docs/gameplay/18_engine_spec.md`, `08_ship_slots_modules.md`,
  `assets/`, `addons/`, the theme.
- **No fit shape change** — one instance per W cell; N barrels keep N mounts
  (the owner's own ruling). No price, damage, cadence or ammo number moves
  except that a volley now charges one round per barrel (which is the ruling).
- No shell-based file edits; workspace-relative `VAJB_WORKER_FILES` paths (L92a).
- Bounded probes only (L82). Never leave a background job.
- A number not in the pinned docs: **report it, never invent it**.

## Staged / deferred

- Player-defined mixed groups (e.g. 2 lasers + 1 cannon on one trigger) — out;
  batteries group by identical `base_id` only. If wanted, it is its own later wave.
- L92's bare-hull mandatory-cell residual still rides its own fix.

## Owner ticks owed after this wave

- None new: the mount semantics are ruled (Q1, 2026-09-22). `BATTERY_STRUM_MS := 40`
  is proposed with reversal 0 — a tick only if the owner wants it different.

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch profile; identical counts) + the live-profile untouched check.
2. `python3 staging/verify_wave.py verify --baseline s4_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md --tests --expect-reports .agents/gen/slices/S4-weapon-batteries/S4-H0_report.md .agents/gen/slices/S4-weapon-batteries/S4-H3_review.md`
   *(Corrected 2026-09-22 in the S3 docs pass: the flags are `nargs="*"`, so comma-joined tokens became one path, the engine spec's snapshot key has no `vajb-orbit/` prefix, and `--expect-reports` resolves under the workspace root — the v1 line exited 1 with an inert frozen-file guard. Re-measured working form above.)*
3. CONTRACTS §9 figure + §10 measured note updated by H3; 09 §10 ticked.
4. `_state/WAVEBOARD.md` row closed; LOW findings appended at the next free row — L94–L106 are taken as of 2026-09-22, so the file's own counter law applies (next free global ticket id **T-93**).
5. Wave-boundary commit.
